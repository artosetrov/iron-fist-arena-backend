import Foundation

struct Achievement: Codable, Identifiable {
    var id: String { key }
    let key: String
    let category: String
    let title: String
    let description: String
    let target: Int
    var progress: Int
    var completed: Bool
    var rewardClaimed: Bool
    let reward: AchievementReward?

    // No explicit CodingKeys needed — all properties match camelCase backend keys.

    var progressFraction: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1.0)
    }

    var canClaim: Bool {
        completed && !rewardClaimed
    }

    var categoryIcon: String {
        switch category {
        case "pvp": "⚔️"
        case "progression": "📈"
        case "ranking": "🏆"
        default: "⭐"
        }
    }

    var rewardText: String {
        guard let reward else { return "" }
        var parts: [String] = []
        if let gold = reward.gold, gold > 0 { parts.append("\(gold) Gold") }
        if let gems = reward.gems, gems > 0 { parts.append("\(gems) Gems") }
        if let title = reward.title { parts.append("Title: \(title)") }
        if let frame = reward.frame { parts.append("Frame: \(frame)") }
        return parts.joined(separator: ", ")
    }
}

struct AchievementReward: Codable {
    let gold: Int?
    let gems: Int?
    let title: String?
    let frame: String?
}
