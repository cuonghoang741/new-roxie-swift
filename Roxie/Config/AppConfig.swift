import Foundation

enum AppConfig {
    static let supabaseURL = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"]
        ?? "https://nysfrunajmmaoqtppowb.supabase.co")!

    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        ?? "sb_publishable_MttiEDMo_A6uxEBx1sqkhg_qX6y79sy"

    static let appScheme = "bonie"
    static let authRedirectPath = "auth/callback"
    static var authRedirectURL: URL {
        URL(string: "\(appScheme)://\(authRedirectPath)")!
    }

    /// RevenueCat public iOS API key. Get from RevenueCat dashboard →
    /// Project Settings → API keys → "Public app-specific" (iOS), prefix `appl_`.
    /// Override at run-time via env var `REVENUECAT_API_KEY` for builds without
    /// the key baked in.
    static let revenueCatAPIKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"]
        ?? "appl_aCCQNfQZVWWNlqjWANUqDSeeKxj"

    /// RevenueCat entitlement identifier that gates Pro features. Must match
    /// the entitlement name configured in the RevenueCat dashboard exactly,
    /// including casing and any whitespace.
    static let revenueCatProEntitlement = "Bonie Pro"

    /// App Store product identifiers for the Pro subscription. Configured in
    /// App Store Connect and linked into the RevenueCat default offering.
    /// Used as a fallback lookup when the package identifier in the dashboard
    /// isn't `$rc_annual` / `$rc_monthly`.
    enum ProProductID {
        static let yearly  = "bonie.pro.yearly"
        static let monthly = "bonie.pro.monthly"
    }

    enum Legal {
        static let terms = URL(string: "https://bonie-pink-heart-web.lovable.app/terms")!
        static let privacy = URL(string: "https://bonie-pink-heart-web.lovable.app/privacy")!
        static let eula = URL(string: "https://bonie-pink-heart-web.lovable.app/eula")!
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
