import SwiftUI

struct ChatHistoryModal: View {
    let chat: ChatManager
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if chat.history.isEmpty && chat.historyLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(L10n.loading).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if chat.history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(L10n.chatEmptyHint)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    list
                }
            }
            .navigationTitle(L10n.chatHistoryTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close, action: onClose)
                }
            }
        }
        .task { await chat.loadInitialHistory() }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if !chat.historyReachedEnd {
                        Button {
                            Task { await chat.loadMoreHistory() }
                        } label: {
                            HStack(spacing: 8) {
                                if chat.historyLoading { ProgressView().controlSize(.small) }
                                Text(L10n.chatLoadMore)
                                    .font(.footnote.weight(.semibold))
                            }
                            .padding(8)
                        }
                    }

                    ForEach(chat.history) { msg in
                        VStack(alignment: msg.isAgent ? .leading : .trailing, spacing: 2) {
                            ChatMessageBubble(message: msg)
                            Text(msg.createdAt, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 14)
                        }
                        .frame(maxWidth: .infinity, alignment: msg.isAgent ? .leading : .trailing)
                        .id(msg.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: chat.history.count) { _, _ in
                if let last = chat.history.last?.id {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
        }
    }
}
