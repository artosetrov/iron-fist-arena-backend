import Foundation

struct BattlePassData: Codable {
    let seasonName: String
    let currentLevel: Int
    let currentXp: Int
    let xpToNext: Int
    let hasPremium: Bool
    let freeRewards: [BPReward]
    let premiumRewards: [BPReward]

    enum CodingKeys: String, CodingKey {
        case seasonName = "season_name"
        case currentLevel = "current_level"
        case currentXp = "current_xp"
        case xpToNext = "xp_to_next"
        case hasPremium = "has_premium"
        case freeRewards = "free_rewards"
        case premiumRewards = "premium_rewards"
    }

    var xpProgress: Double {
        guard xpToNext > 0 else { return 0 }
        return min(Double(currentXp) / Double(xpToNext), 1.0)
    }
}

struct BPReward: Codable, Identifiable {
    var id: String { "\(level)-\(rewardType)-\(track)" }

    let level: Int
    let rewardType: String
    let rewardName: String
    let amount: Int
    var claimed: Bool

    // Track is injected after decoding
    var track: String = "free"

    enum CodingKeys: String, CodingKey {
        case level
        case rewardType = "reward_type"
        case rewardName = "reward_name"
        case amount, claimed
    }

    var icon: String {
        switch rewardType {
        case "gold": "🪙"
        case "gems": "💎"
        case "item": "📦"
        case "xp": "⭐"
        case "chest": "🎁"
        case "skin": "🎨"
        case "stamina": "⚡"
        default: "🏆"
        }
    }

    /// Asset name from xcassets — preferred over emoji icon
    var assetIcon: String? {
        switch rewardType {
        case "gold": "icon-gold"
        case "gems": "icon-gems"
        case "item": "icon-chest"
        case "xp": "icon-xp"
        case "chest": "icon-chest"
        case "skin": "icon-rogue"
        case "stamina": "icon-stamina"
        default: nil
        }
    }
}
