import SwiftUI

struct MediaSheet: View {
    let items: [MediaItem]
    let ownedIds: Set<String>
    var onSend: (MediaItem) -> Void
    var onLockedTap: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .photo

    enum Tab: String, CaseIterable, Identifiable {
        case photo = "Photo"
        case video = "Video"
        var id: String { rawValue }
    }

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]
    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    private var filtered: [MediaItem] {
        items.filter { item in
            let isVideo = (item.contentType?.hasPrefix("video") ?? false)
                || (item.url?.lowercased().hasSuffix(".mp4") ?? false)
                || item.mediaType == "video"
            return tab == .video ? isVideo : !isVideo
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Type", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ScrollView {
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: tab == .video ? "video.slash" : "photo.on.rectangle.angled")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("No \(tab.rawValue.lowercased())s yet")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 80)
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(filtered) { item in
                                let isFree = (item.tier ?? "free").lowercased() == "free"
                                let owned = ownedIds.contains(item.id)
                                let locked = !isPro && !isFree && !owned
                                Button {
                                    if locked { onLockedTap() } else { onSend(item); dismiss() }
                                } label: {
                                    MediaTile(item: item, locked: locked)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .navigationTitle("Send Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button(L10n.close) { dismiss() } } }
            .presentationDetents([.large])
        }
    }
}

private struct MediaTile: View {
    let item: MediaItem
    let locked: Bool

    var body: some View {
        ZStack {
            Color.gray.opacity(0.15)

            AsyncImage(url: URL(string: item.thumbnail ?? item.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.15)
            }
            .blur(radius: locked ? 14 : 0)

            if locked {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                VStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("PRO")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(colors: [Color(hex: "#FFD91B"), Color(hex: "#FFE979")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            if (item.contentType?.hasPrefix("video") ?? false) && !locked {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
