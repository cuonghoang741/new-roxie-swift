import Foundation
import ObjectiveC

/// Swizzles `Bundle.main` so `NSLocalizedString` reads from a chosen
/// `.lproj` instead of the system language. Lets us swap locales at runtime
/// without forcing the user to relaunch.
private var bundleAssocKey: UInt8 = 0

private final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &bundleAssocKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

enum LanguageBundle {
    private static let installSwizzle: Void = {
        object_setClass(Bundle.main, LocalizedBundle.self)
    }()

    /// Apply a locale override. Pass `nil` to use system language.
    static func apply(_ language: String?) {
        _ = installSwizzle
        guard let language,
              let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            objc_setAssociatedObject(Bundle.main, &bundleAssocKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        objc_setAssociatedObject(Bundle.main, &bundleAssocKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
