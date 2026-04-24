import UIKit
import Photos

/// Captures a snapshot of any UIView (the VRM webview in our case) and saves
/// it to the user's Photos library. Mirrors `handleCapture` in App.tsx.
enum CaptureService {

    static func capture(view: UIView) async throws -> UIImage {
        await MainActor.run {
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
            return renderer.image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
        }
    }

    static func saveToPhotos(_ image: UIImage) async throws {
        let status = await ensureAddOnlyPermission()
        guard status == .authorized || status == .limited else {
            throw CaptureError.permissionDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    private static func ensureAddOnlyPermission() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if current == .notDetermined {
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }
        return current
    }

    enum CaptureError: Error {
        case permissionDenied
    }
}
