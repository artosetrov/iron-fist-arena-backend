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

    // NOTE: This table MUST mirror backend `DAILY_LOGIN_REWARDS` in
    // `backend/src/lib/game/balance.ts`. When backend ships Economy v2 values,
    // bump both sides together. See CRIT-02 (QA_FIX_PLAN_2026-04-10).
    // TODO (W1.D3): replace with server-driven config from /api/game/init.
    static let rewards: [DailyReward] = [
        DailyReward(day: 1, icon: "coloncurrencysign.circle.fill", assetIcon: "icon-gold",    label: "150 Gold",        description: "A pouch of gold"),
        DailyReward(day: 2, icon: "flask.fill",                    assetIcon: "icon-stamina", label: "1 S. Potion",     description: "Small stamina potion"),
        DailyReward(day: 3, icon: "coloncurrencysign.circle.fill", assetIcon: "icon-gold",    label: "300 Gold",        description: "A heavier pouch"),
        DailyReward(day: 4, icon: "flask.fill",                    assetIcon: "icon-stamina", label: "2 S. Potions",    description: "Two small stamina potions"),
        DailyReward(day: 5, icon: "coloncurrencysign.circle.fill", assetIcon: "icon-gold",    label: "500 Gold",        description: "A hefty purse"),
        DailyReward(day: 6, icon: "flask.fill",                    assetIcon: "icon-stamina", label: "1 L. Potion",     description: "Large stamina potion"),
        DailyReward(day: 7, icon: "diamond.fill",                  assetIcon: "icon-gems",    label: "25 Gems",         description: "A weekly gem reward"),
    ]
}
