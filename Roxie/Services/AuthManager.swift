import Foundation
import AuthenticationServices
import Supabase

@MainActor
@Observable
final class AuthManager: NSObject {
    static let shared = AuthManager()

    private(set) var session: Session?
    private(set) var user: User?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var hasRestoredSession: Bool = false
    private(set) var isDeletingAccount: Bool = false
    private(set) var isNewUser: Bool?
    /// Whether the user has explicitly chosen to continue as guest. We use
    /// this (rather than "clientId exists") to decide if the sign-in screen
    /// should be shown — otherwise we'd bypass sign-in on the very first
    /// launch because a clientId is minted eagerly for Supabase.
    var guestAcknowledged: Bool {
        UserDefaults.standard.string(forKey: "persist.guestAcknowledged") == "true"
    }

    private let client = SupabaseService.shared.client
    private var appleNonce: String?

    private override init() {
        super.init()
        Task { await restoreSession() }
    }

    var userId: String? {
        user?.id.uuidString.lowercased()
    }

    var isSignedIn: Bool { session != nil }

    func restoreSession() async {
        do {
            let session = try await client.auth.session
            self.session = session
            self.user = session.user
        } catch {
            Log.auth.info("No existing session: \(error.localizedDescription)")
        }
        self.hasRestoredSession = true
    }

    // MARK: - Apple Sign-In

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let nonce = randomNonceString()
            let hashedNonce = sha256(nonce)
            self.appleNonce = nonce

            let authorization = try await requestAppleAuthorization(hashedNonce: hashedNonce)
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let tokenString = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Không lấy được Apple identity token"
                return
            }

            let newSession = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: tokenString,
                    nonce: nonce
                )
            )
            self.session = newSession
            self.user = newSession.user
            await checkUserStatus(userId: newSession.user.id.uuidString)
        } catch let error as ASAuthorizationError where error.code == .canceled {
            Log.auth.info("Apple sign-in cancelled")
        } catch {
            Log.auth.error("Apple sign-in failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Google Sign-In (OAuth via ASWebAuthenticationSession)

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let redirectURL = AppConfig.authRedirectURL
            let oauthURL = try client.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: redirectURL
            )

            let callbackURL = try await presentWebAuth(authURL: oauthURL, callbackScheme: AppConfig.appScheme)
            try await client.auth.session(from: callbackURL)
            let refreshed = try await client.auth.session
            self.session = refreshed
            self.user = refreshed.user
            await checkUserStatus(userId: refreshed.user.id.uuidString)
        } catch {
            Log.auth.error("Google sign-in failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Email

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await client.auth.signIn(email: email, password: password)
            self.session = session
            self.user = session.user
            await checkUserStatus(userId: session.user.id.uuidString)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await client.auth.signUp(email: email, password: password)
            self.session = response.session
            self.user = response.user
            await checkUserStatus(userId: response.user.id.uuidString)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await client.auth.signOut()
            self.session = nil
            self.user = nil
            self.isNewUser = nil
            // Reset guest + onboarding flags so the user lands back on
            // SignInScreen (matches the RN behavior).
            UserDefaults.standard.removeObject(forKey: "persist.guestAcknowledged")
            UserDefaults.standard.removeObject(forKey: "persist.hasClaimedNewUserGift")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Wipe the user's data from Supabase tables, clear local persistence,
    /// then sign out. Mirrors `deleteAccountLocally` from the RN AuthManager.
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let userId = user?.id.uuidString.lowercased()
        let clientId = userId == nil ? ClientIdStore.ensureClientId() : nil

        let tables = [
            "relationship_milestones", "character_relationship", "level_up_rewards",
            "user_daily_quests", "user_level_quests", "user_login_rewards",
            "user_streaks", "user_medals", "user_character", "user_stats",
            "user_currency", "user_assets", "transactions", "purchases",
            "subscriptions", "user_preferences", "api_characters", "conversation",
            "app_feedback", "calls", "scheduled_notifications",
            "user_notification_preferences", "spicy_content_notifications",
            "notification_counters", "user_call_quota",
            "custom_character_requests", "user_background",
        ]
        let skipClientId: Set<String> = ["api_characters", "subscriptions", "user_call_quota"]

        for table in tables {
            do {
                let q = client.from(table).delete()
                if let userId {
                    var query = q.eq("user_id", value: userId)
                    if !skipClientId.contains(table) {
                        query = query.is("client_id", value: nil)
                    }
                    _ = try await query.execute()
                } else if let clientId {
                    _ = try await q.eq("client_id", value: clientId).is("user_id", value: nil).execute()
                }
            } catch {
                Log.auth.warning("delete \(table) failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        // Wipe all local UserDefaults keys we own.
        for key in [
            PersistKeys.characterId, PersistKeys.modelName, PersistKeys.modelURL,
            PersistKeys.backgroundURL, PersistKeys.backgroundName,
            PersistKeys.backgroundSelections, PersistKeys.costumeSelections,
            PersistKeys.hasRatedApp, PersistKeys.lastReviewPromptAt,
            PersistKeys.ageVerified18, PersistKeys.hasCompletedOnboardingV2,
            PersistKeys.isNewUser,
            "settings.autoPlayMusic", "settings.hapticsEnabled", "settings.enableNSFW",
            "persist.guestAcknowledged", "persist.hasClaimedNewUserGift",
        ] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        ClientIdStore.clearClientId()

        await RevenueCatManager.shared.logout()
        await OneSignalService.shared.removeExternalUserId()
        await logout()
    }

    func continueAsGuest() {
        _ = ClientIdStore.ensureClientId()
        UserDefaults.standard.set("true", forKey: "persist.guestAcknowledged")
        // Trigger an @Observable re-render by touching a published field.
        self.hasRestoredSession = true
    }

    func updateDisplayName(_ name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try await client.auth.update(user: UserAttributes(data: ["display_name": .string(trimmed)]))
            let refreshed = try await client.auth.session
            self.session = refreshed
            self.user = refreshed.user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateBirthYear(_ year: Int) async {
        guard year >= 1900, year <= 2100 else { return }
        do {
            try await client.auth.update(user: UserAttributes(data: ["birth_year": .string(String(year))]))
            let refreshed = try await client.auth.session
            self.session = refreshed
            self.user = refreshed.user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkUserStatus(userId: String) async {
        do {
            let count = try await AssetRepository().countOwned(itemType: "character", userId: userId)
            let isNew = count == 0
            self.isNewUser = isNew
            UserDefaults.standard.set(isNew ? "true" : "false", forKey: PersistKeys.isNewUser)
            if !isNew {
                UserDefaults.standard.set("true", forKey: PersistKeys.hasCompletedOnboardingV2)
            }
        } catch {
            Log.auth.warning("checkUserStatus failed: \(error.localizedDescription)")
            self.isNewUser = false
        }
    }

    // MARK: - Apple helpers

    private func requestAppleAuthorization(hashedNonce: String) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { cont in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleAuthDelegate(continuation: cont)
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            AppleAuthDelegate.retain(delegate)
            controller.performRequests()
        }
    }

    // MARK: - OAuth helpers

    private func presentWebAuth(authURL: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { url, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                guard let url else {
                    cont.resume(throwing: URLError(.badURL))
                    return
                }
                cont.resume(returning: url)
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = WebAuthPresentationContextProvider.shared
            session.start()
        }
    }
}

private final class AppleAuthDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private static var retained: [AppleAuthDelegate] = []

    static func retain(_ delegate: AppleAuthDelegate) {
        retained.append(delegate)
    }

    private static func release(_ delegate: AppleAuthDelegate) {
        retained.removeAll { $0 === delegate }
    }

    private let continuation: CheckedContinuation<ASAuthorization, Error>

    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
        Self.release(self)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
        Self.release(self)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        WebAuthPresentationContextProvider.shared.anchor()
    }
}

final class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor()
    }

    func anchor() -> ASPresentationAnchor {
        #if canImport(UIKit)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
            ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}

// MARK: - Nonce helpers

import CryptoKit

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    while remainingLength > 0 {
        var randoms = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
        precondition(status == errSecSuccess)
        for random in randoms {
            if remainingLength == 0 { break }
            if random < charset.count {
                result.append(charset[Int(random) % charset.count])
                remainingLength -= 1
            }
        }
    }
    return result
}

private func sha256(_ input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA256.hash(data: data)
    return hash.map { String(format: "%02x", $0) }.joined()
}

#if canImport(UIKit)
import UIKit
#endif
