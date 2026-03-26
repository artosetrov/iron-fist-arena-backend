import SwiftUI

@MainActor @Observable
final class InventoryViewModel {
    private let appState: AppState
    private let service: InventoryService
    private let shopService: ShopService

    var items: [Item] = []
    var isLoading = false
    var selectedItem: Item?
    var showItemDetail = false
    var totalSlots: Int = 28
    var errorMessage: String? = nil

    // Search & Sort
    var searchText = ""
    var sortMode: InventorySortMode = .rarity

    init(appState: AppState) {
        self.appState = appState
        self.service = InventoryService(appState: appState)
        self.shopService = ShopService(appState: appState)
        self.totalSlots = appState.currentCharacter?.inventorySlots ?? 28
    }

    var gold: Int { appState.currentCharacter?.gold ?? 0 }
    var canExpand: Bool { totalSlots < 58 } // 28 + 3*10
    let expandCost = 5000

    var sortedItems: [Item] {
        var result = items.filter { $0.isEquipped != true }

        // Filter by search text
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.displayName.lowercased().contains(q) ||
                $0.rarity.rawValue.lowercased().contains(q) ||
                $0.itemType.rawValue.lowercased().contains(q)
            }
        }

        // Sort
        return result.sorted { a, b in
            switch sortMode {
            case .rarity:
                let aR = Item.rarityOrder[a.rarity] ?? 0
                let bR = Item.rarityOrder[b.rarity] ?? 0
                if aR != bR { return aR > bR }
                return a.itemLevel > b.itemLevel
            case .level:
                if a.itemLevel != b.itemLevel { return a.itemLevel > b.itemLevel }
                return (Item.rarityOrder[a.rarity] ?? 0) > (Item.rarityOrder[b.rarity] ?? 0)
            case .type:
                if a.itemType != b.itemType { return a.itemType.rawValue < b.itemType.rawValue }
                return (Item.rarityOrder[a.rarity] ?? 0) > (Item.rarityOrder[b.rarity] ?? 0)
            case .newest:
                return a.id > b.id  // IDs are chronological UUIDs
            }
        }
    }

    /// Currently equipped item per slot — used for comparison indicators
    var equippedBySlot: [String: Item] {
        var map: [String: Item] = [:]
        for item in items where item.isEquipped == true {
            map[item.equipSlot] = item
        }
        return map
    }

    /// Grid slots: items + empty placeholders up to totalSlots
    var gridSlots: [InventorySlot] {
        let sorted = sortedItems
        var slots = sorted.enumerated().map { InventorySlot(index: $0.offset, item: $0.element) }
        let emptyCount = max(0, totalSlots - sorted.count)
        for i in 0..<emptyCount {
            slots.append(InventorySlot(index: sorted.count + i, item: nil))
        }
        return slots
    }

    // MARK: - Load

    func loadInventory() async {
        // Serve cached inventory instantly if available
        if let cached = appState.cachedInventory, items.isEmpty {
            items = cached
        } else if items.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        let result = await service.loadInventory()
        items = result
        totalSlots = appState.currentCharacter?.inventorySlots ?? 28
        appState.cachedInventory = result
        isLoading = false
    }

    // MARK: - Actions

    func selectItem(_ item: Item) {
        selectedItem = item
        showItemDetail = true
    }

    func equip(_ item: Item) async {
        // Optimistic UI: update immediately
        let previousItems = items
        applyOptimisticEquip(item)
        appState.cachedInventory = items
        showItemDetail = false
        appState.showToast("Equipped \(item.displayName)", type: .reward)

        if let updated = await service.equip(inventoryId: item.id) {
            // Only update if server response differs from optimistic state
            // to avoid the flicker of item disappearing then reappearing
            appState.cachedInventory = updated
            items = updated
        } else {
            // Rollback on failure
            items = previousItems
            appState.cachedInventory = previousItems
            appState.showToast("Failed to equip", subtitle: "Check class or level requirements", type: .error)
        }
    }

    func unequip(_ item: Item) async {
        // Optimistic UI: update immediately
        let previousItems = items
        applyOptimisticUnequip(item)
        appState.cachedInventory = items
        showItemDetail = false
        appState.showToast("Unequipped \(item.displayName)", type: .info)

        if let updated = await service.unequip(inventoryId: item.id) {
            appState.cachedInventory = updated
            items = updated
        } else {
            items = previousItems
            appState.cachedInventory = previousItems
            appState.showToast("Failed to unequip", subtitle: "Inventory may be full", type: .error)
        }
    }

    func sell(_ item: Item) async {
        // Optimistic UI: remove item immediately
        let previousItems = items
        let sellPrice = item.sellPrice ?? 0
        items.removeAll { $0.id == item.id }
        showItemDetail = false
        appState.showToast("Sold for \(sellPrice) gold", type: .reward)

        if let result = await service.sell(inventoryId: item.id) {
            // Server confirmed — update gold, keep local state (no full reload)
            appState.currentCharacter?.gold = result.gold
            appState.cachedInventory = items
        } else {
            // Rollback on failure
            items = previousItems
            appState.cachedInventory = previousItems
            appState.showToast("Failed to sell", subtitle: "Unequip the item first", type: .error)
        }
    }

    func useItem(_ item: Item) async {
        showItemDetail = false

        // Optimistic UI — update inventory instantly
        let previousItems = items
        if let qty = item.quantity, qty > 1 {
            items = items.map { existing in
                guard existing.id == item.id else { return existing }
                var updated = existing
                updated.quantity = qty - 1
                return updated
            }
        } else {
            items.removeAll { $0.id == item.id }
        }
        appState.cachedInventory = items
        HapticManager.success()
        appState.showToast("Used \(item.displayName)", type: .reward)

        // Fire API in background — revert on failure
        let itemId = item.id
        let consumableType = item.consumableType
        Task { [weak self] in
            let success = await self?.service.useItem(inventoryId: itemId, consumableType: consumableType) ?? false
            if !success {
                await MainActor.run {
                    self?.items = previousItems
                    self?.appState.cachedInventory = previousItems
                }
            } else {
                await MainActor.run {
                    self?.appState.invalidateCache("quests")
                }
            }
        }
    }

    func upgrade(_ item: Item, useProtection: Bool) async {
        showItemDetail = false
        guard let result = await shopService.upgrade(inventoryId: item.id, useProtection: useProtection) else { return }
        // Update the item's upgradeLevel in local array
        items = items.map { existing in
            guard existing.id == item.id else { return existing }
            var updated = existing
            updated.upgradeLevel = result.newLevel
            return updated
        }
        appState.cachedInventory = items
        appState.invalidateCache("quests")
        if result.success {
            SFXManager.shared.play(.uiUpgradeSuccess)
            appState.showToast("⬆ \(item.itemName) +\(result.newLevel)!", type: .reward)
        } else if result.protectionUsed {
            appState.showToast("Protected — level kept at +\(result.newLevel)", type: .info)
        } else if result.levelLost {
            appState.showToast("❌ Failed! Dropped to +\(result.newLevel)", type: .error)
        } else {
            appState.showToast("❌ Upgrade failed", subtitle: "Level unchanged", type: .error)
        }
    }

    func repair(_ item: Item) async {
        showItemDetail = false
        guard let result = await shopService.repair(inventoryId: item.id) else { return }
        items = items.map { existing in
            guard existing.id == item.id else { return existing }
            var updated = existing
            updated.durability = result.newDurability
            updated.maxDurability = result.maxDurability
            return updated
        }
        appState.cachedInventory = items
        appState.showToast("Repaired for \(result.repairCost) gold", type: .reward)
    }

    // MARK: - Expand Inventory

    func expandInventory() async {
        guard canExpand else { return }
        guard gold >= expandCost else {
            appState.showToast("Not enough gold", subtitle: "Earn gold in arena or dungeons", type: .error)
            return
        }
        if let newSlots = await service.expandInventory() {
            totalSlots = newSlots
            appState.showToast("+10 inventory slots! Now: \(newSlots)", type: .reward)
        }
    }

    // MARK: - Comparison

    func equippedItemInSlot(for item: Item) -> Item? {
        guard item.isEquipped != true else { return nil }
        return items.first { $0.isEquipped == true && $0.itemType == item.itemType }
    }

    // MARK: - Optimistic Helpers

    private func applyOptimisticEquip(_ item: Item) {
        // Unequip any existing item in the same slot, equip the new one
        items = items.map { existing in
            var updated = existing
            if existing.id == item.id {
                updated.isEquipped = true
            } else if existing.isEquipped == true && existing.itemType == item.itemType {
                updated.isEquipped = false
            }
            return updated
        }
    }

    private func applyOptimisticUnequip(_ item: Item) {
        items = items.map { existing in
            var updated = existing
            if existing.id == item.id {
                updated.isEquipped = false
            }
            return updated
        }
    }
}

// MARK: - Inventory Slot

struct InventorySlot: Identifiable {
    let index: Int
    let item: Item?
    var id: String { item?.id ?? "empty_\(index)" }
}

// MARK: - Sort Mode

enum InventorySortMode: String, CaseIterable {
    case rarity = "Rarity"
    case level = "Level"
    case type = "Type"
    case newest = "Newest"

    var icon: String {
        switch self {
        case .rarity: "star.fill"
        case .level: "arrow.up.right"
        case .type: "square.grid.2x2"
        case .newest: "clock"
        }
    }
}
