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
        if let cached = cache.cachedDailyQuests() {
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
        if let cached = cache.cachedDailyQuests() {
            quests = cached.quests
            bonusClaimedToday = cached.bonusClaimed
        } else if quests.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        do {
            let result = try await service.loadQuests()
            quests = result.quests
            bonusClaimedToday = result.bonusClaimed
            cache.cacheDailyQuests(result.quests, bonusClaimed: result.bonusClaimed)
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

    /// Claims a daily quest reward.
    ///
    /// BUG-51 (QA 2026-04-10) fix: the previous implementation showed the
    /// "Quest Complete!" celebration + success haptic BEFORE awaiting the API,
    /// which meant the banner fired on server failure too. It also never
    /// awaited the character refresh, so the gold/XP HUD stayed stale for
    /// seconds after the claim (user reported gold 1,643 → 1,643 and XP
    /// 71/480 → 71/480 despite the celebration).
    ///
    /// New flow:
    /// 1. Show a subtle in-flight state (`claimingQuestId`) only.
    /// 2. Await the server — `QuestService.claimQuest` now awaits the
    ///    character refresh internally, so on return `appState.currentCharacter`
    ///    already holds the new gold/XP.
    /// 3. On success: commit optimistic `rewardClaimed`, haptic, celebration
    ///    with the REAL reward values from the server ("+150g  +80 XP").
    /// 4. On failure: keep state untouched, show error toast.
    func claimQuest(_ quest: Quest) async {
        guard claimingQuestId == nil else { return } // prevent double-tap
        claimingQuestId = quest.id

        // ── Fire API first — no optimistic celebration ──
        let result = await service.claimQuest(questId: quest.id)
        claimingQuestId = nil

        guard let result = result else {
            appState.showToast("Quest claim failed", subtitle: "Try again", type: .error)
            return
        }

        // ── Commit local state now that the server confirmed ──
        if let idx = quests.firstIndex(where: { $0.id == quest.id }) {
            quests[idx].rewardClaimed = true
        }
        // Keep the on-disk cache consistent with the new claimed state so a
        // navigate-away-and-back doesn't flash the quest as un-claimed again.
        cache.cacheDailyQuests(quests, bonusClaimed: bonusClaimedToday)

        HapticManager.success()

        // Build a reward subtitle from SERVER values, not the local Quest.
        // Format: "+150g  +80 XP  +3 gems" (omit zero components).
        var parts: [String] = []
        if result.rewardGold > 0 { parts.append("+\(result.rewardGold)g") }
        if result.rewardXp > 0 { parts.append("+\(result.rewardXp) XP") }
        if result.rewardGems > 0 { parts.append("+\(result.rewardGems) gems") }
        let subtitle = parts.isEmpty ? quest.title : parts.joined(separator: "  ")

        // Show reward modal instead of celebration toast
        claimRewardConfig = ClaimRewardConfig(
            title: "QUEST\nCOMPLETE!",
            subtitle: subtitle,
            goldReward: result.rewardGold,
            gemsReward: result.rewardGems,
            xpReward: result.rewardXp,
            lootItems: []
        )
    }

    func claimBonus() async {
        guard !bonusClaimedToday, !isClaimingBonus else { return }

        // ── Optimistic UI: mark bonus claimed instantly ──
        isClaimingBonus = true
        bonusClaimedToday = true
        HapticManager.success()

        // ── Fire API — keep isClaimingBonus until done ──
        let success = await service.claimBonus()
        isClaimingBonus = false
        if success {
            // Show reward modal for daily bonus
            claimRewardConfig = ClaimRewardConfig(
                title: "DAILY BONUS\nCLAIMED!",
                subtitle: "All quests completed",
                goldReward: 500,
                gemsReward: 10,
                xpReward: 0,
                lootItems: []
            )
        } else {
            // Revert on failure
            bonusClaimedToday = false
            appState.showToast("Bonus claim failed", subtitle: "Try again", type: .error)
        }
    }
}
