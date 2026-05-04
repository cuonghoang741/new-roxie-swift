import SwiftUI
import WebKit

/// SwiftUI wrapper around WKWebView that renders the VRM/Three.js HTML
/// bundled in the app's Resources.
struct VRMWebView: UIViewRepresentable {
    @Binding var bridge: WebSceneBridge?

    var onModelReady: (() -> Void)?
    var onMessage: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Route every `vrmcache://...` request through our persistent disk
        // cache so previously-downloaded VRM/FBX files survive across launches.
        config.setURLSchemeHandler(context.coordinator.schemeHandler, forURLScheme: VRMSchemeHandler.scheme)

        // Inject the same two WKUserScripts the Swift version expected before
        // the HTML evaluates: the discovered file list + persisted selections.
        // Also bridge JS console.log/warn/error to the native `loading`
        // message channel so we can read them via `log show`.
        let fileList = FileDiscovery.generateFileListJSON()
        let bootstrap = """
        window.__isNativeShell = true;
        window.discoveredFiles = \(fileList);
        (function(){
            const send = (level, args) => {
                try {
                    const text = '[js:' + level + '] ' + Array.from(args).map(a => {
                        if (typeof a === 'string') return a;
                        try { return JSON.stringify(a); } catch (_) { return String(a); }
                    }).join(' ');
                    window.webkit?.messageHandlers?.loading?.postMessage(text);
                } catch (_) {}
            };
            const orig = { log: console.log, warn: console.warn, error: console.error };
            console.log   = function () { send('log',   arguments); orig.log.apply(console, arguments); };
            console.warn  = function () { send('warn',  arguments); orig.warn.apply(console, arguments); };
            console.error = function () { send('error', arguments); orig.error.apply(console, arguments); };
            window.addEventListener('error', e => send('uncaught', [e.message, e.filename + ':' + e.lineno]));
        })();
        """
        let persisted = Persistence.generateInjectionScript()

        config.userContentController.addUserScript(WKUserScript(
            source: bootstrap,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        if !persisted.isEmpty {
            config.userContentController.addUserScript(WKUserScript(
                source: persisted,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
        }

        config.userContentController.add(context.coordinator, name: "loading")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.allowsLinkPreview = false

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        DispatchQueue.main.async {
            bridge = WebSceneBridge(webView: webView)
        }

        loadHTML(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Bridge is updated in makeUIView; nothing dynamic to refresh here.
    }

    private func loadHTML(into webView: WKWebView) {
        guard let url = Bundle.main.url(forResource: "index", withExtension: "html") else {
            Log.webview.error("index.html missing from bundle")
            webView.loadHTMLString(fallbackHTML, baseURL: URL(string: "https://localhost/"))
            return
        }
        do {
            let html = try String(contentsOf: url, encoding: .utf8)
            webView.loadHTMLString(html, baseURL: URL(string: "https://localhost/"))
        } catch {
            Log.webview.error("Failed reading index.html: \(error.localizedDescription)")
            webView.loadHTMLString(fallbackHTML, baseURL: URL(string: "https://localhost/"))
        }
    }

    private var fallbackHTML: String {
        """
        <!DOCTYPE html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'><style>body{margin:0;height:100vh;display:flex;align-items:center;justify-content:center;font-family:-apple-system;background:#FFC0CB;color:#333;text-align:center;padding:24px}</style></head><body><div><h1>VRM scene unavailable</h1><p>index.html was not found in the app bundle.</p></div></body></html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
        let parent: VRMWebView
        let schemeHandler = VRMSchemeHandler()

        init(parent: VRMWebView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "loading" else { return }
            let text: String
            if let s = message.body as? String {
                text = s
            } else {
                text = String(describing: message.body)
            }
            Log.webview.debug("[loading] \(text, privacy: .public)")

            if text == "initialReady" || text == "modelLoaded" {
                parent.onModelReady?()
            }
            parent.onMessage?(text)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Log.webview.info("VRM webview finished loading")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Log.webview.error("VRM webview failed: \(error.localizedDescription)")
        }
    }
}
