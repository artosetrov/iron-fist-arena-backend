import SwiftUI

struct ShopSection: Identifiable {
    let id: String
    let title: String
    let items: [ShopItem]
}

@MainActor @Observable
final class ShopViewModel {
    private let appState: AppState
    private let service: ShopService
    private let inventoryService: InventoryService

    var items: [ShopItem] = []
    var offers: [ShopOffer] = []
    var isLoading = false
    var selectedTab = 0
    var buyingItemId: String?
    /// Items with a purchase in flight (per-item double-tap guard).
    private var buyingItemIds: Set<String> = []
    var buyingOfferId: String?
    var errorMessage: String? = nil

    /// True only when the last refresh failed AND there is nothing to show.
    ///
    /// A failed background refresh over warm cache must not replace a readable
    /// list with a full-screen error — the stale list is more useful. The error
    /// page is for the case where the screen would otherwise be blank.
    var showsErrorState: Bool { errorMessage != nil && items.isEmpty }

    // Claim reward modal — shown after a successful offer purchase.
    // "The Scavenger" moved to BlackMarketDetailView on 2026-10-14 and keeps
    // its own copy of this.
    var claimRewardConfig: ClaimRewardConfig?

    // Detail modal
    var selectedItem: ShopItem?
    var showItemDetail = false

    // Purchase confirmation (gems / expensive items)
    var pendingPurchaseItem: ShopItem?
    var showPurchaseConfirm = false

    // Purchase animation trigger — set after successful buy, cleared by view
    var lastPurchasedItemId: String?

    static let tabs = ["All", "Weapons", "Equipment", "Potions"]
    static let tabTypes: [[String]] = [
        [], // all — no filter
        ["weapon"],
        ["helmet", "chest", "gloves", "legs", "boots", "accessory", "amulet", "belt", "relic", "necklace", "ring"],
        ["consumable", "potion"]
    ]

    private let cache: GameDataCache

    init(appState: AppState, cache: GameDataCache) {
        self.appState = appState
        self.cache = cache
        self.service = ShopService(appState: appState)
        self.inventoryService = InventoryService(appState: appState)
    }

    var gold: Int { appState.currentCharacter?.gold ?? 0 }
    var gems: Int { appState.currentCharacter?.gems ?? 0 }
    var playerLevel: Int { appState.currentCharacter?.level ?? 1 }
    /// Level gate for gear — prestige-aware (Character.gearLevel).
    var gearLevel: Int { appState.currentCharacter?.gearLevel ?? 1 }
    var playerClass: String { appState.currentCharacter?.characterClass.rawValue ?? "warrior" }

    private func applyClaimedRewardState(
        gold: Int,
        gems: Int,
        xp: Int,
        leveledUp: Bool?,
        newLevel: Int?,
        statPointsAwarded: Int?,
        passivePointsAwarded: Int?
    ) {
        appState.applyAuthoritativeRewardState(
            gold: gold,
            gems: gems,
            xp: xp,
            leveledUp: leveledUp,
            newLevel: newLevel,
            statPointsAwarded: statPointsAwarded,
            passivePointsAwarded: passivePointsAwarded
        )
    }

    var filteredItems: [ShopItem] {
        let types = Self.tabTypes[selectedTab]
        if types.isEmpty { return equippableItems } // "All" tab
        return equippableItems.filter { types.contains($0.itemType) }
    }

    /// Items filtered by level and class restriction (base for all display)
    private var equippableItems: [ShopItem] {
        items.filter { item in
            if item.requiredLevel > gearLevel { return false }
            return Character.canWear(characterClass: playerClass, restriction: item.classRestriction)
        }
    }

    var sectionedItems: [ShopSection] {
        let weaponTypes = Self.tabTypes[1]
        let equipmentTypes = Self.tabTypes[2]
        let potionTypes = Self.tabTypes[3]

        let weapons = equippableItems.filter { weaponTypes.contains($0.itemType) }
        let equipment = equippableItems.filter { equipmentTypes.contains($0.itemType) }
        let gemPacks = equippableItems.filter { ($0.consumableType ?? $0.catalogId ?? "").hasPrefix("gem_pack_") }
        let potions = equippableItems.filter {
            potionTypes.contains($0.itemType) && !($0.consumableType ?? $0.catalogId ?? "").hasPrefix("gem_pack_")
        }

        var sections: [ShopSection] = []
        // BUG-37 (QA 2026-04-10): previously passed plain-text icon keys
        // ("swords", "shield", "pills", "diamond") that were rendered as
        // raw Text in the section header — surfacing literal "swords WEAPONS"
        // strings to players. Headers now use OrnamentalSectionHeader which
        // carries the brand ornament visual language instead of an icon.
        if !weapons.isEmpty {
            sections.append(ShopSection(id: "weapons", title: "Weapons", items: weapons))
        }
        if !equipment.isEmpty {
            sections.append(ShopSection(id: "equipment", title: "Equipment", items: equipment))
        }
        if !potions.isEmpty {
            sections.append(ShopSection(id: "potions", title: "Potions", items: potions))
        }
        if !gemPacks.isEmpty {
            sections.append(ShopSection(id: "gems", title: "Gems", items: gemPacks))
        }
        return sections
    }

    // MARK: - Load

    func loadItems() async {
        // Serve cached shop instantly
        if let cached = cache.staleShop() {
            items = cached
        } else {
            isLoading = true
        }
        errorMessage = nil
        // Load items and offers in parallel
        async let itemsTask = service.getItems()
        async let offersTask: Void = loadOffers()
        let outcome = await itemsTask
        _ = await offersTask
        outcome.apply(
            assign: { self.items = $0 },
            cache: { self.cache.cacheShop($0) },
            setError: { self.errorMessage = $0 }
        )
        // A failed refresh over a shop that still has items shows no error
        // page (showsErrorState needs an empty list), so it would pass
        // unnoticed — that is the one case worth a toast.
        if outcome.isFailure && !items.isEmpty {
            appState.showToast(
                "Couldn't refresh the shop",
                subtitle: errorMessage ?? "Check connection and try again",
                type: .error,
                actionLabel: "Retry"
            ) { [weak self] in
                Task { @MainActor in await self?.loadItems() }
            }
        }
        isLoading = false
        // Pre-load inventory for comparison if not cached
        if appState.cachedInventory == nil {
            _ = await inventoryService.loadInventory()
        }
    }

    private func loadOffers() async {
        guard let charId = appState.currentCharacter?.id else { return }
        do {
            let response: ShopOffersResponse = try await APIClient.shared.get(
                APIEndpoints.shopOffers,
                params: ["character_id": charId]
            )
            offers = response.offers
        } catch {
            #if DEBUG
            print("[ShopVM] Failed to load offers: \(error)")
            #endif
        }
    }

    func canAffordOffer(_ offer: ShopOffer) -> Bool {
        if offer.isGemPurchase {
            return gems >= offer.salePrice
        }
        return gold >= offer.salePrice
    }

    func buyOffer(_ offer: ShopOffer) async {
        guard buyingOfferId == nil else { return } // double-tap guard
        guard let charId = appState.currentCharacter?.id else { return }
        guard offer.canPurchase else {
            appState.showToast("Purchase limit reached!", type: .error)
            return
        }
        buyingOfferId = offer.id
        guard canAffordOffer(offer) else {
            buyingOfferId = nil
            appState.showToast(
                offer.isGemPurchase ? "Not enough gems!" : "Not enough gold!",
                type: .error,
                actionLabel: "GET MORE",
                action: { [weak appState] in
                    appState?.mainPath.append(AppRoute.currencyPurchase())
                }
            )
            return
        }

        // ── Optimistic UI: deduct currency instantly ──
        // As a signed delta, so a failure gives back exactly this price
        // without clobbering a purchase made in the meantime.
        let spend = appState.applyOptimisticCurrencyDelta(
            gold: offer.isGemPurchase ? 0 : -offer.salePrice,
            gems: offer.isGemPurchase ? -offer.salePrice : 0
        )
        HapticManager.success()

        // Latency pass (2026-10-15): the reward modal is built from the
        // offer's own contents, so it opens on the tap instead of after the
        // round trip. A failure takes it back together with the currency.
        let config = ClaimRewardConfig.fromOfferContents(
            title: "CLAIMED!",
            subtitle: offer.title,
            contents: offer.contents
        )
        let hold = appState.holdLevelUpForCeremony()
        let shownConfig: ClaimRewardConfig = {
            var withRelease = config
            withRelease.onDismiss = { [appState] in appState.releaseLevelUpHold(hold) }
            return withRelease
        }()
        claimRewardConfig = shownConfig
        let appStateRef = appState
        func rollBack() {
            appStateRef.revertRewardCredit(spend)
            if claimRewardConfig == shownConfig { claimRewardConfig = nil }
            appStateRef.releaseLevelUpHold(hold)
        }

        // ── Fire API in background ──
        Task { [weak self] in
            guard let self else { return }
            defer { buyingOfferId = nil }
            do {
                let response: OfferPurchaseResponse = try await APIClient.shared.post(
                    APIEndpoints.shopOffers,
                    body: ["character_id": charId, "offer_id": offer.id]
                )
                if response.success {
                    applyClaimedRewardState(
                        gold: response.gold,
                        gems: response.gems,
                        xp: response.xp,
                        leveledUp: response.leveledUp,
                        newLevel: response.newLevel,
                        statPointsAwarded: response.statPointsAwarded,
                        passivePointsAwarded: response.passivePointsAwarded
                    )
                    // Reward modal is already up (opened on the tap). If the
                    // player closed it before this landed, let a level-up in.
                    if claimRewardConfig != shownConfig { appState.releaseLevelUpHold(hold) }
                    // Local patch: bump purchasesMade and flip canPurchase if limit hit.
                    if let idx = offers.firstIndex(where: { $0.id == offer.id }) {
                        let existing = offers[idx]
                        let newCount = existing.purchasesMade + 1
                        let stillPurchasable = existing.maxPurchases == 0 || newCount < existing.maxPurchases
                        offers[idx] = ShopOffer(
                            id: existing.id,
                            key: existing.key,
                            title: existing.title,
                            description: existing.description,
                            offerType: existing.offerType,
                            contents: existing.contents,
                            originalPrice: existing.originalPrice,
                            salePrice: existing.salePrice,
                            currency: existing.currency,
                            discountPct: existing.discountPct,
                            maxPurchases: existing.maxPurchases,
                            purchasesMade: newCount,
                            canPurchase: stillPurchasable,
                            imageKey: existing.imageKey,
                            tags: existing.tags,
                            startsAt: existing.startsAt,
                            endsAt: existing.endsAt
                        )
                    }
                    // Fire-and-forget background reconcile — never blocks the UI.
                    Task { [weak self] in await self?.loadOffers() }
                } else {
                    rollBack()
                    appState.showToast("Purchase failed", subtitle: "Nothing was charged", type: .error)
                }
            } catch {
                rollBack()
                appState.showToast("Purchase failed", subtitle: "Nothing was charged", type: .error)
            }
        }
    }

    // MARK: - Selection

    func selectItem(_ item: ShopItem) {
        selectedItem = item
        showItemDetail = true
    }

    func closeDetail() {
        showItemDetail = false
        selectedItem = nil
    }

    // MARK: - Comparison

    func equippedItemForSlot(_ shopItem: ShopItem) -> Item? {
        guard let inventory = appState.cachedInventory else { return nil }
        return inventory.first {
            $0.isEquipped == true && $0.itemType.rawValue == shopItem.itemType
        }
    }

    // MARK: - Buy

    func canAfford(_ item: ShopItem) -> Bool {
        if item.isGemPurchase {
            return gems >= item.gemPrice
        }
        return gold >= item.goldPrice
    }

    func meetsLevel(_ item: ShopItem) -> Bool {
        gearLevel >= item.requiredLevel
    }

    /// Gate purchases: gem items require confirmation, gold items go through directly.
    /// Bug #20: accepts quantity for stackable consumables (defaults to 1).
    func requestBuy(_ item: ShopItem, quantity: Int = 1) {
        if item.isGemPurchase {
            pendingPurchaseItem = item
            pendingPurchaseQuantity = quantity
            showPurchaseConfirm = true
        } else {
            Task { await buy(item, quantity: quantity) }
        }
    }

    /// Bug #20: quantity captured alongside pendingPurchaseItem so gem confirmation flow
    /// preserves the selected amount.
    var pendingPurchaseQuantity: Int = 1

    func confirmPendingPurchase() {
        guard let item = pendingPurchaseItem else { return }
        let qty = pendingPurchaseQuantity
        pendingPurchaseItem = nil
        pendingPurchaseQuantity = 1
        showPurchaseConfirm = false
        Task { await buy(item, quantity: qty) }
    }

    func cancelPendingPurchase() {
        pendingPurchaseItem = nil
        pendingPurchaseQuantity = 1
        showPurchaseConfirm = false
    }

    func buy(_ item: ShopItem, quantity: Int = 1) async {
        // Double-tap guard per item. It used to be global: one in-flight
        // purchase silently swallowed taps on every OTHER item until the
        // round trip finished (latency pass 2026-10-15).
        guard !buyingItemIds.contains(item.id) else { return }

        // Bug #20: clamp quantity — non-consumables always buy exactly 1.
        let qty: Int
        if item.isConsumable && !item.isGemPurchase {
            qty = max(1, min(quantity, 99))
        } else {
            qty = 1
        }

        let unitPrice = item.isGemPurchase ? item.gemPrice : item.goldPrice
        let totalCost = unitPrice * qty

        // Validate currency against total cost, not unit price
        let hasEnoughForTotal: Bool = item.isGemPurchase
            ? gems >= totalCost
            : gold >= totalCost
        if !hasEnoughForTotal {
            HapticManager.error()
            appState.showToast(
                item.isGemPurchase ? "Not enough gems!" : "Not enough gold!",
                type: .error,
                actionLabel: "GET MORE",
                action: { [weak appState] in
                    appState?.mainPath.append(AppRoute.currencyPurchase())
                }
            )
            return
        }

        buyingItemIds.insert(item.id)
        buyingItemId = item.id

        // ── Optimistic UI: update instantly ──

        // Gem packs add gems while spending gold — they're the one consumable
        // with a bidirectional balance effect. All other items just spend.
        let ct = item.consumableType ?? item.catalogId ?? ""
        let isGemPack = ct.hasPrefix("gem_pack_")
        let gemPackGemsAmount: Int = {
            switch ct {
            case "gem_pack_small": return 10
            case "gem_pack_medium": return 50
            case "gem_pack_large": return 100
            default: return 0
            }
        }()

        // Deduct currency optimistically (Bug #20: total cost, not unit).
        // A signed delta through AppState (fresh struct copy inside, for
        // reliable @Observable notification). Gem packs also credit their
        // gems now — the server response overwrites with authoritative values.
        let spend = appState.applyOptimisticCurrencyDelta(
            gold: item.isGemPurchase ? 0 : -totalCost,
            gems: item.isGemPurchase ? -totalCost : (isGemPack ? gemPackGemsAmount : 0)
        )

        // Remove from list immediately (equipment only) — and from the
        // cache, so re-entering the shop doesn't show it for sale again.
        let removedIndex = item.isConsumable ? nil : items.firstIndex(where: { $0.id == item.id })
        if let removedIndex {
            items.remove(at: removedIndex)
            cache.cacheShop(items)
        }

        HapticManager.success()
        SFXManager.shared.play(.coinsJingle)
        SFXManager.shared.play(.pouchDrop)
        showItemDetail = false
        selectedItem = nil
        lastPurchasedItemId = item.id
        // Confirmation on the tap; a failure replaces it with the error.
        let toastMsg = qty > 1 ? "\(qty)× \(item.itemName) purchased!" : "\(item.itemName) purchased!"
        appState.showToast(toastMsg, type: .reward)
        // No `invalidateCache("inventory")` here any more: emptying the
        // cache on the tap broke the potion buttons on Hero/Arena until a
        // refetch. ShopService revalidates it in the background once the
        // server confirms.
        // NOTE: do NOT invalidate "quests" here. Nil-ing the cache before the
        // POST makes every ActiveQuestBanner refetch *pre-purchase* progress,
        // which could land after the post-purchase refresh and show stale
        // 0/N on the Big Spender banner (AUDIT-2026-10-13 H14). ShopService
        // refreshes quests stale-while-revalidate once the server confirms.

        // ── Fire API in background ──
        Task { [weak self] in
            guard let self else { return }
            defer {
                buyingItemIds.remove(item.id)
                if buyingItemId == item.id { buyingItemId = nil }
            }
            let success: Bool
            if isGemPack {
                success = await service.buyGems(catalogId: ct)
            } else if item.isConsumable, !ct.isEmpty {
                // Bug #20: pass quantity — backend /api/shop/buy-consumable
                // already supports bulk purchase in one atomic transaction.
                success = await service.buyConsumable(consumableType: ct, quantity: qty)
            } else {
                let catalogId = item.catalogId ?? item.id
                success = await service.buy(catalogId: catalogId)
            }

            if success {
                AnalyticsService.shared.track(.shopPurchase, [
                    "catalogId": .string(ct.isEmpty ? (item.catalogId ?? item.id) : ct),
                    "qty": .int(qty),
                    "kind": isGemPack ? "gem_pack" : (item.isConsumable ? "consumable" : "equipment"),
                ])
                // ShopService revalidates the inventory cache in the
                // background (stale-while-revalidate).
            } else {
                // Revert by DELTA (not by snapshot) so a second purchase made
                // while this one was in flight keeps its own deduction.
                appState.revertRewardCredit(spend)
                if let removedIndex, !items.contains(where: { $0.id == item.id }) {
                    items.insert(item, at: min(removedIndex, items.count))
                    cache.cacheShop(items)
                }
                if lastPurchasedItemId == item.id { lastPurchasedItemId = nil }
                // ShopService already showed the server's reason — a second
                // toast here would just replace it.
            }
        }
    }
}
