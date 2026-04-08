import Foundation

struct Opponent: Codable, Identifiable {
    let id: String
    let characterName: String
    let characterClass: CharacterClass
    let origin: CharacterOrigin
    let level: Int
    let pvpRating: Int
    let pvpWins: Int
    let pvpLosses: Int
    let maxHp: Int
    let armor: Int?
    let gearScore: Int?
    let avatar: String?

    // Base stats for preview
    let strength: Int?
    let agility: Int?
    let vitality: Int?
    let intelligence: Int?
    let wisdom: Int?
    let luck: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case characterName                  // JSON: "characterName"
        case characterClass = "class"       // JSON: "class" (Swift reserved word)
        case origin, level
        case pvpRating
        case pvpWins
        case pvpLosses
        case maxHp
        case armor
        case gearScore
        case avatar
        case strength = "str"               // JSON: "str" (Prisma 3-letter field)
        case agility = "agi"
        case vitality = "vit"
        case intelligence = "int"
        case wisdom = "wis"
        case luck = "luk"
    }

    var winRate: Double {
        let total = pvpWins + pvpLosses
        guard total > 0 else { return 0 }
        return Double(pvpWins) / Double(total) * 100.0
    }

    var rank: PvPRank {
        PvPRank.fromRating(pvpRating)
    }

    /// Computed attack power — mirrors Character.attackPower formula per class
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
}
