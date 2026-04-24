import SwiftUI

@main
struct RoxieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var auth = AuthManager.shared
    @State private var vrm = VRMContext()
    @State private var root = AppRootModel()
    @State private var chat = ChatManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(vrm)
                .environment(root)
                .environment(chat)
                .onOpenURL { url in
                    Log.app.info("open url: \(url.absoluteString, privacy: .public)")
                }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseService.shared.configure()
        OneSignalService.shared.initialize()
        AppsFlyerService.shared.initialize()
        FacebookService.shared.initialize()
        TikTokService.shared.initialize()
        RevenueCatManager.shared.configure(userId: AuthManager.shared.userId)
        _ = ClientIdStore.ensureClientId()
        return true
    }
}
