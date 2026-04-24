import Foundation

struct UserCurrency: Codable, Hashable {
    var userId: String?
    var clientId: String?
    var vcoin: Int = 0
    var ruby: Int = 0

    enum CodingKeys: String, CodingKey {
        case vcoin, ruby
        case userId = "user_id"
        case clientId = "client_id"
    }
}

struct UserStats: Codable, Hashable {
    var userId: String?
    var clientId: String?
    var level: Int = 1
    var xp: Int = 0
    var energy: Int = 0
    var energyUpdatedAt: String?
    var loginStreak: Int?

    enum CodingKeys: String, CodingKey {
        case level, xp, energy
        case userId = "user_id"
        case clientId = "client_id"
        case energyUpdatedAt = "energy_updated_at"
        case loginStreak = "login_streak"
    }
}

struct TransactionItem: Codable, Identifiable, Hashable {
    let id: String
    var userId: String?
    var clientId: String?
    var itemId: String?
    var itemType: String?
    var currencyType: String?
    var amountPaid: Int?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case clientId = "client_id"
        case itemId = "item_id"
        case itemType = "item_type"
        case currencyType = "currency_type"
        case amountPaid = "amount_paid"
        case createdAt = "created_at"
    }
}

struct UserAsset: Codable, Identifiable, Hashable {
    let id: String
    var userId: String?
    var clientId: String?
    var itemId: String?
    var itemType: String?
    var transactionId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case clientId = "client_id"
        case itemId = "item_id"
        case itemType = "item_type"
        case transactionId = "transaction_id"
    }
}

struct SubscriptionItem: Codable, Identifiable, Hashable {
    let id: String
    var userId: String?
    var status: String?
    var tier: String?
    var plan: String?
    var currentPeriodEnd: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status, tier, plan
        case userId = "user_id"
        case currentPeriodEnd = "current_period_end"
        case createdAt = "created_at"
    }
}
