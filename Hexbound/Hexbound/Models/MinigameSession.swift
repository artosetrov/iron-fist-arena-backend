import Foundation

/// Gold Mine expedition shaft key — identifies the mini-game background + thumb.
/// Must match backend/src/lib/game/shaft-catalog.ts.
enum ShaftKey: String, Codable, CaseIterable, Identifiable {
    case stone
    case ice

    var id: String { rawValue }

    /// Human-facing label (English, per project rule).
    var displayName: String {
        switch self {
        case .stone: return "Stone Shaft"
        case .ice:   return "Ice Shaft"
        }
    }

    /// Background PNG asset used during the 15s mini-game.
    /// Re-uses mine-slot art from xcassets (covered by gradient overlay).
    var backgroundAssetName: String {
        switch self {
        case .stone: return "mine-slot-1"
        case .ice:   return "mine-slot-4"
        }
    }

    /// Thumbnail asset shown in the shaft picker sheet + active shaft banner.
    /// Re-uses mine-slot art from xcassets.
    var thumbAssetName: String {
        switch self {
        case .stone: return "mine-slot-1"
        case .ice:   return "mine-slot-4"
        }
    }

    /// Minimum gold_mine_slots level required to unlock this shaft.
    var unlockSlotLevel: Int {
        switch self {
        case .stone: return 1
        case .ice:   return 2
        }
    }

    /// Ordered list of all shaft keys.
    static var allKeys: [ShaftKey] { ShaftKey.allCases }
}

/// Summary of the player's currently active expedition shaft.
/// Nil when the player has no shaft selected — the client shows the picker.
struct ActiveShaft: Codable, Equatable {
    let key: ShaftKey
    let progress: Int   // completed extractions (0..total)
    let total: Int      // total extractions required (Phase 1: 5)

    /// Progress fraction 0.0–1.0 for the banner progress bar.
    var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(progress) / Double(total)
    }

    /// Human-readable progress label, e.g. "3/5".
    var progressLabel: String { "\(progress)/\(total)" }

    /// Percent label, e.g. "60%".
    var percentLabel: String {
        let pct = Int((fraction * 100).rounded())
        return "\(pct)%"
    }
}

/// A pending Gold Mine mini-game session returned by /slot-minigame/start
/// (Variant D Phase 2 — per-slot) or the legacy /collect-all flow (Phase 1).
/// Created server-side, claimed once via /slot-minigame/submit.
///
/// `slotIndex` is nil only for the legacy aggregate flow and will be dropped
/// once all clients have migrated.
struct MinigameSessionInfo: Codable, Equatable, Identifiable {
    let id: String
    let slotIndex: Int?
    let shaftKey: ShaftKey
    let passiveGoldAmount: Int
    let capGold: Int
    let gemCap: Int
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case slotIndex = "slot_index"
        case shaftKey = "shaft_key"
        case passiveGoldAmount = "passive_gold_amount"
        case capGold = "cap_gold"
        case gemCap = "gem_cap"
        case expiresAt = "expires_at"
    }
}

/// Result of a completed mini-game, returned by /minigame-bonus.
struct MinigameBonusResult: Codable, Equatable {
    let bonusGold: Int
    let bonusGems: Int
    let gold: Int
    let gems: Int
    let activeShaft: ActiveShaft?
    let shaftCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case bonusGold = "bonus_gold"
        case bonusGems = "bonus_gems"
        case gold
        case gems
        case activeShaft = "active_shaft"
        case shaftCompleted = "shaft_completed"
    }
}

/// Outcome of a /collect-all call. Two branches: needs picker or success.
enum CollectAllOutcome {
    case needsShaftPick(unlocked: [ShaftKey])
    case success(
        goldCollected: Int,
        gemsCollected: Int,
        activeShaft: ActiveShaft,
        minigameSession: MinigameSessionInfo
    )
}

// MARK: - Mini-game drop values (client visual only)

/// Static weight table for falling drops. Values are visual — final reward
/// is always capped server-side in /minigame-bonus. Kept deterministic so
/// playtesting stays reproducible.
enum MinigameDropValue {
    /// Drop kinds with their visual gold values + spawn weights.
    static let goldDrops: [(value: Int, weight: Int)] = [
        (1, 55),
        (2, 25),
        (3, 12),
        (5, 6),
        (10, 2),
    ]

    /// Gem drop weight relative to gold drops. A gem gives +1 to gems caught.
    static let gemDropWeight: Int = 3

    /// Total drops spawned per 15s session (roughly 1 every 300ms).
    static let spawnPerSession: Int = 50
}
