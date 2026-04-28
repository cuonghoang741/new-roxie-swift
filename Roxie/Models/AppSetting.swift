import Foundation

/// One row in `public.app_settings` — a remote feature toggle keyed by name.
struct AppSetting: Codable, Identifiable, Hashable {
    let key: String
    let value: String
    var description: String?
    var updatedAt: String?

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, value, description
        case updatedAt = "updated_at"
    }
}
