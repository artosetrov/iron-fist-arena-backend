import Foundation

@MainActor
final class CharacterService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Fetch Characters

    func loadCharacter() async {
        guard let charId = appState.currentCharacter?.id else { return }
        do {
            let response: CharacterResponse = try await APIClient.shared.get(
                APIEndpoints.character(charId)
            )
            appState.currentCharacter = response.character
        } catch {
            appState.showToast("Failed to load character", type: .error)
        }
    }

    // MARK: - Allocate Stats

    func allocateStats(statChanges: [String: Int]) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = statChanges
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.allocateStats(charId),
                body: body
            )
            if let charData = response["character"] as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: charData)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let updated = try decoder.decode(Character.self, from: jsonData)
                appState.currentCharacter = updated
                appState.showToast("Stats saved!", type: .info)
                return true
            }
            // Fallback: reload character
            await loadCharacter()
            return true
        } catch {
            appState.showToast("Failed to save stats", type: .error)
            return false
        }
    }

    // MARK: - Respec Stats

    func respecStats() async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = ["character_id": charId]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.respecStats(charId),
                body: body
            )
            if let charData = response["character"] as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: charData)
                let respecDecoder = JSONDecoder()
                respecDecoder.keyDecodingStrategy = .convertFromSnakeCase
                let updated = try respecDecoder.decode(Character.self, from: jsonData)
                appState.currentCharacter = updated
                appState.showToast("Stats reset!", type: .info)
                return true
            }
            await loadCharacter()
            return true
        } catch {
            appState.showToast("Failed to reset stats", type: .error)
            return false
        }
    }

    // MARK: - Set Stance

    func setStance(attack: String, defense: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = ["stance": ["attack": attack, "defense": defense]]
            let _ = try await APIClient.shared.postRaw(
                APIEndpoints.setStance(charId),
                body: body
            )
            appState.currentCharacter?.combatStance = CombatStance(attack: attack, defense: defense)
            appState.showToast("Stance updated!", type: .info)
            return true
        } catch {
            appState.showToast("Failed to update stance", type: .error)
            return false
        }
    }

    // MARK: - Train (Simulate Combat)

    func train() async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let body: [String: Any] = ["character_id": charId]
            let response = try await APIClient.shared.postRaw(
                APIEndpoints.combatSimulate,
                body: body
            )
            let jsonData = try JSONSerialization.data(withJSONObject: response)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let combatData = try decoder.decode(CombatData.self, from: jsonData)
            appState.combatData = combatData
            return true
        } catch {
            appState.showToast("Training failed", type: .error)
            return false
        }
    }
}

// MARK: - Response Types

private struct CharacterResponse: Codable {
    let character: Character
}
