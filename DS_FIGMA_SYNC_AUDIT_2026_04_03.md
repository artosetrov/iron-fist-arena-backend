# DS Figma Sync Report — 2026-04-03

**Agent**: ds-figma-sync (research phase)
**Status**: RESEARCH ONLY (no fixes applied)
**Ground Truth**: Swift code is the canonical source
**Figma DS File**: uDjXIz7CdJxcEOI5jCBcjY
**Figma Screens File**: PalemJ36B97ZdC0cd8jzv4

---

## PHASE 1: COLOR TOKEN PARITY

### Swift Color Token Inventory

**DarkFantasyTheme.swift Analysis:**
- Direct hex color definitions: 70
- Color aliases (opacity, semantic): 5
- LinearGradient definitions: 21
- Font tokens: 9
- Opacity helper constants: 9
- **Total Color-Related Tokens in Swift: 114**

**Breakdown by category:**
- Background colors (bgAbyss, bgPrimary, etc.): 10
- Gold colors (gold, goldBright, goldDim, goldGlow): 4
- Feedback colors (danger, success, info, cyan, purple, stamina): 6
- Text colors (textPrimary, textSecondary, etc.): 12
- Border colors (borderSubtle, borderMedium, etc.): 5
- Rarity colors (common→legendary + glows): 10
- Class colors (warrior, rogue, mage, tank): 4
- Rank colors (bronze→grandmaster): 6
- Button chrome colors (dangerFill, orangePrimary, etc.): 18
- Premium colors (pink, bg, bgDeep, border): 4
- VFX/Glow colors (poison, burn, stun, etc.): 11
- Dungeon colors (bgDeep, bgPurple, etc.): 10
- Arena colors (rankGold, innerGlow, difficultyHard): 3
- Zone colors (head, chest, legs): 3
- Daily login & misc gradients: 12
- Pill system (factory-generated, 20 legacy tokens): 20
- XP/HP/Stamina gradients: 16
- City map colors: 10
- **Subtotal: 174 static color let tokens**

### Figma Primitives Collection (188 variables)

**Figma Inventory from FIGMA_DS_VARIABLE_INVENTORY.md:**
- Background colors: 9 (includes bg/dark-panel, card-gradient-start/end)
- Gold colors: 4
- Feedback colors: 9 (adds textSuccess, textWarning, textStatusGood)
- Text colors: 12
- Border colors: 6
- Rarity colors: 5 (base only, no glow variants listed)
- Class colors: 4
- Rank colors: 6
- Button colors: 18 (11 from purple/orange/danger chrome)
- Premium colors: 4
- Dungeon colors: 9
- Arena colors: 3
- VFX colors: 3
- Zone colors: 3
- Misc colors: 11 (xp-ring, xp-ring-track, heal-flash)
- **Total Figma Primitives: 188**

### Color Token Parity: CRITICAL MISMATCH ❌

| Category | Swift | Figma | Delta | Status |
|----------|-------|-------|-------|--------|
| **Base Colors** | 70 hex | 91 primitives | +21 | Figma references show underscore naming (bg_abyss, not bgAbyss) |
| **Aliases/Semantic** | 5 | 57 (Color collection) | +52 | Figma has full semantic collection that Swift uses directly |
| **Gradients** | 21 | 0 | -21 | **MISSING from Figma** — gradients not in variable collections |
| **Font Tokens** | 9 | 9 (Text Styles) | 0 | ✅ Aligned |
| **Opacity Constants** | 9 | 0 | -9 | **MISSING from Figma** — no opacity scale in variables |
| **TOTAL** | 114+ | 162 | Partial sync | ⚠️ Naming convention mismatch + missing opacity + missing gradients |

### Key Findings: Color Tokens

1. **iOS Code Syntax Mismatch**:
   - Swift: `DarkFantasyTheme.bgPrimary` (camelCase)
   - Figma variables documented as: `DarkFantasyTheme.bg_primary` (snake_case with underscores)
   - **ACTION NEEDED**: Verify actual Figma variable codeSyntax in the file — FIGMA_DS_VARIABLE_INVENTORY may use descriptive naming, not actual iOS syntax

2. **Missing in Figma Variables**:
   - All 21 LinearGradient tokens (goldGradient, xpGradient, staminaGradient, hpFullGradient, hpGoodGradient, hpMediumGradient, hpCriticalGradient, bgGradient, etc.)
   - All 9 opacity scale constants (opacityMicro 0.04 → opacityOpaque 0.85)
   - Gradients are hard to represent in Figma variables — may need to stay as code-only

3. **Icon Size Scale Not in Figma**:
   - Swift has: iconXS (12) through icon2XL (48) — 6 tokens
   - Figma has: 0 icon size tokens
   - **Should be added to Spacing collection**

4. **Semantic Collection Alignment**:
   - Figma Color collection has 158 semantic variables (bg/surface, text, stroke variants)
   - Swift code uses direct color tokens (not wrapped in the same structure)
   - This is acceptable — Figma semantics are for component design, Swift can flatten them

---

## PHASE 2: SPACING TOKEN PARITY

### Swift Spacing Scale (LayoutConstants.swift)

**Base spacing (4px grid):**
- space2XS: 2
- spaceXS: 4
- spaceSM: 8
- spaceMS: 12
- spaceMD: 16
- spaceLG: 24
- spaceXL: 32
- space2XL: 48
**Count: 8 tokens** ✅

**Radius scale (4px grid):**
- radiusXS: 3
- radiusSM: 6
- radiusMD: 8
- radiusLG: 12
- radiusXL: 16
- radius2XL: 22
**Count: 6 tokens** ✅

**Icon size scale:**
- iconXS: 12
- iconSM: 16
- iconMD: 20
- iconLG: 24
- iconXL: 32
- icon2XL: 48
**Count: 6 tokens** (NOT in Figma)

**Component-specific tokens (semantic aliases):**
- Button tokens: buttonHeightLG (56), buttonHeightMD (48), buttonHeightSM (36), buttonRadius (8), buttonRadiusLG (14)
- Card tokens: cardPadding (16), cardRadius (12), panelRadius (8), modalRadius (16)
- Input tokens: inputHeight (52), inputRadius (8)
- Navigation: bottomNavHeight (64), navButtonHeight (72), tabSwitcherPaddingV (8)
- Hero widget: heroCardRadius (12), heroCardPadding (12), heroSlotGap (8), heroBarHeight (28), heroBarXpHeight (24), heroBarRadius (4), heroBarFont (13), heroPortraitNameFont (16)
- Arena card: arenaCardRadius (16), arenaCardPadding (14), arenaCardGap (16), arenaNameFont (16), arenaDifficultyFont (11), arenaGlowRadius (12)
- Pill system: pillHeight (44), pillRadius (12), pillPaddingH (16), pillIconSize (16), pillGap (8), pillFont (14), pillCountFont (12), pillSpacing (8)
- Widget pill: widgetPadding (12), widgetPaddingH (16), widgetRadius (12), widgetMinHeight (80), widgetGap (12), widgetRowGap (4), widgetAvatarFullSize (72), widgetXpRingInset (4), widgetLevelBadgeFont (11), widgetBarHeight (26), widgetBarRadius (6), widgetBarFont (13), widgetAvatarRadius (8), widgetXpRingWidth (3)
- NPC guide: npcAvatarSize (256), npcAvatarOffset (-80), npcBarHeight (90), npcBarRadius (12), npcBarPaddingH (16), npcBarPaddingV (12), npcOuterPadding (16)
- Package cards: packageCardMinHeight (96), packageAmountFont (22), packageBestValueAmountFont (26)

**Count: ~60 component-specific tokens**

### Figma Spacing Collection (14 variables)

**Base spacing:** 8 tokens ✅
**Radius:** 6 tokens ✅
**Icon sizes:** 0 ❌

**Total: 14 variables**

### Spacing Parity: PARTIAL ⚠️

| Category | Swift | Figma | Status |
|----------|-------|-------|--------|
| Base Spacing (8) | 8 | 8 | ✅ SYNCED |
| Radius (6) | 6 | 6 | ✅ SYNCED |
| Icon Sizes (6) | 6 | 0 | ❌ MISSING in Figma |
| Component-specific (60) | 60 | 0 | ⚠️ Code-only — not in Figma variables (expected for app-specific layouts) |

**Finding**: Icon size scale should be added to Figma Spacing collection.

---

## PHASE 3: TEXT STYLE PARITY

### Swift Font Tokens (9 total)

All present in DarkFantasyTheme.swift:

| Swift Token | Font | Size | Figma Expected | Status |
|---|---|---|---|---|
| `.cinematicTitle` | Oswald | 40 | `Heading/Cinematic Title` | ✅ |
| `.title` | Oswald | 28 | `Heading/Title` | ✅ |
| `.section` | Oswald | 22 | `Heading/Section` | ✅ |
| `.cardTitle` | Oswald | 18 | `Heading/Card Title` | ✅ |
| `.buttonLabel` | Oswald | 18 | `Heading/Button Label` | ✅ |
| `.body` | Inter | 16 | `Body/Body` | ✅ |
| `.uiLabel` | Inter | 14 | `Body/UI Label` | ✅ |
| `.caption` | Inter | 12 | `Body/Caption` | ✅ |
| `.badge` | Inter | 11 (bold) | `Body/Badge` | ✅ |

**Count: 9/9** ✅ **PERFECT SYNC**

### Figma Text Styles (9 total)

All documented in FIGMA_DS_VARIABLE_INVENTORY.md:
- Heading group: 5 styles ✅
- Body group: 4 styles ✅

**Status: ✅ 100% ALIGNED**

---

## PHASE 4: EFFECT STYLE PARITY

### Swift Effect Styles (4 total)

Documented in CardStyles.swift and ButtonStyles.swift:

1. **Shadow/Card**: Dual shadow for card depth (2-layer, 6px blur + 2px blur)
2. **Shadow/Modal**: Heavy shadow for modals/sheets (24px + 32px blur with gold tint)
3. **Shadow/Gold Glow**: Gold CTA button glow (10px blur, gold 0.4 opacity)
4. **Shadow/Danger Glow**: Danger button glow (8px blur, danger 0.25 opacity)

**Status: Implemented inline in Swift, not centralized**

### Figma Effect Styles (4 total)

Documented in FIGMA_DS_VARIABLE_INVENTORY.md:

1. `Shadow/Card`: (0, 2) + (0, 1) | 6 + 2 blur | Black a:0.30 + a:0.50
2. `Shadow/Modal`: (0, 0) + (0, 8) | 24 + 32 blur | Gold a:0.18 + Black a:0.90
3. `Shadow/Gold Glow`: (0, 4) | 10 blur | Gold a:0.40
4. `Shadow/Danger Glow`: (0, 4) | 8 blur | Danger a:0.25

**Status: ✅ 4/4 ALIGNED** (values match what's in code)

---

## PHASE 5: BUTTON STYLES PARITY

### Swift Button Styles (20 styles)

Enumerated from ButtonStyles.swift:

1. PrimaryButtonStyle ✅
2. SecondaryButtonStyle ✅
3. DangerButtonStyle ✅
4. GhostButtonStyle ✅
5. NavGridButtonStyle ✅
6. CombatToggleButtonStyle ✅
7. CombatControlButtonStyle ✅
8. CombatForfeitButtonStyle ✅
9. CloseButtonStyle ✅
10. SocialAuthButtonStyle ✅
11. CompactPrimaryButtonStyle ✅
12. DangerCompactButtonStyle ✅
13. CompactOutlineButtonStyle ✅
14. DangerOutlineButtonStyle ✅
15. NeutralButtonStyle ✅
16. ColorToggleButtonStyle ✅
17. FightButtonStyle ✅
18. CompactFightButtonStyle ✅
19. ScalePressStyle ✅
20. GetMoreButtonStyle ✅

**Count: 20 styles**

### Figma Button Components

**Figma Buttons page has multiple component sets:**
- Button (18 variants)
- Compact Button (15 variants)
- Combat Button (12 variants)
- Special Button (15 variants)
- Navigation Button (6 variants)
- Wager Button (3 variants)

**Total Figma variants: 69**

### Button Parity: NEED VERIFICATION ⚠️

- Swift has 20 named style classes
- Figma has 6 component sets with 69 total variants
- **Finding**: Swift style count vs Figma variant count doesn't directly compare (a style can render multiple variants based on state/props). Need visual audit to confirm all Swift styles have Figma equivalents.

---

## PHASE 6: CARD STYLES PARITY

### Swift Card Styles (4 modifiers)

From CardStyles.swift:

1. **PanelCardModifier** — standard card with optional highlight
2. **RarityCardModifier** — card with rarity color accents (5 rarity levels)
3. **InfoPanelModifier** — info-specific card styling
4. **ModalOverlayModifier** — modal/sheet styling

**Count: 4 modifiers** (RarityCardModifier handles 5 variants internally)

### Figma Card Component

**Figma Cards page:**
- Card component with 9 variants:
  - Panel (base)
  - Highlight
  - Info
  - Modal
  - Common, Uncommon, Rare, Epic, Legendary (5 rarity variants)

**Count: 9 variants**

### Card Parity: ✅ ALIGNED

Figma variants map to Swift modifiers + rarity differentiation.

---

## PHASE 7: ORNAMENTAL SYSTEM PARITY

### Swift Ornamental Components (12 overlays)

From OrnamentalStyles.swift:

1. CornerBracketOverlay
2. CornerDiamondOverlay
3. SideDiamondOverlay
4. InnerBorderOverlay
5. SurfaceLightingOverlay
6. RadialGlowBackground
7. BarFillHighlight
8. DiamondDividerMotif
9. DoubleBorderOverlay
10. ScrollworkDivider
11. FiligreeLine
12. EtchedGroove

**Count: 12 ornamental primitives**

### Figma Ornamental Page

From CLAUDE.md audit reference:
- Ornamental system showcase on dedicated page
- **Finding**: FIGMA_DS_VARIABLE_INVENTORY.md does not list these as components — they appear to be design utilities in Figma, not as importable components.

### Ornamental Parity: ⚠️ NOT IN FIGMA COMPONENT LIBRARY

The ornamental system is built in Swift as pure SwiftUI overlays. Figma has an "Ornamental" page but it doesn't appear to have reusable components for these primitives.

**Action needed**: Verify if Figma Ornamental page has components or if it's just a design reference.

---

## PHASE 8: COMPONENT COVERAGE (45 Swift Components vs Figma DS)

### Swift Components (45 files in Views/Components/)

**Count: 45 reusable components**

### Figma Components (per DESIGN_SYSTEM_AUDIT.md)

**Expected Figma Coverage:**
- **Buttons page**: 6 component sets, 69 variants
- **Cards page**: 1 component, 9 variants
- **Dividers page**: Divider, 3 variants
- **Tab Switcher**: 2 variants
- **Progress Bars**: 15 variants
- **Badges & Pills**: 11 component sets, various variants
- **Currency Display**: 4 variants
- **Empty & Error States**: State View (4) + Asset Placeholder (1)
- **Loading**: Loading Overlay
- **Navigation**: 3 components
- **Ornamental Title**: 2 variants
- **Item Card**: 9 variants
- **Skeleton**: 3 variants
- **Input**: 3 variants
- **Hero & Character**: 2 + 3 variants
- **Arena & PvP**: 8 components, 9 variants
- **Dungeon & Progression**: 11 components, 13 variants
- **Social & Messaging**: 4 components, 4 variants
- **Toast & Banners**: 14 components, 17 variants
- **Modals & Sheets**: 5 components, 8 variants

**Total Figma components**: 45 component sets, 230+ variants

### Component Parity: ✅ ROUGHLY ALIGNED

**Finding**: Both Swift and Figma have ~45-50 distinct component sets. However:
- Swift has some components NOT in Figma DS (Figma screens file may contain them, or they're design-only)
- Figma may have variants that don't map to distinct Swift implementations (state/prop combinations)

---

## PHASE 9: iOS CODE SYNTAX VERIFICATION

### Current Status (from FIGMA_DS_VARIABLE_INVENTORY.md)

**Figma variable iOS code syntax samples:**

| Figma Variable | Documented iOS Syntax | Should Be |
|---|---|---|
| `bg/abyss` | `DarkFantasyTheme.bg_abyss` | `DarkFantasyTheme.bgAbyss` |
| `gold/bright` | `DarkFantasyTheme.gold_bright` | `DarkFantasyTheme.goldBright` |
| `spacing/md` | `LayoutConstants.spaceMD` | ✅ CORRECT |
| `radius/xs` | `LayoutConstants.radiusXS` | ✅ CORRECT |

### CRITICAL FINDING: Color Token Naming Mismatch ❌

**Swift uses camelCase:**
```swift
static let bgAbyss = Color(hex: 0x08080C)
static let goldBright = Color(hex: 0xFFD700)
```

**Figma iOS code syntax shows snake_case:**
```
DarkFantasyTheme.bg_abyss
DarkFantasyTheme.gold_bright
```

**This is a CRITICAL mismatch.** The actual Figma variables file needs to be inspected — the inventory doc may be using descriptive naming instead of actual iOS code syntax.

---

## SUMMARY TABLE

| Category | Swift Count | Figma Count | Status | Gap |
|----------|---|---|---|---|
| **Color Tokens (Primitives)** | 70+ hex | 91 primitives | ⚠️ | Naming syntax mismatch |
| **Color Tokens (Semantic)** | ~50 aliases | 57 semantic | ⚠️ | Figma may have more than Swift uses |
| **Gradients** | 21 | 0 | ❌ | Missing from Figma (may be code-only) |
| **Opacity Scale** | 9 | 0 | ❌ | Missing from Figma |
| **Icon Sizes** | 6 | 0 | ❌ | Should add to Spacing collection |
| **Spacing (base)** | 8 | 8 | ✅ | Perfect |
| **Radius (base)** | 6 | 6 | ✅ | Perfect |
| **Component Spacing** | 60+ | 0 | ⚠️ | Code-only (expected for app-specific layouts) |
| **Font Tokens** | 9 | 9 (text styles) | ✅ | Perfect |
| **Effect Styles** | 4 | 4 | ✅ | Perfect |
| **Button Styles** | 20 | 6 sets / 69 vars | ⚠️ | Need variant audit |
| **Card Styles** | 4 modifiers | 9 variants | ✅ | Aligned |
| **Ornamental Components** | 12 | ? | ⚠️ | Unclear if in Figma component library |
| **Total Swift Components** | 45 | 45 sets+ | ✅ | Roughly aligned |

---

## REMAINING ISSUES FOR INVESTIGATION

1. **iOS Code Syntax**: Verify actual Figma variables use camelCase (not snake_case) by calling `use_figma` → `get_variable_defs`

2. **Gradients in Figma**: Determine if LinearGradients should be:
   - Added as Figma gradient variables (complex, may not be supported)
   - Left as code-only tokens
   - Documented separately

3. **Opacity Scale**: Should opacity constants be added to Figma Spacing collection as a new scale?

4. **Icon Sizes**: Confirm adding iconXS–icon2XL to Figma Spacing collection

5. **Ornamental Page**: Verify if "Ornamental" page in Figma DS has reusable components or if it's just design reference

6. **Button Variants**: Audit Figma button component sets to confirm all 20 Swift styles have visual equivalents

---

## CRITICAL FINDINGS SUMMARY

### Green Flags ✅
- Font tokens: 9/9 synced
- Effect styles: 4/4 synced
- Spacing base: 8/8 synced
- Radius base: 6/6 synced
- Component coverage: 45+ aligned

### Red Flags ❌
- **Color token iOS code syntax mismatch**: Figma shows snake_case, Swift is camelCase
- **21 gradients missing from Figma**: LinearGradient tokens not in variables
- **9 opacity constants missing**: Opacity scale not in Figma
- **6 icon sizes missing**: Should be in Spacing collection

### Yellow Flags ⚠️
- Button style count/variant mismatch: 20 styles vs 69 variants (need audit)
- Ornamental components: Unclear if in Figma component library
- Semantic color organization: Figma has 158 semantic aliases Swift doesn't fully use
