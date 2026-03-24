import SwiftUI

@MainActor @Observable
final class AchievementsViewModel {
    private let appState: AppState
    private let service: AchievementService

    var achievements: [Achievement] = []
    var isLoading = false
    var errorMessage: String? = nil
    var selectedTab = 0
    var claimingKey: String?

    static let tabs = ["PvP", "Progress", "Ranking"]
    static let tabCategories = ["pvp", "progression", "ranking"]

    private let cache: GameDataCache

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
        claimingKey = achievement.key
        let success = await service.claim(achievementKey: achievement.key)
        claimingKey = nil
        if success {
            if let idx = achievements.firstIndex(where: { $0.key == achievement.key }) {
                achievements[idx].rewardClaimed = true
            }
            appState.showToast("Reward Claimed! \(achievement.title)", type: .achievement)
        } else {
            // H6 fix: error feedback on failed claim (was silent failure)
            appState.showToast("Claim failed. Try again.", type: .error)
        }
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
