import SwiftUI

@MainActor @Observable
final class DailyQuestsViewModel {
    private let appState: AppState
    private let service: QuestService
    private let cache: GameDataCache

    var quests: [Quest] = []
    var isLoading = false
    var hasLoadedOnce = false
    var claimingQuestId: String?
    var isClaimingBonus = false
    var bonusClaimedToday = false
    var errorMessage: String? = nil

    // Claim reward modal — shown after any quest/bonus CLAIM
    var claimRewardConfig: ClaimRewardConfig?

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = QuestService(appState: appState)
        // Serve cached quests instantly (GameDataCache first, then appState fallback).
        // If we have cache, treat the initial state as "loaded" to avoid skeleton flash.
        if let cached = cache.staleDailyQuests() {
            quests = cached.quests
            bonusClaimedToday = cached.bonusClaimed
            hasLoadedOnce = true
        } else if let cached = appState.cachedTypedQuests, !cached.isEmpty {
            quests = cached
            hasLoadedOnce = true
        }
    }

    var completedCount: Int {
        quests.filter(\.completed).count
    }

    /// Claimed quests — the daily chest fills one segment per claim.
    var claimedCount: Int {
        quests.filter(\.rewardClaimed).count
    }

    /// Ready to claim first, then in progress, then already claimed;
    /// server order inside each group.
    var sortedQuests: [Quest] {
        quests.enumerated()
            .sorted { lhs, rhs in
                let l = Self.sortRank(lhs.element), r = Self.sortRank(rhs.element)
                return l != r ? l < r : lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    private static func sortRank(_ quest: Quest) -> Int {
        if quest.canClaim { return 0 }
        return quest.rewardClaimed ? 2 : 1
    }

    var allCompleted: Bool {
        !quests.isEmpty && completedCount == quests.count
    }

    var allClaimed: Bool {
        !quests.isEmpty && quests.allSatisfy(\.rewardClaimed)
    }

    var canClaimBonus: Bool {
        allClaimed && !bonusClaimedToday
    }

    var resetTimeText: String {
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        guard let tomorrow = utcCalendar.date(byAdding: .day, value: 1, to: now),
              let midnight = utcCalendar.date(from: utcCalendar.dateComponents([.year, .month, .day], from: tomorrow))
        else { return "" }
        let remaining = midnight.timeIntervalSince(now)
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return "Resets in: \(hours)h \(minutes)m"
    }

    // MARK: - Load

    /// Loads daily quests with cache-first strategy.
    ///
    /// Rules:
    /// - `isLoading` is true for the entire network call so the view can
    ///   show a skeleton instead of a transient "Failed to Load" flash.
    /// - Stale `quests` from the previous successful load are **kept on
    ///   screen** during a refresh — never blanked out pre-emptively.
    /// - `errorMessage` is set ONLY on a real thrown failure. A silent
    ///   refresh failure with cached data on screen does not surface an
    ///   error UI; the user keeps seeing their quests.
    /// - `hasLoadedOnce` flips to true only on success, so a first-open
    ///   failure without cache correctly shows the error state (not an
    ///   infinite skeleton).
    func loadQuests() async {
        // Cache-first: show cached data instantly.
        // Only flip isLoading on a cold miss — with warm cache the view
        // keeps the cached quests visible while we silently revalidate in
        // the background (no skeleton flash on warm cache).
        if let cached = cache.staleDailyQuests() {
            quests = cached.quests
            bonusClaimedToday = cached.bonusClaimed
        } else if quests.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        do {
            let result = try await service.loadQuests()
            // A refresh that started before an optimistic claim must not
            // resurrect its CLAIM button (a second tap would credit twice):
            // re-apply claims still in flight on top of the server list.
            var fresh = result.quests
            for index in fresh.indices where inFlightClaimIds.contains(fresh[index].id) {
                fresh[index].rewardClaimed = true
            }
            quests = fresh
            bonusClaimedToday = result.bonusClaimed || isClaimingBonus
            syncQuestCaches()
            hasLoadedOnce = true
        } catch {
            // Keep stale `quests` on screen — the view will ignore
            // errorMessage if it has data to show. errorMessage only
            // surfaces when there is nothing to display (empty list).
            errorMessage = "Could not load today's quests. Tap retry."
        }
        isLoading = false
    }

    // MARK: - Claim

    /// Bonus amounts — from the server payload when available. The fallback
    /// matches backend `DAILY_BONUS_REWARD` for an older backend.
    var bonusReward: DailyBonusReward {
        appState.cachedDailyBonusReward ?? DailyBonusReward(gold: 500, xp: 300, gems: 10)
    }

    /// Claims a daily quest reward — optimistically.
    ///
    /// History: BUG-51 (QA 2026-04-10) moved the celebration AFTER the API
    /// call, because the old optimistic version celebrated even when the
    /// server refused and never reconciled the HUD. That made every claim
    /// wait a full round trip (~1 s) before the popup appeared.
    ///
    /// Latency pass (2026-10-15) — optimistic again, with BUG-51's two
    /// failure modes handled:
    /// 1. On tap: mark claimed, credit the quest's own reward amounts (the
    ///    server grants exactly these), open the CLAIMED modal.
    /// 2. Success: apply the server's absolute gold/gems/xp/level. A level-up
    ///    waits for the modal to close (`holdLevelUpForCeremony`).
    /// 3. Failure: subtract exactly what was credited, un-mark the quest,
    ///    close the modal; QuestService shows the server's reason.
    /// Quests whose claim request is still in flight.
    private var inFlightClaimIds: Set<String> = []

    func claimQuest(_ quest: Quest) async {
        guard !inFlightClaimIds.contains(quest.id),
              let idx = quests.firstIndex(where: { $0.id == quest.id }),
              quests[idx].canClaim else { return } // prevent double-tap
        inFlightClaimIds.insert(quest.id)
        defer { inFlightClaimIds.remove(quest.id) }
        claimingQuestId = quest.id
        let previousLevel = appState.currentCharacter?.level
        let gems = quest.rewardGems ?? 0

        // ── 1. Optimistic ──
        quests[idx].rewardClaimed = true
        syncQuestCaches()
        let credit = appState.creditRewardOptimistically(gold: quest.rewardGold, gems: gems, xp: quest.rewardXp)
        let hold = appState.holdLevelUpForCeremony()
        let config = ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: Self.rewardSubtitle(gold: quest.rewardGold, xp: quest.rewardXp, gems: gems, fallback: quest.title),
            goldReward: quest.rewardGold,
            gemsReward: gems,
            xpReward: quest.rewardXp,
            lootItems: [],
            onDismiss: { [appState] in appState.releaseLevelUpHold(hold) }
        )
        claimRewardConfig = config

        // ── 2. Confirm ──
        let result = await service.claimQuest(questId: quest.id)
        if claimingQuestId == quest.id { claimingQuestId = nil }

        guard let result else {
            // ── 3. Roll back ── (QuestService already toasted the reason)
            appState.revertRewardCredit(credit)
            if let i = quests.firstIndex(where: { $0.id == quest.id }) {
                quests[i].rewardClaimed = false
            }
            syncQuestCaches()
            if claimRewardConfig == config { claimRewardConfig = nil }
            appState.releaseLevelUpHold(hold)
            return
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
        // If the player already closed the modal, nothing is holding a
        // level-up any more — let it through now.
        if claimRewardConfig != config { appState.releaseLevelUpHold(hold) }
    }

    func claimBonus() async {
        guard !bonusClaimedToday, !isClaimingBonus else { return }
        isClaimingBonus = true
        let previousLevel = appState.currentCharacter?.level
        let reward = bonusReward

        // Optimistic — same contract as claimQuest.
        bonusClaimedToday = true
        appState.cachedBonusClaimedToday = true
        cache.cacheDailyQuests(quests, bonusClaimed: true)
        let credit = appState.creditRewardOptimistically(gold: reward.gold, gems: reward.gems, xp: reward.xp)
        let hold = appState.holdLevelUpForCeremony()
        let config = ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: "All quests completed",
            goldReward: reward.gold,
            gemsReward: reward.gems,
            xpReward: reward.xp,
            lootItems: [],
            onDismiss: { [appState] in appState.releaseLevelUpHold(hold) }
        )
        claimRewardConfig = config

        let result = await service.claimBonus()
        isClaimingBonus = false

        guard let result else {
            // QuestService already toasted the reason.
            appState.revertRewardCredit(credit)
            bonusClaimedToday = false
            appState.cachedBonusClaimedToday = false
            cache.cacheDailyQuests(quests, bonusClaimed: false)
            if claimRewardConfig == config { claimRewardConfig = nil }
            appState.releaseLevelUpHold(hold)
            return
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
        if claimRewardConfig != config { appState.releaseLevelUpHold(hold) }
    }

    // MARK: - Helpers

    /// Write the quest list to BOTH caches. Hub widgets read
    /// `appState.cachedTypedQuests`, this screen reads `GameDataCache`; they
    /// used to drift, so a quest claimed here still showed CLAIM on the hub
    /// (and vice versa) until the next refetch.
    private func syncQuestCaches() {
        cache.cacheDailyQuests(quests, bonusClaimed: bonusClaimedToday)
        appState.cachedTypedQuests = quests
    }

    /// "+150g  +80 XP  +3 gems" (zero components omitted).
    static func rewardSubtitle(gold: Int, xp: Int, gems: Int, fallback: String) -> String {
        var parts: [String] = []
        if gold > 0 { parts.append("+\(gold)g") }
        if xp > 0 { parts.append("+\(xp) XP") }
        if gems > 0 { parts.append("+\(gems) gems") }
        return parts.isEmpty ? fallback : parts.joined(separator: "  ")
    }
}
