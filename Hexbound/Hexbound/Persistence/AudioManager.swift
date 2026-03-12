import AVFoundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var bgmPlayer: AVAudioPlayer?
    private let settings = SettingsManager.shared
    private var currentBGM: String?

    var isPlaying: Bool { bgmPlayer?.isPlaying ?? false }

    private init() {
        setupAudioSession()
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        } catch {
            #if DEBUG
            print("[AudioManager] Failed to set audio session: \(error)")
            #endif
        }
    }

    // MARK: - BGM

    func playBGM(_ filename: String) {
        // Don't reload if same track already loaded
        if currentBGM == filename, bgmPlayer != nil {
            syncVolume()
            return
        }

        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension.isEmpty ? "mp3" : (filename as NSString).pathExtension

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            #if DEBUG
            print("[AudioManager] BGM file not found: \(filename)")
            #endif
            return
        }

        do {
            // Activate audio session only when actually playing
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = effectiveVolume
            player.prepareToPlay()
            bgmPlayer = player
            currentBGM = filename

            if effectiveVolume > 0 {
                player.play()
            }
        } catch {
            #if DEBUG
            print("[AudioManager] Failed to load BGM: \(error)")
            #endif
        }
    }

    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
        currentBGM = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Call this whenever bgmVolume or isMuted changes in settings.
    func syncVolume() {
        guard let player = bgmPlayer else { return }
        let vol = effectiveVolume
        player.volume = vol
        if vol > 0 {
            if !player.isPlaying { player.play() }
        } else {
            player.pause()
        }
    }

    /// Returns 0 if muted, otherwise bgmVolume
    private var effectiveVolume: Float {
        settings.isMuted ? 0 : settings.bgmVolume
    }
}
