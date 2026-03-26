import SwiftUI

@MainActor @Observable
final class DailyQuestsViewModel {
    private let appState: AppState
    private let service: QuestService
    private let cache: GameDataCache

    var quests: [Quest] = []
    var isLoading = false
    var claimingQuestId: String?
    var isClaimingBonus = false
    var bonusClaimedToday = false
    var errorMessage: String? = nil

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = QuestService(appState: appState)
        // Serve cached quests instantly (GameDataCache first, then appState fallback)
        if let cached = cache.cachedDailyQuests() {
            quests = cached.quests
            bonusClaimedToday = cached.bonusClaimed
        } else if let cached = appState.cachedTypedQuests, !cached.isEmpty {
            quests = cached
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

    func loadQuests() async {
        // Cache-first: show cached data instantly, only show spinner if empty
        if let cached = cache.cachedDailyQuests() {
            quests = cached.quests
            bonusClaimedToday = cached.bonusClaimed
        } else if quests.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        let result = await service.loadQuests()
        quests = result.quests
        bonusClaimedToday = result.bonusClaimed
        cache.cacheDailyQuests(result.quests, bonusClaimed: result.bonusClaimed)
        isLoading = false
    }

    // MARK: - Claim

    func claimQuest(_ quest: Quest) async {
        claimingQuestId = quest.id

        // ── Optimistic UI: mark claimed instantly ──
        if let idx = quests.firstIndex(where: { $0.id == quest.id }) {
            quests[idx].rewardClaimed = true
        }
        claimingQuestId = nil
        HapticManager.success()
        appState.showToast("Quest Complete! \(quest.title)", type: .quest)

        // ── Fire API in background ──
        Task { [weak self] in
            guard let self else { return }
            let success = await service.claimQuest(questId: quest.id)
            if !success {
                // Revert on failure
                if let idx = quests.firstIndex(where: { $0.id == quest.id }) {
                    quests[idx].rewardClaimed = false
                }
                appState.showToast("Quest claim failed", subtitle: "Try again", type: .error)
            }
        }
    }

    func claimBonus() async {
        guard !bonusClaimedToday else { return }

        // ── Optimistic UI: mark bonus claimed instantly ──
        isClaimingBonus = true
        bonusClaimedToday = true
        isClaimingBonus = false
        HapticManager.success()
        appState.showToast("Bonus: +500 Gold, +10 Gems!", type: .reward)

        // ── Fire API in background ──
        Task { [weak self] in
            guard let self else { return }
            let success = await service.claimBonus()
            if !success {
                // Revert on failure
                bonusClaimedToday = false
                appState.showToast("Bonus claim failed", subtitle: "Try again", type: .error)
            }
        }
    }
}
