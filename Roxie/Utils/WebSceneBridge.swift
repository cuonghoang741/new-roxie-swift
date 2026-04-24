import Foundation
import UIKit
import WebKit

/// Mirrors `src/utils/WebSceneBridge.ts` — thin wrapper around evaluateJavaScript
/// that invokes the globals exposed by the bundled HTML/Three.js scene.
///
/// Available globals in index.html (confirmed via `grep window\. index.html`):
/// - window.loadModelByURL(url, name)
/// - window.loadModelByName(name)
/// - window.loadAnimationByName(name)
/// - window.triggerDance()
/// - window.triggerLove()
/// - window.applyParallax(dx, dy)
/// - window.setCallMode(enabled)
/// - window.setMouthOpen(value)
/// - window.setBackgroundImage(url)
/// - window.setBackgroundVideo(url)
/// - window.nextBackground()
/// - window.prevBackground()
/// - window.resetCamera()
/// - window.clearVRM()
@MainActor
final class WebSceneBridge {
    weak var webView: WKWebView?

    private var lastParallaxSentAt: Date = .distantPast
    private let parallaxMinInterval: TimeInterval = 1.0 / 45.0
    private var lastMouthLogAt: Date = .distantPast
    private var lastLoadedModelURL: String?

    init(webView: WKWebView? = nil) {
        self.webView = webView
    }

    func setCallMode(_ enabled: Bool) {
        evaluate("window.setCallMode && window.setCallMode(\(enabled ? "true" : "false"));")
    }

    /// Renders the current webview into a UIImage. Used by the Capture button
    /// to save a snapshot of the VRM scene to Photos.
    func snapshot() async -> UIImage? {
        guard let webView else { return nil }
        let bounds = webView.bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            webView.drawHierarchy(in: bounds, afterScreenUpdates: false)
        }
    }

    func applyParallax(dx: Double, dy: Double) {
        let now = Date()
        if now.timeIntervalSince(lastParallaxSentAt) < parallaxMinInterval {
            return
        }
        lastParallaxSentAt = now
        evaluate("window.applyParallax && window.applyParallax(\(dx), \(dy));")
    }

    func triggerDance() {
        evaluate("window.triggerDance && window.triggerDance();")
    }

    func triggerLove() {
        evaluate("window.triggerLove && window.triggerLove();")
    }

    func stopAction() {
        evaluate("window.loadAnimationByName && window.loadAnimationByName('Idle Stand');")
    }

    func loadAnimation(named name: String) {
        let escaped = escape(name)
        evaluate("window.loadAnimationByName && window.loadAnimationByName('\(escaped)');")
    }

    func setMouthOpen(_ value: Double) {
        let clamped = max(0, min(1, value.isFinite ? value : 0))
        let now = Date()
        if clamped > 0.1, now.timeIntervalSince(lastMouthLogAt) > 1 {
            lastMouthLogAt = now
            Log.bridge.debug("setMouthOpen \(clamped)")
        }
        evaluate("window.setMouthOpen && window.setMouthOpen(\(String(format: "%.3f", clamped)));")
    }

    /// Load a VRM model by remote URL. Matches how the RN app calls it (see
    /// App.tsx ~line 517). Wrapped in an async IIFE so Promise rejections
    /// don't take down the outer evaluateJavaScript call.
    func loadModelByURL(_ url: String, name: String) {
        guard !url.isEmpty else { return }
        if lastLoadedModelURL == url {
            Log.bridge.debug("skip loadModelByURL: same url already loaded")
            return
        }
        lastLoadedModelURL = url
        let escapedURL = escape(url)
        let escapedName = escape(name)
        let js = """
        (async function(){ try { if (window.loadModelByURL) { await window.loadModelByURL("\(escapedURL)", "\(escapedName)"); } return true; } catch(e) { console.log('loadModelByURL error', e); return true; } })();
        """
        evaluate(js)
    }

    func setBackgroundImage(_ url: String) {
        guard !url.isEmpty else { return }
        let escaped = escape(url)
        evaluate("window.setBackgroundImage && window.setBackgroundImage('\(escaped)');")
    }

    func setBackgroundVideo(_ url: String) {
        guard !url.isEmpty else { return }
        let escaped = escape(url)
        evaluate("window.setBackgroundVideo && window.setBackgroundVideo('\(escaped)');")
    }

    func clearVRM() {
        evaluate("window.clearVRM && window.clearVRM();")
    }

    func loadModel(script: String) {
        evaluate(script)
    }

    private func evaluate(_ js: String) {
        guard let webView else {
            Log.bridge.warning("evaluate called with no webView: \(js, privacy: .public)")
            return
        }
        webView.evaluateJavaScript(js) { _, error in
            if let error {
                Log.bridge.error("JS eval error: \(error.localizedDescription)")
            }
        }
    }

    private func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "'", with: "\\'")
    }
}
