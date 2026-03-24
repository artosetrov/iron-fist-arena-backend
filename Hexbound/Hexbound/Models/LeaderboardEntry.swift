import Foundation

struct LeaderboardEntry: Codable, Identifiable {
    var id: String { characterId }
    let characterId: String
    let characterName: String
    let characterClass: String
    let avatar: String?
    let level: Int?
    let value: Int
    var rank: Int

    enum CodingKeys: String, CodingKey {
        case characterId
        case characterName
        case characterClass = "class"  // Swift reserved word
        case avatar, level, value, rank
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

    /// Portrait asset key derived from avatar string
    var portraitAsset: String? {
        guard let avatar else { return nil }
        return "portrait-\(avatar)"
    }
}

// MARK: - Search Result

struct LeaderboardSearchResult: Codable, Identifiable {
    var id: String { characterId }
    let characterId: String
    let characterName: String
    let characterClass: String
    let avatar: String?
    let rating: Int
    let level: Int

    enum CodingKeys: String, CodingKey {
        case characterId
        case characterName
        case characterClass = "class"
        case avatar, rating, level
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

    /// Convert to LeaderboardEntry for profile sheet compatibility
    func toLeaderboardEntry() -> LeaderboardEntry {
        LeaderboardEntry(
            characterId: characterId,
            characterName: characterName,
            characterClass: characterClass,
            avatar: avatar,
            level: level,
            value: rating,
            rank: 0
        )
    }
}

struct LeaderboardSearchResponse: Codable {
    let results: [LeaderboardSearchResult]
}
