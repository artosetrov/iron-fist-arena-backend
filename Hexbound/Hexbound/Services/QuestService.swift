import Foundation

/// Errors surfaced by `QuestService.loadQuests()`.
/// Previously the service swallowed all failures and returned `([], false)`,
/// which was indistinguishable from "no quests today" and caused the
/// Daily Quests screen to flash "Failed to Load" every open. It now throws
/// so the caller (ViewModel) can decide whether to show an error state,
/// a skeleton, or keep stale data on screen during a silent refresh.
enum QuestServiceError: Error {
    case noCharacter
    case decoding
    case network(Error)
}

/// Result returned by a successful quest claim.
///
/// BUG-51 (QA 2026-04-10): before this struct existed, `claimQuest` returned a
/// plain `Bool` and the ViewModel guessed the rewards from the local `Quest`
/// struct BEFORE the API call — which meant the celebration banner fired even
/// on failure, and the gold/XP HUD never updated because the character refresh
/// was a detached background `Task` that the ViewModel never awaited. Returning
/// the server-confirmed rewards + awaiting the refresh fixes both halves.
struct QuestClaimResult {
    let rewardGold: Int
    let rewardXp: Int
    let rewardGems: Int
    let leveledUp: Bool
    let newLevel: Int?
    let statPointsAwarded: Int?
}

@MainActor
final class QuestService {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    /// Fetches today's daily quests. Throws on transport / decoding failures
    /// so the ViewModel can distinguish a real error from an intentionally
    /// empty server response. Non-throwing callers may use `try?`.
    func loadQuests() async throws -> (quests: [Quest], bonusClaimed: Bool) {
        guard let charId = appState.currentCharacter?.id else {
            throw QuestServiceError.noCharacter
        }
        do {
            let data = try await APIClient.shared.getRaw(
                APIEndpoints.questsDaily,
                params: ["character_id": charId]
            )
            guard let questsData = data["quests"] as? [[String: Any]] else {
                throw QuestServiceError.decoding
            }
            let jsonData = try JSONSerialization.data(withJSONObject: questsData)
            let decoder = JSONDecoder()
            let quests = try decoder.decode([Quest].self, from: jsonData)
            let bonusClaimed = data["daily_bonus_claimed"] as? Bool ?? false
            appState.cachedTypedQuests = quests
            appState.cachedBonusClaimedToday = bonusClaimed
            return (quests, bonusClaimed)
        } catch let error as QuestServiceError {
            throw error
        } catch {
            throw QuestServiceError.network(error)
        }
    }

    /// Claims a daily quest reward.
    ///
    /// Returns the server-confirmed rewards on success, or `nil` on any
    /// failure. The function **awaits the character refresh inline** so the
    /// caller observes the fresh `gold` / `currentXp` on `appState.currentCharacter`
    /// immediately upon return — no background racing with the UI (BUG-51).
    func claimQuest(questId: String) async -> QuestClaimResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let result = try await APIClient.shared.postRaw(
                APIEndpoints.questsDaily,
                body: ["character_id": charId, "quest_id": questId, "action": "claim"]
            )
            // Server must echo success: true AND the reward values. If the
            // response is missing either, treat as failure so the ViewModel
            // doesn't show a false-positive celebration.
            guard (result["success"] as? Bool) == true else { return nil }

            let rewardGold = result["reward_gold"] as? Int ?? 0
            let rewardXp = result["reward_xp"] as? Int ?? 0
            let rewardGems = result["reward_gems"] as? Int ?? 0
            let leveledUp = result["leveled_up"] as? Bool ?? false
            let newLevel = result["new_level"] as? Int
            let statPoints = result["stat_points_awarded"] as? Int

            // Await the refresh BEFORE returning — the ViewModel relies on
            // `appState.currentCharacter.gold` being up to date when this call
            // completes so the HUD shows +150g / +80 XP immediately.
            await refreshCharacter()

            return QuestClaimResult(
                rewardGold: rewardGold,
                rewardXp: rewardXp,
                rewardGems: rewardGems,
                leveledUp: leveledUp,
                newLevel: newLevel,
                statPointsAwarded: statPoints,
            )
        } catch {
            appState.showToast("Failed to claim quest", subtitle: "Quest may not be completed yet", type: .error)
            return nil
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
