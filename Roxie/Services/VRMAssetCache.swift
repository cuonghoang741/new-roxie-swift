import Foundation
import CryptoKit

/// Persistent on-disk cache for VRM models and FBX animations.
///
/// Files served by `VRMSchemeHandler` and pre-warmed at sign-in time live here.
/// Disk layout: `<Caches>/vrm-assets/<sha256(virtualURL)>` keyed by the virtual
/// `vrmcache://...` URL the WebView requests.
final class VRMAssetCache: @unchecked Sendable {
    static let shared = VRMAssetCache()

    /// Maps the custom-scheme host to the real CDN base URL. The JS in
    /// index.html constructs `vrmcache://<host>/<path>`, and this dictionary
    /// resolves it back to the real download URL.
    static let hostToRealBase: [String: String] = [
        "r2-chars":  "https://pub-6671ed00c8d945b28ff7d8ec392f60b8.r2.dev/CHARACTERS/",
        "n6n-anim":  "https://n6n.top/Anim/",
        "r2-anim":   "https://pub-8b57fd6b30c04b11b3f3a092bdfed0e2.r2.dev/",
    ]

    /// All assets the JS preloads at startup. Mirrors `vrmFiles`,
    /// `legacyFbxFiles`, `proFbxFiles` in index.html — keep in sync if either
    /// list changes.
    private static let vrmFiles: [String] = [
        "001/001_vrm/001_01.vrm",
        "002/002_vrm/002_01.vrm",
        "003/003_vrm/003_01.vrm",
        "004/004_vrm/004_01.vrm",
        "005/005_vrm/005_01.vrm",
        "006/006_vrm/006_01.vrm",
    ]
    private static let legacyFbxFiles: [String] = [
        "Angry.fbx", "Bashful.fbx", "Blow A Kiss.fbx", "Booty Hip Hop Dance.fbx", "Cross Jumps.fbx",
        "Hand Raising.fbx", "Happy.fbx", "Hip Hop Dancing.fbx", "Idle Stand.fbx", "Jumping Jacks.fbx",
        "Quick Steps.fbx", "Rumba Dancing.fbx", "Snake Hip Hop Dance.fbx", "Standing Arguing.fbx",
        "Standing Greeting.fbx", "Step Hip Hop Dance.fbx", "Talking.fbx", "Taunt.fbx", "Thinking.fbx",
        "Threatening.fbx",
    ]
    private static let proFbxFiles: [String] = [
        "Dance - Give Your Soul.fbx",
        "Feminine - Exaggerated 2.fbx",
        "Heart-Flutter Pose.fbx",
        "Making a snow angel.fbx",
        "Sly - Finger gun gesture.fbx",
    ]

    private let session: URLSession
    private let cacheDir: URL
    /// In-flight downloads — coalesce concurrent requests for the same key.
    private var inflight: [String: Task<URL, Error>] = [:]
    private let inflightLock = NSLock()
    private var preloadStarted = false

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDir = caches.appendingPathComponent("vrm-assets", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// Resolve a `vrmcache://<host>/<path>` URL to the real download URL.
    /// Returns nil if the host isn't recognized.
    static func realURL(forVirtual virtual: URL) -> URL? {
        guard virtual.scheme?.lowercased() == "vrmcache",
              let host = virtual.host,
              let base = hostToRealBase[host] else { return nil }
        let path = virtual.path.hasPrefix("/") ? String(virtual.path.dropFirst()) : virtual.path
        guard let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        return URL(string: base + encoded)
    }

    /// Returns true iff the file for `virtualURL` is already on disk.
    func hasCached(virtualURL: URL) -> Bool {
        FileManager.default.fileExists(atPath: location(for: virtualURL).path)
    }

    /// Fetch the bytes for `virtualURL`, downloading + persisting if needed.
    /// Concurrent calls for the same URL are coalesced.
    func data(forVirtual virtualURL: URL) async throws -> Data {
        let fileURL = try await ensureFile(for: virtualURL)
        return try Data(contentsOf: fileURL)
    }

    /// Ensures the file for `virtualURL` exists on disk and returns its path.
    @discardableResult
    func ensureFile(for virtualURL: URL) async throws -> URL {
        let dest = location(for: virtualURL)
        if FileManager.default.fileExists(atPath: dest.path) {
            return dest
        }

        let key = dest.lastPathComponent
        let task = inflightLock.withLock { () -> Task<URL, Error> in
            if let existing = inflight[key] { return existing }
            let new = Task<URL, Error> {
                defer {
                    self.inflightLock.withLock { _ = self.inflight.removeValue(forKey: key) }
                }
                return try await self.downloadAndStore(virtualURL: virtualURL, dest: dest)
            }
            inflight[key] = new
            return new
        }
        return try await task.value
    }

    /// Kick off downloads for every VRM + FBX. Idempotent — subsequent calls
    /// after the first one are no-ops while a preload is in progress; cached
    /// files are skipped at the per-task level.
    func preloadAll() {
        inflightLock.withLock {
            if preloadStarted { return }
            preloadStarted = true
        }

        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let jobs: [URL] = (
                Self.vrmFiles.compactMap     { Self.virtualURL(host: "r2-chars", path: $0) } +
                Self.legacyFbxFiles.compactMap { Self.virtualURL(host: "n6n-anim", path: $0) } +
                Self.proFbxFiles.compactMap    { Self.virtualURL(host: "r2-anim",  path: $0) }
            )
            await withTaskGroup(of: Void.self) { group in
                let limit = 2
                var iterator = jobs.makeIterator()
                // Seed the pool.
                for _ in 0..<limit {
                    guard let next = iterator.next() else { break }
                    group.addTask { _ = try? await self.ensureFile(for: next) }
                }
                // Refill as each finishes.
                while await group.next() != nil {
                    guard let next = iterator.next() else { continue }
                    group.addTask { _ = try? await self.ensureFile(for: next) }
                }
            }
            Log.webview.info("VRMAssetCache preload finished")
        }
    }

    // MARK: - Internals

    private func downloadAndStore(virtualURL: URL, dest: URL) async throws -> URL {
        guard let real = Self.realURL(forVirtual: virtualURL) else {
            throw URLError(.badURL)
        }
        let (tmpURL, response) = try await session.download(from: real)
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.init(rawValue: http.statusCode))
        }

        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tmpURL, to: dest)
        Log.webview.debug("VRMAssetCache cached \(virtualURL.absoluteString, privacy: .public)")
        return dest
    }

    private func location(for virtualURL: URL) -> URL {
        let key = sha256Hex(virtualURL.absoluteString)
        return cacheDir.appendingPathComponent(key)
    }

    private func sha256Hex(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func virtualURL(host: String, path: String) -> URL? {
        guard let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        return URL(string: "vrmcache://\(host)/\(encoded)")
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock(); defer { unlock() }
        return body()
    }
}
