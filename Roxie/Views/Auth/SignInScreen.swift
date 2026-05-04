import SwiftUI
import SafariServices
import AuthenticationServices

struct SignInScreen: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.colorScheme) private var colorScheme

    @State private var isAgeVerified: Bool = UserPreferencesService.ageVerified18
    @State private var showAgePrompt: Bool = false
    @State private var pendingProvider: Provider?
    @State private var showingLegal: LegalDocument?
    @State private var showLanguagePicker: Bool = false

    enum Provider { case apple, google }
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

            appleSignInButton
            googleSignInButton
        }
    }

    // Apple's HIG-compliant button via AuthenticationServices.
    //
    // We MUST NOT render `SignInWithAppleButton` when the user hasn't
    // completed the age gate yet — SwiftUI submits the auth request the
    // moment the button fires its `onRequest` callback, with no way to
    // abort. That used to leave a sentinel nonce in flight, which broke
    // the actual sign-in attempt that came after the age confirmation.
    //
    // Instead, when not age-verified we render an Apple-styled placeholder
    // button that only shows the age prompt; once `isAgeVerified` flips
    // true, we swap to the real `SignInWithAppleButton` and the user taps
    // it for the actual auth flow.
    @ViewBuilder
    private var appleSignInButton: some View {
        if isAgeVerified {
            SignInWithAppleButton(.signIn) { request in
                auth.configureAppleRequest(request)
            } onCompletion: { result in
                Task { await auth.handleAppleResult(result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            Button {
                pendingProvider = .apple
                showAgePrompt = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 18, weight: .medium))
                    Text(L10n.signInWithApple)
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // Google branding-compliant button:
    // white surface, 1pt grey border, multicolor "G" logo, "Sign in with Google" text.
    // https://developers.google.com/identity/branding-guidelines
    private var googleSignInButton: some View {
        Button {
            handleSignIn(.google)
        } label: {
            HStack(spacing: 12) {
                GoogleGLogo()
                    .frame(width: 18, height: 18)
                Text(L10n.signInWithGoogle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(red: 0.118, green: 0.122, blue: 0.133)) // #1F1F21 per spec
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.882, green: 0.886, blue: 0.890), lineWidth: 1) // #E1E2E3
            )
        }
        .buttonStyle(.plain)
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
            case .apple: break // Apple flow is driven by SignInWithAppleButton itself
            case .google: await auth.signInWithGoogle()
            }
        }
    }
}

// MARK: - Google "G" logo

/// Multicolor Google "G" mark, rendered from the official 24×24 path data.
/// Brand guidelines require an unmodified, multicolor mark on the button.
private struct GoogleGLogo: View {
    var body: some View {
        Canvas { ctx, size in
            let scale = min(size.width, size.height) / 24.0
            ctx.translateBy(x: (size.width - 24 * scale) / 2,
                            y: (size.height - 24 * scale) / 2)
            ctx.scaleBy(x: scale, y: scale)

            for stroke in Self.strokes {
                ctx.fill(stroke.path, with: .color(stroke.color))
            }
        }
        .accessibilityHidden(true)
    }

    private struct Stroke {
        let color: Color
        let path: Path
    }

    private static let strokes: [Stroke] = [
        Stroke(
            color: Color(red: 0.259, green: 0.522, blue: 0.957), // #4285F4
            path: SVGPath.parse("M23.7663 12.2764C23.7663 11.4607 23.7001 10.6406 23.559 9.83807H12.2402V14.4591H18.722C18.453 15.9494 17.5888 17.2678 16.3233 18.1056V21.1039H20.1903C22.4611 19.0139 23.7663 15.9274 23.7663 12.2764Z")
        ),
        Stroke(
            color: Color(red: 0.204, green: 0.659, blue: 0.325), // #34A853
            path: SVGPath.parse("M12.24 24.0008C15.4764 24.0008 18.2058 22.9382 20.1944 21.1039L16.3274 18.1055C15.2516 18.8375 13.8626 19.252 12.2444 19.252C9.11376 19.252 6.45934 17.1399 5.50693 14.3003H1.51648V17.3912C3.55359 21.4434 7.70278 24.0008 12.24 24.0008Z")
        ),
        Stroke(
            color: Color(red: 0.984, green: 0.737, blue: 0.016), // #FBBC04
            path: SVGPath.parse("M5.50277 14.3003C5.00011 12.8099 5.00011 11.1961 5.50277 9.70575V6.61481H1.51674C-0.185266 10.0056 -0.185266 14.0004 1.51674 17.3912L5.50277 14.3003Z")
        ),
        Stroke(
            color: Color(red: 0.918, green: 0.263, blue: 0.208), // #EA4335
            path: SVGPath.parse("M12.24 4.74966C13.9508 4.7232 15.6043 5.36697 16.8433 6.54867L20.2694 3.12262C18.1 1.0855 15.2207 -0.034466 12.24 0.000808666C7.70277 0.000808666 3.55359 2.55822 1.51648 6.61481L5.50252 9.70575C6.45052 6.86173 9.10935 4.74966 12.24 4.74966Z")
        ),
    ]
}

/// Minimal SVG path-data parser for the absolute commands used by the Google G:
/// M (moveto), L (lineto), C (cubic-bezier), H (horizontal lineto), V (vertical lineto), Z (closepath).
private enum SVGPath {
    static func parse(_ d: String) -> Path {
        var path = Path()
        var current = CGPoint.zero
        var idx = d.startIndex
        let end = d.endIndex

        func skipSep() {
            while idx < end, d[idx] == " " || d[idx] == "," || d[idx] == "\n" || d[idx] == "\t" {
                idx = d.index(after: idx)
            }
        }

        func readNumber() -> CGFloat? {
            skipSep()
            let start = idx
            var sawDigit = false
            if idx < end, d[idx] == "-" || d[idx] == "+" { idx = d.index(after: idx) }
            while idx < end {
                let c = d[idx]
                if c.isNumber { sawDigit = true; idx = d.index(after: idx) }
                else if c == "." { idx = d.index(after: idx) }
                else if c == "e" || c == "E" {
                    idx = d.index(after: idx)
                    if idx < end, d[idx] == "-" || d[idx] == "+" { idx = d.index(after: idx) }
                } else { break }
            }
            guard sawDigit else { idx = start; return nil }
            return CGFloat(Double(d[start..<idx]) ?? 0)
        }

        while idx < end {
            let c = d[idx]
            guard c.isLetter else {
                // Unknown leading char (shouldn't happen for well-formed input);
                // advance to guarantee progress.
                idx = d.index(after: idx)
                continue
            }
            idx = d.index(after: idx)
            switch c {
            case "M":
                guard let x = readNumber(), let y = readNumber() else { break }
                current = CGPoint(x: x, y: y)
                path.move(to: current)
                while let nx = readNumber(), let ny = readNumber() {
                    current = CGPoint(x: nx, y: ny)
                    path.addLine(to: current)
                }
            case "L":
                while let x = readNumber(), let y = readNumber() {
                    current = CGPoint(x: x, y: y)
                    path.addLine(to: current)
                }
            case "C":
                while let c1x = readNumber(), let c1y = readNumber(),
                      let c2x = readNumber(), let c2y = readNumber(),
                      let x = readNumber(), let y = readNumber() {
                    current = CGPoint(x: x, y: y)
                    path.addCurve(to: current,
                                  control1: CGPoint(x: c1x, y: c1y),
                                  control2: CGPoint(x: c2x, y: c2y))
                }
            case "H":
                while let x = readNumber() {
                    current = CGPoint(x: x, y: current.y)
                    path.addLine(to: current)
                }
            case "V":
                while let y = readNumber() {
                    current = CGPoint(x: current.x, y: y)
                    path.addLine(to: current)
                }
            case "Z", "z":
                path.closeSubpath()
            default:
                break
            }
        }
        return path
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
    @State private var refreshTrigger = false

    var body: some View {
        CyberSheetChrome(title: L10n.Cyber.sheetLanguage, subtitle: L10n.Cyber.sheetLanguageSub, tint: Cyber.cyan) {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(L10n.Locale.allCases) { locale in
                        languageRow(locale)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.large])
        .id(refreshTrigger)
    }

    private func languageRow(_ locale: L10n.Locale) -> some View {
        let active = locale == AppLanguage.current
        return Button {
            AppLanguage.set(locale)
            refreshTrigger.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        } label: {
            HStack(spacing: 12) {
                Text(locale.rawValue.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(active ? Cyber.bg : Cyber.cyan)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(active ? Cyber.cyan : Color.clear)
                    .overlay(Rectangle().stroke(Cyber.cyan.opacity(active ? 0 : 0.6), lineWidth: 1))

                Text(locale.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Cyber.text)

                Spacer()

                if active {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Cyber.lime)
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Cyber.lime)
                            .tracking(1.4)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Cyber.surface.opacity(0.85))
            .overlay(Rectangle().stroke(active ? Cyber.cyan : Cyber.cyan.opacity(0.3), lineWidth: active ? 1.5 : 1))
            .shadow(color: active ? Cyber.cyan.opacity(0.4) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
    }
}
