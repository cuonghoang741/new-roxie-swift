import SwiftUI

struct DanceSheet: View {
    let items: [DanceItem]
    let ownedIds: Set<String>
    var onPlay: (DanceItem) -> Void
    var onLockedTap: () -> Void
    var onStop: () -> Void
    var isDancing: Bool

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]
    private var isPro: Bool { RevenueCatManager.shared.isProUser }

    var body: some View {
        CyberSheetChrome(title: L10n.Cyber.sheetChoreo,
                         subtitle: String(format: L10n.Cyber.sheetChoreoSub, items.count),
                         tint: Cyber.magenta) {
            VStack(spacing: 0) {
                if isDancing {
                    Button {
                        onStop()
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill").font(.system(size: 12, weight: .heavy))
                            Text(L10n.Cyber.stopRoutine)
                                .font(Cyber.mono(11, weight: .heavy))
                                .tracking(1.4)
                            Spacer()
                            StatusDot(tint: Cyber.danger)
                        }
                        .foregroundStyle(Cyber.bg)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Cyber.danger)
                        .overlay(CornerBrackets(tint: Cyber.bg.opacity(0.4), size: 6))
                        .shadow(color: Cyber.danger.opacity(0.6), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(items) { item in
                            let locked = !isPro && (item.tier ?? "free").lowercased() != "free" && !ownedIds.contains(item.id)
                            Button {
                                if locked { onLockedTap() } else { onPlay(item) }
                            } label: {
                                DanceTile(item: item, locked: locked)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                }
                .scrollIndicators(.hidden)
            }
        }
        .presentationDetents([.large])
    }
}

private struct DanceTile: View {
    let item: DanceItem
    let locked: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle().fill(Cyber.surface)
                if let url = item.iconUrl, let u = URL(string: url) {
                    AsyncImage(url: u) { img in
                        img.resizable().scaledToFit().padding(10)
                    } placeholder: {
                        Text(item.emoji ?? "💃").font(.system(size: 36))
                    }
                } else {
                    Text(item.emoji ?? "💃").font(.system(size: 36))
                }
                if locked { CyberLockOverlay() }
            }
            .aspectRatio(1, contentMode: .fit)

            VStack(spacing: 2) {
                Text((item.name ?? "—").uppercased())
                    .font(Cyber.mono(10, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1)
                    .lineLimit(1)
                if locked {
                    Text(L10n.Cyber.proOnly).font(Cyber.mono(8, weight: .heavy))
                        .foregroundStyle(Cyber.magenta).tracking(1.2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Cyber.surface.opacity(0.95))
        }
        .overlay(Rectangle().stroke(Cyber.magenta.opacity(0.5), lineWidth: 1))
        .overlay(CornerBrackets(tint: Cyber.magenta, size: 7))
    }
}
