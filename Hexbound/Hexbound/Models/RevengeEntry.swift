import Foundation

struct RevengeEntry: Codable, Identifiable {
    let id: String
    let attackerId: String
    let attackerName: String
    let attackerClass: CharacterClass
    let attackerLevel: Int
    let attackerRating: Int
    let ratingLost: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case attackerId = "attacker_id"
        case attackerName = "attacker_name"
        case attackerClass = "attacker_class"
        case attackerLevel = "attacker_level"
        case attackerRating = "attacker_rating"
        case ratingLost = "rating_lost"
        case createdAt = "created_at"
    }

    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: createdAt) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date2 = formatter.date(from: createdAt) else { return "" }
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
