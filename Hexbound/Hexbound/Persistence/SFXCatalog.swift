import Foundation

// MARK: - SFX Catalog

/// All available sound effects in the game.
/// Audio files go in the bundle as `<rawValue>.wav`.
/// If a file is missing, SFXManager silently skips it (no crash).
@MainActor
enum SFX: String, CaseIterable {
    // UI — general
    case uiTap = "ui_tap"
    case uiTapHeavy = "ui_tap_heavy"
    case uiOpen = "ui_open"
    case uiClose = "ui_close"
    case uiTransition = "ui_transition"
    case uiBack = "ui_back"
    case uiConfirm = "ui_confirm"
    case uiCancel = "ui_cancel"
    case uiError = "ui_error"
    case uiToggle = "ui_toggle"
    case uiSlide = "ui_slide"

    // UI — specific screens
    case uiPurchase = "ui_purchase"
    case uiEquip = "ui_equip"
    case uiUnequip = "ui_unequip"
    case uiSell = "ui_sell"
    case uiUpgradeSuccess = "ui_upgrade_success"
    case uiUpgradeFail = "ui_upgrade_fail"
    case uiLevelUp = "ui_level_up"
    case uiQuestComplete = "ui_quest_complete"
    case uiRewardClaim = "ui_reward_claim"

    // Battle result
    case battleVictory = "battle_victory"
    case battleDefeat = "battle_defeat"
    case battleDraw = "battle_draw"
    case battleStart = "battle_start"

    // Combat — hits
    case hitPhysical = "hit_physical"
    case hitMagical = "hit_magical"
    case hitCritical = "hit_critical"
    case hitPoison = "hit_poison"
    case hitRogue = "hit_rogue"
    case hitTrue = "hit_true"

    // Combat — actions
    case combatBlock = "combat_block"
    case combatMiss = "combat_miss"
    case combatDodge = "combat_dodge"
    case combatPoison = "combat_poison"
    case combatHeal = "combat_heal"
    case combatDeath = "combat_death"
    case combatSpecial = "combat_special"
    case combatShield = "combat_shield"
    case combatBuff = "combat_buff"

    // Dungeon
    case dungeonEnter = "dungeon_enter"
    case dungeonFloorComplete = "dungeon_floor_complete"
    case dungeonBossAppear = "dungeon_boss_appear"
    case dungeonDoorOpen = "dungeon_door_open"
    case dungeonDoorClose = "dungeon_door_close"
    case dungeonGateClose = "dungeon_gate_close"
    case dungeonUnlock = "dungeon_unlock"

    // Ambient — weather
    case thunderRumble = "thunder_rumble"
    case rainAmbient = "rain_ambient"

    // Atmospheric — Arena
    case crowdRoar = "crowd_roar"          // Arena entrance burst
    case warDrums = "war_drums"            // Pre-fight anticipation
    case gongHit = "gong_hit"              // Match start punctuation

    // Atmospheric — Shop & Economy
    case coinsJingle = "coins_jingle"      // Purchase confirmation
    case merchantGreet = "merchant_greet"  // Shop open (cloth + bell)
    case pouchDrop = "pouch_drop"          // Gold transaction

    // Atmospheric — Inventory & Forge
    case armorClink = "armor_clink"        // Metal equip
    case clothRustle = "cloth_rustle"      // Cloth/accessory equip
    case magicShimmer = "magic_shimmer"    // Relic/ring equip
    case anvilStrike = "anvil_strike"      // Upgrade hammer hit
    case enchantGlow = "enchant_glow"      // Successful enchant

    // Atmospheric — Dungeon
    case creatureGrowl = "creature_growl"  // Pre-boss tension
    case rockCrumble = "rock_crumble"      // Floor collapse / gate
    case chainRattle = "chain_rattle"      // Gate unlock chains
    case footstepStone = "footstep_stone"  // Dungeon movement
    case footstepWood = "footstep_wood"    // Building entry

    // Atmospheric — Rewards & Ceremonies
    case epicHornFanfare = "epic_horn_fanfare"  // Level up / rank up
    case sealStamp = "seal_stamp"              // Achievement unlocked
    case scrollUnfurl = "scroll_unfurl"        // Quest list open
    case chainBreak = "chain_break"            // Battle pass tier unlock
    case magicSpark = "magic_spark"            // Reward claim sparkle

    // Atmospheric — Minigames
    case wheelSpin = "wheel_spin"          // Fortune wheel ratchet
    case shellShuffle = "shell_shuffle"    // Shell game shuffle
    case pickaxeHit = "pickaxe_hit"        // Gold mine tap

    // Atmospheric — Buildings / Hub
    case doorCreak = "door_creak"          // Building entry
    case torchIgnite = "torch_ignite"      // Screen transition fire whoosh

    // Misc
    case coinDrop = "coin_drop"
    case itemDrop = "item_drop"
    case potionUse = "potion_use"
    case chestOpen = "chest_open"
    case chestClose = "chest_close"
    case goldMine = "gold_mine"

    var filename: String { rawValue + ".wav" }

    /// Number of available sound files for this SFX (1 = no variations).
    /// Variations are named `<rawValue>_2.wav`, `<rawValue>_3.wav`, etc.
    var variationCount: Int {
        switch self {
        case .hitPhysical:      return 7  // hit_physical + _2.._7
        case .hitMagical:       return 7  // hit_magical + _2.._7
        case .hitCritical:      return 6  // hit_critical + _2.._6
        case .hitPoison:        return 2  // hit_poison + _2, _3
        case .hitRogue:         return 4  // hit_rogue + _2.._4
        case .hitTrue:          return 4  // hit_true + _2.._4
        case .combatBlock:      return 4  // combat_block + _2.._4
        case .combatMiss:       return 4  // combat_miss + _2.._4
        case .combatDodge:      return 3  // combat_dodge + _2, _3
        case .combatPoison:     return 5  // combat_poison + _2.._6
        case .combatHeal:       return 2  // combat_heal + _2, _3
        case .combatSpecial:    return 2  // combat_special + _2
        case .combatShield:     return 4  // combat_shield + _2.._4
        case .uiEquip:          return 2  // ui_equip + _2
        case .uiUnequip:        return 2  // ui_unequip + _2
        case .chestOpen:        return 3  // chest_open + _2, _3
        case .chestClose:       return 2  // chest_close + _2
        case .goldMine:         return 5  // gold_mine + _2.._5
        case .dungeonEnter:     return 3  // dungeon_enter + _2, _3
        case .dungeonBossAppear: return 3  // dungeon_boss_appear + _2, _3
        case .dungeonDoorOpen:  return 2  // dungeon_door_open + _2
        case .dungeonDoorClose: return 2  // dungeon_door_close + _2
        case .thunderRumble:    return 3  // thunder_rumble + _2, _3
        case .rainAmbient:      return 1  // rain_ambient (continuous, no variations)
        case .crowdRoar:        return 2  // crowd_roar + _2
        case .warDrums:         return 2  // war_drums + _2
        case .coinsJingle:      return 3  // coins_jingle + _2, _3
        case .armorClink:       return 2  // armor_clink + _2
        case .creatureGrowl:    return 3  // creature_growl + _2, _3
        case .rockCrumble:      return 2  // rock_crumble + _2
        case .footstepStone:    return 4  // footstep_stone + _2.._4
        case .footstepWood:     return 3  // footstep_wood + _2, _3
        case .pickaxeHit:       return 3  // pickaxe_hit + _2, _3
        case .doorCreak:        return 2  // door_creak + _2
        default:                return 1
        }
    }

    // MARK: - Haptic Mapping

    /// Returns the haptic feedback to fire alongside this SFX.
    /// `nil` = no haptic (scroll sounds, passive sounds).
    var haptic: (() -> Void)? {
        switch self {
        // UI — lightweight taps
        case .uiTap, .uiToggle, .uiSlide:
            return { HapticManager.light() }
        case .uiTapHeavy, .uiConfirm:
            return { HapticManager.medium() }
        case .uiOpen, .uiClose, .uiTransition, .uiBack:
            return { HapticManager.selection() }
        case .uiCancel:
            return { HapticManager.light() }
        case .uiError:
            return { HapticManager.error() }

        // UI — special moments
        case .uiPurchase, .uiEquip, .uiUnequip:
            return { HapticManager.medium() }
        case .uiSell:
            return { HapticManager.light() }
        case .uiUpgradeSuccess:
            return { HapticManager.success() }
        case .uiUpgradeFail:
            return { HapticManager.warning() }
        case .uiLevelUp:
            return { HapticManager.success() }
        case .uiQuestComplete:
            return { HapticManager.stamp() }
        case .uiRewardClaim:
            return { HapticManager.medium() }

        // Battle result
        case .battleVictory:
            return { HapticManager.victory() }
        case .battleDefeat:
            return { HapticManager.defeat() }
        case .battleDraw:
            return { HapticManager.warning() }
        case .battleStart:
            return { HapticManager.heavy() }

        // Combat — hits
        case .hitPhysical:
            return { HapticManager.medium() }
        case .hitMagical:
            return { HapticManager.light() }
        case .hitCritical:
            return { HapticManager.heavy() }
        case .hitPoison:
            return { HapticManager.light() }
        case .hitRogue:
            return { HapticManager.medium() }
        case .hitTrue:
            return { HapticManager.medium() }

        // Combat — actions
        case .combatBlock:
            return { HapticManager.medium() }
        case .combatMiss, .combatDodge:
            return nil // No haptic for misses (feels wrong)
        case .combatPoison:
            return { HapticManager.light() }
        case .combatHeal:
            return { HapticManager.success() }
        case .combatDeath:
            return { HapticManager.shake() }
        case .combatSpecial:
            return { HapticManager.heavy() }
        case .combatShield:
            return { HapticManager.medium() }
        case .combatBuff:
            return { HapticManager.light() }

        // Dungeon
        case .dungeonEnter:
            return { HapticManager.heavy() }
        case .dungeonFloorComplete:
            return { HapticManager.success() }
        case .dungeonBossAppear:
            return { HapticManager.heavy() }
        case .dungeonDoorOpen, .dungeonDoorClose:
            return { HapticManager.medium() }
        case .dungeonGateClose:
            return { HapticManager.heavy() }
        case .dungeonUnlock:
            return { HapticManager.success() }

        // Ambient — weather
        case .thunderRumble:
            return nil  // No haptic (ambient rumble)
        case .rainAmbient:
            return nil  // No haptic (continuous ambient)

        // Atmospheric — Arena
        case .crowdRoar:
            return { HapticManager.heavy() }
        case .warDrums:
            return { HapticManager.medium() }
        case .gongHit:
            return { HapticManager.heavy() }

        // Atmospheric — Shop & Economy
        case .coinsJingle:
            return { HapticManager.light() }
        case .merchantGreet:
            return { HapticManager.light() }
        case .pouchDrop:
            return { HapticManager.medium() }

        // Atmospheric — Inventory & Forge
        case .armorClink:
            return { HapticManager.medium() }
        case .clothRustle:
            return { HapticManager.light() }
        case .magicShimmer:
            return { HapticManager.light() }
        case .anvilStrike:
            return { HapticManager.heavy() }
        case .enchantGlow:
            return { HapticManager.success() }

        // Atmospheric — Dungeon
        case .creatureGrowl:
            return { HapticManager.heavy() }
        case .rockCrumble:
            return { HapticManager.heavy() }
        case .chainRattle:
            return { HapticManager.medium() }
        case .footstepStone, .footstepWood:
            return nil  // No haptic for footsteps (too frequent)

        // Atmospheric — Rewards & Ceremonies
        case .epicHornFanfare:
            return { HapticManager.victory() }
        case .sealStamp:
            return { HapticManager.stamp() }
        case .scrollUnfurl:
            return { HapticManager.light() }
        case .chainBreak:
            return { HapticManager.heavy() }
        case .magicSpark:
            return { HapticManager.light() }

        // Atmospheric — Minigames
        case .wheelSpin:
            return nil  // No haptic (continuous sound)
        case .shellShuffle:
            return nil  // No haptic (continuous sound)
        case .pickaxeHit:
            return { HapticManager.medium() }

        // Atmospheric — Hub
        case .doorCreak:
            return { HapticManager.medium() }
        case .torchIgnite:
            return nil  // No haptic (ambient whoosh)

        // Misc
        case .coinDrop:
            return { HapticManager.light() }
        case .itemDrop:
            return { HapticManager.medium() }
        case .potionUse:
            return { HapticManager.light() }
        case .chestOpen:
            return { HapticManager.medium() }
        case .chestClose:
            return { HapticManager.light() }
        case .goldMine:
            return { HapticManager.medium() }
        }
    }

    // MARK: - Combat Mapping

    /// Map a VFXEffectType to the corresponding SFX.
    static func from(vfxType: VFXEffectType) -> SFX {
        switch vfxType {
        case .physicalHit:  return .hitPhysical
        case .physicalCrit: return .hitCritical
        case .magicalHit:   return .hitMagical
        case .magicalCrit:  return .hitCritical
        case .poisonHit:    return .hitPoison
        case .poisonCrit:   return .hitCritical
        case .trueHit:      return .hitTrue
        case .trueCrit:     return .hitCritical
        case .dodge:        return .combatDodge
        case .miss:         return .combatMiss
        case .block:        return .combatBlock
        case .heal:         return .combatHeal
        case .statusProc:   return .combatPoison
        }
    }
}
