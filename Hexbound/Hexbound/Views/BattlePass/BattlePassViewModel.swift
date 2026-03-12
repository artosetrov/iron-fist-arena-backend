import SwiftUI

@MainActor @Observable
final class BattlePassViewModel {
    private let appState: AppState
    private let service: BattlePassService

    var data: BattlePassData?
    var isLoading = false
    var claimingLevel: Int?
    var isBuyingPremium = false

    private let cache: GameDataCache

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = BattlePassService(appState: appState)
    }

    var seasonName: String { data?.seasonName ?? "Battle Pass" }
    var currentLevel: Int { data?.currentLevel ?? 0 }
    var currentXp: Int { data?.currentXp ?? 0 }
    var xpToNext: Int { data?.xpToNext ?? 100 }
    var xpProgress: Double { data?.xpProgress ?? 0 }
    var hasPremium: Bool { data?.hasPremium ?? false }
    var freeRewards: [BPReward] { data?.freeRewards ?? [] }
    var premiumRewards: [BPReward] { data?.premiumRewards ?? [] }

    func rewardState(_ reward: BPReward) -> BPRewardState {
        if reward.claimed { return .claimed }
        if reward.level <= currentLevel {
            if reward.track == "premium" && !hasPremium { return .locked }
            return .claimable
        }
        return .locked
    }

    // MARK: - Actions

    func loadBattlePass() async {
        if let cached = cache.cachedBattlePass() {
            data = cached
        } else {
            isLoading = true
        }
        let result = await service.loadBattlePass()
        data = result
        if let result { cache.cacheBattlePass(result) }
        isLoading = false
    }

    func claimReward(_ reward: BPReward) async {
        guard rewardState(reward) == .claimable else { return }
        claimingLevel = reward.level
        let success = await service.claimReward(level: reward.level)
        if success {
            await loadBattlePass()
        }
        claimingLevel = nil
    }

    func buyPremium() async {
        guard !isBuyingPremium else { return }
        isBuyingPremium = true
        defer { isBuyingPremium = false }
        let success = await service.buyPremium()
        if success {
            await loadBattlePass()
        }
    }
}

enum BPRewardState {
    case locked, claimable, claimed
}
