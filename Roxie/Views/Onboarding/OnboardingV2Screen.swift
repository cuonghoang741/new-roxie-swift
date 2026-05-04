import SwiftUI

struct OnboardingV2Screen: View {
    var selectedCharacter: CharacterItem?
    var onFinish: () -> Void

    @Environment(AuthManager.self) private var auth
    @State private var displayName: String = ""
    @State private var birthYear: String = ""
    @State private var saving: Bool = false

    var body: some View {
        ZStack {
            Cyber.bg.ignoresSafeArea()
            CyberGridBackdrop().opacity(0.18).ignoresSafeArea()
            ScanLineBackdrop().ignoresSafeArea()
            RadialGradient(
                colors: [Cyber.cyan.opacity(0.3), .clear],
                center: .top, startRadius: 0, endRadius: 320
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    fieldGroup(label: "DISPLAY_NAME") {
                        TextField("",
                                  text: $displayName,
                                  prompt: Text("ENTER_ALIAS").font(Cyber.mono(13)).foregroundColor(Cyber.textDim))
                            .textInputAutocapitalization(.words)
                            .font(Cyber.mono(14, weight: .semibold))
                            .foregroundStyle(Cyber.text)
                            .tint(Cyber.cyan)
                            .padding(12)
                    }
                    fieldGroup(label: "BIRTH_YEAR") {
                        TextField("",
                                  text: $birthYear,
                                  prompt: Text("YYYY").font(Cyber.mono(13)).foregroundColor(Cyber.textDim))
                            .keyboardType(.numberPad)
                            .font(Cyber.mono(14, weight: .semibold))
                            .foregroundStyle(Cyber.text)
                            .tint(Cyber.cyan)
                            .padding(12)
                    }

                    if let char = selectedCharacter {
                        characterBox(char)
                    }

                    Spacer().frame(height: 4)

                    Button {
                        Task { await save() }
                    } label: {
                        HStack(spacing: 10) {
                            if saving {
                                ProgressView().tint(Cyber.bg).controlSize(.small)
                                Text("SAVING //")
                                    .font(Cyber.mono(13, weight: .heavy))
                                    .tracking(1.6)
                            } else {
                                Text("FINALIZE //")
                                    .font(Cyber.mono(13, weight: .heavy))
                                    .tracking(1.6)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .heavy))
                            }
                        }
                        .foregroundStyle(Cyber.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: Cyber.cyan.opacity(0.7), radius: 10)
                    }
                    .disabled(saving)
                    .opacity(saving ? 0.7 : 1)
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("[ PROFILE.SETUP ]")
                .font(Cyber.mono(11, weight: .heavy))
                .foregroundStyle(Cyber.cyan)
                .tracking(2)
            Text("//IDENTIFY")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(Cyber.text)
                .tracking(1.2)
            Text(L10n.profileSubtitle.uppercased())
                .font(Cyber.mono(11, weight: .semibold))
                .foregroundStyle(Cyber.textDim)
                .tracking(1.2)
        }
    }

    @ViewBuilder
    private func fieldGroup<C: View>(label: String, @ViewBuilder content: () -> C) -> some View {
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

    private func characterBox(_ char: CharacterItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("// COMPANION_LINKED")
                .font(Cyber.mono(10, weight: .heavy))
                .foregroundStyle(Cyber.magenta)
                .tracking(1.4)
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: char.thumbnailUrl ?? char.avatar ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Cyber.surfaceHi
                }
                .frame(width: 56, height: 56)
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Cyber.magenta.opacity(0.6), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text((char.name ?? "—").uppercased())
                        .font(Cyber.mono(13, weight: .heavy))
                        .foregroundStyle(Cyber.text)
                        .tracking(1.2)
                    Text("[ ID: \(char.id.prefix(8)) ]")
                        .font(Cyber.mono(9, weight: .semibold))
                        .foregroundStyle(Cyber.textDim)
                        .tracking(1)
                }
                Spacer()
                StatusDot(tint: Cyber.lime)
            }
            .padding(10)
            .background(Cyber.surface.opacity(0.85))
            .overlay(Rectangle().stroke(Cyber.magenta.opacity(0.5), lineWidth: 1))
        }
    }

    private func save() async {
        Log.app.info("[OnboardingV2] save() start — name='\(displayName, privacy: .public)' year='\(birthYear, privacy: .public)'")
        saving = true
        defer { saving = false }
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            Log.app.info("[OnboardingV2] updateDisplayName starting")
            await auth.updateDisplayName(trimmedName)
            Log.app.info("[OnboardingV2] updateDisplayName done")
        }
        if let year = Int(birthYear.trimmingCharacters(in: .whitespaces)) {
            Log.app.info("[OnboardingV2] updateBirthYear starting (\(year))")
            await auth.updateBirthYear(year)
            Log.app.info("[OnboardingV2] updateBirthYear done")
        }
        UserPreferencesService.hasCompletedOnboardingV2 = true
        Log.app.info("[OnboardingV2] save() complete — calling onFinish()")
        onFinish()
    }
}
