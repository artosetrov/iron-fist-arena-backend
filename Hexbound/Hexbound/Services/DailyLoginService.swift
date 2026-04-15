import Foundation

@MainActor
final class DailyLoginService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Get Status

    func getStatus() async -> DailyLoginData? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let data: DailyLoginData = try await APIClient.shared.get(
                APIEndpoints.dailyLogin,
                params: ["character_id": charId]
            )
            return data
        } catch {
            return nil
        }
    }

    // MARK: - Claim Reward

    func claimReward() async -> DailyLoginClaimResponse? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let response: DailyLoginClaimResponse = try await APIClient.shared.post(
                APIEndpoints.dailyLoginClaim,
                body: ["character_id": charId]
            )

            appState.applyAuthoritativeRewardState(
                gold: response.gold,
                gems: response.gems
            )
            if response.reward.type == "consumable" {
                appState.cachedInventory = nil
            }

            appState.showToast("Reward claimed!", type: .reward)
            return response
        } catch {
            appState.showToast("Failed to claim reward", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }
}
