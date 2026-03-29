# Unified Preloader Concept — Hexbound

## Problem

The app has 4+ different loading patterns with inconsistent styling: fullscreen LoadingOverlay, 12 skeleton variants, 40+ ProgressView spinners with varying colors/sizes, and hardcoded text labels.

## Proposed Solution: `HexLoadingView` — 3 Tiers

### Tier 1: `.fullscreen` (blocking operations)
**When:** Auth flows, initial game data load, major transitions.
**What:** Current `LoadingOverlay` — pulsing hexagon logo, radial glow, gold diamond-dot animation, dark backdrop (0.85 opacity). **No changes needed**, it's already consistent.

### Tier 2: `.combat` (battle preparation)
**When:** Dungeon boss fights, arena preparation, any combat initiation.
**What:** Semi-transparent overlay (0.75 opacity) with ornamental modal panel containing: bolt.shield icon, "PREPARING FOR BATTLE..." text, 3 animated diamond dots. Follows standard modal ornamental pattern (RadialGlow + surfaceLighting + innerBorder + cornerBrackets + cornerDiamonds). **Implemented in BossDetailSheet** — extract to shared component.

### Tier 3: `.inline` (button/card actions)
**When:** Claim rewards, buy items, equip, repair — any button action.
**What:** Standardized ProgressView with consistent parameters:
- Color: `DarkFantasyTheme.gold` (always, not textOnGold or textTertiary)
- Scale: `.small` = 0.6x, `.medium` = 0.8x, `.large` = 1.0x
- No text label (action context already clear from button)

### Tier 4: `.skeleton` (list/grid loading)
**When:** Initial content load for lists, grids, tabs.
**What:** Existing `SkeletonViews.swift` — already consistent with gold shimmer, 1.2s cycle. **No changes needed.**

## Implementation Plan

### Phase 1: Extract `CombatLoadingOverlay` from BossDetailSheet
Create reusable component at `Views/Components/CombatLoadingOverlay.swift`:
- Parameters: `message: String`, `icon: String`, `accentColor: Color`
- Defaults: "PREPARING FOR BATTLE...", "bolt.shield.fill", gold
- Reuse in: BossDetailSheet, DungeonRoomDetailView, any future combat initiation

### Phase 2: Create `.hexSpinner()` View modifier
Standardize all inline ProgressView usage:
```swift
extension View {
    func hexSpinner(size: HexSpinnerSize = .medium) -> some View
}
enum HexSpinnerSize { case small, medium, large }
```
Replace 40+ inconsistent ProgressView calls with `.hexSpinner()`.

### Phase 3: Standardize loading text
Create `LoadingMessage` enum with localized strings:
- `.loading` → "Loading..."
- `.loadingHeroes` → "Loading heroes..."
- `.preparingBattle` → "Preparing for battle..."
- `.checkingAvailability` → "Checking availability..."

## Visual Style

All loading indicators share the gold-on-dark theme:
- Primary color: `DarkFantasyTheme.gold`
- Background: `DarkFantasyTheme.bgAbyss` or `bgSecondary`
- Animated elements: diamond shapes (◆), not circles
- Font: Oswald for labels, Inter for descriptions
- All follow ornamental design system patterns
