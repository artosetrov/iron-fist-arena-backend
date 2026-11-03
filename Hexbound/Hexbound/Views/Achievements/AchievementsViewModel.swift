import SwiftUI

@MainActor @Observable
final class AchievementsViewModel {
    private let appState: AppState
    private let service: AchievementService

    var achievements: [Achievement] = []
    var isLoading = false
    var errorMessage: String? = nil

    /// True only when the last refresh failed AND there is nothing to show.
    ///
    /// A failed background refresh over warm cache must not replace a readable
    /// list with a full-screen error — the stale list is more useful. The error
    /// page is for the case where the screen would otherwise be blank.
    var showsErrorState: Bool { errorMessage != nil && achievements.isEmpty }
    var selectedTab = 0
    static let tabs = ["PvP", "Progress", "Ranking"]
    static let tabCategories = ["pvp", "progression", "ranking"]

    private var claimingKeys: Set<String> = []
    private let cache: GameDataCache

    // Claim reward modal
    var claimRewardConfig: ClaimRewardConfig?

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = AchievementService(appState: appState)
    }

    var totalCount: Int { achievements.count }
    var completedCount: Int { achievements.filter(\.completed).count }
    var unclaimedCount: Int { achievements.filter(\.canClaim).count }

    /// Unclaimed count for a specific tab index (H4 fix: per-tab badges).
    func unclaimedCountForTab(_ tabIndex: Int) -> Int {
        guard tabIndex >= 0, tabIndex < Self.tabCategories.count else { return 0 }
        let category = Self.tabCategories[tabIndex]
        return achievements.filter { $0.category == category && $0.canClaim }.count
    }

    var filteredAchievements: [Achievement] {
        let category = Self.tabCategories[selectedTab]
        return achievements
            .filter { $0.category == category }
            .sorted { a, b in
                // Claimable first, then in-progress, then claimed
                if a.canClaim != b.canClaim { return a.canClaim }
                if a.rewardClaimed != b.rewardClaimed { return !a.rewardClaimed }
                return a.progressFraction > b.progressFraction
            }
    }

    // MARK: - Load

    func loadAchievements() async {
        errorMessage = nil
        if let cached = cache.staleAchievements() {
            achievements = cached
            autoSelectBestTab() // H4 fix: auto-select tab with most unclaimed
        } else {
            isLoading = true
        }
        let outcome = await service.loadAchievements()
        // Re-apply claims still in flight: a refresh that started before an
        // optimistic claim must not bring its CLAIM button back.
        outcome.apply(
            assign: { self.achievements = self.withInFlightClaims($0) },
            cache: { self.cache.cacheAchievements(self.withInFlightClaims($0)) },
            setError: { self.errorMessage = $0 }
        )
        isLoading = false
        autoSelectBestTab() // H4 fix: re-check after network load
    }

    // MARK: - Claim

    /// Latency pass (2026-10-15): optimistic. The reward (gold / gems / xp /
    /// title / frame) is already on the `Achievement`, so the card flips to
    /// claimed, the HUD is credited and the CLAIMED modal opens on the tap.
    /// The server's absolute totals reconcile on success (a level-up waits
    /// for the modal to close); a refusal subtracts the credit, un-claims the
    /// card and withdraws the modal.
    func claim(_ achievement: Achievement) async {
        guard !claimingKeys.contains(achievement.key),
              let idx = achievements.firstIndex(where: { $0.key == achievement.key }),
              achievements[idx].canClaim else { return }
        claimingKeys.insert(achievement.key)
        recentClaimKeys[achievement.key] = Date()
        let previousLevel = appState.currentCharacter?.level
        let reward = achievement.reward
        let gold = reward?.gold ?? 0
        let gems = reward?.gems ?? 0
        let xp = reward?.xp ?? 0

        // ── Optimistic ──
        achievements[idx].rewardClaimed = true
        cache.cacheAchievements(achievements)
        SFXManager.shared.play(.sealStamp)
        let credit = appState.creditRewardOptimistically(gold: gold, gems: gems, xp: xp)
        let hold = appState.holdLevelUpForCeremony()
        let config = ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: achievement.title,
            goldReward: gold,
            gemsReward: gems,
            xpReward: xp,
            lootItems: Self.cosmeticLoot(title: reward?.title, frame: reward?.frame),
            onDismiss: { [appState] in appState.releaseLevelUpHold(hold) },
            family: .glory,
            art: UIImage(named: achievement.badgeAsset) != nil ? .object(achievement.badgeAsset, fill: 0.56) : nil
        )
        claimRewardConfig = config

        // ── Confirm ──
        let result = await service.claim(achievementKey: achievement.key)
        claimingKeys.remove(achievement.key)

        guard let result else {
            recentClaimKeys[achievement.key] = nil
            appState.revertRewardCredit(credit)
            if let i = achievements.firstIndex(where: { $0.key == achievement.key }) {
                achievements[i].rewardClaimed = false
            }
            cache.cacheAchievements(achievements)
            if claimRewardConfig == config { claimRewardConfig = nil }
            appState.releaseLevelUpHold(hold)
            appState.showToast("Claim failed", subtitle: "Reward returned — try again", type: .error)
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

    /// Claimed in the last minute (in flight or just confirmed) — survives a
    /// refresh that was requested before the claim landed.
    private var recentClaimKeys: [String: Date] = [:]

    private func withInFlightClaims(_ list: [Achievement]) -> [Achievement] {
        let now = Date()
        recentClaimKeys = recentClaimKeys.filter { now.timeIntervalSince($0.value) < 60 }
        guard !claimingKeys.isEmpty || !recentClaimKeys.isEmpty else { return list }
        var patched = list
        for index in patched.indices
        where claimingKeys.contains(patched[index].key) || recentClaimKeys[patched[index].key] != nil {
            patched[index].rewardClaimed = true
        }
        return patched
    }

    /// Title / frame cosmetics shown as loot cards in the CLAIMED modal.
    private static func cosmeticLoot(title: String?, frame: String?) -> [ClaimLootItem] {
        var items: [ClaimLootItem] = []
        if let title {
            items.append(ClaimLootItem(
                id: "title:\(title)",
                name: "Title: \(title)",
                quantity: 1,
                imageKey: nil,
                fallbackIcon: "sparkles",
                rarity: .epic,
                rarityColor: DarkFantasyTheme.rarityEpic
            ))
        }
        if let frame {
            items.append(ClaimLootItem(
                id: "frame:\(frame)",
                name: "Frame: \(frame)",
                quantity: 1,
                imageKey: nil,
                fallbackIcon: "sparkles.rectangle.stack",
                rarity: .epic,
                rarityColor: DarkFantasyTheme.rarityEpic
            ))
        }
        return items
    }

    // MARK: - Auto-Select Tab (H4 fix)

    /// On first load, auto-select the tab with the most unclaimed achievements.
    private func autoSelectBestTab() {
        // Only auto-select if current tab has no unclaimed
        guard unclaimedCountForTab(selectedTab) == 0 else { return }
        let bestTab = Self.tabCategories.indices.max(by: {
            unclaimedCountForTab($0) < unclaimedCountForTab($1)
        })
        if let bestTab, unclaimedCountForTab(bestTab) > 0 {
            selectedTab = bestTab
        }
    }
}
