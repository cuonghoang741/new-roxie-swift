import SwiftUI

private func isFreeTier(_ tier: String?) -> Bool {
    (tier ?? "free").lowercased() == "free"
}

private struct LockOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
            Image(systemName: "lock.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .padding(8)
                .background(
                    Circle().fill(Color.black.opacity(0.55))
                )
        }
    }
}

private struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#FFD91B"), Color(hex: "#FFE979")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .padding(6)
    }
}

struct CharacterSheet: View {
    let items: [CharacterItem]
    let ownedIds: Set<String>
    var onSelect: (CharacterItem) -> Void
    var onLockedTap: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]
    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        let locked = !isPro && !isFreeTier(item.tier) && !ownedIds.contains(item.id)
                        Button {
                            if locked { onLockedTap() } else { onSelect(item) }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    AsyncImage(url: URL(string: item.thumbnailUrl ?? item.avatar ?? "")) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Rectangle().fill(Color.gray.opacity(0.2))
                                    }
                                    .frame(height: 180)
                                    .clipped()

                                    if locked {
                                        LockOverlay()
                                        ProBadge()
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                                Text(item.name ?? "").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                if locked {
                                    Label("Pro", systemImage: "crown.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "#FFB800"))
                                } else if ownedIds.contains(item.id) {
                                    Label(L10n.owned, systemImage: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundStyle(Palette.Semantic.success)
                                } else {
                                    Label("Free", systemImage: "gift.fill")
                                        .font(.caption)
                                        .foregroundStyle(Palette.Semantic.success)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle(L10n.sheetCharacters)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.close) { dismiss() } } }
            .presentationDetents([.large])
        }
    }
}

struct BackgroundSheet: View {
    let items: [BackgroundItem]
    let ownedIds: Set<String>
    var onSelect: (BackgroundItem) -> Void
    var onLockedTap: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]
    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        let locked = !isPro && !isFreeTier(item.tier) && !ownedIds.contains(item.id)
                        Button {
                            if locked { onLockedTap() } else { onSelect(item) }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack(alignment: .topTrailing) {
                                    AsyncImage(url: URL(string: item.thumbnail ?? item.image ?? "")) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Rectangle().fill(Color.gray.opacity(0.2))
                                    }
                                    .frame(height: 120)
                                    .clipped()

                                    if locked {
                                        LockOverlay()
                                        ProBadge()
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(item.name ?? "")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle(L10n.sheetBackgrounds)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.close) { dismiss() } } }
            .presentationDetents([.large])
        }
    }
}

struct CostumeSheet: View {
    let items: [CostumeItem]
    let ownedIds: Set<String>
    var onSelect: (CostumeItem) -> Void
    var onLockedTap: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]
    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        NavigationStack {
            ScrollView {
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tshirt").font(.largeTitle).foregroundStyle(.secondary)
                        Text(L10n.noCostumes).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 120)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(items) { item in
                            let locked = !isPro && !isFreeTier(item.tier) && !ownedIds.contains(item.id)
                            Button {
                                if locked { onLockedTap() } else { onSelect(item) }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: URL(string: item.thumbnail ?? item.url ?? "")) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Rectangle().fill(Color.gray.opacity(0.2))
                                        }
                                        .frame(height: 160)
                                        .clipped()

                                        if locked {
                                            LockOverlay()
                                            ProBadge()
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(item.costumeName ?? "")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(L10n.sheetCostumes)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.close) { dismiss() } } }
            .presentationDetents([.large])
        }
    }
}

// SettingsSheet moved to its own file: SettingsSheet.swift
