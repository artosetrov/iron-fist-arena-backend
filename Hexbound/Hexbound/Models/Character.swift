import Foundation

struct Character: Codable, Identifiable {
    let id: String
    var characterName: String
    var characterClass: CharacterClass
    var origin: CharacterOrigin
    var gender: CharacterGender?
    var avatar: String?
    var level: Int
    var experience: Int?
    var gold: Int
    var gems: Int?
    var currentHp: Int
    var maxHp: Int
    var currentStamina: Int
    var maxStamina: Int
    var pvpRating: Int
    var pvpWins: Int
    var pvpLosses: Int
    var pvpWinStreak: Int?
    var pvpLossStreak: Int?
    var firstWinToday: Bool?
    var freePvpToday: Int?
    var inventorySlots: Int?

    // Stats
    var strength: Int?
    var agility: Int?
    var vitality: Int?
    var endurance: Int?
    var intelligence: Int?
    var wisdom: Int?
    var luck: Int?
    var charisma: Int?
    var statPoints: Int?

    // Stance
    var combatStance: CombatStance?

    // Prestige
    var prestige: Int?

    // Armor & derived
    var armor: Int?
    var magicResist: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case characterName                          // JSON: "characterName"
        case characterClass = "class"               // JSON: "class" (Swift reserved word)
        case origin
        case gender
        case avatar
        case level
        case experience = "currentXp"               // JSON: "currentXp" (Prisma field name)
        case gold, gems
        case currentHp
        case maxHp
        case currentStamina
        case maxStamina
        case pvpRating
        case pvpWins
        case pvpLosses
        case pvpWinStreak
        case pvpLossStreak
        case firstWinToday
        case freePvpToday
        case inventorySlots
        case strength = "str"                       // JSON: "str" (Prisma 3-letter field)
        case agility = "agi"
        case vitality = "vit"
        case endurance = "end"
        case intelligence = "int"
        case wisdom = "wis"
        case luck = "luk"
        case charisma = "cha"
        case statPoints = "statPointsAvailable"     // JSON: "statPointsAvailable"
        case combatStance
        case prestige = "prestigeLevel"             // JSON: "prestigeLevel"
        case armor
        case magicResist
    }

    // Computed
    var rankName: String {
        PvPRank.fromRating(pvpRating).rawValue
    }

    var xpNeeded: Int {
        let nextLevel = level + 1
        return 100 * nextLevel + 20 * nextLevel * nextLevel
    }

    var xpPercentage: Double {
        guard let xp = experience else { return 0 }
        guard xpNeeded > 0 else { return 0 }
        return min(Double(xp) / Double(xpNeeded), 1.0)
    }

    var hpPercentage: Double {
        guard maxHp > 0 else { return 0 }
        return Double(currentHp) / Double(maxHp)
    }

    var staminaPercentage: Double {
        guard maxStamina > 0 else { return 0 }
        return Double(currentStamina) / Double(maxStamina)
    }

    var critChance: Double {
        // Matches backend: luk * 0.7 + agi * 0.15
        Double(luck ?? 0) * 0.7 + Double(agility ?? 0) * 0.15
    }

    var dodgeChance: Double {
        // Matches backend: agi * 0.2 + luk * 0.1
        Double(agility ?? 0) * 0.2 + Double(luck ?? 0) * 0.1
    }

    var attackPower: Int {
        // Matches backend combat.ts baseDamage() fallback formulas
        switch characterClass {
        case .warrior:
            return Int(Double(strength ?? 0) * 1.5 + Double(agility ?? 0) * 0.3) + level * 2
        case .tank:
            return Int(Double(strength ?? 0) * 1.3 + Double(vitality ?? 0) * 0.3) + level * 2
        case .rogue:
            return Int(Double(agility ?? 0) * 1.5 + Double(luck ?? 0) * 0.3) + level * 2
        case .mage:
            return Int(Double(intelligence ?? 0) * 1.2 + Double(wisdom ?? 0) * 0.5) + level * 2
        }
    }

    var damageTypeName: String {
        switch characterClass {
        case .mage: "Magical"
        case .rogue: "Poison"
        default: "Physical"
        }
    }

    // MARK: - Client-Side Stat Preview

    /// Preview derived stats if an item were equipped, replacing any current item in that slot.
    /// Uses same formulas as backend `equipment-stats.ts`.
    func previewStatsWithItem(_ newItem: Item, replacing currentItem: Item?) -> StatPreview {
        var totalStr = strength ?? 0
        var totalAgi = agility ?? 0
        var totalVit = vitality ?? 0
        var totalEnd = endurance ?? 0
        var totalInt = intelligence ?? 0
        var totalWis = wisdom ?? 0
        var totalLuk = luck ?? 0

        // Remove old item stats (if replacing)
        if let old = currentItem {
            let stats = old.totalStats
            totalStr -= stats["str"] ?? 0
            totalAgi -= stats["agi"] ?? 0
            totalVit -= stats["vit"] ?? 0
            totalEnd -= stats["end"] ?? 0
            totalInt -= stats["int"] ?? 0
            totalWis -= stats["wis"] ?? 0
            totalLuk -= stats["luk"] ?? 0
        }

        // Add new item stats
        let newStats = newItem.totalStats
        totalStr += newStats["str"] ?? 0
        totalAgi += newStats["agi"] ?? 0
        totalVit += newStats["vit"] ?? 0
        totalEnd += newStats["end"] ?? 0
        totalInt += newStats["int"] ?? 0
        totalWis += newStats["wis"] ?? 0
        totalLuk += newStats["luk"] ?? 0

        // Derived stats (same formulas as backend equipment-stats.ts)
        let newMaxHp = 80 + totalVit * 5 + totalEnd * 3
        let newArmor = totalEnd * 2 + Int(Double(totalStr) * 0.5)
        let newMagicResist = totalWis * 2 + Int(Double(totalInt) * 0.5)

        return StatPreview(
            maxHp: newMaxHp,
            maxHpDiff: newMaxHp - maxHp,
            armor: newArmor,
            armorDiff: newArmor - (armor ?? 0),
            magicResist: newMagicResist,
            magicResistDiff: newMagicResist - (magicResist ?? 0)
        )
    }
}

/// Client-side stat diff for equip preview
struct StatPreview {
    let maxHp: Int
    let maxHpDiff: Int
    let armor: Int
    let armorDiff: Int
    let magicResist: Int
    let magicResistDiff: Int
}

// MARK: - Combat Stance

struct CombatStance: Codable {
    var attack: String
    var defense: String

    static let `default` = CombatStance(attack: "chest", defense: "chest")
}

// MARK: - Stat Helpers

enum StatType: String, CaseIterable {
    case strength = "STR"
    case agility = "AGI"
    case vitality = "VIT"
    case endurance = "END"
    case intelligence = "INT"
    case wisdom = "WIS"
    case luck = "LUK"
    case charisma = "CHA"

    var fullName: String {
        switch self {
        case .strength: "Strength"
        case .agility: "Agility"
        case .vitality: "Vitality"
        case .endurance: "Endurance"
        case .intelligence: "Intelligence"
        case .wisdom: "Wisdom"
        case .luck: "Luck"
        case .charisma: "Charisma"
        }
    }

    var description: String {
        switch self {
        case .strength:     "Increases physical attack power"
        case .agility:      "Increases dodge chance and attack speed"
        case .vitality:     "Increases max HP"
        case .endurance:    "Increases armor and damage reduction"
        case .intelligence: "Increases magic attack power"
        case .wisdom:       "Increases magic resistance"
        case .luck:         "Increases critical hit chance and loot quality"
        case .charisma:     "Increases gold and XP rewards"
        }
    }

    var iconAsset: String {
        switch self {
        case .strength:     "icon-strength"
        case .agility:      "icon-agility"
        case .vitality:     "icon-vitality"
        case .endurance:    "icon-endurance"
        case .intelligence: "icon-intelligence"
        case .wisdom:       "icon-wisdom"
        case .luck:         "icon-luck"
        case .charisma:     "icon-charisma"
        }
    }

    var apiKey: String {
        switch self {
        case .strength:     "str"
        case .agility:      "agi"
        case .vitality:     "vit"
        case .endurance:    "end"
        case .intelligence: "int"
        case .wisdom:       "wis"
        case .luck:         "luk"
        case .charisma:     "cha"
        }
    }

    func value(from character: Character) -> Int {
        switch self {
        case .strength: character.strength ?? 0
        case .agility: character.agility ?? 0
        case .vitality: character.vitality ?? 0
        case .endurance: character.endurance ?? 0
        case .intelligence: character.intelligence ?? 0
        case .wisdom: character.wisdom ?? 0
        case .luck: character.luck ?? 0
        case .charisma: character.charisma ?? 0
        }
    }

    /// Primary stats for each class — used for recommendation badges
    static func primaryStats(for characterClass: CharacterClass) -> Set<StatType> {
        switch characterClass {
        case .warrior: [.strength, .endurance]
        case .rogue:   [.agility, .luck]
        case .mage:    [.intelligence, .wisdom]
        case .tank:    [.endurance, .vitality]
        }
    }
}

// MARK: - Stat Group

enum StatGroup: String, CaseIterable {
    case offensive = "OFFENSIVE"
    case defensive = "DEFENSIVE"
    case magicUtility = "MAGIC & UTILITY"

    var stats: [StatType] {
        switch self {
        case .offensive:    [.strength, .agility, .luck]
        case .defensive:    [.vitality, .endurance]
        case .magicUtility: [.intelligence, .wisdom, .charisma]
        }
    }
}
