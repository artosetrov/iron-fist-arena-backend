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
    /// Separate namespace for "compact bar also dismissed forever" flag.
    /// When the player dismisses the compact ContextualHintBar on a repeat
    /// visit (or hits "Don't show again" on the first-visit widget), this
    /// flag is written so neither form of the hint ever reappears.
    private let compactPrefix = "npc_hint_compact_seen_"

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

    /// Dismiss current hint and mark as seen. Also locks the compact bar
    /// so "Don't show again" on the first-visit widget is a true "forever".
    func dismiss(for characterId: String) {
        guard let hint = activeHint else { return }
        let key = "\(prefix)\(characterId)_\(hint.id)"
        defaults.set(true, forKey: key)
        // Bug #17: also mark compact-bar dismissed so it never auto-appears.
        let compactKey = "\(compactPrefix)\(characterId)_\(hint.id)"
        defaults.set(true, forKey: compactKey)
        withAnimation(.easeInOut(duration: 0.25)) {
            activeHint = nil
        }
    }

    /// Dismiss and skip ALL remaining hints for this character
    func skipAll(for characterId: String) {
        // Mark all defined hints as seen (both main + compact)
        for hint in NPCHint.allHints {
            let key = "\(prefix)\(characterId)_\(hint.id)"
            defaults.set(true, forKey: key)
            let compactKey = "\(compactPrefix)\(characterId)_\(hint.id)"
            defaults.set(true, forKey: compactKey)
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

    /// Bug #17: Has the compact ContextualHintBar been permanently dismissed
    /// for this hint? Returns true once the player taps X on the compact bar
    /// OR hits "Don't show again" on the first-visit widget.
    func hasCompactBeenDismissed(_ hintId: String, for characterId: String) -> Bool {
        let key = "\(compactPrefix)\(characterId)_\(hintId)"
        return defaults.bool(forKey: key)
    }

    /// Bug #17: Mark the compact bar as dismissed forever for this hint.
    /// Called from `ContextualHintOverlay` when the player dismisses the
    /// compact repeat-visit bar.
    func dismissCompact(_ hintId: String, for characterId: String) {
        let key = "\(compactPrefix)\(characterId)_\(hintId)"
        defaults.set(true, forKey: key)
    }

    /// Reset all hints for a character (debug only)
    func resetAll(for characterId: String) {
        for hint in NPCHint.allHints {
            let key = "\(prefix)\(characterId)_\(hint.id)"
            defaults.removeObject(forKey: key)
            let compactKey = "\(compactPrefix)\(characterId)_\(hint.id)"
            defaults.removeObject(forKey: compactKey)
        }
    }
}

// MARK: - Hint Category

/// Visual category for contextual hint bars — determines icon and accent color
enum HintCategory: String {
    case health    // ❤️ Low HP, potions, heal
    case stamina   // ⚡ No stamina, recharge
    case combat    // ⚔️ Arena, fights, strategy
    case quest     // 📜 Active quests, tasks
    case reward    // 🎁 Unclaimed rewards
    case gear      // 🛡️ Equipment, upgrades, repair
    case navigate  // 🗺️ Go to location
    case onboard   // 🏰 First visit intro
    case economy   // 💰 Gold, spending
    case status    // ℹ️ Informational

    /// SF Symbol icon for compact hint bar
    var sfSymbol: String {
        switch self {
        case .health:   return "heart.fill"
        case .stamina:  return "bolt.fill"
        case .combat:   return "swords"
        case .quest:    return "scroll.fill"
        case .reward:   return "gift.fill"
        case .gear:     return "shield.lefthalf.filled"
        case .navigate: return "map.fill"
        case .onboard:  return "book.closed.fill"
        case .economy:  return "banknote.fill"
        case .status:   return "info.circle.fill"
        }
    }

    /// Accent color for the category icon background
    var accentColor: SwiftUI.Color {
        switch self {
        case .health:   return DarkFantasyTheme.danger
        case .stamina:  return DarkFantasyTheme.stamina
        case .combat:   return .orange
        case .quest:    return DarkFantasyTheme.info
        case .reward:   return DarkFantasyTheme.gold
        case .gear:     return DarkFantasyTheme.goldDim
        case .navigate: return DarkFantasyTheme.info
        case .onboard:  return DarkFantasyTheme.gold
        case .economy:  return DarkFantasyTheme.gold
        case .status:   return DarkFantasyTheme.textSecondary
        }
    }
}

// MARK: - Hint Definitions

struct NPCHint: Identifiable, Equatable {
    let id: String
    let npcName: String
    let npcImage: String  // asset name for NPC avatar
    let message: String
    var ctaLabel: String? = nil
    var compactText: String? = nil
    /// Sublabel shown under compact text (e.g. "3 potions in inventory")
    var compactSublabel: String? = nil
    /// Visual category for compact hint bar icon & color
    var category: HintCategory = .onboard
    /// Optional asset name that overrides the category SF Symbol icon
    /// in the compact ContextualHintBar. Rendered as a rounded square thumbnail.
    var iconAsset: String? = nil

    static func == (lhs: NPCHint, rhs: NPCHint) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - All Hints Catalog

    static let hub = NPCHint(
        id: "hub_welcome",
        npcName: "Tavern Keeper",
        npcImage: "shopkeeper",
        message: "Welcome, adventurer! Tap any building on the map to explore. Start with the Arena to earn gold and climb the ranks!",
        category: .onboard
    )

    static let arena = NPCHint(
        id: "arena_intro",
        npcName: "Arena Master",
        npcImage: "shopkeeper",
        message: "Choose your opponent wisely! You get free fights daily. Keep your HP above 10% or you won't be able to fight.",
        category: .onboard
    )

    static let hero = NPCHint(
        id: "hero_stats",
        npcName: "Sage",
        npcImage: "shopkeeper",
        message: "You have stat points to spend! Go to the STATUS tab and allocate them to make your hero stronger.",
        category: .onboard
    )

    static let shop = NPCHint(
        id: "shop_intro",
        npcName: "Merchant",
        npcImage: "shopkeeper",
        message: "Browse my wares! Health potions restore HP, stamina potions let you fight more. Upgrade your gear for better stats.",
        category: .onboard
    )

    static let dungeon = NPCHint(
        id: "dungeon_intro",
        npcName: "Dungeon Guide",
        npcImage: "shopkeeper",
        message: "Each dungeon has bosses of increasing difficulty. Defeat them for rare loot and XP! Choose your battles carefully.",
        category: .onboard
    )

    static let goldMine = NPCHint(
        id: "gold_mine_intro",
        npcName: "Mine Foreman",
        npcImage: "shopkeeper",
        message: "Start mining to earn gold passively! Each slot takes 4 hours. Come back when it's ready to collect your earnings.",
        category: .onboard
    )

    static let battlePass = NPCHint(
        id: "battlepass_intro",
        npcName: "Herald",
        npcImage: "shopkeeper",
        message: "Complete daily quests and battles to earn Battle Pass XP. Each tier unlocks rewards — premium tier has even more!",
        category: .onboard
    )

    static let achievements = NPCHint(
        id: "achievements_intro",
        npcName: "Chronicler",
        npcImage: "shopkeeper",
        message: "Track your progress here! Claim rewards when you reach milestones. PvP, Progression, and Ranking achievements await.",
        category: .onboard
    )

    static let usePotion = NPCHint(
        id: "use_potion",
        npcName: "Healer",
        npcImage: "shopkeeper",
        message: "Your health is low! Use a health potion from your inventory to restore HP before your next battle.",
        category: .health
    )

    static let levelUp = NPCHint(
        id: "level_up_stats",
        npcName: "Sage",
        npcImage: "shopkeeper",
        message: "You leveled up! Don't forget to allocate your new stat points in the STATUS tab on the Hero page.",
        category: .onboard
    )

    static let inventory = NPCHint(
        id: "inventory_empty",
        npcName: "Sage",
        npcImage: "shopkeeper",
        message: "You have no gear yet! Visit the Shop and buy some equipment — you'll need it to survive in the Arena.",
        category: .gear
    )

    // MARK: - Contextual Hints (33 new)

    // HERO screen (8 hints)
    static let heroNoGear = NPCHint(
        id: "hero_no_gear",
        npcName: "Sage",
        npcImage: "shopkeeper",
        message: "You're going into battle... naked? Bold strategy. Might I suggest visiting the Shop before someone mistakes you for a training dummy?",
        ctaLabel: "GO TO SHOP",
        compactText: "Equip gear first",
        compactSublabel: "Visit the Shop for equipment",
        category: .gear
    )

    static let heroLowHpPotions = NPCHint(
        id: "hero_low_hp_potions",
        npcName: "Healer",
        npcImage: "shopkeeper",
        message: "You look like you lost a fight with a staircase. Good news — you've got potions! Drink one before something finishes the job.",
        ctaLabel: "HEAL",
        compactText: "Low HP — Drink potion",
        compactSublabel: "You have potions in inventory",
        category: .health
    )

    static let heroLowHpNoPotions = NPCHint(
        id: "hero_low_hp_no_potions",
        npcName: "Healer",
        npcImage: "shopkeeper",
        message: "Barely alive AND no potions? That's not bravery, that's a death wish. The Shop has what you need. Run. Don't walk.",
        ctaLabel: "GO TO SHOP",
        compactText: "Critical HP — Buy potions",
        compactSublabel: "No potions left",
        category: .health
    )

    static let heroDamagedGear = NPCHint(
        id: "hero_damaged_gear",
        npcName: "Blacksmith",
        npcImage: "shopkeeper",
        message: "Is that a sword or a butter knife? Your gear's falling apart! Tap an item and hit Repair before it crumbles to dust.",
        compactText: "Repair your gear",
        compactSublabel: "Tap an item to repair",
        category: .gear
    )

    static let heroUpgradeQuest = NPCHint(
        id: "hero_upgrade_quest",
        npcName: "Blacksmith",
        npcImage: "shopkeeper",
        message: "Got a quest to upgrade, eh? Pick any item, hit Upgrade, and pray to the RNG gods. I've seen grown warriors cry at this screen.",
        compactText: "Upgrade an item",
        compactSublabel: "Active quest requirement",
        category: .quest
    )

    static let heroUpgradeNoItem = NPCHint(
        id: "hero_upgrade_no_item",
        npcName: "Blacksmith",
        npcImage: "shopkeeper",
        message: "Can't upgrade what you don't have, genius. Pop over to the Shop, grab some gear, then come back. I'll keep the forge warm.",
        ctaLabel: "GO TO SHOP",
        compactText: "Buy gear to upgrade",
        compactSublabel: "No upgradeable items",
        category: .gear
    )

    static let heroStatPoints = NPCHint(
        id: "hero_stat_points",
        npcName: "Sage",
        npcImage: "shopkeeper",
        message: "You have stat points gathering dust! Switch to the STATUS tab and make yourself less... mediocre. No offense.",
        compactText: "Allocate stat points",
        compactSublabel: "Switch to STATUS tab",
        category: .reward
    )

    static let heroConsumableQuest = NPCHint(
        id: "hero_consumable_quest",
        npcName: "Healer",
        npcImage: "shopkeeper",
        message: "Your quest says 'use a consumable.' I know it hurts to waste a perfectly good potion, but science demands sacrifice.",
        compactText: "Use a consumable",
        compactSublabel: "Active quest requirement",
        category: .quest
    )

    // HUB screen (6 hints)
    static let hubNoStamina = NPCHint(
        id: "hub_no_stamina",
        npcName: "Tavern Keeper",
        npcImage: "shopkeeper",
        message: "Exhausted already? Even my cat has more stamina. Wait for it to recover, or throw some gems at the problem in the Shop.",
        compactText: "Stamina empty",
        compactSublabel: "Wait to recharge or visit Shop",
        category: .stamina
    )

    static let hubFirstPvp = NPCHint(
        id: "hub_first_pvp",
        npcName: "Arena Master",
        npcImage: "shopkeeper",
        message: "Hey, you! Yeah, the one who's never fought anyone. The Arena awaits! Pick someone your size and show them what you... probably can't do yet.",
        ctaLabel: "FIGHT",
        compactText: "Try the Arena!",
        compactSublabel: "Earn gold and climb ranks",
        category: .combat,
        iconAsset: "building-arena"
    )

    static let hubFirstDungeon = NPCHint(
        id: "hub_first_dungeon",
        npcName: "Dungeon Guide",
        npcImage: "shopkeeper",
        message: "The dungeons aren't going to clear themselves. Well, technically the monsters live there, so... they already have. But YOU haven't.",
        ctaLabel: "FIGHT",
        compactText: "Try a Dungeon!",
        compactSublabel: "Clear monsters for rare loot",
        category: .combat,
        iconAsset: "boss-arena-warden-portrait"
    )

    static let hubFirstMine = NPCHint(
        id: "hub_first_mine",
        npcName: "Mine Foreman",
        npcImage: "shopkeeper",
        message: "Free gold, just sitting there, and you haven't visited the mine? It's like finding money on the ground and walking over it.",
        ctaLabel: "MINE",
        compactText: "Visit the Gold Mine",
        compactSublabel: "Earn gold passively",
        category: .economy,
        iconAsset: "building-gold-mine"
    )

    static let hubMineReady = NPCHint(
        id: "hub_mine_ready",
        npcName: "Mine Foreman",
        npcImage: "shopkeeper",
        message: "Your miners struck pay-dirt! There's gold ready to collect at the mine. Get it before someone else notices.",
        ctaLabel: "COLLECT",
        compactText: "Gold ready at the mine",
        compactSublabel: "Tap to collect your gains",
        category: .reward,
        iconAsset: "building-gold-mine"
    )

    static let hubUnclaimedRewards = NPCHint(
        id: "hub_unclaimed_rewards",
        npcName: "Herald",
        npcImage: "shopkeeper",
        message: "You've got unclaimed rewards just... sitting there. Rotting. Gathering cobwebs. Please claim them before I have a breakdown.",
        compactText: "Claim quest rewards",
        compactSublabel: "Completed quests waiting",
        category: .reward
    )

    // ARENA screen (7 hints)
    static let arenaLowHpPotions = NPCHint(
        id: "arena_low_hp_potions",
        npcName: "Field Medic",
        npcImage: "shopkeeper",
        message: "Walking into the Arena at death's door? At least chug a potion first. I'm a medic, not a miracle worker.",
        ctaLabel: "HEAL",
        compactText: "Heal before fighting",
        compactSublabel: "You have potions available",
        category: .health
    )

    static let arenaLowHpNoPotions = NPCHint(
        id: "arena_low_hp_no_potions",
        npcName: "Field Medic",
        npcImage: "shopkeeper",
        message: "No health, no potions, still wants to fight. You're either incredibly brave or profoundly unwise. Shop's that way.",
        ctaLabel: "GO TO SHOP",
        compactText: "Buy potions first",
        compactSublabel: "No potions left",
        category: .health
    )

    static let arenaFirstFight = NPCHint(
        id: "arena_first_fight",
        npcName: "Arena Master",
        npcImage: "shopkeeper",
        message: "First blood! Pick the greenest opponent — that means weak, not literally green. Well, some ARE literally green. Orcs, you know.",
        compactText: "Pick your first fight!",
        compactSublabel: "Choose a weaker opponent to start",
        category: .combat
    )

    static let arenaLossStreak = NPCHint(
        id: "arena_loss_streak",
        npcName: "Arena Master",
        npcImage: "shopkeeper",
        message: "Rough patch, eh? Try someone with a lower rating, or switch your Combat Stance. Sometimes offense IS the best defense. Or the worst. Who knows.",
        compactText: "Try a weaker opponent",
        compactSublabel: "Switch Combat Stance for advantage",
        category: .combat
    )

    static let arenaLowStamina = NPCHint(
        id: "arena_low_stamina",
        npcName: "Arena Master",
        npcImage: "shopkeeper",
        message: "You're running on fumes! Can't fight without stamina — even legends need to rest. Or buy some energy in the Shop, like a proper pay-to-win player.",
        compactText: "Not enough stamina",
        compactSublabel: "Wait to recharge or visit Shop",
        category: .stamina
    )

    static let arenaFirstWin = NPCHint(
        id: "arena_first_win",
        npcName: "Arena Master",
        npcImage: "shopkeeper",
        message: "PSA: Your first win today gets BONUS rewards! That's free money. Well, free-ish. You still have to win. Minor detail.",
        compactText: "First Win Bonus available!",
        compactSublabel: "Extra rewards for today's first victory",
        category: .reward
    )

    // SHOP screen (5 hints)
    static let shopRedirectPotions = NPCHint(
        id: "shop_redirect_potions",
        npcName: "Merchant",
        npcImage: "shopkeeper",
        message: "Ah, the Healer sent you? Smart. Health potions are in the Potions tab. Buy two — one for now, one for when you inevitably get hit again.",
        category: .navigate
    )

    static let shopRedirectGear = NPCHint(
        id: "shop_redirect_gear",
        npcName: "Merchant",
        npcImage: "shopkeeper",
        message: "Looking for upgrade material? Check the Equipment tab! Anything you buy can be upgraded later. The Blacksmith loves fresh victims... I mean, customers.",
        category: .navigate
    )

    static let shopBroke = NPCHint(
        id: "shop_broke",
        npcName: "Merchant",
        npcImage: "shopkeeper",
        message: "Empty pockets, huh? Can't help you there. Go win some Arena fights or dig up gold in the Mine. Come back when you can actually afford something.",
        compactText: "Earn gold first",
        compactSublabel: "Win fights or mine gold",
        category: .economy
    )

    static let shopGoldQuest = NPCHint(
        id: "shop_gold_quest",
        npcName: "Merchant",
        npcImage: "shopkeeper",
        message: "A quest to spend gold? Finally, a quest I can get behind! Buy anything — gear, potions, a nice hat. It all counts!",
        compactText: "Spend gold for quest",
        compactSublabel: "Buy anything to complete quest",
        category: .quest
    )

    // DUNGEON screen (4 hints)
    static let dungeonLowStamina = NPCHint(
        id: "dungeon_low_stamina",
        npcName: "Dungeon Guide",
        npcImage: "shopkeeper",
        message: "You need stamina to enter, and you're running on empty. Come back when you've recharged, or buy some in the Shop. The monsters aren't going anywhere.",
        compactText: "Need stamina",
        compactSublabel: "Wait to recharge or visit Shop",
        category: .stamina
    )

    static let dungeonLowHp = NPCHint(
        id: "dungeon_low_hp",
        npcName: "Dungeon Guide",
        npcImage: "shopkeeper",
        message: "Going into a dungeon at half health? I admire your confidence. I question your judgment. Maybe drink a potion first?",
        compactText: "Heal before dungeon",
        compactSublabel: "Use a potion first",
        category: .health
    )

    static let dungeonQuest = NPCHint(
        id: "dungeon_quest",
        npcName: "Dungeon Guide",
        npcImage: "shopkeeper",
        message: "Got a dungeon quest? Pick any floor and clear it. Pro tip: the difficulty tag isn't a suggestion, it's a warning.",
        compactText: "Complete dungeon for quest",
        compactSublabel: "Clear any floor to progress",
        category: .quest
    )

    // GOLD MINE (4 hints)
    static let mineReadyCollect = NPCHint(
        id: "mine_ready_collect",
        npcName: "Mine Foreman",
        npcImage: "shopkeeper",
        message: "Your miners found gold! Tap the slot to collect before they spend it all at the tavern. Trust me, they will.",
        compactText: "Gold ready to collect!",
        compactSublabel: "Tap slot to claim",
        category: .reward
    )

    static let mineAllBusy = NPCHint(
        id: "mine_all_busy",
        npcName: "Mine Foreman",
        npcImage: "shopkeeper",
        message: "Everything's running smoothly. Go do something else — fight, shop, stare at your equipment. I'll hold down the fort.",
        category: .status
    )

    static let mineCollectQuest = NPCHint(
        id: "mine_collect_quest",
        npcName: "Mine Foreman",
        npcImage: "shopkeeper",
        message: "Quest says collect from the mine? Start a slot if you haven't, then come back when it's done. Patience, grasshopper.",
        compactText: "Collect for quest",
        compactSublabel: "Start mining if you haven't",
        category: .quest
    )

    // BATTLE PASS (1 hint)
    static let bpUnclaimedRewards = NPCHint(
        id: "bp_unclaimed_rewards",
        npcName: "Herald",
        npcImage: "shopkeeper",
        message: "You've passed tiers with unclaimed rewards! That's like leaving money on the table, except the table is on fire and the money is getting crispy.",
        compactText: "Claim BP rewards!",
        compactSublabel: "Tier rewards waiting",
        category: .reward
    )

    // ACHIEVEMENTS (1 hint)
    static let achievementUnclaimed = NPCHint(
        id: "achievement_unclaimed",
        npcName: "Chronicler",
        npcImage: "shopkeeper",
        message: "You've EARNED glory and you haven't COLLECTED it? That's like slaying a dragon and forgetting to loot the hoard. Tap and claim!",
        compactText: "Claim achievement rewards!",
        compactSublabel: "Completed achievements waiting",
        category: .reward
    )

    // MINIGAMES (1 hint)
    static let shellGameQuest = NPCHint(
        id: "shell_game_quest",
        npcName: "Trickster",
        npcImage: "shopkeeper",
        message: "Got a quest to play my game? Excellent! Watch the shells, pick the right one, and try not to blink. Or cry. Crying is also common.",
        compactText: "Play shell game for quest",
        compactSublabel: "Active quest requirement",
        category: .quest
    )

    static let allHints: [NPCHint] = [
        // Original 11 intro hints
        .hub, .arena, .hero, .shop, .dungeon, .goldMine,
        .battlePass, .achievements, .usePotion, .levelUp, .inventory,
        // HERO screen (8)
        .heroNoGear, .heroLowHpPotions, .heroLowHpNoPotions, .heroDamagedGear,
        .heroUpgradeQuest, .heroUpgradeNoItem, .heroStatPoints, .heroConsumableQuest,
        // HUB screen (7)
        .hubNoStamina, .hubFirstPvp, .hubFirstDungeon, .hubFirstMine,
        .hubMineReady, .hubUnclaimedRewards,
        // ARENA screen (7)
        .arenaLowHpPotions, .arenaLowHpNoPotions, .arenaFirstFight,
        .arenaLossStreak, .arenaLowStamina, .arenaFirstWin,
        // SHOP screen (5)
        .shopRedirectPotions, .shopRedirectGear, .shopBroke, .shopGoldQuest,
        // DUNGEON screen (4)
        .dungeonLowStamina, .dungeonLowHp, .dungeonQuest,
        // GOLD MINE (4)
        .mineReadyCollect, .mineAllBusy, .mineCollectQuest,
        // BATTLE PASS (1)
        .bpUnclaimedRewards,
        // ACHIEVEMENTS (1)
        .achievementUnclaimed,
        // MINIGAMES (1)
        .shellGameQuest
    ]
}
