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

    enum CodingKeys: String, CodingKey {
        case id
        case catalogId = "catalog_id"
        case itemName = "item_name"
        case itemType = "item_type"
        case rarity
        case itemLevel = "item_level"
        case requiredLevel = "required_level"
        case goldPrice = "gold_price"
        case gemPrice = "gem_price"
        case sellPrice = "sell_price"
        case baseStats = "base_stats"
        case description
        case specialEffect = "special_effect"
        case uniquePassive = "unique_passive"
        case setName = "set_name"
        case consumableType = "consumable_type"
        case classRestriction = "class_restriction"
        case imageUrl = "image_url"
        case imageKey = "image_key"
        case isTwoHanded = "is_two_handed"
    }

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
        typeEnum?.icon ?? "📦"
    }

    /// Resolves imageKey for consumables — remaps legacy "pot_" keys and fills missing keys.
    var resolvedImageKey: String? {
        if !isConsumable {
            return imageKey
        }

        // Remap legacy "pot_*" keys
        if let key = imageKey, !key.isEmpty {
            let remapped = Self.legacyKeyRemap[key]
            if remapped != nil { return remapped }
            return key
        }

        // Derive from consumableType
        let ct = consumableType ?? catalogId ?? ""
        if ct.contains("stamina") && ct.contains("large") { return "stamina_potion_large" }
        if ct.contains("stamina") && ct.contains("medium") { return "stamina_potion_medium" }
        if ct.contains("stamina") { return "stamina_potion_small" }
        if ct.contains("health") && ct.contains("large") { return "health_potion_large" }
        if ct.contains("health") && ct.contains("medium") { return "health_potion_medium" }
        if ct.contains("health") { return "health_potion_small" }
        if ct.contains("gem_pack") && ct.contains("large") { return "gem_pack_large" }
        if ct.contains("gem_pack") && ct.contains("medium") { return "gem_pack_medium" }
        if ct.contains("gem_pack") { return "gem_pack_small" }
        return nil
    }

    private static let legacyKeyRemap: [String: String] = [
        "pot_stamina_small": "stamina_potion_small",
        "pot_stamina_medium": "stamina_potion_medium",
        "pot_stamina_large": "stamina_potion_large",
        "pot_health_small": "health_potion_small",
        "pot_health_medium": "health_potion_medium",
        "pot_health_large": "health_potion_large",
    ]

    /// SF Symbol icon for consumable items
    var consumableIcon: String? {
        guard isConsumable else { return nil }
        let ct = consumableType ?? catalogId ?? ""
        if ct.contains("gem_pack") { return "diamond.fill" }
        if ct.contains("health") { return "heart.fill" }
        if ct.contains("stamina") { return "bolt.fill" }
        return "cross.vial.fill"
    }

    /// Icon tint color for consumable items
    var consumableIconColor: Color? {
        guard isConsumable else { return nil }
        let ct = consumableType ?? catalogId ?? ""
        if ct.contains("gem_pack") { return DarkFantasyTheme.cyan }
        if ct.contains("health") { return DarkFantasyTheme.danger }
        if ct.contains("stamina") { return DarkFantasyTheme.success }
        return DarkFantasyTheme.goldBright
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
