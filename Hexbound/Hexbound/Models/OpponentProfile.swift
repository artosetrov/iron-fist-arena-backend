import Foundation

/// Full public profile of another player, fetched from GET /characters/:id/profile.
/// Used in leaderboard detail sheet and social features.
struct OpponentProfile: Codable, Identifiable {
    let id: String
    let characterName: String
    let characterClass: CharacterClass
    let origin: CharacterOrigin
    let gender: CharacterGender?
    let avatar: String?
    let level: Int
    let prestigeLevel: Int?

    // HP
    let currentHp: Int
    let maxHp: Int

    // PvP
    let pvpRating: Int
    let pvpWins: Int
    let pvpLosses: Int
    let pvpWinStreak: Int?

    // Base stats
    let strength: Int?
    let agility: Int?
    let vitality: Int?
    let endurance: Int?
    let intelligence: Int?
    let wisdom: Int?
    let luck: Int?
    let charisma: Int?

    // Derived
    let armor: Int?
    let magicResist: Int?

    // Stance
    let combatStance: CombatStance?

    // Equipped items
    let equipment: [Item]?

    enum CodingKeys: String, CodingKey {
        case id
        case characterName
        case characterClass = "class"
        case origin
        case gender
        case avatar
        case level
        case prestigeLevel
        case currentHp
        case maxHp
        case pvpRating
        case pvpWins
        case pvpLosses
        case pvpWinStreak
        case strength = "str"
        case agility = "agi"
        case vitality = "vit"
        case endurance = "end"
        case intelligence = "int"
        case wisdom = "wis"
        case luck = "luk"
        case charisma = "cha"
        case armor
        case magicResist
        case combatStance
        case equipment
    }

    // MARK: - Computed Properties

    var hpPercentage: Double {
        guard maxHp > 0 else { return 0 }
        return Double(currentHp) / Double(maxHp)
    }

    var rankName: String {
        PvPRank.fromRating(pvpRating).rawValue
    }

    var pvpRank: PvPRank {
        PvPRank.fromRating(pvpRating)
    }

    var winRate: Double {
        let total = pvpWins + pvpLosses
        guard total > 0 else { return 0 }
        return Double(pvpWins) / Double(total)
    }

    var critChance: Double {
        Double(luck ?? 0) * 0.7 + Double(agility ?? 0) * 0.15
    }

    var dodgeChance: Double {
        Double(agility ?? 0) * 0.2 + Double(luck ?? 0) * 0.1
    }

    var attackPower: Int {
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

    /// Equipped item for a specific slot
    func equippedItem(for slot: String) -> Item? {
        equipment?.first { $0.equippedSlot == slot }
    }

    /// Get stat value by StatType (for grouped stat display)
    func statValue(for stat: StatType) -> Int {
        switch stat {
        case .strength:     return strength ?? 0
        case .agility:      return agility ?? 0
        case .vitality:     return vitality ?? 0
        case .endurance:    return endurance ?? 0
        case .intelligence: return intelligence ?? 0
        case .wisdom:       return wisdom ?? 0
        case .luck:         return luck ?? 0
        case .charisma:     return charisma ?? 0
        }
    }
}

/// Response wrapper for the profile endpoint
struct OpponentProfileResponse: Codable {
    let profile: OpponentProfile
}
