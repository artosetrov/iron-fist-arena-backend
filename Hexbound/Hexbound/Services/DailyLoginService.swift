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

    func claimReward() async -> DailyLoginData? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let body: [String: Any] = ["character_id": charId]
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.dailyLoginClaim,
                body: body
            )
            appState.showToast("Reward claimed!", type: .reward)
            // Reload character + re-fetch status in parallel
            let charService = CharacterService(appState: appState)
            async let charRefresh: Void = charService.loadCharacter()
            async let status = getStatus()
            _ = await charRefresh
            return await status
        } catch {
            appState.showToast("Failed to claim reward", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }
}
