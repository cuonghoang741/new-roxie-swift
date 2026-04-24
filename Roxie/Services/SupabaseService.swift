import Foundation
import Supabase

/// Singleton wrapper around the Supabase client. Automatically attaches
/// the X-Client-Id header for guest users (mirrors the RN implementation).
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        let clientId = ClientIdStore.ensureClientId()
        let options = SupabaseClientOptions(
            global: .init(headers: [
                "apikey": AppConfig.supabaseAnonKey,
                "X-Client-Id": clientId
            ])
        )
        self.client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey,
            options: options
        )
    }
}

struct AuthIdentifier {
    let userId: String?
    let clientId: String?
}

enum AuthIdentifierProvider {
    static func current(userId: String?) async -> AuthIdentifier {
        if let userId, !userId.isEmpty {
            return AuthIdentifier(userId: userId.lowercased(), clientId: nil)
        }
        let clientId = ClientIdStore.ensureClientId()
        return AuthIdentifier(userId: nil, clientId: clientId)
    }
}
