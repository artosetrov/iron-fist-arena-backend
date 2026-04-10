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

    // Animation states
    var claimedDayBounce: Int? = nil
    var showClaimParticles = false

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
        // Sync hub badge state with fresh server data
        appState.dailyLoginCanClaim = canClaim
    }

    func claimReward() async {
        guard loginData?.canClaim == true, !isClaiming else { return }
        let currentDay = loginData?.currentDay ?? 0
        isClaiming = true

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
            } else {
                // Revert on failure
                hasClaimed = false
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

    var nextDayReward: DailyReward? {
        guard let currentDay = loginData?.currentDay, currentDay < 7 else { return nil }
        return DailyReward.rewards(from: cache).first(where: { $0.day == currentDay + 1 })
    }

    func dismiss() {
        appState.dismissDailyLoginPopup()
    }
}
