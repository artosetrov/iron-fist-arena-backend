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
        if let cached = cache.staleBattlePass() {
            data = cached
        } else {
            isLoading = true
        }
        errorMessage = nil
        let result = await service.loadBattlePass()
        if let result {
            // Re-apply levels still being claimed — a refresh that started
            // before an optimistic claim must not bring the CLAIM back.
            let patched = withInFlightClaims(result)
            data = patched
            cache.cacheBattlePass(patched)
        } else if data == nil {
            errorMessage = "Failed to load Battle Pass"
        }
        isLoading = false
    }

    /// Whether a specific level is currently mid-claim (for UI disabling)
    func isClaimingLevel(_ level: Int) -> Bool {
        claimingLevels.contains(level)
    }

    /// Latency pass (2026-10-15): optimistic. Every reward the server will
    /// grant for this level (free + premium when owned — the route claims
    /// them together) is already in `data`, so the nodes flip to claimed, the
    /// HUD is credited and the CLAIMED modal opens on the tap. The blocking
    /// full `loadBattlePass()` that used to run after EVERY claim (holding
    /// the lock for two round trips and re-rendering every node) now runs
    /// only to resync after a failure.
    func claimReward(_ reward: BPReward) async {
        let level = reward.level

        // ── Guards: state + duplicate-request lock ──
        guard rewardState(reward) == .claimable else { return }
        guard !claimingLevels.contains(level) else { return }
        claimingLevels.insert(level)
        defer { claimingLevels.remove(level) }
        let previousLevel = appState.currentCharacter?.level

        // ── Optimistic ──
        let expected = expectedClaims(at: level)
        let claimsFree = expected.contains { !$0.isPremium }
        let claimsPremium = expected.contains { $0.isPremium }
        recentClaims[level] = RecentClaim(free: claimsFree, premium: claimsPremium, at: Date())
        setClaimed(true, level: level, free: claimsFree, premium: claimsPremium)
        let credit = appState.creditRewardOptimistically(
            gold: Self.sum(expected, type: "gold"),
            gems: Self.sum(expected, type: "gems"),
            xp: Self.sum(expected, type: "xp")
        )
        let hold = appState.holdLevelUpForCeremony()
        var config = buildClaimRewardConfig(level: level, rewards: expected)
        config.onDismiss = { [appState] in appState.releaseLevelUpHold(hold) }
        claimRewardConfig = config

        // ── Confirm ──
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
            if claimRewardConfig != config { appState.releaseLevelUpHold(hold) }
            return
        } catch let error as BattlePassClaimError {
            if case .alreadyClaimed = error {
                appState.showToast("Already claimed", subtitle: error.toastSubtitle, type: .info)
            } else {
                appState.showToast("Claim failed", subtitle: error.toastSubtitle, type: .error)
            }
        } catch {
            appState.showToast("Claim failed", subtitle: "Check connection and try again", type: .error)
        }

        // ── Roll back + resync with server truth ──
        recentClaims[level] = nil
        appState.revertRewardCredit(credit)
        setClaimed(false, level: level, free: claimsFree, premium: claimsPremium)
        if claimRewardConfig == config { claimRewardConfig = nil }
        appState.releaseLevelUpHold(hold)
        Task { [weak self] in
            guard let self, let freshData = await self.service.loadBattlePass() else { return }
            self.data = freshData
            self.cache.cacheBattlePass(freshData)
        }
    }

    /// Claims made in the last minute (in flight or just confirmed), per
    /// level AND track — buying premium later must not mark that level's
    /// premium node as claimed just because its free node was.
    private struct RecentClaim {
        let free: Bool
        let premium: Bool
        let at: Date
    }
    private var recentClaims: [Int: RecentClaim] = [:]

    private func withInFlightClaims(_ bp: BattlePassData) -> BattlePassData {
        let now = Date()
        recentClaims = recentClaims.filter { now.timeIntervalSince($0.value.at) < 60 }
        guard !recentClaims.isEmpty else { return bp }
        var patched = bp
        for index in patched.freeRewards.indices
        where recentClaims[patched.freeRewards[index].level]?.free == true {
            patched.freeRewards[index].claimed = true
        }
        for index in patched.premiumRewards.indices
        where recentClaims[patched.premiumRewards[index].level]?.premium == true {
            patched.premiumRewards[index].claimed = true
        }
        return patched
    }

    /// What `POST /battle-pass/claim/{level}` will grant: the unclaimed free
    /// reward(s) at `level`, plus the premium ones when the pass is owned.
    private func expectedClaims(at level: Int) -> [BattlePassClaimReward] {
        let free = freeRewards.filter { $0.level == level && !$0.claimed }
        let premium = hasPremium ? premiumRewards.filter { $0.level == level && !$0.claimed } : []
        return free.map { Self.claimLine($0, isPremium: false) } + premium.map { Self.claimLine($0, isPremium: true) }
    }

    private static func claimLine(_ reward: BPReward, isPremium: Bool) -> BattlePassClaimReward {
        BattlePassClaimReward(
            rewardType: reward.rewardType,
            rewardName: reward.rewardName,
            rewardId: nil,
            rewardAmount: reward.amount,
            isPremium: isPremium
        )
    }

    private static func sum(_ rewards: [BattlePassClaimReward], type: String) -> Int {
        rewards.filter { $0.rewardType == type }.reduce(0) { $0 + $1.rewardAmount }
    }

    /// Flip the claimed flag of this level's nodes only (never a snapshot
    /// restore — a parallel claim of another level must survive a rollback).
    private func setClaimed(_ claimed: Bool, level: Int, free: Bool, premium: Bool) {
        guard var bp = data else { return }
        if free {
            for index in bp.freeRewards.indices where bp.freeRewards[index].level == level {
                bp.freeRewards[index].claimed = claimed
            }
        }
        if premium {
            for index in bp.premiumRewards.indices where bp.premiumRewards[index].level == level {
                bp.premiumRewards[index].claimed = claimed
            }
        }
        data = bp
        cache.cacheBattlePass(bp)
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

    private func buildClaimRewardConfig(level: Int, rewards: [BattlePassClaimReward]) -> ClaimRewardConfig {
        let goldReward = Self.sum(rewards, type: "gold")
        let gemsReward = Self.sum(rewards, type: "gems")
        let xpReward = Self.sum(rewards, type: "xp")

        let lootItems = rewards.compactMap { reward -> ClaimLootItem? in
            let trackRarity: ItemRarity = reward.isPremium ? .epic : .rare
            let trackColor = reward.isPremium ? DarkFantasyTheme.rarityEpic : DarkFantasyTheme.rarityRare

            switch reward.rewardType {
            case "item", "chest":
                return ClaimLootItem(
                    id: reward.rewardId ?? "\(level)-\(reward.rewardType)",
                    name: reward.rewardName,
                    quantity: reward.rewardAmount,
                    imageKey: nil,
                    fallbackIcon: "shippingbox",
                    rarity: trackRarity,
                    rarityColor: trackColor
                )
            case "consumable":
                return ClaimLootItem(
                    id: reward.rewardId ?? "\(level)-consumable",
                    name: reward.rewardName,
                    quantity: reward.rewardAmount,
                    imageKey: nil,
                    fallbackIcon: "cross.vial",
                    rarity: trackRarity,
                    rarityColor: trackColor
                )
            case "stamina":
                return ClaimLootItem(
                    id: reward.rewardId ?? "\(level)-stamina",
                    name: reward.rewardName,
                    quantity: reward.rewardAmount,
                    imageKey: nil,
                    fallbackIcon: "bolt.fill",
                    rarity: .uncommon,
                    rarityColor: DarkFantasyTheme.rarityUncommon
                )
            case "skin", "title", "frame", "effect", "cosmetic":
                return ClaimLootItem(
                    id: reward.rewardId ?? "\(level)-\(reward.rewardType)",
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

        let tracks = Set(rewards.map { $0.isPremium ? "Premium" : "Free" })
        let subtitle: String
        if tracks.count == 2 {
            subtitle = "Level \(level) — Free + Premium"
        } else {
            subtitle = "Level \(level) — \(tracks.first ?? "Reward")"
        }

        return ClaimRewardConfig(
            title: "CLAIMED!",
            subtitle: subtitle,
            goldReward: goldReward,
            gemsReward: gemsReward,
            xpReward: xpReward,
            lootItems: lootItems,
            family: .glory,
            // A hundred levels in five metals: 1–19 iron … 80+ mythic.
            tier: RewardCardTier(rawValue: min(5, 1 + level / 20)) ?? .iron
        )
    }
}

enum BPRewardState {
    case locked, claimable, claimed
}
