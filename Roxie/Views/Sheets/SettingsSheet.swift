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
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "#FF5CA8"), Color(hex: "#FF2D79")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Text(initialLetter)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    if isPro {
                        Text("PRO")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(
                                LinearGradient(colors: [Color(hex: "#FFD91B"), Color(hex: "#FFE979")], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Text("FREE")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                Text(emailText)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isPro ? "Bonie Pro Active" : "Upgrade to Bonie Pro")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(isPro ? "Enjoying full access" : "Unlock everything")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: isPro
                        ? [Color(hex: "#FF4081"), Color(hex: "#F50057")]
                        : [Color(hex: "#FF5D9D"), Color(hex: "#FF2D79")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Section group helper

    @ViewBuilder
    private func sectionGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 16)
            VStack(spacing: 0) { content() }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
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
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                trailing()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
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
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
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
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "#FF5CA8"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

@ViewBuilder
private func iconBubble(systemName: String, tint: Color) -> some View {
    Image(systemName: systemName)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 30, height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint)
        )
}

// MARK: - Edit profile sub-sheet

struct EditProfileSheet: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var saving = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display name", text: $name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit { saveName() }
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(auth.user?.email ?? "—").foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button("Save", action: saveName)
                        .disabled(saving || name.isEmpty)
                }
                Section {
                    Button("Delete Account", role: .destructive) { showDeleteConfirm = true }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.close) { dismiss() } } }
            .onAppear {
                if case let .string(value)? = auth.user?.userMetadata["display_name"] {
                    name = value
                }
            }
            .confirmationDialog(
                "Delete your account? This permanently removes your data and cannot be undone.",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        await auth.deleteAccount()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .overlay {
                if auth.isLoading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(.white).scaleEffect(1.4)
                            Text("Deleting account...")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
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
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) {
                    ForEach(Kind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                Section("Tell us more") {
                    TextEditor(text: $message)
                        .frame(minHeight: 160)
                }

                Section {
                    Button("Send") {
                        // Native sends to Supabase feedback table; stub for now.
                        Log.app.info("[feedback] \(kind.rawValue): \(message, privacy: .public)")
                        dismiss()
                    }
                    .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.close) { dismiss() } } }
        }
    }
}
