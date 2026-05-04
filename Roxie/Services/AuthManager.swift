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
    private let client = SupabaseService.shared.client
    private var appleNonce: String?

    private override init() {
        super.init()
        // Wipe any legacy guest flag from older builds — the app no longer
        // supports guest mode and only proceeds past sign-in with a real
        // Supabase session.
        UserDefaults.standard.removeObject(forKey: "persist.guestAcknowledged")
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
            // Identify the restored user to RevenueCat so purchases attribute
            // to the real Supabase UUID instead of `$RCAnonymousID:...`.
            await RevenueCatManager.shared.login(userId: session.user.id.uuidString.lowercased())
        } catch {
            Log.auth.info("No existing session: \(error.localizedDescription)")
        }
        self.hasRestoredSession = true
    }

    // MARK: - Apple Sign-In

    /// Configure an `ASAuthorizationAppleIDRequest` produced by SwiftUI's
    /// `SignInWithAppleButton`. Generates a fresh nonce, hashes it, and
    /// stores the raw nonce for later token verification.
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        self.appleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Handle the result of `SignInWithAppleButton`'s authorization flow.
    func handleAppleResult(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let authorization = try result.get()
            try await completeAppleSignIn(authorization: authorization)
        } catch let error as ASAuthorizationError where error.code == .canceled {
            Log.auth.info("Apple sign-in cancelled")
        } catch {
            Log.auth.error("Apple sign-in failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    private func completeAppleSignIn(authorization: ASAuthorization) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Log.auth.error("Apple credential not ASAuthorizationAppleIDCredential — got \(type(of: authorization.credential))")
            errorMessage = "Không lấy được Apple credential"
            return
        }
        Log.auth.info("Apple credential userID=\(credential.user, privacy: .public) hasToken=\(credential.identityToken != nil) hasAuthCode=\(credential.authorizationCode != nil) email=\(credential.email ?? "nil", privacy: .public)")
        guard let tokenData = credential.identityToken else {
            Log.auth.error("Apple identityToken is nil — likely Sign In with Apple capability not enabled on the App ID, or simulator has no Apple ID signed in")
            errorMessage = "Apple chưa cấp identity token. Kiểm tra lại Sign In with Apple capability trên App ID, hoặc đăng nhập Apple ID trong Settings của simulator/device."
            return
        }
        guard let tokenString = String(data: tokenData, encoding: .utf8) else {
            Log.auth.error("identityToken data is not UTF-8")
            errorMessage = "Apple identity token không hợp lệ"
            return
        }
        guard let nonce = appleNonce else {
            Log.auth.error("appleNonce was not set before authorization — race condition")
            errorMessage = "Phiên đăng nhập Apple đã hết hạn, thử lại"
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
        // Identify the freshly-authenticated user to RevenueCat so any
        // purchase / customerInfo write attributes to this UUID rather than
        // the previously-generated `$RCAnonymousID:...`. Called from every
        // sign-in path (Apple/Google/email/sign-up) that lands here.
        await RevenueCatManager.shared.login(userId: userId.lowercased())

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
