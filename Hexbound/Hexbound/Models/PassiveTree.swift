//
//  PassiveTree.swift
//  Hexbound
//
//  Codable models for the passive skill tree (Talents tab).
//  Mirrors backend shapes from /api/passives/tree, /character, /unlock, /respec.
//
//  NOTE: APIClient.shared uses `.convertFromSnakeCase`, so we intentionally
//  DO NOT define custom CodingKeys with snake_case strings here — the decoder
//  transforms incoming keys to camelCase before lookup. Custom snake_case
//  CodingKeys would shadow that and break decoding.
//

import Foundation

// MARK: - Tree definition (from GET /api/passives/tree)

/// A single node in the passive tree catalog.
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

// MARK: - Character-specific unlocks (from GET /api/passives/character)

/// A node unlocked by the current character.
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
}

struct CharacterPassiveResponse: Codable {
    let passivePointsAvailable: Int
    let unlockedNodes: [CharacterPassiveUnlocked]
}

// MARK: - Mutations

struct PassiveStatsDelta: Codable, Hashable {
    let maxHp: Int?
    let armor: Int?
    let magicResist: Int?
}

struct PassiveUnlockResponse: Codable {
    let success: Bool
    let passivePointsAvailable: Int
    let stats: PassiveStatsDelta?
}

struct PassiveRespecResponse: Codable {
    let success: Bool
    let pointsRefunded: Int
    let passivePointsAvailable: Int
    let gemsSpent: Int
    let gemsRemaining: Int
    let stats: PassiveStatsDelta?
}
