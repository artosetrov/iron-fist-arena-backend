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
    var imageUrl: String?
    var imageKey: String?

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
        case imageUrl = "image_url"
        case imageKey = "image_key"
    }

    var isConsumable: Bool {
        itemType == "consumable" || itemType == "potion"
    }

    var displayPrice: String {
        if gemPrice > 0 {
            return "\(gemPrice) 💎"
        }
        return "\(goldPrice) 💰"
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

    /// SF Symbol icon for consumable items
    var consumableIcon: String? {
        guard isConsumable else { return nil }
        let ct = consumableType ?? catalogId ?? ""
        if ct.contains("gem_pack") { return "diamond.fill" }
        if ct.contains("health") { return "heart.fill" }
        if ct.contains("stamina") { return "bolt.fill" }
        return "flask.fill"
    }

    /// Icon tint color for consumable items
    var consumableIconColor: Color? {
        guard isConsumable else { return nil }
        let ct = consumableType ?? catalogId ?? ""
        if ct.contains("gem_pack") { return .cyan }
        if ct.contains("health") { return .red }
        if ct.contains("stamina") { return .green }
        return .yellow
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
            classRestriction: nil,
            imageUrl: imageUrl,
            imageKey: imageKey,
            quantity: nil,
            consumableType: consumableType
        )
    }
}
