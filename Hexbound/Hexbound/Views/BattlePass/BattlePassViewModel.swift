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

    // Claim reward modal
    var claimRewardConfig: ClaimRewardConfig?

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
        let previousLevel = appState.currentCharacter?.level

        // ── Await API call (not fire-and-forget) ──
        do {
            let response = try await service.claimReward(level: level)

            applyClaimResponse(response)
            appState.applyAuthoritativeRewardState(
                gold: response.gold,
                gems: response.gems,
                xp: response.xp,
                leveledUp: response.leveledUp,
                newLevel: response.newLevel,
                statPointsAwarded: response.statPointsAwarded,
                passivePointsAwarded: response.passivePointsAwarded,
                previousLevel: previousLevel
            )
            if response.rewards.contains(where: { $0.rewardType == "item" || $0.rewardType == "consumable" }) {
                appState.cachedInventory = nil
            }
            HapticManager.success()

            claimRewardConfig = buildClaimRewardConfig(response: response)
        } catch let error as BattlePassClaimError {
            if case .alreadyClaimed = error {
                appState.showToast("Already claimed", subtitle: error.toastSubtitle, type: .info)
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

    private func applyClaimResponse(_ response: BattlePassClaimResponse) {
        guard var bp = data else { return }

        for reward in response.rewards {
            if reward.isPremium {
                for index in bp.premiumRewards.indices where bp.premiumRewards[index].level == response.level {
                    bp.premiumRewards[index].claimed = true
                }
            } else {
                for index in bp.freeRewards.indices where bp.freeRewards[index].level == response.level {
                    bp.freeRewards[index].claimed = true
                }
            }
        }

        data = bp
        cache.cacheBattlePass(bp)
    }

    private func buildClaimRewardConfig(response: BattlePassClaimResponse) -> ClaimRewardConfig {
        let goldReward = response.rewards
            .filter { $0.rewardType == "gold" }
            .reduce(0) { $0 + $1.rewardAmount }
        let gemsReward = response.rewards
            .filter { $0.rewardType == "gems" }
            .reduce(0) { $0 + $1.rewardAmount }
        let xpReward = response.rewards
            .filter { $0.rewardType == "xp" }
            .reduce(0) { $0 + $1.rewardAmount }

        let lootItems = response.rewards.compactMap { reward -> ClaimLootItem? in
            let trackRarity: ItemRarity = reward.isPremium ? .epic : .rare
            let trackColor = reward.isPremium ? DarkFantasyTheme.rarityEpic : DarkFantasyTheme.rarityRare

            switch reward.rewardType {
            case "item", "chest":
                return ClaimLootItem(
                    id: reward.rewardId ?? "\(response.level)-\(reward.rewardType)",
                    name: reward.rewardName,
                    quantity: reward.rewardAmount,
                    imageKey: nil,
                    fallbackIcon: "shippingbox",
                    rarity: trackRarity,
                    rarityColor: trackColor
                )
            case "consumable":
                return ClaimLootItem(
                    id: reward.rewardId ?? "\(response.level)-consumable",
                    name: reward.rewardName,
                    quantity: reward.rewardAmount,
                    imageKey: nil,
                    fallbackIcon: "cross.vial",
                    rarity: trackRarity,
                    rarityColor: trackColor
                )
            case "stamina":
                return ClaimLootItem(
                    id: reward.rewardId ?? "\(response.level)-stamina",
                    name: reward.rewardName,
                    quantity: reward.rewardAmount,
                    imageKey: nil,
                    fallbackIcon: "bolt.fill",
                    rarity: .uncommon,
                    rarityColor: DarkFantasyTheme.rarityUncommon
                )
            case "skin", "title", "frame", "effect", "cosmetic":
                return ClaimLootItem(
                    id: reward.rewardId ?? "\(response.level)-\(reward.rewardType)",
                    name: reward.rewardName,
                    quantity: reward.rewardAmount,
                    imageKey: nil,
                    fallbackIcon: "sparkles",
                    rarity: .epic,
                    rarityColor: DarkFantasyTheme.rarityEpic
                )
            default:
                return nil
            }
        }

        let tracks = Set(response.rewards.map { $0.isPremium ? "Premium" : "Free" })
        let subtitle: String
        if tracks.count == 2 {
            subtitle = "Level \(response.level) — Free + Premium"
        } else {
            subtitle = "Level \(response.level) — \(tracks.first ?? "Reward")"
        }

        return ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: subtitle,
            goldReward: goldReward,
            gemsReward: gemsReward,
            xpReward: xpReward,
            lootItems: lootItems
        )
    }
}

enum BPRewardState {
    case locked, claimable, claimed
}
