import Foundation

private struct AchievementListResponse: Codable {
    let achievements: [Achievement]?
    let data: [Achievement]?
}

struct AchievementClaimResult: Codable {
    let rewardGold: Int
    let rewardGems: Int
    let rewardXp: Int
    let gold: Int
    let gems: Int
    let xp: Int
    let leveledUp: Bool
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
}

@MainActor
final class AchievementService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadAchievements() async -> [Achievement] {
        guard let charId = appState.currentCharacter?.id else { return [] }
        do {
            let response: AchievementListResponse = try await APIClient.shared.get(
                APIEndpoints.achievements,
                params: ["character_id": charId]
            )
            return response.achievements ?? response.data ?? []
        } catch {
            return []
        }
    }

    func claim(achievementKey: String) async -> AchievementClaimResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let result: AchievementClaimResult = try await APIClient.shared.post(
                APIEndpoints.achievementsClaim,
                body: ["character_id": charId, "achievement_key": achievementKey]
            )
            return result
        } catch {
            return nil
        }
    }
}
