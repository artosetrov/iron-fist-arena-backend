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

struct DailyLoginClaimReward: Codable {
    let type: String
    let amount: Int
    let itemId: String?
    let displayName: String?
    let displayIcon: String?

    var rewardDef: DailyLoginRewardDef {
        DailyLoginRewardDef(
            type: type,
            amount: amount,
            itemId: itemId,
            displayName: displayName,
            displayIcon: displayIcon
        )
    }
}

struct DailyLoginClaimResponse: Codable {
    let reward: DailyLoginClaimReward
    let currentDay: Int
    let streak: Int
    let totalClaims: Int
    let lastClaimDate: String?
    let canClaim: Bool
    let gold: Int
    let gems: Int
    let premiumGemsAwarded: Int

    var status: DailyLoginData {
        DailyLoginData(
            currentDay: currentDay,
            streak: streak,
            totalClaims: totalClaims,
            lastClaimDate: lastClaimDate,
            canClaim: canClaim
        )
    }
}

// MARK: - Daily Rewards Definition
//
// W1.D3 SSoT refactor (2026-04-10): the 7-day reward table is no longer
// hardcoded in the client. It comes from `/api/game/init` →
// `config.dailyLoginRewards`, is parsed by `GameConfig.parseDailyRewards`,
// and read through `DailyReward.rewards(from:)` below. When the cache is
// empty (cold start / offline), `GameConfig.fallbackDailyRewards` is used.
//
// See CRIT-02 and `docs/07_ui_ux/W1_D3_GAMECONFIG_SSOT_REVIEW.md`.

struct DailyReward {
    let day: Int
    /// Kept for backward compat with older SF Symbol callers. Now unused —
    /// every call site reads `assetIcon` + AssetManager.
    let icon: String
    /// Asset name from xcassets. Always non-nil for server-driven rewards.
    let assetIcon: String?
    let label: String
    let description: String
}

extension DailyReward {
    /// Build the 7-day display table from the live game config cache.
    ///
    /// - Parameter cache: the shared `GameDataCache` (via `@Environment`).
    /// - Returns: 7 `DailyReward` values, day 1 → day 7.
    ///
    /// Resolution order:
    /// 1. `cache.gameConfig?.dailyLoginRewards` — server-authored, fresh from
    ///    `/api/game/init`. This is the normal case.
    /// 2. `GameConfig.fallbackDailyRewards` — bundled mirror of `balance.ts`,
    ///    used only on cold start before the first successful init, or when
    ///    the server payload is missing/malformed.
    ///
    /// This helper is intentionally cheap (pure map, no caching) because the
    /// screens that call it are rendered a handful of times per session.
    ///
    /// Marked `@MainActor` because `GameDataCache` is main-actor-isolated —
    /// its `gameConfig` property can't be touched from a nonisolated context.
    @MainActor
    static func rewards(from cache: GameDataCache) -> [DailyReward] {
        let source = cache.gameConfig?.dailyLoginRewards
            ?? GameConfig.fallbackDailyRewards
        return source.enumerated().map { index, def in
            DailyReward(
                day: index + 1,
                icon: "",                       // legacy — use assetIcon
                assetIcon: def.assetName,
                label: def.resolvedLabel,
                description: def.resolvedLabel  // single-line descriptor for now
            )
        }
    }
}
