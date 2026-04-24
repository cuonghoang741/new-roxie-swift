import Foundation

enum UserPreferencesService {
    private static let defaults = UserDefaults.standard

    static var ageVerified18: Bool {
        get { defaults.string(forKey: PersistKeys.ageVerified18) == "true" }
        set { defaults.set(newValue ? "true" : "false", forKey: PersistKeys.ageVerified18) }
    }

    static var hasCompletedOnboardingV2: Bool {
        get { defaults.string(forKey: PersistKeys.hasCompletedOnboardingV2) == "true" }
        set { defaults.set(newValue ? "true" : "false", forKey: PersistKeys.hasCompletedOnboardingV2) }
    }

    static var autoPlayMusic: Bool {
        get { defaults.object(forKey: "settings.autoPlayMusic") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "settings.autoPlayMusic") }
    }

    static var hapticsEnabled: Bool {
        get { defaults.object(forKey: "settings.hapticsEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "settings.hapticsEnabled") }
    }

    static var enableNSFW: Bool {
        get { defaults.bool(forKey: "settings.enableNSFW") }
        set { defaults.set(newValue, forKey: "settings.enableNSFW") }
    }
}
