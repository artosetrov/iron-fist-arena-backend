import SwiftUI

@MainActor @Observable
final class DailyLoginPopupViewModel {
    let appState: AppState
    /// Live game config source — used to resolve the 7-day reward table.
    /// Held as a reference (not owned) so the VM stays in lockstep with the
    /// shared `GameDataCache` without duplicating state.
    private let cache: GameDataCache
    private let service: DailyLoginService

    var loginData: DailyLoginData?
    var isLoading = true
    var isClaiming = false
    var hasClaimed = false

    // Claim reward modal
    var claimRewardConfig: ClaimRewardConfig?

    // Animation states
    var claimedDayBounce: Int? = nil
    var showClaimParticles = false

    // BUG-23 (QA 2026-04-10): backend stores `currentDay` as
    // "next day to claim" and advances it post-claim (newDay → (newDay % 7) + 1).
    // Client UI treats the displayed day as "the reward being claimed/just claimed",
    // which drifts 1 day ahead after a successful claim.
    //
    // `justClaimedDay` snapshots the day the player is actually seeing so that
    // the confirmation modal / progress bar / day strip keep pointing at the
    // correct cell even after the server advances `currentDay`.
    var justClaimedDay: Int? = nil

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = DailyLoginService(appState: appState)
    }

    /// Set once the player claims in this popup, so a status refresh that
    /// was already in flight can't flip the screen back to "claimable".
    private var didClaimHere = false

    /// Latency pass (2026-10-15): open from `appState.cachedDailyLogin`
    /// (filled by /game/init) instead of a spinner, then revalidate.
    func loadData() async {
        if loginData == nil, let cached = appState.cachedDailyLogin {
            applyStatus(cached)
            isLoading = false
        } else if loginData == nil {
            isLoading = true
        }
        let data = await service.getStatus()
        if let data, !didClaimHere, !isClaiming {
            applyStatus(data)
        }
        isLoading = false
    }

    private func applyStatus(_ data: DailyLoginData) {
        loginData = data
        let canClaim = data.canClaim
        hasClaimed = !canClaim
        // BUG-23: if we load into an already-claimed state (e.g. modal reopened
        // mid-cooldown), the backend's `currentDay` is *tomorrow's* slot. Roll
        // it back one position in the 7-day cycle so the confirmation UI shows
        // the reward the player actually received, not tomorrow's preview.
        if !canClaim {
            justClaimedDay = data.currentDay == 1 ? 7 : data.currentDay - 1
        } else {
            justClaimedDay = nil
        }
        // Sync hub badge state with fresh server data
        appState.dailyLoginCanClaim = canClaim
    }

    /// Latency pass (2026-10-15): the CLAIMED modal used to wait for the
    /// server even though the claimed state flipped instantly. The day's
    /// reward is in the live config table, so the modal and the gold/gems
    /// credit now land on the tap too. On success the server's absolute
    /// totals reconcile (done in DailyLoginService); if the server granted a
    /// different reward (streak reset → day 1, config drift) the modal is
    /// replaced with the real one, and a Premium bonus is announced on top.
    /// On failure everything rolls back; DailyLoginService toasts once.
    func claimReward() async {
        guard let data = loginData, data.canClaim, !isClaiming else { return }
        let currentDay = Self.expectedClaimDay(data)
        isClaiming = true
        didClaimHere = true

        // BUG-23: freeze the "day shown" before we flip hasClaimed — this
        // snapshot survives the server pushing `loginData.currentDay` forward.
        justClaimedDay = currentDay

        // Optimistic UI: show claimed state INSTANTLY
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            claimedDayBounce = currentDay
            showClaimParticles = true
            hasClaimed = true
        }
        appState.dailyLoginCanClaim = false
        // Invalidate cached daily login so Hub doesn't re-read stale canClaim=true
        appState.cachedDailyLogin = nil

        // Optimistic reward + modal from the live 7-day table.
        let defs = cache.gameConfig?.dailyLoginRewards ?? GameConfig.fallbackDailyRewards
        let expectedDef: DailyLoginRewardDef? = defs.indices.contains(currentDay - 1) ? defs[currentDay - 1] : nil
        let credit: AppState.RewardCredit = expectedDef.map {
            appState.creditRewardOptimistically(
                gold: $0.type == "gold" ? $0.amount : 0,
                gems: $0.type == "gems" ? $0.amount : 0,
                xp: 0
            )
        } ?? .none
        let optimisticConfig: ClaimRewardConfig? = expectedDef.map {
            buildClaimRewardConfig(def: $0, premiumGems: 0, claimedDay: currentDay)
        }
        if let optimisticConfig {
            claimRewardConfig = optimisticConfig
        }

        // Fire API in background — don't block UI
        Task { [weak self] in
            guard let self else { return }
            let claimResponse = await service.claimReward()
            isClaiming = false
            if let claimResponse {
                loginData = claimResponse.status
                let grantedDef = claimResponse.reward.rewardDef
                // Mechanics only — display strings may legitimately differ
                // between the config table and the claim response.
                let sameReward = expectedDef.map {
                    $0.type == grantedDef.type && $0.amount == grantedDef.amount && $0.itemId == grantedDef.itemId
                } ?? false
                if !sameReward {
                    // Server claimed a different day (streak reset) — show
                    // what was actually granted.
                    let grantedDay = claimResponse.currentDay == 1 ? 7 : claimResponse.currentDay - 1
                    justClaimedDay = grantedDay
                    claimRewardConfig = buildClaimRewardConfig(
                        def: grantedDef,
                        premiumGems: claimResponse.premiumGemsAwarded,
                        claimedDay: grantedDay
                    )
                } else if claimResponse.premiumGemsAwarded > 0 {
                    appState.showToast(
                        "+\(claimResponse.premiumGemsAwarded) gems",
                        subtitle: "Premium daily bonus",
                        type: .reward
                    )
                }
            } else {
                // Revert on failure (the service already showed the toast)
                appState.revertRewardCredit(credit)
                if let optimisticConfig, claimRewardConfig == optimisticConfig {
                    claimRewardConfig = nil
                }
                hasClaimed = false
                justClaimedDay = nil
                didClaimHere = false
                appState.dailyLoginCanClaim = true
            }

            // Reset particles after animation
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation {
                self.showClaimParticles = false
            }
        }
    }

    /// Day the server will grant. Mirrors backend `shouldResetStreak`
    /// (lib/game/daily-login.ts): no previous claim, or ≥ 48 h since it,
    /// resets the cycle to day 1; otherwise `currentDay`.
    static func expectedClaimDay(_ data: DailyLoginData, now: Date = Date()) -> Int {
        guard let raw = data.lastClaimDate else { return 1 }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        guard let last = withFraction.date(from: raw) ?? plain.date(from: raw) else {
            return data.currentDay
        }
        return now.timeIntervalSince(last) >= 48 * 60 * 60 ? 1 : data.currentDay
    }

    // MARK: - BUG-23 display helpers
    //
    // Single bridge between backend semantics ("currentDay = next to claim")
    // and UI semantics ("currentDay = the cell being shown"). All views should
    // reach for `displayDay` / `tomorrowDay` / `claimedCount` instead of
    // touching `loginData.currentDay` directly.

    /// The day the player is looking at in the modal — the reward currently
    /// being claimed (pre-claim) or just claimed (post-claim).
    var displayDay: Int {
        if let claimed = justClaimedDay { return claimed }
        return loginData?.currentDay ?? 1
    }

    /// Next day in the 7-day cycle (wraps from 7 → 1).
    var tomorrowDay: Int {
        (displayDay % 7) + 1
    }

    /// Number of completed (claimed) days in the current 7-day cycle.
    /// Drives the weekly progress bar fill.
    var claimedCount: Int {
        hasClaimed ? displayDay : max(0, displayDay - 1)
    }

    var nextDayReward: DailyReward? {
        DailyReward.rewards(from: cache).first(where: { $0.day == tomorrowDay })
    }

    func dismiss() {
        appState.dismissDailyLoginPopup()
    }

    private func buildClaimRewardConfig(
        def reward: DailyLoginRewardDef,
        premiumGems: Int,
        claimedDay: Int
    ) -> ClaimRewardConfig {
        var goldReward = 0
        var gemsReward = premiumGems
        var lootItems: [ClaimLootItem] = []

        switch reward.type {
        case "gold":
            goldReward = reward.amount
        case "gems":
            gemsReward += reward.amount
        case "consumable":
            lootItems = [
                ClaimLootItem(
                    id: reward.itemId ?? "daily-login-consumable-\(claimedDay)",
                    name: reward.resolvedLabel,
                    quantity: reward.amount,
                    imageKey: reward.assetName,
                    fallbackIcon: "cross.vial",
                    rarity: .uncommon,
                    rarityColor: DarkFantasyTheme.rarityUncommon
                )
            ]
        default:
            break
        }

        return ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: "Day \(claimedDay)",
            goldReward: goldReward,
            gemsReward: gemsReward,
            xpReward: 0,
            lootItems: lootItems,
            family: .tribute,
            tier: Self.cardTier(forDay: claimedDay)
        )
    }

    /// The week's streak climbs the metals: days 1–2 iron, 3–4 bronze, 5–6 silver, day 7 gold.
    private static func cardTier(forDay day: Int) -> RewardCardTier {
        switch day {
        case ..<3: .iron
        case 3..<5: .bronze
        case 5..<7: .silver
        default: .gold
        }
    }
}
