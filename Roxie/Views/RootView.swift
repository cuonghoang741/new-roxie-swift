import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(VRMContext.self) private var vrm

    // @AppStorage for onboarding flags so the view re-renders the moment
    // their string flips to "true". Reading UserDefaults inside a computed
    // property doesn't trigger SwiftUI updates — the previous version of
    // this view set the flag in UserDefaults and got stuck because nothing
    // observed the change.
    @AppStorage("persist.hasSeenImageOnboarding") private var hasSeenImageOnboarding: String = ""
    @AppStorage("persist.hasClaimedNewUserGift") private var hasClaimedNewUserGift: String = ""
    @AppStorage(PersistKeys.hasCompletedOnboardingV2) private var hasCompletedOnboardingV2: String = ""

    @State private var claiming = false

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
                    Task { await claimStarter() }
                }
                .onAppear { Log.app.info("[onboarding] route=newUserGift") }
                .disabled(claiming)
                .overlay {
                    if claiming {
                        ZStack {
                            Color.black.opacity(0.55).ignoresSafeArea()
                            ProgressView().tint(.white).scaleEffect(1.4)
                        }
                    }
                }
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

    @MainActor
    private func claimStarter() async {
        guard !claiming else { return }
        claiming = true
        defer { claiming = false }
        Log.app.info("[onboarding] NewUserGift CLAIM tapped — granting random starter")
        do {
            let pick = try await CharacterRepository().claimRandomStarter()
            // Refresh catalog so ownedCharacterIds includes the new claim,
            // then set the picked character as current. Without the refresh,
            // ensureDefaultSelection on the next screen would fall back to
            // the first catalog row again.
            await vrm.refreshInitialData()
            vrm.setCurrentCharacter(pick)
            hasClaimedNewUserGift = "true"
        } catch {
            Log.app.error("[onboarding] claimStarter failed: \(error.localizedDescription, privacy: .public)")
            // Don't block the user — flip the flag so they can proceed even
            // if the insert failed; ensureDefaultSelection will fall back to
            // a catalog character.
            hasClaimedNewUserGift = "true"
        }
    }
}
