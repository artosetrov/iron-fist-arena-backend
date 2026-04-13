//
//  PassiveTree.swift
//  Hexbound
//
//  Codable models for the passive skill tree (Talents tab).
//  Mirrors backend shapes from /api/passives/tree, /character, /unlock, /respec.
//

import Foundation

// MARK: - Tree definition (from GET /api/passives/tree)

/// A single node in the passive tree catalog (camelCase from backend).
struct PassiveNode: Codable, Identifiable, Hashable {
    let id: String
    let nodeKey: String
    let name: String
    let description: String
    let bonusType: String        // e.g. "stat", "keystone", "ultimate"
    let bonusStat: String?       // e.g. "strength", "maxHp", "armor"
    let bonusValue: Double?
    let tier: Int
    let positionX: Double
    let positionY: Double
    let cost: Int
    let icon: String?
    let classRestriction: String?
    let isStartNode: Bool
}

/// Directed edge between two PassiveNode ids.
struct PassiveConnection: Codable, Identifiable, Hashable {
    let id: String
    let fromId: String
    let toId: String
}

/// Wrapper for GET /api/passives/tree response.
struct PassiveTreeResponse: Codable {
    let nodes: [PassiveNode]
    let connections: [PassiveConnection]
}

// MARK: - Character-specific unlocks (from GET /api/passives/character — snake_case)

/// A node unlocked by the current character (fields are snake_case in JSON).
struct CharacterPassiveUnlocked: Codable, Identifiable, Hashable {
    let id: String
    let nodeId: String
    let nodeKey: String
    let name: String
    let description: String
    let bonusType: String
    let bonusStat: String?
    let bonusValue: Double?
    let tier: Int
    let cost: Int
    let icon: String?
    let unlockedAt: String?   // ISO8601 string — decoded as String to avoid Date strategy issues

    enum CodingKeys: String, CodingKey {
        case id
        case nodeId = "node_id"
        case nodeKey = "node_key"
        case name
        case description
        case bonusType = "bonus_type"
        case bonusStat = "bonus_stat"
        case bonusValue = "bonus_value"
        case tier
        case cost
        case icon
        case unlockedAt = "unlocked_at"
    }
}

struct CharacterPassiveResponse: Codable {
    let passivePointsAvailable: Int
    let unlockedNodes: [CharacterPassiveUnlocked]

    enum CodingKeys: String, CodingKey {
        case passivePointsAvailable = "passive_points_available"
        case unlockedNodes = "unlocked_nodes"
    }
}

// MARK: - Mutations

struct PassiveStatsDelta: Codable, Hashable {
    let maxHp: Int?
    let armor: Int?
    let magicResist: Int?

    enum CodingKeys: String, CodingKey {
        case maxHp = "max_hp"
        case armor
        case magicResist = "magic_resist"
    }
}

struct PassiveUnlockResponse: Codable {
    let success: Bool
    let passivePointsAvailable: Int
    let stats: PassiveStatsDelta?

    enum CodingKeys: String, CodingKey {
        case success
        case passivePointsAvailable = "passive_points_available"
        case stats
    }
}

struct PassiveRespecResponse: Codable {
    let success: Bool
    let pointsRefunded: Int
    let passivePointsAvailable: Int
    let gemsSpent: Int
    let gemsRemaining: Int
    let stats: PassiveStatsDelta?

    enum CodingKeys: String, CodingKey {
        case success
        case pointsRefunded = "points_refunded"
        case passivePointsAvailable = "passive_points_available"
        case gemsSpent = "gems_spent"
        case gemsRemaining = "gems_remaining"
        case stats
    }
}
