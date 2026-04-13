import Foundation

enum LayoutConstants {

    // ╔══════════════════════════════════════════════════════════╗
    // ║  BASE SCALES — the only "real" values in the system     ║
    // ║  Everything below either IS a scale token or aliases    ║
    // ║  one. Never add a raw number — snap to scale.           ║
    // ╚══════════════════════════════════════════════════════════╝

    // MARK: - Spacing Scale (4px grid)

    static let space2XS: CGFloat = 2   // Micro gaps, inline icon offsets
    static let spaceXS: CGFloat = 4    // Badge padding, tight groups
    static let spaceSM: CGFloat = 8    // Card internal gaps, filter tag gaps
    static let spaceMS: CGFloat = 12   // Compact element padding, zone indicators
    static let spaceMD: CGFloat = 16   // Standard padding, section gaps
    static let spaceLG: CGFloat = 24   // Section separation
    static let spaceXL: CGFloat = 32   // Screen section breaks
    static let space2XL: CGFloat = 48  // Hero areas, dramatic spacing

    // MARK: - Radius Scale (4px grid)

    static let radiusXS: CGFloat = 3       // Micro: progress bars, tiny indicators
    static let radiusSM: CGFloat = 6       // Small: badges, stat bars, tag chips
    static let radiusMD: CGFloat = 8       // Medium: buttons, panels, pills, inputs
    static let radiusLG: CGFloat = 12      // Large: cards, widgets
    static let radiusXL: CGFloat = 16      // Extra-large: modals, featured cards
    static let radius2XL: CGFloat = 22     // Capsule-like: auth inputs, large CTAs

    // MARK: - Icon Size Scale

    static let iconXS: CGFloat = 12       // Micro icons (status dots, inline indicators)
    static let iconSM: CGFloat = 16       // Small icons (pill icons, badge icons)
    static let iconMD: CGFloat = 20       // Medium icons (list row icons, nav icons)
    static let iconLG: CGFloat = 24       // Large icons (action icons, toolbar)
    static let iconXL: CGFloat = 32       // Extra-large (empty state, fallback)
    static let icon2XL: CGFloat = 48      // Hero icons (empty state, celebration)
    static let icon3XL: CGFloat = 56      // Reward row icons (Victory rewards)

    // MARK: - Typography Sizes

    static let textHero: CGFloat = 64          // Level up number, celebration
    static let textCelebration: CGFloat = 44   // Level up subtitle, victory
    static let textCinematic: CGFloat = 40     // Full-screen ceremonies
    static let textScreen: CGFloat = 28        // Screen titles (Oswald)
    static let textSection: CGFloat = 22       // Sub-section headers (Oswald)
    static let textCard: CGFloat = 18          // Card headers (Oswald)
    static let textButton: CGFloat = 18        // Button text (Oswald)
    static let textBody: CGFloat = 16          // Body text (Inter)
    static let textLabel: CGFloat = 16         // Labels — minimum 16px rule
    static let textCaption: CGFloat = 16       // Captions — minimum 16px rule
    static let textBadge: CGFloat = 16         // Badges — minimum 16px rule

    // MARK: - Touch Targets (Apple HIG)

    static let touchMin: CGFloat = 48          // Minimum tappable area
    static let touchComfortable: CGFloat = 56  // Comfortable tappable area

    // ╔══════════════════════════════════════════════════════════╗
    // ║  SEMANTIC ALIASES — named references to base scales     ║
    // ║  Use these for readability; they all resolve to a       ║
    // ║  scale token above. Comment shows which one.            ║
    // ╚══════════════════════════════════════════════════════════╝

    // MARK: - Screen Layout

    static let screenPadding: CGFloat = spaceMD        // 16 — horizontal content inset
    static let screenTopGap: CGFloat = spaceMD         // 16 — gap below header
    static let safeAreaTop: CGFloat = 59               // iOS Dynamic Island (device-specific)
    static let safeAreaBottom: CGFloat = 34             // iOS Home indicator (device-specific)
    static let sectionGap: CGFloat = spaceMD           // 16 — main VStack spacing

    // MARK: - Buttons (semantic → scale)

    static let buttonHeightLG: CGFloat = touchComfortable  // 56 — Primary CTA
    static let buttonHeightMD: CGFloat = touchComfortable   // 56 — Unified: all full-width buttons same height as Primary
    static let buttonHeightSM: CGFloat = 36                // Tertiary, filter tags
    static let buttonPaddingH: CGFloat = spaceLG           // 24 — horizontal padding inside buttons
    static let buttonRadius: CGFloat = radiusMD            // 8
    static let buttonRadiusLG: CGFloat = 14                // Fight / boss card buttons (between radiusLG and radiusXL)

    // MARK: - Cards (semantic → scale)

    static let cardPadding: CGFloat = spaceMD              // 16
    static let cardRadius: CGFloat = radiusLG              // 12
    static let panelRadius: CGFloat = radiusMD             // 8
    static let modalRadius: CGFloat = radiusXL             // 16

    // MARK: - Inputs

    static let inputHeight: CGFloat = 52                   // Between touchMin and touchComfortable
    static let inputRadius: CGFloat = radiusMD             // 8

    // MARK: - Navigation

    static let bottomNavHeight: CGFloat = 64
    static let navButtonHeight: CGFloat = 72
    static let tabSwitcherPaddingV: CGFloat = spaceSM      // 8

    // MARK: - Grid Layouts

    static let inventoryCols = 4
    static let inventoryGap: CGFloat = spaceSM             // 8
    static let shopCols = 4
    static let shopGap: CGFloat = 10                       // Off-grid: visual density compromise
    static let equipmentCols = 3
    static let equipmentGap: CGFloat = spaceMS             // 12
    static let classGridCols = 2
    static let classGridGap: CGFloat = spaceMS             // 12
    static let navGridCols = 2
    static let navGridGap: CGFloat = spaceMS               // 12

    // MARK: - Avatar Rings (Hub character card)

    static let avatarInnerSize: CGFloat = 64               // Avatar image inside XP ring

    // MARK: - Banner

    static let bannerPadding: CGFloat = 14                 // Off-grid: compact exception

    // ╔══════════════════════════════════════════════════════════╗
    // ║  COMPONENT TOKENS — used in ≥2 files, justified by     ║
    // ║  needing a value that doesn't exist in base scale.      ║
    // ╚══════════════════════════════════════════════════════════╝

    // MARK: - Hero Integrated Card

    static let heroCardRadius: CGFloat = radiusLG          // 12
    static let heroCardPadding: CGFloat = spaceMS          // 12
    static let heroSlotGap: CGFloat = spaceMS              // 12
    static let heroSlotRadius: CGFloat = radiusLG          // 12 — same as cardRadius
    static let heroBarHeight: CGFloat = 28                 // HP bar with text inside (unique)
    static let heroBarXpHeight: CGFloat = 24               // XP bar with text inside (unique)
    static let heroBarRadius: CGFloat = radiusXS + 1       // 4 — micro bar radius
    static let heroBarFont: CGFloat = 13                   // Text inside bars (unique, readability)
    static let heroPortraitNameFont: CGFloat = spaceMD     // 16 — name overlay on portrait

    // MARK: - Card Portrait System (unified aspect ratio — all portrait cards)

    /// Aspect ratio for all portrait cards (Arena, Boss, Hero selection).
    /// height = width × cardAspectRatio
    /// Changed from 1.4 → 1.55 per Card Audit v4 (2026-04-10)
    static let cardAspectRatio: CGFloat = 1.55

    /// LVL badge size for portrait cards (Arena, Hero) — 38pt circle
    static let cardLvlBadgeSize: CGFloat = 38

    // MARK: - Arena Opponent Card

    static let arenaCardRadius: CGFloat = radiusXL         // 16
    static let arenaCardPadding: CGFloat = 14              // Off-grid: visual density
    static let arenaCardGap: CGFloat = spaceMD             // 16
    static let arenaNameFont: CGFloat = spaceMD            // 16 — strong player name
    static let arenaDifficultyFont: CGFloat = 11           // Difficulty badge (unique, small)
    static let arenaGlowRadius: CGFloat = radiusLG         // 12 — animated border glow

    // MARK: - Pill System (WidgetPill)

    static let pillHeight: CGFloat = touchMin - 4          // 44 — Apple HIG touch target
    static let pillRadius: CGFloat = radiusLG              // 12
    static let pillPaddingH: CGFloat = spaceMD             // 16
    static let pillIconSize: CGFloat = iconSM              // 16
    static let pillGap: CGFloat = spaceSM                  // 8
    static let pillFont: CGFloat = 14                      // Comfortable reading (unique)
    static let pillCountFont: CGFloat = 12                 // Count badge font (unique)
    static let pillSpacing: CGFloat = spaceSM              // 8 — gap between pills

    // MARK: - Unified Hero Widget

    static let widgetPadding: CGFloat = spaceMS            // 12 — vertical padding
    static let widgetPaddingH: CGFloat = spaceMD           // 16 — horizontal padding
    static let widgetRadius: CGFloat = radiusLG            // 12 — card radius
    static let widgetMinHeight: CGFloat = 80               // Unique: min height (10×8 grid)
    static let widgetGap: CGFloat = spaceMS                // 12 — gap between columns
    static let widgetRowGap: CGFloat = spaceXS             // 4 — gap between rows
    static let widgetAvatarFullSize: CGFloat = 72          // Full-height avatar (unique)
    static let widgetXpRingInset: CGFloat = spaceXS        // 4 — SVG offset from avatar edge
    static let widgetLevelBadgeFont: CGFloat = 11          // Matches textBadge design token
    static let widgetBarHeight: CGFloat = 26               // HP/Stamina bars with text (unique)
    static let widgetBarRadius: CGFloat = radiusSM         // 6
    static let widgetBarFont: CGFloat = 13                 // Text inside bars (same as heroBarFont)
    static let widgetAvatarRadius: CGFloat = radiusMD      // 8 — rounded square corners
    static let widgetXpRingWidth: CGFloat = 3              // Stroke width for XP border (unique)

    // MARK: - NPC Guide Widget

    static let npcAvatarSize: CGFloat = 256                // Full NPC portrait (Figma: NPC Avatar size-[256px])
    static let npcAvatarOffset: CGFloat = -140             // Shift avatar up (Figma: VStack mb-[-40px] → ZStack equivalent)
    static let npcBarHeight: CGFloat = 90                  // Fixed speech bar height (unique)
    static let npcBarRadius: CGFloat = radiusLG            // 12
    static let npcBarPaddingH: CGFloat = spaceMD           // 16
    static let npcBarPaddingV: CGFloat = spaceMS           // 12
    static let npcOuterPadding: CGFloat = spaceMD          // 16

    // (Legacy merchant aliases removed — migrated to npc*/touchComfortable tokens)

    // MARK: - Package Cards (Currency Purchase)

    static let packageCardMinHeight: CGFloat = 96          // Unique: visual weight
    static let packageAmountFont: CGFloat = textSection     // 22
    static let packageBestValueAmountFont: CGFloat = 26    // Unique: best value emphasis

    // MARK: - Gold Mine (Mine Slot Cards, Shaft Picker, Mini-Game)

    static let mineThumbnailSize: CGFloat = 52              // Mine slot thumbnail in card header
    static let mineShaftThumbSM: CGFloat = 56               // Active shaft banner thumb
    static let mineShaftThumbMD: CGFloat = 64               // Shaft picker row thumb
    static let mineShaftThumbLG: CGFloat = 140              // Shaft cleared celebration thumb
    static let mineProgressHeight: CGFloat = 10             // Mining / shaft progress bar height (matches XPBarView.compact) — used for both collapsed and expanded mine cards
    static let mineCapBarHeight: CGFloat = 8                // Mini-game cap meter bar height
    static let mineDropCoinSize: CGFloat = 42                // Falling single coin (value 1-2)
    static let mineDropBagSmSize: CGFloat = 48              // Falling small bag (value 3)
    static let mineDropBagMdSize: CGFloat = 54              // Falling medium bag (value 5)
    static let mineDropBagLgSize: CGFloat = 62              // Falling large bag (value 10)
    static let mineDropGemSize: CGFloat = 58                // Falling gem drop
    static let mineResultIconSize: CGFloat = iconMD         // 20 — result row icon
    static let mineLoaderHeight: CGFloat = 34               // Spinner height in action slot

    // MARK: - Layout Insets (safe area + navigation offsets)

    static let barInternalPadding: CGFloat = 1             // Pixel-precise internal padding for progress bars
    static let editorBottomInset: CGFloat = 140            // Clearance above bottom toolbar in editor views
    static let combatVsTopInset: CGFloat = 90              // VS label positioning in combat view
    static let authBottomInset: CGFloat = 60               // Bottom padding in auth screens
    static let bannerTopInset: CGFloat = 94                // Status bar (50) + nav bar (44) for overlays
    static let cinematicPaddingH: CGFloat = 40             // Horizontal padding for cinematic ceremonies
}
