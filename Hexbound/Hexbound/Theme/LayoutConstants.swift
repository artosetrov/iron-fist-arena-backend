import Foundation

enum LayoutConstants {
    // MARK: - Screen Layout (from UI_DESIGN_DOCUMENT Section 4.3)

    static let screenPadding: CGFloat = 16       // Horizontal content inset
    static let screenTopGap: CGFloat = 16        // Gap below header before content
    static let safeAreaTop: CGFloat = 59         // iOS Dynamic Island
    static let safeAreaBottom: CGFloat = 34      // iOS Home indicator

    // MARK: - Spacing Scale

    static let space2XS: CGFloat = 2   // Micro gaps, inline icon offsets
    static let spaceXS: CGFloat = 4    // Badge padding, tight groups
    static let spaceSM: CGFloat = 8    // Card internal gaps, filter tag gaps
    static let spaceMS: CGFloat = 12   // Compact element padding, zone indicators
    static let spaceMD: CGFloat = 16   // Standard padding, section gaps
    static let spaceLG: CGFloat = 24   // Section separation
    static let spaceXL: CGFloat = 32   // Screen section breaks
    static let space2XL: CGFloat = 48  // Hero areas, dramatic spacing

    // MARK: - Component Sizing

    // Buttons
    static let buttonHeightLG: CGFloat = 56      // Primary CTA
    static let buttonHeightMD: CGFloat = 48      // Secondary buttons
    static let buttonHeightSM: CGFloat = 36      // Tertiary, filter tags
    static let buttonPaddingH: CGFloat = 24      // Horizontal padding inside buttons
    static let buttonRadius: CGFloat = 8

    // Cards
    static let cardPadding: CGFloat = 16
    static let cardRadius: CGFloat = 12
    static let panelRadius: CGFloat = 8
    static let modalRadius: CGFloat = 16

    // Inputs
    static let inputHeight: CGFloat = 52
    static let inputRadius: CGFloat = 8

    // Avatars
    static let avatarSizeLG: CGFloat = 72        // Hub, profile
    static let avatarSizeMD: CGFloat = 56        // Combat, leaderboard
    static let avatarSizeSM: CGFloat = 40        // Lists, chat

    // Navigation
    static let bottomNavHeight: CGFloat = 64
    static let navButtonHeight: CGFloat = 72

    // MARK: - Touch Targets

    static let touchMin: CGFloat = 48
    static let touchComfortable: CGFloat = 56

    // MARK: - Grid

    static let inventoryCols = 4
    static let inventoryGap: CGFloat = 8
    static let shopCols = 4
    static let shopGap: CGFloat = 10
    static let equipmentCols = 3
    static let equipmentGap: CGFloat = 12
    static let classGridCols = 2
    static let classGridGap: CGFloat = 12
    static let navGridCols = 2
    static let navGridGap: CGFloat = 12

    // MARK: - Typography Sizes (AAA Standard)

    static let textHero: CGFloat = 64          // Level up number, celebration
    static let textCelebration: CGFloat = 44   // Level up subtitle, victory
    static let textCinematic: CGFloat = 40
    static let textScreen: CGFloat = 28
    static let textSection: CGFloat = 22
    static let textCard: CGFloat = 18
    static let textButton: CGFloat = 18
    static let textBody: CGFloat = 16
    static let textLabel: CGFloat = 14
    static let textCaption: CGFloat = 12
    static let textBadge: CGFloat = 11

    // MARK: - Compact Card Sizing

    static let bannerPadding: CGFloat = 14     // Hub banner cards (compact exception)

    // MARK: - Character Card Sizing

    static let avatarRingSize: CGFloat = 74    // XP ring diameter on Hub
    static let avatarInnerSize: CGFloat = 64   // Avatar image inside ring
    static let avatarRingOverflow: CGFloat = 80 // Container height for badge overflow
}
