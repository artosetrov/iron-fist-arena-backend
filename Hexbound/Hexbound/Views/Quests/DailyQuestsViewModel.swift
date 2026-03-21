import SwiftUI

@MainActor @Observable
final class DailyQuestsViewModel {
    private let appState: AppState
    private let service: QuestService

    var quests: [Quest] = []
    var isLoading = false
    var claimingQuestId: String?
    var isClaimingBonus = false
    var bonusClaimedToday = false
    var errorMessage: String? = nil

    init(appState: AppState) {
        self.appState = appState
        self.service = QuestService(appState: appState)
        // Serve cached quests from /game/init instantly
        if let cached = appState.cachedTypedQuests, !cached.isEmpty {
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
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
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
        if quests.isEmpty { isLoading = true }
        errorMessage = nil
        let result = await service.loadQuests()
        quests = result.quests
        bonusClaimedToday = result.bonusClaimed
        isLoading = false
    }

    // MARK: - Claim

    func claimQuest(_ quest: Quest) async {
        claimingQuestId = quest.id
        let success = await service.claimQuest(questId: quest.id)
        claimingQuestId = nil
        if success {
            if let idx = quests.firstIndex(where: { $0.id == quest.id }) {
                quests[idx].rewardClaimed = true
            }
            appState.showToast("Quest Complete! \(quest.title)", type: .quest)
        }
    }

    func claimBonus() async {
        isClaimingBonus = true
        let success = await service.claimBonus()
        isClaimingBonus = false
        if success {
            bonusClaimedToday = true
            appState.showToast("Bonus: +500 Gold, +10 Gems!", type: .reward)
        }
    }
}
