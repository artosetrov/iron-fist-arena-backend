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
    var isTwoHanded: Bool?

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

    // MARK: - Consumable Image Resolution

    /// Resolves imageKey for consumables — remaps legacy "pot_" keys and fills missing keys.
    /// Asset names match Supabase Storage (synced by sync-assets.sh).
    var resolvedImageKey: String? {
        // Non-consumables: return imageKey as-is
        if itemType != .consumable {
            return imageKey
        }

        // Remap legacy "pot_*" keys to Supabase asset names
        if let key = imageKey, !key.isEmpty {
            let remapped = Self.legacyKeyRemap[key]
            if remapped != nil { return remapped }
            return key
        }

        // No imageKey from backend — derive from consumableType
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

    /// Legacy imageKey → current Supabase asset name remap
    private static let legacyKeyRemap: [String: String] = [
        "pot_stamina_small": "stamina_potion_small",
        "pot_stamina_medium": "stamina_potion_medium",
        "pot_stamina_large": "stamina_potion_large",
        "pot_health_small": "health_potion_small",
        "pot_health_medium": "health_potion_medium",
        "pot_health_large": "health_potion_large",
    ]

    // MARK: - Consumable Icon Helpers

    /// SF Symbol name for consumable items based on consumableType
    var consumableIcon: String? {
        guard itemType == .consumable else { return nil }
        let ct = consumableType ?? catalogId ?? ""
        if ct.contains("gem_pack") { return "diamond.fill" }
        if ct.contains("health") { return "heart.fill" }
        if ct.contains("stamina") { return "bolt.fill" }
        return "cross.vial.fill"
    }

    /// Tint color for consumable SF Symbol
    var consumableIconColor: Color? {
        guard itemType == .consumable else { return nil }
        let ct = consumableType ?? catalogId ?? ""
        if ct.contains("gem_pack") { return DarkFantasyTheme.cyan }
        if ct.contains("health") { return DarkFantasyTheme.danger }
        if ct.contains("stamina") { return DarkFantasyTheme.success }
        return DarkFantasyTheme.goldBright
    }
}
