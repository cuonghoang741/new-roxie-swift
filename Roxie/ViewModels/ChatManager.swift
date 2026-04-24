import Foundation
import SwiftUI

/// Port of `src/hooks/useChatManager.ts`. Holds all chat state for the
/// currently-selected character and orchestrates the send → edge function →
/// typed-reply streaming flow.
@MainActor
@Observable
final class ChatManager {
    // MARK: - State

    private(set) var messages: [ChatUIMessage] = []
    private(set) var history: [ChatUIMessage] = []
    private(set) var historyLoading: Bool = false
    private(set) var historyReachedEnd: Bool = false
    private(set) var isTyping: Bool = false

    var showChatList: Bool = true
    var showChatHistoryFullScreen: Bool = false

    var characterId: String?
    var characterName: String?
    var isPro: Bool = false

    /// Fired for each agent message (used to drive TTS / mouth animation).
    var onAgentReply: ((String) -> Void)?

    private let service = ChatService.shared
    private let overlayLimit = 20

    // MARK: - Character lifecycle

    func configure(characterId: String?, characterName: String?, isPro: Bool) {
        let changed = self.characterId != characterId
        self.characterId = characterId
        self.characterName = characterName
        self.isPro = isPro

        if changed {
            messages = []
            history = []
            historyReachedEnd = false
            if let cid = characterId {
                Task { await loadRecent(for: cid) }
            }
        }
    }

    // MARK: - Fetch

    func loadRecent(for characterId: String, limit: Int = 5) async {
        do {
            let recent = try await service.fetchRecentMessages(characterId: characterId, limit: limit)
            messages = recent
        } catch {
            Log.app.error("loadRecent failed: \(error.localizedDescription)")
        }
    }

    func loadInitialHistory() async {
        guard let cid = characterId, history.isEmpty else { return }
        await loadMoreHistory()
    }

    func loadMoreHistory() async {
        guard let cid = characterId, !historyLoading, !historyReachedEnd else { return }
        historyLoading = true
        defer { historyLoading = false }

        let cursor = history.first?.createdAt
        do {
            let page = try await service.fetchHistory(characterId: cid, cursor: cursor)
            history = page.messages + history
            historyReachedEnd = page.reachedEnd
        } catch {
            Log.app.error("loadMoreHistory failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Send

    func sendText(_ raw: String) async {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let characterId else { return }

        let userMessage = ChatUIMessage(
            id: UUID().uuidString,
            kind: .text(text),
            isAgent: false,
            createdAt: Date()
        )
        append(userMessage)

        // Persist user message in background.
        Task { await service.persist(text: text, isAgent: false, characterId: characterId) }

        isTyping = true

        do {
            let replies = try await service.sendToGemini(
                text: text,
                characterId: characterId,
                characterName: characterName ?? "",
                history: messages,
                isPro: isPro
            )

            if replies.isEmpty {
                isTyping = false
                return
            }

            for (idx, reply) in replies.enumerated() {
                if idx > 0 {
                    isTyping = true
                    let delay = UInt64.random(in: 800_000_000...1_500_000_000)
                    try? await Task.sleep(nanoseconds: delay)
                }
                let agentMessage = ChatUIMessage(
                    id: UUID().uuidString,
                    kind: .text(reply),
                    isAgent: true,
                    createdAt: Date()
                )
                append(agentMessage)
                onAgentReply?(reply)

                // Persist each agent message.
                Task { await service.persist(text: reply, isAgent: true, characterId: characterId) }
            }
            isTyping = false
        } catch {
            Log.app.error("sendToGemini failed: \(error.localizedDescription)")
            let fallback = ChatUIMessage(
                id: UUID().uuidString,
                kind: .text(L10n.errorNetwork),
                isAgent: true,
                createdAt: Date()
            )
            append(fallback)
            isTyping = false
        }
    }

    // MARK: - Overlay helpers

    func toggleChatList() {
        showChatList.toggle()
    }

    func openHistory() {
        showChatHistoryFullScreen = true
        Task { await loadInitialHistory() }
    }

    func closeHistory() {
        showChatHistoryFullScreen = false
    }

    func sendMedia(_ media: MediaItem) async {
        let message = ChatUIMessage(
            id: UUID().uuidString,
            kind: .media(media),
            isAgent: false,
            createdAt: Date()
        )
        append(message)
        if !showChatList { showChatList = true }
    }

    func addAgentMessage(_ text: String, persist: Bool = true) {
        let message = ChatUIMessage(
            id: UUID().uuidString,
            kind: .text(text),
            isAgent: true,
            createdAt: Date()
        )
        append(message)
        if persist, let cid = characterId {
            Task { await service.persist(text: text, isAgent: true, characterId: cid) }
        }
    }

    // MARK: - Internal

    private func append(_ message: ChatUIMessage) {
        messages.append(message)
        if messages.count > overlayLimit {
            messages.removeFirst(messages.count - overlayLimit)
        }
    }
}
