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

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    /// Supported locales – keep in sync with the .lproj folders.
    enum Locale: String, CaseIterable, Identifiable {
        case en, vi, ja, fr, ko
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .en: return "English"
            case .vi: return "Tiếng Việt"
            case .ja: return "日本語"
            case .fr: return "Français"
            case .ko: return "한국어"
            }
        }
    }
}

/// Override the app language at runtime (persists across launches via
/// `AppleLanguages` — standard iOS mechanism).
enum AppLanguage {
    private static let defaultsKey = "AppleLanguages"

    static var current: L10n.Locale {
        let code = Foundation.Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        return L10n.Locale(rawValue: String(code)) ?? .en
    }

    static func set(_ locale: L10n.Locale) {
        UserDefaults.standard.set([locale.rawValue], forKey: defaultsKey)
        UserDefaults.standard.synchronize()
    }
}
