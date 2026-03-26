import SwiftUI

struct ShopSection: Identifiable {
    let id: String
    let title: String
    let icon: String
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

    var filteredItems: [ShopItem] {
        let types = Self.tabTypes[selectedTab]
        if types.isEmpty { return items } // "All" tab
        return items.filter { types.contains($0.itemType) }
    }

    var sectionedItems: [ShopSection] {
        let weaponTypes = Self.tabTypes[1]
        let equipmentTypes = Self.tabTypes[2]
        let potionTypes = Self.tabTypes[3]

        let weapons = items.filter { weaponTypes.contains($0.itemType) }
        let equipment = items.filter { equipmentTypes.contains($0.itemType) }
        let gemPacks = items.filter { ($0.consumableType ?? $0.catalogId ?? "").hasPrefix("gem_pack_") }
        let potions = items.filter {
            potionTypes.contains($0.itemType) && !($0.consumableType ?? $0.catalogId ?? "").hasPrefix("gem_pack_")
        }

        var sections: [ShopSection] = []
        if !weapons.isEmpty {
            sections.append(ShopSection(id: "weapons", title: "Weapons", icon: "swords", items: weapons))
        }
        if !equipment.isEmpty {
            sections.append(ShopSection(id: "equipment", title: "Equipment", icon: "shield", items: equipment))
        }
        if !potions.isEmpty {
            sections.append(ShopSection(id: "potions", title: "Potions", icon: "pills", items: potions))
        }
        if !gemPacks.isEmpty {
            sections.append(ShopSection(id: "gems", title: "Gems", icon: "diamond", items: gemPacks))
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
        let result = await itemsTask
        _ = await offersTask
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

    func canAffordOffer(_ offer: ShopOffer) -> Bool {
        if offer.isGemPurchase {
            return gems >= offer.salePrice
        }
        return gold >= offer.salePrice
    }

    func buyOffer(_ offer: ShopOffer) async {
        guard let charId = appState.currentCharacter?.id else { return }
        guard offer.canPurchase else {
            appState.showToast("Purchase limit reached!", type: .error)
            return
        }
        guard canAffordOffer(offer) else {
            appState.showToast(
                offer.isGemPurchase ? "Not enough gems!" : "Not enough gold!",
                type: .error,
                actionLabel: "GET MORE",
                action: { [weak appState] in
                    appState?.mainPath.append(AppRoute.currencyPurchase)
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
        appState.showToast("Purchased \(offer.title)!", type: .reward)
        buyingOfferId = nil

        // ── Fire API in background ──
        Task { [weak self] in
            guard let self else { return }
            do {
                let response: OfferPurchaseResponse = try await APIClient.shared.post(
                    APIEndpoints.shopOffers,
                    body: ["character_id": charId, "offer_id": offer.id]
                )
                if response.success {
                    appState.currentCharacter?.gold = response.gold
                    appState.currentCharacter?.gems = response.gems
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
    func requestBuy(_ item: ShopItem) {
        if item.isGemPurchase {
            pendingPurchaseItem = item
            showPurchaseConfirm = true
        } else {
            Task { await buy(item) }
        }
    }

    func confirmPendingPurchase() {
        guard let item = pendingPurchaseItem else { return }
        pendingPurchaseItem = nil
        showPurchaseConfirm = false
        Task { await buy(item) }
    }

    func cancelPendingPurchase() {
        pendingPurchaseItem = nil
        showPurchaseConfirm = false
    }

    func buy(_ item: ShopItem) async {
        // Validate currency
        if !canAfford(item) {
            HapticManager.error()
            appState.showToast(
                item.isGemPurchase ? "Not enough gems!" : "Not enough gold!",
                type: .error,
                actionLabel: "GET MORE",
                action: { [weak appState] in
                    appState?.mainPath.append(AppRoute.currencyPurchase)
                }
            )
            return
        }

        // ── Optimistic UI: update instantly ──
        let savedGold = appState.currentCharacter?.gold ?? 0
        let savedGems = appState.currentCharacter?.gems ?? 0
        let savedItems = items

        // Deduct currency optimistically
        if item.isGemPurchase {
            appState.currentCharacter?.gems = savedGems - item.gemPrice
        } else {
            appState.currentCharacter?.gold = savedGold - item.goldPrice
        }

        // Remove from list immediately (equipment only)
        if !item.isConsumable {
            items.removeAll { $0.id == item.id }
        }

        HapticManager.success()
        showItemDetail = false
        selectedItem = nil
        lastPurchasedItemId = item.id
        appState.showToast("Purchased \(item.itemName)!", type: .reward)
        appState.invalidateCache("inventory")
        appState.invalidateCache("quests")

        // ── Fire API in background ──
        buyingItemId = nil
        let ct = item.consumableType ?? item.catalogId ?? ""
        Task { [weak self] in
            guard let self else { return }
            let success: Bool
            if ct.hasPrefix("gem_pack_") {
                let gemsAmount: Int
                switch ct {
                case "gem_pack_small": gemsAmount = 10
                case "gem_pack_medium": gemsAmount = 50
                case "gem_pack_large": gemsAmount = 100
                default: gemsAmount = 10
                }
                success = await service.buyGems(gemsAmount: gemsAmount)
            } else if item.isConsumable, !ct.isEmpty {
                success = await service.buyConsumable(consumableType: ct)
            } else {
                let catalogId = item.catalogId ?? item.id
                success = await service.buy(catalogId: catalogId)
            }

            if !success {
                // Revert optimistic state
                appState.currentCharacter?.gold = savedGold
                appState.currentCharacter?.gems = savedGems
                items = savedItems
                lastPurchasedItemId = nil
                appState.showToast("Purchase failed", subtitle: "Gold refunded", type: .error)
            }
        }
    }
}
