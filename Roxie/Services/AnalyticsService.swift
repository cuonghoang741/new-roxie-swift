import Foundation

/// Lightweight analytics stub. The RN version wires up Firebase Analytics,
/// AppsFlyer, Facebook and TikTok; we log the same event names locally so
/// a real integration can be dropped in later.
enum AnalyticsEvents {
    static let signIn = "sign_in"
    static let signOut = "sign_out"
    static let deleteAccount = "delete_account"
    static let openSheet = "open_sheet"
    static let purchase = "purchase"
    static let startVoiceCall = "start_voice_call"
    static let endVoiceCall = "end_voice_call"
    static let characterSelected = "character_selected"
    static let backgroundSelected = "background_selected"
    static let costumeSelected = "costume_selected"
}

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    private var userId: String?

    func setUserId(_ id: String?) {
        userId = id
    }

    func log(_ name: String, params: [String: Any] = [:]) {
        Log.app.info("[analytics] \(name) params=\(params.description, privacy: .public) uid=\(self.userId ?? "-", privacy: .public)")
    }

    func logSignIn(method: String) {
        log(AnalyticsEvents.signIn, params: ["method": method])
    }

    func logSignOut() {
        log(AnalyticsEvents.signOut)
    }
}
