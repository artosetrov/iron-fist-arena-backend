import Foundation

// Nested opponent object returned by /api/pvp/history
struct MatchOpponent: Codable {
    let id: String
    let name: String
    let characterClass: CharacterClass
    let level: Int

    enum CodingKeys: String, CodingKey {
        case id, name, level
        case characterClass = "class"
    }
}

struct MatchHistory: Codable, Identifiable {
    let id: String              // JSON: "matchId"
    let opponent: MatchOpponent
    let won: Bool               // JSON: "won"
    let ratingChange: Int
    let goldReward: Int?
    let xpReward: Int?
    let turnsTaken: Int?
    let matchType: String?
    let isRevenge: Bool?
    let playedAt: String        // JSON: "playedAt"

    enum CodingKeys: String, CodingKey {
        case id = "matchId"
        case opponent
        case won
        case ratingChange
        case goldReward
        case xpReward
        case turnsTaken
        case matchType
        case isRevenge
        case playedAt
    }

    // Backward compatibility computed properties
    var opponentName: String { opponent.name }
    var opponentClass: CharacterClass { opponent.characterClass }
    var opponentLevel: Int { opponent.level }
    var isWin: Bool { won }
    var createdAt: String { playedAt }

    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: playedAt) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date2 = formatter.date(from: playedAt) else { return "" }
            return Self.relativeTime(from: date2)
        }
        return Self.relativeTime(from: date)
    }

    private static func relativeTime(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }
}
