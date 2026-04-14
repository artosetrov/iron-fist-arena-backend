//
//  InteractiveCombatModels.swift
//  Hexbound
//
//  Interactive Combat v1 — DTOs for match lifecycle endpoints:
//    POST /api/pvp/match/start    — begin an in-progress match
//    POST /api/pvp/strike         — resolve one round (player + AI counter)
//    POST /api/pvp/match/complete — finalize: ELO + rewards
//  Additive, feature-flagged on server. Does NOT replace existing CombatData.
//

import Foundation

// MARK: - Body Zone

/// Three zones for attack / defense pick in Predict window.
/// Must match backend `BodyZone` in balance.ts.
enum InteractiveBodyZone: String, Codable, CaseIterable, Sendable {
    case head
    case chest
    case legs
}

// MARK: - Match Start

// NOTE: APIClient sets JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase
// and JSONEncoder.keyEncodingStrategy = .convertToSnakeCase. Per
// `Hexbound/CLAUDE.md` CodingKeys-vs-convertFromSnakeCase rule: do NOT
// redeclare CodingKeys with snake_case raw values — that bypasses the
// strategy and causes `keyNotFound` failures (e.g. "Decode: missing
// 'match_id'"). Only define CodingKeys when renaming is required
// (e.g. `class` is a Swift keyword → must map explicitly).

struct InteractiveMatchStartRequest: Encodable, Sendable {
    let characterId: String
    let opponentId: String
}

struct InteractiveCharacterSnapshot: Decodable, Sendable {
    let id: String
    let characterName: String?
    let characterClass: String?
    let origin: String?
    let level: Int?
    let avatar: String?
    let maxHp: Int
    let currentHp: Int

    enum CodingKeys: String, CodingKey {
        case id
        case characterName
        case characterClass = "class"
        case origin, level, avatar
        case maxHp
        case currentHp
    }
}

struct InteractiveMatchStaminaInfo: Decodable, Sendable {
    let current: Int
    let max: Int
}

struct InteractiveMatchStartResponse: Decodable, Sendable {
    let matchId: String
    let maxRounds: Int
    let timeoutAt: String
    let attacker: InteractiveCharacterSnapshot
    let defender: InteractiveCharacterSnapshot
    let stamina: InteractiveMatchStaminaInfo
    let actives: InteractiveActivesState?
}

// MARK: - Active Slot Snapshot (Phase 3)

/// Mirror of ActiveSlotSnapshot from backend pvp/strike/route.ts. Fired slot
/// sets `cooldownRemaining = cooldownMax`; tick-down happens each round.
struct InteractiveActiveSlotSnapshot: Decodable, Sendable, Hashable, Identifiable {
    var id: Int { slotIndex }
    let slotIndex: Int
    let nodeId: Int
    let nodeKey: String
    let name: String
    let icon: String?
    let actionType: String?
    let cooldownMax: Int
    let magnitude: Double
    let cooldownRemaining: Int

    var isReady: Bool { cooldownRemaining == 0 && actionType != nil }

    var talentAction: TalentSlotAction? {
        guard let raw = actionType else { return nil }
        return TalentSlotAction(rawValue: raw)
    }
}

struct InteractiveActivesState: Decodable, Sendable {
    let p1: [InteractiveActiveSlotSnapshot]
    let p2: [InteractiveActiveSlotSnapshot]
}

// MARK: - Strike Request (v2 — match-aware)

struct InteractiveStrikeRequest: Encodable, Sendable {
    let matchId: String
    let attackerZone: InteractiveBodyZone
    let defenderZone: InteractiveBodyZone
    /// Phase 3 — optional slot index (0..2) to fire an active this round.
    let playerActiveSlot: Int?
}

// MARK: - Strike Response (v2 — two turns + server-authoritative HP)

/// Mirrors backend `Turn` shape returned from resolveSingleStrike.
struct InteractiveStrikeTurn: Decodable, Sendable {
    let turnNumber: Int?
    let attackerId: String?
    let damage: Int
    let isCrit: Bool?
    let isDodge: Bool?
    let isMiss: Bool?
    let defenderHpAfter: Int?
    let targetZone: String?
    let defendZone: String?
    let skillUsed: String?
    let skillKey: String?
    let damageType: String?
    let healAmount: Int?
}

struct InteractiveOpponentZones: Decodable, Sendable {
    let attack: InteractiveBodyZone
    let defend: InteractiveBodyZone
}

struct InteractiveStrikeResponse: Decodable, Sendable {
    let matchId: String
    let strikeIndex: Int
    let playerStrike: InteractiveStrikeTurn
    let opponentStrike: InteractiveStrikeTurn?
    let attackerHp: Int
    let defenderHp: Int
    let oppZones: InteractiveOpponentZones
    let matchFinished: Bool
    let winnerId: String?
    /// Phase 3 — refreshed active-slot state for both players (with cooldowns).
    let actives: InteractiveActivesState?
    /// Phase 3 — echoes the slot_index fired this round (nil = no active used).
    let playerActiveFired: Int?
    /// Phase 3 — action_type label that fired, for HUD floating-text feedback.
    let playerActiveLabel: String?
    /// Phase 3.B — opponent AI fired this slot_index (nil = no active used).
    let opponentActiveFired: Int?
    /// Phase 3.B — opponent action_type label that fired.
    let opponentActiveLabel: String?
}

// MARK: - Match Complete

struct InteractiveMatchCompleteRequest: Encodable, Sendable {
    let matchId: String
}

// /pvp/match/complete returns a CombatData-compatible payload, decoded directly
// via `APIClient.shared.post(...): CombatData` — no separate DTO needed.

// MARK: - Outcome Taxonomy (client-side derivation)

/// 9-outcome taxonomy from COMBAT_MECHANIC_SPEC.md §3.3.
/// Derived from the Turn DTO — backend doesn't tag this explicitly,
/// so the client classifies for Reveal animation + toast copy.
enum InteractiveStrikeOutcome: String, Sendable {
    case miss
    case dodge
    case glancing
    case hit
    case antiRead
    case crit
    case execute
    case blocked
    case fatigue

    var label: String {
        switch self {
        case .miss: return "MISS"
        case .dodge: return "DODGE"
        case .glancing: return "GLANCING"
        case .hit: return "HIT"
        case .antiRead: return "ANTI-READ"
        case .crit: return "CRIT"
        case .execute: return "EXECUTE"
        case .blocked: return "BLOCKED"
        case .fatigue: return "FATIGUE"
        }
    }

    static func classify(turn: InteractiveStrikeTurn,
                         attackerZone: InteractiveBodyZone,
                         defenderZone: InteractiveBodyZone,
                         baseExpected: Double = 0) -> InteractiveStrikeOutcome {
        if turn.isMiss == true { return .miss }
        if turn.isDodge == true { return .dodge }
        if let key = turn.skillKey?.lowercased(), key.contains("execute") {
            return .execute
        }
        if turn.damage <= 0 {
            return .blocked
        }
        if turn.isCrit == true { return .crit }

        let mismatch = attackerZone != defenderZone
        if baseExpected > 0 {
            let ratio = Double(turn.damage) / baseExpected
            if mismatch && ratio >= 1.5 { return .antiRead }
            if ratio < 0.25 { return .glancing }
        }
        return .hit
    }
}

// MARK: - Match State (client-owned)

/// Server is authoritative on HP (read from /strike response).
/// Client keeps a local mirror for the UI + animation history.
struct InteractiveMatchState: Sendable {
    var matchId: String
    let attackerId: String
    let defenderId: String
    var attackerHp: Int
    var defenderHp: Int
    let attackerMaxHp: Int
    let defenderMaxHp: Int
    var strikes: [InteractiveStrikeTurn] = []

    var isFinished: Bool {
        attackerHp <= 0 || defenderHp <= 0
    }

    var winnerId: String? {
        if defenderHp <= 0 { return attackerId }
        if attackerHp <= 0 { return defenderId }
        return nil
    }
}
