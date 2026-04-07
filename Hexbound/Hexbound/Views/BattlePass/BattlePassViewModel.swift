import SwiftUI

@MainActor @Observable
final class BattlePassViewModel {
    private let appState: AppState
    private let service: BattlePassService

    var data: BattlePassData?
    var isLoading = false
    var errorMessage: String?
    var isBuyingPremium = false

    /// Levels currently being claimed — prevents duplicate requests
    private var claimingLevels: Set<Int> = []
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

    /// Whether a specific level is currently mid-claim (for UI disabling)
    func isClaimingLevel(_ level: Int) -> Bool {
        claimingLevels.contains(level)
    }

    func claimReward(_ reward: BPReward) async {
        let level = reward.level

        // ── Guards: state + duplicate-request lock ──
        guard rewardState(reward) == .claimable else { return }
        guard !claimingLevels.contains(level) else { return }
        claimingLevels.insert(level)

        // ── Optimistic UI: mark claimed instantly ──
        if var bp = data {
            if reward.track == "premium" {
                for i in bp.premiumRewards.indices where bp.premiumRewards[i].level == level {
                    bp.premiumRewards[i].claimed = true
                }
            } else {
                for i in bp.freeRewards.indices where bp.freeRewards[i].level == level {
                    bp.freeRewards[i].claimed = true
                }
            }
            data = bp
            cache.cacheBattlePass(bp)
        }
        HapticManager.success()

        // ── Await API call (not fire-and-forget) ──
        do {
            try await service.claimReward(level: level)
        } catch let error as BattlePassClaimError {
            // Silently ignore "already claimed" — the reward IS claimed on server
            if case .alreadyClaimed = error {
                // Optimistic state is correct, just refresh
            } else {
                appState.showToast("Claim failed", subtitle: error.toastSubtitle, type: .error)
            }
        } catch {
            appState.showToast("Claim failed", subtitle: "Check connection and try again", type: .error)
        }

        // ── Always refresh to sync with server truth ──
        if let freshData = await service.loadBattlePass() {
            data = freshData
            cache.cacheBattlePass(freshData)
        }

        // Remove lock AFTER all async work (API + refresh) completes
        claimingLevels.remove(level)
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
