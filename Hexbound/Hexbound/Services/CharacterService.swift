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
            let response: CharacterEnvelope = try await APIClient.shared.get(
                APIEndpoints.character(charId)
            )
            appState.currentCharacter = response.character
        } catch {
            appState.showToast("Failed to load character", subtitle: "Check connection and try again", type: .error, actionLabel: "Retry") { [weak self] in
                Task { @MainActor in
                    await self?.loadCharacter()
                }
            }
        }
    }

    // MARK: - Allocate Stats

    func allocateStats(statChanges: [String: Int]) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let response: CharacterEnvelope = try await APIClient.shared.post(
                APIEndpoints.allocateStats(charId),
                body: statChanges
            )
            appState.currentCharacter = response.character
            appState.showToast("Stats saved!", type: .info)
            return true
        } catch {
            appState.showToast("Failed to save stats", subtitle: "Changes not applied — try again", type: .error)
            return false
        }
    }

    // MARK: - Respec Stats

    func respecStats() async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let response: CharacterEnvelope = try await APIClient.shared.post(
                APIEndpoints.respecStats(charId),
                body: CharacterIdBody(characterId: charId)
            )
            appState.currentCharacter = response.character
            appState.showToast("Stats reset!", type: .info)
            return true
        } catch {
            appState.showToast("Failed to reset stats", subtitle: "Check connection and try again", type: .error)
            return false
        }
    }

    // MARK: - Buy Stat Points

    func buyStatPoints() async -> BuyStatPointsResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let response: BuyStatPointsResponse = try await APIClient.shared.post(
                APIEndpoints.buyStatPoints(charId),
                body: CharacterIdBody(characterId: charId)
            )
            if let updated = response.character {
                appState.currentCharacter = updated
            }
            return response.purchase
        } catch {
            appState.showToast("Purchase failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    func getStatPurchaseStatus() async -> StatPurchaseStatus? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let response: StatPurchaseStatus = try await APIClient.shared.get(
                APIEndpoints.statPurchaseStatus(charId)
            )
            return response
        } catch {
            return nil
        }
    }

    // MARK: - Set Stance

    func setStance(attack: String, defense: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let response: CharacterEnvelope = try await APIClient.shared.post(
                APIEndpoints.setStance(charId),
                body: SetStanceBody(stance: StanceSelectionBody(attack: attack, defense: defense))
            )
            appState.currentCharacter = response.character
            appState.showToast("Stance updated!", type: .info)
            return true
        } catch {
            appState.showToast("Failed to update stance", subtitle: "Check connection and try again", type: .error)
            return false
        }
    }

    // MARK: - Train (Simulate Combat)

    func train() async -> Bool {
        appState.showToast(
            "Training unavailable",
            subtitle: "This client path still points at a deprecated combat endpoint",
            type: .info
        )
        return false
    }
}

private struct CharacterEnvelope: Decodable {
    let character: Character
}

private struct BuyStatPointsResponse: Decodable {
    let character: Character?
    let purchase: BuyStatPointsResult?
}

private struct CharacterIdBody: Encodable {
    let characterId: String
}

private struct StanceSelectionBody: Encodable {
    let attack: String
    let defense: String
}

private struct SetStanceBody: Encodable {
    let stance: StanceSelectionBody
}
