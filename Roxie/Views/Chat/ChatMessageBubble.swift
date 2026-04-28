import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatUIMessage
    var compact: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            bubble
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var bubble: some View {
        switch message.kind {
        case .text(let text):
            textBubble(text, isSystem: false)
        case .system(let text):
            textBubble(text, isSystem: true)
        case .media(let media):
            mediaBubble(media)
        case .upgradeButton:
            upgradeBubble
        }
    }

    private func textBubble(_ text: String, isSystem: Bool) -> some View {
        let accent: Color = isSystem ? Cyber.amber : (message.isAgent ? Cyber.cyan : Cyber.magenta)
        let tag: String = isSystem ? "SYS" : (message.isAgent ? "AGT" : "USR")

        return HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: 2)
                .shadow(color: accent.opacity(0.8), radius: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(tag)
                    .font(Cyber.mono(9, weight: .heavy))
                    .foregroundStyle(accent)
                    .tracking(1.4)
                Text(text)
                    .font(.system(size: compact ? 13 : 14, weight: .medium))
                    .foregroundStyle(Cyber.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(
            Cyber.surface.opacity(0.8)
                .background(.ultraThinMaterial.opacity(0.5))
        )
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .continuous)
                .stroke(accent.opacity(0.35), lineWidth: 1)
        )
        .clipShape(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .continuous)
        )
    }

    private func mediaBubble(_ media: MediaItem) -> some View {
        ZStack {
            AsyncImage(url: URL(string: media.thumbnail ?? media.url ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Cyber.surfaceHi
            }
            CornerBrackets(tint: Cyber.cyan, size: 12)
        }
        .frame(width: 200, height: 268)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Cyber.cyan.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Cyber.cyan.opacity(0.4), radius: 8)
    }

    private var upgradeBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 12, weight: .bold))
            Text("UPGRADE //PRO")
                .font(Cyber.mono(11, weight: .heavy))
                .tracking(1.2)
        }
        .foregroundStyle(Cyber.bg)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            LinearGradient(colors: [Cyber.cyan, Cyber.magenta], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: Cyber.magenta.opacity(0.6), radius: 10)
    }
}
