import SwiftUI

struct ChatInputBar: View {
    @Environment(\.isDarkBackground) private var isDark
    @Binding var text: String
    var onSend: () -> Void
    var onToggleMic: (() -> Void)? = nil
    var onToggleVideo: (() -> Void)? = nil
    var isVoiceCallActive: Bool = false
    var isVideoCallActive: Bool = false
    var disabled: Bool = false
    var placeholder: String = "Chat"

    @FocusState private var focused: Bool

    private var showSend: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var fg: Color { ScenePalette.foreground(isDark: isDark) }
    private var glassTint: Color { ScenePalette.glassTint(isDark: isDark) }
    private var stroke: Color { ScenePalette.glassStroke(isDark: isDark) }
    private var placeholderColor: Color { ScenePalette.placeholder(isDark: isDark) }

    var body: some View {
        HStack(spacing: 6) {
            if let onToggleMic, !focused {
                Button(action: onToggleMic) {
                    Image(systemName: isVoiceCallActive ? "phone.down.fill" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isVoiceCallActive ? Color(hex: "#FF6EA1") : fg)
                        .frame(width: 44, height: 44)
                        .background(LiquidGlassBackground(cornerRadius: 22, tint: glassTint))
                }
                .transition(.scale.combined(with: .opacity))
            }

            if let onToggleVideo, !focused, isVoiceCallActive {
                Button(action: onToggleVideo) {
                    Image(systemName: isVideoCallActive ? "video.slash.fill" : "video.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isVideoCallActive ? Color(hex: "#FF6EA1") : fg)
                        .frame(width: 44, height: 44)
                        .background(LiquidGlassBackground(cornerRadius: 22, tint: glassTint))
                }
                .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: 4) {
                TextField("", text: $text, axis: .horizontal)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundStyle(placeholderColor)
                            .font(.system(size: 16))
                    }
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit { triggerSend() }
                    .padding(.leading, 16)
                    .padding(.vertical, 10)
                    .font(.system(size: 16))
                    .foregroundStyle(fg)
                    .tint(fg)
                    .disabled(disabled)

                Spacer(minLength: 0)

                if showSend {
                    Button(action: triggerSend) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(fg)
                            .frame(width: 36, height: 36)
                    }
                    .padding(.trailing, 4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(
                Capsule(style: .continuous).fill(.ultraThinMaterial)
            )
            .background(
                Capsule(style: .continuous).fill(glassTint)
            )
            .overlay(
                Capsule(style: .continuous).stroke(stroke, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.18), value: showSend)
        }
        .animation(.easeInOut(duration: 0.18), value: focused)
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
