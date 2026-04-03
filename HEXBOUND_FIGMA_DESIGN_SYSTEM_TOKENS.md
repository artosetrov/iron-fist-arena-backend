# Hexbound Figma Design System - Complete Token Extraction

**Extracted:** 2026-04-03
**File:** Hexbound-DS (fileKey: `uDjXIz7CdJxcEOI5jCBcjY`)
**Total Variables:** 198 (104 Primitives + 8 Spacing + 6 Radius + 80 Semantic Color)
**Text Styles:** 9
**Effect Styles:** 4

---

## Summary Statistics

| Collection | Count | Modes | Scopes |
|---|---|---|---|
| **Primitives** | 104 | Value | `[]` (Hidden — for internal aliasing only) |
| **Spacing** | 8 | Value | `["GAP"]` |
| **Radius** | 6 | Value | `["CORNER_RADIUS"]` |
| **Color (Semantic)** | 80 | Dark | FILL / TEXT / STROKE (role-specific) |
| **Text Styles** | 9 | — | — |
| **Effect Styles** | 4 | — | — |
| **TOTAL** | **198** | | |

---

## 1. Primitives Collection (104 Raw Colors)

**Scope:** `[]` (Hidden)
**Mode:** Value
**Purpose:** Raw hex values. NEVER use directly in components — always alias through the Color collection.

### Background Colors (9)

| Token | Hex | Use |
|---|---|---|
| `bg/abyss` | `#08080C` | Darkest bg, deep voids |
| `bg/primary` | `#0D0D12` | Main application bg |
| `bg/secondary` | `#1A1A2E` | Secondary bg, panels |
| `bg/tertiary` | `#16213E` | Tertiary bg, cards |
| `bg/elevated` | `#1E2240` | Elevated surfaces |
| `bg/disabled` | `#333340` | Disabled element bg |
| `bg/dark-panel` | `#141428` | Dark modal panels |
| `bg/card-gradient-start` | `#1C1C30` | Card gradient top |
| `bg/card-gradient-end` | `#2A2A40` | Card gradient bottom |

### Gold/Primary Accent (4)

| Token | Hex | Use |
|---|---|---|
| `gold/default` | `#D4A537` | Standard gold (buttons, accents) |
| `gold/bright` | `#FFD700` | Bright gold (highlights) |
| `gold/dim` | `#8B6914` | Dim gold (disabled gold) |
| `gold/glow-orange` | `#F39C12` | Orange-gold glow variant |

### Feedback Colors (6)

| Token | Hex | Use |
|---|---|---|
| `feedback/danger` | `#E63946` | Error/danger states |
| `feedback/success` | `#2ECC71` | Success states |
| `feedback/info` | `#3498DB` | Informational |
| `feedback/cyan` | `#00D4FF` | Cyan accent |
| `feedback/purple` | `#9B59B6` | Purple accent |
| `feedback/stamina` | `#E67E22` | Stamina indicator |

### Text Colors (12)

| Token | Hex | Use |
|---|---|---|
| `text/primary` | `#F5F5F5` | Main text |
| `text/secondary` | `#A0A0B0` | Secondary text |
| `text/tertiary` | `#6B6B80` | Tertiary text |
| `text/disabled` | `#555566` | Disabled text |
| `text/gold` | `#FFD700` | Gold text (CTA) |
| `text/on-gold` | `#1A1A2E` | Text ON gold background |
| `text/danger` | `#FF6B6B` | Danger text |
| `text/success` | `#5DECA5` | Success text |
| `text/warning` | `#FFA502` | Warning text |
| `text/status-good` | `#7BED9F` | Good status |
| `text/dim-label` | `#4A4A6A` | Dim labels |
| `text/tertiary-aa` | `#8A8AA0` | WCAG AA contrast tertiary |

### Border Colors (6)

| Token | Hex | Use |
|---|---|---|
| `border/subtle` | `#2A2A3E` | Subtle borders |
| `border/medium` | `#3A3A50` | Medium borders |
| `border/strong` | `#4A4A60` | Strong borders |
| `border/ornament` | `#B8860B` | Ornamental borders |
| `border/card` | `#3A3A55` | Card borders |
| `border/dark-panel` | `#252545` | Dark panel borders |

### Rarity Colors (5)

| Token | Hex | Use |
|---|---|---|
| `rarity/common` | `#999999` | Common items |
| `rarity/uncommon` | `#4DCC4D` | Uncommon items |
| `rarity/rare` | `#4D80FF` | Rare items |
| `rarity/epic` | `#A64DE6` | Epic items |
| `rarity/legendary` | `#FFBF1A` | Legendary items |

### Class Colors (4)

| Token | Hex | Use |
|---|---|---|
| `class/warrior` | `#E68C33` | Warrior class |
| `class/rogue` | `#4DD958` | Rogue class |
| `class/mage` | `#6680FF` | Mage class |
| `class/tank` | `#9999B2` | Tank class |

### PvP Rank Colors (6)

| Token | Hex | Use |
|---|---|---|
| `rank/bronze` | `#B38040` | Bronze rank |
| `rank/silver` | `#BFBFCC` | Silver rank |
| `rank/gold` | `#FFD600` | Gold rank |
| `rank/platinum` | `#66CCCC` | Platinum rank |
| `rank/diamond` | `#99CCFF` | Diamond rank |
| `rank/grandmaster` | `#FF4D4D` | Grandmaster rank |

### Button Colors (13)

**Danger:**

| Token | Hex | Use |
|---|---|---|
| `btn/danger-fill` | `#8B1A22` | Danger btn fill |
| `btn/danger-stroke` | `#5A0A10` | Danger btn stroke |
| `btn/danger-accent` | `#FF6B6B` | Danger btn accent |

**Orange (Fight CTA):**

| Token | Hex | Use |
|---|---|---|
| `btn/orange-primary` | `#FF6600` | Primary orange |
| `btn/orange-bright` | `#FF8833` | Bright orange |
| `btn/orange-glow` | `#FF5000` | Glow orange |
| `btn/orange-stroke` | `#4A1500` | Orange stroke |
| `btn/orange-dark` | `#8B1A00` | Dark orange |
| `btn/orange-mid` | `#C44200` | Mid orange |
| `btn/orange-base` | `#D35400` | Base orange |

**Purple (Premium):**

| Token | Hex | Use |
|---|---|---|
| `btn/purple-dark` | `#7B2D8E` | Dark purple |
| `btn/purple-bright` | `#C77DDF` | Bright purple |
| `btn/purple-stroke` | `#6C3483` | Purple stroke |

### Premium Colors (4)

| Token | Hex | Use |
|---|---|---|
| `premium/pink` | `#E5A0FF` | Premium accent |
| `premium/bg` | `#2A1040` | Premium bg |
| `premium/bg-deep` | `#1A0A2E` | Premium deep bg |
| `premium/border` | `#352050` | Premium border |

### Dungeon/Progression Colors (9)

| Token | Hex | Use |
|---|---|---|
| `dungeon/bg-deep` | `#0C0C18` | Dungeon deep bg |
| `dungeon/bg-purple` | `#120E24` | Dungeon purple bg |
| `dungeon/bg-card` | `#1A1A30` | Dungeon card bg |
| `dungeon/boss-border` | `#6C3483` | Boss card border |
| `dungeon/loot-gold` | `#F1C40F` | Loot gold |
| `dungeon/text-boss` | `#8A8AAA` | Boss text |
| `dungeon/locked-gray` | `#2A2A45` | Locked node bg |
| `dungeon/text-locked` | `#3A3A5A` | Locked text |
| `dungeon/defeated` | `#1A9C54` | Defeated indicator |

### Arena/PvP Colors (4)

| Token | Hex | Use |
|---|---|---|
| `arena/rank-gold` | `#F39C12` | Arena rank gold |
| `arena/inner-glow` | `#2A2A50` | Arena inner glow |
| `arena/difficulty-hard` | `#E74C3C` | Hard difficulty |
| `arena/difficulty-hard-red` | `#E74C3C` | Hard difficulty red |

### VFX Colors (3)

| Token | Hex | Use |
|---|---|---|
| `vfx/poison` | `#7CFC00` | Poison effect |
| `vfx/burn` | `#FF6B35` | Burn effect |
| `vfx/stun` | `#FFF8DC` | Stun effect |

### Damage Zone Colors (3)

| Token | Hex | Use |
|---|---|---|
| `zone/head` | `#E66666` | Head damage zone |
| `zone/chest` | `#6699E6` | Chest damage zone |
| `zone/legs` | `#66E666` | Legs damage zone |

### Miscellaneous Colors (4)

| Token | Hex | Use |
|---|---|---|
| `misc/xp-ring` | `#5DADE2` | XP ring fill |
| `misc/xp-ring-track` | `#2A2A4A` | XP ring track |
| `misc/heal-flash` | `#2ECC71` | Heal flash |
| `misc/upgrade-blue` | `#60A5FA` | Upgrade indicator |

### Toast/Notification Colors (2)

| Token | Hex | Use |
|---|---|---|
| `toast/level-up` | `#66FF66` | Level-up toast |
| `toast/rank-up` | `#9966FF` | Rank-up toast |

### Glow/Atmospheric Colors (10)

| Token | Hex | Use |
|---|---|---|
| `glow/arena` | `#E68C33` | Arena atmosphere |
| `glow/mystic` | `#8040B0` | Mystic glow |
| `glow/forge` | `#FF6626` | Forge glow |
| `glow/nature` | `#4CAF50` | Nature glow |
| `glow/volcanic` | `#E65100` | Volcanic glow |
| `glow/ice` | `#42A5F5` | Ice glow |
| `glow/treasure` | `#FFD54F` | Treasure glow |
| `glow/shadow` | `#424242` | Shadow glow |
| `glow/stone` | `#78909C` | Stone glow |
| `glow/blood` | `#B71C1C` | Blood glow |

---

## 2. Spacing Collection (8 Variables)

**Scope:** `["GAP"]`
**Mode:** Value
**Purpose:** Inter-element gaps in auto-layout containers.

| Token | Value | Use |
|---|---|---|
| `spacing/2xs` | 2px | Micro gaps, badge padding |
| `spacing/xs` | 4px | Extra small gaps |
| `spacing/sm` | 8px | Small gaps, card internal |
| `spacing/ms` | 12px | Compact padding |
| `spacing/md` | 16px | Standard padding |
| `spacing/lg` | 24px | Section separation |
| `spacing/xl` | 32px | Large gaps |
| `spacing/2xl` | 48px | Hero section breaks |

---

## 3. Radius Collection (6 Variables)

**Scope:** `["CORNER_RADIUS"]`
**Mode:** Value
**Purpose:** Corner radius scale for all rounded shapes.

| Token | Value | Use |
|---|---|---|
| `radius/xs` | 3px | Minimal rounding |
| `radius/sm` | 6px | Small components |
| `radius/md` | 8px | Standard cards |
| `radius/lg` | 12px | Large panels |
| `radius/xl` | 16px | Extra large surfaces |
| `radius/2xl` | 22px | Maximum radius |

---

## 4. Color Collection (80 Semantic Aliases)

**Scope:** Varies by color role (FILL / TEXT / STROKE)
**Mode:** Dark
**Purpose:** Single-mode semantic aliases to Primitives. Use these in ALL components instead of raw primitives.

### Background Colors (9)

| Token | Aliases To | Scopes |
|---|---|---|
| `color/bg/abyss` | `bg/abyss` | `FRAME_FILL` |
| `color/bg/primary` | `bg/primary` | `FRAME_FILL` |
| `color/bg/secondary` | `bg/secondary` | `FRAME_FILL`, `SHAPE_FILL` |
| `color/bg/tertiary` | `bg/tertiary` | `FRAME_FILL`, `SHAPE_FILL` |
| `color/bg/elevated` | `bg/elevated` | `FRAME_FILL`, `SHAPE_FILL` |
| `color/bg/disabled` | `bg/disabled` | `FRAME_FILL`, `SHAPE_FILL` |
| `color/bg/dark-panel` | `bg/dark-panel` | `FRAME_FILL` |
| `color/bg/card-gradient-start` | `bg/card-gradient-start` | (gradient support) |
| `color/bg/card-gradient-end` | `bg/card-gradient-end` | (gradient support) |

### Gold/Primary Accent (4)

| Token | Aliases To | Scopes |
|---|---|---|
| `color/gold/default` | `gold/default` | `FRAME_FILL`, `SHAPE_FILL`, `STROKE_COLOR` |
| `color/gold/bright` | `gold/bright` | `SHAPE_FILL`, `TEXT_FILL`, `STROKE_COLOR` |
| `color/gold/dim` | `gold/dim` | `SHAPE_FILL`, `TEXT_FILL`, `STROKE_COLOR` |

### Feedback Colors (6)

| Token | Aliases To | Scopes |
|---|---|---|
| `color/feedback/danger` | `feedback/danger` | `FRAME_FILL`, `SHAPE_FILL`, `STROKE_COLOR` |
| `color/feedback/success` | `feedback/success` | `FRAME_FILL`, `SHAPE_FILL`, `STROKE_COLOR` |
| `color/feedback/info` | `feedback/info` | `FRAME_FILL`, `SHAPE_FILL` |
| `color/feedback/cyan` | `feedback/cyan` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/feedback/purple` | `feedback/purple` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/feedback/stamina` | `feedback/stamina` | `SHAPE_FILL`, `TEXT_FILL` |

### Text Colors (10)

| Token | Aliases To | Scopes |
|---|---|---|
| `color/text/primary` | `text/primary` | `TEXT_FILL` |
| `color/text/secondary` | `text/secondary` | `TEXT_FILL` |
| `color/text/tertiary` | `text/tertiary` | `TEXT_FILL` |
| `color/text/disabled` | `text/disabled` | `TEXT_FILL` |
| `color/text/gold` | `text/gold` | `TEXT_FILL` |
| `color/text/on-gold` | `text/on-gold` | `TEXT_FILL` |
| `color/text/danger` | `text/danger` | `TEXT_FILL` |
| `color/text/success` | `text/success` | `TEXT_FILL` |
| `color/text/warning` | `text/warning` | `TEXT_FILL` |

### Border Colors (5)

| Token | Aliases To | Scopes |
|---|---|---|
| `color/border/subtle` | `border/subtle` | `STROKE_COLOR` |
| `color/border/medium` | `border/medium` | `STROKE_COLOR` |
| `color/border/strong` | `border/strong` | `STROKE_COLOR` |
| `color/border/gold` | `gold/default` | `STROKE_COLOR` |
| `color/border/ornament` | `border/ornament` | `STROKE_COLOR` |

### Rarity Colors (5)

| Token | Aliases To | Scopes |
|---|---|---|
| `color/rarity/common` | `rarity/common` | `SHAPE_FILL`, `TEXT_FILL`, `STROKE_COLOR` |
| `color/rarity/uncommon` | `rarity/uncommon` | `SHAPE_FILL`, `TEXT_FILL`, `STROKE_COLOR` |
| `color/rarity/rare` | `rarity/rare` | `SHAPE_FILL`, `TEXT_FILL`, `STROKE_COLOR` |
| `color/rarity/epic` | `rarity/epic` | `SHAPE_FILL`, `TEXT_FILL`, `STROKE_COLOR` |
| `color/rarity/legendary` | `rarity/legendary` | `SHAPE_FILL`, `TEXT_FILL`, `STROKE_COLOR` |

### Class Colors (4)

| Token | Aliases To | Scopes |
|---|---|---|
| `color/class/warrior` | `class/warrior` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/class/rogue` | `class/rogue` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/class/mage` | `class/mage` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/class/tank` | `class/tank` | `SHAPE_FILL`, `TEXT_FILL` |

### Rank Colors (6)

| Token | Aliases To | Scopes |
|---|---|---|
| `color/rank/bronze` | `rank/bronze` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/rank/silver` | `rank/silver` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/rank/gold` | `rank/gold` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/rank/platinum` | `rank/platinum` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/rank/diamond` | `rank/diamond` | `SHAPE_FILL`, `TEXT_FILL` |
| `color/rank/grandmaster` | `rank/grandmaster` | `SHAPE_FILL`, `TEXT_FILL` |

---

## 5. Text Styles (9)

**Font Family:** All use system fonts (Oswald for headings, Inter for body)
**Letter Spacing:** Stored in PIXELS format
**Line Height:** Stored in PIXELS format

### Heading Styles

| Style | Font | Size | Weight | Line Height | Letter Spacing |
|---|---|---|---|---|---|
| **Heading/Cinematic Title** | Oswald | 40px | Semi Bold | 48px | 0px |
| **Heading/Title** | Oswald | 28px | Semi Bold | 34px | 0px |
| **Heading/Section** | Oswald | 22px | Semi Bold | 28px | 0px |
| **Heading/Card Title** | Oswald | 18px | Semi Bold | 24px | 0px |
| **Heading/Button Label** | Oswald | 18px | Semi Bold | 24px | 2px |

### Body Styles

| Style | Font | Size | Weight | Line Height | Letter Spacing |
|---|---|---|---|---|---|
| **Body/Body** | Inter | 16px | Regular | 22px | 0px |
| **Body/UI Label** | Inter | 14px | Regular | 20px | 0px |
| **Body/Caption** | Inter | 12px | Regular | 16px | 0px |
| **Body/Badge** | Inter | 11px | Bold | 14px | 0.5px |

---

## 6. Effect Styles (4)

### Shadow/Card

**Effects:** 2 drop shadows (layered depth)

```
Shadow 1 (base):
  Type: DROP_SHADOW
  Offset: 0, 2px
  Blur: 6px
  Spread: 0
  Color: rgba(0, 0, 0, 0.30)
  Blend: NORMAL

Shadow 2 (edge):
  Type: DROP_SHADOW
  Offset: 0, 1px
  Blur: 2px
  Spread: 0
  Color: rgba(8, 8, 12, 0.50)
  Blend: NORMAL
```

**Use:** Standard card shadows (shallow depth)

### Shadow/Modal

**Effects:** 2 drop shadows (prominent depth)

```
Shadow 1 (glow):
  Type: DROP_SHADOW
  Offset: 0, 0px
  Blur: 24px
  Spread: 0
  Color: rgba(242, 153, 74, 0.18)
  Blend: NORMAL

Shadow 2 (base):
  Type: DROP_SHADOW
  Offset: 0, 8px
  Blur: 32px
  Spread: 0
  Color: rgba(8, 8, 12, 0.90)
  Blend: NORMAL
```

**Use:** Modal dialogs, elevated surfaces (deep shadow)

### Shadow/Gold Glow

**Effects:** 1 drop shadow (gold accent)

```
Shadow 1 (glow):
  Type: DROP_SHADOW
  Offset: 0, 4px
  Blur: 10px
  Spread: 0
  Color: rgba(242, 159, 18, 0.40)
  Blend: NORMAL
```

**Use:** Gold/premium button accents, CTA highlights

### Shadow/Danger Glow

**Effects:** 1 drop shadow (danger accent)

```
Shadow 1 (glow):
  Type: DROP_SHADOW
  Offset: 0, 4px
  Blur: 8px
  Spread: 0
  Color: rgba(230, 57, 70, 0.25)
  Blend: NORMAL
```

**Use:** Danger buttons, error states

---

## iOS Code Mapping

All Figma variable names map 1:1 to Swift `DarkFantasyTheme` and `LayoutConstants`:

### Primitives → Not exposed (internal only)

### Spacing → `LayoutConstants`

```swift
LayoutConstants.space2XS     // 2px
LayoutConstants.spaceXS      // 4px
LayoutConstants.spaceSM      // 8px
LayoutConstants.spaceMS      // 12px
LayoutConstants.spaceMD      // 16px
LayoutConstants.spaceLG      // 24px
LayoutConstants.spaceXL      // 32px
LayoutConstants.space2XL     // 48px
```

### Radius → `LayoutConstants`

```swift
LayoutConstants.radiusXS     // 3px
LayoutConstants.radiusSM     // 6px
LayoutConstants.radiusMD     // 8px
LayoutConstants.radiusLG     // 12px
LayoutConstants.radiusXL     // 16px
LayoutConstants.radius2XL    // 22px
```

### Semantic Color → `DarkFantasyTheme`

```swift
DarkFantasyTheme.bgAbyss
DarkFantasyTheme.bgPrimary
DarkFantasyTheme.bgSecondary
DarkFantasyTheme.bgTertiary
DarkFantasyTheme.bgElevated
DarkFantasyTheme.bgDisabled
DarkFantasyTheme.bgDarkPanel

DarkFantasyTheme.gold
DarkFantasyTheme.goldBright
DarkFantasyTheme.goldDim

DarkFantasyTheme.textPrimary
DarkFantasyTheme.textSecondary
DarkFantasyTheme.textTertiary
DarkFantasyTheme.textDisabled
DarkFantasyTheme.textGold
DarkFantasyTheme.textOnGold
DarkFantasyTheme.textDanger
DarkFantasyTheme.textSuccess
DarkFantasyTheme.textWarning

DarkFantasyTheme.borderSubtle
DarkFantasyTheme.borderMedium
DarkFantasyTheme.borderStrong
DarkFantasyTheme.borderOrnament

// ... and all rarity, class, rank, feedback colors
```

### Text Styles → `DarkFantasyTheme` font tokens

```swift
DarkFantasyTheme.cinematicTitle  // 40px Oswald
DarkFantasyTheme.title           // 28px Oswald
DarkFantasyTheme.section         // 22px Oswald
DarkFantasyTheme.cardTitle       // 18px Oswald
DarkFantasyTheme.buttonLabel     // 18px Oswald, +2px letter spacing
DarkFantasyTheme.body            // 16px Inter
DarkFantasyTheme.uiLabel         // 14px Inter
DarkFantasyTheme.caption          // 12px Inter
DarkFantasyTheme.badge           // 11px Inter Bold
```

### Effect Styles → Hardcoded in component SwiftUI modifiers

```swift
// Shadow/Card
.shadow(color: Color.black.opacity(0.30), radius: 6, x: 0, y: 2)
.shadow(color: Color(hex: "#08080C").opacity(0.50), radius: 2, x: 0, y: 1)

// Shadow/Modal
.shadow(color: Color(hex: "#F29F4A").opacity(0.18), radius: 24, x: 0, y: 0)
.shadow(color: Color(hex: "#08080C").opacity(0.90), radius: 32, x: 0, y: 8)

// Shadow/Gold Glow
.shadow(color: Color(hex: "#F29F12").opacity(0.40), radius: 10, x: 0, y: 4)

// Shadow/Danger Glow
.shadow(color: Color(hex: "#E63946").opacity(0.25), radius: 8, x: 0, y: 4)
```

---

## Design System Sync Status (Figma ↔ Code)

**Last verified:** 2026-04-03

| Layer | Count | Status | Source | Notes |
|---|---|---|---|---|
| **Primitives** | 104 | ✓ Synced | Figma Primitives collection | Hidden scopes — never exposed |
| **Spacing** | 8 | ✓ Synced | Figma Spacing collection → LayoutConstants | Verified in code |
| **Radius** | 6 | ✓ Synced | Figma Spacing collection → LayoutConstants | Verified in code |
| **Semantic Color** | 80 | ✓ Synced | Figma Color collection → DarkFantasyTheme | Verified in code |
| **Text Styles** | 9 | ✓ Synced | Figma text styles → DarkFantasyTheme font tokens | Verified in code |
| **Effect Styles** | 4 | ✓ Manual | Figma effect styles → hardcoded in components | No Figma-to-code binding yet |

---

## Usage Guidelines

### Do's

- Use semantic Color variables (e.g., `color/text/primary`, not `text/primary` primitive)
- Bind color variables to component properties in Figma
- Export spacing/radius to iOS as LayoutConstants
- Apply text styles to all text in Figma (auto-applies font/size/weight)
- Apply effect styles to shadow layers
- Version token changes with migrations

### Don'ts

- Never use Primitives directly in Figma components (results in no semantic aliasing)
- Never hardcode hex values in code (defeats token purpose)
- Don't invent new token names without updating both Figma and code
- Don't change token values without updating Figma design system file
- Never apply custom shadows to components (use Shadow effect styles instead)

---

## Cross-Layer Audit Checklist

- [ ] All 80 semantic colors in Figma Color collection match DarkFantasyTheme
- [ ] All 8 spacing tokens bound to GAP scope in component frames
- [ ] All 6 radius tokens bound to CORNER_RADIUS scope
- [ ] All 9 text styles applied to text nodes (no override)
- [ ] All 4 effect styles applied to shadow nodes
- [ ] No hardcoded hex values in component shapes (only variable-bound fills)
- [ ] No Primitives collection scopes set (remain `[]`)
- [ ] Color collection mode set to "Dark" only (no modes)
- [ ] All variables have iOS code syntax display (e.g., `DarkFantasyTheme.gold`)

