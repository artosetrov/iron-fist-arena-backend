import AVFoundation

// MARK: - Ambient Zone Catalog

/// Defines ambient sound zones — each zone can have multiple layered loops.
/// Files go in `Resources/Audio/Ambient/` as `.wav` or `.ogg`.
/// If a file is missing, AmbientManager silently skips it (no crash).
enum AmbientZone: String, CaseIterable {

    // --- Hub / City ---
    case hub               // City hub — torch crackle + distant crowd murmur
    case hubRain           // Hub during rain weather — rain loop + distant thunder

    // --- Arena ---
    case arena             // Arena lobby — crowd murmur + distant cheers
    case arenaFight        // Active PvP fight — intense crowd roar

    // --- Dungeon ---
    case dungeon           // Generic dungeon floor — cave drip + wind
    case dungeonDeep       // Deep floors (6+) — heavier wind + bone rattle
    case dungeonBoss       // Boss room — ominous rumble

    // --- Shop ---
    case shop              // Merchant shop — fire crackle + coin clink ambient

    // --- Inventory / Forge ---
    case forge             // Upgrade/inventory — forge fire + anvil ambient

    // --- Minigames ---
    case goldMine          // Gold mine — pickaxe echoes + dripping
    case tavern            // Shell game / fortune wheel — tavern bustle

    // --- Onboarding ---
    case cinematic         // Onboarding cinematic — wind howl + fire distant

    // --- Profile / Leaderboard ---
    case hallOfFame        // Leaderboard — torch + echo hall

    /// Layers of looping audio files for this zone.
    /// Multiple layers mix together for richer atmosphere.
    var layers: [AmbientLayer] {
        switch self {
        case .hub:
            return [
                AmbientLayer(file: "amb_torch_crackle", volume: 0.25),
                AmbientLayer(file: "amb_city_murmur", volume: 0.15),
                AmbientLayer(file: "amb_wind_light", volume: 0.10),
            ]
        case .hubRain:
            return [
                AmbientLayer(file: "amb_rain_loop", volume: 0.30),
                AmbientLayer(file: "amb_thunder_distant", volume: 0.12),
                AmbientLayer(file: "amb_torch_crackle", volume: 0.15),
            ]
        case .arena:
            return [
                AmbientLayer(file: "amb_crowd_murmur", volume: 0.20),
                AmbientLayer(file: "amb_torch_crackle", volume: 0.15),
            ]
        case .arenaFight:
            return [
                AmbientLayer(file: "amb_crowd_roar", volume: 0.25),
                AmbientLayer(file: "amb_torch_crackle", volume: 0.10),
            ]
        case .dungeon:
            return [
                AmbientLayer(file: "amb_cave_drip", volume: 0.25),
                AmbientLayer(file: "amb_wind_cave", volume: 0.18),
            ]
        case .dungeonDeep:
            return [
                AmbientLayer(file: "amb_cave_drip", volume: 0.20),
                AmbientLayer(file: "amb_wind_heavy", volume: 0.22),
                AmbientLayer(file: "amb_bone_rattle", volume: 0.08),
            ]
        case .dungeonBoss:
            return [
                AmbientLayer(file: "amb_ominous_rumble", volume: 0.30),
                AmbientLayer(file: "amb_wind_cave", volume: 0.12),
            ]
        case .shop:
            return [
                AmbientLayer(file: "amb_torch_crackle", volume: 0.20),
                AmbientLayer(file: "amb_coins_ambient", volume: 0.10),
            ]
        case .forge:
            return [
                AmbientLayer(file: "amb_forge_fire", volume: 0.25),
                AmbientLayer(file: "amb_anvil_ambient", volume: 0.08),
            ]
        case .goldMine:
            return [
                AmbientLayer(file: "amb_cave_drip", volume: 0.22),
                AmbientLayer(file: "amb_pickaxe_distant", volume: 0.10),
                AmbientLayer(file: "amb_wind_cave", volume: 0.08),
            ]
        case .tavern:
            return [
                AmbientLayer(file: "amb_tavern_bustle", volume: 0.22),
                AmbientLayer(file: "amb_torch_crackle", volume: 0.12),
            ]
        case .cinematic:
            return [
                AmbientLayer(file: "amb_wind_heavy", volume: 0.20),
                AmbientLayer(file: "amb_fire_distant", volume: 0.12),
            ]
        case .hallOfFame:
            return [
                AmbientLayer(file: "amb_torch_crackle", volume: 0.18),
                AmbientLayer(file: "amb_hall_echo", volume: 0.12),
            ]
        }
    }
}

/// A single ambient audio layer within a zone.
struct AmbientLayer {
    let file: String       // Filename without extension (looks for .wav first, then .mp3)
    let volume: Float      // Base volume (0.0–1.0), scaled by user sfxVolume setting
}

// MARK: - Ambient Manager

/// Manages looping ambient sound layers per game zone.
/// Crossfades between zones for seamless transitions.
/// Volume respects the user's SFX volume setting.
@MainActor
final class AmbientManager {
    static let shared = AmbientManager()

    private let settings = SettingsManager.shared

    /// Currently active zone
    private(set) var currentZone: AmbientZone?

    /// Active looping players for the current zone
    private var activeLayers: [AVAudioPlayer] = []

    /// Crossfade duration in seconds
    private let crossfadeDuration: TimeInterval = 1.0

    /// Fade-out task for previous zone layers
    private var fadeOutTask: Task<Void, Never>?

    /// Players being faded out (kept alive until fade completes)
    private var fadingOutPlayers: [AVAudioPlayer] = []

    private init() {}

    // MARK: - Public API

    /// Transition to a new ambient zone with crossfade.
    /// If already in this zone, does nothing.
    /// Pass `nil` to stop all ambient audio.
    func setZone(_ zone: AmbientZone?) {
        guard zone != currentZone else {
            syncVolume()
            return
        }

        // Fade out current layers
        fadeOutCurrentLayers()

        currentZone = zone

        guard let zone else { return }
        guard !settings.isMuted, settings.sfxVolume > 0 else { return }

        // Start new layers
        startLayers(for: zone)
    }

    /// Call when sfxVolume or isMuted changes.
    func syncVolume() {
        let muted = settings.isMuted
        let vol = settings.sfxVolume

        for (index, player) in activeLayers.enumerated() {
            guard let zone = currentZone else { break }
            let layers = zone.layers
            guard index < layers.count else { break }

            let targetVol = muted ? Float(0) : layers[index].volume * vol
            player.volume = targetVol

            if targetVol > 0 && !player.isPlaying {
                player.play()
            } else if targetVol <= 0 && player.isPlaying {
                player.pause()
            }
        }
    }

    /// Stop all ambient immediately (no fade). Use for app background / cleanup.
    func stopAll() {
        fadeOutTask?.cancel()
        for player in activeLayers { player.stop() }
        for player in fadingOutPlayers { player.stop() }
        activeLayers.removeAll()
        fadingOutPlayers.removeAll()
        currentZone = nil
    }

    // MARK: - Private

    private func startLayers(for zone: AmbientZone) {
        var newPlayers: [AVAudioPlayer] = []

        for layer in zone.layers {
            guard let player = loadPlayer(filename: layer.file) else { continue }

            player.numberOfLoops = -1 // Loop forever
            player.volume = 0         // Start silent for fade-in
            player.prepareToPlay()
            player.play()

            let targetVol = layer.volume * settings.sfxVolume
            player.setVolume(targetVol, fadeDuration: crossfadeDuration)

            newPlayers.append(player)
        }

        activeLayers = newPlayers
    }

    private func fadeOutCurrentLayers() {
        fadeOutTask?.cancel()

        let playersToFade = activeLayers
        activeLayers = []

        guard !playersToFade.isEmpty else { return }

        // Keep references alive during fade
        fadingOutPlayers.append(contentsOf: playersToFade)

        for player in playersToFade {
            player.setVolume(0, fadeDuration: crossfadeDuration)
        }

        fadeOutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(self?.crossfadeDuration ?? 1.0 + 0.1))
            guard !Task.isCancelled else { return }
            for player in playersToFade {
                player.stop()
            }
            self?.fadingOutPlayers.removeAll { playersToFade.contains($0) }
        }
    }

    private func loadPlayer(filename: String) -> AVAudioPlayer? {
        // Try .wav first, then .mp3
        for ext in ["wav", "mp3"] {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                return try? AVAudioPlayer(contentsOf: url)
            }
        }
        #if DEBUG
        print("[AmbientManager] File not found: \(filename).wav/.mp3")
        #endif
        return nil
    }
}
