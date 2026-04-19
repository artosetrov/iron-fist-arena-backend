import Foundation

struct BattlePassData: Codable {
    let seasonName: String
    let currentLevel: Int
    let currentXp: Int
    let xpToNext: Int
    var hasPremium: Bool
    var freeRewards: [BPReward]
    var premiumRewards: [BPReward]

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

    // Track is injected after decoding — excluded from CodingKeys so synthesized
    // init(from:) doesn't attempt to decode it (backend doesn't send it).
    var track: String = "free"

    enum CodingKeys: String, CodingKey {
        case level
        case rewardType
        case rewardName
        case amount
        case claimed
    }

    var icon: String {
        switch rewardType {
        case "gold": "coloncurrencysign.circle.fill"
        case "gems": "diamond.fill"
        case "item": "shippingbox.fill"
        case "xp": "star.fill"
        case "chest": "gift.fill"
        case "skin": "paintpalette.fill"
        case "stamina": "bolt.fill"
        default: "trophy.fill"
        }
    }

    /// Mapped rarity for visual consistency with ItemCardView
    var rewardRarity: ItemRarity {
        switch rewardType {
        case "chest": .legendary
        case "skin": .epic
        case "gems": .rare
        case "item": .uncommon
        default: .common
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

struct BattlePassClaimResponse: Codable {
    let level: Int
    let rewards: [BattlePassClaimReward]
    let gold: Int?
    let gems: Int?
    let xp: Int?
    let leveledUp: Bool
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
}

struct BattlePassClaimReward: Codable, Equatable {
    let rewardType: String
    let rewardName: String
    let rewardId: String?
    let rewardAmount: Int
    let isPremium: Bool
}
