import SwiftUI

struct ChatHistoryModal: View {
    let chat: ChatManager
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Cyber.bg.ignoresSafeArea()
            CyberGridBackdrop().opacity(0.18).ignoresSafeArea()
            ScanLineBackdrop().ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().background(Cyber.cyan.opacity(0.4))
                Group {
                    if chat.history.isEmpty && chat.historyLoading {
                        loadingState
                    } else if chat.history.isEmpty {
                        emptyState
                    } else {
                        list
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await chat.loadInitialHistory() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("//")
                .font(Cyber.mono(13, weight: .heavy))
                .foregroundStyle(Cyber.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Cyber.sheetChatLog)
                    .font(Cyber.mono(13, weight: .heavy))
                    .foregroundStyle(Cyber.text)
                    .tracking(1.6)
                Text(String(format: L10n.Cyber.archiveCount, chat.history.count))
                    .font(Cyber.mono(9, weight: .semibold))
                    .foregroundStyle(Cyber.textDim)
                    .tracking(1.4)
            }
            Spacer()
            Button(action: onClose) {
                ZStack {
                    Rectangle().fill(Cyber.surface.opacity(0.85))
                    Rectangle().stroke(Cyber.cyan.opacity(0.7), lineWidth: 1)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Cyber.cyan)
                }
                .frame(width: 36, height: 36)
                .shadow(color: Cyber.cyan.opacity(0.5), radius: 5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView().tint(Cyber.cyan).scaleEffect(1.2)
            Text(L10n.Cyber.loadingArchive)
                .font(Cyber.mono(11, weight: .heavy))
                .foregroundStyle(Cyber.textDim)
                .tracking(1.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(Cyber.cyan.opacity(0.5))
            Text(L10n.Cyber.logEmpty)
                .font(Cyber.mono(11, weight: .heavy))
                .foregroundStyle(Cyber.textDim)
                .tracking(1.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if !chat.historyReachedEnd {
                        Button {
                            Task { await chat.loadMoreHistory() }
                        } label: {
                            HStack(spacing: 6) {
                                if chat.historyLoading { ProgressView().tint(Cyber.cyan).controlSize(.small) }
                                Text(L10n.Cyber.loadMore)
                                    .font(Cyber.mono(10, weight: .heavy))
                                    .foregroundStyle(Cyber.cyan)
                                    .tracking(1.4)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .overlay(Rectangle().stroke(Cyber.cyan.opacity(0.5), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(chat.history) { msg in
                        VStack(alignment: .leading, spacing: 2) {
                            ChatMessageBubble(message: msg, compact: false)
                            Text(timestamp(msg.createdAt))
                                .font(Cyber.mono(9, weight: .semibold))
                                .foregroundStyle(Cyber.textMuted)
                                .tracking(1)
                                .padding(.leading, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(msg.id)
                    }
                }
                .padding(14)
            }
            .scrollIndicators(.hidden)
            .onChange(of: chat.history.count) { _, _ in
                if let last = chat.history.last?.id {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
        }
    }

    private func timestamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return "[ \(f.string(from: date)) ]"
    }
}
