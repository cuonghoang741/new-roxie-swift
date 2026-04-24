import SwiftUI

struct CharacterPreviewScreen: View {
    var characters: [CharacterItem]
    var ownedIds: Set<String>
    var initialIndex: Int
    var onPick: (CharacterItem) -> Void
    var onDismiss: () -> Void

    @State private var index: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.GrayDark.s900.ignoresSafeArea()

                if characters.isEmpty {
                    ProgressView(L10n.loadingCharacters).tint(.white)
                } else {
                    TabView(selection: $index) {
                        ForEach(characters.indices, id: \.self) { i in
                            let character = characters[i]
                            CharacterCard(character: character, isOwned: ownedIds.contains(character.id))
                                .tag(i)
                                .padding(.horizontal, 16)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                }

                VStack {
                    Spacer()
                    if let character = currentCharacter {
                        PrimaryButton(title: ownedIds.contains(character.id) ? L10n.pick : L10n.viewDetail) {
                            onPick(character)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle(L10n.chooseCharacter)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.close) { onDismiss() }
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                index = min(max(0, initialIndex), max(0, characters.count - 1))
            }
        }
    }

    private var currentCharacter: CharacterItem? {
        guard characters.indices.contains(index) else { return nil }
        return characters[index]
    }
}

private struct CharacterCard: View {
    let character: CharacterItem
    let isOwned: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if let url = URL(string: character.thumbnailUrl ?? character.avatar ?? "") {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.15))
                    }
                } else {
                    Rectangle().fill(Color.gray.opacity(0.15))
                }
            }
            .frame(height: 420)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(spacing: 6) {
                Text(character.name ?? "")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                if let description = character.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(3)
                }
                if !isOwned {
                    HStack(spacing: 8) {
                        if let price = character.priceRuby {
                            Label("\(price)", systemImage: "diamond.fill")
                                .foregroundStyle(Palette.Brand.s300)
                        }
                        if let price = character.priceVcoin {
                            Label("\(price)", systemImage: "dollarsign.circle.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    .font(.footnote)
                }
            }
        }
    }
}
