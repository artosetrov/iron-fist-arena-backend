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
            // BUG-62 (2026-04-11): merge only the equipment slice from
            // the server response — the /api/inventory/equip endpoint
            // returns `{ equipment: [...] }` (NO consumables). Previously
            // we replaced `items = updated` outright whenever the
            // equipped-id set disagreed with the optimistic prediction,
            // which silently erased every consumable (potions, gems…)
            // from inventory until the next full `loadInventory()`.
            // Now we keep existing consumables and replace only the
            // equipment part.
            mergeEquipmentResponse(updated)
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
            // BUG-62: merge only the equipment slice (see note in equip).
            mergeEquipmentResponse(updated)
        } else {
            items = previousItems
            appState.cachedInventory = previousItems
            appState.showToast("Failed to unequip", subtitle: "Inventory may be full", type: .error)
        }
    }

    /// Merge an equipment-only server response into `items`, preserving
    /// consumables. Skipped when the equipped-id set already matches the
    /// optimistic prediction AND the equipment rows are byte-equivalent —
    /// that's the happy path (most equips), and a no-op avoids a pointless
    /// full-grid re-render.
    private func mergeEquipmentResponse(_ serverEquipment: [Item]) {
        let consumables = items.filter { $0.itemType == .consumable }
        let currentEquipment = items.filter { $0.itemType != .consumable }

        // Fast equality: same count + same (id, isEquipped, equippedSlot,
        // durability, upgradeLevel) per id. Anything else means the server
        // changed something (auto-swap of two-handed weapon, corrected
        // ring slot, durability tick, upgrade, …) and we must apply it.
        let serverEquippedSet = Set(serverEquipment.filter { $0.isEquipped == true }.map(\.id))
        let optimisticEquippedSet = Set(currentEquipment.filter { $0.isEquipped == true }.map(\.id))

        if serverEquippedSet == optimisticEquippedSet &&
           serverEquipment.count == currentEquipment.count {
            // Optimistic prediction matches — skip the re-render entirely.
            appState.cachedInventory = items
            return
        }

        // Server disagreed with optimistic prediction: apply equipment
        // slice verbatim, keep consumables intact.
        let merged = serverEquipment + consumables
        items = merged
        appState.cachedInventory = merged
    }

    func sell(_ item: Item) async {
        // Optimistic UI: remove item + add gold immediately
        let previousItems = items
        let previousGold = appState.currentCharacter?.gold ?? 0
        let sellPrice = item.sellPrice ?? 0
        items.removeAll { $0.id == item.id }
        appState.currentCharacter?.gold = previousGold + sellPrice
        showItemDetail = false
        appState.showToast("Sold for \(sellPrice) gold", type: .reward)

        if let result = await service.sell(inventoryId: item.id) {
            // Server confirmed — sync authoritative gold
            appState.currentCharacter?.gold = result.gold
            appState.cachedInventory = items
        } else {
            // Rollback on failure
            items = previousItems
            appState.currentCharacter?.gold = previousGold
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

        // Optimistic stat update — estimate HP/stamina change immediately
        let previousHp = appState.currentCharacter?.currentHp ?? 0
        let previousStamina = appState.currentCharacter?.currentStamina ?? 0
        let isHealthPotion = item.consumableType?.contains("health_potion") == true
        let isStaminaPotion = item.consumableType?.contains("stamina_potion") == true

        if isHealthPotion, var char = appState.currentCharacter {
            let estimatedHeal = max(Int(Double(char.maxHp) * 0.3), 50)
            char.currentHp = min(char.currentHp + estimatedHeal, char.maxHp)
            appState.currentCharacter = char
        } else if isStaminaPotion, var char = appState.currentCharacter {
            let estimatedRestore = max(Int(Double(char.maxStamina) * 0.3), 20)
            char.currentStamina = min(char.currentStamina + estimatedRestore, char.maxStamina)
            appState.currentCharacter = char
        }

        HapticManager.success()
        appState.showToast("Used \(item.displayName)", type: .reward)

        // Fire API in background — revert on failure, server corrects stat values on success
        let itemId = item.id
        let consumableType = item.consumableType
        Task { [weak self] in
            let success = await self?.service.useItem(inventoryId: itemId, consumableType: consumableType) ?? false
            if !success {
                await MainActor.run {
                    self?.items = previousItems
                    self?.appState.cachedInventory = previousItems
                    // Revert optimistic stat changes
                    if isHealthPotion {
                        self?.appState.currentCharacter?.currentHp = previousHp
                    } else if isStaminaPotion {
                        self?.appState.currentCharacter?.currentStamina = previousStamina
                    }
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
        HapticManager.medium()

        // Upgrade must wait for server result (success/fail/level-change is server-authoritative)
        // But we dismiss UI instantly and show result as toast
        guard let result = await shopService.upgrade(inventoryId: item.id, useProtection: useProtection) else { return }
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
            HapticManager.success()
            appState.showToast("⬆ \(item.itemName) +\(result.newLevel)!", type: .reward)
        } else if result.protectionUsed {
            appState.showToast("Protected — level kept at +\(result.newLevel)", type: .info)
        } else if result.levelLost {
            HapticManager.error()
            appState.showToast("Failed! Dropped to +\(result.newLevel)", type: .error)
        } else {
            HapticManager.error()
            appState.showToast("Upgrade failed", subtitle: "Level unchanged", type: .error)
        }
    }

    private var repairingItemId: String?

    func repair(_ item: Item) {
        guard repairingItemId == nil else { return } // prevent double-tap
        repairingItemId = item.id
        showItemDetail = false

        // Optimistic: restore durability + deduct gold instantly
        let previousItems = items
        let previousGold = appState.currentCharacter?.gold ?? 0
        let repairCost = item.repairCost ?? 0

        items = items.map { existing in
            guard existing.id == item.id else { return existing }
            var updated = existing
            updated.durability = existing.maxDurability
            return updated
        }
        appState.cachedInventory = items
        if repairCost > 0 {
            appState.currentCharacter?.gold = max(0, previousGold - repairCost)
        }
        HapticManager.success()
        appState.showToast("Repaired!", type: .reward)

        // Fire API in background
        let itemId = item.id
        Task { [weak self] in
            guard let self else { return }
            defer { repairingItemId = nil }
            guard let result = await shopService.repair(inventoryId: itemId) else {
                // Revert on failure
                items = previousItems
                appState.cachedInventory = previousItems
                appState.currentCharacter?.gold = previousGold
                appState.showToast("Repair failed", type: .error)
                return
            }
            // Sync with server values
            items = items.map { existing in
                guard existing.id == itemId else { return existing }
                var updated = existing
                updated.durability = result.newDurability
                updated.maxDurability = result.maxDurability
                return updated
            }
            appState.cachedInventory = items
        }
    }

    // MARK: - Expand Inventory

    private var isExpanding = false

    func expandInventory() {
        guard !isExpanding else { return } // prevent double-tap
        guard canExpand else { return }
        guard gold >= expandCost else {
            appState.showToast("Not enough gold", subtitle: "Earn gold in arena or dungeons", type: .error)
            return
        }

        // Optimistic: increase slots + deduct gold instantly
        let previousSlots = totalSlots
        let previousGold = appState.currentCharacter?.gold ?? 0
        isExpanding = true
        totalSlots += 10
        appState.currentCharacter?.gold = max(0, previousGold - expandCost)
        HapticManager.success()
        appState.showToast("+10 inventory slots! Now: \(totalSlots)", type: .reward)

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            defer { isExpanding = false }
            if let newSlots = await service.expandInventory() {
                totalSlots = newSlots
            } else {
                // Revert on failure
                totalSlots = previousSlots
                appState.currentCharacter?.gold = previousGold
                appState.showToast("Failed to expand", type: .error)
            }
        }
    }

    // MARK: - Comparison

    func equippedItemInSlot(for item: Item) -> Item? {
        guard item.isEquipped != true else { return nil }
        return items.first { $0.isEquipped == true && $0.itemType == item.itemType }
    }

    // MARK: - Optimistic Helpers

    private func applyOptimisticEquip(_ item: Item) {
        // Unequip any existing item in the same slot, equip the new one.
        //
        // BUG-59 (QA 2026-04-10): also assign `equippedSlot` to the
        // canonical primary slot for the item's type. Without this the
        // render layer (IntegratedCharacterCard.findEquippedItem) fell
        // back to matching by accepted-types, and a weapon with a nil
        // slot appeared in BOTH the weapon slot and the "relic" universal
        // off-hand slot, duplicating the item visually.
        let canonicalSlot = Self.canonicalPrimarySlot(for: item.itemType.rawValue)
        items = items.map { existing in
            var updated = existing
            if existing.id == item.id {
                updated.isEquipped = true
                if updated.equippedSlot == nil, let canonicalSlot {
                    updated.equippedSlot = canonicalSlot
                }
            } else if existing.isEquipped == true && existing.itemType == item.itemType {
                updated.isEquipped = false
                updated.equippedSlot = nil
            }
            return updated
        }
    }

    private func applyOptimisticUnequip(_ item: Item) {
        items = items.map { existing in
            var updated = existing
            if existing.id == item.id {
                updated.isEquipped = false
                updated.equippedSlot = nil
            }
            return updated
        }
    }

    /// Mirror of `IntegratedCharacterCard.canonicalPrimarySlot` — picks
    /// the first slot in `EquipmentViewModel.slotOrder` that accepts the
    /// given item type. Kept local so the view model doesn't depend on
    /// the view layer.
    private static func canonicalPrimarySlot(for itemType: String) -> String? {
        for candidate in EquipmentViewModel.slotOrder {
            let accepted = EquipmentViewModel.slotAccepts[candidate] ?? [candidate]
            if accepted.contains(itemType) {
                return candidate
            }
        }
        return nil
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
