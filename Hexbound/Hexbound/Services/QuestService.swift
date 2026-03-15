import Foundation

@MainActor
final class QuestService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadQuests() async -> (quests: [Quest], bonusClaimed: Bool) {
        guard let charId = appState.currentCharacter?.id else { return ([], false) }
        do {
            let data = try await APIClient.shared.getRaw(
                APIEndpoints.questsDaily,
                params: ["character_id": charId]
            )
            guard let questsData = data["quests"] as? [[String: Any]] else { return ([], false) }
            let jsonData = try JSONSerialization.data(withJSONObject: questsData)
            let decoder = JSONDecoder()
            let quests = try decoder.decode([Quest].self, from: jsonData)
            let bonusClaimed = data["daily_bonus_claimed"] as? Bool ?? false
            appState.cachedTypedQuests = quests
            appState.cachedBonusClaimedToday = bonusClaimed
            return (quests, bonusClaimed)
        } catch {
            return ([], false)
        }
    }

    func claimQuest(questId: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            let result = try await APIClient.shared.postRaw(
                APIEndpoints.questsDaily,
                body: ["character_id": charId, "quest_id": questId, "action": "claim"]
            )
            // Refresh character in background (don't block UI)
            Task { [weak self] in await self?.refreshCharacter() }
            return result["success"] as? Bool ?? true
        } catch {
            appState.showToast("Failed to claim quest", subtitle: "Quest may not be completed yet", type: .error)
            return false
        }
    }

    func claimBonus() async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.questsDailyBonus,
                body: ["character_id": charId]
            )
            appState.cachedBonusClaimedToday = true
            // Refresh character in background (don't block UI)
            Task { [weak self] in await self?.refreshCharacter() }
            return true
        } catch {
            appState.showToast("Bonus already claimed today", type: .info)
            return false
        }
    }

    private func refreshCharacter() async {
        let charService = CharacterService(appState: appState)
        await charService.loadCharacter()
    }
}
