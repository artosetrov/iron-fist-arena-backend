import SwiftUI

@MainActor @Observable
final class BattlePassViewModel {
    private let appState: AppState
    private let service: BattlePassService

    var data: BattlePassData?
    var isLoading = false
    var errorMessage: String?
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
        errorMessage = nil
        let result = await service.loadBattlePass()
        if let result {
            data = result
            cache.cacheBattlePass(result)
        } else if data == nil {
            errorMessage = "Failed to load Battle Pass"
        }
        isLoading = false
    }

    func claimReward(_ reward: BPReward) async {
        guard rewardState(reward) == .claimable else { return }

        // ── Optimistic UI: mark claimed instantly ──
        claimingLevel = reward.level
        if var bp = data {
            if reward.track == "premium" {
                if let idx = bp.premiumRewards.firstIndex(where: { $0.level == reward.level }) {
                    bp.premiumRewards[idx].claimed = true
                }
            } else {
                if let idx = bp.freeRewards.firstIndex(where: { $0.level == reward.level }) {
                    bp.freeRewards[idx].claimed = true
                }
            }
            data = bp
            cache.cacheBattlePass(bp)
        }
        claimingLevel = nil
        HapticManager.success()

        // ── Fire API in background, refresh for server-true state ──
        Task { [weak self] in
            guard let self else { return }
            let success = await service.claimReward(level: reward.level)
            if success {
                // Silently refresh to get accurate server state
                if let freshData = await service.loadBattlePass() {
                    data = freshData
                    cache.cacheBattlePass(freshData)
                }
            } else {
                // Revert: re-load from server
                if let freshData = await service.loadBattlePass() {
                    data = freshData
                    cache.cacheBattlePass(freshData)
                }
                appState.showToast("Claim failed", subtitle: "Try again", type: .error)
            }
        }
    }

    func buyPremium() {
        guard !isBuyingPremium else { return }
        isBuyingPremium = true

        // Optimistic: mark premium instantly
        data?.hasPremium = true
        HapticManager.legendaryReveal()

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            let success = await service.buyPremium()
            isBuyingPremium = false
            if success {
                // Silent refresh to sync tier data
                await loadBattlePass()
            } else {
                // Revert on failure
                data?.hasPremium = false
                appState.showToast("Purchase failed", subtitle: "Try again", type: .error)
            }
        }
    }
}

enum BPRewardState {
    case locked, claimable, claimed
}
