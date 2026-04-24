import Foundation

/// Mirrors `useAppVoiceCall.ts` from native. Drives a state machine for
/// voice + video calls; the actual ElevenLabs/LiveKit SDKs are stubbed but
/// the public surface (state flags, toggle methods, quota countdown) matches
/// what the UI expects so we can wire the native UX 1:1.
@Observable
@MainActor
final class VoiceCallService {
    static let shared = VoiceCallService()

    enum Status: String {
        case idle, booting, connecting, live, ending
    }

    private(set) var status: Status = .idle
    private(set) var isVoiceMode: Bool = false
    private(set) var isCameraMode: Bool = false
    private(set) var isUserSpeaking: Bool = false
    private(set) var lastCallDurationSeconds: Int = 0

    /// Free users get 30s, Pro users get 30 minutes (1800s) — same as native.
    private(set) var remainingQuotaSeconds: Int = 30
    private(set) var currentCharacterId: String?
    private(set) var currentCharacterName: String?
    private(set) var currentCharacterAvatar: String?

    var isBooting: Bool { status == .booting }
    var isConnecting: Bool { status == .connecting }
    var isConnected: Bool { status == .live }

    private var meterTask: Task<Void, Never>?
    private var startedAt: Date?

    private init() {}

    // MARK: - Public flow

    func startVoiceCall(character: CharacterItem?) async {
        guard status == .idle else { return }
        currentCharacterId = character?.id
        currentCharacterName = character?.name
        currentCharacterAvatar = character?.avatar ?? character?.thumbnailUrl
        isVoiceMode = true
        isCameraMode = false
        status = .booting

        // Simulate the real boot/connect handshake from ElevenLabs SDK.
        try? await Task.sleep(nanoseconds: 600_000_000)
        status = .connecting
        try? await Task.sleep(nanoseconds: 800_000_000)
        beginLive()
    }

    func startVideoCall(character: CharacterItem?) async {
        guard status == .idle else { return }
        currentCharacterId = character?.id
        currentCharacterName = character?.name
        currentCharacterAvatar = character?.avatar ?? character?.thumbnailUrl
        isVoiceMode = true
        isCameraMode = true
        status = .booting

        try? await Task.sleep(nanoseconds: 600_000_000)
        status = .connecting
        try? await Task.sleep(nanoseconds: 800_000_000)
        beginLive()
    }

    func toggleCameraMode() {
        guard isConnected else { return }
        isCameraMode.toggle()
    }

    func endCall() async {
        guard status != .idle else { return }
        status = .ending
        meterTask?.cancel()
        if let startedAt {
            lastCallDurationSeconds = max(0, Int(Date().timeIntervalSince(startedAt)))
        }
        try? await Task.sleep(nanoseconds: 250_000_000)
        isVoiceMode = false
        isCameraMode = false
        startedAt = nil
        status = .idle
    }

    // MARK: - Internals

    private func beginLive() {
        status = .live
        startedAt = Date()
        meterTask?.cancel()
        meterTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { return }
                if self.remainingQuotaSeconds > 0 {
                    self.remainingQuotaSeconds -= 1
                }
                if self.remainingQuotaSeconds <= 0 && !RevenueCatManager.shared.isProUser {
                    await self.endCall()
                    return
                }
            }
        }
    }
}
