//
//  DiceCombatModels.swift
//  Hexbound
//
//  Dice combat — DTOs for the round-based duel and the Hero → Dice tab.
//  Spec: docs/06_game_systems/DICE_RUNES_DESIGN.md
//
//    POST /api/pvp/match/start      — begin a match, round 1 already rolled (`dice`)
//    POST /api/pvp/dice/act         — spend Focus: reroll a die (2) or set a face (4)
//    POST /api/pvp/dice/resolve     — clash; returns ordered events + next round
//    POST /api/pvp/match/complete   — unchanged (CombatData)
//    GET  /api/dice                 — both dice, sockets, the class's 9 runes
//    POST /api/dice/socket          — put / move / remove a rune
//
//  APIClient decodes with .convertFromSnakeCase — no CodingKeys except where
//  a key is a Swift keyword (`class`, `guard`).
//

import Foundation

// MARK: - Faces

enum DiceZone: String, Codable, Sendable, CaseIterable {
    case head, chest, legs

    /// Faces 0…5 are always head, head, chest, chest, legs, legs.
    static func of(face: Int) -> DiceZone {
        switch max(0, min(5, face)) {
        case 0, 1: return .head
        case 2, 3: return .chest
        default: return .legs
        }
    }

    /// Zone emblem imageset (Assets.xcassets).
    var emblemAsset: String {
        switch self {
        case .head: return "dice-zone-head"
        case .chest: return "dice-zone-body"
        case .legs: return "dice-zone-legs"
        }
    }

    var label: String {
        switch self {
        case .head: return "Head"
        case .chest: return "Body"
        case .legs: return "Legs"
        }
    }
}

/// Attack die = "a" / "atk", guard die = "d" / "grd" (combat vs profile wire names).
enum DiceKind: String, Sendable {
    case attack, guardDie

    var tileAsset: String { self == .attack ? "dice-face-attack" : "dice-face-guard" }
    var combatKey: String { self == .attack ? "a" : "d" }
    var profileKey: String { self == .attack ? "atk" : "grd" }
    var title: String { self == .attack ? "Attack die" : "Guard die" }
}

// MARK: - Combat public view (`dice` in start / act / resolve)

struct DiceDot: Decodable, Sendable, Equatable {
    let kind: String      // bleed | poison | burn
    let dmg: Int
    let rounds: Int
}

struct DiceSideView: Decodable, Sendable, Equatable {
    let id: String
    let hp: Int
    let maxHp: Int
    let focus: Int
    /// Rune key per face (6 entries, nil = bare face).
    let atk: [String?]
    let grd: [String?]
    let opened: Bool
    let stunned: Bool
    let frozen: Bool
    let dots: [DiceDot]
    let boss: Bool
}

struct DiceRollSide: Decodable, Sendable, Equatable {
    var a: Int
    var d: Int
    var a2: Int?
}

struct DiceRollView: Decodable, Sendable, Equatable {
    var p: DiceRollSide
    var o: DiceRollSide
}

struct DiceStrikePreview: Decodable, Sendable, Equatable {
    /// crit | hit | pierce | blocked | miss
    let out: String
    let expected: Int
    let missChance: Double
    let opens: Bool
    let halved: Bool
}

struct DicePreviewPair: Decodable, Sendable, Equatable {
    let p: DiceStrikePreview?
    let o: DiceStrikePreview?
}

struct DiceRules: Decodable, Sendable, Equatable {
    let rerollCost: Int
    let setFaceCost: Int
    let focusMax: Int
    let windowMs: Int
}

struct DiceActionDTO: Codable, Sendable, Equatable {
    /// reroll | set
    let type: String
    /// a | d
    let die: String
    let face: Int?
}

struct DiceMatchView: Decodable, Sendable, Equatable {
    let round: Int
    let maxRounds: Int
    let finished: Bool
    /// "p" | "o" | nil
    let winner: String?
    let playerFirst: Bool
    let omen: Bool
    let roll: DiceRollView
    let acted: DiceActionDTO?
    /// Boss telegraph — the face its attack die shows next round.
    let bossNext: Int?
    let p: DiceSideView
    let o: DiceSideView
    let preview: DicePreviewPair
    let rules: DiceRules
}

struct DiceRuneInfo: Decodable, Sendable, Equatable, Identifiable {
    let key: String
    let name: String
    let desc: String
    let asset: String
    /// atk | grd
    let die: String
    /// lesser | path | great
    let tier: String
    var id: String { key }
}

// MARK: - Events (ordered, from /pvp/dice/resolve)

struct DiceHpSnap: Decodable, Sendable, Equatable {
    let p: Int
    let o: Int
}

/// One flat shape for every event type; `t` says which fields are set:
///   act    — side, action, face, focus         (the opponent's hidden action lands)
///   dot    — side, kind, dmg
///   omen   —
///   stance — side, focus
///   strike — from, die (a|a2), out, dmg, zone, guardZone, opens, halved, runes, heal
///   rune   — side, die (a|d), rune, fx, value, focus
struct DiceEvent: Decodable, Sendable, Identifiable {
    let id = UUID()
    let t: String
    let hp: DiceHpSnap
    let side: String?
    let from: String?
    let die: String?
    let out: String?
    let dmg: Int?
    let zone: DiceZone?
    let guardZone: DiceZone?
    let opens: Bool?
    let halved: Bool?
    let runes: [String]?
    let heal: Int?
    let kind: String?
    let rune: String?
    let fx: String?
    let value: Int?
    let focus: Int?
    let action: DiceActionDTO?
    let face: Int?

    enum CodingKeys: String, CodingKey {
        case t, hp, side, from, die, out, dmg, zone
        case guardZone = "guard"
        case opens, halved, runes, heal, kind, rune, fx, value, focus, action, face
    }
}

// MARK: - Requests / responses

struct DiceMatchStartResponse: Decodable, Sendable {
    let matchId: String
    let maxRounds: Int
    let attacker: InteractiveCharacterSnapshot
    let defender: InteractiveCharacterSnapshot
    let dice: DiceMatchView?
    let runeInfo: [DiceRuneInfo]?
}

struct DiceActRequest: Encodable, Sendable {
    let matchId: String
    let round: Int
    let action: DiceActionDTO
}

struct DiceActResponse: Decodable, Sendable {
    let face: Int
    let dice: DiceMatchView
}

struct DiceResolveRequest: Encodable, Sendable {
    let matchId: String
    let round: Int
}

struct DiceResolveResponse: Decodable, Sendable {
    let round: Int
    let events: [DiceEvent]
    let dice: DiceMatchView
    let matchFinished: Bool
    let winnerId: String?
}

// MARK: - Hero → Dice tab

struct DiceDieLoadout: Decodable, Sendable, Equatable {
    let runes: [String?]
    let sockets: Int
    let maxSockets: Int
    let nextSocketLevel: Int?
    let used: Int
    let landChance: Double
}

struct DiceLoadoutPair: Decodable, Sendable, Equatable {
    let atk: DiceDieLoadout
    let grd: DiceDieLoadout
}

struct DiceRunePlacement: Decodable, Sendable, Equatable {
    let die: String
    let face: Int
}

struct DiceRuneEntry: Decodable, Sendable, Equatable, Identifiable {
    let key: String
    let name: String
    let desc: String
    let asset: String
    let die: String
    let tier: String
    let owned: Bool
    let socketed: DiceRunePlacement?
    let nodeKey: String
    let nodeId: String?
    let nodeName: String?
    let nodeCost: Int?
    var id: String { key }

    var tierLabel: String {
        switch tier {
        case "great": return "Great rune"
        case "path": return "Path rune"
        default: return "Lesser rune"
        }
    }
}

struct DiceLoadoutResponse: Decodable, Sendable, Equatable {
    let characterId: String
    let level: Int
    let characterClass: String
    let faces: [DiceZone]
    let inMatch: Bool
    let dice: DiceLoadoutPair
    let runes: [DiceRuneEntry]

    enum CodingKeys: String, CodingKey {
        case characterId, level
        case characterClass = "class"
        case faces, inMatch, dice, runes
    }

    func loadout(_ kind: DiceKind) -> DiceDieLoadout { kind == .attack ? dice.atk : dice.grd }
    func rune(_ key: String?) -> DiceRuneEntry? {
        guard let key else { return nil }
        return runes.first { $0.key == key }
    }
}

struct DiceSocketRequest: Encodable, Sendable {
    let characterId: String
    let die: String
    let faceIndex: Int
    /// nil = take the rune off this face. Encoded explicitly as null.
    let runeKey: String?

    enum CodingKeys: String, CodingKey { case characterId, die, faceIndex, runeKey }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(characterId, forKey: .characterId)
        try c.encode(die, forKey: .die)
        try c.encode(faceIndex, forKey: .faceIndex)
        try c.encode(runeKey, forKey: .runeKey)   // encodes JSON null when nil
    }
}

/// Talent-tree node → rune it grants (from GET /api/passives/tree `rune`).
struct PassiveNodeRune: Codable, Hashable, Sendable {
    let key: String
    let name: String
    let desc: String
    let asset: String
    let die: String
    let tier: String
}
