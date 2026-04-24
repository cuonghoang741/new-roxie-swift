import Foundation
import Supabase

/// Base class exposing a shared client + helpers mirroring the RN BaseRepository.
class BaseRepository {
    let client: SupabaseClient

    init() {
        self.client = SupabaseService.shared.client
    }

    /// Lowercase user id from the current auth session (or nil for guests).
    func currentUserId() async -> String? {
        do {
            let session = try await client.auth.session
            return session.user.id.uuidString.lowercased()
        } catch {
            return nil
        }
    }

    /// Build the current auth identifier (either user_id or guest client_id).
    func currentIdentifier() async -> AuthIdentifier {
        let userId = await currentUserId()
        return await AuthIdentifierProvider.current(userId: userId)
    }
}

enum RepositoryError: Error {
    case notAuthenticated
    case decodeFailed(String)
}
