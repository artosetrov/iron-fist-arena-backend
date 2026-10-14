import SwiftUI

/// "The Scavenger" — the black market's one offer: a timed contraband drop.
///
/// This logic used to live in `ShopViewModel`, where the widget sat above the
/// gear list and the shop suppressed its own SPECIAL OFFERS carousel until the
/// Scavenger had been claimed, so the two would not compete for attention.
/// With the black market on its own screen (2026-10-14) there is nothing to
/// compete with, and the coupling is gone.
@MainActor @Observable
final class BlackMarketViewModel {
    private let appState: AppState
    private let cache: GameDataCache

    var contrabandState: ContrabandUIState = .loading
    var isClaiming = false

    /// Reward ceremony shown after a successful claim.
    var claimRewardConfig: ClaimRewardConfig?

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        // Hydrate from cache instantly so the cooldown ticker renders on entry
        // without waiting for the network; `load()` revalidates behind it.
        if let cached = cache.cachedContraband() {
            contrabandState = ContrabandUIState.from(cached)
        }
    }

    var gold: Int { appState.currentCharacter?.gold ?? 0 }
    var gems: Int { appState.currentCharacter?.gems ?? 0 }

    var canAfford: Bool {
        if case .available(let offer) = contrabandState {
            return offer.isFree || gold >= offer.price
        }
        return false
    }

    // MARK: - Load

    func load() async {
        guard let charId = appState.currentCharacter?.id else { return }
        do {
            let response: ContrabandResponse = try await APIClient.shared.get(
                APIEndpoints.shopContraband,
                params: ["character_id": charId]
            )
            cache.cacheContraband(response)
            contrabandState = ContrabandUIState.from(response)
        } catch {
            #if DEBUG
            print("[BlackMarketVM] Failed to load contraband: \(error)")
            #endif
            // Keep a stale cache on screen rather than blanking the card on a
            // transient network error. `.error` is for having nothing at all.
            if cache.cachedContraband() == nil {
                contrabandState = .error
            }
        }
    }

    // MARK: - Claim

    func claim() async {
        guard !isClaiming else { return }
        guard let charId = appState.currentCharacter?.id else { return }

        // Affordability check for paid drops
        if case .available(let offer) = contrabandState, !offer.isFree {
            guard gold >= offer.price else {
                HapticManager.error()
                appState.showToast("Not enough gold!", type: .error,
                    actionLabel: "GET MORE",
                    action: { [weak appState] in
                        appState?.mainPath.append(AppRoute.currencyPurchase())
                    }
                )
                return
            }
        }

        isClaiming = true

        let savedGold = appState.currentCharacter?.gold ?? 0
        let savedGems = appState.currentCharacter?.gems ?? 0

        // Optimistic: deduct gold for paid drops
        if case .available(let offer) = contrabandState, !offer.isFree {
            appState.currentCharacter?.gold = savedGold - offer.price
        }
        HapticManager.success()

        defer { isClaiming = false }
        do {
            let response: ContrabandClaimResponse = try await APIClient.shared.post(
                APIEndpoints.shopContraband,
                body: ["character_id": charId]
            )
            if response.success {
                appState.applyAuthoritativeRewardState(
                    gold: response.gold,
                    gems: response.gems,
                    xp: response.xp,
                    leveledUp: response.leveledUp,
                    newLevel: response.newLevel,
                    statPointsAwarded: response.statPointsAwarded,
                    passivePointsAwarded: response.passivePointsAwarded
                )
                claimRewardConfig = .fromOfferContents(
                    title: "CLAIMED!",
                    subtitle: "Drop #\(response.claimNumber)",
                    contents: response.contents
                )
                // The cache now holds a pre-claim "available" snapshot — drop
                // it so the next entry doesn't serve a claimable card.
                cache.invalidateContraband()
                // Flip to the loading placeholder at once; the refresh behind
                // it syncs the exact `nextAvailableAt`.
                contrabandState = .loading
                Task { [weak self] in await self?.load() }
            } else {
                rollBack(gold: savedGold, gems: savedGems)
                appState.showToast("Claim failed", type: .error)
            }
        } catch {
            rollBack(gold: savedGold, gems: savedGems)
            appState.showToast("Claim failed", type: .error)
        }
    }

    private func rollBack(gold: Int, gems: Int) {
        if var char = appState.currentCharacter {
            char.gold = gold
            char.gems = gems
            appState.currentCharacter = char
        }
    }
}
