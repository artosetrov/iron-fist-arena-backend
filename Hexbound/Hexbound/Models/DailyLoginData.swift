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
    let icon: String
    let label: String
    let description: String

    static let rewards: [DailyReward] = [
        DailyReward(day: 1, icon: "🪙", label: "200 Gold", description: "A pouch of gold"),
        DailyReward(day: 2, icon: "🧪", label: "1 Potion", description: "Stamina potion"),
        DailyReward(day: 3, icon: "💎", label: "1 Gem", description: "A precious gem"),
        DailyReward(day: 4, icon: "🪙", label: "500 Gold", description: "A hefty purse"),
        DailyReward(day: 5, icon: "⚔️", label: "Weapon Crate", description: "Random weapon"),
        DailyReward(day: 6, icon: "🪙", label: "1000 Gold", description: "A chest of gold"),
        DailyReward(day: 7, icon: "👑", label: "5 Gems + Rare", description: "Gems and rare item"),
    ]
}
