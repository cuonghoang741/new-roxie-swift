import SwiftUI

/// Mirrors native `isDarkBackground` — the background's `is_dark` field tells
/// each overlay whether to use white-on-dark or black-on-light glyphs/tints.
/// Defaults to `true` (dark) so the app reads correctly before a background
/// finishes loading.
private struct IsDarkBackgroundKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var isDarkBackground: Bool {
        get { self[IsDarkBackgroundKey.self] }
        set { self[IsDarkBackgroundKey.self] = newValue }
    }
}

/// Centralised color choices that flip with `isDarkBackground`. Use these
/// instead of hard-coding `.white` / `.black` so every overlay stays in sync.
enum ScenePalette {
    static func foreground(isDark: Bool) -> Color {
        isDark ? .white : .black
    }

    static func glassTint(isDark: Bool) -> Color {
        isDark ? Color.black.opacity(0.35) : Color.white.opacity(0.55)
    }

    static func glassStroke(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.12)
    }

    static func placeholder(isDark: Bool) -> Color {
        (isDark ? Color.white : Color.black).opacity(0.6)
    }
}
