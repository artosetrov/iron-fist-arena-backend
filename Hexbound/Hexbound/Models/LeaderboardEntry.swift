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
    // W3.D5 — BAL-05 ladder: tier info resolved server-side from pvpRating + rank
    // so iOS only needs to render, never classify. All three are optional for
    // forward-compat with older responses / gold leaderboard entries without
    // an attached character.
    let tierKey: String?
    let division: String?
    let tierLabel: String?

    enum CodingKeys: String, CodingKey {
        case characterId
        case characterName
        case characterClass = "class"  // Swift reserved word
        case avatar, level, value, rank
        case tierKey, division, tierLabel
    }

    var classIcon: String {
        switch characterClass {
        case "warrior": "bolt.sword"
        case "rogue": "arrow.trianglehead.up.and.arrow.trianglehead.down"
        case "mage": "wand.and.stars"
        case "tank": "shield.fill"
        default: "person.fill"
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
        case "warrior": "bolt.sword"
        case "rogue": "arrow.trianglehead.up.and.arrow.trianglehead.down"
        case "mage": "wand.and.stars"
        case "tank": "shield.fill"
        default: "person.fill"
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
            rank: 0,
            tierKey: nil,
            division: nil,
            tierLabel: nil
        )
    }
}

struct LeaderboardSearchResponse: Codable {
    let results: [LeaderboardSearchResult]
}
