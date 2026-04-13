import SwiftUI

@MainActor @Observable
final class StashViewModel {
    private let appState: AppState
    private let service: StashService

    var items: [Item] = []
    var isLoading = false
    var maxSlots = 100
    var usedSlots = 0

    var selectedItem: Item?
    var showItemDetail = false

    // Sort
    var sortMode: InventorySortMode = .rarity

    init(appState: AppState) {
        self.appState = appState
        self.service = StashService(appState: appState)
    }

    // MARK: - Computed

    var sortedItems: [Item] {
        items.sorted { a, b in
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
                return a.id > b.id
            }
        }
    }

    var gridSlots: [InventorySlot] {
        let sorted = sortedItems
        var slots = sorted.enumerated().map { InventorySlot(index: $0.offset, item: $0.element) }
        let emptyCount = max(0, maxSlots - sorted.count)
        for i in 0..<emptyCount {
            slots.append(InventorySlot(index: sorted.count + i, item: nil))
        }
        return slots
    }

    // MARK: - Load

    func loadStash() async {
        if items.isEmpty { isLoading = true }
        if let response = await service.loadStash() {
            items = response.items
            maxSlots = response.maxSlots
            usedSlots = response.usedSlots
        }
        isLoading = false
    }

    // MARK: - Withdraw (Stash → Character Inventory)

    func withdraw(_ item: Item) async {
        // Optimistic UI — remove instantly, API in background with rollback
        let previousItems = items
        let previousUsedSlots = usedSlots
        items.removeAll { $0.id == item.id }
        usedSlots = items.count
        showItemDetail = false
        // Invalidate inventory cache so Hero screen reloads fresh
        appState.cachedInventory = nil
        appState.showToast("Withdrawn to inventory", type: .success)

        let success = await service.withdraw(stashItemId: item.id)
        if !success {
            // Rollback on failure
            items = previousItems
            usedSlots = previousUsedSlots
            appState.showToast("Failed to withdraw item", type: .error)
        }
    }

    // MARK: - Selection

    func selectItem(_ item: Item) {
        selectedItem = item
        showItemDetail = true
    }
}
