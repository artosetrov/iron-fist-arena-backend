import Foundation

struct LeaderboardEntry: Codable, Identifiable {
    var id: String { characterId }
    let characterId: String
    let characterName: String
    let characterClass: String
    let value: Int
    var rank: Int

    enum CodingKeys: String, CodingKey {
        case characterId
        case characterName
        case characterClass = "class"  // Swift reserved word
        case value, rank
    }

    var classIcon: String {
        switch characterClass {
        case "warrior": "⚔"
        case "rogue": "🗡️"
        case "mage": "🔮"
        case "tank": "🛡️"
        default: "👤"
        }
    }
}
