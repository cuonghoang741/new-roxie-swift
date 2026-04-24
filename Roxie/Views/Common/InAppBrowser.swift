import SwiftUI
import SafariServices

/// Wrapper around `SFSafariViewController` so we can present Terms/Privacy/EULA
/// inside the app instead of bouncing to Safari, like the RN app's
/// `WebBrowser.openBrowserAsync`.
struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let cfg = SFSafariViewController.Configuration()
        cfg.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: cfg)
        vc.preferredBarTintColor = .black
        vc.preferredControlTintColor = .white
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

/// View modifier helpers for presenting an in-app browser as a sheet.
extension View {
    func inAppBrowser(url: Binding<URL?>) -> some View {
        sheet(item: Binding(
            get: { url.wrappedValue.map(IdentifiableURL.init) },
            set: { url.wrappedValue = $0?.url }
        )) { wrapper in
            SafariSheet(url: wrapper.url)
                .ignoresSafeArea()
        }
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
