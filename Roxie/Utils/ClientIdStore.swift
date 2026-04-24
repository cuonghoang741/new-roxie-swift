import Foundation

enum ClientIdStore {
    private static let defaults = UserDefaults.standard

    @discardableResult
    static func ensureClientId() -> String {
        if let existing = defaults.string(forKey: PersistKeys.clientId), !existing.isEmpty {
            return existing
        }
        let generated = UUID().uuidString.lowercased()
        defaults.set(generated, forKey: PersistKeys.clientId)
        return generated
    }

    static func getClientId() -> String? {
        defaults.string(forKey: PersistKeys.clientId)
    }

    static func clearClientId() {
        defaults.removeObject(forKey: PersistKeys.clientId)
    }
}
