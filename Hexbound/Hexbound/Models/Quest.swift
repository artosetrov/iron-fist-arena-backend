import Foundation

struct Quest: Codable, Identifiable {
    let id: String
    let type: String
    let title: String
    let description: String
    let icon: String
    let target: Int
    var progress: Int
    var completed: Bool
    var rewardClaimed: Bool
    let rewardGold: Int
    let rewardXp: Int
    let rewardGems: Int?

    enum CodingKeys: String, CodingKey {
        case id, type, title, description, icon, target, progress, completed
        case rewardClaimed = "reward_claimed"
        case rewardGold = "reward_gold"
        case rewardXp = "reward_xp"
        case rewardGems = "reward_gems"
    }

    var progressFraction: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1.0)
    }

    var canClaim: Bool {
        completed && !rewardClaimed
    }
}
