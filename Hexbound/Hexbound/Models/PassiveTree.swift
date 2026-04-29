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

    // Interactive Combat v1 — Active Slot metadata. All nullable.
    // isActivatable is optional-with-default to stay forward-compatible with
    // old backends that don't return the field yet.
    let isActivatable: Bool?
    let activeActionType: TalentSlotAction?
    let activeCooldown: Int?
    let activeMagnitude: Double?

    // Talents v2 (2026-04-19): ranked nodes. Backend is source of truth — each
    // node ships a per-rank cost schedule (e.g. `[1,2,3]` for a cost=6 ranked
    // stat node, `[3]` for a keystone, `[5]` for an ultimate). Legacy payloads
    // omit these fields; clients fall back to `cost`/`[cost]`/1 accordingly.
    let rankCosts: [Int]?
    let maxRank: Int?

    /// Per-rank cost schedule with a legacy fallback — use this instead of
    /// `rankCosts` when you need a guaranteed non-nil array.
    var rankCostSchedule: [Int] { rankCosts ?? [cost] }

    /// Max rank supported by this node. Defaults to 1 if the backend omits it.
    var maxRankResolved: Int { maxRank ?? rankCostSchedule.count }

    /// True when this node has more than one rank (ranked stat nodes).
    var isRanked: Bool { maxRankResolved > 1 }

    /// Cost to advance from `currentRank` to the next rank, or nil when already
    /// at max rank or when the node is single-rank.
    func nextRankCost(currentRank: Int) -> Int? {
        guard currentRank >= 0, currentRank < maxRankResolved else { return nil }
        let schedule = rankCostSchedule
        guard currentRank < schedule.count else { return nil }
        return schedule[currentRank]
    }
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
    let isActivatable: Bool?
    let activeActionType: TalentSlotAction?
    let activeCooldown: Int?
    let activeMagnitude: Double?
    let unlockedAt: String?   // ISO8601 string — decoded as String to avoid Date strategy issues

    // Talents v2 (2026-04-19): per-character rank progress. Old backends don't
    // return these; callers coalesce to rank 1 / max rank 1 for compatibility.
    let currentRank: Int?
    let maxRank: Int?

    /// Rank the character currently has in this node. Legacy payloads collapse
    /// to 1 because pre-v2 nodes were always single-rank.
    var currentRankResolved: Int { currentRank ?? 1 }

    /// Max rank available for this node (1 for keystones/ultimates/legacy).
    var maxRankResolved: Int { maxRank ?? 1 }

    /// True when the character can still invest points into this node.
    var canRankUp: Bool { currentRankResolved < maxRankResolved }
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

    // Talents v2 (2026-04-19): the unlock endpoint also services rank-ups.
    // All three are optional so pre-v2 responses keep decoding.
    let currentRank: Int?
    let maxRank: Int?
    let spSpent: Int?
}

struct PassiveRespecResponse: Codable {
    let success: Bool
    let pointsRefunded: Int
    let passivePointsAvailable: Int
    let gemsSpent: Int
    let gemsRemaining: Int
    let stats: PassiveStatsDelta?

    // Talents v2 (2026-04-19): free-weekly respec. Both fields are optional so
    // legacy responses decode cleanly.
    let usedFreeRespec: Bool?
    /// ISO8601 string for the moment the next free respec becomes available.
    let nextFreeRespecAt: String?
}

/// POST /api/passives/active-slots/unlock-premium response.
struct PremiumSlotUnlockResponse: Codable {
    let success: Bool
    let gems: Int
    let maxSlots: Int
}

// MARK: - Active Slot (Interactive Combat v1)

/// Mirrors backend `TalentSlotAction` enum.
enum TalentSlotAction: String, Codable, Hashable, CaseIterable {
    case burstDamage    = "burst_damage"
    case healSelf       = "heal_self"
    case shieldSelf     = "shield_self"
    case stunEnemy      = "stun_enemy"
    case execute
    // Talents v2 ultimates (2026-04-29) — see SKILL_TREE_DESIGN_V2.md §8
    case stealth        = "stealth"          // Rogue Vanish — next attack auto-crits
    case aoeDamage      = "aoe_damage"       // Mage Cataclysm — alias of burst_damage in 1v1
    case cooldownReset  = "cooldown_reset"   // Mage Rewind — zeros other slot cooldowns
    case aoeStun        = "aoe_stun"         // Tank Quake — multi-round opponent stun

    /// Compact label for combat HUD.
    var shortLabel: String {
        switch self {
        case .burstDamage:   return "Burst"
        case .healSelf:      return "Heal"
        case .shieldSelf:    return "Shield"
        case .stunEnemy:     return "Stun"
        case .execute:       return "Execute"
        case .stealth:       return "Vanish"
        case .aoeDamage:     return "Cataclysm"
        case .cooldownReset: return "Rewind"
        case .aoeStun:       return "Quake"
        }
    }

    /// SF Symbol fallback for when the node has no icon asset.
    var sfSymbol: String {
        switch self {
        case .burstDamage:   return "bolt.fill"
        case .healSelf:      return "cross.case.fill"
        case .shieldSelf:    return "shield.lefthalf.filled"
        case .stunEnemy:     return "hand.raised.fill"
        case .execute:       return "scope"
        case .stealth:       return "eye.slash.fill"
        case .aoeDamage:     return "flame.fill"
        case .cooldownReset: return "clock.arrow.circlepath"
        case .aoeStun:       return "bolt.horizontal.fill"
        }
    }
}

/// Kind of content occupying an active slot. Phase 4.B introduced `consumable`
/// alongside `talent`. Old backends that don't send this field are treated as
/// `talent` to keep decoding forward-compatible.
enum ActiveSlotKind: String, Codable, Hashable {
    case talent
    case consumable
}

/// One equipped active-skill slot. Mirrors backend `SlotResponse` from
/// `/api/passives/active-slots` (Phase 4.B).
///
/// Mutual exclusion: exactly one of `nodeId` / `consumableType` is non-nil,
/// enforced by DB CHECK. Talent slots have `activeActionType/Cooldown/Magnitude`;
/// consumable slots have those all nil (1/battle, not cooldown-based).
struct ActiveSlot: Codable, Identifiable, Hashable {
    // id synthesised from slotIndex — backend doesn't echo a primary key.
    var id: Int { slotIndex }

    let slotIndex: Int
    /// Defaults to `.talent` if the backend omits the field (pre-4.B payloads).
    let kind: ActiveSlotKind
    let nodeId: String?
    let nodeKey: String?
    let consumableType: String?
    let name: String
    let description: String?
    let icon: String?
    let activeActionType: TalentSlotAction?
    let activeCooldown: Int?
    let activeMagnitude: Double?
    let equippedAt: String?   // ISO8601, decoded as String

    var isTalent: Bool { kind == .talent }
    var isConsumable: Bool { kind == .consumable }

    init(
        slotIndex: Int,
        kind: ActiveSlotKind = .talent,
        nodeId: String? = nil,
        nodeKey: String? = nil,
        consumableType: String? = nil,
        name: String,
        description: String? = nil,
        icon: String? = nil,
        activeActionType: TalentSlotAction? = nil,
        activeCooldown: Int? = nil,
        activeMagnitude: Double? = nil,
        equippedAt: String? = nil
    ) {
        self.slotIndex = slotIndex
        self.kind = kind
        self.nodeId = nodeId
        self.nodeKey = nodeKey
        self.consumableType = consumableType
        self.name = name
        self.description = description
        self.icon = icon
        self.activeActionType = activeActionType
        self.activeCooldown = activeCooldown
        self.activeMagnitude = activeMagnitude
        self.equippedAt = equippedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DecodingKey.self)
        slotIndex = try c.decode(Int.self, forKey: .slotIndex)
        kind = (try? c.decode(ActiveSlotKind.self, forKey: .kind)) ?? .talent
        nodeId = try c.decodeIfPresent(String.self, forKey: .nodeId)
        nodeKey = try c.decodeIfPresent(String.self, forKey: .nodeKey)
        consumableType = try c.decodeIfPresent(String.self, forKey: .consumableType)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        activeActionType = try c.decodeIfPresent(TalentSlotAction.self, forKey: .activeActionType)
        activeCooldown = try c.decodeIfPresent(Int.self, forKey: .activeCooldown)
        activeMagnitude = try c.decodeIfPresent(Double.self, forKey: .activeMagnitude)
        equippedAt = try c.decodeIfPresent(String.self, forKey: .equippedAt)
    }

    private enum DecodingKey: String, CodingKey {
        case slotIndex, kind, nodeId, nodeKey, consumableType
        case name, description, icon
        case activeActionType, activeCooldown, activeMagnitude, equippedAt
    }
}

/// Picker meta for a consumable — price + owned count, used by the Consumables
/// section of the Active Skill Picker. Mirrors backend `ConsumableMeta`.
struct ConsumableMeta: Codable, Hashable, Identifiable {
    var id: String { consumableType }

    let consumableType: String
    let name: String
    let description: String?
    let rarity: String
    let priceGold: Int
    let ownedCount: Int
}

/// Wrapper for GET /api/passives/active-slots response.
struct ActiveSlotsResponse: Codable {
    let slots: [ActiveSlot]
    let maxSlots: Int
    /// Picker meta for every allowed health potion. Nil for pre-4.B backends.
    let consumablesMeta: [ConsumableMeta]?
}

// MARK: - Batch save (Active Skill Picker commits 3 slots atomically)

/// One slot in a `POST /api/passives/active-slots/batch` payload. Exactly one of
/// `nodeId` / `consumableType` is set for a non-empty slot; both nil = empty.
struct ActiveSlotLoadoutEntry: Encodable, Hashable {
    let slotIndex: Int
    let nodeId: String?
    let consumableType: String?

    static func empty(slotIndex: Int) -> ActiveSlotLoadoutEntry {
        .init(slotIndex: slotIndex, nodeId: nil, consumableType: nil)
    }
    static func talent(slotIndex: Int, nodeId: String) -> ActiveSlotLoadoutEntry {
        .init(slotIndex: slotIndex, nodeId: nodeId, consumableType: nil)
    }
    static func consumable(slotIndex: Int, consumableType: String) -> ActiveSlotLoadoutEntry {
        .init(slotIndex: slotIndex, nodeId: nil, consumableType: consumableType)
    }
}
