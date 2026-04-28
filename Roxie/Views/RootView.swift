import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Group {
            if !auth.hasRestoredSession {
                launchView
            } else if needsSignIn {
                SignInScreen()
            } else if needsImageOnboarding {
                ImageOnboardingScreen {
                    UserDefaults.standard.set("true", forKey: "persist.hasSeenImageOnboarding")
                }
            } else if needsNewUserGift {
                NewUserGiftScreen {
                    UserDefaults.standard.set("true", forKey: "persist.hasClaimedNewUserGift")
                }
            } else if needsOnboardingV2 {
                OnboardingV2Screen(selectedCharacter: nil) {
                    UserPreferencesService.hasCompletedOnboardingV2 = true
                }
            } else {
                VRMExperienceScreen()
            }
        }
        .animation(.easeInOut, value: auth.hasRestoredSession)
        .animation(.easeInOut, value: auth.session?.accessToken)
    }

    private var launchView: some View {
        CyberLaunchView()
    }

    // Match the RN condition: `hasRestoredSession && !session`.
    // Guest mode still requires the user to explicitly tap "Continue as guest"
    // on the sign-in screen; that sets `guestAcknowledged = true`.
    private var needsSignIn: Bool {
        if auth.session != nil { return false }
        return !auth.guestAcknowledged
    }

    private var needsImageOnboarding: Bool {
        let key = "persist.hasSeenImageOnboarding"
        return UserDefaults.standard.string(forKey: key) != "true"
    }

    private var needsNewUserGift: Bool {
        guard auth.isNewUser == true else { return false }
        let key = "persist.hasClaimedNewUserGift"
        return UserDefaults.standard.string(forKey: key) != "true"
    }

    private var needsOnboardingV2: Bool {
        guard auth.session != nil else { return false }
        return !UserPreferencesService.hasCompletedOnboardingV2
    }
}
