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

    func loadData() async {
        isLoading = true
        let data = await service.getStatus()
        loginData = data
        isLoading = false
        let canClaim = data?.canClaim ?? false
        hasClaimed = !canClaim
        // BUG-23: if we load into an already-claimed state (e.g. modal reopened
        // mid-cooldown), the backend's `currentDay` is *tomorrow's* slot. Roll
        // it back one position in the 7-day cycle so the confirmation UI shows
        // the reward the player actually received, not tomorrow's preview.
        if !canClaim, let currentDay = data?.currentDay {
            justClaimedDay = currentDay == 1 ? 7 : currentDay - 1
        } else {
            justClaimedDay = nil
        }
        // Sync hub badge state with fresh server data
        appState.dailyLoginCanClaim = canClaim
    }

    func claimReward() async {
        guard loginData?.canClaim == true, !isClaiming else { return }
        let currentDay = loginData?.currentDay ?? 0
        isClaiming = true

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

        // Fire API in background — don't block UI
        Task { [weak self] in
            guard let self else { return }
            let updatedData = await service.claimReward()
            isClaiming = false
            if let data = updatedData {
                loginData = data

                // Show reward modal — parse reward from the daily reward table
                let rewards = DailyReward.rewards(from: cache)
                if let todayReward = rewards.first(where: { $0.day == currentDay }) {
                    // Parse gold/xp from label (e.g. "150 Gold", "50 XP")
                    let goldAmount = Self.parseRewardAmount(todayReward.label, type: "Gold")
                    let xpAmount = Self.parseRewardAmount(todayReward.label, type: "XP")
                    let gemsAmount = Self.parseRewardAmount(todayReward.label, type: "Gems")

                    claimRewardConfig = ClaimRewardConfig(
                        title: "DAILY REWARD\nCLAIMED!",
                        subtitle: "Day \(currentDay)",
                        goldReward: goldAmount,
                        gemsReward: gemsAmount,
                        xpReward: xpAmount,
                        lootItems: []
                    )
                }
            } else {
                // Revert on failure
                hasClaimed = false
                justClaimedDay = nil
                appState.dailyLoginCanClaim = true
                appState.showToast("Claim failed", subtitle: "Try again", type: .error)
            }

            // Reset particles after animation
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation {
                self.showClaimParticles = false
            }
        }
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

    // MARK: - Reward Parsing

    /// Extracts a numeric amount from reward label like "150 Gold" or "50 XP".
    private static func parseRewardAmount(_ label: String, type: String) -> Int {
        let lowered = label.lowercased()
        let typeKey = type.lowercased()
        guard lowered.contains(typeKey) else { return 0 }
        // Extract first number from the label
        let digits = label.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(digits) ?? 0
    }
}
