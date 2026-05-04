import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var auth

    // @AppStorage for onboarding flags so the view re-renders the moment
    // their string flips to "true". Reading UserDefaults inside a computed
    // property doesn't trigger SwiftUI updates — the previous version of
    // this view set the flag in UserDefaults and got stuck because nothing
    // observed the change.
    @AppStorage("persist.hasSeenImageOnboarding") private var hasSeenImageOnboarding: String = ""
    @AppStorage("persist.hasClaimedNewUserGift") private var hasClaimedNewUserGift: String = ""
    @AppStorage(PersistKeys.hasCompletedOnboardingV2) private var hasCompletedOnboardingV2: String = ""

    var body: some View {
        Group {
            if !auth.hasRestoredSession {
                launchView
                    .onAppear { Log.app.info("[onboarding] route=launch (waiting hasRestoredSession)") }
            } else if needsSignIn {
                SignInScreen()
                    .onAppear { Log.app.info("[onboarding] route=signIn") }
            } else if needsImageOnboarding {
                ImageOnboardingScreen {
                    Log.app.info("[onboarding] ImageOnboarding onFinish — flipping hasSeenImageOnboarding")
                    hasSeenImageOnboarding = "true"
                }
                .onAppear { Log.app.info("[onboarding] route=imageOnboarding") }
            } else if needsNewUserGift {
                NewUserGiftScreen {
                    Log.app.info("[onboarding] NewUserGift onFinish — flipping hasClaimedNewUserGift")
                    hasClaimedNewUserGift = "true"
                }
                .onAppear { Log.app.info("[onboarding] route=newUserGift") }
            } else if needsOnboardingV2 {
                OnboardingV2Screen(selectedCharacter: nil) {
                    Log.app.info("[onboarding] OnboardingV2 onFinish — flipping hasCompletedOnboardingV2")
                    hasCompletedOnboardingV2 = "true"
                }
                .onAppear { Log.app.info("[onboarding] route=onboardingV2") }
            } else {
                VRMExperienceScreen()
                    .onAppear { Log.app.info("[onboarding] route=vrmExperience (done)") }
            }
        }
        .animation(.easeInOut, value: auth.hasRestoredSession)
        .animation(.easeInOut, value: auth.session?.accessToken)
        .task {
            // Warm the VRM/FBX disk cache as soon as the app shows any UI.
            // Runs once per app launch (idempotent inside the cache); covers
            // both the sign-in path and already-authenticated users who skip
            // straight to the experience screen.
            VRMAssetCache.shared.preloadAll()
        }
    }

    private var launchView: some View {
        CyberLaunchView()
    }

    // Strict: a real Supabase session is required to leave the sign-in
    // screen. Guest mode was removed — only Apple/Google sign-in advance
    // past this gate.
    private var needsSignIn: Bool { auth.session == nil }

    private var needsImageOnboarding: Bool { hasSeenImageOnboarding != "true" }

    private var needsNewUserGift: Bool {
        guard auth.isNewUser == true else { return false }
        return hasClaimedNewUserGift != "true"
    }

    private var needsOnboardingV2: Bool {
        guard auth.session != nil else { return false }
        return hasCompletedOnboardingV2 != "true"
    }
}
