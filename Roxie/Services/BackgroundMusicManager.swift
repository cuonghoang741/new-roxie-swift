import Foundation
import AVFoundation

@Observable
@MainActor
final class BackgroundMusicManager {
    static let shared = BackgroundMusicManager()

    private(set) var isPlaying: Bool = false
    private(set) var isEnabled: Bool = false
    private var player: AVAudioPlayer?

    private init() {}

    func toggle() {
        isEnabled.toggle()
        if isEnabled { play() } else { stop() }
    }

    func play() {
        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") else {
            Log.app.info("[bgm] no bundled bgm.mp3, running silent")
            isPlaying = false
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.4
            player?.play()
            isPlaying = true
        } catch {
            Log.app.error("[bgm] failed: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}
