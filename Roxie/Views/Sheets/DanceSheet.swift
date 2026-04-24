import SwiftUI

struct DanceSheet: View {
    let items: [DanceItem]
    let ownedIds: Set<String>
    var onPlay: (DanceItem) -> Void
    var onLockedTap: () -> Void
    var onStop: () -> Void
    var isDancing: Bool

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]
    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        let locked = !isPro && (item.tier ?? "free").lowercased() != "free" && !ownedIds.contains(item.id)
                        Button {
                            if locked { onLockedTap() } else { onPlay(item); dismiss() }
                        } label: {
                            DanceTile(item: item, locked: locked)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Dance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button(L10n.close) { dismiss() } }
                if isDancing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onStop()
                            dismiss()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

private struct DanceTile: View {
    let item: DanceItem
    let locked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .aspectRatio(1, contentMode: .fit)

                if let url = item.iconUrl, let u = URL(string: url) {
                    AsyncImage(url: u) { img in
                        img.resizable().scaledToFit().padding(12)
                    } placeholder: {
                        Text(item.emoji ?? "💃").font(.system(size: 36))
                    }
                } else {
                    Text(item.emoji ?? "💃").font(.system(size: 36))
                }

                if locked {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.4))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(item.name ?? "")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if locked {
                Label("Pro", systemImage: "crown.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "#FFB800"))
            }
        }
    }
}
