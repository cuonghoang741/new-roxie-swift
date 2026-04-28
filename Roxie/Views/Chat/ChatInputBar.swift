import SwiftUI

struct ChatInputBar: View {
    @Environment(RemoteSettings.self) private var remote
    @Binding var text: String
    var onSend: () -> Void
    var onToggleMic: (() -> Void)? = nil
    var onToggleVideo: (() -> Void)? = nil
    var isVoiceCallActive: Bool = false
    var isVideoCallActive: Bool = false
    var disabled: Bool = false
    var placeholder: String = L10n.Cyber.inputPlaceholder

    @FocusState private var focused: Bool

    private var showSend: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        HStack(spacing: 8) {
            if let onToggleMic, !focused, remote.bool("show_btn_voice_call") {
                hudButton(
                    isVoiceCallActive ? "phone.down.fill" : "mic.fill",
                    tint: isVoiceCallActive ? Cyber.danger : Cyber.cyan,
                    action: onToggleMic
                )
                .transition(.scale.combined(with: .opacity))
            }
            if let onToggleVideo, !focused, isVoiceCallActive, remote.bool("show_btn_video_call") {
                hudButton(
                    isVideoCallActive ? "video.slash.fill" : "video.fill",
                    tint: isVideoCallActive ? Cyber.danger : Cyber.violet,
                    action: onToggleVideo
                )
                .transition(.scale.combined(with: .opacity))
            }

            inputField
        }
        .animation(.easeInOut(duration: 0.18), value: focused)
    }

    private var inputField: some View {
        HStack(spacing: 6) {
            Text(">")
                .font(Cyber.mono(15, weight: .heavy))
                .foregroundStyle(Cyber.cyan)

            TextField("", text: $text, axis: .horizontal)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .font(Cyber.mono(13, weight: .semibold))
                        .foregroundStyle(Cyber.textDim)
                        .tracking(1.2)
                }
                .textFieldStyle(.plain)
                .focused($focused)
                .submitLabel(.send)
                .onSubmit { triggerSend() }
                .font(Cyber.mono(14, weight: .semibold))
                .foregroundStyle(Cyber.text)
                .tint(Cyber.cyan)
                .disabled(disabled)

            if showSend {
                Button(action: triggerSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Cyber.bg)
                        .frame(width: 30, height: 30)
                        .background(Cyber.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: Cyber.cyan.opacity(0.7), radius: 6)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(Cyber.surface.opacity(0.85).background(.ultraThinMaterial.opacity(0.4)))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(focused ? Cyber.cyan : Cyber.cyan.opacity(0.4), lineWidth: focused ? 1.5 : 1)
        )
        .shadow(color: focused ? Cyber.cyan.opacity(0.5) : .clear, radius: focused ? 6 : 0)
        .animation(.easeInOut(duration: 0.18), value: focused)
        .animation(.easeInOut(duration: 0.18), value: showSend)
    }

    private func hudButton(_ system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(Cyber.surface.opacity(0.85).background(.ultraThinMaterial.opacity(0.4)))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(tint.opacity(0.7), lineWidth: 1))
                .shadow(color: tint.opacity(0.5), radius: 5)
        }
    }

    private func triggerSend() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSend()
        text = ""
    }
}

private extension View {
    @ViewBuilder
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0).allowsHitTesting(false)
            self
        }
    }
}
