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

/// The running expedition: every collected cart is one haul, `total` hauls
/// open the expedition chest and the next expedition starts on its own
/// (2026-10-16). The shaft key only picks the bonus-round backdrop.
struct ActiveShaft: Codable, Equatable {
    let key: ShaftKey
    let progress: Int   // carts hauled this expedition (0..<total)
    let total: Int      // carts per expedition (5)

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

    /// An empty tunnel — stands in for a slot the server has not listed yet
    /// (e.g. right after buying one).
    static func idle(_ slotIndex: Int) -> GoldMineSlotResponse {
        GoldMineSlotResponse(
            slotIndex: slotIndex,
            status: .idle,
            sessionId: nil,
            startedAt: nil,
            endsAt: nil,
            reward: nil,
            gemReward: nil,
            boosted: nil,
            minigamePlayed: nil,
            minigameSessionId: nil,
            stats: nil
        )
    }

    var startDate: Date? { startedAt.flatMap(parseGoldMineISODate) }
    var endDate: Date? { endsAt.flatMap(parseGoldMineISODate) }

    func resolvedStatus(now: Date = Date()) -> GoldMineSlotStatus {
        guard status == .mining, let endsAt else { return status }
        guard let endDate = parseGoldMineISODate(endsAt) else { return status }
        return endDate <= now ? .ready : status
    }
}

struct GoldMineStatusResponse: Codable {
    let slots: [GoldMineSlotResponse]
    let maxSlots: Int
    /// The running expedition — always sent since 2026-10-16.
    let activeShaft: ActiveShaft?
    /// Prices, payout ranges and bonus terms (2026-10-16). Decoded leniently:
    /// a malformed block drops to nil instead of failing the whole status.
    let economy: GoldMineEconomy?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        slots = try c.decode([GoldMineSlotResponse].self, forKey: .slots)
        maxSlots = try c.decode(Int.self, forKey: .maxSlots)
        activeShaft = try? c.decodeIfPresent(ActiveShaft.self, forKey: .activeShaft)
        economy = try? c.decodeIfPresent(GoldMineEconomy.self, forKey: .economy)
    }
}

/// Everything the mine screen prints about payouts and prices, sent by
/// /status so the client keeps no copy of balance numbers. Mirrors the
/// `economy` block in `backend/.../gold-mine/status/route.ts`.
struct GoldMineEconomy: Codable, Equatable {
    let slotLimit: Int
    let slotCostGems: Int
    let boostCostGems: Int
    /// A boosted ("double haul") cart pays this many times its haul.
    let boostMultiplier: Int?
    let runHours: Double
    let rewardMin: Int
    let rewardMax: Int
    /// 0…1 chance that a cart also carries gems.
    let gemChance: Double
    let gemMin: Int
    let gemMax: Int
    let chestGold: Int
    let chestGems: Int
    // Bonus round (optional coin rush) — newer than the rest, so optional.
    let bonusSeconds: Int?
    let bonusCapPercent: Int?
    let bonusGemCap: Int?
    let bonusGemCatchPercent: Int?
}

/// Paid when an expedition fills (`expedition_chest` on collect responses).
struct GoldMineExpeditionChest: Codable, Equatable {
    let gold: Int
    let gems: Int
    let shaftKey: String?
}

protocol GoldMineSlotsBridge {
    var slots: [GoldMineSlotResponse] { get }
}

extension GoldMineSlotsBridge {
}

private let goldMineFractionalISO: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

private let goldMinePlainISO: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

/// Parsed every second per tunnel on the mine screen — formatters are shared.
private func parseGoldMineISODate(_ raw: String) -> Date? {
    goldMineFractionalISO.date(from: raw) ?? goldMinePlainISO.date(from: raw)
}

struct GoldMineSlotActionRequest: Encodable {
    let characterId: String
    let slotIndex: Int
}

struct GoldMineCharacterRequest: Encodable {
    let characterId: String
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
    let expeditionChest: GoldMineExpeditionChest?
}

struct GoldMineCollectAllResponse: Codable, GoldMineSlotsBridge {
    let slots: [GoldMineSlotResponse]
    let goldCollected: Int
    let gemsCollected: Int
    let gold: Int?
    let gems: Int?
    let activeShaft: ActiveShaft?
    let expeditionChest: GoldMineExpeditionChest?
}

struct GoldMineSlotMinigameStartResponse: Codable, GoldMineSlotsBridge {
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
    /// Server-published outcome probabilities (App Store 3.1.1 odds disclosure).
    let odds: [FortuneWheelOdd]?
    /// Fortuna's Treasury — progressive jackpot paid on the x5 sector.
    let treasury: Int?
    /// Bets this size or more get the full take; smaller bets scale down.
    let treasuryMaxBet: Int?
    /// Fraction of the Treasury a max bet takes on x5.
    let treasuryTakeRate: Double?
}

struct FortuneWheelOdd: Codable, Identifiable {
    let label: String
    let multiplier: Double
    let percent: Double
    var id: Double { multiplier }
    var displayLabel: String { multiplier == 0 ? "Lose" : "×\(multiplier.formatted(.number.precision(.fractionLength(0...1))))" }
    var displayPercent: String { "\(percent.formatted(.number.precision(.fractionLength(0...1))))%" }
}

struct FortuneWheelSpinRequest: Encodable {
    let characterId: String
    let betAmount: Int
}

struct FortuneWheelSectorResponse: Codable, Equatable {
    let index: Int
    let multiplier: Double
    let label: String
    let jackpot: Bool?
}

struct FortuneWheelSpinResponse: Codable {
    let won: Bool
    let sectorIndex: Int
    let multiplier: Double
    /// Total paid, Treasury share included.
    let winAmount: Int
    /// Part of `winAmount` that came from the Treasury (x5 only).
    let jackpotShare: Int?
    /// Treasury after this spin.
    let treasury: Int?
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
