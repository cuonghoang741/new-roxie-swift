import SwiftUI

struct ChatBottomActions: View {
    @Environment(RemoteSettings.self) private var remote
    var onCapture: () -> Void
    var onSendPhoto: () -> Void
    var onDance: () -> Void
    var isDancing: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if remote.bool("show_btn_capture") {
                ActionTag(label: L10n.Cyber.actionCapture, systemImage: "viewfinder", tint: Cyber.cyan, action: onCapture)
            }
            if remote.bool("show_btn_send_media") {
                ActionTag(label: L10n.Cyber.actionSend, systemImage: "photo.stack", tint: Cyber.violet, action: onSendPhoto)
            }
            if remote.bool("show_btn_dance") {
                ActionTag(
                    label: isDancing ? L10n.Cyber.actionStop : L10n.Cyber.actionDance,
                    systemImage: isDancing ? "stop.circle.fill" : "music.note",
                    tint: isDancing ? Cyber.danger : Cyber.magenta,
                    action: onDance
                )
            }
        }
        .padding(.horizontal, 12)
    }
}

private struct ActionTag: View {
    let label: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .heavy))
                Text(label)
                    .font(Cyber.mono(10, weight: .heavy))
                    .tracking(1.4)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Cyber.surface.opacity(0.78).background(.ultraThinMaterial.opacity(0.4)))
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(tint.opacity(0.7), lineWidth: 1))
            .shadow(color: tint.opacity(0.45), radius: 5)
        }
        .buttonStyle(.plain)
    }
}
