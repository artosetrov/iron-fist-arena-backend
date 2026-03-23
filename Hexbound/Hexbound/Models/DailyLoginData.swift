import Foundation

struct DailyLoginData: Codable {
    let currentDay: Int
    let streak: Int
    let totalClaims: Int
    let lastClaimDate: String?
    let canClaim: Bool

    // No explicit CodingKeys needed — backend sends camelCase (Prisma),
    // and APIClient.decoder uses .convertFromSnakeCase which passes camelCase through unchanged.
}

// MARK: - Daily Rewards Definition

struct DailyReward {
    let day: Int
    let icon: String      // kept for backward compat — prefer assetIcon
    let assetIcon: String? // asset name from xcassets (nil = fallback to icon emoji)
    let label: String
    let description: String

    static let rewards: [DailyReward] = [
        DailyReward(day: 1, icon: "🪙", assetIcon: "icon-gold",       label: "200 Gold",       description: "A pouch of gold"),
        DailyReward(day: 2, icon: "🧪", assetIcon: "icon-stamina",    label: "1 Potion",       description: "Stamina potion"),
        DailyReward(day: 3, icon: "💎", assetIcon: "icon-gems",       label: "1 Gem",          description: "A precious gem"),
        DailyReward(day: 4, icon: "🪙", assetIcon: "icon-gold",       label: "500 Gold",       description: "A hefty purse"),
        DailyReward(day: 5, icon: "⚔️", assetIcon: "icon-weapon-offhand", label: "Weapon Crate", description: "Random weapon"),
        DailyReward(day: 6, icon: "🪙", assetIcon: "icon-gold",       label: "1000 Gold",      description: "A chest of gold"),
        DailyReward(day: 7, icon: "👑", assetIcon: "icon-leaderboard", label: "5 Gems + Rare",  description: "Gems and rare item"),
    ]
}
