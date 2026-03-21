import Foundation

enum LayoutConstants {
    // MARK: - Screen Layout (see docs/07_ui_ux/DESIGN_SYSTEM.md)

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

    /// Gap between major content blocks on a screen (widget → stance → tabs, etc.)
    /// Use this instead of spaceLG for the main ScrollView VStack spacing.
    static let sectionGap: CGFloat = 16

    // MARK: - Component Sizing

    // Buttons
    static let buttonHeightLG: CGFloat = 56      // Primary CTA
    static let buttonHeightMD: CGFloat = 48      // Secondary buttons
    static let buttonHeightSM: CGFloat = 36      // Tertiary, filter tags
    static let buttonPaddingH: CGFloat = 24      // Horizontal padding inside buttons
    static let buttonRadius: CGFloat = 8
    static let buttonRadiusLG: CGFloat = 14     // Fight / boss card buttons

    // Cards
    static let cardPadding: CGFloat = 16
    static let cardRadius: CGFloat = 12
    static let panelRadius: CGFloat = 8
    static let modalRadius: CGFloat = 16
    static let bossCardRadius: CGFloat = 20     // Dungeon boss card

    // Inputs
    static let inputHeight: CGFloat = 52
    static let inputRadius: CGFloat = 8

    // Avatars
    static let avatarSizeLG: CGFloat = 72        // Hub, profile
    static let avatarSizeMD: CGFloat = 56        // Combat, leaderboard
    static let avatarSizeSM: CGFloat = 40        // Lists, chat

    // Tab Switcher
    static let tabSwitcherPaddingV: CGFloat = 8  // Vertical gap above & below TabSwitcher (== spaceSM)

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
    static let textLabel: CGFloat = 16          // was 14 — minimum 16px rule
    static let textCaption: CGFloat = 16        // was 12 — minimum 16px rule
    static let textBadge: CGFloat = 16          // was 11 — minimum 16px rule

    // MARK: - Compact Card Sizing

    static let bannerPadding: CGFloat = 14     // Hub banner cards (compact exception)

    // MARK: - Character Card Sizing

    static let avatarRingSize: CGFloat = 74    // XP ring diameter on Hub
    static let avatarInnerSize: CGFloat = 64   // Avatar image inside ring
    static let avatarRingOverflow: CGFloat = 80 // Container height for badge overflow

    // MARK: - Unified Hero Widget

    static let widgetPadding: CGFloat = 12         // Vertical padding (4px grid: 3×4)
    static let widgetPaddingH: CGFloat = 16        // Horizontal padding (4px grid: 4×4)
    static let widgetRadius: CGFloat = 12          // Card radius (radius-lg, 4px grid)
    static let widgetMinHeight: CGFloat = 80       // Min height (10×8 grid)
    static let widgetGap: CGFloat = 12             // Gap between avatar, center, right columns
    static let widgetRowGap: CGFloat = 4           // Gap between row-1, row-2, row-3

    // Pill System (Unified Action Elements)
    static let pillHeight: CGFloat = 32            // Dense control min (Rulebook §2.5)
    static let pillRadius: CGFloat = 8             // radius-md (4px grid)
    static let pillPaddingH: CGFloat = 12          // Horizontal padding (4px grid: 3×4)
    static let pillIconSize: CGFloat = 12          // icon-xs
    static let pillGap: CGFloat = 4                // Internal element gap
    static let pillFont: CGFloat = 12              // Minimum readable font (12px absolute min)
    static let pillSpacing: CGFloat = 8            // Gap between pills in row-3

    // Widget Avatar
    static let widgetAvatarFullSize: CGFloat = 72  // Full-height avatar (1:1 square, matches content height)
    static let widgetAvatarSize: CGFloat = 48      // Legacy small avatar
    static let widgetAvatarRadius: CGFloat = 8     // Rounded square corners
    static let widgetXpRingInset: CGFloat = 4      // SVG offset from avatar edge
    static let widgetXpRingWidth: CGFloat = 3      // Stroke width for XP border
    static let widgetLevelBadgeFont: CGFloat = 11  // Matches textBadge
    static let widgetBarHeight: CGFloat = 22         // HP/Stamina bars with text inside
    static let widgetBarRadius: CGFloat = 6          // Bar corner radius
    static let widgetBarFont: CGFloat = 11           // Text inside bars (matches textBadge)

    // MARK: - NPC Guide Widget (reusable: merchant, arena coach, dungeon guide, etc.)
    // Use these tokens for any NPC tip/tutorial widget across screens.

    static let npcAvatarSize: CGFloat = 256           // Full NPC portrait (no frame, no clip)
    static let npcAvatarOffset: CGFloat = -30         // Shift avatar up so it peeks above the bar
    static let npcBarHeight: CGFloat = 90             // Fixed speech bar height (title + 2-line body + padding)
    static let npcBarRadius: CGFloat = 12             // Rounded corners for widget card (matches widgetRadius)
    static let npcBarPaddingH: CGFloat = 16           // Horizontal inner padding (matches screenPadding)
    static let npcBarPaddingV: CGFloat = 12           // Vertical inner padding (matches widgetPadding)
    static let npcMiniSize: CGFloat = 56              // Collapsed floating avatar (matches avatarSizeMD)
    static let npcOuterPadding: CGFloat = 16          // Equal padding: left, right, bottom (matches screenPadding)

    // Legacy aliases (kept for backward compat — prefer npc* tokens)
    static let merchantAvatarSize: CGFloat = npcAvatarSize
    static let merchantMiniSize: CGFloat = npcMiniSize
    static let merchantBarHeight: CGFloat = npcBarHeight
    static let merchantBubbleRadius: CGFloat = npcBarRadius

    // MARK: - Package Cards (Currency Purchase)

    static let packageCardMinHeight: CGFloat = 96      // Improved from ~72pt for visual weight
    static let packagePriceBtnWidth: CGFloat = 80      // Price button width
    static let packagePriceBtnHeight: CGFloat = 48     // Price button height (== touchMin)
    static let packageAmountFont: CGFloat = 22         // Amount text size
    static let packageBestValueAmountFont: CGFloat = 26 // Best Value amount text size

    // MARK: - Arena Opponent Card (Premium Redesign)

    static let arenaCardRadius: CGFloat = 16
    static let arenaCardPadding: CGFloat = 16
    static let arenaCardPaddingTop: CGFloat = 20
    static let arenaAvatarSize: CGFloat = 120       // Enlarged portrait
    static let arenaAvatarRadius: CGFloat = 14
    static let arenaCardGap: CGFloat = 16           // Horizontal gap between cards
    static let arenaBadgePadding: CGFloat = 10
    static let arenaRatingFont: CGFloat = 26        // Dominant power value
    static let arenaNameFont: CGFloat = 16          // Strong player name
    static let arenaClassFont: CGFloat = 13         // Secondary class/level
    static let arenaStatFont: CGFloat = 14          // Stat values
    static let arenaStatLabelFont: CGFloat = 12     // Stat labels
    static let arenaDifficultyFont: CGFloat = 11    // Difficulty badge
    static let arenaGlowRadius: CGFloat = 12        // Animated border glow
    static let arenaShimmerWidth: CGFloat = 80       // Shimmer band width

    // MARK: - Hero Integrated Card

    static let heroCardRadius: CGFloat = 12
    static let heroCardPadding: CGFloat = 12
    static let heroSlotSize: CGFloat = 84          // same as inventory cell
    static let heroSlotGap: CGFloat = 8            // same as inventoryGap
    static let heroPortraitSideGap: CGFloat = 16  // breathing room between portrait and side slots
    static let heroSlotRadius: CGFloat = 12        // same as cardRadius
    static let heroBarHeight: CGFloat = 24         // HP bar with text inside
    static let heroBarXpHeight: CGFloat = 20       // XP bar with text inside
    static let heroBarRadius: CGFloat = 4
    static let heroBarFont: CGFloat = 11           // text inside bars
    static let heroPortraitNameFont: CGFloat = 16  // name overlay on portrait
    static let heroBottomSlots: Int = 4            // Ring, Weapon, Relic, Belt
}
