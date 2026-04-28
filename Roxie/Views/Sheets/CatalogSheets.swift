import SwiftUI

private func isFreeTier(_ tier: String?) -> Bool {
    (tier ?? "free").lowercased() == "free"
}

// MARK: - Character

struct CharacterSheet: View {
    let items: [CharacterItem]
    let ownedIds: Set<String>
    var onSelect: (CharacterItem) -> Void
    var onLockedTap: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]
    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        CyberSheetChrome(title: L10n.Cyber.sheetCompanions,
                         subtitle: String(format: L10n.Cyber.sheetCompanionsSub, items.count),
                         tint: Cyber.cyan) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(items) { item in
                        let locked = !isPro && !isFreeTier(item.tier) && !ownedIds.contains(item.id)
                        Button {
                            if locked { onLockedTap() } else { onSelect(item) }
                        } label: {
                            CharacterTile(item: item, owned: ownedIds.contains(item.id), locked: locked)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.large])
    }
}

private struct CharacterTile: View {
    let item: CharacterItem
    let owned: Bool
    let locked: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                AsyncImage(url: URL(string: item.thumbnailUrl ?? item.avatar ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: { Cyber.surfaceHi }

                if locked { CyberLockOverlay() }
            }
            .frame(height: 180)
            .clipped()

            // Bottom info plate
            VStack(alignment: .leading, spacing: 3) {
                Text((item.name ?? "—").uppercased())
                    .font(Cyber.mono(11, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1.2)
                    .lineLimit(1)
                if locked {
                    Text(L10n.Cyber.proOnly).font(Cyber.mono(9, weight: .heavy))
                        .foregroundStyle(Cyber.magenta).tracking(1.2)
                } else if owned {
                    CyberOwnedBadge()
                } else {
                    CyberFreeBadge()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(
                LinearGradient(colors: [.clear, Cyber.bg.opacity(0.95)], startPoint: .top, endPoint: .bottom)
            )
        }
        .frame(height: 180)
        .background(Cyber.surface)
        .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.45), lineWidth: 1))
        .overlay(CornerBrackets(tint: Cyber.cyan, size: 8))
    }
}

// MARK: - Background

struct BackgroundSheet: View {
    let items: [BackgroundItem]
    let ownedIds: Set<String>
    var onSelect: (BackgroundItem) -> Void
    var onLockedTap: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 10)]
    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        CyberSheetChrome(title: L10n.Cyber.sheetEnvironments,
                         subtitle: String(format: L10n.Cyber.sheetEnvironmentsSub, items.count),
                         tint: Cyber.violet) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(items) { item in
                        let locked = !isPro && !isFreeTier(item.tier) && !ownedIds.contains(item.id)
                        Button {
                            if locked { onLockedTap() } else { onSelect(item) }
                        } label: {
                            BackgroundTile(item: item, owned: ownedIds.contains(item.id), locked: locked)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.large])
    }
}

private struct BackgroundTile: View {
    let item: BackgroundItem
    let owned: Bool
    let locked: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                AsyncImage(url: URL(string: item.thumbnail ?? item.image ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: { Cyber.surfaceHi }
                if locked { CyberLockOverlay() }
            }
            .frame(height: 120)
            .clipped()

            HStack {
                Text((item.name ?? "—").uppercased())
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1)
                    .lineLimit(1)
                Spacer()
                if owned {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Cyber.lime)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(LinearGradient(colors: [.clear, Cyber.bg.opacity(0.95)], startPoint: .top, endPoint: .bottom))
        }
        .frame(height: 120)
        .background(Cyber.surface)
        .overlay(Rectangle().stroke(Cyber.violet.opacity(0.5), lineWidth: 1))
        .overlay(CornerBrackets(tint: Cyber.violet, size: 8))
    }
}

// MARK: - Costume

struct CostumeSheet: View {
    let items: [CostumeItem]
    let ownedIds: Set<String>
    var onSelect: (CostumeItem) -> Void
    var onLockedTap: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 10)]
    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        CyberSheetChrome(title: L10n.Cyber.sheetOutfits,
                         subtitle: String(format: L10n.Cyber.sheetOutfitsSub, items.count),
                         tint: Cyber.magenta) {
            ScrollView {
                if items.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundStyle(Cyber.cyan.opacity(0.5))
                        Text(L10n.Cyber.emptyOutfits)
                            .font(Cyber.mono(11, weight: .heavy))
                            .foregroundStyle(Cyber.textDim)
                            .tracking(1.4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 120)
                } else {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(items) { item in
                            let locked = !isPro && !isFreeTier(item.tier) && !ownedIds.contains(item.id)
                            Button {
                                if locked { onLockedTap() } else { onSelect(item) }
                            } label: {
                                CostumeTile(item: item, owned: ownedIds.contains(item.id), locked: locked)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                }
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.large])
    }
}

private struct CostumeTile: View {
    let item: CostumeItem
    let owned: Bool
    let locked: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                AsyncImage(url: URL(string: item.thumbnail ?? item.url ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: { Cyber.surfaceHi }
                if locked { CyberLockOverlay() }
            }
            .frame(height: 160)
            .clipped()

            HStack {
                Text((item.costumeName ?? "—").uppercased())
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1)
                    .lineLimit(1)
                Spacer()
                if owned {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Cyber.lime)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(LinearGradient(colors: [.clear, Cyber.bg.opacity(0.95)], startPoint: .top, endPoint: .bottom))
        }
        .frame(height: 160)
        .background(Cyber.surface)
        .overlay(Rectangle().stroke(Cyber.magenta.opacity(0.5), lineWidth: 1))
        .overlay(CornerBrackets(tint: Cyber.magenta, size: 8))
    }
}

// SettingsSheet moved to its own file: SettingsSheet.swift
