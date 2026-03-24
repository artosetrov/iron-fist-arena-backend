import Foundation

@MainActor
final class BattlePassService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadBattlePass() async -> BattlePassData? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let data = try await APIClient.shared.getRaw(
                APIEndpoints.battlePass,
                params: ["character_id": charId]
            )
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let decoder = JSONDecoder()
            var bp = try decoder.decode(BattlePassData.self, from: jsonData)
            // Tag tracks
            var free = bp.freeRewards
            for i in free.indices { free[i].track = "free" }
            var premium = bp.premiumRewards
            for i in premium.indices { premium[i].track = "premium" }
            bp = BattlePassData(
                seasonName: bp.seasonName,
                currentLevel: bp.currentLevel,
                currentXp: bp.currentXp,
                xpToNext: bp.xpToNext,
                hasPremium: bp.hasPremium,
                freeRewards: free,
                premiumRewards: premium
            )
            return bp
        } catch {
            return nil
        }
    }

    func claimReward(level: Int) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.battlePassClaim(level),
                body: ["character_id": charId]
            )
            // Refresh character in background (don't block UI)
            Task { [weak self] in await self?.refreshCharacter() }
            return true
        } catch {
            appState.showToast("Failed to claim reward", subtitle: "Check connection and try again", type: .error)
            return false
        }
    }

    func buyPremium() async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.battlePassBuyPremium,
                body: ["character_id": charId]
            )
            // Refresh character in background (don't block UI)
            Task { [weak self] in await self?.refreshCharacter() }
            return true
        } catch let error as APIError {
            let subtitle: String
            switch error {
            case .serverError(let msg):
                if msg.contains("Not enough gems") {
                    subtitle = "Not enough gems"
                } else if msg.contains("already premium") {
                    subtitle = "Already premium"
                } else if msg.contains("No active season") {
                    subtitle = "No active season available"
                } else {
                    subtitle = msg
                }
            default:
                subtitle = error.localizedDescription
            }
            appState.showToast("Failed to buy premium", subtitle: subtitle, type: .error)
            return false
        } catch {
            appState.showToast("Failed to buy premium", subtitle: "Check connection and try again", type: .error)
            return false
        }
    }

    private func refreshCharacter() async {
        let charService = CharacterService(appState: appState)
        await charService.loadCharacter()
    }
}
