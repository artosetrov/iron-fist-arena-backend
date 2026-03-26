import SwiftUI

@MainActor @Observable
final class DailyLoginPopupViewModel {
    let appState: AppState
    private let service: DailyLoginService

    var loginData: DailyLoginData?
    var isLoading = true
    var isClaiming = false
    var hasClaimed = false

    // Animation states
    var claimedDayBounce: Int? = nil
    var showClaimParticles = false

    init(appState: AppState) {
        self.appState = appState
        self.service = DailyLoginService(appState: appState)
    }

    func loadData() async {
        isLoading = true
        let data = await service.getStatus()
        loginData = data
        isLoading = false
        hasClaimed = !(data?.canClaim ?? true)
    }

    func claimReward() async {
        guard loginData?.canClaim == true else { return }
        let currentDay = loginData?.currentDay ?? 0
        isClaiming = true

        // Optimistic UI: show claimed state INSTANTLY
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            claimedDayBounce = currentDay
            showClaimParticles = true
            hasClaimed = true
        }
        isClaiming = false
        appState.dailyLoginCanClaim = false

        // Fire API in background — don't block UI
        Task {
            let updatedData = await service.claimReward()
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
                showClaimParticles = false
            }
        }
    }

    var nextDayReward: DailyReward? {
        guard let currentDay = loginData?.currentDay, currentDay < 7 else { return nil }
        return DailyReward.rewards.first(where: { $0.day == currentDay + 1 })
    }

    func dismiss() {
        appState.dismissDailyLoginPopup()
    }
}
