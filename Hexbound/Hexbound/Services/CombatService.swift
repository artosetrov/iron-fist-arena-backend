import Foundation

@MainActor
final class CombatService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Simulate Combat (Training)

    func simulate() async -> CombatData? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let body: [String: Any] = ["character_id": charId]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.combatSimulate,
                body: body
            )
            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(CombatData.self, from: jsonData)
        } catch {
            appState.showToast("Combat failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    // MARK: - Get Status

    func getStatus() async -> [String: Any]? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        return try? await APIClient.shared.getRaw(
            APIEndpoints.combatStatus,
            params: ["character_id": charId]
        )
    }

    // MARK: - Buy Extra Attempts

    func buyExtra() async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.combatBuyExtra,
                body: ["character_id": charId]
            )
            // Update gems and stamina from response (single write-back to avoid @Observable re-entrant access)
            if var char = appState.currentCharacter {
                if let gems = response["gems"] as? Int ?? response["gemsRemaining"] as? Int ?? response["gems_remaining"] as? Int {
                    char.gems = gems
                }
                if let stamina = response["stamina"] as? [String: Any],
                   let current = stamina["current"] as? Int {
                    char.currentStamina = current
                }
                appState.currentCharacter = char
            }
            return true
        } catch {
            appState.showToast("Purchase failed", subtitle: "Check your gem balance", type: .error)
            return false
        }
    }
}
