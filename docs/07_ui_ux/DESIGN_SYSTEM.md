# Design System Reference (Source of Truth)
*Derived from DarkFantasyTheme.swift, ButtonStyles.swift, LayoutConstants.swift*

## Colors

### Backgrounds
- `bgAbyss` — deepest background, UI surfaces
- `bgPrimary` (#0D0D12) — main canvas background
- `bgSecondary` (#1A1A2E) — elevated panels, cards
- `bgTertiary` — tertiary surface
- `bgElevated` — floating elements, modals
- `bgDark` — darkest surface for depth

### Gold Accent
- `gold` (#D4A537) — primary accent, borders, icons
- `goldBright` (#FFD700) — highlighted gold, interactive states
- `goldDim` — desaturated gold, disabled/tertiary
- `goldGlow` — glowing variant for emphasis

### Feedback
- `danger` (#E63946) — errors, destructive actions, loss states
- `success` (#2ECC71) — rewards, wins, progression
- `info` — informational states
- `cyan` (#00D4FF) — special effects, tech elements
- `purple` — alternative accent

### Text
- `textPrimary` — body text, high contrast
- `textSecondary` — supporting text, reduced contrast
- `textTertiary` — disabled, tertiary information
- `textDisabled` — disabled states
- `textGold` — gold-colored text (navigation, emphasis)
- `textOnGold` — text on gold backgrounds

### Rarity Colors
- `Common`, `Uncommon`, `Rare`, `Epic`, `Legendary` — item rarity indicators
- Each has a `Glow` variant for highlighting

### Stat Colors
- `STR`, `AGI`, `VIT`, `END`, `INT`, `WIS`, `LUK`, `CHA` — color-coded stats
- Consistent across inventory, character sheet, tooltips

### Class Colors
- `Warrior` (orange) — strength-based
- `Rogue` (green) — agility-based
- `Mage` (blue) — intelligence-based
- `Tank` (gray) — vitality-based

### Rank Colors
- `Bronze` through `Grandmaster` — PvP rating tiers
- Progression: Bronze → Silver → Gold → Platinum → Diamond → Grandmaster

## Typography

### Font Families
- **Oswald** — titles, section headers, buttons, UI chrome (all-caps, bold)
- **Inter** — body text, labels, captions, descriptive content

### Font Size Functions
- `title(size:)` — cinematic titles (40pt → 18pt)
- `section(size:)` — section headers
- `body(size:)` — body text (16pt → 11pt)
- Dynamic scaling from 40pt (hero) down to 11pt (badge)

### Size Scale Reference
- Hero: 64pt
- Cinematic: 40pt
- Screen: 28pt
- Section: 22pt
- Body: 16pt
- Caption: 14pt
- Label: 12pt
- Badge: 11pt (minimum)

## Button Styles (18 total)

### Core Buttons

| Style | API | Height | Appearance | Use |
|-------|-----|--------|------------|-----|
| Primary | `.primary` | 56pt | Gold gradient + ornamental border | Main CTAs (Start Battle, Claim Reward, Confirm) |
| Secondary | `.secondary` | 48pt | Outlined gold, transparent bg | Important non-primary (Shop, Equipment, Passives) |
| Danger | `.danger` | 48pt | Crimson background | Destructive actions (Dismantle, Abandon, Reset) |
| Ghost | `.ghost` | content | Text-only, no background | Tertiary (Cancel, Close, Help) |
| Neutral | `.neutral` | 48pt | Muted background, full width | Settings actions (Link Account, etc.) |

### Combat Buttons

| Style | API | Purpose |
|-------|-----|---------|
| Fight | `.fight` / `.fight(accent:)` | Combat CTA — orange→gold gradient, shine effect, shadow |
| Combat Toggle | `.combatToggle(isActive:)` | Speed toggles (1X / 2X) with active state |
| Combat Control | `.combatControl` | Neutral combat actions (SKIP) |
| Combat Forfeit | `.combatForfeit` | Icon button with danger accent |

### Navigation & Auth

| Style | API | Purpose |
|-------|-----|---------|
| Nav Grid | `.navGrid` | Hub navigation tiles with metallic highlight |
| Social Auth | `.socialAuth` | Apple/Google sign-in (56pt, black background) |
| Close | `.closeButton` | 32×32 circular X button for modal dismiss |

### Compact Variants

| Style | API | Purpose |
|-------|-----|---------|
| Compact Primary | `.compactPrimary` | Inline gold CTA, content-sized |
| Danger Compact | `.dangerCompact` | Inline danger action, compact red |
| Compact Outline | `.compactOutline(color:fillOpacity:)` | Generic colored outline, parameterized |
| Danger Outline | `.dangerOutline` | Full-width danger outline (48pt, Logout style) |

### Utility

| Style | API | Purpose |
|-------|-----|---------|
| Color Toggle | `.colorToggle(isActive:color:height:)` | Generic toggle with active state, customizable color/height |
| Scale Press | `.scalePress` / `.scalePress(_:)` | Pure press feedback modifier (default 0.9 scale) |

### Button Animations
- All buttons support `.scalePress(0.97)` — slightly shrink on press
- Pressed state feedback is critical for game feel
- Fight button has additional shine animation on tap

## Layout Constants

### Spacing Scale
- `2XS` — 2pt (micro-spacing)
- `XS` — 4pt (tight spacing)
- `SM` — 8pt (small spacing)
- `MD` — 16pt (default spacing)
- `LG` — 24pt (large spacing)
- `XL` — 32pt (extra large)
- `2XL` — 48pt (huge spacing)

### Screen Layout
- Screen padding: 16pt (MD)
- Safe area respect required
- Landscape mode: adjust column count

### Component Sizes
- Button height: 36pt (compact) → 56pt (primary)
- Touch target minimum: 48pt
- Touch target comfortable: 56pt+

### Grid Layouts
- Inventory grid: 4 columns (inventory management)
- Shop grid: 4 columns (item browsing)
- Equipment grid: 3 columns (equipment selection)
- Dungeon rewards: varies by count

### Typography Scale
- Hero title: 64pt
- Cinematic title: 40pt
- Screen title: 28pt
- Section header: 22pt
- Body: 16pt
- Label: 12pt
- Badge: 11pt (minimum — never smaller)

## Gradients

### Progress Bars
- **HP Bar**: green (full) → amber (warning) → red (critical)
- **XP Bar**: cyan → gold → bright gold
- **Stamina Bar**: blue → cyan gradient
- **Experience**: gradient progression

### Card Gradients
- Card backgrounds: subtle dark-to-dark gradient
- Elevated cards: brighter secondary background
- Dungeon cards: thematic gradient (matches dungeon difficulty)

### Button Gradients
- Primary button: gold gradient with depth
- Fight button: orange → gold gradient
- Stat buttons: stat-color gradient

## CRITICAL VERIFICATION RULES

### Never Hardcode Colors
```swift
// ❌ WRONG
Button { } label: {
    Text("Attack")
}
.foregroundColor(Color(hex: "#D4A537"))

// ✅ CORRECT
Button { } label: {
    Text("Attack")
}
.foregroundColor(.gold)
```

### Never Guess Token Names
Before using ANY `DarkFantasyTheme.xxx`:
1. Open `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
2. Confirm the property exists
3. Use the exact name

Common mistakes that DO NOT EXIST:
- ❌ `.accent` — use `.gold` instead
- ❌ `.primary` (color) — use `.bgPrimary` instead
- ❌ `.background` — use `.bgSecondary` instead
- ❌ `.text` — use `.textPrimary` instead

### Correct Token Examples
```swift
// Colors
.foregroundColor(.gold)
.foregroundColor(.textPrimary)
.background(.bgSecondary)

// Buttons
.buttonStyle(.primary)
.buttonStyle(.secondary)
.buttonStyle(.danger)

// Layout
.padding(.MD)
.frame(height: 56)
```

### Button Style Verification
Before using ANY button style:
1. Open `Hexbound/Hexbound/Theme/ButtonStyles.swift`
2. Verify the style name (e.g., `.primary`, `.secondary`, `.danger`, `.ghost`)
3. Check if animation modifiers like `.scalePress(0.97)` are already included

### Typography Verification
- Minimum font size is `LayoutConstants.textBadge` (11pt)
- Never use font sizes smaller than 11pt
- Always use the dynamic font functions from `DarkFantasyTheme`

## Component Library

### Views/Components/ (17 files)
- `ActiveQuestBanner` — quest type indicators in Hub
- `AvatarImageView` — character avatar with async loading + caching
- `BattleResultCardView` — combat result summary card
- `CurrencyDisplay` — gold/gems amount display with icon
- `GuestGateView` — full-screen guest upgrade prompt
- `GuestNudgeBanner` — inline banner prompting guest upgrade
- `HPBarView` — health bar (green→amber→red gradient)
- `ItemImageView` — item icon with rarity-colored border
- `LevelUpModalView` — level-up celebration modal
- `LoadingOverlay` — fullscreen loading spinner
- `OfflineBannerView` — network status indicator
- `ScreenLayout` — standard screen wrapper (contains `HubLogoButton`)
- `SkeletonViews` — loading placeholder cards
- `StaminaBarView` — stamina bar with recovery timer
- `TabSwitcher` — multi-tab segment selector
- `ToastOverlayView` — notification toasts (7 types)
- `VictoryParticlesView` — particle confetti for victory screens

### Theme/CardStyles.swift
- `panelCard()` — view modifier, styled card container
- `GoldDivider()` — decorative gold divider

**Check existing components before proposing new ones.**

---

## Design System Checklist

When designing or implementing new screens:
- [ ] All colors use `DarkFantasyTheme` tokens
- [ ] All buttons use `ButtonStyles` (not inline styling)
- [ ] Spacing uses `LayoutConstants` scale
- [ ] Minimum font size is 11pt
- [ ] Primary buttons are 56pt, secondary 48pt
- [ ] Touch targets minimum 48pt
- [ ] Loading states use skeletons, not spinners
- [ ] Empty states have clear CTA
- [ ] Error states define recovery action
- [ ] Color tokens verified against source files
- [ ] Button style tokens verified against source files
