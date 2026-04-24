import Foundation
import OSLog

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.eduto.roxieswift"
    static let app = Logger(subsystem: subsystem, category: "app")
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let supabase = Logger(subsystem: subsystem, category: "supabase")
    static let webview = Logger(subsystem: subsystem, category: "webview")
    static let bridge = Logger(subsystem: subsystem, category: "bridge")
}
