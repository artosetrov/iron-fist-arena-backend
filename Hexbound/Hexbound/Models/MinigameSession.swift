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

    /// Background PNG asset used during the 60s mini-game.
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
    let expiresAt: String
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

enum GoldMineSlotStatus: String, Codable {
    case idle
    case mining
    case ready
}

struct GoldMineSlotStatsResponse: Codable, Equatable {
    let totalGoldMined: Int
    let sessionsCompleted: Int
    let bestHaul: Int
    let currentStreak: Int
}

struct GoldMineSlotResponse: Codable, Equatable {
    var slotIndex: Int
    var status: GoldMineSlotStatus
    var sessionId: String?
    var startedAt: String?
    var endsAt: String?
    var reward: Int?
    var gemReward: Int?
    var boosted: Bool?
    var minigamePlayed: Bool?
    var minigameSessionId: String?
    var stats: GoldMineSlotStatsResponse?

    init(
        slotIndex: Int,
        status: GoldMineSlotStatus,
        sessionId: String?,
        startedAt: String?,
        endsAt: String?,
        reward: Int?,
        gemReward: Int?,
        boosted: Bool?,
        minigamePlayed: Bool?,
        minigameSessionId: String?,
        stats: GoldMineSlotStatsResponse?
    ) {
        self.slotIndex = slotIndex
        self.status = status
        self.sessionId = sessionId
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.reward = reward
        self.gemReward = gemReward
        self.boosted = boosted
        self.minigamePlayed = minigamePlayed
        self.minigameSessionId = minigameSessionId
        self.stats = stats
    }

    var hasPlayedMinigame: Bool {
        minigamePlayed ?? false
    }

    var hasInFlightMinigameSession: Bool {
        guard let minigameSessionId else { return false }
        return !minigameSessionId.isEmpty
    }

    var isBoosted: Bool {
        boosted ?? false
    }

    func resolvedStatus(now: Date = Date()) -> GoldMineSlotStatus {
        guard status == .mining, let endsAt else { return status }
        guard let endDate = parseGoldMineISODate(endsAt) else { return status }
        return endDate <= now ? .ready : status
    }
}

struct GoldMineStatusResponse: Codable {
    let slots: [GoldMineSlotResponse]
    let maxSlots: Int
}

protocol GoldMineSlotsBridge {
    var slots: [GoldMineSlotResponse] { get }
}

extension GoldMineSlotsBridge {
}

private func parseGoldMineISODate(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) {
            return date
        }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: raw)
}

struct GoldMineSlotActionRequest: Encodable {
    let characterId: String
    let slotIndex: Int
}

struct GoldMineCharacterRequest: Encodable {
    let characterId: String
}

struct GoldMineCollectAllRequest: Encodable {
    let characterId: String
    let pickedShaftKey: ShaftKey?
}

struct GoldMineSlotMinigameStartRequest: Encodable {
    let characterId: String
    let slotIndex: Int
    let pickedShaftKey: ShaftKey?
}

struct GoldMineSlotMinigameSubmitRequest: Encodable {
    let characterId: String
    let slotIndex: Int?
    let sessionId: String
    let caughtCount: Int
    let spawnedCount: Int
    let goldClaimedInSession: Int
    let gemsClaimedInSession: Int
    let skipped: Bool
}

struct GoldMineStartResponse: Codable, GoldMineSlotsBridge {
    let slots: [GoldMineSlotResponse]
}

struct GoldMineCollectResponse: Codable, GoldMineSlotsBridge {
    let slots: [GoldMineSlotResponse]
    let goldCollected: Int
    let gemsCollected: Int
    let gold: Int
    let gems: Int
    let activeShaft: ActiveShaft?
}

struct GoldMineCollectAllResponse: Codable, GoldMineSlotsBridge {
    let slots: [GoldMineSlotResponse]
    let goldCollected: Int
    let gemsCollected: Int
    let gold: Int?
    let gems: Int?
    let needsShaftPick: Bool?
    let unlockedShafts: [ShaftKey]?
    let activeShaft: ActiveShaft?
    let unplayedReadySlotIndices: [Int]?
}

struct GoldMineSlotMinigameStartResponse: Codable, GoldMineSlotsBridge {
    let needsShaftPick: Bool?
    let unlockedShafts: [ShaftKey]?
    let slots: [GoldMineSlotResponse]
    let activeShaft: ActiveShaft?
    let minigameSession: MinigameSessionInfo?
}

struct GoldMineBoostResponse: Codable, GoldMineSlotsBridge {
    let slots: [GoldMineSlotResponse]
    let gems: Int
}

struct GoldMineBuySlotResponse: Codable, GoldMineSlotsBridge {
    let slots: [GoldMineSlotResponse]
    let maxSlots: Int
    let gems: Int
}

struct GoldMineSlotMinigameSubmitResponse: Codable, GoldMineSlotsBridge {
    let bonusGold: Int
    let bonusGems: Int
    let gold: Int
    let gems: Int
    let slots: [GoldMineSlotResponse]
}

struct FortuneWheelStatusResponse: Codable {
    let spinsToday: Int?
    let spinsLimit: Int
    let spinsRemaining: Int
    let gold: Int?
}

struct FortuneWheelSpinRequest: Encodable {
    let characterId: String
    let betAmount: Int
}

struct FortuneWheelSectorResponse: Codable, Equatable {
    let index: Int
    let multiplier: Double
    let label: String
}

struct FortuneWheelSpinResponse: Codable {
    let won: Bool
    let sectorIndex: Int
    let multiplier: Double
    let winAmount: Int
    let gold: Int
    let spinsToday: Int?
    let spinsLimit: Int
    let spinsRemaining: Int
    let sectors: [FortuneWheelSectorResponse]?
}

struct ShellGameStatusResponse: Codable {
    let playsRemaining: Int
    let playsLimit: Int
}

struct ShellGameStartRequest: Encodable {
    let characterId: String
    let betAmount: Int
}

struct ShellGameStartResponse: Codable {
    let sessionId: String
    let betAmount: Int
    let playsRemaining: Int
    let playsLimit: Int
}

struct ShellGameGuessRequest: Encodable {
    let characterId: String
    let sessionId: String
    let chosenCup: Int
}

struct ShellGameGuessResponse: Codable {
    let won: Bool
    let winningCup: Int
    let winAmount: Int
    let gold: Int
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
/// is always capped server-side in /slot-minigame/submit. Kept deterministic
/// so playtesting stays reproducible.
///
/// NOTE: Drop weights are now per-wave (see `MinigameWave` in
/// GoldMineMiniGameView.swift). These constants are kept for backward
/// compat and as default fallback values.
enum MinigameDropValue {
    /// Default gold drop weights (used by warmup wave).
    static let goldDrops: [(value: Int, weight: Int)] = [
        (1, 55),
        (2, 25),
        (3, 12),
        (5, 6),
        (10, 2),
    ]

    /// Default gem drop weight (3%).
    static let gemDropWeight: Int = 3

    /// Max drops spawned per 60s session (~160, varies by wave pacing).
    static let spawnPerSession: Int = 160
}
