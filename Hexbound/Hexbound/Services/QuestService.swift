import SwiftUI

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
    /// Added 2026-10-15; optional so an older backend still decodes.
    let dailyBonusReward: DailyBonusReward?
}

/// Amounts of the daily all-quests bonus, served by GET /api/quests/daily.
struct DailyBonusReward: Codable, Equatable {
    let gold: Int
    let xp: Int
    let gems: Int
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

    /// Quests claimed (in flight or just confirmed) in the last minute.
    /// A quest list fetched before a claim landed would otherwise show the
    /// quest as claimable again — on the hub, the banner and the quests
    /// screen alike — inviting a second tap that the server refuses.
    private static var recentClaims: [String: Date] = [:]
    private static let recentClaimWindow: TimeInterval = 60

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
            let now = Date()
            Self.recentClaims = Self.recentClaims.filter { now.timeIntervalSince($0.value) < Self.recentClaimWindow }
            var quests = response.quests
            for index in quests.indices where Self.recentClaims[quests[index].id] != nil {
                quests[index].rewardClaimed = true
            }
            appState.cachedTypedQuests = quests
            appState.cachedBonusClaimedToday = response.dailyBonusClaimed
            if let reward = response.dailyBonusReward {
                appState.cachedDailyBonusReward = reward
            }
            return (quests, response.dailyBonusClaimed)
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
        Self.recentClaims[questId] = Date()
        do {
            let result: QuestClaimResult = try await APIClient.shared.post(
                APIEndpoints.questsDaily,
                body: ["character_id": charId, "quest_id": questId, "action": "claim"]
            )
            guard result.success else {
                Self.recentClaims[questId] = nil
                appState.showToast("Quest claim failed", subtitle: "Unknown server response", type: .error)
                return nil
            }
            return result
        } catch let apiError as APIError {
            Self.recentClaims[questId] = nil
            // 401 is handled globally by APIClient — don't double-toast it.
            if apiError.isUnauthorized { return nil }
            appState.showToast("Quest claim failed", subtitle: apiError.userMessage, type: .error)
            return nil
        } catch {
            Self.recentClaims[questId] = nil
            appState.showToast("Quest claim failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }

    /// Optimistic quest claim for hub-level widgets that present through the
    /// ROOT modal queue (QuestRewardWidget, ActiveQuestBanner).
    ///
    /// Latency pass (2026-10-15): the CLAIMED modal opens on the tap with the
    /// quest's own amounts (the server grants exactly these); a level-up from
    /// the response queues behind it. On failure the credit is subtracted,
    /// the quest un-marked, the modal withdrawn, and `claimQuest` toasts the
    /// server's reason. Returns whether the server confirmed.
    @discardableResult
    func claimQuestOptimistically(_ quest: Quest, cache: GameDataCache? = nil) async -> Bool {
        let questId = quest.id
        let previousLevel = appState.currentCharacter?.level
        let gems = quest.rewardGems ?? 0

        setRewardClaimed(questId, true, cache: cache)
        let credit = appState.creditRewardOptimistically(gold: quest.rewardGold, gems: gems, xp: quest.rewardXp)
        let config = ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: quest.title,
            goldReward: quest.rewardGold,
            gemsReward: gems,
            xpReward: quest.rewardXp,
            lootItems: []
        )
        appState.claimRewardConfig = config

        guard let result = await claimQuest(questId: questId) else {
            appState.revertRewardCredit(credit)
            setRewardClaimed(questId, false, cache: cache)
            appState.withdrawClaimReward(config)
            return false
        }

        appState.applyAuthoritativeRewardState(
            gold: result.gold,
            gems: result.gems,
            xp: result.xp,
            leveledUp: result.leveledUp,
            newLevel: result.newLevel,
            statPointsAwarded: result.statPointsAwarded,
            passivePointsAwarded: result.passivePointsAwarded,
            previousLevel: previousLevel
        )
        return true
    }

    /// Flip `rewardClaimed` in both quest caches (hub reads AppState, the
    /// Daily Quests screen reads GameDataCache).
    private func setRewardClaimed(_ questId: String, _ claimed: Bool, cache: GameDataCache?) {
        if let idx = appState.cachedTypedQuests?.firstIndex(where: { $0.id == questId }) {
            withAnimation(.easeOut(duration: 0.3)) {
                appState.cachedTypedQuests?[idx].rewardClaimed = claimed
            }
        }
        if let cache, var list = cache.staleDailyQuests()?.quests,
           let idx = list.firstIndex(where: { $0.id == questId }) {
            list[idx].rewardClaimed = claimed
            cache.patchDailyQuests(list)
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
        } catch let apiError as APIError {
            if apiError.isUnauthorized { return nil }
            appState.showToast("Bonus claim failed", subtitle: apiError.userMessage, type: .error)
            return nil
        } catch {
            appState.showToast("Bonus claim failed", subtitle: "Check connection and try again", type: .error)
            return nil
        }
    }
}
