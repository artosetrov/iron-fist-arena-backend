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
    var authoritativeEffectiveStats: [String: Int]? = nil

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

    /// Stats including upgrade bonus. Prefer the authoritative server snapshot
    /// when present; otherwise fall back to the local legacy computation.
    var effectiveStats: [String: Int] {
        if let authoritativeEffectiveStats, !authoritativeEffectiveStats.isEmpty {
            return authoritativeEffectiveStats
        }

        let base = totalStats
        let level = upgradeLevel ?? 0
        guard level > 0 else { return base }
        var result: [String: Int] = [:]
        for (key, val) in base {
            result[key] = val + level
        }
        return result
    }

    /// The total upgrade bonus currently applied per stat.
    var upgradeBonusPerStat: Int {
        if let authoritativeEffectiveStats,
           let baseStats,
           let level = upgradeLevel,
           level > 0 {
            for key in authoritativeEffectiveStats.keys.sorted() {
                if let baseValue = baseStats[key],
                   let effectiveValue = authoritativeEffectiveStats[key] {
                    return max(0, effectiveValue - baseValue)
                }
            }
        }
        return upgradeLevel ?? 0
    }

    /// Best-effort preview for the next upgrade step per stat.
    /// When the item already carries authoritative stats from the backend,
    /// derive the per-level increment from them; otherwise use the legacy +1 fallback.
    var upgradeIncrementPerStat: Int {
        if let level = upgradeLevel, level > 0 {
            let totalBonus = upgradeBonusPerStat
            return max(1, totalBonus / level)
        }
        return 1
    }

    /// Sum of all effective stats — used for quick power comparison
    var totalPower: Int {
        effectiveStats.values.reduce(0, +)
    }

    /// Estimated gold cost to repair this item (2g per missing durability point)
    var repairCost: Int? {
        guard let dur = durability, let maxDur = maxDurability, dur < maxDur else { return nil }
        return (maxDur - dur) * 2
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
        return ConsumableCatalog.resolvedImageKey(
            consumableType: consumableType,
            catalogId: catalogId,
            imageKey: imageKey
        )
    }

    // MARK: - Consumable Icon Helpers

    /// SF Symbol name for consumable items based on consumableType
    var consumableIcon: String? {
        guard itemType == .consumable else { return nil }
        return ConsumableCatalog.systemIcon(
            consumableType: consumableType,
            catalogId: catalogId,
            imageKey: imageKey
        ) ?? "cross.vial.fill"
    }

    /// Tint color for consumable SF Symbol
    var consumableIconColor: Color? {
        guard itemType == .consumable else { return nil }
        return ConsumableCatalog.systemIconColor(
            consumableType: consumableType,
            catalogId: catalogId,
            imageKey: imageKey
        ) ?? DarkFantasyTheme.goldBright
    }
}
