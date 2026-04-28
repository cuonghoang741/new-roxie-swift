import SwiftUI

struct CharacterPreviewScreen: View {
    var characters: [CharacterItem]
    var ownedIds: Set<String>
    var initialIndex: Int
    var onPick: (CharacterItem) -> Void
    var onDismiss: () -> Void

    @State private var index: Int = 0

    var body: some View {
        ZStack {
            Cyber.bg.ignoresSafeArea()
            CyberGridBackdrop().opacity(0.18).ignoresSafeArea()
            ScanLineBackdrop().ignoresSafeArea()

            if characters.isEmpty {
                VStack(spacing: 10) {
                    ProgressView().tint(Cyber.cyan).scaleEffect(1.2)
                    Text(L10n.Cyber.loadingRoster)
                        .font(Cyber.mono(11, weight: .heavy))
                        .foregroundStyle(Cyber.textDim)
                        .tracking(1.4)
                }
            } else {
                VStack(spacing: 0) {
                    header
                    TabView(selection: $index) {
                        ForEach(characters.indices, id: \.self) { i in
                            CharacterCard(character: characters[i], isOwned: ownedIds.contains(characters[i].id))
                                .padding(.horizontal, 16)
                                .padding(.top, 6)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    counterStrip

                    if let character = currentCharacter {
                        Button {
                            onPick(character)
                        } label: {
                            HStack(spacing: 10) {
                                Text(ownedIds.contains(character.id) ? L10n.Cyber.charSelect : L10n.Cyber.charPreview)
                                    .font(Cyber.mono(13, weight: .heavy))
                                    .tracking(1.6)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .heavy))
                            }
                            .foregroundStyle(Cyber.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shadow(color: Cyber.cyan.opacity(0.7), radius: 10)
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .onAppear {
            index = min(max(0, initialIndex), max(0, characters.count - 1))
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { onDismiss() } label: {
                ZStack {
                    Rectangle().fill(Cyber.surface.opacity(0.85))
                    Rectangle().stroke(Cyber.cyan.opacity(0.7), lineWidth: 1)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Cyber.cyan)
                }
                .frame(width: 36, height: 36)
                .shadow(color: Cyber.cyan.opacity(0.5), radius: 5)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Cyber.charCompanions)
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.cyan)
                    .tracking(1.6)
                Text(L10n.Cyber.charSelectPartner)
                    .font(Cyber.mono(12, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1.2)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var counterStrip: some View {
        HStack {
            Text("[\(index + 1)/\(characters.count)]")
                .font(Cyber.mono(10, weight: .heavy))
                .foregroundStyle(Cyber.textDim)
                .tracking(1.4)
            Spacer()
            HStack(spacing: 4) {
                ForEach(characters.indices, id: \.self) { i in
                    Rectangle()
                        .fill(i == index ? Cyber.cyan : Cyber.textMuted)
                        .frame(width: i == index ? 18 : 4, height: 3)
                        .animation(.easeInOut(duration: 0.25), value: index)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
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
            ZStack(alignment: .topTrailing) {
                if let url = URL(string: character.thumbnailUrl ?? character.avatar ?? "") {
                    AsyncImage(url: url) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Cyber.surfaceHi
                    }
                } else {
                    Cyber.surfaceHi
                }

                CornerBrackets(tint: Cyber.cyan, size: 14, thickness: 1.5)

                if isOwned {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .heavy))
                        Text(L10n.Cyber.owned)
                            .font(Cyber.mono(9, weight: .heavy))
                            .tracking(1.4)
                    }
                    .foregroundStyle(Cyber.bg)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Cyber.lime)
                    .padding(10)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 420)
            .background(Cyber.surface)
            .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.4), lineWidth: 1))
            .clipShape(Rectangle())

            VStack(spacing: 4) {
                Text((character.name ?? "—").uppercased())
                    .font(Cyber.mono(18, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1.6)
                if let description = character.description {
                    Text(description)
                        .font(Cyber.mono(11, weight: .semibold))
                        .foregroundStyle(Cyber.textDim)
                        .tracking(0.6)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                if !isOwned {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill").font(.system(size: 10, weight: .heavy))
                        Text(L10n.Cyber.proRequired)
                            .font(Cyber.mono(10, weight: .heavy))
                            .tracking(1.4)
                    }
                    .foregroundStyle(Cyber.magenta)
                }
            }
        }
    }
}
