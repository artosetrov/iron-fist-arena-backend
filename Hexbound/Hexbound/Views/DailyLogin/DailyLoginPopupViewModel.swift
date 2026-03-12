import SwiftUI

@MainActor @Observable
final class DailyLoginPopupViewModel {
    let appState: AppState
    private let service: DailyLoginService

    var loginData: DailyLoginData?
    var isLoading = true
    var isClaiming = false
    var hasClaimed = false

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
        isClaiming = true
        let updatedData = await service.claimReward()
        isClaiming = false
        if let data = updatedData {
            loginData = data
            hasClaimed = true
            appState.dailyLoginCanClaim = false
        }
    }

    func dismiss() {
        appState.showDailyLoginPopup = false
    }
}
