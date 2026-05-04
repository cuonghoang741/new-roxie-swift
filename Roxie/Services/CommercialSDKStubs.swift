import Foundation

/// Placeholder wrappers for the 3rd-party SDKs the RN app talks to. They
/// currently log only so the Swift port compiles + runs without pulling in
/// the real SDKs. Swap each `log(…)` call with the real SDK invocation when
/// you wire up OneSignal / Firebase / AppsFlyer / Facebook.

// RevenueCatManager moved to its own file: Services/RevenueCatManager.swift

final class OneSignalService {
    static let shared = OneSignalService()
    private init() {}

    func initialize() {
        Log.app.info("[onesignal] initialize (stub)")
    }

    func setExternalUserId(_ id: String) async {
        Log.app.info("[onesignal] setExternalUserId \(id, privacy: .public)")
    }

    func removeExternalUserId() async {
        Log.app.info("[onesignal] removeExternalUserId")
    }
}

final class AppsFlyerService {
    static let shared = AppsFlyerService()
    private init() {}

    func initialize() {
        Log.app.info("[appsflyer] initialize (stub)")
    }

    func logEvent(_ name: String, values: [String: Any] = [:]) {
        Log.app.info("[appsflyer] event \(name) \(values.description, privacy: .public)")
    }
}

final class FacebookService {
    static let shared = FacebookService()
    private init() {}

    func initialize() {
        Log.app.info("[facebook] initialize (stub)")
    }

    func logEvent(_ name: String, parameters: [String: Any] = [:]) {
        Log.app.info("[facebook] event \(name)")
    }
}

final class TikTokService {
    static let shared = TikTokService()
    private init() {}

    func initialize() {
        Log.app.info("[tiktok] initialize (stub)")
    }
}

final class FirebaseService {
    static let shared = FirebaseService()
    private init() {}

    func configure() {
        Log.app.info("[firebase] configure (stub)")
    }
}
