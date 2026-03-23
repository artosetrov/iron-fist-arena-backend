import SwiftUI

/// Static utility for equipment slot metadata.
/// Used by HeroIntegratedCard for slot matching and icon display.
enum EquipmentViewModel {
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
        "weapon": "swords", "helmet": "helmet", "chest": "shield",
        "gloves": "hand.raised", "legs": "pants", "boots": "shoe",
        "amulet": "pendant", "ring": "wand.and.stars", "ring2": "wand.and.stars",
        "belt": "square.and.line.vertical.and.square", "relic": "sparkles", "necklace": "pendant"
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
}
