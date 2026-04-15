import Foundation
import SwiftUI

struct ShopItem: Codable, Identifiable {
    let id: String
    let catalogId: String?
    var itemName: String
    var itemType: String
    var rarity: ItemRarity
    var itemLevel: Int?
    var requiredLevel: Int
    var goldPrice: Int
    var gemPrice: Int
    var sellPrice: Int?
    var baseStats: [String: Int]?
    var description: String?
    var specialEffect: String?
    var uniquePassive: String?
    var setName: String?
    var consumableType: String?
    var classRestriction: String?
    var imageUrl: String?
    var imageKey: String?
    var isTwoHanded: Bool?
    // APIClient already converts snake_case -> camelCase.
    // Keep this DTO as plain camelCase to avoid double-conversion bugs.

    var isConsumable: Bool {
        itemType == "consumable" || itemType == "potion"
    }

    var displayPrice: String {
        if gemPrice > 0 {
            return "\(gemPrice) gems"
        }
        return "\(goldPrice) gold"
    }

    var isGemPurchase: Bool {
        gemPrice > 0
    }

    var typeEnum: ItemType? {
        ItemType(rawValue: itemType)
    }

    var typeIcon: String {
        typeEnum?.icon ?? "shippingbox.fill"
    }

    /// Resolves imageKey for consumables — remaps legacy "pot_" keys and fills missing keys.
    var resolvedImageKey: String? {
        if !isConsumable {
            return imageKey
        }
        return ConsumableCatalog.resolvedImageKey(
            consumableType: consumableType,
            catalogId: catalogId,
            imageKey: imageKey
        )
    }

    /// SF Symbol icon for consumable items
    var consumableIcon: String? {
        guard isConsumable else { return nil }
        return ConsumableCatalog.systemIcon(
            consumableType: consumableType,
            catalogId: catalogId,
            imageKey: imageKey
        ) ?? "cross.vial.fill"
    }

    /// Icon tint color for consumable items
    var consumableIconColor: Color? {
        guard isConsumable else { return nil }
        return ConsumableCatalog.systemIconColor(
            consumableType: consumableType,
            catalogId: catalogId,
            imageKey: imageKey
        ) ?? DarkFantasyTheme.goldBright
    }

    var level: Int {
        itemLevel ?? requiredLevel
    }

    var totalStats: [String: Int] {
        baseStats ?? [:]
    }

    /// Convert to Item for unified display in ItemDetailSheet
    func toItem() -> Item {
        Item(
            id: id,
            itemName: itemName,
            itemType: typeEnum ?? .accessory,
            rarity: rarity,
            itemLevel: level,
            upgradeLevel: nil,
            isEquipped: false,
            equippedSlot: nil,
            baseStats: baseStats,
            rolledStats: nil,
            buyPrice: goldPrice > 0 ? goldPrice : gemPrice,
            sellPrice: sellPrice,
            setName: setName,
            specialEffect: specialEffect,
            uniquePassive: uniquePassive,
            durability: nil,
            maxDurability: nil,
            description: description,
            catalogId: catalogId,
            classRestriction: classRestriction,
            imageUrl: imageUrl,
            imageKey: imageKey,
            quantity: nil,
            consumableType: consumableType,
            isTwoHanded: isTwoHanded
        )
    }
}
