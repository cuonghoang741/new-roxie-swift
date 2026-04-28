import SwiftUI

struct MediaSheet: View {
    let items: [MediaItem]
    let ownedIds: Set<String>
    var onSend: (MediaItem) -> Void
    var onLockedTap: () -> Void

    @State private var tab: Tab = .photo

    enum Tab: String, CaseIterable, Identifiable {
        case photo = "PHOTO"
        case video = "VIDEO"
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
        CyberSheetChrome(title: L10n.Cyber.sheetVault,
                         subtitle: String(format: L10n.Cyber.sheetVaultSub, items.count),
                         tint: Cyber.violet) {
            VStack(spacing: 0) {
                segmented
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                ScrollView {
                    if filtered.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: tab == .video ? "video.slash" : "photo.on.rectangle.angled")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundStyle(Cyber.violet.opacity(0.5))
                            Text(L10n.Cyber.emptyVault)
                                .font(Cyber.mono(11, weight: .heavy))
                                .foregroundStyle(Cyber.textDim)
                                .tracking(1.4)
                        }
                        .padding(.top, 100)
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(filtered) { item in
                                let isFree = (item.tier ?? "free").lowercased() == "free"
                                let owned = ownedIds.contains(item.id)
                                let locked = !isPro && !isFree && !owned
                                Button {
                                    if locked { onLockedTap() } else { onSend(item) }
                                } label: {
                                    MediaTile(item: item, locked: locked)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .presentationDetents([.large])
    }

    private var segmented: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { t in
                Button { tab = t } label: {
                    Text(t.rawValue)
                        .font(Cyber.mono(11, weight: .heavy))
                        .tracking(1.6)
                        .foregroundStyle(tab == t ? Cyber.bg : Cyber.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(tab == t ? Cyber.cyan : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Cyber.surface.opacity(0.85))
        .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.5), lineWidth: 1))
    }
}

private struct MediaTile: View {
    let item: MediaItem
    let locked: Bool

    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: item.thumbnail ?? item.url ?? "")) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Cyber.surfaceHi
            }
            .blur(radius: locked ? 14 : 0)

            if locked { CyberLockOverlay() }

            if (item.contentType?.hasPrefix("video") ?? false) && !locked {
                ZStack {
                    Rectangle().fill(Cyber.bg.opacity(0.4))
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Cyber.text)
                        .frame(width: 36, height: 36)
                        .background(Cyber.violet)
                        .clipShape(Circle())
                        .shadow(color: Cyber.violet.opacity(0.7), radius: 8)
                }
            }

            VStack { Spacer(); CornerBrackets(tint: Cyber.violet, size: 7) }
        }
        .aspectRatio(3/4, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Cyber.violet.opacity(0.5), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
