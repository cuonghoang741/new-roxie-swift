import Foundation

struct CharacterBackgroundSelection: Codable {
    var backgroundId: String?
    var backgroundURL: String?
    var backgroundName: String?
}

struct CharacterCostumeSelection: Codable {
    var costumeId: String?
    var modelName: String?
    var modelURL: String?
}

enum Persistence {
    private static let defaults = UserDefaults.standard

    static var modelName: String {
        get { defaults.string(forKey: PersistKeys.modelName) ?? "" }
        set { defaults.set(newValue, forKey: PersistKeys.modelName) }
    }

    static var modelURL: String {
        get { defaults.string(forKey: PersistKeys.modelURL) ?? "" }
        set { defaults.set(newValue, forKey: PersistKeys.modelURL) }
    }

    static var backgroundURL: String {
        get { defaults.string(forKey: PersistKeys.backgroundURL) ?? "" }
        set { defaults.set(newValue, forKey: PersistKeys.backgroundURL) }
    }

    static var backgroundName: String {
        get { defaults.string(forKey: PersistKeys.backgroundName) ?? "" }
        set { defaults.set(newValue, forKey: PersistKeys.backgroundName) }
    }

    static var characterId: String? {
        get { defaults.string(forKey: PersistKeys.characterId) }
        set { defaults.set(newValue, forKey: PersistKeys.characterId) }
    }

    private static func readMap<T: Codable>(_ key: String) -> [String: T] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        return (try? JSONDecoder().decode([String: T].self, from: data)) ?? [:]
    }

    private static func writeMap<T: Codable>(_ key: String, _ map: [String: T]) {
        if map.isEmpty {
            defaults.removeObject(forKey: key)
            return
        }
        if let data = try? JSONEncoder().encode(map) {
            defaults.set(data, forKey: key)
        }
    }

    static func getBackgroundSelection(for characterId: String) -> CharacterBackgroundSelection? {
        let map: [String: CharacterBackgroundSelection] = readMap(PersistKeys.backgroundSelections)
        return map[characterId]
    }

    static func setBackgroundSelection(for characterId: String, _ selection: CharacterBackgroundSelection?) {
        guard !characterId.isEmpty else { return }
        var map: [String: CharacterBackgroundSelection] = readMap(PersistKeys.backgroundSelections)
        if let selection, selection.backgroundId != nil || selection.backgroundURL != nil {
            map[characterId] = selection
        } else {
            map.removeValue(forKey: characterId)
        }
        writeMap(PersistKeys.backgroundSelections, map)
    }

    static func getCostumeSelection(for characterId: String) -> CharacterCostumeSelection? {
        let map: [String: CharacterCostumeSelection] = readMap(PersistKeys.costumeSelections)
        return map[characterId]
    }

    static func setCostumeSelection(for characterId: String, _ selection: CharacterCostumeSelection?) {
        guard !characterId.isEmpty else { return }
        var map: [String: CharacterCostumeSelection] = readMap(PersistKeys.costumeSelections)
        if let selection, selection.costumeId != nil || selection.modelName != nil || selection.modelURL != nil {
            map[characterId] = selection
        } else {
            map.removeValue(forKey: characterId)
        }
        writeMap(PersistKeys.costumeSelections, map)
    }

    /// Generate the initial JS to inject into the VRM WebView so the scene boots
    /// with the user's persisted selections.
    static func generateInjectionScript() -> String {
        let charId = characterId ?? ""
        let backgroundSelection = charId.isEmpty ? nil : getBackgroundSelection(for: charId)
        let costumeSelection = charId.isEmpty ? nil : getCostumeSelection(for: charId)

        let effectiveModelName = costumeSelection?.modelName ?? modelName
        let effectiveModelURL = costumeSelection?.modelURL ?? modelURL
        let effectiveBackgroundURL = backgroundSelection?.backgroundURL ?? backgroundURL

        var lines: [String] = []
        if !effectiveModelName.isEmpty {
            lines.append("window.nativeSelectedModelName=\"\(escape(effectiveModelName))\";")
        }
        if !effectiveModelURL.isEmpty {
            lines.append("window.nativeSelectedModelURL=\"\(escape(effectiveModelURL))\";")
        }
        if !effectiveBackgroundURL.isEmpty {
            lines.append("window.initialBackgroundUrl=\"\(escape(effectiveBackgroundURL))\";")
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

enum FileDiscovery {
    /// Mirrors the RN side which returns empty lists (files are fetched from remote URLs).
    static func generateFileListJSON() -> String {
        let payload: [String: [String]] = [
            "vrmFiles": [],
            "fbxFiles": []
        ]
        let data = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data("{}".utf8)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
