import SwiftUI

enum DarkFantasyTheme {

    // MARK: - Background & Surface Colors (see docs/07_ui_ux/DESIGN_SYSTEM.md)

    static let bgAbyss = Color(hex: 0x08080C)       // Deepest black — behind modals
    static let bgPrimary = Color(hex: 0x0D0D12)     // Main screen background
    static let bgSecondary = Color(hex: 0x1A1A2E)   // Panel backgrounds, cards
    static let bgTertiary = Color(hex: 0x16213E)    // Card interiors, form fields
    static let bgElevated = Color(hex: 0x1E2240)    // Active cards, selected items
    static let bgModal = Color.black.opacity(0.75)   // Modal overlay
    static let bgBackdrop = Color.black.opacity(0.85) // Heavy backdrop for sheets/overlays
    static let bgBackdropLight = Color.black.opacity(0.7) // Lighter backdrop for popups
    static let bgScrim = Color.black.opacity(0.5)       // Semi-transparent scrim fill

    // Legacy aliases (used in existing code)
    static let bgDark = bgPrimary
    static let bgCard = bgSecondary

    // MARK: - Gold Accent System

    static let gold = Color(hex: 0xD4A537)           // Primary CTA, gold buttons
    static let goldBright = Color(hex: 0xFFD700)      // Highlighted text, important values
    static let goldDim = Color(hex: 0x8B6914)         // Disabled gold, inactive
    static let goldGlow = Color(hex: 0xF39C12).opacity(0.4) // Orange glow for shadows (unified)
    static let glowOrange = Color(hex: 0xF39C12)         // Unified orange glow color

    // Legacy aliases
    static let goldLight = goldBright

    // MARK: - Feedback Colors

    static let danger = Color(hex: 0xE63946)          // Danger, defeat, HP critical
    static let dangerGlow = Color(hex: 0xE63946).opacity(0.25)
    static let success = Color(hex: 0x2ECC71)         // Victory, HP high
    static let successGlow = Color(hex: 0x2ECC71).opacity(0.25)
    static let info = Color(hex: 0x3498DB)            // Info, links, mana
    static let cyan = Color(hex: 0x00D4FF)            // Enchanted/premium accents
    static let purple = Color(hex: 0x9B59B6)          // XP, magic, epic

    // Legacy aliases — DEPRECATED: use canonical names instead
    static let hpRed = danger
    @available(*, deprecated, message: "Misleading name: was blood-red, not green. Use danger instead.")
    static let hpGreen = Color(hex: 0xC41E3A)
    static let hpBlood = Color(hex: 0xC41E3A)          // Blood-red HP text color
    static let stamina = Color(hex: 0xE67E22)          // Orange stamina
    @available(*, deprecated, message: "Use purple instead — xpBlue is misleading.")
    static let xpBlue = purple
    static let gems = cyan

    // MARK: - Text Colors

    static let textPrimary = Color(hex: 0xF5F5F5)     // Main readable text (WCAG AAA)
    static let textSecondary = Color(hex: 0xA0A0B0)    // Subtitles, labels (WCAG AA)
    static let textTertiary = Color(hex: 0x6B6B80)     // Hints, placeholders
    static let textDisabled = Color(hex: 0x555566)     // Disabled states
    static let textGold = Color(hex: 0xFFD700)         // Currency, highlighted values
    static let textOnGold = Color(hex: 0x1A1A2E)       // Dark text ON gold backgrounds
    static let textDanger = Color(hex: 0xFF6B6B)       // Error messages
    static let textSuccess = Color(hex: 0x5DECA5)      // Positive changes, buffs

    // Legacy alias
    static let textMuted = textTertiary

    // MARK: - Border & Frame Colors

    static let borderSubtle = Color(hex: 0x2A2A3E)    // Panel borders, dividers
    static let borderMedium = Color(hex: 0x3A3A50)    // Metallic highlight
    static let borderStrong = Color(hex: 0x4A4A60)    // Active element borders
    static let borderGold = gold                        // Selected items, active tabs
    static let borderOrnament = Color(hex: 0xB8860B)   // Ornamental engravings

    // Legacy alias
    static let borderDefault = borderSubtle

    // MARK: - Rarity Colors

    static let rarityCommon = Color(hex: 0x999999)
    static let rarityUncommon = Color(hex: 0x4DCC4D)
    static let rarityRare = Color(hex: 0x4D80FF)
    static let rarityEpic = Color(hex: 0xA64DE6)
    static let rarityLegendary = Color(hex: 0xFFBF1A)

    // Rarity Glows
    static let rarityCommonGlow = Color(hex: 0x999999).opacity(0.13)
    static let rarityUncommonGlow = Color(hex: 0x4DCC4D).opacity(0.19)
    static let rarityRareGlow = Color(hex: 0x4D80FF).opacity(0.25)
    static let rarityEpicGlow = Color(hex: 0xA64DE6).opacity(0.31)
    static let rarityLegendaryGlow = Color(hex: 0xFFBF1A).opacity(0.38)

    // MARK: - Stat Colors (Unified Gold Palette)
    //
    // All stats use gold shades for visual cohesion.
    // Boosted stats (above base 5) render with statBoosted (bright gold).
    // Base stats render with statBase (dim gold).
    // Use statBarColor(value:base:) helper for automatic selection.

    static let statBoosted = Color(hex: 0xFFD700)     // goldBright — for stats above base
    static let statBase = Color(hex: 0x8B6914)         // goldDim — for base-level stats
    static let statBarFill = Color(hex: 0xD4A537)      // gold — standard bar fill

    /// Returns bright gold for boosted stats, dim gold for base stats.
    static func statBarColor(value: Int, base: Int = 5) -> Color {
        value > base ? statBoosted : statBase
    }

    /// Gradient for stat bar fill — brighter for higher values.
    static func statBarGradient(value: Int, base: Int = 5) -> LinearGradient {
        let color = value > base ? statBoosted : statBarFill
        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // Legacy stat colors — DEPRECATED: use statBarColor(value:base:) instead
    @available(*, deprecated, message: "Use statBarColor(value:base:) or statBoosted/statBase instead")
    static let statSTR = Color(hex: 0xE6594D)   // Crimson
    @available(*, deprecated, message: "Use statBarColor(value:base:) or statBoosted/statBase instead")
    static let statAGI = Color(hex: 0x4DE666)   // Emerald
    @available(*, deprecated, message: "Use statBarColor(value:base:) or statBoosted/statBase instead")
    static let statVIT = Color(hex: 0xE68080)   // Rose
    @available(*, deprecated, message: "Use statBarColor(value:base:) or statBoosted/statBase instead")
    static let statEND = Color(hex: 0xB3B34D)   // Amber
    @available(*, deprecated, message: "Use statBarColor(value:base:) or statBoosted/statBase instead")
    static let statINT = Color(hex: 0x6680FF)   // Sapphire
    @available(*, deprecated, message: "Use statBarColor(value:base:) or statBoosted/statBase instead")
    static let statWIS = Color(hex: 0x9966E6)   // Violet
    @available(*, deprecated, message: "Use statBarColor(value:base:) or statBoosted/statBase instead")
    static let statLUK = Color(hex: 0xE6D94D)   // Gold
    @available(*, deprecated, message: "Use statBarColor(value:base:) or statBoosted/statBase instead")
    static let statCHA = Color(hex: 0xE699CC)   // Blush

    // MARK: - Class Colors

    static let classWarrior = Color(hex: 0xE68C33)  // Ember Orange
    static let classRogue = Color(hex: 0x4DD958)     // Venom Green
    static let classMage = Color(hex: 0x6680FF)      // Arcane Blue
    static let classTank = Color(hex: 0x9999B2)      // Iron Gray

    // MARK: - Rank Colors

    static let rankBronze = Color(hex: 0xB38040)
    static let rankSilver = Color(hex: 0xBFBFCC)
    static let rankGold = Color(hex: 0xFFD600)
    static let rankPlatinum = Color(hex: 0x66CCCC)
    static let rankDiamond = Color(hex: 0x99CCFF)
    static let rankGrandmaster = Color(hex: 0xFF4D4D)

    // MARK: - Hub Character Card Colors

    static let xpRing = Color(hex: 0x5DADE2)           // XP ring on avatar
    static let xpRingTrack = Color(hex: 0x2A2A4A)      // XP ring background track
    static let textWarning = Color(hex: 0xFFA502)       // Warning/amber status text
    static let textStatusGood = Color(hex: 0x7BED9F)    // "Battle Ready" status
    static let bgCardGradientStart = Color(hex: 0x1C1C30)  // Character card gradient start
    static let bgCardGradientEnd = Color(hex: 0x2A2A40)    // Character card gradient end
    static let bgCardBorder = Color(hex: 0x3A3A55)         // Character card border
    static let bgDarkPanel = Color(hex: 0x141428)          // Dark panel bg (arena header)
    static let bgDarkPanelBorder = Color(hex: 0x252545)    // Dark panel border
    static let textDimLabel = Color(hex: 0x4A4A6A)         // Dim labels (arena, loadout)

    static let bgCardGradient = LinearGradient(
        colors: [bgCardGradientStart, bgCardGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let bgCardGradientVertical = LinearGradient(
        colors: [bgCardGradientStart, bgCardGradientEnd],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - HP Bar Gradients (Canonical: green → amber → red)

    static let hpFullGradient = LinearGradient(
        colors: [Color(hex: 0x2ECC71), Color(hex: 0x55EFC4)],
        startPoint: .leading, endPoint: .trailing
    )
    static let hpGoodGradient = LinearGradient(
        colors: [Color(hex: 0x2ECC71), Color(hex: 0x7BED9F)],
        startPoint: .leading, endPoint: .trailing
    )
    static let hpMediumGradient = LinearGradient(
        colors: [Color(hex: 0xE67E22), Color(hex: 0xF1C40F)],
        startPoint: .leading, endPoint: .trailing
    )
    static let hpCriticalGradient = LinearGradient(
        colors: [Color(hex: 0xC0392B), Color(hex: 0xE74C3C)],
        startPoint: .leading, endPoint: .trailing
    )

    /// Canonical HP gradient — use this everywhere instead of blood-red variants
    static func canonicalHpGradient(percentage: Double) -> LinearGradient {
        if percentage >= 1.0 { return hpFullGradient }
        if percentage >= 0.75 { return hpGoodGradient }
        if percentage >= 0.25 { return hpMediumGradient }
        return hpCriticalGradient
    }

    // MARK: - Durability Colors

    static let durabilityGood = Color(hex: 0x2ECC71)    // >60%
    static let durabilityMedium = Color(hex: 0xE67E22)   // 30-60%
    static let durabilityLow = Color(hex: 0xE63946)      // <30%

    static func durabilityColor(fraction: Double) -> Color {
        if fraction > 0.6 { return durabilityGood }
        if fraction > 0.3 { return durabilityMedium }
        return durabilityLow
    }

    // MARK: - Button Disabled Background

    static let bgDisabled = Color(hex: 0x333340)

    // MARK: - Refresh / Stamina Button Gradient

    static let staminaButtonGradient = LinearGradient(
        colors: [Color(hex: 0xD35400), Color(hex: 0xF39C12)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Arena Rank Display Color

    static let arenaRankGold = Color(hex: 0xF39C12)

    // MARK: - Heal Flash

    static let healFlash = Color(hex: 0x2ECC71)

    // MARK: - Dungeon Colors

    static let bgDungeonDeep = Color(hex: 0x0C0C18)       // Darkest dungeon background
    static let bgDungeonPurple = Color(hex: 0x120E24)      // Deep purple dungeon overlay
    static let bgDungeonCard = Color(hex: 0x1A1A30)        // Dungeon node/card background
    static let bossBorderPurple = Color(hex: 0x6C3483)     // Boss card border
    static let lootGold = Color(hex: 0xF1C40F)             // Loot/reward gold highlight
    static let textBossDesc = Color(hex: 0x8A8AAA)         // Boss description text
    static let lockedGray = Color(hex: 0x2A2A45)           // Locked node fill
    static let textLocked = Color(hex: 0x3A3A5A)           // Locked button text
    static let defeatedGreen = Color(hex: 0x1A9C54)        // Defeated boss border

    static let bgDungeonGradient = LinearGradient(
        colors: [bgDungeonDeep, bgDungeonPurple, bgDungeonDeep],
        startPoint: .top, endPoint: .bottom
    )

    // Boss card gradient
    static let bossCardGradient = LinearGradient(
        colors: [Color(hex: 0x1A1230), bgDungeonPurple, bgDungeonDeep],
        startPoint: .top, endPoint: .bottom
    )

    // Dungeon HP bar (blood-red, intentionally different from canonical green→red)
    static let dungeonHpGradient = LinearGradient(
        colors: [Color(hex: 0xC0392B), Color(hex: 0xE74C3C), Color(hex: 0xFF6B6B)],
        startPoint: .leading, endPoint: .trailing
    )

    // MARK: - Arena Colors

    static let bgArenaSheet = LinearGradient(
        colors: [Color(hex: 0x1A1A35), Color(hex: 0x111128)],
        startPoint: .top, endPoint: .bottom
    )

    static let bgArenaCard = LinearGradient(
        colors: [Color(hex: 0x161630), Color(hex: 0x111125)],
        startPoint: .top, endPoint: .bottom
    )

    // Fight button gradient (same colors as staminaButtonGradient)
    static let fightButtonGradient = staminaButtonGradient

    // Arena Premium Card
    static let bgArenaCardPremium = LinearGradient(
        colors: [Color(hex: 0x1A1A38), Color(hex: 0x12122A), Color(hex: 0x0E0E20)],
        startPoint: .top, endPoint: .bottom
    )
    static let arenaCardInnerGlow = Color(hex: 0x2A2A50)  // Subtle inner lighting
    static let arenaShimmerColor = Color.white.opacity(0.07) // Moving shine

    // Difficulty colors — semantic aliases
    static let difficultyEasy = success               // 0x2ECC71
    static let difficultyMedium = arenaRankGold        // 0xF39C12
    static let difficultyHard = Color(hex: 0xE74C3C)  // Slightly different from danger

    // MARK: - Premium / Shop Colors

    static let premiumPink = Color(hex: 0xE5A0FF)         // Premium icon, text, border
    static let bgPremium = Color(hex: 0x2A1040)            // Premium button background
    static let bgPremiumDeep = Color(hex: 0x1A0A2E)        // Premium skin cell background
    static let borderPremium = Color(hex: 0x352050)         // Unselected premium border

    // MARK: - VFX Glow Colors

    static let vfxPoisonGlow = Color(hex: 0x7CFC00)       // Poison glow (brighter green)
    static let vfxBurnGlow = Color(hex: 0xFF6B35)          // Burn glow (orange-red)
    static let vfxStunGlow = Color(hex: 0xFFF8DC)          // Stun glow (cornsilk/cream)

    // MARK: - Toast Indicator Colors

    static let toastAchievement = goldBright                     // Gold dot for achievements
    static let toastLevelUp     = Color(hex: 0x66FF66)           // Bright green for level-up
    static let toastRankUp      = Color(hex: 0x9966FF)           // Bright purple for rank-up
    static let toastQuest       = cyan                           // Cyan dot for quest completion
    static let toastReward      = stamina                        // Orange dot for rewards
    static let toastInfo        = Color(hex: 0xCCCCDA)           // Neutral light for info
    static let toastError       = textDanger                     // Red dot for errors

    // MARK: - Unified Hero Widget Pill Colors

    /// WCAG AA compliant tertiary text (≥4.5:1 on dark bg). Use in widget + pills.
    static let textTertiaryAA = Color(hex: 0x8A8AA0)

    // Pill: Heal (green, for health potion action)
    static let pillHealBg = Color(hex: 0x2ECC71, opacity: 0.12)
    static let pillHealBorder = Color(hex: 0x2ECC71, opacity: 0.25)
    static let pillHealText = textStatusGood

    // Pill: Urgent Heal (red, critical HP + potion available)
    static let pillUrgentBg = Color(hex: 0xE63946, opacity: 0.12)
    static let pillUrgentBorder = Color(hex: 0xE63946, opacity: 0.30)
    static let pillUrgentText = textDanger

    // Pill: Energy (orange, stamina potion action)
    static let pillEnergyBg = Color(hex: 0xE67E22, opacity: 0.12)
    static let pillEnergyBorder = Color(hex: 0xE67E22, opacity: 0.25)
    static let pillEnergyText = stamina

    // Pill: Stat Points (gold, level up → allocate)
    static let pillStatBg = Color(hex: 0xD4A537, opacity: 0.12)
    static let pillStatBorder = Color(hex: 0xD4A537, opacity: 0.30)
    static let pillStatText = goldBright

    // Pill: Warning (red, broken gear / critical / no potions)
    static let pillWarnBg = Color(hex: 0xE63946, opacity: 0.10)
    static let pillWarnBorder = Color(hex: 0xE63946, opacity: 0.20)
    static let pillWarnText = textDanger

    // Pill: PvP (gold tint, arena rating)
    static let pillPvpBg = Color(hex: 0xD4A537, opacity: 0.08)
    static let pillPvpBorder = Color(hex: 0xD4A537, opacity: 0.15)

    // Pill: Win Streak (red tint)
    static let pillStreakBg = Color(hex: 0xE63946, opacity: 0.08)
    static let pillStreakBorder = Color(hex: 0xE63946, opacity: 0.15)

    // Pill: Bonus (green tint, first win)
    static let pillBonusBg = Color(hex: 0x2ECC71, opacity: 0.10)
    static let pillBonusBorder = Color(hex: 0x2ECC71, opacity: 0.20)

    // Pill: Error (red, API failure)
    static let pillErrorBg = Color(hex: 0xE63946, opacity: 0.10)
    static let pillErrorBorder = Color(hex: 0xE63946, opacity: 0.20)

    // Pill: Offline (neutral, cached data indicator)
    static let pillOfflineBg = Color.white.opacity(0.04)
    static let pillOfflineBorder = Color.white.opacity(0.08)
    static let pillOfflineText = textSecondary

    // XP bar golden variant (for level-up imminent state)
    static let xpGoldenGradient = LinearGradient(
        colors: [gold, goldBright],
        startPoint: .leading, endPoint: .trailing
    )

    // MARK: - Button Chrome Colors
    //
    // Used by ButtonStyles.swift for danger, orange (fight/stamina),
    // and purple (premium) button styles. Never hardcode Color(hex:) in ButtonStyles.

    // Danger button chrome (dark crimson)
    static let btnDangerFill = Color(hex: 0x8B1A22)         // Danger button base fill
    static let btnDangerStroke = Color(hex: 0x5A0A10)       // Danger button outer stroke
    static let btnDangerAccent = Color(hex: 0xFF6B6B)       // Danger button corner diamonds

    // Orange button chrome (fight, stamina)
    static let btnOrangePrimary = Color(hex: 0xFF6600)      // Orange buttons primary — same as glowFire
    static let btnOrangeBright = Color(hex: 0xFF8833)        // Orange bright accent — same as glowEmber
    static let btnOrangeGlow = Color(hex: 0xFF5000)          // Orange shadow glow
    static let btnOrangeShine = Color(hex: 0xFF7832)         // Orange shimmer highlight
    static let btnOrangeStroke = Color(hex: 0x4A1500)        // Orange button dark stroke
    static let btnOrangeDark = Color(hex: 0x8B1A00)          // Orange gradient dark end
    static let btnOrangeMid = Color(hex: 0xC44200)           // Orange gradient mid
    static let btnOrangeBase = Color(hex: 0xD35400)          // Orange gradient base

    // Purple button chrome (premium)
    static let btnPurpleDark = Color(hex: 0x7B2D8E)         // Purple gradient dark end
    static let btnPurpleBright = Color(hex: 0xC77DDF)        // Purple gradient bright end
    static let btnPurpleStroke = Color(hex: 0x6C3483)        // Purple button stroke — same as bossBorderPurple

    // MARK: - Misc UI Colors

    static let upgradeBlue = Color(hex: 0x60A5FA)          // Max upgrade level highlight

    // MARK: - Stance Zone Colors

    static let zoneHead = Color(hex: 0xE66666)
    static let zoneChest = Color(hex: 0x6699E6)
    static let zoneLegs = Color(hex: 0x66E666)

    // MARK: - City Map Sky & Atmosphere

    static let skyNight = Color(hex: 0x0A0A12)             // Night sky background
    static let moonGlowOuter1 = Color(hex: 0xE8E0D0)       // Moon halo — warm outer
    static let moonGlowOuter2 = Color(hex: 0xCCBBAA)       // Moon halo — mid ring
    static let moonGlowOuter3 = Color(hex: 0x8888AA)       // Moon halo — cool fringe
    static let moonGlowInner1 = Color(hex: 0xFFF8E8)       // Moon core — bright
    static let moonGlowInner2 = Color(hex: 0xDDCCAA)       // Moon core — warm falloff
    static let fogLight = Color(hex: 0x2A2A3A)             // Fog strip — lightest
    static let fogMid = Color(hex: 0x1A1A2A)               // Fog strip — mid
    static let fogDark = Color(hex: 0x0A0A15)              // Fog strip — darkest

    // MARK: - City Map Glow Effects

    static let glowFire = Color(hex: 0xFF6600)            // Firepit / torch glow
    static let glowWarm = Color(hex: 0xFFAA33)            // Warm ambient light
    static let glowEmber = Color(hex: 0xFF8833)            // Ember glow

    // MARK: - Dungeon Building Glow Colors

    static let glowArena = Color(hex: 0xE68C33)           // Arena building
    static let glowMystic = Color(hex: 0x8040B0)          // Mystic / magic building
    static let glowForge = Color(hex: 0xFF6626)           // Forge / smithing
    static let glowNature = Color(hex: 0x4CAF50)          // Nature / healing
    static let glowVolcanic = Color(hex: 0xE65100)        // Volcanic / fire
    static let glowIce = Color(hex: 0x42A5F5)             // Ice / water
    static let glowTreasure = Color(hex: 0xFFD54F)        // Treasure / gold
    static let glowShadow = Color(hex: 0x424242)          // Shadow / dark
    static let glowStone = Color(hex: 0x78909C)           // Stone / neutral
    static let glowBlood = Color(hex: 0xB71C1C)           // Blood / boss

    // MARK: - Daily Login Gradients

    static let dailyGradientTopGold = Color(hex: 0x3D2E0A)
    static let dailyGradientBottomGold = Color(hex: 0x2A1F05)
    static let dailyGradientTopGreen = Color(hex: 0x1A3A1A)
    static let dailyGradientBottomGreen = Color(hex: 0x0A2A0A)

    // MARK: - Fonts (AAA Typography Scale)

    // Oswald — titles, hero names, cinematic text, section headers, button labels
    static let title = Font.custom("Oswald-Regular", size: 28)
    static let cinematicTitle = Font.custom("Oswald-Regular", size: 40)

    // Oswald — section headers, button labels, card titles
    static let section = Font.custom("Oswald-Regular", size: 22)
    static let cardTitle = Font.custom("Oswald-Regular", size: 18)
    static let buttonLabel = Font.custom("Oswald-Regular", size: 18)

    // Inter — body text, UI labels, captions
    static let body = Font.custom("Inter-Regular", size: 16)
    static let uiLabel = Font.custom("Inter-Regular", size: 14)
    static let caption = Font.custom("Inter-Regular", size: 12)
    static let badge = Font.custom("Inter-Regular", size: 11).bold()

    // Dynamic size helpers
    static func title(size: CGFloat) -> Font { .custom("Oswald-Regular", size: size) }
    static func section(size: CGFloat) -> Font { .custom("Oswald-Regular", size: size) }
    static func body(size: CGFloat) -> Font { .custom("Inter-Regular", size: size) }

    // MARK: - Gradients

    // Gold button gradient
    static let goldGradient = LinearGradient(
        colors: [gold, Color(hex: 0xB8860B)],
        startPoint: .top,
        endPoint: .bottom
    )

    // HP bar gradients — DEPRECATED: use canonicalHpGradient(percentage:) instead
    // These blood-red variants reduce information density. Kept for backward compatibility.
    @available(*, deprecated, message: "Use canonicalHpGradient(percentage:) instead")
    static let hpHighGradient = LinearGradient(
        colors: [Color(hex: 0xC41E3A), Color(hex: 0x9B1B30)],
        startPoint: .leading, endPoint: .trailing
    )
    static let hpMidGradient = LinearGradient(
        colors: [Color(hex: 0xA01830), Color(hex: 0x801525)],
        startPoint: .leading, endPoint: .trailing
    )
    static let hpLowGradient = LinearGradient(
        colors: [Color(hex: 0x80101E), Color(hex: 0x600C18)],
        startPoint: .leading, endPoint: .trailing
    )

    // XP bar gradient (purple)
    static let xpGradient = LinearGradient(
        colors: [Color(hex: 0x9B59B6), Color(hex: 0x8E44AD)],
        startPoint: .leading, endPoint: .trailing
    )

    // Stamina bar gradient (orange)
    static let staminaGradient = LinearGradient(
        colors: [Color(hex: 0xE67E22), Color(hex: 0xD35400)],
        startPoint: .leading, endPoint: .trailing
    )

    // Progress bar gradient (gold)
    static let progressGradient = LinearGradient(
        colors: [Color(hex: 0xD4A537), Color(hex: 0xB8860B)],
        startPoint: .leading, endPoint: .trailing
    )

    // Background gradient
    static let bgGradient = LinearGradient(
        colors: [bgPrimary, Color(hex: 0x0D0D18)],
        startPoint: .top, endPoint: .bottom
    )

    // MARK: - Helpers

    static func classColor(for charClass: CharacterClass) -> Color {
        switch charClass {
        case .warrior: classWarrior
        case .rogue: classRogue
        case .mage: classMage
        case .tank: classTank
        }
    }

    static func rarityColor(for rarity: ItemRarity) -> Color {
        switch rarity {
        case .common: rarityCommon
        case .uncommon: rarityUncommon
        case .rare: rarityRare
        case .epic: rarityEpic
        case .legendary: rarityLegendary
        }
    }

    static func rarityGlow(for rarity: ItemRarity) -> Color {
        switch rarity {
        case .common: rarityCommonGlow
        case .uncommon: rarityUncommonGlow
        case .rare: rarityRareGlow
        case .epic: rarityEpicGlow
        case .legendary: rarityLegendaryGlow
        }
    }

    static func rankColor(for rating: Int) -> Color {
        switch rating {
        case ..<1200: rankBronze
        case 1200..<1500: rankSilver
        case 1500..<1800: rankGold
        case 1800..<2100: rankPlatinum
        case 2100..<2400: rankDiamond
        default: rankGrandmaster
        }
    }

    @available(*, deprecated, message: "Use canonicalHpGradient(percentage:) instead")
    static func hpGradient(percentage: Double) -> LinearGradient {
        canonicalHpGradient(percentage: percentage)
    }

    /// Unified stat color — always gold. Use statBarColor(value:base:) for boosted/base distinction.
    static func statColor(for stat: String) -> Color {
        statBarFill
    }
}

// MARK: - Color hex initializer

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - Color convenience accessors (enables .bgAbyss / .textPrimary shorthand)

extension Color {
    static var bgAbyss: Color { DarkFantasyTheme.bgAbyss }
    static var bgPrimary: Color { DarkFantasyTheme.bgPrimary }
    static var bgBackdropLight: Color { DarkFantasyTheme.bgBackdropLight }
    static var textPrimary: Color { DarkFantasyTheme.textPrimary }
}

extension ShapeStyle where Self == Color {
    static var bgAbyss: Color { DarkFantasyTheme.bgAbyss }
    static var bgPrimary: Color { DarkFantasyTheme.bgPrimary }
    static var bgBackdropLight: Color { DarkFantasyTheme.bgBackdropLight }
    static var textPrimary: Color { DarkFantasyTheme.textPrimary }
}
