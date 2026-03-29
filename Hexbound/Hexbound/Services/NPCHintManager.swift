import SwiftUI

// MARK: - NPC Hint Manager

/// Manages one-time NPC guide hints shown on first visit to each screen.
/// Persists seen hints in UserDefaults — each hint shows only once per character.
@MainActor @Observable
final class NPCHintManager {
    static let shared = NPCHintManager()

    /// Currently visible hint (nil = no hint showing)
    var activeHint: NPCHint?

    private let defaults = UserDefaults.standard
    private let prefix = "npc_hint_seen_"

    private init() {}

    // MARK: - Show / Dismiss

    /// Attempts to show a hint. Returns true if shown, false if already seen.
    @discardableResult
    func tryShow(_ hint: NPCHint, for characterId: String) -> Bool {
        let key = "\(prefix)\(characterId)_\(hint.id)"
        guard !defaults.bool(forKey: key) else { return false }
        withAnimation(.easeInOut(duration: 0.3)) {
            activeHint = hint
        }
        return true
    }

    /// Dismiss current hint and mark as seen
    func dismiss(for characterId: String) {
        guard let hint = activeHint else { return }
        let key = "\(prefix)\(characterId)_\(hint.id)"
        defaults.set(true, forKey: key)
        withAnimation(.easeInOut(duration: 0.25)) {
            activeHint = nil
        }
    }

    /// Dismiss and skip ALL remaining hints for this character
    func skipAll(for characterId: String) {
        // Mark all defined hints as seen
        for hint in NPCHint.allHints {
            let key = "\(prefix)\(characterId)_\(hint.id)"
            defaults.set(true, forKey: key)
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            activeHint = nil
        }
    }

    /// Check if a specific hint has been seen
    func hasSeen(_ hintId: String, for characterId: String) -> Bool {
        let key = "\(prefix)\(characterId)_\(hintId)"
        return defaults.bool(forKey: key)
    }

    /// Reset all hints for a character (debug only)
    func resetAll(for characterId: String) {
        for hint in NPCHint.allHints {
            let key = "\(prefix)\(characterId)_\(hint.id)"
            defaults.removeObject(forKey: key)
        }
    }
}

// MARK: - Hint Definitions

struct NPCHint: Identifiable, Equatable {
    let id: String
    let npcName: String
    let npcImage: String  // asset name for NPC avatar
    let message: String

    static func == (lhs: NPCHint, rhs: NPCHint) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - All Hints Catalog

    static let hub = NPCHint(
        id: "hub_welcome",
        npcName: "Tavern Keeper",
        npcImage: "shopkeeper",
        message: "Welcome, adventurer! Tap any building on the map to explore. Start with the Arena to earn gold and climb the ranks!"
    )

    static let arena = NPCHint(
        id: "arena_intro",
        npcName: "Arena Master",
        npcImage: "shopkeeper",
        message: "Choose your opponent wisely! You get free fights daily. Keep your HP above 10% or you won't be able to fight."
    )

    static let hero = NPCHint(
        id: "hero_stats",
        npcName: "Sage",
        npcImage: "shopkeeper",
        message: "You have stat points to spend! Go to the STATUS tab and allocate them to make your hero stronger."
    )

    static let shop = NPCHint(
        id: "shop_intro",
        npcName: "Merchant",
        npcImage: "shopkeeper",
        message: "Browse my wares! Health potions restore HP, stamina potions let you fight more. Upgrade your gear for better stats."
    )

    static let dungeon = NPCHint(
        id: "dungeon_intro",
        npcName: "Dungeon Guide",
        npcImage: "shopkeeper",
        message: "Each dungeon has bosses of increasing difficulty. Defeat them for rare loot and XP! Choose your battles carefully."
    )

    static let goldMine = NPCHint(
        id: "gold_mine_intro",
        npcName: "Mine Foreman",
        npcImage: "shopkeeper",
        message: "Start mining to earn gold passively! Each slot takes 4 hours. Come back when it's ready to collect your earnings."
    )

    static let battlePass = NPCHint(
        id: "battlepass_intro",
        npcName: "Herald",
        npcImage: "shopkeeper",
        message: "Complete daily quests and battles to earn Battle Pass XP. Each tier unlocks rewards — premium tier has even more!"
    )

    static let achievements = NPCHint(
        id: "achievements_intro",
        npcName: "Chronicler",
        npcImage: "shopkeeper",
        message: "Track your progress here! Claim rewards when you reach milestones. PvP, Progression, and Ranking achievements await."
    )

    static let usePotion = NPCHint(
        id: "use_potion",
        npcName: "Healer",
        npcImage: "shopkeeper",
        message: "Your health is low! Use a health potion from your inventory to restore HP before your next battle."
    )

    static let levelUp = NPCHint(
        id: "level_up_stats",
        npcName: "Sage",
        npcImage: "shopkeeper",
        message: "You leveled up! Don't forget to allocate your new stat points in the STATUS tab on the Hero page."
    )

    static let inventory = NPCHint(
        id: "inventory_empty",
        npcName: "Sage",
        npcImage: "shopkeeper",
        message: "You have no gear yet! Visit the Shop and buy some equipment — you'll need it to survive in the Arena."
    )

    static let allHints: [NPCHint] = [
        .hub, .arena, .hero, .shop, .dungeon, .goldMine,
        .battlePass, .achievements, .usePotion, .levelUp, .inventory
    ]
}
