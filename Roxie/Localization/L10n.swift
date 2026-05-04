import Foundation
import SwiftUI

/// Centralized localization keys for the whole app. Keep this in sync with
/// `*.lproj/Localizable.strings`. Using an enum makes key renames a compile
/// error instead of a silent fallback to the raw key.
enum L10n {
    // Common
    static var close: String { localized("common.close") }
    static var cancel: String { localized("common.cancel") }
    static var save: String { localized("common.save") }
    static var done: String { localized("common.done") }
    static var loading: String { localized("common.loading") }
    static var retry: String { localized("common.retry") }
    static var ok: String { localized("common.ok") }
    static var continueAction: String { localized("common.continue") }
    static var finish: String { localized("common.finish") }
    static var skip: String { localized("common.skip") }

    // Auth / Sign in
    static var appTagline: String { localized("auth.tagline") }
    static var welcomeTitle: String { localized("auth.welcome_title") }
    static var welcomeSubtitle: String { localized("auth.welcome_subtitle") }
    static var signInWithApple: String { localized("auth.sign_in_apple") }
    static var signInWithGoogle: String { localized("auth.sign_in_google") }
    static var continueAsGuest: String { localized("auth.continue_guest") }
    static var termsLink: String { localized("auth.terms") }
    static var privacyLink: String { localized("auth.privacy") }
    static var eulaLink: String { localized("auth.eula") }
    static var ageVerifyTitle: String { localized("auth.age_title") }
    static var ageVerifyBody: String { localized("auth.age_body") }
    static var ageVerifyConfirm: String { localized("auth.age_confirm") }

    // Onboarding
    static var onboardingSlide1Title: String { localized("onboarding.slide1.title") }
    static var onboardingSlide1Body: String { localized("onboarding.slide1.body") }
    static var onboardingSlide2Title: String { localized("onboarding.slide2.title") }
    static var onboardingSlide2Body: String { localized("onboarding.slide2.body") }
    static var onboardingSlide3Title: String { localized("onboarding.slide3.title") }
    static var onboardingSlide3Body: String { localized("onboarding.slide3.body") }
    static var onboardingStart: String { localized("onboarding.start") }
    static var onboardingNext: String { localized("onboarding.next") }
    static var giftTitle: String { localized("onboarding.gift_title") }
    static var giftBody: String { localized("onboarding.gift_body") }
    static var giftClaim: String { localized("onboarding.gift_claim") }
    static var profileTitle: String { localized("onboarding.profile_title") }
    static var profileSubtitle: String { localized("onboarding.profile_subtitle") }
    static var displayName: String { localized("onboarding.display_name") }
    static var displayNamePlaceholder: String { localized("onboarding.display_name_placeholder") }
    static var birthYear: String { localized("onboarding.birth_year") }
    static var birthYearPlaceholder: String { localized("onboarding.birth_year_placeholder") }
    static var characterPicked: String { localized("onboarding.character_picked") }
    static var saving: String { localized("onboarding.saving") }

    // Character preview
    static var chooseCharacter: String { localized("character.choose") }
    static var pick: String { localized("character.pick") }
    static var viewDetail: String { localized("character.view_detail") }
    static var loadingCharacters: String { localized("character.loading") }

    // Experience / sheets
    static var subscriptionTitle: String { localized("subscription.title") }
    static var subscriptionBody: String { localized("subscription.body") }
    static var subscriptionCta: String { localized("subscription.cta") }
    static var sheetBackgrounds: String { localized("sheet.backgrounds") }
    static var sheetCharacters: String { localized("sheet.characters") }
    static var sheetCostumes: String { localized("sheet.costumes") }
    static var sheetQuests: String { localized("sheet.quests") }
    static var sheetEnergy: String { localized("sheet.energy") }
    static var sheetLevel: String { localized("sheet.level") }
    static var sheetStreak: String { localized("sheet.streak") }
    static var sheetRubyPurchase: String { localized("sheet.ruby_purchase") }
    static var sheetSettings: String { localized("sheet.settings") }
    static var questDaily: String { localized("sheet.quest_daily") }
    static var noCostumes: String { localized("sheet.no_costumes") }
    static var owned: String { localized("sheet.owned") }
    static var guestLabel: String { localized("settings.guest") }
    static var signOut: String { localized("settings.sign_out") }
    static var sectionAccount: String { localized("settings.section_account") }
    static var sectionInfo: String { localized("settings.section_info") }

    // Delete account
    static var deleteAccount: String { localized("delete.account") }
    static var deleteCancel: String { localized("delete.cancel") }
    static var deleteConfirmMessage: String { localized("delete.confirm_message") }
    static var deleteContinue: String { localized("delete.continue") }
    static var deleteProWarningTitle: String { localized("delete.pro_warning_title") }
    static var deleteProWarningBody: String { localized("delete.pro_warning_body") }
    static var deleteOpenAppStore: String { localized("delete.open_app_store") }
    static var deleteServerFailed: String { localized("delete.server_failed") }
    static var initializing: String { localized("experience.initializing") }

    // Chat
    static var chatInputPlaceholder: String { localized("chat.input_placeholder") }
    static var chatHistoryTitle: String { localized("chat.history_title") }
    static var chatEmptyHint: String { localized("chat.empty_hint") }
    static var chatLoadMore: String { localized("chat.load_more") }
    static var chatTyping: String { localized("chat.typing") }
    static var chatDateToday: String { localized("chat.date_today") }
    static var chatDateYesterday: String { localized("chat.date_yesterday") }
    static var chatUpgradePro: String { localized("chat.upgrade_pro") }
    static var chatCallStarted: String { localized("chat.call_started") }
    static var chatCallEnded: String { localized("chat.call_ended") }

    // Errors
    static var errorLoad: String { localized("error.load") }
    static var errorNetwork: String { localized("error.network") }

    // Cyber UI labels (kept short — these appear inside the cyber HUD chrome)
    enum Cyber {
        static var online: String { localized("cyber.online") }
        static var live: String { localized("cyber.live") }
        static var connecting: String { localized("cyber.connecting") }
        static var establishingLink: String { localized("cyber.establishing_link") }
        static var booting: String { localized("cyber.booting") }
        static var initializing: String { localized("cyber.initializing") }

        static var actionCapture: String { localized("cyber.action.capture") }
        static var actionSend: String { localized("cyber.action.send") }
        static var actionDance: String { localized("cyber.action.dance") }
        static var actionStop: String { localized("cyber.action.stop") }
        static var actionEnd: String { localized("cyber.action.end") }

        static var inputPlaceholder: String { localized("cyber.input_placeholder") }

        // Sheet titles
        static var sheetCompanions: String { localized("cyber.sheet.companions") }
        static var sheetCompanionsSub: String { localized("cyber.sheet.companions_sub") }
        static var sheetEnvironments: String { localized("cyber.sheet.environments") }
        static var sheetEnvironmentsSub: String { localized("cyber.sheet.environments_sub") }
        static var sheetOutfits: String { localized("cyber.sheet.outfits") }
        static var sheetOutfitsSub: String { localized("cyber.sheet.outfits_sub") }
        static var sheetChoreo: String { localized("cyber.sheet.choreo") }
        static var sheetChoreoSub: String { localized("cyber.sheet.choreo_sub") }
        static var sheetVault: String { localized("cyber.sheet.vault") }
        static var sheetVaultSub: String { localized("cyber.sheet.vault_sub") }
        static var sheetSettings: String { localized("cyber.sheet.settings") }
        static var sheetLanguage: String { localized("cyber.sheet.language") }
        static var sheetLanguageSub: String { localized("cyber.sheet.language_sub") }
        static var sheetProfile: String { localized("cyber.sheet.profile") }
        static var sheetProfileSub: String { localized("cyber.sheet.profile_sub") }
        static var sheetFeedback: String { localized("cyber.sheet.feedback") }
        static var sheetFeedbackSub: String { localized("cyber.sheet.feedback_sub") }
        static var sheetChatLog: String { localized("cyber.sheet.chat_log") }

        static var stopRoutine: String { localized("cyber.stop_routine") }
        static var proOnly: String { localized("cyber.pro_only") }
        static var proRequired: String { localized("cyber.pro_required") }
        static var owned: String { localized("cyber.owned") }
        static var free: String { localized("cyber.free") }
        static var emptyOutfits: String { localized("cyber.empty_outfits") }
        static var emptyVault: String { localized("cyber.empty_vault") }
        static var logEmpty: String { localized("cyber.log_empty") }
        static var loadMore: String { localized("cyber.load_more") }
        static var loadingArchive: String { localized("cyber.loading_archive") }
        static var loadingRoster: String { localized("cyber.loading_roster") }
        static var loadingModel: String { localized("cyber.loading_model") }
        static var archiveCount: String { localized("cyber.archive_count") } // %d entries

        // Subscription
        static var subTier: String { localized("cyber.sub.tier") }
        static var subProUnlimited: String { localized("cyber.sub.pro_unlimited") }
        static var subTitle1: String { localized("cyber.sub.title_1") } // STAY
        static var subTitle2: String { localized("cyber.sub.title_2") } // WITH//ME
        static var subTitle3: String { localized("cyber.sub.title_3") } // WITHOUT.LIMITS
        static var subPerk1: String { localized("cyber.sub.perk_1") }
        static var subPerk2: String { localized("cyber.sub.perk_2") }
        static var subPerk3: String { localized("cyber.sub.perk_3") }
        static var subPerk4: String { localized("cyber.sub.perk_4") }
        static var subPerk5: String { localized("cyber.sub.perk_5") }
        static var subPerk6: String { localized("cyber.sub.perk_6") }
        static var subAnnual: String { localized("cyber.sub.annual") }
        static var subMonthly: String { localized("cyber.sub.monthly") }
        static var subPerYear: String { localized("cyber.sub.per_year") }
        static var subPerMonth: String { localized("cyber.sub.per_month") }
        static var subInitialize: String { localized("cyber.sub.initialize") }
        static var subPrivacy: String { localized("cyber.sub.privacy") }
        static var subRestore: String { localized("cyber.sub.restore") }
        static var subTerms: String { localized("cyber.sub.terms") }

        // Settings
        static var settingsAccountSection: String { localized("cyber.settings.account_section") }
        static var settingsPreferencesSection: String { localized("cyber.settings.preferences_section") }
        static var settingsLegalSection: String { localized("cyber.settings.legal_section") }
        static var settingsSubscription: String { localized("cyber.settings.subscription") }
        static var settingsEditProfile: String { localized("cyber.settings.edit_profile") }
        static var settingsNotifications: String { localized("cyber.settings.notifications") }
        static var settingsAutoMusic: String { localized("cyber.settings.auto_music") }
        static var settingsHaptics: String { localized("cyber.settings.haptics") }
        static var settingsNSFW: String { localized("cyber.settings.nsfw") }
        static var settingsLanguage: String { localized("cyber.settings.language") }
        static var settingsTerms: String { localized("cyber.settings.terms") }
        static var settingsPrivacy: String { localized("cyber.settings.privacy") }
        static var settingsEula: String { localized("cyber.settings.eula") }
        static var settingsRate: String { localized("cyber.settings.rate") }
        static var settingsReport: String { localized("cyber.settings.report") }
        static var settingsProActive: String { localized("cyber.settings.pro_active") }
        static var settingsInitPro: String { localized("cyber.settings.init_pro") }
        static var settingsFullAccess: String { localized("cyber.settings.full_access") }
        static var settingsUnlockFalse: String { localized("cyber.settings.unlock_false") }
        static var settingsDeleteAccount: String { localized("cyber.settings.delete_account") }
        static var settingsIrreversible: String { localized("cyber.settings.irreversible") }
        static var settingsPurging: String { localized("cyber.settings.purging") }
        static var settingsSaveProfile: String { localized("cyber.settings.save_profile") }
        static var settingsAlias: String { localized("cyber.settings.alias") }
        static var settingsEmail: String { localized("cyber.settings.email") }

        // Feedback
        static var feedbackBug: String { localized("cyber.feedback.bug") }
        static var feedbackFeature: String { localized("cyber.feedback.feature") }
        static var feedbackPlaceholder: String { localized("cyber.feedback.placeholder") }
        static var feedbackTransmit: String { localized("cyber.feedback.transmit") }

        // Onboarding
        static var onboardWelcome: String { localized("cyber.onboard.welcome") }
        static var onboardCustomize: String { localized("cyber.onboard.customize") }
        static var onboardConnect: String { localized("cyber.onboard.connect") }
        static var onboardWelcomeBody: String { localized("cyber.onboard.welcome_body") }
        static var onboardCustomizeBody: String { localized("cyber.onboard.customize_body") }
        static var onboardConnectBody: String { localized("cyber.onboard.connect_body") }
        static var onboardSkip: String { localized("cyber.onboard.skip") }
        static var onboardNext: String { localized("cyber.onboard.next") }
        static var onboardInitialize: String { localized("cyber.onboard.initialize") }

        static var giftTitle: String { localized("cyber.gift.title") }
        static var giftClaim: String { localized("cyber.gift.claim") }

        static var profileSetup: String { localized("cyber.profile.setup") }
        static var profileIdentify: String { localized("cyber.profile.identify") }
        static var profileEnterAlias: String { localized("cyber.profile.enter_alias") }
        static var profileBirthHint: String { localized("cyber.profile.birth_hint") }
        static var profileFinalize: String { localized("cyber.profile.finalize") }
        static var profileCompanionLinked: String { localized("cyber.profile.companion_linked") }

        // Char preview
        static var charSelect: String { localized("cyber.char.select") }
        static var charPreview: String { localized("cyber.char.preview") }
        static var charCompanions: String { localized("cyber.char.companions") }
        static var charSelectPartner: String { localized("cyber.char.select_partner") }
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    /// Supported locales – keep in sync with the .lproj folders.
    enum Locale: String, CaseIterable, Identifiable {
        case en, ja, ko
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .en: return "English"
            case .ja: return "日本語"
            case .ko: return "한국어"
            }
        }
    }
}

/// Override the app language at runtime. Persists across launches and uses
/// `LanguageBundle` to swap `NSLocalizedString` results without restart.
enum AppLanguage {
    private static let defaultsKey = "AppleLanguages"
    private static let overrideKey = "app.language_override"

    /// Notification posted whenever the override changes — listened to by
    /// the App root to bump a state id and re-render the SwiftUI tree.
    static let didChange = Notification.Name("AppLanguage.didChange")

    static var current: L10n.Locale {
        if let saved = UserDefaults.standard.string(forKey: overrideKey),
           let locale = L10n.Locale(rawValue: saved) {
            return locale
        }
        let code = Foundation.Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        return L10n.Locale(rawValue: String(code)) ?? .en
    }

    /// Apply on app launch so subsequent `NSLocalizedString` lookups use the
    /// stored override before any view renders.
    static func bootstrap() {
        let saved = UserDefaults.standard.string(forKey: overrideKey)
        LanguageBundle.apply(saved)
    }

    static func set(_ locale: L10n.Locale) {
        UserDefaults.standard.set(locale.rawValue, forKey: overrideKey)
        UserDefaults.standard.set([locale.rawValue], forKey: defaultsKey)
        UserDefaults.standard.synchronize()
        LanguageBundle.apply(locale.rawValue)
        NotificationCenter.default.post(name: didChange, object: nil)
    }
}
