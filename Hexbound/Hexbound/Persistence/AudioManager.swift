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
    private var voiceFadeTask: Task<Void, Never>?

    // MARK: - BGM ducking

    /// Why the music is currently pulled down. Ducking used to be one
    /// boolean owned by the voice player, which meant the first thing to
    /// finish restored the music while anything else still wanted it quiet.
    /// Held as a set instead: the music stays down until the last reason
    /// lets go, at the deepest fraction any of them asks for.
    enum BGMDuckReason: Hashable {
        /// Narration or NPC dialogue over the track.
        case voice
        /// A cinematic beat — a boss reveal, a promotion. Near silence is
        /// the point: the moment lands because the music stepped out of it.
        case ceremony

        var fraction: Float {
            switch self {
            case .voice: 0.30
            case .ceremony: 0.06
            }
        }
    }

    private var duckReasons: Set<BGMDuckReason> = []
    private var isBGMDucked: Bool { !duckReasons.isEmpty }
    private var duckFraction: Float {
        duckReasons.map(\.fraction).min() ?? 1.0
    }

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
        // No track left to duck, so no reason outlives it.
        duckReasons.removeAll()
        stopVoice(fadeOut: false)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Call this whenever bgmVolume or isMuted changes in settings.
    func syncVolume() {
        guard let player = bgmPlayer else { return }
        let baseVol = effectiveVolume
        let vol = isBGMDucked ? baseVol * duckFraction : baseVol
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

        // "NPC/npc_merchant_ab12cd34.m4a" → subdirectory "NPC" (folder reference)
        let path = filename as NSString
        let dir = path.deletingLastPathComponent
        let name = (path.lastPathComponent as NSString).deletingPathExtension
        let ext = path.pathExtension.isEmpty ? "mp3" : path.pathExtension

        guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: dir.isEmpty ? nil : dir) else {
            #if DEBUG
            print("[AudioManager] Voice file not found: \(filename)")
            #endif
            onFinish?()
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            // Speech has its own level; BGM is ducked underneath it
            player.volume = settings.voiceVolume
            player.numberOfLoops = 0
            player.prepareToPlay()
            voicePlayer = player
            currentVoice = filename
            duckBGM(for: .voice)
            player.play()

            // Always un-duck BGM when the line ends naturally — previously this
            // only happened when a completion handler was passed, so a voice
            // played without one left the music quiet until the next stop.
            let duration = player.duration
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration))
                // Only if this exact player is still the active track
                if self.voicePlayer === player {
                    self.restoreBGM(for: .voice)
                    self.currentVoice = nil
                    self.voicePlayer = nil
                    onFinish?()
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
            restoreBGM(for: .voice)
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
                self.restoreBGM(for: .voice)
            }
        } else {
            player.stop()
            voicePlayer = nil
            currentVoice = nil
            restoreBGM(for: .voice)
        }
    }

    /// Pull the music down for `reason`, and keep it down until that same
    /// reason is released. Calling twice for one reason is a no-op.
    func duckBGM(for reason: BGMDuckReason) {
        guard duckReasons.insert(reason).inserted else { return }
        applyDuck(fadeDuration: reason == .ceremony ? 0.5 : 0.25)
    }

    /// Release one reason. The music comes back only once none are left.
    func restoreBGM(for reason: BGMDuckReason) {
        guard duckReasons.remove(reason) != nil else { return }
        applyDuck(fadeDuration: reason == .ceremony ? 0.8 : 0.25)
    }

    private func applyDuck(fadeDuration: TimeInterval) {
        guard let player = bgmPlayer else { return }
        let target = isBGMDucked ? effectiveVolume * duckFraction : effectiveVolume
        player.setVolume(target, fadeDuration: fadeDuration)
    }
}
