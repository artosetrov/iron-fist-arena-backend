import SwiftUI

@MainActor @Observable
final class EquipmentViewModel {
    private let appState: AppState
    private let service: InventoryService

    var items: [Item] = []
    var isLoading = false
    var selectedItem: Item?
    var showItemDetail = false

    static let slotOrder = [
        "helmet", "amulet",
        "chest", "gloves",
        "legs", "boots",
        "belt", "necklace",
        "ring", "ring2",
        "weapon", "relic"
    ]

    static let slotLabels: [String: String] = [
        "weapon": "Weapon", "helmet": "Helmet", "chest": "Chest",
        "gloves": "Gloves", "legs": "Pants", "boots": "Boots",
        "amulet": "Amulet", "ring": "Ring", "ring2": "Ring",
        "belt": "Belt", "relic": "Relic", "necklace": "Necklace"
    ]

    static let slotIcons: [String: String] = [
        "weapon": "⚔️", "helmet": "🪖", "chest": "🛡️",
        "gloves": "🧤", "legs": "👖", "boots": "👢",
        "amulet": "📿", "ring": "💍", "ring2": "💍",
        "belt": "🪢", "relic": "🔮", "necklace": "📿"
    ]

    static let slotAssets: [String: String] = [
        "weapon": "icon-weapon-offhand", "helmet": "icon-helmet", "chest": "icon-chest",
        "gloves": "icon-gloves", "legs": "icon-legs", "boots": "icon-boots",
        "amulet": "icon-amulet", "ring": "icon-ring", "ring2": "icon-ring",
        "belt": "icon-belt", "relic": "icon-relic", "necklace": "icon-amulet"
    ]

    /// Universal slots: which item types each visual slot accepts
    static let slotAccepts: [String: [String]] = [
        "helmet": ["helmet"],
        "chest":  ["chest"],
        "legs":   ["legs"],
        "amulet": ["amulet", "necklace"],          // UNIVERSAL: amulet OR necklace
        "gloves": ["gloves"],
        "boots":  ["boots"],
        "ring":   ["ring"],                         // ring + ring2 via dual logic
        "weapon": ["weapon"],
        "relic":  ["relic", "accessory", "weapon"], // UNIVERSAL: off-hand
        "belt":   ["belt"],
    ]

    init(appState: AppState) {
        self.appState = appState
        self.service = InventoryService(appState: appState)
    }

    var equippedItems: [Item] {
        items.filter { $0.isEquipped == true }
    }

    func equippedIn(slot: String) -> Item? {
        switch slot {
        case "ring":
            return equippedItems.first { $0.equippedSlot == "ring" }
        case "ring2":
            return equippedItems.first { $0.equippedSlot == "ring2" }
        case "belt":
            return equippedItems.first { $0.equippedSlot == "belt" || $0.itemType == .belt }
        case "relic":
            return equippedItems.first { $0.equippedSlot == "relic" || $0.itemType == .relic }
        case "necklace":
            return equippedItems.first { $0.equippedSlot == "necklace" || $0.itemType == .necklace }
        default:
            return equippedItems.first { $0.equippedSlot == slot || $0.itemType.rawValue == slot }
        }
    }

    var totalBonuses: [String: Int] {
        var stats: [String: Int] = [:]
        for item in equippedItems {
            for (key, val) in item.totalStats {
                stats[key, default: 0] += val
            }
        }
        return stats
    }

    // MARK: - Load

    func loadEquipment() async {
        // Show cached inventory instantly, refresh in background
        if let cached = appState.cachedInventory, items.isEmpty {
            items = cached
        } else {
            isLoading = true
        }
        let result = await service.loadInventory()
        items = result
        isLoading = false
    }

    // MARK: - Actions

    func selectItem(_ item: Item) {
        selectedItem = item
        showItemDetail = true
    }

    func unequip(_ item: Item) async {
        if let updated = await service.unequip(inventoryId: item.id) {
            items = updated
            showItemDetail = false
            appState.showToast("Unequipped \(item.displayName)", type: .info)
        }
    }
}
