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
        case .text(let text), .system(let text):
            textBubble(text)
        case .media(let media):
            mediaBubble(media)
        case .upgradeButton:
            upgradeBubble
        }
    }

    private func textBubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: compact ? 13 : 14))
            .lineSpacing(compact ? 4 : 6)
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, compact ? 10 : 12)
            .padding(.vertical, compact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(message.isAgent
                          ? Color(red: 244/255, green: 28/255, blue: 42/255).opacity(0.33)
                          : Color(red: 15/255, green: 15/255, blue: 15/255).opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(message.isAgent
                            ? Color(red: 244/255, green: 28/255, blue: 42/255).opacity(0.40)
                            : Color.white.opacity(0.12), lineWidth: 1)
            )
    }

    private func mediaBubble(_ media: MediaItem) -> some View {
        AsyncImage(url: URL(string: media.thumbnail ?? media.url ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Rectangle().fill(Color.black.opacity(0.4))
        }
        .frame(width: 200, height: 268)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var upgradeBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text(L10n.chatUpgradePro)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(
            Capsule().fill(Color(red: 17/255, green: 17/255, blue: 17/255))
        )
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: Color(hex: "#FF3E8A").opacity(0.4), radius: 10, x: 0, y: 4)
    }
}
