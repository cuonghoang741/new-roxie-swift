import Foundation
import SwiftUI

/// Cached snapshot of `public.app_settings`. Fetched on app launch and
/// observed by views via `@Environment(RemoteSettings.self)` to gate UI
/// elements (e.g. `remote.bool("show_btn_send_media")`).
@Observable
@MainActor
final class RemoteSettings {
    static let shared = RemoteSettings()

    private(set) var values: [String: String] = [:]
    private(set) var isLoaded: Bool = false

    private let repo = AppSettingsRepository()

    private init() {
        // Warm cache from defaults so the first frame can read flags
        // without waiting for the network.
        if let cached = UserDefaults.standard.dictionary(forKey: Self.cacheKey) as? [String: String] {
            values = cached
            isLoaded = true
        }
    }

    func refresh() async {
        do {
            let rows = try await repo.fetchAll()
            var map: [String: String] = [:]
            for row in rows { map[row.key] = row.value }
            values = map
            isLoaded = true
            UserDefaults.standard.set(map, forKey: Self.cacheKey)
        } catch {
            Log.app.warning("RemoteSettings refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func bool(_ key: String, default fallback: Bool = true) -> Bool {
        guard let raw = values[key]?.lowercased() else { return fallback }
        return raw == "true" || raw == "1" || raw == "yes" || raw == "on"
    }

    func string(_ key: String) -> String? { values[key] }

    func int(_ key: String) -> Int? {
        guard let raw = values[key] else { return nil }
        return Int(raw)
    }

    private static let cacheKey = "remote_settings.cache"
}
