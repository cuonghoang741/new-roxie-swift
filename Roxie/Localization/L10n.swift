import Foundation
import SwiftUI

/// Centralized localization keys for the whole app. Keep this in sync with
/// `*.lproj/Localizable.strings`. Using an enum makes key renames a compile
/// error instead of a silent fallback to the raw key.
enum L10n {
    // Common
    static let close = localized("common.close")
    static let cancel = localized("common.cancel")
    static let save = localized("common.save")
    static let done = localized("common.done")
    static let loading = localized("common.loading")
    static let retry = localized("common.retry")
    static let ok = localized("common.ok")
    static let continueAction = localized("common.continue")
    static let finish = localized("common.finish")
    static let skip = localized("common.skip")

    // Auth / Sign in
    static let appTagline = localized("auth.tagline")
    static let welcomeTitle = localized("auth.welcome_title")
    static let welcomeSubtitle = localized("auth.welcome_subtitle")
    static let signInWithApple = localized("auth.sign_in_apple")
    static let signInWithGoogle = localized("auth.sign_in_google")
    static let continueAsGuest = localized("auth.continue_guest")
    static let termsLink = localized("auth.terms")
    static let privacyLink = localized("auth.privacy")
    static let eulaLink = localized("auth.eula")
    static let ageVerifyTitle = localized("auth.age_title")
    static let ageVerifyBody = localized("auth.age_body")
    static let ageVerifyConfirm = localized("auth.age_confirm")

    // Onboarding
    static let onboardingSlide1Title = localized("onboarding.slide1.title")
    static let onboardingSlide1Body = localized("onboarding.slide1.body")
    static let onboardingSlide2Title = localized("onboarding.slide2.title")
    static let onboardingSlide2Body = localized("onboarding.slide2.body")
    static let onboardingSlide3Title = localized("onboarding.slide3.title")
    static let onboardingSlide3Body = localized("onboarding.slide3.body")
    static let onboardingStart = localized("onboarding.start")
    static let onboardingNext = localized("onboarding.next")
    static let giftTitle = localized("onboarding.gift_title")
    static let giftBody = localized("onboarding.gift_body")
    static let giftClaim = localized("onboarding.gift_claim")
    static let profileTitle = localized("onboarding.profile_title")
    static let profileSubtitle = localized("onboarding.profile_subtitle")
    static let displayName = localized("onboarding.display_name")
    static let displayNamePlaceholder = localized("onboarding.display_name_placeholder")
    static let birthYear = localized("onboarding.birth_year")
    static let birthYearPlaceholder = localized("onboarding.birth_year_placeholder")
    static let characterPicked = localized("onboarding.character_picked")
    static let saving = localized("onboarding.saving")

    // Character preview
    static let chooseCharacter = localized("character.choose")
    static let pick = localized("character.pick")
    static let viewDetail = localized("character.view_detail")
    static let loadingCharacters = localized("character.loading")

    // Experience / sheets
    static let subscriptionTitle = localized("subscription.title")
    static let subscriptionBody = localized("subscription.body")
    static let subscriptionCta = localized("subscription.cta")
    static let sheetBackgrounds = localized("sheet.backgrounds")
    static let sheetCharacters = localized("sheet.characters")
    static let sheetCostumes = localized("sheet.costumes")
    static let sheetQuests = localized("sheet.quests")
    static let sheetEnergy = localized("sheet.energy")
    static let sheetLevel = localized("sheet.level")
    static let sheetStreak = localized("sheet.streak")
    static let sheetRubyPurchase = localized("sheet.ruby_purchase")
    static let sheetSettings = localized("sheet.settings")
    static let questDaily = localized("sheet.quest_daily")
    static let noCostumes = localized("sheet.no_costumes")
    static let owned = localized("sheet.owned")
    static let guestLabel = localized("settings.guest")
    static let signOut = localized("settings.sign_out")
    static let sectionAccount = localized("settings.section_account")
    static let sectionInfo = localized("settings.section_info")
    static let initializing = localized("experience.initializing")

    // Chat
    static let chatInputPlaceholder = localized("chat.input_placeholder")
    static let chatHistoryTitle = localized("chat.history_title")
    static let chatEmptyHint = localized("chat.empty_hint")
    static let chatLoadMore = localized("chat.load_more")
    static let chatTyping = localized("chat.typing")
    static let chatDateToday = localized("chat.date_today")
    static let chatDateYesterday = localized("chat.date_yesterday")
    static let chatUpgradePro = localized("chat.upgrade_pro")
    static let chatCallStarted = localized("chat.call_started")
    static let chatCallEnded = localized("chat.call_ended")

    // Errors
    static let errorLoad = localized("error.load")
    static let errorNetwork = localized("error.network")

    // Cyber UI labels (kept short — these appear inside the cyber HUD chrome)
    enum Cyber {
        static let online = localized("cyber.online")
        static let live = localized("cyber.live")
        static let connecting = localized("cyber.connecting")
        static let establishingLink = localized("cyber.establishing_link")
        static let booting = localized("cyber.booting")
        static let initializing = localized("cyber.initializing")

        static let actionCapture = localized("cyber.action.capture")
        static let actionSend = localized("cyber.action.send")
        static let actionDance = localized("cyber.action.dance")
        static let actionStop = localized("cyber.action.stop")
        static let actionEnd = localized("cyber.action.end")

        static let inputPlaceholder = localized("cyber.input_placeholder")

        // Sheet titles
        static let sheetCompanions = localized("cyber.sheet.companions")
        static let sheetCompanionsSub = localized("cyber.sheet.companions_sub")
        static let sheetEnvironments = localized("cyber.sheet.environments")
        static let sheetEnvironmentsSub = localized("cyber.sheet.environments_sub")
        static let sheetOutfits = localized("cyber.sheet.outfits")
        static let sheetOutfitsSub = localized("cyber.sheet.outfits_sub")
        static let sheetChoreo = localized("cyber.sheet.choreo")
        static let sheetChoreoSub = localized("cyber.sheet.choreo_sub")
        static let sheetVault = localized("cyber.sheet.vault")
        static let sheetVaultSub = localized("cyber.sheet.vault_sub")
        static let sheetSettings = localized("cyber.sheet.settings")
        static let sheetLanguage = localized("cyber.sheet.language")
        static let sheetLanguageSub = localized("cyber.sheet.language_sub")
        static let sheetProfile = localized("cyber.sheet.profile")
        static let sheetProfileSub = localized("cyber.sheet.profile_sub")
        static let sheetFeedback = localized("cyber.sheet.feedback")
        static let sheetFeedbackSub = localized("cyber.sheet.feedback_sub")
        static let sheetChatLog = localized("cyber.sheet.chat_log")

        static let stopRoutine = localized("cyber.stop_routine")
        static let proOnly = localized("cyber.pro_only")
        static let proRequired = localized("cyber.pro_required")
        static let owned = localized("cyber.owned")
        static let free = localized("cyber.free")
        static let emptyOutfits = localized("cyber.empty_outfits")
        static let emptyVault = localized("cyber.empty_vault")
        static let logEmpty = localized("cyber.log_empty")
        static let loadMore = localized("cyber.load_more")
        static let loadingArchive = localized("cyber.loading_archive")
        static let loadingRoster = localized("cyber.loading_roster")
        static let archiveCount = localized("cyber.archive_count") // %d entries

        // Subscription
        static let subTier = localized("cyber.sub.tier")
        static let subProUnlimited = localized("cyber.sub.pro_unlimited")
        static let subTitle1 = localized("cyber.sub.title_1") // STAY
        static let subTitle2 = localized("cyber.sub.title_2") // WITH//ME
        static let subTitle3 = localized("cyber.sub.title_3") // WITHOUT.LIMITS
        static let subPerk1 = localized("cyber.sub.perk_1")
        static let subPerk2 = localized("cyber.sub.perk_2")
        static let subPerk3 = localized("cyber.sub.perk_3")
        static let subPerk4 = localized("cyber.sub.perk_4")
        static let subPerk5 = localized("cyber.sub.perk_5")
        static let subPerk6 = localized("cyber.sub.perk_6")
        static let subAnnual = localized("cyber.sub.annual")
        static let subMonthly = localized("cyber.sub.monthly")
        static let subPerYear = localized("cyber.sub.per_year")
        static let subPerMonth = localized("cyber.sub.per_month")
        static let subInitialize = localized("cyber.sub.initialize")
        static let subPrivacy = localized("cyber.sub.privacy")
        static let subRestore = localized("cyber.sub.restore")
        static let subTerms = localized("cyber.sub.terms")

        // Settings
        static let settingsAccountSection = localized("cyber.settings.account_section")
        static let settingsPreferencesSection = localized("cyber.settings.preferences_section")
        static let settingsLegalSection = localized("cyber.settings.legal_section")
        static let settingsSubscription = localized("cyber.settings.subscription")
        static let settingsEditProfile = localized("cyber.settings.edit_profile")
        static let settingsNotifications = localized("cyber.settings.notifications")
        static let settingsAutoMusic = localized("cyber.settings.auto_music")
        static let settingsHaptics = localized("cyber.settings.haptics")
        static let settingsNSFW = localized("cyber.settings.nsfw")
        static let settingsLanguage = localized("cyber.settings.language")
        static let settingsTerms = localized("cyber.settings.terms")
        static let settingsPrivacy = localized("cyber.settings.privacy")
        static let settingsEula = localized("cyber.settings.eula")
        static let settingsRate = localized("cyber.settings.rate")
        static let settingsReport = localized("cyber.settings.report")
        static let settingsProActive = localized("cyber.settings.pro_active")
        static let settingsInitPro = localized("cyber.settings.init_pro")
        static let settingsFullAccess = localized("cyber.settings.full_access")
        static let settingsUnlockFalse = localized("cyber.settings.unlock_false")
        static let settingsDeleteAccount = localized("cyber.settings.delete_account")
        static let settingsIrreversible = localized("cyber.settings.irreversible")
        static let settingsPurging = localized("cyber.settings.purging")
        static let settingsSaveProfile = localized("cyber.settings.save_profile")
        static let settingsAlias = localized("cyber.settings.alias")
        static let settingsEmail = localized("cyber.settings.email")

        // Feedback
        static let feedbackBug = localized("cyber.feedback.bug")
        static let feedbackFeature = localized("cyber.feedback.feature")
        static let feedbackPlaceholder = localized("cyber.feedback.placeholder")
        static let feedbackTransmit = localized("cyber.feedback.transmit")

        // Onboarding
        static let onboardWelcome = localized("cyber.onboard.welcome")
        static let onboardCustomize = localized("cyber.onboard.customize")
        static let onboardConnect = localized("cyber.onboard.connect")
        static let onboardWelcomeBody = localized("cyber.onboard.welcome_body")
        static let onboardCustomizeBody = localized("cyber.onboard.customize_body")
        static let onboardConnectBody = localized("cyber.onboard.connect_body")
        static let onboardSkip = localized("cyber.onboard.skip")
        static let onboardNext = localized("cyber.onboard.next")
        static let onboardInitialize = localized("cyber.onboard.initialize")

        static let giftTitle = localized("cyber.gift.title")
        static let giftClaim = localized("cyber.gift.claim")

        static let profileSetup = localized("cyber.profile.setup")
        static let profileIdentify = localized("cyber.profile.identify")
        static let profileEnterAlias = localized("cyber.profile.enter_alias")
        static let profileBirthHint = localized("cyber.profile.birth_hint")
        static let profileFinalize = localized("cyber.profile.finalize")
        static let profileCompanionLinked = localized("cyber.profile.companion_linked")

        // Char preview
        static let charSelect = localized("cyber.char.select")
        static let charPreview = localized("cyber.char.preview")
        static let charCompanions = localized("cyber.char.companions")
        static let charSelectPartner = localized("cyber.char.select_partner")
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
