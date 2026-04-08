import SwiftUI

// MARK: - Contextual Hint Provider

/// Evaluates player state and returns the highest-priority contextual NPC hint for each screen.
/// Returns nil if no actionable condition is detected.
///
/// Usage:
/// ```swift
/// let hint = ContextualHintProvider.heroHint(character: char, equippedItems: items, quests: quests, potionCount: n)
/// ```
@MainActor
enum ContextualHintProvider {

    // MARK: - HERO Screen

    /// Returns the highest-priority contextual hint for the Hero (Equipment) screen.
    static func heroHint(
        character: Character,
        equippedCount: Int,
        potionCount: Int,
        hasDamagedGear: Bool,
        quests: [Quest],
        inventoryCount: Int
    ) -> NPCHint? {
        // Priority 1: No gear at all
        if equippedCount == 0 && inventoryCount == 0 {
            return .heroNoGear
        }

        // Priority 2: Critical HP + no potions
        if character.hpPercentage < 0.30 && potionCount == 0 {
            return .heroLowHpNoPotions
        }

        // Priority 3: Critical HP + has potions
        if character.hpPercentage < 0.30 && potionCount > 0 {
            return .heroLowHpPotions
        }

        // Priority 4: Damaged gear
        if hasDamagedGear {
            return .heroDamagedGear
        }

        // Priority 5: Upgrade quest + no items to upgrade
        let hasUpgradeQuest = quests.contains { $0.type == "item_upgrade" && !$0.completed }
        if hasUpgradeQuest && inventoryCount == 0 {
            return .heroUpgradeNoItem
        }

        // Priority 6: Upgrade quest + has items
        if hasUpgradeQuest {
            return .heroUpgradeQuest
        }

        // Priority 7: Unspent stat points
        if (character.statPoints ?? 0) > 0 {
            return .heroStatPoints
        }

        // Priority 8: Consumable use quest
        let hasConsumableQuest = quests.contains { $0.type == "consumable_use" && !$0.completed }
        if hasConsumableQuest {
            return .heroConsumableQuest
        }

        return nil
    }

    // MARK: - HUB Screen

    /// Returns the highest-priority contextual hint for the Hub screen.
    static func hubHint(
        character: Character,
        totalPvpFights: Int,
        totalDungeonClears: Int,
        hasVisitedMine: Bool,
        hasUnclaimedQuestRewards: Bool
    ) -> NPCHint? {
        // Priority 1: Stamina depleted
        if character.currentStamina == 0 {
            return .hubNoStamina
        }

        // Priority 2: Never fought in arena
        if totalPvpFights == 0 {
            return .hubFirstPvp
        }

        // Priority 3: Never cleared a dungeon
        if totalDungeonClears == 0 {
            return .hubFirstDungeon
        }

        // Priority 4: Never visited mine
        if !hasVisitedMine {
            return .hubFirstMine
        }

        // Priority 5: Unclaimed quest rewards
        if hasUnclaimedQuestRewards {
            return .hubUnclaimedRewards
        }

        return nil
    }

    // MARK: - ARENA Screen

    /// Returns the highest-priority contextual hint for the Arena screen.
    static func arenaHint(
        character: Character,
        potionCount: Int,
        totalPvpFights: Int,
        currentLossStreak: Int,
        staminaCostPerFight: Int
    ) -> NPCHint? {
        // Priority 1: HP critical + no potions
        if character.hpPercentage < 0.30 && potionCount == 0 {
            return .arenaLowHpNoPotions
        }

        // Priority 2: HP critical + has potions
        if character.hpPercentage < 0.30 && potionCount > 0 {
            return .arenaLowHpPotions
        }

        // Priority 3: Not enough stamina
        if character.currentStamina < staminaCostPerFight {
            return .arenaLowStamina
        }

        // Priority 4: First ever fight
        if totalPvpFights == 0 {
            return .arenaFirstFight
        }

        // Priority 5: Loss streak
        if currentLossStreak >= 3 {
            return .arenaLossStreak
        }

        // Priority 6: First win bonus available
        if character.firstWinToday == false {
            return .arenaFirstWin
        }

        return nil
    }

    // MARK: - SHOP Screen

    /// Returns the highest-priority contextual hint for the Shop screen.
    static func shopHint(
        character: Character,
        quests: [Quest],
        redirectReason: ShopRedirectReason?
    ) -> NPCHint? {
        // Priority 1: Redirected for potions
        if redirectReason == .buyPotions {
            return .shopRedirectPotions
        }

        // Priority 2: Redirected for gear
        if redirectReason == .buyGear {
            return .shopRedirectGear
        }

        // Priority 3: Broke (no gold)
        if character.gold <= 0 {
            return .shopBroke
        }

        // Priority 4: Gold spending quest
        let hasGoldQuest = quests.contains { $0.type == "gold_spent" && !$0.completed }
        if hasGoldQuest {
            return .shopGoldQuest
        }

        return nil
    }

    enum ShopRedirectReason {
        case buyPotions
        case buyGear
    }

    // MARK: - DUNGEON Screen

    /// Returns the highest-priority contextual hint for the Dungeon Select screen.
    static func dungeonHint(
        character: Character,
        staminaCostPerEntry: Int,
        quests: [Quest]
    ) -> NPCHint? {
        // Priority 1: Not enough stamina
        if character.currentStamina < staminaCostPerEntry {
            return .dungeonLowStamina
        }

        // Priority 2: Low HP
        if character.hpPercentage < 0.50 {
            return .dungeonLowHp
        }

        // Priority 3: Dungeon quest active
        let hasDungeonQuest = quests.contains { $0.type == "dungeons_complete" && !$0.completed }
        if hasDungeonQuest {
            return .dungeonQuest
        }

        return nil
    }

    // MARK: - GOLD MINE Screen

    /// Returns the highest-priority contextual hint for the Gold Mine screen.
    static func mineHint(
        readySlotsCount: Int,
        allSlotsBusy: Bool,
        quests: [Quest]
    ) -> NPCHint? {
        // Priority 1: Slots ready to collect
        if readySlotsCount > 0 {
            return .mineReadyCollect
        }

        // Priority 2: Mine collect quest
        let hasMineQuest = quests.contains { $0.type == "gold_mine_collect" && !$0.completed }
        if hasMineQuest {
            return .mineCollectQuest
        }

        // Priority 3: All busy (informational, no action needed)
        if allSlotsBusy {
            return .mineAllBusy
        }

        return nil
    }

    // MARK: - BATTLE PASS Screen

    /// Returns contextual hint for Battle Pass screen.
    static func battlePassHint(hasUnclaimedRewards: Bool) -> NPCHint? {
        if hasUnclaimedRewards {
            return .bpUnclaimedRewards
        }
        return nil
    }

    // MARK: - ACHIEVEMENTS Screen

    /// Returns contextual hint for Achievements screen.
    static func achievementsHint(hasUnclaimedRewards: Bool) -> NPCHint? {
        if hasUnclaimedRewards {
            return .achievementUnclaimed
        }
        return nil
    }

    // MARK: - SHELL GAME

    /// Returns contextual hint for Shell Game screen.
    static func shellGameHint(quests: [Quest]) -> NPCHint? {
        let hasQuest = quests.contains { $0.type == "shell_game_play" && !$0.completed }
        if hasQuest {
            return .shellGameQuest
        }
        return nil
    }
}
