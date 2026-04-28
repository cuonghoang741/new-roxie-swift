import Foundation

/// Pulls remote feature toggles from `public.app_settings`.
final class AppSettingsRepository: BaseRepository {
    func fetchAll() async throws -> [AppSetting] {
        try await client
            .from("app_settings")
            .select()
            .execute()
            .value
    }
}
