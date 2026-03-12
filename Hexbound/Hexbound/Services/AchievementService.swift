import Foundation

@MainActor
final class AchievementService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadAchievements() async -> [Achievement] {
        guard let charId = appState.currentCharacter?.id else { return [] }
        do {
            let data = try await APIClient.shared.getRaw(
                APIEndpoints.achievements,
                params: ["character_id": charId]
            )
            let achievementsData: [[String: Any]]
            if let arr = data["achievements"] as? [[String: Any]] {
                achievementsData = arr
            } else if let arr = data["data"] as? [[String: Any]] {
                achievementsData = arr
            } else {
                return []
            }
            let jsonData = try JSONSerialization.data(withJSONObject: achievementsData)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([Achievement].self, from: jsonData)
        } catch {
            return []
        }
    }

    func claim(achievementKey: String) async -> Bool {
        guard let charId = appState.currentCharacter?.id else { return false }
        do {
            _ = try await APIClient.shared.postRaw(
                APIEndpoints.achievementsClaim,
                body: ["character_id": charId, "achievement_key": achievementKey]
            )
            // Refresh character in background (don't block UI)
            Task { [weak self] in
                guard let appState = self?.appState else { return }
                let charService = CharacterService(appState: appState)
                await charService.loadCharacter()
            }
            return true
        } catch {
            appState.showToast("Failed to claim reward", type: .error)
            return false
        }
    }
}
