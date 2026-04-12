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

    // Contraband (timed loot drops from "The Scavenger")
    var contrabandState: ContrabandUIState = .loading
    var isClaimingContraband = false

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
    var playerClass: String { appState.currentCharacter?.characterClass.rawValue ?? "warrior" }

    var filteredItems: [ShopItem] {
        let types = Self.tabTypes[selectedTab]
        if types.isEmpty { return equippableItems } // "All" tab
        return equippableItems.filter { types.contains($0.itemType) }
    }

    /// Items filtered by level and class restriction (base for all display)
    private var equippableItems: [ShopItem] {
        items.filter { item in
            if item.requiredLevel > playerLevel { return false }
            if let restriction = item.classRestriction, !restriction.isEmpty {
                return restriction == playerClass
            }
            return true
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
        // Load items, offers, and contraband in parallel
        async let itemsTask = service.getItems()
        async let offersTask: Void = loadOffers()
        async let contrabandTask: Void = loadContraband()
        let result = await itemsTask
        _ = await offersTask
        _ = await contrabandTask
        items = result
        cache.cacheShop(result)
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

    // MARK: - Contraband

    func loadContraband() async {
        guard let charId = appState.currentCharacter?.id else { return }
        do {
            let response: ContrabandResponse = try await APIClient.shared.get(
                APIEndpoints.shopContraband,
                params: ["character_id": charId]
            )
            contrabandState = ContrabandUIState.from(response)
        } catch {
            #if DEBUG
            print("[ShopVM] Failed to load contraband: \(error)")
            #endif
            contrabandState = .error
        }
    }

    func claimContraband() async {
        guard !isClaimingContraband else { return }
        guard let charId = appState.currentCharacter?.id else { return }

        // Check affordability for paid drops
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

        isClaimingContraband = true

        // Optimistic: deduct gold for paid drops
        let savedGold = appState.currentCharacter?.gold ?? 0
        let savedGems = appState.currentCharacter?.gems ?? 0

        if case .available(let offer) = contrabandState, !offer.isFree {
            appState.currentCharacter?.gold = savedGold - offer.price
        }
        HapticManager.success()

        defer { isClaimingContraband = false }
        do {
            let response: ContrabandClaimResponse = try await APIClient.shared.post(
                APIEndpoints.shopContraband,
                body: ["character_id": charId]
            )
            if response.success {
                appState.currentCharacter?.gold = response.gold
                appState.currentCharacter?.gems = response.gems
                appState.showToast("Contraband claimed!", type: .reward)
                // Reload to get cooldown state
                await loadContraband()
            } else {
                appState.currentCharacter?.gold = savedGold
                appState.currentCharacter?.gems = savedGems
                appState.showToast("Claim failed", type: .error)
            }
        } catch {
            appState.currentCharacter?.gold = savedGold
            appState.currentCharacter?.gems = savedGems
            appState.showToast("Claim failed", type: .error)
        }
    }

    var canAffordContraband: Bool {
        if case .available(let offer) = contrabandState {
            return offer.isFree || gold >= offer.price
        }
        return false
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
                    appState.currentCharacter?.gold = response.gold
                    appState.currentCharacter?.gems = response.gems
                    appState.showToast("Offer purchased!", type: .reward)
                    await loadOffers()
                } else {
                    // Revert
                    appState.currentCharacter?.gold = savedGold
                    appState.currentCharacter?.gems = savedGems
                    appState.showToast("Purchase failed", type: .error)
                }
            } catch {
                appState.currentCharacter?.gold = savedGold
                appState.currentCharacter?.gems = savedGems
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
        playerLevel >= item.requiredLevel
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
        appState.invalidateCache("quests")

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
                let toastMsg = qty > 1 ? "\(qty)× \(item.itemName) purchased!" : "Item purchased!"
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
