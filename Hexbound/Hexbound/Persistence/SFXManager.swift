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

    /// Play a sound effect by SFX enum case.
    func play(_ sfx: SFX) {
        play(filename: sfx.filename)
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
    func preload(_ sfxList: [SFX]) {
        for sfx in sfxList {
            let filename = sfx.filename
            guard cache[filename] == nil else { continue }

            let name = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension.isEmpty ? "wav" : (filename as NSString).pathExtension

            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let data = try? Data(contentsOf: url) {
                cache[filename] = data
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

// MARK: - SFX Catalog

/// All available sound effects in the game.
/// Audio files go in the bundle as `<rawValue>.wav`.
/// If a file is missing, SFXManager silently skips it (no crash).
enum SFX: String, CaseIterable {
    // UI — general
    case uiTap = "ui_tap"
    case uiTapHeavy = "ui_tap_heavy"
    case uiOpen = "ui_open"
    case uiClose = "ui_close"
    case uiTransition = "ui_transition"
    case uiBack = "ui_back"
    case uiConfirm = "ui_confirm"
    case uiCancel = "ui_cancel"
    case uiError = "ui_error"
    case uiToggle = "ui_toggle"
    case uiSlide = "ui_slide"

    // UI — specific screens
    case uiPurchase = "ui_purchase"
    case uiEquip = "ui_equip"
    case uiUnequip = "ui_unequip"
    case uiSell = "ui_sell"
    case uiUpgradeSuccess = "ui_upgrade_success"
    case uiUpgradeFail = "ui_upgrade_fail"
    case uiLevelUp = "ui_level_up"
    case uiQuestComplete = "ui_quest_complete"
    case uiRewardClaim = "ui_reward_claim"

    // Battle result
    case battleVictory = "battle_victory"
    case battleDefeat = "battle_defeat"
    case battleDraw = "battle_draw"
    case battleStart = "battle_start"

    // Combat — hits
    case hitPhysical = "hit_physical"
    case hitMagical = "hit_magical"
    case hitCritical = "hit_critical"
    case hitPoison = "hit_poison"

    // Combat — actions
    case combatBlock = "combat_block"
    case combatMiss = "combat_miss"
    case combatDodge = "combat_dodge"
    case combatPoison = "combat_poison"
    case combatHeal = "combat_heal"
    case combatDeath = "combat_death"

    // Misc
    case coinDrop = "coin_drop"
    case itemDrop = "item_drop"
    case potionUse = "potion_use"

    var filename: String { rawValue + ".wav" }

    // MARK: - Combat Mapping

    /// Map a VFXEffectType to the corresponding SFX.
    static func from(vfxType: VFXEffectType) -> SFX {
        switch vfxType {
        case .physicalHit:  return .hitPhysical
        case .physicalCrit: return .hitCritical
        case .magicalHit:   return .hitMagical
        case .magicalCrit:  return .hitCritical
        case .poisonHit:    return .hitPoison
        case .poisonCrit:   return .hitCritical
        case .trueHit:      return .hitMagical
        case .trueCrit:     return .hitCritical
        case .dodge:        return .combatDodge
        case .miss:         return .combatMiss
        case .block:        return .combatBlock
        case .heal:         return .combatHeal
        case .statusProc:   return .combatPoison
        }
    }
}
