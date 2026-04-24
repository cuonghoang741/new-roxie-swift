import Foundation
import SwiftUI

@MainActor
@Observable
final class AppRootModel {
    enum Route: Hashable {
        case experience
        case characterPreview(initialIndex: Int)
        case onboardingV2(selectedCharacterId: String)
    }

    enum Step {
        case launching
        case signIn
        case imageOnboarding
        case newUserGift
        case onboardingV2
        case experience
    }

    var path: [Route] = []
    var step: Step = .launching
    var showSubscriptionSheet: Bool = false
    var showQuestSheet: Bool = false
    var showBackgroundSheet: Bool = false
    var showCharacterSheet: Bool = false
    var showCostumeSheet: Bool = false
    var showDanceSheet: Bool = false
    var showMediaSheet: Bool = false
    var showChatHistory: Bool = false
    var showSettings: Bool = false
}
