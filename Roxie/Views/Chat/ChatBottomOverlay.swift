import SwiftUI

struct ChatBottomOverlay: View {
    let chat: ChatManager
    var onOpenHistory: () -> Void
    var onToggleMic: (() -> Void)?
    var onToggleVideo: (() -> Void)? = nil
    var onCapture: () -> Void = {}
    var onSendPhoto: () -> Void = {}
    var onDance: () -> Void = {}
    var isDancing: Bool = false
    var isVoiceCallActive: Bool = false
    var isVideoCallActive: Bool = false
    var isInCall: Bool = false

    @State private var inputText: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Messages overlay — leaves ~80pt on right for character switcher (≈ native 23%)
            if chat.showChatList {
                messagesScroll
                    .frame(maxWidth: .infinity, maxHeight: 280, alignment: .bottomLeading)
                    .padding(.trailing, 80)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            // Action pills (Capture / Send Photo / Dance) — hide when in call
            if !inputFocused && !isInCall {
                ChatBottomActions(
                    onCapture: onCapture,
                    onSendPhoto: onSendPhoto,
                    onDance: onDance,
                    isDancing: isDancing
                )
                .transition(.opacity)
            }

            // Input bar — paddingHorizontal 12 inside the parent's padding 10
            ChatInputBar(
                text: $inputText,
                onSend: {
                    let toSend = inputText
                    Task { await chat.sendText(toSend) }
                    if !chat.showChatList {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            chat.toggleChatList()
                        }
                    }
                },
                onToggleMic: onToggleMic,
                onToggleVideo: onToggleVideo,
                isVoiceCallActive: isVoiceCallActive,
                isVideoCallActive: isVideoCallActive
            )
            .focused($inputFocused)
            .padding(.horizontal, 12)
            .onChange(of: inputText) { _, newValue in
                if !newValue.isEmpty && !chat.showChatList {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        chat.toggleChatList()
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, inputFocused ? 6 : 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.2), value: inputFocused)
    }

    private var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    if chat.messages.isEmpty && !chat.isTyping {
                        ChatMessageBubble(
                            message: ChatUIMessage(
                                id: "default",
                                kind: .text("What's on your mind? 💭"),
                                isAgent: true,
                                createdAt: Date()
                            ),
                            compact: true
                        )
                    } else {
                        ForEach(chat.messages) { msg in
                            ChatMessageBubble(message: msg, compact: true)
                                .id(msg.id)
                                .onTapGesture { onOpenHistory() }
                        }
                        if chat.isTyping {
                            HStack {
                                TypingIndicator()
                                Spacer(minLength: 0)
                            }
                            .padding(.leading, 4)
                            .id("typing")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: chat.messages.count) { _, _ in scrollToBottom(proxy) }
            .onChange(of: chat.isTyping) { _, _ in scrollToBottom(proxy) }
            .onAppear { scrollToBottom(proxy) }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if chat.isTyping {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = chat.messages.last?.id {
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }
}
