import SwiftUI
import AVFoundation

/// In-call HUD: countdown timer chip at top center + draggable PiP camera
/// preview at top-right (FaceTime-style) + end-call button. Mirrors native
/// `CameraPreviewOverlay` + the call-time chip in `VRMUIOverlay`.
struct CallControlsOverlay: View {
    let remainingSeconds: Int
    let isCameraMode: Bool
    var onEndCall: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Top-center countdown + end-call
            VStack {
                HStack(spacing: 10) {
                    countdownChip
                    Spacer()
                    endCallButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }

            if isCameraMode {
                PiPCameraPreview()
            }
        }
    }

    private var countdownChip: some View {
        HStack(spacing: 8) {
            StatusDot(tint: Cyber.lime)
            Text(L10n.Cyber.live)
                .font(Cyber.mono(10, weight: .heavy))
                .foregroundStyle(Cyber.lime)
                .tracking(1.4)
            Text(formatTime(remainingSeconds))
                .font(Cyber.mono(14, weight: .heavy))
                .foregroundStyle(Cyber.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Cyber.surface.opacity(0.85))
        .overlay(Rectangle().stroke(Cyber.lime.opacity(0.7), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: Cyber.lime.opacity(0.5), radius: 6)
    }

    private var endCallButton: some View {
        Button(action: onEndCall) {
            HStack(spacing: 6) {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 13, weight: .heavy))
                Text(L10n.Cyber.actionEnd)
                    .font(Cyber.mono(11, weight: .heavy))
                    .tracking(1.4)
            }
            .foregroundStyle(Cyber.bg)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Cyber.danger)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .shadow(color: Cyber.danger.opacity(0.6), radius: 8)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - PiP camera preview (front camera, draggable)

private struct PiPCameraPreview: View {
    @State private var offset: CGSize = .init(width: 0, height: 0)
    @State private var dragStart: CGSize = .zero
    @State private var session = AVCaptureSession()
    @State private var hasCamera = false

    private let pipSize = CGSize(width: 110, height: 150)
    private let initialPadding: CGFloat = 16
    private let topInset: CGFloat = 110

    var body: some View {
        GeometryReader { geo in
            CameraPreviewLayer(session: session, hasCamera: $hasCamera)
                .frame(width: pipSize.width, height: pipSize.height)
                .background(Color.black)
                .overlay {
                    if !hasCamera {
                        VStack(spacing: 6) {
                            Image(systemName: "video.slash.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("Camera off")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
                .position(
                    x: max(pipSize.width / 2, min(geo.size.width - pipSize.width / 2, geo.size.width - pipSize.width / 2 - initialPadding + offset.width)),
                    y: max(pipSize.height / 2, min(geo.size.height - pipSize.height / 2, topInset + pipSize.height / 2 + offset.height))
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: dragStart.width + value.translation.width,
                                height: dragStart.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            dragStart = offset
                        }
                )
        }
        .onAppear { startCameraIfPossible() }
        .onDisappear { session.stopRunning() }
    }

    private func startCameraIfPossible() {
        Task.detached(priority: .userInitiated) {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            let granted: Bool
            if status == .notDetermined {
                granted = await AVCaptureDevice.requestAccess(for: .video)
            } else {
                granted = (status == .authorized)
            }
            guard granted else { return }

            await MainActor.run { configureSession() }
        }
    }

    private func configureSession() {
        guard !session.isRunning else { return }
        session.beginConfiguration()
        session.sessionPreset = .medium
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
            hasCamera = true
        }
        session.commitConfiguration()
        Task.detached(priority: .userInitiated) {
            session.startRunning()
        }
    }
}

private struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    @Binding var hasCamera: Bool

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
