import Foundation
import Supabase

/// Port of `src/services/ChatService.ts`. Talks to the `conversation` table
/// and the `gemini-chat` edge function.
@MainActor
final class ChatService {
    static let shared = ChatService()

    private let client = SupabaseService.shared.client

    // MARK: - Row models

    private struct ConversationRow: Codable {
        let id: String
        let message: String?
        let is_agent: Bool?
        let created_at: String?
        let media_id: String?
        let medias: MediaItem?
    }

    private struct InsertRow: Encodable {
        let message: String
        let is_agent: Bool
        let character_id: String
        let user_id: String?
        let client_id: String?
        let media_id: String?
    }

    // MARK: - Public API

    func fetchRecentMessages(characterId: String, limit: Int = 5) async throws -> [ChatUIMessage] {
        let identifier = await AuthIdentifierProvider.current(userId: await currentUserId())
        var query = client
            .from("conversation")
            .select("id, message, is_agent, created_at, media_id, medias(*)")
            .eq("character_id", value: characterId)

        if let uid = identifier.userId {
            query = query.eq("user_id", value: uid)
        } else if let cid = identifier.clientId {
            query = query.eq("client_id", value: cid)
        } else {
            return []
        }

        let rows: [ConversationRow] = try await query
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return rows.reversed().map(Self.map)
    }

    func fetchHistory(characterId: String, cursor: Date? = nil, limit: Int = 20) async throws -> (messages: [ChatUIMessage], reachedEnd: Bool) {
        let identifier = await AuthIdentifierProvider.current(userId: await currentUserId())
        var query = client
            .from("conversation")
            .select("id, message, is_agent, created_at, media_id, medias(*)")
            .eq("character_id", value: characterId)

        if let uid = identifier.userId {
            query = query.eq("user_id", value: uid)
        } else if let cid = identifier.clientId {
            query = query.eq("client_id", value: cid)
        } else {
            return ([], true)
        }

        if let cursor {
            let iso = ISO8601DateFormatter().string(from: cursor)
            query = query.lt("created_at", value: iso)
        }

        let rows: [ConversationRow] = try await query
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        let reachedEnd = rows.count < limit
        return (rows.reversed().map(Self.map), reachedEnd)
    }

    func persist(text: String, isAgent: Bool, characterId: String, mediaId: String? = nil) async {
        let identifier = await AuthIdentifierProvider.current(userId: await currentUserId())
        let row = InsertRow(
            message: text,
            is_agent: isAgent,
            character_id: characterId,
            user_id: identifier.userId,
            client_id: identifier.clientId,
            media_id: mediaId
        )
        do {
            try await client.from("conversation").insert(row).execute()
        } catch {
            Log.app.error("persist chat row failed: \(error.localizedDescription)")
        }
    }

    func sendToGemini(text: String,
                      characterId: String,
                      characterName: String,
                      history: [ChatUIMessage],
                      isPro: Bool) async throws -> [String] {
        let uid = await currentUserId() ?? ""

        struct HistoryPart: Codable {
            let role: String
            let text: String
        }

        let historyPayload: [HistoryPart] = history.suffix(10).compactMap { msg in
            switch msg.kind {
            case .text(let t):
                return HistoryPart(role: msg.isAgent ? "model" : "user", text: t)
            default:
                return nil
            }
        }

        struct Payload: Codable {
            let message: String
            let character_id: String
            let conversation_history: [HistoryPart]
            let user_id: String
            let is_pro: Bool
        }

        let payload = Payload(
            message: text,
            character_id: characterId,
            conversation_history: historyPayload,
            user_id: uid,
            is_pro: isPro
        )

        struct Response: Decodable {
            let messages: [String]?
            let response: String?
        }

        let response: Response = try await client.functions.invoke(
            "gemini-chat",
            options: FunctionInvokeOptions(body: payload)
        )

        if let msgs = response.messages, !msgs.isEmpty {
            return msgs.filter { !$0.isEmpty }
        }
        if let single = response.response, !single.isEmpty {
            return single.components(separatedBy: "|||").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        return []
    }

    // MARK: - Helpers

    private func currentUserId() async -> String? {
        do {
            return try await client.auth.session.user.id.uuidString.lowercased()
        } catch {
            return nil
        }
    }

    private static func map(_ row: ConversationRow) -> ChatUIMessage {
        let createdAt = row.created_at.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        let kind: ChatUIMessage.Kind
        if let media = row.medias, row.media_id != nil {
            kind = .media(media)
        } else {
            kind = .text(row.message ?? "")
        }
        return ChatUIMessage(
            id: row.id,
            kind: kind,
            isAgent: row.is_agent ?? false,
            createdAt: createdAt
        )
    }
}

// MARK: - Chat message model

struct ChatUIMessage: Identifiable, Hashable {
    enum Kind: Hashable {
        case text(String)
        case media(MediaItem)
        case system(String)
        case upgradeButton
    }

    let id: String
    let kind: Kind
    let isAgent: Bool
    let createdAt: Date

    var previewText: String {
        switch kind {
        case .text(let t), .system(let t): return t
        case .media: return "📷"
        case .upgradeButton: return "💎"
        }
    }
}
