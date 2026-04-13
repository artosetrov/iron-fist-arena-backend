//
//  InteractiveCombatModels.swift
//  Hexbound
//
//  Interactive Combat v1 — DTOs for POST /api/pvp/strike.
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

// MARK: - Strike Request

struct InteractiveStrikeRequest: Encodable, Sendable {
    let matchId: String
    let strikeIndex: Int
    let attackerId: String
    let defenderId: String
    let attackerZone: InteractiveBodyZone
    let defenderZone: InteractiveBodyZone
    let defenderHp: Int

    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case strikeIndex = "strike_index"
        case attackerId = "attacker_id"
        case defenderId = "defender_id"
        case attackerZone = "attacker_zone"
        case defenderZone = "defender_zone"
        case defenderHp = "defender_hp"
    }
}

// MARK: - Strike Response

/// Mirrors backend `Turn` shape returned from resolveSingleStrike.
struct InteractiveStrikeTurn: Decodable, Sendable {
    let turnNumber: Int
    let attackerId: String
    let damage: Int
    let isCrit: Bool
    let isDodge: Bool
    let isMiss: Bool?
    let defenderHpAfter: Int
    let targetZone: String?
    let defendZone: String?
    let skillUsed: String?
    let skillKey: String?
    let damageType: String?
    let healAmount: Int?

    enum CodingKeys: String, CodingKey {
        case turnNumber
        case attackerId
        case damage
        case isCrit
        case isDodge
        case isMiss
        case defenderHpAfter
        case targetZone
        case defendZone
        case skillUsed
        case skillKey
        case damageType
        case healAmount
    }
}

struct InteractiveStrikeResponse: Decodable, Sendable {
    let turn: InteractiveStrikeTurn
    let newDefenderHp: Int
    let healAmount: Int
    let seed: Int
    let matchId: String
    let strikeIndex: Int

    enum CodingKeys: String, CodingKey {
        case turn
        case newDefenderHp = "new_defender_hp"
        case healAmount = "heal_amount"
        case seed
        case matchId = "match_id"
        case strikeIndex = "strike_index"
    }
}

// MARK: - Outcome Taxonomy (client-side derivation)

/// 9-outcome taxonomy from COMBAT_MECHANIC_SPEC.md §3.3.
/// Derived from the Turn DTO — backend doesn't tag this explicitly,
/// so the client classifies for Reveal animation + toast copy.
enum InteractiveStrikeOutcome: String, Sendable {
    case miss          // CHA pre-hit whiff
    case dodge         // Defender evaded
    case glancing      // Hit but low damage (< 25% of base)
    case hit           // Normal hit
    case antiRead      // Zone mismatch caught the defender (high damage)
    case crit          // Rolled crit
    case execute       // Rogue execute threshold fired
    case blocked       // Zone match absorbed most of the hit
    case fatigue       // Battle-fatigue damage floor triggered

    /// Display string for HUD / reveal badge.
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

    /// Classify a resolved turn into a display outcome. Heuristic:
    /// — isMiss → miss
    /// — isDodge → dodge
    /// — damage == 0 && !miss/dodge → blocked (zone match fully absorbed)
    /// — skillUsed ~= execute → execute
    /// — isCrit → crit
    /// — attackerZone != defenderZone AND damage > 1.5× expected → antiRead
    /// — damage < 25% of baseExpected → glancing
    /// — else → hit
    ///
    /// `baseExpected` is the caller's estimated base damage (no crit/mult). Pass
    /// 0 to skip the glancing/antiRead tagging; result will collapse to .hit.
    static func classify(turn: InteractiveStrikeTurn,
                         attackerZone: InteractiveBodyZone,
                         defenderZone: InteractiveBodyZone,
                         baseExpected: Double = 0) -> InteractiveStrikeOutcome {
        if turn.isMiss == true { return .miss }
        if turn.isDodge { return .dodge }
        // Skill-flag routes
        if let key = turn.skillKey?.lowercased(), key.contains("execute") {
            return .execute
        }
        if turn.damage <= 0 {
            // Non-dodge, non-miss, zero damage → zone match absorption.
            return .blocked
        }
        if turn.isCrit { return .crit }

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

/// The iOS client owns match state across the strike loop since /pvp/strike
/// is stateless on the server in v1. Holds HP snapshots, strike history,
/// and the deterministic seed source (matchId).
struct InteractiveMatchState: Sendable {
    let matchId: String
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
