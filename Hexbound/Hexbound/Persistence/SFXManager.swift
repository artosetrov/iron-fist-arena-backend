import AVFoundation

/// Manages sound effect playback for the app.
/// Uses a pool of AVAudioPlayer instances for overlapping/polyphonic SFX.
@MainActor
final class SFXManager {
    static let shared = SFXManager()

    private let settings = SettingsManager.shared

    /// Pool of active players — auto-cleaned after playback
    private var activePlayers: [AVAudioPlayer] = []

    /// Pre-loaded audio data cache (filename → Data)
    private var cache: [String: Data] = [:]

    private init() {}

    // MARK: - Public API

    /// Play a sound effect by SFX enum case (with paired haptic feedback).
    /// If the SFX has variations, picks one at random for variety.
    func play(_ sfx: SFX) {
        let count = sfx.variationCount
        if count > 1 {
            let pick = Int.random(in: 1...count)
            if pick == 1 {
                play(filename: sfx.filename)
            } else {
                // e.g. "hit_physical_2.wav"
                play(filename: sfx.rawValue + "_\(pick).wav")
            }
        } else {
            play(filename: sfx.filename)
        }
        // Fire paired haptic if haptics enabled
        if settings.hapticsEnabled {
            sfx.haptic?()
        }
    }

    /// Play a sound effect by filename (looks in bundle).
    func play(filename: String) {
        guard !settings.isMuted else { return }
        let vol = settings.sfxVolume
        guard vol > 0 else { return }

        // Get cached data or load from bundle
        let data: Data
        if let cached = cache[filename] {
            data = cached
        } else {
            let name = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension.isEmpty ? "wav" : (filename as NSString).pathExtension

            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
                #if DEBUG
                print("[SFXManager] File not found: \(filename)")
                #endif
                return
            }
            guard let loaded = try? Data(contentsOf: url) else {
                #if DEBUG
                print("[SFXManager] Failed to load: \(filename)")
                #endif
                return
            }
            cache[filename] = loaded
            data = loaded
        }

        // Create a new player for this instance (allows overlapping)
        guard let player = try? AVAudioPlayer(data: data) else {
            #if DEBUG
            print("[SFXManager] Failed to create player for: \(filename)")
            #endif
            return
        }

        player.volume = vol
        player.prepareToPlay()
        player.play()

        activePlayers.append(player)

        // Clean up finished players periodically
        cleanupFinishedPlayers()
    }

    /// Preload SFX into memory cache for faster first playback.
    /// Also preloads all variations (e.g. hit_physical_2, hit_physical_3).
    func preload(_ sfxList: [SFX]) {
        for sfx in sfxList {
            for i in 1...sfx.variationCount {
                let filename = i == 1 ? sfx.filename : sfx.rawValue + "_\(i).wav"
                guard cache[filename] == nil else { continue }

                let name = (filename as NSString).deletingPathExtension
                let ext = (filename as NSString).pathExtension.isEmpty ? "wav" : (filename as NSString).pathExtension

                if let url = Bundle.main.url(forResource: name, withExtension: ext),
                   let data = try? Data(contentsOf: url) {
                    cache[filename] = data
                }
            }
        }
    }

    /// Clear all cached audio data.
    func clearCache() {
        cache.removeAll()
        activePlayers.removeAll()
    }

    // MARK: - Private

    private func cleanupFinishedPlayers() {
        activePlayers.removeAll { !$0.isPlaying }
    }
}

