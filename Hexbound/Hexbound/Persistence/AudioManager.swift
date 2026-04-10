import AVFoundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var bgmPlayer: AVAudioPlayer?
    private let settings = SettingsManager.shared
    private var currentBGM: String?

    // MARK: - Voice (narration / dialogue over BGM)

    private var voicePlayer: AVAudioPlayer?
    private var currentVoice: String?
    /// When voice is active, BGM is ducked to this fraction of its effective volume.
    private let bgmDuckFraction: Float = 0.3
    private var isBGMDucked: Bool = false
    private var voiceFadeTask: Task<Void, Never>?

    var isPlaying: Bool { bgmPlayer?.isPlaying ?? false }
    var isVoicePlaying: Bool { voicePlayer?.isPlaying ?? false }

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
        isBGMDucked = false
        stopVoice(fadeOut: false)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Call this whenever bgmVolume or isMuted changes in settings.
    func syncVolume() {
        guard let player = bgmPlayer else { return }
        let baseVol = effectiveVolume
        let vol = isBGMDucked ? baseVol * bgmDuckFraction : baseVol
        player.volume = vol
        if baseVol > 0 {
            if !player.isPlaying { player.play() }
        } else {
            player.pause()
        }
        // Keep voice volume in sync with settings
        if let vp = voicePlayer {
            vp.volume = settings.isMuted ? 0 : settings.bgmVolume
        }
    }

    /// Returns 0 if muted, otherwise bgmVolume
    private var effectiveVolume: Float {
        settings.isMuted ? 0 : settings.bgmVolume
    }

    // MARK: - Voice

    /// Play a narration/voice track on top of BGM. Automatically ducks BGM while playing.
    /// - Parameters:
    ///   - filename: Bundle resource filename (with or without extension; defaults to mp3)
    ///   - onFinish: Called on main actor when playback completes naturally (not on stop).
    func playVoice(_ filename: String, onFinish: (@MainActor @Sendable () -> Void)? = nil) {
        // Don't restart same voice track if already playing
        if currentVoice == filename, let player = voicePlayer, player.isPlaying {
            return
        }

        stopVoice(fadeOut: false)

        guard !settings.isMuted else {
            // Still fire completion so flow continues
            onFinish?()
            return
        }

        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension.isEmpty ? "mp3" : (filename as NSString).pathExtension

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            #if DEBUG
            print("[AudioManager] Voice file not found: \(filename)")
            #endif
            onFinish?()
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            // Voice uses full bgmVolume level — sits above ducked BGM
            player.volume = settings.bgmVolume
            player.numberOfLoops = 0
            player.prepareToPlay()
            voicePlayer = player
            currentVoice = filename
            duckBGM()
            player.play()

            if let onFinish {
                let duration = player.duration
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(duration))
                    // Only call if this is still the active track
                    if self.currentVoice == filename {
                        self.restoreBGM()
                        self.currentVoice = nil
                        self.voicePlayer = nil
                        onFinish()
                    }
                }
            }
        } catch {
            #if DEBUG
            print("[AudioManager] Failed to load voice: \(error)")
            #endif
            onFinish?()
        }
    }

    /// Stop voice playback. If `fadeOut` is true, fades over 200ms.
    func stopVoice(fadeOut: Bool = false) {
        voiceFadeTask?.cancel()
        guard let player = voicePlayer else {
            restoreBGM()
            currentVoice = nil
            return
        }

        if fadeOut && player.isPlaying {
            let startVol = player.volume
            voiceFadeTask = Task { @MainActor in
                let steps = 8
                let stepDuration: UInt64 = 25_000_000 // 25ms
                for i in 1...steps {
                    guard !Task.isCancelled else { return }
                    let frac = Float(steps - i) / Float(steps)
                    player.volume = startVol * frac
                    try? await Task.sleep(nanoseconds: stepDuration)
                }
                player.stop()
                self.voicePlayer = nil
                self.currentVoice = nil
                self.restoreBGM()
            }
        } else {
            player.stop()
            voicePlayer = nil
            currentVoice = nil
            restoreBGM()
        }
    }

    /// Lower BGM volume while voice is active.
    private func duckBGM() {
        guard !isBGMDucked, let player = bgmPlayer else { return }
        isBGMDucked = true
        player.setVolume(effectiveVolume * bgmDuckFraction, fadeDuration: 0.25)
    }

    /// Restore BGM volume after voice ends.
    private func restoreBGM() {
        guard isBGMDucked, let player = bgmPlayer else {
            isBGMDucked = false
            return
        }
        isBGMDucked = false
        player.setVolume(effectiveVolume, fadeDuration: 0.25)
    }
}
