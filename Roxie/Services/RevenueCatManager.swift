import Foundation
import RevenueCat

/// Wraps the RevenueCat SDK. Owns SDK configuration, user identification,
/// fetching offerings, executing purchases, and exposing the user's Pro
/// entitlement state to the UI.
///
/// Setup checklist:
/// 1. Set `AppConfig.revenueCatAPIKey` (or env `REVENUECAT_API_KEY`) to the
///    public iOS app-specific API key from the RevenueCat dashboard.
/// 2. In RevenueCat dashboard: configure offerings + entitlement matching
///    `AppConfig.revenueCatProEntitlement`, link to App Store Connect IAPs.
/// 3. Add the IAP capability + StoreKit configuration in Xcode if testing
///    in sandbox.
@MainActor
@Observable
final class RevenueCatManager {
    static let shared = RevenueCatManager()

    /// `true` if the customer has the Pro entitlement active. Backed by
    /// RevenueCat `customerInfo.entitlements`. Updated reactively via the
    /// `customerInfoStream`.
    private(set) var isProUser: Bool = false

    /// Latest fetched offerings. Nil until `fetchOfferings()` succeeds at
    /// least once.
    private(set) var currentOffering: Offering?

    /// `true` while a purchase or restore is in-flight.
    private(set) var isPurchasing: Bool = false

    /// Last user-facing error message from a purchase / restore. Nil on success.
    private(set) var lastError: String?

    private var configured = false
    private var customerInfoTask: Task<Void, Never>?

    private init() {}

    // MARK: - Lifecycle

    func configure(userId: String?) {
        guard !configured else { return }
        configured = true

        Purchases.logLevel = .info
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: AppConfig.revenueCatAPIKey)
                .with(appUserID: userId)
                .build()
        )

        // Subscribe to customerInfo updates so isProUser stays fresh after
        // renewals, refunds, restores, or purchases on other devices.
        customerInfoTask?.cancel()
        customerInfoTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                await MainActor.run { self?.applyCustomerInfo(info) }
            }
        }

        // Initial fetch + offerings prefetch in the background.
        Task {
            await refreshSubscriptionStatus()
            await fetchOfferings()
        }
    }

    func login(userId: String) async {
        guard configured else {
            Log.app.warning("RevenueCat.login called before configure")
            return
        }
        do {
            let result = try await Purchases.shared.logIn(userId)
            applyCustomerInfo(result.customerInfo)
        } catch {
            Log.app.error("RevenueCat login failed: \(error.localizedDescription)")
        }
    }

    func logout() async {
        guard configured else { return }
        do {
            let info = try await Purchases.shared.logOut()
            applyCustomerInfo(info)
        } catch {
            Log.app.error("RevenueCat logout failed: \(error.localizedDescription)")
        }
        isProUser = false
    }

    /// Force-refresh from RevenueCat. The customerInfoStream handles ambient
    /// updates; this is for explicit user-triggered refreshes.
    func refreshSubscriptionStatus() async {
        guard configured else { return }
        do {
            let info = try await Purchases.shared.customerInfo()
            applyCustomerInfo(info)
        } catch {
            Log.app.warning("customerInfo fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Offerings

    /// Pulls the current offering (set as default in RevenueCat dashboard).
    /// Returns `nil` on failure or if no offering is configured.
    @discardableResult
    func fetchOfferings() async -> Offering? {
        guard configured else { return nil }
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            if let off = currentOffering {
                let pkgSummary = off.availablePackages.map { p in
                    "\(p.identifier)=\(p.storeProduct.productIdentifier)[type=\(p.packageType)]"
                }.joined(separator: ", ")
                Log.app.info("[RC] currentOffering='\(off.identifier, privacy: .public)' packages=[\(pkgSummary, privacy: .public)]")
            } else {
                Log.app.warning("[RC] No current offering — set one as Default in RevenueCat dashboard. allOfferings=\(offerings.all.keys.joined(separator: ","), privacy: .public)")
            }
            return currentOffering
        } catch {
            Log.app.error("[RC] Offerings fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Purchase / Restore

    /// Buys the given package. Returns `true` if the purchase completed and
    /// the Pro entitlement is now active.
    @discardableResult
    func purchase(package: Package) async -> Bool {
        guard configured else { return false }
        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                Log.app.info("Purchase cancelled by user")
                return false
            }
            applyCustomerInfo(result.customerInfo)
            return isProUser
        } catch {
            let nsError = error as NSError
            // Don't surface the cancel as an error.
            if nsError.domain == ErrorCode.errorDomain,
               nsError.code == ErrorCode.purchaseCancelledError.rawValue {
                return false
            }
            Log.app.error("Purchase failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
            return false
        }
    }

    /// Restores prior purchases for this Apple ID. Returns `true` if any
    /// active entitlement was restored.
    @discardableResult
    func restorePurchases() async -> Bool {
        guard configured else { return false }
        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            applyCustomerInfo(info)
            return isProUser
        } catch {
            Log.app.error("Restore failed: \(error.localizedDescription)")
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Internals

    private func applyCustomerInfo(_ info: CustomerInfo) {
        let allEnts = info.entitlements.all
        let activeEnts = info.entitlements.active
        let activeProductIds = info.activeSubscriptions.joined(separator: ",")
        let entitlement = info.entitlements[AppConfig.revenueCatProEntitlement]
        let active = entitlement?.isActive == true

        Log.app.info("[RC] applyCustomerInfo userID=\(info.originalAppUserId, privacy: .public) lookingFor='\(AppConfig.revenueCatProEntitlement, privacy: .public)' allEnts=[\(allEnts.keys.joined(separator: ","), privacy: .public)] activeEnts=[\(activeEnts.keys.joined(separator: ","), privacy: .public)] activeSubs=[\(activeProductIds, privacy: .public)] -> isProUser=\(active)")

        if active != isProUser {
            Log.app.info("[RC] Pro entitlement changed: \(active)")
        }
        isProUser = active
    }
}
