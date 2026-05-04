import SwiftUI
import AVKit
import Combine
import RevenueCat

struct SubscriptionScreen: View {
    var onClose: () -> Void

    @Environment(VRMContext.self) private var vrm
    @State private var rc = RevenueCatManager.shared
    @State private var selectedPlan: Plan = .yearly
    @State private var player: AVPlayer?
    @State private var playerReady: Bool = false
    @State private var statusCancellable: AnyCancellable?
    @State private var browserURL: URL?
    @State private var loadingOfferings: Bool = false
    @State private var purchaseAlert: PurchaseAlert?

    enum Plan: Hashable { case yearly, monthly }

    struct PurchaseAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private var yearlyPackage: Package? {
        guard let off = rc.currentOffering else { return nil }
        return off.availablePackages.first { $0.storeProduct.productIdentifier == AppConfig.ProProductID.yearly }
            ?? off.annual
            ?? off.availablePackages.first { $0.packageType == .annual }
            ?? off.availablePackages.first { matchesYearly($0) }
    }

    private var monthlyPackage: Package? {
        guard let off = rc.currentOffering else { return nil }
        return off.availablePackages.first { $0.storeProduct.productIdentifier == AppConfig.ProProductID.monthly }
            ?? off.monthly
            ?? off.availablePackages.first { $0.packageType == .monthly }
            ?? off.availablePackages.first { matchesMonthly($0) }
    }

    /// Loose match for "yearly/annual" — covers Test Store / mis-tagged dashboards
    /// (e.g. RevenueCat's Test Store sometimes ships annual products under
    /// `$rc_lifetime` packages with productID just `yearly`).
    private func matchesYearly(_ p: Package) -> Bool {
        let pid = p.storeProduct.productIdentifier.lowercased()
        let id = p.identifier.lowercased()
        return pid.contains("year") || pid.contains("annual")
            || id.contains("year") || id.contains("annual")
    }
    private func matchesMonthly(_ p: Package) -> Bool {
        let pid = p.storeProduct.productIdentifier.lowercased()
        let id = p.identifier.lowercased()
        return pid.contains("month") || id.contains("month")
    }

    private var selectedPackage: Package? {
        selectedPlan == .yearly ? yearlyPackage : monthlyPackage
    }

    private func priceString(for plan: Plan) -> String {
        let pkg = plan == .yearly ? yearlyPackage : monthlyPackage
        return pkg?.storeProduct.localizedPriceString ?? (plan == .yearly ? "$59.99" : "$9.99")
    }

    private func planCode(for plan: Plan) -> String { plan == .yearly ? "PRO.A" : "PRO.M" }
    private func planName(for plan: Plan) -> String { plan == .yearly ? "ANNUAL" : "MONTHLY" }
    private func planPeriod(for plan: Plan) -> String { plan == .yearly ? "PER YEAR" : "PER MONTH" }
    private func planSubDetail(for plan: Plan) -> String? {
        guard plan == .yearly, let pkg = yearlyPackage else { return nil }
        // Show approximate per-month equivalent (annual price ÷ 12).
        let price = pkg.storeProduct.price as Decimal
        let perMonth = NSDecimalNumber(decimal: price / 12)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = pkg.storeProduct.priceFormatter?.locale ?? .current
        formatter.currencyCode = pkg.storeProduct.currencyCode
        return formatter.string(from: perMonth).map { "\($0) / mo" }
    }

    private let perks: [(systemImage: String, text: String)] = [
        ("infinity", "UNLIMITED MESSAGES"),
        ("photo.stack.fill", "EXCLUSIVE MEDIA VAULT"),
        ("video.fill", "30 MIN VIDEO / MONTH"),
        ("person.2.fill", "15+ COMPANIONS UNLOCKED"),
        ("tshirt.fill", "FULL OUTFIT LIBRARY"),
        ("photo.on.rectangle.angled", "FULL BACKGROUND LIBRARY"),
    ]

    private var defaultVideoURL: URL? {
        URL(string: "https://pub-6671ed00c8d945b28ff7d8ec392f60b8.r2.dev/videos/Smiling_sweetly_to_202601061626_n3trm%20(online-video-cutter.com).mp4")
    }
    private var heroCharacter: CharacterItem? { vrm.currentCharacter }
    private var heroVideoURL: URL? {
        if let s = vrm.currentCostume?.videoUrl, let u = URL(string: s) { return u }
        if let s = heroCharacter?.videoUrl, let u = URL(string: s) { return u }
        return defaultVideoURL
    }
    private var discountText: String? {
        guard let yearly = yearlyPackage, let monthly = monthlyPackage else { return nil }
        let monthlyAnnualized = (monthly.storeProduct.price as Decimal) * 12
        let yearlyPrice = yearly.storeProduct.price as Decimal
        guard monthlyAnnualized > 0 else { return nil }
        let savedFraction = (monthlyAnnualized - yearlyPrice) / monthlyAnnualized
        let pct = Int((savedFraction as NSDecimalNumber).doubleValue * 100)
        return pct > 0 ? "-\(pct)%" : nil
    }

    var body: some View {
        ZStack(alignment: .top) {
            Cyber.bg.ignoresSafeArea()

            videoBackdrop
            scanlineOverlay
            CyberGrid().opacity(0.18).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                bottomDeck
            }
        }
        .onAppear {
            setupPlayer()
            Task {
                loadingOfferings = true
                await rc.fetchOfferings()
                loadingOfferings = false
            }
        }
        .onChange(of: vrm.currentCharacter?.id) { _, _ in setupPlayer() }
        .onChange(of: vrm.currentCostume?.id) { _, _ in setupPlayer() }
        .onChange(of: rc.isProUser) { _, isPro in
            // Auto-dismiss if the user becomes Pro (purchase or restore).
            if isPro { onClose() }
        }
        .onDisappear { player?.pause(); player = nil }
        .preferredColorScheme(.dark)
        .inAppBrowser(url: $browserURL)
        .alert(item: $purchaseAlert) { a in
            Alert(title: Text(a.title), message: Text(a.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Layers

    private var videoBackdrop: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1: poster image as backdrop while video loads.
                if let img = heroCharacter?.thumbnailUrl ?? heroCharacter?.avatar,
                   let url = URL(string: img) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Cyber.bg
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .id(heroCharacter?.id)
                    .transition(.opacity)
                } else {
                    Cyber.bg
                }

                // Layer 2: video covers the whole screen once the first frame is ready.
                if let player, playerReady {
                    FillVideoPlayer(player: player)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                // Bottom-up dark gradient so the deck content stays legible
                // while the hero image/video bleeds full-screen behind it.
                LinearGradient(
                    colors: [.clear, .clear, Cyber.bg.opacity(0.55), Cyber.bg.opacity(0.95)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.25), value: playerReady)
    }

    private var scanlineOverlay: some View {
        VStack(spacing: 3) {
            ForEach(0..<60) { _ in
                Color.white.opacity(0.04).frame(height: 1)
                Color.clear.frame(height: 3)
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Text("//")
                    .font(Cyber.mono(13, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                Text("BONIE_OS  v1.0")
                    .font(Cyber.mono(11, weight: .semibold))
                    .foregroundStyle(Cyber.textDim)
                    .tracking(1)
            }
            Spacer()
            Button(action: onClose) {
                ZStack {
                    Rectangle().fill(Cyber.surface.opacity(0.85))
                    Rectangle().stroke(Cyber.cyan.opacity(0.7), lineWidth: 1)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(Cyber.cyan)
                }
                .frame(width: 38, height: 38)
                .shadow(color: Cyber.cyan.opacity(0.6), radius: 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var bottomDeck: some View {
        VStack(spacing: 18) {
            heroBlock
            perksBlock
            planBlock
            ctaBlock
            footerLinks
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("[ TIER ]")
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .tracking(1.4)
                Text("PRO.UNLIMITED")
                    .font(Cyber.mono(11, weight: .heavy))
                    .foregroundStyle(Cyber.magenta)
                    .tracking(1.2)
                Spacer()
                StatusDot(tint: Cyber.lime)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("STAY")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(Cyber.text)
                Text("WITH//ME")
                    .font(Cyber.mono(28, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .shadow(color: Cyber.cyan.opacity(0.7), radius: 6)
            }
            Text("WITHOUT.LIMITS")
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(Cyber.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var perksBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(perks, id: \.text) { perk in
                HStack(spacing: 10) {
                    Image(systemName: perk.systemImage)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Cyber.cyan)
                        .frame(width: 18)
                    Text("//")
                        .font(Cyber.mono(11, weight: .heavy))
                        .foregroundStyle(Cyber.cyan.opacity(0.6))
                    Text(perk.text)
                        .font(Cyber.mono(11, weight: .semibold))
                        .foregroundStyle(Cyber.text)
                        .tracking(0.8)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Cyber.surface.opacity(0.7))
        .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.4), lineWidth: 1))
        .overlay(CornerBrackets(tint: Cyber.cyan, size: 8))
    }

    private var planBlock: some View {
        HStack(spacing: 10) {
            CyberPlanCard(
                code: planCode(for: .yearly),
                name: planName(for: .yearly),
                price: priceString(for: .yearly),
                period: planPeriod(for: .yearly),
                subDetail: planSubDetail(for: .yearly),
                badge: discountText,
                tint: Cyber.magenta,
                isSelected: selectedPlan == .yearly,
                isLoading: loadingOfferings && yearlyPackage == nil,
                onTap: { selectedPlan = .yearly }
            )
            CyberPlanCard(
                code: planCode(for: .monthly),
                name: planName(for: .monthly),
                price: priceString(for: .monthly),
                period: planPeriod(for: .monthly),
                subDetail: nil,
                badge: nil,
                tint: Cyber.cyan,
                isSelected: selectedPlan == .monthly,
                isLoading: loadingOfferings && monthlyPackage == nil,
                onTap: { selectedPlan = .monthly }
            )
        }
    }

    private var ctaBlock: some View {
        Button {
            handlePurchase()
        } label: {
            ZStack {
                LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .leading, endPoint: .trailing)
                if rc.isPurchasing {
                    ProgressView().tint(Cyber.bg)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "bolt.fill").font(.system(size: 14, weight: .heavy))
                        Text("INITIALIZE PRO//")
                            .font(Cyber.mono(14, weight: .heavy))
                            .tracking(1.4)
                    }
                    .foregroundStyle(Cyber.bg)
                }
            }
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: Cyber.magenta.opacity(0.7), radius: 10)
        }
        .disabled(rc.isPurchasing || selectedPackage == nil)
        .opacity((rc.isPurchasing || selectedPackage == nil) ? 0.55 : 1)
    }

    private var footerLinks: some View {
        HStack(spacing: 12) {
            Button { browserURL = AppConfig.Legal.privacy } label: { footerText(L10n.Cyber.subPrivacy) }
            Text("//").font(Cyber.mono(10, weight: .heavy)).foregroundStyle(Cyber.cyan.opacity(0.5))
            Button { handleRestore() } label: { footerText(L10n.Cyber.subRestore) }
                .disabled(rc.isPurchasing)
            Text("//").font(Cyber.mono(10, weight: .heavy)).foregroundStyle(Cyber.cyan.opacity(0.5))
            Button { browserURL = AppConfig.Legal.terms } label: { footerText(L10n.Cyber.subTerms) }
        }
    }

    private func handlePurchase() {
        guard let package = selectedPackage else {
            purchaseAlert = .init(title: "Unavailable", message: "Subscription plans are still loading. Please try again in a moment.")
            return
        }
        Task {
            let success = await rc.purchase(package: package)
            if !success, let err = rc.lastError {
                purchaseAlert = .init(title: "Purchase failed", message: err)
            }
            // Success path closes the screen via onChange(of: rc.isProUser).
        }
    }

    private func handleRestore() {
        Task {
            let restored = await rc.restorePurchases()
            if restored {
                purchaseAlert = .init(title: "Restored", message: "Your Pro subscription is now active.")
            } else if let err = rc.lastError {
                purchaseAlert = .init(title: "Restore failed", message: err)
            } else {
                purchaseAlert = .init(title: "Nothing to restore", message: "No active subscription was found on this Apple ID.")
            }
        }
    }

    private func footerText(_ s: String) -> some View {
        Text(s)
            .font(Cyber.mono(10, weight: .heavy))
            .foregroundStyle(Cyber.textDim)
            .tracking(1.4)
    }

    private func setupPlayer() {
        guard let url = heroVideoURL else { return }
        playerReady = false
        statusCancellable?.cancel()

        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = true
        p.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in p.seek(to: .zero); p.play() }

        statusCancellable = item.publisher(for: \.status, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { status in
                if status == .readyToPlay { playerReady = true }
            }

        player = p
        p.play()
    }
}

private struct CyberPlanCard: View {
    let code: String
    let name: String
    let price: String
    let period: String
    let subDetail: String?
    let badge: String?
    let tint: Color
    let isSelected: Bool
    var isLoading: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(code)
                        .font(Cyber.mono(9, weight: .heavy))
                        .foregroundStyle(tint)
                        .tracking(1.4)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(Cyber.mono(10, weight: .heavy))
                            .foregroundStyle(Cyber.bg)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(tint)
                    }
                }
                Text(name)
                    .font(Cyber.mono(13, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1.2)
                if isLoading {
                    ProgressView()
                        .tint(tint)
                        .frame(height: 28)
                } else {
                    Text(price)
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(Cyber.text)
                }
                Text(period)
                    .font(Cyber.mono(9, weight: .semibold))
                    .foregroundStyle(Cyber.textDim)
                    .tracking(1)
                if let subDetail {
                    Text(subDetail)
                        .font(Cyber.mono(9, weight: .semibold))
                        .foregroundStyle(tint)
                        .tracking(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? tint.opacity(0.12) : Cyber.surface.opacity(0.78))
            .overlay(Rectangle().stroke(isSelected ? tint : tint.opacity(0.35), lineWidth: isSelected ? 1.5 : 1))
            .overlay(CornerBrackets(tint: tint, size: 8))
            .shadow(color: isSelected ? tint.opacity(0.6) : .clear, radius: isSelected ? 8 : 0)
        }
        .buttonStyle(.plain)
    }
}

/// AVPlayer wrapper that uses `.resizeAspectFill` so the video crops to fill
/// instead of letterboxing. SwiftUI's `VideoPlayer` doesn't expose this.
private struct FillVideoPlayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let v = PlayerView()
        v.playerLayer.player = player
        v.playerLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

private struct CyberGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 32
            let stroke = GraphicsContext.Shading.color(.white.opacity(0.06))
            for x in stride(from: 0, through: size.width, by: step) {
                var p = Path()
                p.move(to: .init(x: x, y: 0))
                p.addLine(to: .init(x: x, y: size.height))
                ctx.stroke(p, with: stroke, lineWidth: 0.5)
            }
            for y in stride(from: 0, through: size.height, by: step) {
                var p = Path()
                p.move(to: .init(x: 0, y: y))
                p.addLine(to: .init(x: size.width, y: y))
                ctx.stroke(p, with: stroke, lineWidth: 0.5)
            }
        }
    }
}
