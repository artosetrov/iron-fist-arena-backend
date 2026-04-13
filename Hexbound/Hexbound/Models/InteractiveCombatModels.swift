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

struct InteractiveMatchStartRequest: Encodable, Sendable {
    let characterId: String
    let opponentId: String

    enum CodingKeys: String, CodingKey {
        case characterId = "character_id"
        case opponentId = "opponent_id"
    }
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
        case characterName = "character_name"
        case characterClass = "class"
        case origin, level, avatar
        case maxHp = "max_hp"
        case currentHp = "current_hp"
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

    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case maxRounds = "max_rounds"
        case timeoutAt = "timeout_at"
        case attacker, defender, stamina
    }
}

// MARK: - Strike Request (v2 — match-aware)

struct InteractiveStrikeRequest: Encodable, Sendable {
    let matchId: String
    let attackerZone: InteractiveBodyZone
    let defenderZone: InteractiveBodyZone

    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case attackerZone = "attacker_zone"
        case defenderZone = "defender_zone"
    }
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

    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case strikeIndex = "strike_index"
        case playerStrike = "player_strike"
        case opponentStrike = "opponent_strike"
        case attackerHp = "attacker_hp"
        case defenderHp = "defender_hp"
        case oppZones = "opp_zones"
        case matchFinished = "match_finished"
        case winnerId = "winner_id"
    }
}

// MARK: - Match Complete

struct InteractiveMatchCompleteRequest: Encodable, Sendable {
    let matchId: String

    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
    }
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
