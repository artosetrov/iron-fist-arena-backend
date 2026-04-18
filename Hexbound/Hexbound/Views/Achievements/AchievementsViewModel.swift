import SwiftUI

@MainActor @Observable
final class AchievementsViewModel {
    private let appState: AppState
    private let service: AchievementService

    var achievements: [Achievement] = []
    var isLoading = false
    var errorMessage: String? = nil
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
        if let cached = cache.cachedAchievements() {
            achievements = cached
            autoSelectBestTab() // H4 fix: auto-select tab with most unclaimed
        } else {
            isLoading = true
        }
        let result = await service.loadAchievements()
        achievements = result
        cache.cacheAchievements(result)
        isLoading = false
        autoSelectBestTab() // H4 fix: re-check after network load
    }

    // MARK: - Claim

    func claim(_ achievement: Achievement) async {
        guard !claimingKeys.contains(achievement.key) else { return }
        claimingKeys.insert(achievement.key)
        let previousLevel = appState.currentCharacter?.level

        let result = await service.claim(achievementKey: achievement.key)
        claimingKeys.remove(achievement.key)

        guard let result else {
            appState.showToast("Claim failed. Try again.", type: .error)
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

        if let idx = achievements.firstIndex(where: { $0.key == achievement.key }) {
            achievements[idx].rewardClaimed = true
        }
        cache.cacheAchievements(achievements)
        HapticManager.success()
        SFXManager.shared.play(.sealStamp)

        let lootItems: [ClaimLootItem]
        if let reward = result.reward {
            switch reward.type {
            case "title":
                let ref = reward.id ?? achievement.reward?.title ?? "unknown"
                lootItems = [
                    ClaimLootItem(
                        id: "title:\(ref)",
                        name: "Title: \(ref)",
                        quantity: max(reward.amount, 1),
                        imageKey: nil,
                        fallbackIcon: "sparkles",
                        rarity: .epic,
                        rarityColor: DarkFantasyTheme.rarityEpic
                    )
                ]
            case "frame":
                let ref = reward.id ?? achievement.reward?.frame ?? "unknown"
                lootItems = [
                    ClaimLootItem(
                        id: "frame:\(ref)",
                        name: "Frame: \(ref)",
                        quantity: max(reward.amount, 1),
                        imageKey: nil,
                        fallbackIcon: "sparkles.rectangle.stack",
                        rarity: .epic,
                        rarityColor: DarkFantasyTheme.rarityEpic
                    )
                ]
            default:
                lootItems = []
            }
        } else {
            lootItems = []
        }

        claimRewardConfig = ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: achievement.title,
            goldReward: result.rewardGold,
            gemsReward: result.rewardGems,
            xpReward: result.rewardXp,
            lootItems: lootItems
        )
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
