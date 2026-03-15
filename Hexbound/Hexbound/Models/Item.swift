import Foundation
import SwiftUI

struct Item: Codable, Identifiable {
    let id: String
    var itemName: String
    var itemType: ItemType
    var rarity: ItemRarity
    var itemLevel: Int
    var upgradeLevel: Int?
    var isEquipped: Bool?
    var equippedSlot: String?
    var baseStats: [String: Int]?
    var rolledStats: [String: Int]?
    var buyPrice: Int?
    var sellPrice: Int?
    var setName: String?
    var specialEffect: String?
    var uniquePassive: String?
    var durability: Int?
    var maxDurability: Int?
    var description: String?
    var catalogId: String?
    var classRestriction: String?
    var imageUrl: String?
    var imageKey: String?
    var quantity: Int?
    var consumableType: String?

    // No CodingKeys needed — Prisma sends camelCase which matches
    // Swift property names directly (itemName, itemType, etc.)

    var displayName: String {
        if let level = upgradeLevel, level > 0 {
            return "\(itemName) +\(level)"
        }
        return itemName
    }

    var totalStats: [String: Int] {
        var stats: [String: Int] = [:]
        if let base = baseStats {
            for (key, val) in base { stats[key, default: 0] += val }
        }
        if let rolled = rolledStats {
            for (key, val) in rolled { stats[key, default: 0] += val }
        }
        return stats
    }

    /// Stats including upgrade bonus (+1 per upgrade level per stat that exists on the item)
    var effectiveStats: [String: Int] {
        let base = totalStats
        let level = upgradeLevel ?? 0
        guard level > 0 else { return base }
        var result: [String: Int] = [:]
        for (key, val) in base {
            result[key] = val + level
        }
        return result
    }

    /// The total upgrade bonus per stat (upgradeLevel × 1)
    var upgradeBonusPerStat: Int {
        upgradeLevel ?? 0
    }

    /// Sum of all effective stats — used for quick power comparison
    var totalPower: Int {
        effectiveStats.values.reduce(0, +)
    }

    /// Slot this item can go in (uses equippedSlot if set, otherwise derives from itemType)
    var equipSlot: String {
        if let slot = equippedSlot, !slot.isEmpty { return slot }
        return itemType.rawValue
    }

    /// Stat key → full display label mapping
    static let statLabels: [String: String] = [
        "str": "Strength", "agi": "Agility", "vit": "Vitality", "end": "Endurance",
        "int": "Intelligence", "wis": "Wisdom", "luk": "Luck", "cha": "Charisma",
        "damageMin": "Min Damage", "damageMax": "Max Damage",
        "critChance": "Crit Chance", "attackSpeed": "Attack Speed",
        "defense": "Defense", "hpBonus": "HP Bonus", "manaBonus": "Mana Bonus",
    ]

    static let rarityOrder: [ItemRarity: Int] = [
        .common: 1, .uncommon: 2, .rare: 3, .epic: 4, .legendary: 5
    ]

    // MARK: - Consumable Icon Helpers

    /// SF Symbol name for consumable items based on consumableType
    var consumableIcon: String? {
        guard itemType == .consumable else { return nil }
        let ct = consumableType ?? ""
        if ct.contains("gem_pack") { return "diamond.fill" }
        if ct.contains("health") { return "heart.fill" }
        if ct.contains("stamina") { return "bolt.fill" }
        return "flask.fill"
    }

    /// Tint color for consumable SF Symbol
    var consumableIconColor: Color? {
        guard itemType == .consumable else { return nil }
        let ct = consumableType ?? ""
        if ct.contains("gem_pack") { return .cyan }
        if ct.contains("health") { return .red }
        if ct.contains("stamina") { return .green }
        return .yellow
    }
}
