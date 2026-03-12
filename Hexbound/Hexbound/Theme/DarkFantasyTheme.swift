import SwiftUI

enum DarkFantasyTheme {

    // MARK: - Background & Surface Colors (from UI_DESIGN_DOCUMENT Section 4.1)

    static let bgAbyss = Color(hex: 0x08080C)       // Deepest black — behind modals
    static let bgPrimary = Color(hex: 0x0D0D12)     // Main screen background
    static let bgSecondary = Color(hex: 0x1A1A2E)   // Panel backgrounds, cards
    static let bgTertiary = Color(hex: 0x16213E)    // Card interiors, form fields
    static let bgElevated = Color(hex: 0x1E2240)    // Active cards, selected items
    static let bgModal = Color.black.opacity(0.75)   // Modal overlay

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

    // Legacy aliases
    static let hpRed = danger
    static let hpGreen = Color(hex: 0xC41E3A)         // Blood-red — unified HP color
    static let hpBlood = Color(hex: 0xC41E3A)          // Blood-red HP bar (canonical)
    static let stamina = Color(hex: 0xE67E22)          // Orange stamina
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

    // HP bar gradients — unified blood-red style
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
        case ..<1100: rankBronze
        case 1100..<1300: rankSilver
        case 1300..<1500: rankGold
        case 1500..<1700: rankPlatinum
        case 1700..<2000: rankDiamond
        default: rankGrandmaster
        }
    }

    static func hpGradient(percentage: Double) -> LinearGradient {
        if percentage > 0.6 { return hpHighGradient }
        if percentage > 0.3 { return hpMidGradient }
        return hpLowGradient
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
