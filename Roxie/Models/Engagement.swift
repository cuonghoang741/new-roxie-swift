import Foundation

struct Quest: Codable, Identifiable, Hashable {
    let id: String
    var questType: String?
    var questCategory: String?
    var difficulty: String?
    var description: String?
    var targetValue: Int?
    var rewardVcoin: Int?
    var rewardRuby: Int?
    var rewardXp: Int?
    var rewardCharacterId: String?
    var rewardBackgroundId: String?
    var rewardCostumeId: String?
    var isRepeatable: Bool?
    var isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, description, difficulty
        case questType = "quest_type"
        case questCategory = "quest_category"
        case targetValue = "target_value"
        case rewardVcoin = "reward_vcoin"
        case rewardRuby = "reward_ruby"
        case rewardXp = "reward_xp"
        case rewardCharacterId = "reward_character_id"
        case rewardBackgroundId = "reward_background_id"
        case rewardCostumeId = "reward_costume_id"
        case isRepeatable = "is_repeatable"
        case isActive = "is_active"
    }
}

struct UserDailyQuest: Codable, Identifiable, Hashable {
    let id: String
    var userId: String?
    var clientId: String?
    var questId: String = ""
    var progress: Int = 0
    var completed: Bool = false
    var claimed: Bool = false
    var questDate: String?

    enum CodingKeys: String, CodingKey {
        case id, progress, completed, claimed
        case userId = "user_id"
        case clientId = "client_id"
        case questId = "quest_id"
        case questDate = "quest_date"
    }
}

struct CharacterRelationship: Codable, Identifiable, Hashable {
    let id: String
    var userId: String?
    var clientId: String?
    var characterId: String = ""
    var level: Int = 0
    var points: Int = 0
    var unlockedItems: [String]?

    enum CodingKeys: String, CodingKey {
        case id, level, points
        case userId = "user_id"
        case clientId = "client_id"
        case characterId = "character_id"
        case unlockedItems = "unlocked_items"
    }
}

struct LoginReward: Codable, Identifiable, Hashable {
    let id: String
    var dayNumber: Int = 0
    var rewardVcoin: Int?
    var rewardRuby: Int?
    var rewardEnergy: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case dayNumber = "day_number"
        case rewardVcoin = "reward_vcoin"
        case rewardRuby = "reward_ruby"
        case rewardEnergy = "reward_energy"
    }
}

struct UserLoginReward: Codable, Identifiable, Hashable {
    let id: String
    var userId: String?
    var clientId: String?
    var currentDay: Int = 0
    var lastClaimDate: String?
    var totalDaysClaimed: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case clientId = "client_id"
        case currentDay = "current_day"
        case lastClaimDate = "last_claim_date"
        case totalDaysClaimed = "total_days_claimed"
    }
}

struct MediaItem: Codable, Identifiable, Hashable {
    let id: String
    var url: String?
    var thumbnail: String?
    var characterId: String?
    var tier: String?
    var available: Bool?
    var priceVcoin: Int?
    var priceRuby: Int?
    var mediaType: String?
    var contentType: String?
    var rarity: String?
    var name: String?
    var keywords: [String]?

    enum CodingKeys: String, CodingKey {
        case id, url, thumbnail, tier, available, rarity, name, keywords
        case characterId = "character_id"
        case priceVcoin = "price_vcoin"
        case priceRuby = "price_ruby"
        case mediaType = "media_type"
        case contentType = "content_type"
    }
}

struct ChatMessage: Codable, Identifiable, Hashable {
    let id: String
    var userId: String?
    var characterId: String?
    var message: String = ""
    var isAgent: Bool = false
    var mediaId: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, message
        case userId = "user_id"
        case characterId = "character_id"
        case isAgent = "is_agent"
        case mediaId = "media_id"
        case createdAt = "created_at"
    }
}
