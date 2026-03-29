import Foundation

struct CombatData: Codable {
    let player: CombatFighter
    let enemy: CombatFighter
    let combatLog: [CombatLog]
    let result: CombatResultInfo
    let rewards: CombatRewards?
    let loot: [CombatLootItem]?
    let source: String?
    let matchId: String?
    let stamina: StaminaInfo?
    let postCombatHp: PostCombatHp?

    // Memberwise init
    init(player: CombatFighter, enemy: CombatFighter, combatLog: [CombatLog], result: CombatResultInfo, rewards: CombatRewards? = nil, loot: [CombatLootItem]? = nil, source: String? = nil, matchId: String? = nil, stamina: StaminaInfo? = nil, postCombatHp: PostCombatHp? = nil) {
        self.player = player
        self.enemy = enemy
        self.combatLog = combatLog
        self.result = result
        self.rewards = rewards
        self.loot = loot
        self.source = source
        self.matchId = matchId
        self.stamina = stamina
        self.postCombatHp = postCombatHp
    }

    // No custom CodingKeys — APIClient's .convertFromSnakeCase handles
    // snake_case JSON keys automatically (combat_log → combatLog, etc.)
}

struct CombatFighter: Codable, Identifiable {
    let id: String
    let characterName: String
    let characterClass: CharacterClass
    let origin: CharacterOrigin
    let level: Int
    let maxHp: Int
    let currentHp: Int?
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case characterName = "character_name"
        case characterClass = "class"
        case origin, level
        case maxHp = "max_hp"
        case currentHp = "current_hp"
        case avatar
    }
}

struct CombatLog: Codable {
    let attackerId: String
    let action: String?
    let targetZone: String?
    let defendZone: String?
    let damage: Int
    let isCrit: Bool
    let isMiss: Bool
    let isDodge: Bool
    let isBlocked: Bool
    let statusApplied: String?
    let heal: Int?
    let damageType: String?
    let skillUsed: String?

    // No custom CodingKeys — .convertFromSnakeCase handles it:
    // attacker_id → attackerId, target_zone → targetZone, etc.

    init(attackerId: String, action: String?, targetZone: String?, defendZone: String?, damage: Int, isCrit: Bool, isMiss: Bool, isDodge: Bool, isBlocked: Bool, statusApplied: String?, heal: Int?, damageType: String?, skillUsed: String?) {
        self.attackerId = attackerId
        self.action = action
        self.targetZone = targetZone
        self.defendZone = defendZone
        self.damage = damage
        self.isCrit = isCrit
        self.isMiss = isMiss
        self.isDodge = isDodge
        self.isBlocked = isBlocked
        self.statusApplied = statusApplied
        self.heal = heal
        self.damageType = damageType
        self.skillUsed = skillUsed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        attackerId = try container.decode(String.self, forKey: .attackerId)
        action = try container.decodeIfPresent(String.self, forKey: .action)
        targetZone = try container.decodeIfPresent(String.self, forKey: .targetZone)
        defendZone = try container.decodeIfPresent(String.self, forKey: .defendZone)
        damage = try container.decodeIfPresent(Int.self, forKey: .damage) ?? 0
        isCrit = try container.decodeIfPresent(Bool.self, forKey: .isCrit) ?? false
        isMiss = try container.decodeIfPresent(Bool.self, forKey: .isMiss) ?? false
        isDodge = try container.decodeIfPresent(Bool.self, forKey: .isDodge) ?? false
        isBlocked = try container.decodeIfPresent(Bool.self, forKey: .isBlocked) ?? false
        statusApplied = try container.decodeIfPresent(String.self, forKey: .statusApplied)
        heal = try container.decodeIfPresent(Int.self, forKey: .heal)
        damageType = try container.decodeIfPresent(String.self, forKey: .damageType)
        skillUsed = try container.decodeIfPresent(String.self, forKey: .skillUsed)
    }

    // CodingKeys use camelCase to work with .convertFromSnakeCase decoder
    enum CodingKeys: String, CodingKey {
        case attackerId, action, targetZone, defendZone, damage
        case isCrit, isMiss, isDodge, isBlocked
        case statusApplied, heal, damageType, skillUsed
    }
}

struct CombatResultInfo: Codable {
    let isWin: Bool
    let winnerId: String?
    let goldReward: Int?
    let xpReward: Int?
    let turnsTaken: Int?
    let ratingChange: Int?
    let firstWinBonus: Bool?
    let leveledUp: Bool?
    let newLevel: Int?
    let statPointsAwarded: Int?

    // No custom CodingKeys — .convertFromSnakeCase handles it:
    // is_win → isWin, winner_id → winnerId, etc.
}

struct CombatRewards: Codable {
    let gold: Int?
    let xp: Int?
}

/// Loot item from combat rewards
struct CombatLootItem: Codable, Identifiable {
    let id: String?
    let itemName: String?
    let name: String?          // backend sends both `name` and `item_name`
    let itemType: String?
    let rarity: String?
    let itemLevel: Int?
    let upgradeLevel: Int?
    let baseStats: [String: Int]?
    let imageKey: String?
    let imageUrl: String?

    /// Stable identifier for SwiftUI — generated once, not on every access
    private let _stableId: String = UUID().uuidString
    var identifier: String { id ?? _stableId }

    /// Resolved display name — prefers itemName, falls back to name
    var displayName: String { itemName ?? name ?? "Unknown Item" }

    private enum CodingKeys: String, CodingKey {
        case id, itemName, name, itemType, rarity, itemLevel, upgradeLevel, baseStats, imageKey, imageUrl
    }
}

/// Stamina info returned from combat endpoints
struct StaminaInfo: Codable {
    let current: Int
    let max: Int
}

/// Post-combat HP for both fighters
struct PostCombatHp: Codable {
    let player: Int?
    let enemy: Int?
}
