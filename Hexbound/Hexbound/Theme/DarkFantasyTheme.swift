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
    static let goldGlow = Color(hex: 0xD4A537).opacity(0.4) // Gold glow for shadows

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

    // MARK: - Stat Colors

    static let statSTR = Color(hex: 0xE6594D)   // Crimson
    static let statAGI = Color(hex: 0x4DE666)   // Emerald
    static let statVIT = Color(hex: 0xE68080)   // Rose
    static let statEND = Color(hex: 0xB3B34D)   // Amber
    static let statINT = Color(hex: 0x6680FF)   // Sapphire
    static let statWIS = Color(hex: 0x9966E6)   // Violet
    static let statLUK = Color(hex: 0xE6D94D)   // Gold
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

    // MARK: - Misc UI Colors

    static let upgradeBlue = Color(hex: 0x60A5FA)          // Max upgrade level highlight

    // MARK: - Stance Zone Colors

    static let zoneHead = Color(hex: 0xE66666)
    static let zoneChest = Color(hex: 0x6699E6)
    static let zoneLegs = Color(hex: 0x66E666)

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

    static func statColor(for stat: String) -> Color {
        switch stat.uppercased() {
        case "STR", "STRENGTH": statSTR
        case "AGI", "AGILITY": statAGI
        case "VIT", "VITALITY": statVIT
        case "END", "ENDURANCE": statEND
        case "INT", "INTELLIGENCE": statINT
        case "WIS", "WISDOM": statWIS
        case "LUK", "LUCK": statLUK
        case "CHA", "CHARISMA": statCHA
        default: textSecondary
        }
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
