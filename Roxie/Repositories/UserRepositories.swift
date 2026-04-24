import Foundation

/// Repositories that read/write user-scoped rows (filtered by user_id or client_id).
final class CurrencyRepository: BaseRepository {
    func fetchBalance() async throws -> UserCurrency? {
        let id = await currentIdentifier()
        var query = client.from("user_currency").select()
        if let uid = id.userId {
            query = query.eq("user_id", value: uid).is("client_id", value: nil)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid).is("user_id", value: nil)
        } else {
            return nil
        }
        let rows: [UserCurrency] = try await query.limit(1).execute().value
        return rows.first
    }
}

final class UserStatsRepository: BaseRepository {
    func fetchStats() async throws -> UserStats? {
        let id = await currentIdentifier()
        var query = client.from("user_stats").select()
        if let uid = id.userId {
            query = query.eq("user_id", value: uid).is("client_id", value: nil)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid).is("user_id", value: nil)
        } else {
            return nil
        }
        let rows: [UserStats] = try await query.limit(1).execute().value
        return rows.first
    }
}

final class QuestRepository: BaseRepository {
    func fetchActiveQuests() async throws -> [Quest] {
        try await client
            .from("quests")
            .select()
            .eq("is_active", value: true)
            .execute()
            .value
    }

    func fetchUserDailyQuests() async throws -> [UserDailyQuest] {
        let id = await currentIdentifier()
        var query = client.from("user_daily_quests").select()
        if let uid = id.userId {
            query = query.eq("user_id", value: uid).is("client_id", value: nil)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid).is("user_id", value: nil)
        } else {
            return []
        }
        return try await query.execute().value
    }
}

final class RelationshipRepository: BaseRepository {
    func fetchRelationship(characterId: String) async throws -> CharacterRelationship? {
        let id = await currentIdentifier()
        var query = client
            .from("character_relationship")
            .select()
            .eq("character_id", value: characterId)
        if let uid = id.userId {
            query = query.eq("user_id", value: uid).is("client_id", value: nil)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid).is("user_id", value: nil)
        } else {
            return nil
        }
        let rows: [CharacterRelationship] = try await query.limit(1).execute().value
        return rows.first
    }
}

final class LoginRewardRepository: BaseRepository {
    func fetchRewards() async throws -> [LoginReward] {
        try await client
            .from("login_rewards")
            .select()
            .order("day_number", ascending: true)
            .execute()
            .value
    }

    func fetchUserReward() async throws -> UserLoginReward? {
        let id = await currentIdentifier()
        var query = client.from("user_login_rewards").select()
        if let uid = id.userId {
            query = query.eq("user_id", value: uid).is("client_id", value: nil)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid).is("user_id", value: nil)
        } else {
            return nil
        }
        let rows: [UserLoginReward] = try await query.limit(1).execute().value
        return rows.first
    }
}

final class SubscriptionRepository: BaseRepository {
    func fetchCurrent() async throws -> SubscriptionItem? {
        guard let uid = await currentUserId() else { return nil }
        let rows: [SubscriptionItem] = try await client
            .from("subscriptions")
            .select()
            .eq("user_id", value: uid)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }
}

final class TransactionRepository: BaseRepository {
    func fetchTransactions() async throws -> [TransactionItem] {
        let id = await currentIdentifier()
        var query = client
            .from("transactions")
            .select()
        if let uid = id.userId {
            query = query.eq("user_id", value: uid)
        } else if let cid = id.clientId {
            query = query.eq("client_id", value: cid)
        } else {
            return []
        }
        return try await query.order("created_at", ascending: false).execute().value
    }
}
