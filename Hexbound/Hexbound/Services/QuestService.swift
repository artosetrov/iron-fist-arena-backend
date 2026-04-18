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

private struct DailyQuestsResponse: Codable {
    let quests: [Quest]
    let dailyBonusClaimed: Bool
}

/// Result returned by a successful quest claim.
///
/// BUG-51 (QA 2026-04-10): before this struct existed, `claimQuest` returned a
/// plain `Bool` and the ViewModel guessed the rewards from the local `Quest`
/// struct BEFORE the API call — which meant the celebration banner fired even
/// on failure, and the gold/XP HUD never updated because the character refresh
/// was a detached background `Task` that the ViewModel never awaited. Returning
/// the server-confirmed reward deltas plus authoritative post-claim totals fixes
/// both halves without an extra refresh round-trip.
struct QuestClaimResult: Codable {
    let success: Bool
    let rewardGold: Int
    let rewardXp: Int
    let rewardGems: Int
    let gold: Int
    let gems: Int
    let xp: Int
    let leveledUp: Bool
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
}

struct QuestBonusClaimResult: Codable {
    let success: Bool
    let rewardGold: Int
    let rewardXp: Int
    let rewardGems: Int
    let gold: Int
    let gems: Int
    let xp: Int
    let leveledUp: Bool
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
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
            let response: DailyQuestsResponse = try await APIClient.shared.get(
                APIEndpoints.questsDaily,
                params: ["character_id": charId]
            )
            appState.cachedTypedQuests = response.quests
            appState.cachedBonusClaimedToday = response.dailyBonusClaimed
            return (response.quests, response.dailyBonusClaimed)
        } catch let error as QuestServiceError {
            throw error
        } catch let error as APIError {
            if case .decodingError = error {
                throw QuestServiceError.decoding
            }
            throw QuestServiceError.network(error)
        } catch is DecodingError {
            throw QuestServiceError.decoding
        } catch {
            throw QuestServiceError.network(error)
        }
    }

    /// Claims a daily quest reward.
    ///
    /// Returns the server-confirmed rewards on success, or `nil` on any
    /// failure. The response now includes both reward deltas and post-claim
    /// authoritative totals, so callers can update `AppState.currentCharacter`
    /// immediately without an extra character refresh round-trip.
    ///
    /// On failure the service shows the specific server-provided reason
    /// ("Reward already claimed", "Quest not completed yet", …) so the user
    /// sees WHY it failed. Callers MUST NOT also show a generic error toast
    /// on nil — that was previously duplicating the message.
    func claimQuest(questId: String) async -> QuestClaimResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let result: QuestClaimResult = try await APIClient.shared.post(
                APIEndpoints.questsDaily,
                body: ["character_id": charId, "quest_id": questId, "action": "claim"]
            )
            guard result.success else {
                appState.showToast("Quest claim failed", subtitle: "Unknown server response", type: .error)
                return nil
            }
            return result
        } catch let apiError as APIError {
            // 401 is handled globally by APIClient — don't double-toast it.
            if apiError.isUnauthorized { return nil }
            appState.showToast("Quest claim failed", subtitle: apiError.userMessage, type: .error)
            return nil
        } catch {
            appState.showToast("Quest claim failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    func claimBonus() async -> QuestBonusClaimResult? {
        guard let charId = appState.currentCharacter?.id else { return nil }
        do {
            let result: QuestBonusClaimResult = try await APIClient.shared.post(
                APIEndpoints.questsDailyBonus,
                body: ["character_id": charId]
            )
            guard result.success else { return nil }
            appState.cachedBonusClaimedToday = true
            return result
        } catch {
            appState.showToast("Bonus already claimed today", type: .info)
            return nil
        }
    }
}
