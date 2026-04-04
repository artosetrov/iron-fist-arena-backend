import SwiftUI

enum DarkFantasyTheme {

    // ╔══════════════════════════════════════════════════════════╗
    // ║  CORE PALETTE — unique hex values. Every color in the   ║
    // ║  system is either defined here or aliases one of these. ║
    // ╚══════════════════════════════════════════════════════════╝

    // MARK: - Background & Surface Colors

    static let bgAbyss = Color(hex: 0x08080C)       // Deepest black — behind modals
    static let bgPrimary = Color(hex: 0x0D0D12)     // Main screen background
    static let bgSecondary = Color(hex: 0x1A1A2E)   // Panel backgrounds, cards
    static let bgTertiary = Color(hex: 0x16213E)    // Card interiors, form fields
    static let bgElevated = Color(hex: 0x1E2240)    // Active cards, selected items
    static let bgDisabled = Color(hex: 0x333340)    // Disabled button background
    static let bgSecondaryPressed = Color(hex: 0x18182B) // Pressed state of bgSecondary
    static let bgTertiaryPressed = Color(hex: 0x151F3A)  // Pressed state of bgTertiary
    static let bgModal = Color.black.opacity(0.75)   // Modal overlay
    static let bgBackdrop = Color.black.opacity(0.85) // Heavy backdrop for sheets
    static let bgBackdropLight = Color.black.opacity(0.7) // Lighter backdrop for popups
    static let bgScrim = Color.black.opacity(0.5)   // Semi-transparent scrim fill

    // MARK: - Gold Accent System

    static let gold = Color(hex: 0xD4A537)           // Primary CTA, gold buttons
    static let goldBright = Color(hex: 0xFFD700)     // Highlighted text, important values
    static let goldDim = Color(hex: 0x8B6914)        // Disabled gold, inactive
    static let goldGlow = Color(hex: 0xF39C12).opacity(0.4) // Orange glow for shadows

    // MARK: - Feedback Colors

    static let danger = Color(hex: 0xE63946)          // Danger, defeat, HP critical
    static let dangerGlow = danger.opacity(0.25)
    static let success = Color(hex: 0x2ECC71)         // Victory, HP high, heal
    static let successGlow = success.opacity(0.25)
    static let info = Color(hex: 0x3498DB)            // Info, links, mana
    static let cyan = Color(hex: 0x00D4FF)            // Enchanted/premium accents
    static let purple = Color(hex: 0x9B59B6)          // XP, magic, epic
    static let stamina = Color(hex: 0xE67E22)         // Orange stamina

    // Semantic aliases
    static let gems = cyan
    static let healFlash = success

    // MARK: - Text Colors

    static let textPrimary = Color(hex: 0xF5F5F5)     // Main readable text (WCAG AAA)
    static let textSecondary = Color(hex: 0xA0A0B0)   // Subtitles, labels (WCAG AA)
    static let textTertiary = Color(hex: 0x6B6B80)    // Hints, placeholders
    static let textTertiaryAA = Color(hex: 0x8A8AA0)  // WCAG AA compliant tertiary (≥4.5:1)
    static let textDisabled = Color(hex: 0x555566)     // Disabled states
    static let textGold = goldBright                   // Currency, highlighted values (= 0xFFD700)
    static let textOnGold = Color(hex: 0x1A1A2E)      // Dark text ON gold backgrounds
    static let textDanger = Color(hex: 0xFF6B6B)       // Error messages
    static let textSuccess = Color(hex: 0x5DECA5)      // Positive changes, buffs
    static let textWarning = Color(hex: 0xFFA502)      // Warning/amber status text
    static let textStatusGood = Color(hex: 0x7BED9F)   // "Battle Ready" status
    static let textDimLabel = Color(hex: 0x4A4A6A)     // Dim labels (arena, loadout)
    static let textBossDesc = Color(hex: 0x8A8AAA)     // Boss description text
    static let textLocked = Color(hex: 0x3A3A5A)       // Locked button text

    // MARK: - Border & Frame Colors

    static let borderSubtle = Color(hex: 0x2A2A3E)    // Panel borders, dividers
    static let borderMedium = Color(hex: 0x3A3A50)    // Metallic highlight
    static let borderStrong = Color(hex: 0x4A4A60)    // Active element borders
    static let borderGold = gold                       // Selected items, active tabs
    static let borderOrnament = Color(hex: 0xB8860B)   // Ornamental engravings

    // MARK: - Rarity Colors

    static let rarityCommon = Color(hex: 0x999999)
    static let rarityUncommon = Color(hex: 0x4DCC4D)
    static let rarityRare = Color(hex: 0x4D80FF)
    static let rarityEpic = Color(hex: 0xA64DE6)
    static let rarityLegendary = Color(hex: 0xFFBF1A)

    static let rarityCommonGlow = rarityCommon.opacity(0.13)
    static let rarityUncommonGlow = rarityUncommon.opacity(0.19)
    static let rarityRareGlow = rarityRare.opacity(0.25)
    static let rarityEpicGlow = rarityEpic.opacity(0.31)
    static let rarityLegendaryGlow = rarityLegendary.opacity(0.38)

    // MARK: - Stat Colors (Unified Gold Palette)

    static let statBoosted = goldBright                // Bright gold — stats above base (= 0xFFD700)
    static let statBase = goldDim                      // Dim gold — base-level stats (= 0x8B6914)
    static let statBarFill = gold                      // Standard bar fill (= 0xD4A537)

    static func statBarColor(value: Int, base: Int = 5) -> Color {
        value > base ? statBoosted : statBase
    }

    static func statBarGradient(value: Int, base: Int = 5) -> LinearGradient {
        let color = value > base ? statBoosted : statBarFill
        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .leading, endPoint: .trailing
        )
    }

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

    static let xpRing = Color(hex: 0x5DADE2)
    static let xpRingTrack = Color(hex: 0x2A2A4A)
    static let bgCardGradientStart = Color(hex: 0x1C1C30)
    static let bgCardGradientEnd = Color(hex: 0x2A2A40)
    static let bgCardBorder = Color(hex: 0x3A3A55)
    static let bgDarkPanel = Color(hex: 0x141428)
    static let bgDarkPanelBorder = Color(hex: 0x252545)

    static let bgCardGradient = LinearGradient(
        colors: [bgCardGradientStart, bgCardGradientEnd],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let bgCardGradientVertical = LinearGradient(
        colors: [bgCardGradientStart, bgCardGradientEnd],
        startPoint: .top, endPoint: .bottom
    )

    // MARK: - HP Bar Gradients (Canonical: green → amber → red)

    static let hpFullGradient = LinearGradient(
        colors: [success, Color(hex: 0x55EFC4)],
        startPoint: .leading, endPoint: .trailing
    )
    static let hpGoodGradient = LinearGradient(
        colors: [success, textStatusGood],
        startPoint: .leading, endPoint: .trailing
    )
    static let hpMediumGradient = LinearGradient(
        colors: [stamina, Color(hex: 0xF1C40F)],
        startPoint: .leading, endPoint: .trailing
    )
    static let hpCriticalGradient = LinearGradient(
        colors: [Color(hex: 0xC0392B), Color(hex: 0xE74C3C)],
        startPoint: .leading, endPoint: .trailing
    )

    static func canonicalHpGradient(percentage: Double) -> LinearGradient {
        if percentage >= 1.0 { return hpFullGradient }
        if percentage >= 0.75 { return hpGoodGradient }
        if percentage >= 0.25 { return hpMediumGradient }
        return hpCriticalGradient
    }

    // MARK: - Durability Colors (aliases to feedback)

    static let durabilityGood = success          // >60%  (= 0x2ECC71)
    static let durabilityMedium = stamina         // 30-60% (= 0xE67E22)
    static let durabilityLow = danger             // <30%  (= 0xE63946)

    static func durabilityColor(fraction: Double) -> Color {
        if fraction > 0.6 { return durabilityGood }
        if fraction > 0.3 { return durabilityMedium }
        return durabilityLow
    }

    // MARK: - Stance Zone Colors

    static let zoneHead = Color(hex: 0xE66666)
    static let zoneChest = Color(hex: 0x6699E6)
    static let zoneLegs = Color(hex: 0x66E666)

    // MARK: - Dungeon Colors

    static let bgDungeonDeep = Color(hex: 0x0C0C18)
    static let bgDungeonPurple = Color(hex: 0x120E24)
    static let bgDungeonCard = Color(hex: 0x1A1A30)
    static let bossBorderPurple = Color(hex: 0x6C3483)
    static let lootGold = Color(hex: 0xF1C40F)
    static let lockedGray = Color(hex: 0x2A2A45)
    static let defeatedGreen = Color(hex: 0x1A9C54)

    static let bgDungeonGradient = LinearGradient(
        colors: [bgDungeonDeep, bgDungeonPurple, bgDungeonDeep],
        startPoint: .top, endPoint: .bottom
    )

    static let bossCardGradient = LinearGradient(
        colors: [Color(hex: 0x1A1230), bgDungeonPurple, bgDungeonDeep],
        startPoint: .top, endPoint: .bottom
    )

    static let dungeonHpGradient = LinearGradient(
        colors: [Color(hex: 0xC0392B), Color(hex: 0xE74C3C), textDanger],
        startPoint: .leading, endPoint: .trailing
    )

    // MARK: - Arena Colors

    static let arenaRankGold = Color(hex: 0xF39C12) // Also used as difficultyMedium
    static let arenaCardInnerGlow = Color(hex: 0x2A2A50)
    static let arenaShimmerColor = Color.white.opacity(0.07)

    static let bgArenaSheet = LinearGradient(
        colors: [Color(hex: 0x1A1A35), Color(hex: 0x111128)],
        startPoint: .top, endPoint: .bottom
    )

    static let bgArenaCard = LinearGradient(
        colors: [Color(hex: 0x161630), Color(hex: 0x111125)],
        startPoint: .top, endPoint: .bottom
    )

    static let bgArenaCardPremium = LinearGradient(
        colors: [Color(hex: 0x1A1A38), Color(hex: 0x12122A), Color(hex: 0x0E0E20)],
        startPoint: .top, endPoint: .bottom
    )

    // Difficulty colors — semantic aliases
    static let difficultyEasy = success
    static let difficultyMedium = arenaRankGold
    static let difficultyHard = Color(hex: 0xE74C3C)

    // MARK: - Premium / Shop Colors

    static let premiumPink = Color(hex: 0xE5A0FF)
    static let bgPremium = Color(hex: 0x2A1040)
    static let bgPremiumDeep = Color(hex: 0x1A0A2E)
    static let borderPremium = Color(hex: 0x352050)

    // MARK: - VFX Glow Colors

    static let vfxPoisonGlow = Color(hex: 0x7CFC00)
    static let vfxBurnGlow = Color(hex: 0xFF6B35)
    static let vfxStunGlow = Color(hex: 0xFFF8DC)

    // MARK: - Toast Indicator Colors

    static let toastAchievement = goldBright
    static let toastLevelUp     = Color(hex: 0x66FF66)
    static let toastRankUp      = Color(hex: 0x9966FF)
    static let toastQuest       = cyan
    static let toastReward      = stamina
    static let toastInfo        = Color(hex: 0xCCCCDA)
    static let toastError       = textDanger

    // MARK: - Event Banner Colors

    static let eventNormalBg   = Color(hex: 0x29252F)  // Event banner normal bg tint
    static let eventUrgentBg   = Color(hex: 0x2A1E2F)  // Event banner urgent bg tint
    static let eventNormalIcon = Color(hex: 0x3F3630)  // Event banner normal icon bg
    static let eventUrgentIcon = Color(hex: 0x432431)  // Event banner urgent icon bg

    // MARK: - Payout Pill Backgrounds

    static let payoutX15Bg = Color(hex: 0x302B2F)     // x1.5 payout pill tinted bg
    static let payoutX2Bg  = Color(hex: 0x353128)     // x2 payout pill tinted bg
    static let payoutX3Bg  = Color(hex: 0x29223E)     // x3 payout pill tinted bg
    static let payoutX5Bg  = Color(hex: 0x1D2943)     // x5 payout pill tinted bg

    // ╔══════════════════════════════════════════════════════════╗
    // ║  PILL COLOR FACTORY — replaces 20 individual tokens     ║
    // ║  Usage: DarkFantasyTheme.pill(.heal, .bg)               ║
    // ╚══════════════════════════════════════════════════════════╝

    // MARK: - Pill System

    enum PillVariant { case heal, urgent, energy, stat, warn, pvp, streak, bonus, error, offline }
    enum PillLayer { case bg, border, text }

    /// Pill backgrounds, borders, and text — all derived from 4 base feedback colors.
    static func pill(_ variant: PillVariant, _ layer: PillLayer) -> Color {
        switch (variant, layer) {
        // Heal (green)
        case (.heal, .bg):     return success.opacity(0.12)
        case (.heal, .border): return success.opacity(0.25)
        case (.heal, .text):   return textStatusGood
        // Urgent (red, critical HP)
        case (.urgent, .bg):     return danger.opacity(0.12)
        case (.urgent, .border): return danger.opacity(0.30)
        case (.urgent, .text):   return textDanger
        // Energy (orange, stamina)
        case (.energy, .bg):     return stamina.opacity(0.12)
        case (.energy, .border): return stamina.opacity(0.25)
        case (.energy, .text):   return stamina
        // Stat Points (gold)
        case (.stat, .bg):     return gold.opacity(0.12)
        case (.stat, .border): return gold.opacity(0.30)
        case (.stat, .text):   return goldBright
        // Warning (red, broken gear)
        case (.warn, .bg):     return danger.opacity(0.10)
        case (.warn, .border): return danger.opacity(0.20)
        case (.warn, .text):   return textDanger
        // PvP (gold tint)
        case (.pvp, .bg):     return gold.opacity(0.08)
        case (.pvp, .border): return gold.opacity(0.15)
        case (.pvp, .text):   return goldBright
        // Win Streak (red tint)
        case (.streak, .bg):     return danger.opacity(0.08)
        case (.streak, .border): return danger.opacity(0.15)
        case (.streak, .text):   return textDanger
        // Bonus (green tint, first win)
        case (.bonus, .bg):     return success.opacity(0.10)
        case (.bonus, .border): return success.opacity(0.20)
        case (.bonus, .text):   return textSuccess
        // Error (red, API failure)
        case (.error, .bg):     return danger.opacity(0.10)
        case (.error, .border): return danger.opacity(0.20)
        case (.error, .text):   return textDanger
        // Offline (neutral)
        case (.offline, .bg):     return Color.white.opacity(0.04)
        case (.offline, .border): return Color.white.opacity(0.08)
        case (.offline, .text):   return textSecondary
        }
    }

    // Legacy pill tokens — kept for backward compat during migration
    static let pillHealBg = pill(.heal, .bg)
    static let pillHealBorder = pill(.heal, .border)
    static let pillHealText = pill(.heal, .text)
    static let pillUrgentBg = pill(.urgent, .bg)
    static let pillUrgentBorder = pill(.urgent, .border)
    static let pillUrgentText = pill(.urgent, .text)
    static let pillEnergyBg = pill(.energy, .bg)
    static let pillEnergyBorder = pill(.energy, .border)
    static let pillEnergyText = pill(.energy, .text)
    static let pillStatBg = pill(.stat, .bg)
    static let pillStatBorder = pill(.stat, .border)
    static let pillStatText = pill(.stat, .text)
    static let pillWarnBg = pill(.warn, .bg)
    static let pillWarnBorder = pill(.warn, .border)
    static let pillWarnText = pill(.warn, .text)
    static let pillPvpBg = pill(.pvp, .bg)
    static let pillPvpBorder = pill(.pvp, .border)
    static let pillStreakBg = pill(.streak, .bg)
    static let pillStreakBorder = pill(.streak, .border)
    static let pillBonusBg = pill(.bonus, .bg)
    static let pillBonusBorder = pill(.bonus, .border)
    static let pillErrorBg = pill(.error, .bg)
    static let pillErrorBorder = pill(.error, .border)
    static let pillOfflineBg = pill(.offline, .bg)
    static let pillOfflineBorder = pill(.offline, .border)
    static let pillOfflineText = pill(.offline, .text)

    // XP bar golden variant
    static let xpGoldenGradient = LinearGradient(
        colors: [gold, goldBright],
        startPoint: .leading, endPoint: .trailing
    )

    // MARK: - Button Chrome Colors

    // Danger button chrome
    static let btnDangerFill = Color(hex: 0x8B1A22)
    static let btnDangerStroke = Color(hex: 0x5A0A10)
    static let btnDangerAccent = textDanger             // = 0xFF6B6B (was duplicate)

    // Orange button chrome (fight, stamina)
    static let btnOrangePrimary = Color(hex: 0xFF6600)
    static let btnOrangeBright = Color(hex: 0xFF8833)
    static let btnOrangeGlow = Color(hex: 0xFF5000)
    static let btnOrangeShine = Color(hex: 0xFF7832)
    static let btnOrangeStroke = Color(hex: 0x4A1500)
    static let btnOrangeDark = Color(hex: 0x8B1A00)
    static let btnOrangeMid = Color(hex: 0xC44200)
    static let btnOrangeBase = Color(hex: 0xD35400)

    // Purple button chrome (premium)
    static let btnPurpleDark = Color(hex: 0x7B2D8E)
    static let btnPurpleBright = Color(hex: 0xC77DDF)
    static let btnPurpleStroke = bossBorderPurple       // = 0x6C3483 (was duplicate)

    // MARK: - Misc UI Colors

    static let upgradeBlue = Color(hex: 0x60A5FA)

    // MARK: - City Map Sky & Atmosphere

    static let skyNight = Color(hex: 0x0A0A12)
    static let moonGlowOuter1 = Color(hex: 0xE8E0D0)
    static let moonGlowOuter2 = Color(hex: 0xCCBBAA)
    static let moonGlowOuter3 = Color(hex: 0x8888AA)
    static let moonGlowInner1 = Color(hex: 0xFFF8E8)
    static let moonGlowInner2 = Color(hex: 0xDDCCAA)
    static let fogLight = Color(hex: 0x2A2A3A)
    static let fogMid = Color(hex: 0x1A1A2A)
    static let fogDark = Color(hex: 0x0A0A15)

    // MARK: - City Map Glow Effects

    static let glowFire = btnOrangePrimary              // = 0xFF6600 (was duplicate)
    static let glowWarm = Color(hex: 0xFFAA33)
    static let glowEmber = btnOrangeBright               // = 0xFF8833 (was duplicate)

    // Dungeon Building Glows
    static let glowArena = classWarrior                  // = 0xE68C33 (was duplicate)
    static let glowMystic = Color(hex: 0x8040B0)
    static let glowForge = Color(hex: 0xFF6626)
    static let glowNature = Color(hex: 0x4CAF50)
    static let glowVolcanic = Color(hex: 0xE65100)
    static let glowIce = Color(hex: 0x42A5F5)
    static let glowTreasure = Color(hex: 0xFFD54F)
    static let glowShadow = Color(hex: 0x424242)
    static let glowStone = Color(hex: 0x78909C)
    static let glowBlood = Color(hex: 0xB71C1C)

    // MARK: - Daily Login Gradients

    static let dailyGradientTopGold = Color(hex: 0x3D2E0A)
    static let dailyGradientBottomGold = Color(hex: 0x2A1F05)
    static let dailyGradientTopGreen = Color(hex: 0x1A3A1A)
    static let dailyGradientBottomGreen = Color(hex: 0x0A2A0A)

    // MARK: - Stamin Button Gradient

    static let staminaButtonGradient = LinearGradient(
        colors: [btnOrangeBase, arenaRankGold],
        startPoint: .leading, endPoint: .trailing
    )

    static let fightButtonGradient = staminaButtonGradient

    // ╔══════════════════════════════════════════════════════════╗
    // ║  FONTS                                                   ║
    // ╚══════════════════════════════════════════════════════════╝

    // MARK: - Fonts (AAA Typography Scale)

    // Oswald — titles, hero names, cinematic text, section headers, button labels
    static let cinematicTitle = Font.custom("Oswald-Regular", size: 40)
    static let title = Font.custom("Oswald-Regular", size: 28)
    static let section = Font.custom("Oswald-Regular", size: 22)
    static let cardTitle = Font.custom("Oswald-Regular", size: 18)
    static let buttonLabel = Font.custom("Oswald-Regular", size: 18)
    static let buttonLabelCompact = Font.custom("Oswald-Regular", size: 16) // Compact/small buttons

    // Inter — body text, UI labels, captions
    static let body = Font.custom("Inter-Regular", size: 16)
    static let uiLabel = Font.custom("Inter-Regular", size: 14)
    static let caption = Font.custom("Inter-Regular", size: 12)
    static let badge = Font.custom("Inter-Regular", size: 11).bold()

    // Special-purpose font tokens (SF Symbols, branded text, debug)
    static let iconHero = Font.system(size: 64)                       // Large decorative SF Symbols
    static let iconCinematic = Font.system(size: 44)                  // Ceremony SF Symbols
    static let iconLarge = Font.system(size: 24, design: .rounded)    // Featured SF Symbol icons
    static let iconMedium = Font.system(size: 20)                     // Medium emoji/SF Symbols
    static let iconSmall = Font.system(size: 14)                      // Small emoji/SF Symbols
    static let iconMini = Font.system(size: 12)                       // Mini emoji indicators
    static let iconFlame = Font.system(size: 11, design: .rounded)    // Smallest allowed icon (min 11pt)
    static let googleLogo = Font.system(size: 22, weight: .bold, design: .rounded)  // Google "G" branding
    static let debugMono = Font.system(size: 12, weight: .medium, design: .monospaced) // Dev tools only
    static let debugMonoSmall = Font.system(size: 10, design: .monospaced)            // Catalog IDs

    // MARK: - Opacity Scale

    static let opacityMicro: Double = 0.04
    static let opacitySoft: Double = 0.08
    static let opacityLight: Double = 0.12
    static let opacityMild: Double = 0.15
    static let opacityMedium: Double = 0.25
    static let opacityStrong: Double = 0.40
    static let opacityHeavy: Double = 0.60
    static let opacityDense: Double = 0.75
    static let opacityOpaque: Double = 0.85

    // ╔══════════════════════════════════════════════════════════╗
    // ║  GRADIENTS                                               ║
    // ╚══════════════════════════════════════════════════════════╝

    // MARK: - Gradients

    static let goldGradient = LinearGradient(
        colors: [gold, borderOrnament],
        startPoint: .top, endPoint: .bottom
    )

    static let xpGradient = LinearGradient(
        colors: [purple, Color(hex: 0x8E44AD)],
        startPoint: .leading, endPoint: .trailing
    )

    static let staminaGradient = LinearGradient(
        colors: [stamina, btnOrangeBase],
        startPoint: .leading, endPoint: .trailing
    )

    static let progressGradient = LinearGradient(
        colors: [gold, borderOrnament],
        startPoint: .leading, endPoint: .trailing
    )

    static let bgGradient = LinearGradient(
        colors: [bgPrimary, Color(hex: 0x0D0D18)],
        startPoint: .top, endPoint: .bottom
    )

    // ╔══════════════════════════════════════════════════════════╗
    // ║  HELPERS                                                 ║
    // ╚══════════════════════════════════════════════════════════╝

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

    static func statColor(for stat: String) -> Color { statBarFill }

    // ╔══════════════════════════════════════════════════════════╗
    // ║  LEGACY ALIASES — backward compat, will be removed      ║
    // ╚══════════════════════════════════════════════════════════╝

    // MARK: - Legacy Aliases

    static let bgDark = bgPrimary
    static let bgCard = bgSecondary
    static let goldLight = goldBright
    static let textMuted = textTertiary
    static let borderDefault = borderSubtle
    static let hpRed = danger
    static let hpBlood = Color(hex: 0xC41E3A)
    static let glowOrange = Color(hex: 0xF39C12)

    // Deprecated HP gradients — use canonicalHpGradient(percentage:) instead
    static let hpMidGradient = LinearGradient(
        colors: [Color(hex: 0xA01830), Color(hex: 0x801525)],
        startPoint: .leading, endPoint: .trailing
    )
    static let hpLowGradient = LinearGradient(
        colors: [Color(hex: 0x80101E), Color(hex: 0x600C18)],
        startPoint: .leading, endPoint: .trailing
    )
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

// MARK: - Color convenience accessors

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
