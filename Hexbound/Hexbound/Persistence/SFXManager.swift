import AVFoundation

/// Manages sound effect playback for the app.
///
/// Latency pass (2026-10-15): the main thread only reads settings and
/// enqueues. Reading the WAV, creating the `AVAudioPlayer` and
/// `prepareToPlay()` all used to run on main on EVERY button touch-down
/// (a fresh player per play), which cost a few ms per tap and much more on
/// the first play of each file. They now live on a private serial queue
/// that keeps a small pool of prepared players per file, so a repeat play
/// is "rewind + play" on an already-prepared player.
@MainActor
final class SFXManager {
    static let shared = SFXManager()

    private let settings = SettingsManager.shared
    private let engine = SFXPlaybackEngine()

    /// Sounds every screen hits within the first seconds — warmed at launch
    /// so the very first tap is as fast as the hundredth.
    static let uiWarmSet: [SFX] = [
        .uiTap, .uiTapHeavy, .uiOpen, .uiClose, .uiConfirm, .uiCancel,
        .uiError, .uiToggle, .uiEquip, .uiUnequip, .uiPurchase, .uiRewardClaim,
    ]

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

    /// Play a sound effect by filename (looks in bundle). Never blocks main.
    func play(filename: String) {
        guard !settings.isMuted else { return }
        let vol = settings.sfxVolume
        guard vol > 0 else { return }
        engine.play(filename: filename, volume: vol)
    }

    /// Preload SFX (and their variations) into prepared players off the
    /// main thread, so the first playback has no file I/O.
    func preload(_ sfxList: [SFX]) {
        var filenames: [String] = []
        for sfx in sfxList {
            for i in 1...max(1, sfx.variationCount) {
                filenames.append(i == 1 ? sfx.filename : sfx.rawValue + "_\(i).wav")
            }
        }
        engine.preload(filenames: filenames)
    }

    /// Warm the UI tap / confirm sounds. Called once at launch.
    func preloadUI() {
        preload(Self.uiWarmSet)
    }

    /// Clear all cached audio data.
    func clearCache() {
        engine.clear()
    }
}

// MARK: - Playback engine (off main)

/// Owns every `AVAudioPlayer` used for SFX. All state is confined to
/// `queue`, which is why the class can be `@unchecked Sendable`.
final class SFXPlaybackEngine: @unchecked Sendable {
    private let queue = DispatchQueue(label: "app.hexbound.sfx", qos: .userInteractive)
    private var dataCache: [String: Data] = [:]
    private var pools: [String: [AVAudioPlayer]] = [:]
    private var missing: Set<String> = []

    /// Overlapping copies of one sound allowed at once. A fifth rapid tap
    /// restarts the oldest copy instead of allocating more players.
    private let maxPlayersPerFile = 4

    func play(filename: String, volume: Float) {
        queue.async { [self] in
            guard let player = dequeuePlayer(for: filename) else { return }
            player.volume = volume
            player.currentTime = 0
            player.play()
        }
    }

    func preload(filenames: [String]) {
        queue.async { [self] in
            for filename in filenames where (pools[filename] ?? []).isEmpty {
                if let player = makePlayer(for: filename) {
                    pools[filename] = [player]
                }
            }
        }
    }

    func clear() {
        queue.async { [self] in
            for pool in pools.values { pool.forEach { $0.stop() } }
            pools.removeAll()
            dataCache.removeAll()
            missing.removeAll()
        }
    }

    // MARK: Queue-confined helpers

    private func dequeuePlayer(for filename: String) -> AVAudioPlayer? {
        var pool = pools[filename] ?? []
        if let idle = pool.first(where: { !$0.isPlaying }) {
            return idle
        }
        if pool.count >= maxPlayersPerFile, let oldest = pool.first {
            // Rotate so the next overflow restarts a different copy.
            pool.removeFirst()
            pool.append(oldest)
            pools[filename] = pool
            oldest.stop()
            return oldest
        }
        guard let player = makePlayer(for: filename) else { return nil }
        pool.append(player)
        pools[filename] = pool
        return player
    }

    private func makePlayer(for filename: String) -> AVAudioPlayer? {
        guard let data = loadData(filename) else { return nil }
        guard let player = try? AVAudioPlayer(data: data) else {
            #if DEBUG
            print("[SFXManager] Failed to create player for: \(filename)")
            #endif
            return nil
        }
        player.prepareToPlay()
        return player
    }

    private func loadData(_ filename: String) -> Data? {
        if let cached = dataCache[filename] { return cached }
        guard !missing.contains(filename) else { return nil }

        let name = (filename as NSString).deletingPathExtension
        let rawExt = (filename as NSString).pathExtension
        let ext = rawExt.isEmpty ? "wav" : rawExt
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let loaded = try? Data(contentsOf: url) else {
            #if DEBUG
            print("[SFXManager] File not found or unreadable: \(filename)")
            #endif
            missing.insert(filename)
            return nil
        }
        dataCache[filename] = loaded
        return loaded
    }
}
