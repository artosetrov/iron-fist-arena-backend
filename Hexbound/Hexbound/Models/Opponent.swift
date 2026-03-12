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
    let avatar: String?

    // Optional stats for preview
    let strength: Int?
    let agility: Int?
    let vitality: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case characterName                  // JSON: "characterName"
        case characterClass = "class"       // JSON: "class" (Swift reserved word)
        case origin, level
        case pvpRating
        case pvpWins
        case pvpLosses
        case maxHp
        case avatar
        case strength = "str"               // JSON: "str" (Prisma 3-letter field)
        case agility = "agi"
        case vitality = "vit"
    }

    var winRate: Double {
        let total = pvpWins + pvpLosses
        guard total > 0 else { return 0 }
        return Double(pvpWins) / Double(total) * 100.0
    }

    var rank: PvPRank {
        PvPRank.fromRating(pvpRating)
    }
}
