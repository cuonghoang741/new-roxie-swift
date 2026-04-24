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
            Palette.Brand.s100.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.profileTitle)
                    .font(.largeTitle.bold())
                Text(L10n.profileSubtitle)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.displayName).font(.subheadline.weight(.semibold))
                    TextField(L10n.displayNamePlaceholder, text: $displayName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.birthYear).font(.subheadline.weight(.semibold))
                    TextField(L10n.birthYearPlaceholder, text: $birthYear)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                }

                if let char = selectedCharacter {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: char.thumbnailUrl ?? char.avatar ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading) {
                            Text(L10n.characterPicked).font(.footnote).foregroundStyle(.secondary)
                            Text(char.name ?? "").font(.headline)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Spacer()

                PrimaryButton(title: saving ? L10n.saving : L10n.finish, isLoading: saving) {
                    Task { await save() }
                }
            }
            .padding(24)
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty { await auth.updateDisplayName(trimmedName) }
        if let year = Int(birthYear.trimmingCharacters(in: .whitespaces)) {
            await auth.updateBirthYear(year)
        }
        UserPreferencesService.hasCompletedOnboardingV2 = true
        onFinish()
    }
}
