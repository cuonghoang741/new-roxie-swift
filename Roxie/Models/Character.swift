import Foundation

struct CharacterItem: Codable, Identifiable, Hashable {
    let id: String
    var name: String?
    var description: String?
    var thumbnailUrl: String?
    var avatar: String?
    var smallAvatarUrl: String?
    var videoUrl: String?
    var baseModelUrl: String?
    var agentElevenlabsId: String?
    var tier: String?
    var order: String?
    var available: Bool?
    var priceVcoin: Int?
    var priceRuby: Int?
    var defaultCostumeId: String?
    var backgroundDefaultId: String?
    var ownerById: String?

    var displayName: String { name ?? "" }

    enum CodingKeys: String, CodingKey {
        case id, name, description, avatar, tier, order, available
        case thumbnailUrl = "thumbnail_url"
        case smallAvatarUrl = "small_avatar_url"
        case videoUrl = "video_url"
        case baseModelUrl = "base_model_url"
        case agentElevenlabsId = "agent_elevenlabs_id"
        case priceVcoin = "price_vcoin"
        case priceRuby = "price_ruby"
        case defaultCostumeId = "default_costume_id"
        case backgroundDefaultId = "background_default_id"
        case ownerById = "owner_by_id"
    }
}

struct BackgroundItem: Codable, Identifiable, Hashable {
    let id: String
    var name: String?
    var thumbnail: String?
    var image: String?
    var videoUrl: String?
    var isPublic: Bool?
    var tier: String?
    var available: Bool?
    var priceVcoin: Int?
    var priceRuby: Int?
    var isDark: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, thumbnail, image, tier, available
        case videoUrl = "video_url"
        case isPublic = "public"
        case priceVcoin = "price_vcoin"
        case priceRuby = "price_ruby"
        case isDark = "is_dark"
    }
}

struct CostumeItem: Codable, Identifiable, Hashable {
    let id: String
    var characterId: String?
    var costumeName: String?
    var url: String?
    var videoUrl: String?
    var thumbnail: String?
    var modelUrl: String?
    var tier: String?
    var available: Bool?
    var priceVcoin: Int?
    var priceRuby: Int?
    var streakDays: Int?

    enum CodingKeys: String, CodingKey {
        case id, url, thumbnail, tier, available
        case characterId = "character_id"
        case costumeName = "costume_name"
        case videoUrl = "video_url"
        case modelUrl = "model_url"
        case priceVcoin = "price_vcoin"
        case priceRuby = "price_ruby"
        case streakDays = "streak_days"
    }
}

struct DanceItem: Codable, Identifiable, Hashable {
    let id: String
    var name: String?
    var fileName: String?
    var tier: String?
    var emoji: String?
    var iconUrl: String?
    var priceRuby: Int?
    var displayOrder: Int?
    var available: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, tier, emoji, available
        case fileName = "file_name"
        case iconUrl = "icon_url"
        case priceRuby = "price_ruby"
        case displayOrder = "display_order"
    }
}
