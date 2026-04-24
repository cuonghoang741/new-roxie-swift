import Foundation

enum AppConfig {
    static let supabaseURL = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"]
        ?? "https://cjtghurczxqheqwegpiy.supabase.co")!

    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqdGdodXJjenhxaGVxd2VncGl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzODAwMTAsImV4cCI6MjA3ODk1NjAxMH0.l2IvbVrPipNQpGxQrRNCBRDfxyZCOO756PNFABYPOCQ"

    static let appScheme = "roxieswift"
    static let authRedirectPath = "auth/callback"
    static var authRedirectURL: URL {
        URL(string: "\(appScheme)://\(authRedirectPath)")!
    }

    enum Legal {
        static let terms = URL(string: "https://roxie-terms-privacy-hub.lovable.app/terms")!
        static let privacy = URL(string: "https://roxie-terms-privacy-hub.lovable.app/privacy")!
        static let eula = URL(string: "https://roxie-terms-privacy-hub.lovable.app/eula")!
    }
}

enum PersistKeys {
    static let characterId = "persist.characterId"
    static let modelName = "persist.modelName"
    static let modelURL = "persist.modelURL"
    static let backgroundURL = "persist.backgroundURL"
    static let backgroundName = "persist.backgroundName"
    static let backgroundSelections = "persist.backgroundSelections"
    static let costumeSelections = "persist.costumeSelections"
    static let clientId = "persist.clientId"
    static let hasRatedApp = "persist.hasRatedApp"
    static let lastReviewPromptAt = "persist.lastReviewPromptAt"
    static let ageVerified18 = "persist.ageVerified18"
    static let hasCompletedOnboardingV2 = "persist.hasCompletedOnboardingV2"
    static let isNewUser = "isNewUser"
}
