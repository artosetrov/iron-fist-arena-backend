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
        if let cached = cache.cachedShop() {
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
        let savedGold = appState.currentCharacter?.gold ?? 0
        let savedGems = appState.currentCharacter?.gems ?? 0

        if offer.isGemPurchase {
            appState.currentCharacter?.gems = savedGems - offer.salePrice
        } else {
            appState.currentCharacter?.gold = savedGold - offer.salePrice
        }
        HapticManager.success()

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
                    // Show reward modal with the offer's contents
                    claimRewardConfig = .fromOfferContents(
                        title: "CLAIMED!",
                        subtitle: offer.title,
                        contents: offer.contents
                    )
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
                    if var char = appState.currentCharacter {
                        char.gold = savedGold; char.gems = savedGems
                        appState.currentCharacter = char
                    }
                    appState.showToast("Purchase failed", type: .error)
                }
            } catch {
                if var char = appState.currentCharacter {
                    char.gold = savedGold; char.gems = savedGems
                    appState.currentCharacter = char
                }
                appState.showToast("Purchase failed", type: .error)
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
        guard buyingItemId == nil else { return } // double-tap guard

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

        buyingItemId = item.id

        // ── Optimistic UI: update instantly ──
        let savedGold = appState.currentCharacter?.gold ?? 0
        let savedGems = appState.currentCharacter?.gems ?? 0
        let savedItems = items

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
        // Use a fresh struct copy + reassignment so @Observable reliably
        // notifies every view reading `currentCharacter.gold/gems` — optional
        // chain mutation on a struct property has been flaky in practice.
        if var char = appState.currentCharacter {
            if item.isGemPurchase {
                char.gems = savedGems - totalCost
            } else {
                char.gold = savedGold - totalCost
                if isGemPack {
                    // Credit the gems immediately — server response will overwrite
                    // with authoritative values a moment later.
                    char.gems = savedGems + gemPackGemsAmount
                }
            }
            appState.currentCharacter = char
        }

        // Remove from list immediately (equipment only)
        if !item.isConsumable {
            items.removeAll { $0.id == item.id }
        }

        HapticManager.success()
        SFXManager.shared.play(.coinsJingle)
        SFXManager.shared.play(.pouchDrop)
        showItemDetail = false
        selectedItem = nil
        lastPurchasedItemId = item.id
        appState.invalidateCache("inventory")
        // NOTE: do NOT invalidate "quests" here. Nil-ing the cache before the
        // POST makes every ActiveQuestBanner refetch *pre-purchase* progress,
        // which could land after the post-purchase refresh and show stale
        // 0/N on the Big Spender banner (AUDIT-2026-10-13 H14). ShopService
        // refreshes quests stale-while-revalidate once the server confirms.

        // ── Fire API in background ──
        Task { [weak self] in
            guard let self else { return }
            defer { buyingItemId = nil }
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
                let toastMsg = qty > 1 ? "\(qty)× \(item.itemName) purchased!" : "\(item.itemName) purchased!"
                appState.showToast(toastMsg, type: .reward)
            } else {
                // Revert optimistic state using a fresh struct copy for the
                // same @Observable-reliable notification reason as the deduct.
                if var char = appState.currentCharacter {
                    char.gold = savedGold
                    char.gems = savedGems
                    appState.currentCharacter = char
                }
                items = savedItems
                lastPurchasedItemId = nil
                appState.showToast("Purchase failed", subtitle: "Gold refunded", type: .error)
            }
        }
    }
}
