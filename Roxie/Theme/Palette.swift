import SwiftUI

extension Color {
    init(hex: String) {
        let trimmed = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Palette {
    enum Brand {
        static let s25 = Color(hex: "#fff5f8")
        static let s50 = Color(hex: "#ffe8f0")
        static let s100 = Color(hex: "#ffd6e5")
        static let s200 = Color(hex: "#ffb3cc")
        static let s300 = Color(hex: "#ff8fb3")
        static let s400 = Color(hex: "#ff6b99")
        static let s500 = Color(hex: "#ff579a")
        static let s600 = Color(hex: "#e64d8a")
        static let s700 = Color(hex: "#cc447a")
        static let s800 = Color(hex: "#b33a6a")
        static let s900 = Color(hex: "#993059")
        static let s950 = Color(hex: "#661f3b")
    }

    enum GrayDark {
        static let s100 = Color(hex: "#F0F1F1")
        static let s300 = Color(hex: "#CECFD2")
        static let s500 = Color(hex: "#85888E")
        static let s700 = Color(hex: "#333741")
        static let s800 = Color(hex: "#1F242F")
        static let s900 = Color(hex: "#161B26")
        static let s950 = Color(hex: "#0C111D")
    }

    enum GrayNeutral {
        static let s25 = Color(hex: "#fcfcfd")
        static let s100 = Color(hex: "#f3f4f6")
        static let s500 = Color(hex: "#6c737f")
        static let s800 = Color(hex: "#1f2a37")
        static let s900 = Color(hex: "#111927")
    }

    enum Semantic {
        static let error = Color(hex: "#D92D20")
        static let success = Color(hex: "#079455")
        static let warning = Color(hex: "#F79009")
    }

    static let sheetLight = Color.white.opacity(0.85)
    static let sheetDark = Color(hex: "#272727").opacity(0.7)
}
