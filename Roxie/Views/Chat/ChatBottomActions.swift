import SwiftUI

struct ChatBottomActions: View {
    @Environment(\.isDarkBackground) private var isDark
    var onCapture: () -> Void
    var onSendPhoto: () -> Void
    var onDance: () -> Void
    var isDancing: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            ActionPill(systemImage: "camera", label: "Capture", action: onCapture)
            ActionPill(systemImage: "heart", label: "Send photo", action: onSendPhoto)
            ActionPill(
                systemImage: isDancing ? "xmark" : "music.note",
                label: "Dance",
                action: onDance
            )
        }
        .padding(.horizontal, 12)
    }
}

private struct ActionPill: View {
    @Environment(\.isDarkBackground) private var isDark
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(ScenePalette.foreground(isDark: isDark))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(.ultraThinMaterial)
            )
            .background(
                Capsule().fill(ScenePalette.glassTint(isDark: isDark))
            )
            .overlay(
                Capsule().stroke(ScenePalette.glassStroke(isDark: isDark), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
