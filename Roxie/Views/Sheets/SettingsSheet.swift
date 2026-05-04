import SwiftUI
import StoreKit

struct SettingsSheet: View {
    @Environment(AuthManager.self) private var auth
    @Environment(AppRootModel.self) private var root
    @Environment(\.dismiss) private var dismiss

    @State private var autoPlayMusic = UserPreferencesService.autoPlayMusic
    @State private var hapticsEnabled = UserPreferencesService.hapticsEnabled
    @State private var enableNSFW = UserPreferencesService.enableNSFW
    @State private var showLanguagePicker = false
    @State private var showEditProfile = false
    @State private var showFeedback = false
    @State private var browserURL: URL?

    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    private var displayName: String {
        if case let .string(name)? = auth.user?.userMetadata["display_name"] {
            return name
        }
        return auth.user?.email?.components(separatedBy: "@").first ?? "Guest"
    }

    private var emailText: String {
        auth.user?.email ?? L10n.guestLabel
    }

    private var initialLetter: String {
        String(displayName.prefix(1)).uppercased()
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileCard
                    premiumBanner

                    sectionGroup("Your Account") {
                        SettingsRow(icon: "creditcard.fill", iconTint: Color(hex: "#FF5CA8"), label: "Subscription") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                root.showSubscriptionSheet = true
                            }
                        }
                        Divider().opacity(0.08)
                        SettingsRow(icon: "person.text.rectangle", iconTint: .blue, label: "Edit Profile") {
                            showEditProfile = true
                        }
                        Divider().opacity(0.08)
                        SettingsRow(icon: "bell.fill", iconTint: .orange, label: "Notifications", trailing: {
                            Text("Off").foregroundStyle(.white.opacity(0.4)).font(.system(size: 14))
                        }, action: {})
                    }

                    sectionGroup("Preferences") {
                        SettingsToggleRow(icon: "music.note", iconTint: .purple, label: "Auto-play Music", isOn: $autoPlayMusic)
                            .onChange(of: autoPlayMusic) { _, v in UserPreferencesService.autoPlayMusic = v }
                        Divider().opacity(0.08)
                        SettingsToggleRow(icon: "hand.tap.fill", iconTint: Color(hex: "#FF5CA8"), label: "Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in UserPreferencesService.hapticsEnabled = v }
                        Divider().opacity(0.08)
                        SettingsToggleRow(icon: "flame.fill", iconTint: .red, label: "NSFW Content", isOn: $enableNSFW)
                            .onChange(of: enableNSFW) { _, v in UserPreferencesService.enableNSFW = v }
                        Divider().opacity(0.08)
                        SettingsRow(icon: "globe", iconTint: .teal, label: "Language", trailing: {
                            Text(AppLanguage.current.displayName)
                                .foregroundStyle(.white.opacity(0.5))
                                .font(.system(size: 14))
                        }, action: { showLanguagePicker = true })
                    }

                    sectionGroup("Legal & Support") {
                        SettingsRow(icon: "doc.text.fill", iconTint: .gray, label: "Terms of Service") { browserURL = AppConfig.Legal.terms }
                        Divider().opacity(0.08)
                        SettingsRow(icon: "lock.shield.fill", iconTint: .gray, label: "Privacy Policy") { browserURL = AppConfig.Legal.privacy }
                        Divider().opacity(0.08)
                        SettingsRow(icon: "doc.plaintext.fill", iconTint: .gray, label: "EULA") { browserURL = AppConfig.Legal.eula }
                        Divider().opacity(0.08)
                        SettingsRow(icon: "star.fill", iconTint: .yellow, label: "Rate Us") { rateApp() }
                        Divider().opacity(0.08)
                        SettingsRow(icon: "envelope.fill", iconTint: .blue, label: "Report a Problem") { showFeedback = true }
                    }

                    Button {
                        Task {
                            await auth.logout()
                            dismiss()
                        }
                    } label: {
                        Text(L10n.signOut)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.red.opacity(0.12))
                            )
                    }
                    .padding(.horizontal, 16)

                    Text(appVersion)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.bottom, 24)
                }
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }.foregroundStyle(.white)
                }
            }
            .sheet(isPresented: $showLanguagePicker) { LanguagePickerSheet() }
            .sheet(isPresented: $showEditProfile) { EditProfileSheet() }
            .sheet(isPresented: $showFeedback) { FeedbackSheet() }
            .inAppBrowser(url: $browserURL)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Profile card

    private var profileCard: some View {
        Button {
            showEditProfile = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    HexagonShape().fill(LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .topLeading, endPoint: .bottomTrailing))
                    HexagonShape().stroke(Cyber.cyan.opacity(0.7), lineWidth: 1)
                    Text(initialLetter)
                        .font(Cyber.mono(22, weight: .heavy))
                        .foregroundStyle(Cyber.bg)
                }
                .frame(width: 60, height: 68)
                .shadow(color: Cyber.cyan.opacity(0.6), radius: 8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(displayName.uppercased())
                            .font(Cyber.mono(15, weight: .heavy))
                            .foregroundStyle(Cyber.text)
                            .tracking(1.2)
                            .lineLimit(1)
                        Text(isPro ? "PRO" : "FREE")
                            .font(Cyber.mono(9, weight: .heavy))
                            .foregroundStyle(isPro ? Cyber.bg : Cyber.cyan)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(isPro ? AnyView(LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .leading, endPoint: .trailing)) : AnyView(Color.clear))
                            .overlay(Rectangle().stroke(Cyber.cyan.opacity(isPro ? 0 : 0.7), lineWidth: 1))
                            .tracking(1.4)
                    }
                    HStack(spacing: 6) {
                        Text("[ID]")
                            .font(Cyber.mono(9, weight: .heavy))
                            .foregroundStyle(Cyber.cyan.opacity(0.6))
                            .tracking(1)
                        Text(emailText)
                            .font(Cyber.mono(11, weight: .semibold))
                            .foregroundStyle(Cyber.textDim)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
            }
            .padding(14)
            .background(Cyber.surface.opacity(0.85))
            .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.4), lineWidth: 1))
            .overlay(CornerBrackets(tint: Cyber.cyan, size: 8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Premium banner

    private var premiumBanner: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                root.showSubscriptionSheet = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Cyber.bg)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isPro ? "PRO//ACTIVE" : "INITIALIZE PRO")
                        .font(Cyber.mono(14, weight: .heavy))
                        .foregroundStyle(Cyber.bg)
                        .tracking(1.4)
                    Text(isPro ? "FULL_ACCESS = TRUE" : "UNLOCK_ALL = FALSE")
                        .font(Cyber.mono(10, weight: .semibold))
                        .foregroundStyle(Cyber.bg.opacity(0.7))
                        .tracking(1)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Cyber.bg)
            }
            .padding(14)
            .background(LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(CornerBrackets(tint: Cyber.bg.opacity(0.4), size: 8))
            .shadow(color: Cyber.magenta.opacity(0.6), radius: 10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Section group helper

    @ViewBuilder
    private func sectionGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("//")
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                Text(title.uppercased())
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .tracking(1.6)
                ScanLine(tint: Cyber.cyan).frame(maxWidth: 80)
            }
            .padding(.horizontal, 16)
            VStack(spacing: 0) { content() }
                .background(Cyber.surface.opacity(0.78))
                .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 16)
        }
    }

    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Row primitives

private struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconTint: Color
    let label: String
    @ViewBuilder var trailing: () -> Trailing
    let action: () -> Void

    init(icon: String, iconTint: Color, label: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }, action: @escaping () -> Void) {
        self.icon = icon
        self.iconTint = iconTint
        self.label = label
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBubble(systemName: icon, tint: iconTint)
                Text(label.uppercased())
                    .font(Cyber.mono(12, weight: .semibold))
                    .foregroundStyle(Cyber.text)
                    .tracking(1)
                Spacer()
                trailing()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Cyber.cyan.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsLinkRow: View {
    let icon: String
    let iconTint: Color
    let label: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                iconBubble(systemName: icon, tint: iconTint)
                Text(label.uppercased())
                    .font(Cyber.mono(12, weight: .semibold))
                    .foregroundStyle(Cyber.text)
                    .tracking(1)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Cyber.cyan.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let iconTint: Color
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            iconBubble(systemName: icon, tint: iconTint)
            Text(label.uppercased())
                .font(Cyber.mono(12, weight: .semibold))
                .foregroundStyle(Cyber.text)
                .tracking(1)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Cyber.cyan)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

@ViewBuilder
private func iconBubble(systemName: String, tint: Color) -> some View {
    Image(systemName: systemName)
        .font(.system(size: 12, weight: .heavy))
        .foregroundStyle(tint)
        .frame(width: 28, height: 28)
        .background(tint.opacity(0.15))
        .overlay(Rectangle().stroke(tint.opacity(0.6), lineWidth: 1))
        .shadow(color: tint.opacity(0.5), radius: 4)
}

// MARK: - Edit profile sub-sheet

struct EditProfileSheet: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var saving = false
    @State private var showDeleteSubWarning = false
    @State private var showDeleteConfirm = false

    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        CyberSheetChrome(title: "Profile_Edit", subtitle: "User // Mutate", tint: Cyber.cyan) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    cyberFieldGroup(label: "DISPLAY_NAME") {
                        TextField("", text: $name, prompt: Text("ALIAS").font(Cyber.mono(13)).foregroundColor(Cyber.textDim))
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .onSubmit { saveName() }
                            .font(Cyber.mono(14, weight: .semibold))
                            .foregroundStyle(Cyber.text)
                            .tint(Cyber.cyan)
                            .padding(10)
                    }

                    cyberFieldGroup(label: "EMAIL") {
                        Text(auth.user?.email ?? "—")
                            .font(Cyber.mono(13, weight: .semibold))
                            .foregroundStyle(Cyber.textDim)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                    }

                    Button(action: saveName) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 14, weight: .heavy))
                            Text("SAVE_PROFILE")
                                .font(Cyber.mono(13, weight: .heavy))
                                .tracking(1.4)
                        }
                        .foregroundStyle(Cyber.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [Cyber.cyan, Cyber.violet], startPoint: .leading, endPoint: .trailing))
                        .shadow(color: Cyber.cyan.opacity(0.6), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(saving || name.isEmpty)
                    .opacity(name.isEmpty || saving ? 0.6 : 1)

                    Spacer().frame(height: 12)

                    Button {
                        if isPro {
                            showDeleteSubWarning = true
                        } else {
                            showDeleteConfirm = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill").font(.system(size: 13, weight: .heavy))
                            Text("DELETE_ACCOUNT")
                                .font(Cyber.mono(12, weight: .heavy))
                                .tracking(1.4)
                            Spacer()
                            Text("//IRREVERSIBLE")
                                .font(Cyber.mono(9, weight: .heavy))
                                .tracking(1.4)
                        }
                        .foregroundStyle(Cyber.danger)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Cyber.danger.opacity(0.08))
                        .overlay(Rectangle().stroke(Cyber.danger.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            if case let .string(value)? = auth.user?.userMetadata["display_name"] {
                name = value
            }
        }
        .alert(L10n.deleteProWarningTitle, isPresented: $showDeleteSubWarning) {
            Button(L10n.deleteOpenAppStore) {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    openURL(url)
                }
            }
            Button(L10n.deleteContinue, role: .destructive) {
                showDeleteConfirm = true
            }
            Button(L10n.deleteCancel, role: .cancel) {}
        } message: {
            Text(L10n.deleteProWarningBody)
        }
        .confirmationDialog(
            L10n.deleteConfirmMessage,
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.deleteAccount, role: .destructive) {
                Task {
                    await auth.deleteAccount()
                    dismiss()
                }
            }
            Button(L10n.deleteCancel, role: .cancel) {}
        }
        .overlay {
            if auth.isDeletingAccount {
                ZStack {
                    Cyber.bg.opacity(0.85).ignoresSafeArea()
                    DeleteAccountProgressOverlay(stage: auth.deleteAccountStage)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: auth.isDeletingAccount)
    }

    @ViewBuilder
    private func cyberFieldGroup<C: View>(label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("// \(label)")
                .font(Cyber.mono(10, weight: .heavy))
                .foregroundStyle(Cyber.cyan)
                .tracking(1.4)
            content()
                .background(Cyber.surface.opacity(0.85))
                .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.4), lineWidth: 1))
        }
    }

    private func saveName() {
        saving = true
        Task {
            await auth.updateDisplayName(name)
            saving = false
            dismiss()
        }
    }
}

// MARK: - Delete-account progress HUD

private struct DeleteAccountProgressOverlay: View {
    let stage: AuthManager.DeleteStage

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: stageIcon)
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(stageTint)
                .shadow(color: stageTint.opacity(0.7), radius: 10)

            Text(stageTitle)
                .font(Cyber.mono(13, weight: .heavy))
                .foregroundStyle(Cyber.text)
                .tracking(1.6)

            VStack(alignment: .leading, spacing: 8) {
                stepRow(label: "PURGE_DATA", state: state(for: .purgingData))
                stepRow(label: "DELETE_AUTH_USER", state: state(for: .deletingAuthUser))
                stepRow(label: "SIGN_OUT", state: state(for: .loggingOut))
            }
            .padding(14)
            .background(Cyber.surface.opacity(0.85))
            .overlay(Rectangle().stroke(Cyber.danger.opacity(0.5), lineWidth: 1))

            if case .failed(let msg) = stage {
                Text(msg)
                    .font(Cyber.mono(10, weight: .semibold))
                    .foregroundStyle(Cyber.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(28)
    }

    private enum StepState { case pending, active, done }

    private func state(for step: AuthManager.DeleteStage) -> StepState {
        switch (step, stage) {
        case (.purgingData, .purgingData): return .active
        case (.deletingAuthUser, .deletingAuthUser): return .active
        case (.loggingOut, .loggingOut): return .active
        case (.purgingData, .deletingAuthUser), (.purgingData, .loggingOut), (.purgingData, .done): return .done
        case (.deletingAuthUser, .loggingOut), (.deletingAuthUser, .done): return .done
        case (.loggingOut, .done): return .done
        default: return .pending
        }
    }

    private var stageIcon: String {
        if case .failed = stage { return "xmark.octagon.fill" }
        if stage == .done { return "checkmark.seal.fill" }
        return "trash.fill"
    }

    private var stageTint: Color {
        if case .failed = stage { return Cyber.danger }
        if stage == .done { return Cyber.lime }
        return Cyber.danger
    }

    private var stageTitle: String {
        switch stage {
        case .idle: return "// READY"
        case .purgingData: return "// PURGING USER DATA"
        case .deletingAuthUser: return "// DELETING ACCOUNT"
        case .loggingOut: return "// SIGNING OUT"
        case .done: return "// COMPLETE"
        case .failed: return "// FAILED"
        }
    }

    private func stepRow(label: String, state: StepState) -> some View {
        HStack(spacing: 10) {
            Group {
                switch state {
                case .pending:
                    Image(systemName: "circle")
                        .foregroundStyle(Cyber.textMuted)
                case .active:
                    ProgressView().tint(Cyber.danger).scaleEffect(0.7)
                case .done:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Cyber.lime)
                }
            }
            .frame(width: 18, height: 18)

            Text(label)
                .font(Cyber.mono(10, weight: .heavy))
                .foregroundStyle(state == .pending ? Cyber.textMuted : Cyber.text)
                .tracking(1.4)
            Spacer()
        }
        .frame(width: 220, alignment: .leading)
    }
}

// MARK: - Feedback sub-sheet

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var kind: Kind = .problem
    @State private var message: String = ""

    enum Kind: String, CaseIterable, Identifiable {
        case problem = "Report a problem"
        case feature = "Request a feature"
        var id: String { rawValue }
    }

    var body: some View {
        CyberSheetChrome(title: "Feedback", subtitle: "Transmit // Report", tint: Cyber.violet) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 0) {
                    ForEach(Kind.allCases) { k in
                        Button { kind = k } label: {
                            Text(k == .problem ? "BUG_REPORT" : "FEATURE_REQ")
                                .font(Cyber.mono(11, weight: .heavy))
                                .tracking(1.4)
                                .foregroundStyle(kind == k ? Cyber.bg : Cyber.violet)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(kind == k ? Cyber.violet : Color.clear)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Cyber.surface.opacity(0.85))
                .overlay(Rectangle().stroke(Cyber.violet.opacity(0.5), lineWidth: 1))

                VStack(alignment: .leading, spacing: 6) {
                    Text("// MESSAGE")
                        .font(Cyber.mono(10, weight: .heavy))
                        .foregroundStyle(Cyber.violet)
                        .tracking(1.4)
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Tell us more...")
                                .font(Cyber.mono(13))
                                .foregroundStyle(Cyber.textDim)
                                .padding(.horizontal, 14).padding(.vertical, 12)
                        }
                        TextEditor(text: $message)
                            .scrollContentBackground(.hidden)
                            .font(Cyber.mono(13, weight: .semibold))
                            .foregroundStyle(Cyber.text)
                            .tint(Cyber.violet)
                            .padding(8)
                    }
                    .frame(minHeight: 180)
                    .background(Cyber.surface.opacity(0.85))
                    .overlay(Rectangle().stroke(Cyber.violet.opacity(0.45), lineWidth: 1))
                }

                Button {
                    Log.app.info("[feedback] \(kind.rawValue): \(message, privacy: .public)")
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill").font(.system(size: 13, weight: .heavy))
                        Text("TRANSMIT")
                            .font(Cyber.mono(13, weight: .heavy))
                            .tracking(1.6)
                    }
                    .foregroundStyle(Cyber.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient(colors: [Cyber.violet, Cyber.magenta], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: Cyber.violet.opacity(0.6), radius: 8)
                }
                .buttonStyle(.plain)
                .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(message.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)

                Spacer()
            }
            .padding(16)
        }
    }
}
