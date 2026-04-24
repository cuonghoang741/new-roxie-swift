import SwiftUI
import SafariServices

struct SignInScreen: View {
    @Environment(AuthManager.self) private var auth

    @State private var isAgeVerified: Bool = UserPreferencesService.ageVerified18
    @State private var showAgePrompt: Bool = false
    @State private var pendingProvider: Provider?
    @State private var showingLegal: LegalDocument?
    @State private var showLanguagePicker: Bool = false

    enum Provider { case apple, google, guest }
    enum LegalDocument: Identifiable {
        case terms, privacy, eula
        var id: String { "\(self)" }
        var url: URL {
            switch self {
            case .terms: return AppConfig.Legal.terms
            case .privacy: return AppConfig.Legal.privacy
            case .eula: return AppConfig.Legal.eula
            }
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.Brand.s100, Palette.Brand.s300, Palette.Brand.s500.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                topBar
                Spacer(minLength: 0)
                hero
                Spacer()
                actionButtons
                legalFooter
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sheet(item: $showingLegal) { doc in
            SafariWebView(url: doc.url)
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet()
        }
        .alert(L10n.ageVerifyTitle, isPresented: $showAgePrompt) {
            Button(L10n.ageVerifyConfirm) {
                isAgeVerified = true
                UserPreferencesService.ageVerified18 = true
                if let provider = pendingProvider {
                    proceed(with: provider)
                }
            }
            Button(L10n.cancel, role: .cancel) {
                pendingProvider = nil
            }
        } message: {
            Text(L10n.ageVerifyBody)
        }
        .overlay {
            if auth.isLoading {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView().controlSize(.large).tint(.white)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                showLanguagePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                    Text(AppLanguage.current.displayName)
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .padding(.top, 8)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.circle.fill")
                .resizable()
                .frame(width: 96, height: 96)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.18), radius: 20, y: 12)
            Text("Bonie")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(L10n.welcomeTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text(L10n.welcomeSubtitle)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let message = auth.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                handleSignIn(.apple)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                    Text(L10n.signInWithApple)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                handleSignIn(.google)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                    Text(L10n.signInWithGoogle)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Palette.GrayDark.s900)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                handleSignIn(.guest)
            } label: {
                Text(L10n.continueAsGuest)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
            }
        }
    }

    private var legalFooter: some View {
        HStack(spacing: 4) {
            Button(L10n.termsLink) { showingLegal = .terms }
            Text("•").foregroundStyle(.white.opacity(0.7))
            Button(L10n.privacyLink) { showingLegal = .privacy }
            Text("•").foregroundStyle(.white.opacity(0.7))
            Button(L10n.eulaLink) { showingLegal = .eula }
        }
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.9))
    }

    private func handleSignIn(_ provider: Provider) {
        pendingProvider = provider
        if !isAgeVerified {
            showAgePrompt = true
            return
        }
        proceed(with: provider)
    }

    private func proceed(with provider: Provider) {
        Task { @MainActor in
            switch provider {
            case .apple: await auth.signInWithApple()
            case .google: await auth.signInWithGoogle()
            case .guest: auth.continueAsGuest()
            }
        }
    }
}

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct LanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(L10n.Locale.allCases) { locale in
                    Button {
                        AppLanguage.set(locale)
                        dismiss()
                        // Tell user to relaunch (iOS picks up AppleLanguages on next launch).
                        // Alternatively we could do a full UI bundle swap here.
                        exit(0)
                    } label: {
                        HStack {
                            Text(locale.displayName).foregroundStyle(.primary)
                            Spacer()
                            if locale == AppLanguage.current {
                                Image(systemName: "checkmark").foregroundStyle(Palette.Brand.s500)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("Language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.close) { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}
