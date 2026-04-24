import Foundation

/// Matches the RN repositories exactly — including table names and filters
/// so the Swift client pulls the same rows the native app does.
final class CharacterRepository: BaseRepository {
    /// `characters` table, filtered by `is_public = true` + (`owner_by_id is null`
    /// OR `owner_by_id = currentUser`). ORDER by `order` ascending.
    func fetchAllCharacters() async throws -> [CharacterItem] {
        let userId = await currentUserId()
        var query = client
            .from("characters")
            .select()
            .eq("is_public", value: true)

        if let uid = userId {
            query = query.or("owner_by_id.is.null,owner_by_id.eq.\(uid)")
        } else {
            query = query.is("owner_by_id", value: nil)
        }

        return try await query.order("order", ascending: true).execute().value
    }

    func fetchCharacter(id: String) async throws -> CharacterItem? {
        let rows: [CharacterItem] = try await client
            .from("characters")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// `user_character.character_id` — same contract as
    /// `CharacterRepository.fetchOwnedCharacterIds` in RN.
    func fetchOwnedCharacterIds() async throws -> [String] {
        let id = await currentIdentifier()
        struct Row: Decodable { let character_id: String? }

        var query = client
            .from("user_character")
            .select("character_id")
            .not("character_id", operator: .is, value: "null")

        if let uid = id.userId {
            query = query.eq("user_id", value: uid).is("client_id", value: nil as Bool?)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid).is("user_id", value: nil as Bool?)
        } else {
            return []
        }
        let rows: [Row] = try await query.execute().value
        return rows.compactMap { $0.character_id }
    }

    func fetchOwnedItemIds(itemType: String) async throws -> [String] {
        switch itemType {
        case "character":
            return try await fetchOwnedCharacterIds()
        case "background":
            return try await fetchOwnedBackgroundIds()
        case "costume":
            return try await fetchOwnedCostumeIds()
        default:
            return []
        }
    }

    private func fetchOwnedBackgroundIds() async throws -> [String] {
        let id = await currentIdentifier()
        struct Row: Decodable { let background_id: String? }
        var query = client
            .from("user_background")
            .select("background_id")
            .not("background_id", operator: .is, value: "null")
        if let uid = id.userId {
            query = query.eq("user_id", value: uid).is("client_id", value: nil as Bool?)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid).is("user_id", value: nil as Bool?)
        } else {
            return []
        }
        let rows: [Row] = try await query.execute().value
        return rows.compactMap { $0.background_id }
    }

    private func fetchOwnedCostumeIds() async throws -> [String] {
        let id = await currentIdentifier()
        struct Row: Decodable { let costume_id: String? }
        var query = client
            .from("user_costume")
            .select("costume_id")
            .not("costume_id", operator: .is, value: "null")
        if let uid = id.userId {
            query = query.eq("user_id", value: uid).is("client_id", value: nil as Bool?)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid).is("user_id", value: nil as Bool?)
        } else {
            return []
        }
        let rows: [Row] = try await query.execute().value
        return rows.compactMap { $0.costume_id }
    }
}

final class BackgroundRepository: BaseRepository {
    /// `backgrounds` table, `public = true` + `available = true`.
    func fetchAllBackgrounds() async throws -> [BackgroundItem] {
        try await client
            .from("backgrounds")
            .select()
            .eq("public", value: true)
            .eq("available", value: true)
            .order("created_at", ascending: true)
            .execute()
            .value
    }
}

final class CostumeRepository: BaseRepository {
    func fetchAllCostumes() async throws -> [CostumeItem] {
        try await client
            .from("character_costumes")
            .select()
            .eq("available", value: true)
            .execute()
            .value
    }

    func fetchCostumes(for characterId: String) async throws -> [CostumeItem] {
        try await client
            .from("character_costumes")
            .select()
            .eq("character_id", value: characterId)
            .eq("available", value: true)
            .execute()
            .value
    }
}

final class DanceRepository: BaseRepository {
    func fetchAllDances() async throws -> [DanceItem] {
        try await client
            .from("dances")
            .select()
            .eq("available", value: true)
            .order("display_order", ascending: true)
            .execute()
            .value
    }
}

final class MediaRepository: BaseRepository {
    func fetchAllMedia() async throws -> [MediaItem] {
        try await client
            .from("medias")
            .select()
            .eq("available", value: true)
            .execute()
            .value
    }

    func fetchMedia(for characterId: String) async throws -> [MediaItem] {
        try await client
            .from("medias")
            .select()
            .eq("character_id", value: characterId)
            .eq("available", value: true)
            .execute()
            .value
    }
}

final class AssetRepository: BaseRepository {
    func fetchOwnedAssets() async throws -> [UserAsset] {
        let id = await currentIdentifier()
        var query = client.from("user_assets").select()
        if let uid = id.userId {
            query = query.eq("user_id", value: uid).is("client_id", value: nil as Bool?)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid).is("user_id", value: nil as Bool?)
        } else {
            return []
        }
        return try await query.execute().value
    }

    /// Used by AuthManager to decide "new user" (no owned characters yet).
    /// We count distinct rows in `user_character` for parity with the RN
    /// AssetRepository which actually queries that table.
    func countOwned(itemType: String, userId: String) async throws -> Int {
        let table: String
        switch itemType {
        case "character": table = "user_character"
        case "background": table = "user_background"
        case "costume": table = "user_costume"
        default: table = "user_assets"
        }
        let response = try await client
            .from(table)
            .select("*", head: true, count: .exact)
            .eq("user_id", value: userId.lowercased())
            .execute()
        return response.count ?? 0
    }
}
