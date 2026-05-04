import Foundation
import WebKit

/// Custom URL scheme handler that serves VRM/FBX assets to the WebView from
/// `VRMAssetCache`. The WebView is configured to route every `vrmcache://`
/// request through here; on cache miss the handler triggers a download,
/// persists it, then serves the bytes back.
final class VRMSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "vrmcache"

    private var inflight: [ObjectIdentifier: Task<Void, Never>] = [:]
    private let lock = NSLock()

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let request = urlSchemeTask.request
        guard let virtualURL = request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        let key = ObjectIdentifier(urlSchemeTask)
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let fileURL = try await VRMAssetCache.shared.ensureFile(for: virtualURL)
                if Task.isCancelled { return }
                let data = try Data(contentsOf: fileURL)
                if Task.isCancelled { return }

                let response = HTTPURLResponse(
                    url: virtualURL,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: [
                        "Content-Type": Self.mimeType(for: virtualURL),
                        "Content-Length": "\(data.count)",
                        "Access-Control-Allow-Origin": "*",
                        "Cache-Control": "public, max-age=31536000",
                    ]
                )!

                await MainActor.run {
                    self.finish(task: urlSchemeTask, key: key) {
                        urlSchemeTask.didReceive(response)
                        urlSchemeTask.didReceive(data)
                        urlSchemeTask.didFinish()
                    }
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.finish(task: urlSchemeTask, key: key) {
                        urlSchemeTask.didFailWithError(error)
                    }
                }
            }
        }
        lock.lock(); inflight[key] = task; lock.unlock()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let key = ObjectIdentifier(urlSchemeTask)
        lock.lock()
        let task = inflight.removeValue(forKey: key)
        lock.unlock()
        task?.cancel()
    }

    /// Guarded callback into the WKURLSchemeTask that drops responses if the
    /// task was already stopped — calling didReceive/didFinish on a stopped
    /// task throws a runtime exception in WebKit.
    private func finish(task: WKURLSchemeTask, key: ObjectIdentifier, body: () -> Void) {
        lock.lock()
        let isLive = inflight.removeValue(forKey: key) != nil
        lock.unlock()
        guard isLive else { return }
        body()
    }

    private static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "vrm", "glb", "gltf": return "model/gltf-binary"
        case "fbx":                return "application/octet-stream"
        default:                   return "application/octet-stream"
        }
    }
}
