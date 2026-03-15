# HEXBOUND — UI/UX CONSISTENCY AUDIT & UNIFIED STANDARD GUIDE

> **Version:** 1.0
> **Date:** 2026-03-15
> **Author:** Principal Mobile Game UX/UI Auditor
> **Platform:** iOS (SwiftUI, Portrait 1170×2532)
> **Scope:** 26 screens, 31 Swift view files, 4 theme files, 1 design document (3300+ lines)
> **Status:** COMPLETE AUDIT + CANONICAL STANDARDS

---

## TABLE OF CONTENTS

- [A. Executive Summary](#a-executive-summary)
- [B. Core Principles](#b-core-principles)
- [C. Heuristic Review (Nielsen Norman Group)](#c-heuristic-review)
- [D. Component Catalog](#d-component-catalog)
- [E. Layout Rules](#e-layout-rules)
- [F. Interaction Rules](#f-interaction-rules)
- [G. Standardization Matrix](#g-standardization-matrix)
- [H. Screen-by-Screen Review](#h-screen-by-screen-review)
- [I. Final Mandatory Rules](#i-final-mandatory-rules)
- [J. Critical UI/UX Inconsistencies](#j-critical-uiux-inconsistencies)
- [K. Approved Canonical Components](#k-approved-canonical-components)
- [L. Migration Plan to Unified Mobile Game UI System](#l-migration-plan)

---

## A. EXECUTIVE SUMMARY

### Overall Quality Level: **B+ (Good, with targeted fixes needed)**

The Hexbound UI system demonstrates **strong architectural foundations**. The `DarkFantasyTheme`, `ButtonStyles`, `CardStyles`, and `LayoutConstants` files form a coherent design system backbone. Approximately **87% of views (27/31)** follow the design system consistently. The design document is exceptionally detailed (3300+ lines covering all 26 screens with ASCII wireframes, tokens, and interaction states).

### Overall Consistency Level: **B− (Moderate inconsistencies present)**

While the system is well-architected, **4 critical files deviate significantly** from the design system, and approximately **15-20 instances of hardcoded values** exist across the codebase where theme tokens should be used.

### Top 5 Systemic Problems

| # | Problem | Severity | Impact |
|---|---------|----------|--------|
| 1 | **OnboardingDetailView** uses 30+ hardcoded hex colors, font sizes, and custom button styles instead of theme system | CRITICAL | First impression screen breaks design language for new players |
| 2 | **HP Bar gradient logic** exists in 3 different implementations (DarkFantasyTheme blood-red, HubCharacterCard green-amber-red, design doc green-amber-red) | HIGH | Conflicting visual language for the most important game metric |
| 3 | **Back navigation pattern** is inconsistent — HubLogoButton on most screens, custom back buttons on onboarding, no back on combat | HIGH | Breaks user control and freedom, increases cognitive load |
| 4 | **Hardcoded Color(hex:)** values in ArenaDetailView, LoadingOverlay, CombatDetailView, ItemCardView, DailyLoginDetailView bypass the theme system | MEDIUM | Maintenance nightmare, prevents global theme changes |
| 5 | **Currency display** exists as both `TopCurrencyBar` and `currencyRow` inside `HubCharacterCard` with different layouts, spacing, and behavior | MEDIUM | Same data displayed differently, breaks consistency |

### Top 5 Critical UX Errors

| # | Error | Nielsen Heuristic Violated |
|---|-------|---------------------------|
| 1 | No visible loading feedback when tapping FIGHT button before combat generation (7-14 turns calculated) | Visibility of System Status |
| 2 | Potion button on HubCharacterCard requires cached inventory to work — fails silently if cache empty | Error Prevention |
| 3 | BattlePassCard uses hardcoded mock data (`level: 7, maxLevel: 30`) with TODO comment | Match Between System and Real World |
| 4 | OnboardingDetailView (1019 lines) is a monolith with no reusable components | Consistency and Standards |
| 5 | No confirmation dialog before selling equipped items (sell button disabled but no explanation why) | Error Prevention |

### Quick Wins (< 1 day each)

1. Replace all `Color(hex: 0x...)` in view files with `DarkFantasyTheme.*` tokens
2. Unify HP bar gradient to single canonical implementation in `DarkFantasyTheme`
3. Add `LoadingOverlay` to combat initiation flow (arena FIGHT, training, dungeon FIGHT)
4. Wire real BattlePass data into `BattlePassCard` (remove TODO mock)
5. Extract onboarding step components into reusable views using `panelCard()` modifier

---

## B. CORE PRINCIPLES

### B.1 — Global Interface Principles

| Principle | Standard | Enforcement |
|-----------|----------|-------------|
| **Single Source of Truth** | ALL colors from `DarkFantasyTheme`, ALL sizes from `LayoutConstants`, ALL button styles from `ButtonStyles.swift` | Zero tolerance for hardcoded values |
| **3-Second Rule** | Player understands any screen's primary action within 3 seconds | Every screen must have ONE clear CTA |
| **Predictable Navigation** | Hub → any screen in 1 tap, any screen → Hub in 1 tap (HubLogoButton) | Maximum depth: 3 levels |
| **Touch-First** | Minimum 48×48pt touch targets, primary CTAs at 56pt height | No exceptions for interactive elements |
| **Cognitive Budget** | Maximum 4-6 actions visible simultaneously on any screen | Group secondary actions behind tabs/panels |
| **Immediate Feedback** | Every tap produces visual + optional haptic feedback within 100ms | Press state (scale 0.97) + color shift |

### B.2 — Unified Visual Language

**CANONICAL DECISION:** The visual language is **Dark Fantasy Premium** as defined in the design document. All screens must express this through:

- Dark stone backgrounds (`bgPrimary: #0D0D12`)
- Worn metal borders with metallic top-edge highlights
- Gold accent system for CTAs and important values
- Ornamental dividers between sections
- Rarity-coded elements for all game items

### B.3 — Unified UX Language

| Concept | Canonical Representation |
|---------|------------------------|
| **Primary Action** | Gold gradient button, 56px height, UPPERCASE Oswald |
| **Secondary Action** | Gold-outlined button, 48px height |
| **Destructive Action** | Crimson button (#E63946), requires confirmation |
| **Selected State** | 2px gold border + gold glow shadow |
| **Disabled State** | 40% opacity, gray (#333340) background, no interaction |
| **Locked State** | Grayscale + padlock icon overlay, 50% opacity |
| **Equipped State** | Rarity border + [E] badge + star icon |
| **Claimable State** | Pulsing gold border + notification dot |
| **Currency (Gold)** | icon-gold image + formatted number, goldBright color |
| **Currency (Gems)** | icon-gems image + number, cyan color |
| **Reward Gained** | "+X" prefix, green (`textSuccess`) or gold (`textGold`) |
| **Loss/Cost** | "−X" prefix or red text (`textDanger`) |
| **Progress** | Horizontal bar with gradient fill, numeric "X/Y" label |

### B.4 — Mobile-First Game UI Rules

1. **Thumb zone priority:** Primary CTA in bottom 40% of screen (reachable zone)
2. **One-hand operation:** All critical actions reachable without stretching
3. **Large touch targets:** Minimum 48pt, comfortable 56pt for primary actions
4. **Fast scanning:** Visual hierarchy via size/weight/color, not position alone
5. **Minimal text:** Use icons + short labels, not paragraphs
6. **Instant gratification:** Reward animations play immediately, not after navigation
7. **Session-friendly:** Every screen allows quick exit back to Hub

### B.5 — Readability Rules

| Rule | Standard |
|------|----------|
| Minimum font size | 11px (badge only), 12px (caption), 16px (body/buttons) |
| Minimum font weight | 500 (Medium) — no thin/light weights |
| Primary text contrast | ≥7:1 WCAG AAA (#F5F5F5 on #0D0D12 = 15.3:1) |
| Secondary text contrast | ≥4.5:1 WCAG AA (#A0A0B0 on #0D0D12 = 7.8:1) |
| Button text on gold | ≥4.5:1 (#1A1A2E on #D4A537 = 5.2:1) |
| Line height | ≥1.3× font size |
| Letter spacing | +2px buttons, +1.5px screen titles, +1px section headers |

### B.6 — Action & Feedback Rules

| Action Type | Feedback Required | Timing |
|-------------|-------------------|--------|
| Button tap | Scale 0.97 + color shift | ≤100ms |
| Navigation | Screen transition (fade/slide) | 300ms |
| API call start | Loading spinner overlay | Immediate |
| API call success | Toast (success type) + data refresh | ≤200ms after response |
| API call failure | Toast (error type) + retry option | ≤200ms after response |
| Reward claim | Gold particle burst + value animation | 500ms |
| Level up | Full-screen modal with scale animation | 800ms |
| Item equip | Slot highlight + equipped badge appear | 300ms |
| Destructive action | Confirmation dialog BEFORE execution | Blocking |

### B.7 — Cognitive Load Reduction Rules

1. **Progressive disclosure:** Show summary first, details on tap
2. **Recognition over recall:** Always show current state (equipped item, selected stance, active quest)
3. **Consistent placement:** Navigation always bottom, back always top-left, CTA always bottom of content
4. **Grouped information:** Stats together, currencies together, actions together
5. **Visual chunking:** Use `panelCard()` to group related information
6. **Default selections:** Pre-select last used / most common option
7. **Inline comparison:** Show delta ("▲ +8") next to new item stats, not separate screen

---

## C. HEURISTIC REVIEW

### C.1 — Visibility of System Status

**Current Score: 7/10**

| What Works | What's Broken | Fix |
|------------|---------------|-----|
| HP/Stamina/XP bars on Hub show real-time state | No loading indicator when generating combat turns (7-14 turns, noticeable delay) | Add `LoadingOverlay` to combat initiation in ArenaDetailView and HubView training flow |
| Toast system provides success/error/info feedback | BattlePassCard shows mock data, not real progress | Wire `BattlePassService` data into card |
| StaminaBarView shows timer and current/max values | Free PvP counter ("Free: 2/3") only visible inside Arena, not on Hub | Add free PvP indicator to Arena NavTile on Hub or stamina bar |
| Skeleton loading views exist for data fetch | Potion use result is a toast — easy to miss during quick play | Add HP bar animation (green flash overlay) — already implemented but requires cached inventory |

**Priority fix:** Loading state for combat initiation — player taps FIGHT and sees no feedback for 0.5-2 seconds while turns generate.

### C.2 — Match Between System and the Real World

**Current Score: 8/10**

| What Works | What's Broken | Fix |
|------------|---------------|-----|
| Game terminology is consistent (Gold, Gems, Stamina, XP, Rating) | 3-letter status effect codes (BLD, BRN, STN) require memorization | Replace with full words + colored icons during combat |
| Rarity colors follow industry standard (gray → green → blue → purple → gold) | "Prestige: 0" shown when prestige hasn't been explained to player | Hide prestige label when value is 0 |
| Class icons and colors are intuitive (Warrior=orange, Mage=blue) | Stat abbreviations (STR, AGI, VIT, END, INT, WIS, LUK, CHA) assume RPG literacy | Add tooltip/info icon on first view, or show full names on Character screen |

### C.3 — User Control and Freedom

**Current Score: 7/10**

| What Works | What's Broken | Fix |
|------------|---------------|-----|
| HubLogoButton provides 1-tap return to Hub from any screen | Combat screen has no way to exit mid-combat (only Skip to end) | Add "Forfeit" option with confirmation dialog |
| Back navigation consistent via toolbar | Onboarding has no "skip" for returning players switching characters | Add skip/fast-track for experienced players |
| Tab navigation (Opponents/Revenge/History) allows quick context switching | No undo for stat point allocation until Save is pressed | Add "Reset" button to restore original stat values |
| Sell action is available in item detail | No buy-back for accidentally sold items | Add buy-back tab in Shop for last 10 sold items |

### C.4 — Consistency and Standards

**Current Score: 6/10 (Primary improvement area)**

| What Works | What's Broken | Fix |
|------------|---------------|-----|
| `ButtonStyles.swift` defines 5 canonical button types used across most screens | OnboardingDetailView uses custom `AppearanceButtonStyle` not from system | Replace with `PrimaryButtonStyle` / `SecondaryButtonStyle` |
| `CardStyles.swift` provides `panelCard()`, `rarityCard()`, `infoPanel()`, `modalOverlay()` | HP bar gradient defined in 3 places with 3 different color schemes | Single canonical implementation in `DarkFantasyTheme` |
| `DarkFantasyTheme` has comprehensive color tokens (60+ colors) | 15-20 hardcoded `Color(hex:)` values across views | Replace all with theme tokens |
| `LayoutConstants` defines all spacing, sizing, and grid values | OnboardingDetailView has hardcoded spacing (14, 12, 10, 22px) | Replace with `LayoutConstants.spaceSM`, `.spaceMD`, etc. |
| `ScreenLayout` provides unified screen wrapper with toolbar | Some screens (HubView, CombatDetailView) don't use `ScreenLayout` | Document which screens are exempt and why |
| `TabSwitcher` is a reusable tab component | Arena tabs use custom implementation alongside `TabSwitcher` | Standardize on `TabSwitcher` everywhere |

### C.5 — Error Prevention

**Current Score: 7/10**

| What Works | What's Broken | Fix |
|------------|---------------|-----|
| Disabled buttons when preconditions not met (e.g., stat points = 0) | Sell button disabled for equipped items but no tooltip explaining why | Add "Unequip first" label or auto-unequip + confirm |
| Stamina check before training combat | No confirmation before spending 10 stamina on PvP | Add "Spend 10 STA?" confirmation for stamina-cost actions |
| Name validation on onboarding (max 16 chars) | No duplicate name check until API returns error | Pre-validate name uniqueness on blur |
| Login form shows validation errors | Guest login has no warning about data loss | Add "Guest data may be lost. Link account to save progress" warning |

### C.6 — Recognition Rather Than Recall

**Current Score: 8/10**

| What Works | What's Broken | Fix |
|------------|---------------|-----|
| Equipped items show [E] badge in inventory | Current stance (attack/defense zones) not visible on Hub or Arena | Show stance summary in Arena header or character card |
| Currency display persistent on Hub | Active quest objectives not visible during gameplay (only on Quests screen) | Add `ActiveQuestBanner` to combat result and loot screens |
| Class/race shown alongside character name | Item comparison deltas only visible in ItemDetailSheet, not in inventory grid | Add green/red arrows on inventory cards showing upgrade potential |
| Daily quest progress visible on Hub via floating icon | Battle Pass progress only visible inside Battle Pass screen | Show current BP reward in Hub banner |

### C.7 — Flexibility and Efficiency of Use

**Current Score: 8/10**

| What Works | What's Broken | Fix |
|------------|---------------|-----|
| Combat speed toggle (1x → 2x → Skip) | No "auto-equip best" option for inventory management | Add "Optimize Equipment" button on Equipment screen |
| Filter tabs for inventory (10 categories) | No search or sort options in inventory beyond filters | Add sort dropdown (level, rarity, stat) and search bar |
| Quick navigation from Hub to all screens (1 tap) | No shortcut to re-fight same opponent in Arena | Add "Rematch" button on combat result screen |
| Prefetch system (opponents, shop, achievements cached on Hub load) | No way to compare two items side-by-side | Add comparison mode in inventory |

### C.8 — Aesthetic and Minimalist Design

**Current Score: 9/10**

| What Works | What's Broken | Fix |
|------------|---------------|-----|
| Dark fantasy theme is cohesive and immersive | Hub screen has many floating action icons that can feel cluttered | Group floating icons into single expandable FAB |
| Ornamental dividers add flavor without noise | BattlePassCard uses emoji (🎖️) instead of custom icon | Replace all emoji with custom HUD icons (already have hud-gift, hud-quests) |
| Rarity glow system creates clear visual hierarchy | FirstWinBonusCard uses emoji (🎯) inconsistently | Create hud-first-win icon |
| Color coding is meaningful (stat colors, class colors, rarity colors) | — | — |

### C.9 — Help Users Recognize, Diagnose, and Recover from Errors

**Current Score: 6/10**

| What Works | What's Broken | Fix |
|------------|---------------|-----|
| Login screen shows validation errors | API errors show generic toast without actionable guidance | Add specific error messages: "Server busy, tap to retry" |
| Toast system differentiates success/error/info/warning | No offline mode or network error handling visible | Add "No connection" banner with retry button |
| Empty state labels exist in lists | Empty inventory shows generic text, not encouraging action | "Your inventory is empty. Win battles to earn loot!" + CTA to Arena |
| — | No error recovery for failed item equip/sell/purchase | Add retry mechanism in error toasts |

---

## D. COMPONENT CATALOG

### D.1 — Buttons

#### D.1.1 — PrimaryButton (Gold CTA)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `PrimaryButtonStyle` |
| **Purpose** | Main call-to-action on every screen |
| **Height** | 56px (`LayoutConstants.buttonHeightLG`) |
| **Background** | `DarkFantasyTheme.goldGradient` (D4A537 → B8860B) |
| **Text** | `textOnGold` (#1A1A2E), Oswald SemiBold 18px, UPPERCASE, tracking +2 |
| **Border** | 2px `borderOrnament` (#B8860B) |
| **Corner Radius** | 8px (`LayoutConstants.buttonRadius`) |
| **Shadow** | Gold glow, radius 12, y 4 |
| **Press State** | Scale 0.97, 150ms ease-out |
| **Disabled State** | 40% opacity, bg #333340, text #555566, no shadow |
| **Loading State** | Spinner overlay replacing text |
| **Where Used** | ENTER ARENA, CONTINUE, CONFIRM, SAVE, CLAIM, FIGHT, TAKE ALL |
| **Misuse** | Using for secondary actions, using without full-width |
| **Code** | `.buttonStyle(.primary)` or `.buttonStyle(.primary(enabled: condition))` |

#### D.1.2 — SecondaryButton (Gold Outline)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `SecondaryButtonStyle` |
| **Purpose** | Secondary actions, alternatives to primary CTA |
| **Height** | 48px (`LayoutConstants.buttonHeightMD`) |
| **Background** | Transparent (10% gold on press) |
| **Text** | `gold` (#D4A537), Oswald SemiBold 16px, UPPERCASE |
| **Border** | 1px gold (#D4A537) |
| **Where Used** | VIEW EQUIPMENT, OPEN INVENTORY, CREATE ACCOUNT, VIEW LOOT |
| **Misuse** | Using for primary CTA, using for destructive actions |
| **Code** | `.buttonStyle(.secondary)` |

#### D.1.3 — DangerButton (Crimson)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `DangerButtonStyle` |
| **Purpose** | Destructive or irreversible actions |
| **Height** | 48px |
| **Background** | `danger` (#E63946) |
| **Text** | White, Oswald SemiBold 16px, UPPERCASE |
| **Where Used** | SELL, LOGOUT, DELETE |
| **Rule** | ALWAYS pair with confirmation dialog |
| **Code** | `.buttonStyle(.danger)` |

#### D.1.4 — GhostButton (Text Only)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `GhostButtonStyle` |
| **Purpose** | Tertiary actions, links, dismiss actions |
| **Height** | Auto (no fixed height) |
| **Text** | `textSecondary`, Inter Regular 16px |
| **Press State** | 60% opacity |
| **Where Used** | Forgot Password, Cancel, Skip |
| **Code** | `.buttonStyle(.ghost)` |

#### D.1.5 — NavGridButton (Hub Navigation Tiles)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `NavGridButtonStyle` |
| **Purpose** | Hub screen navigation tiles (2×2 grid) |
| **Height** | 72px (`LayoutConstants.navButtonHeight`) |
| **Background** | `bgSecondary` (#1A1A2E) |
| **Border** | 1px `borderSubtle` + 1px `borderMedium` top highlight |
| **Corner Radius** | 12px (`LayoutConstants.cardRadius`) |
| **Shadow** | Black 40%, radius 4, y 2 |
| **Press State** | Scale 0.95 |
| **Where Used** | Hub navigation tiles only |
| **Code** | `.buttonStyle(.navGrid)` |

#### D.1.6 — IconButton (Floating Action)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `FloatingActionIcon` |
| **Purpose** | Floating circular action buttons |
| **Size** | 50-56px circle |
| **Background** | `bgSecondary` circle |
| **Border** | 1.5px accent color at 50% opacity |
| **Shadow** | Accent color 30%, radius 8 |
| **Badge** | 14px red dot with `bgPrimary` 2px border, pulse animation |
| **Where Used** | Hub floating icons (Daily Login, Quests, Sound) |
| **Code** | `FloatingActionIcon(customIcon:badgeActive:accentColor:size:action:)` |

**REJECTED PATTERNS:**
- ❌ `AppearanceButtonStyle` in OnboardingDetailView — replace with `PrimaryButtonStyle`
- ❌ Custom inline button styling in CombatDetailView speed buttons — extract to `CombatSpeedButtonStyle`
- ❌ Emoji-based buttons — replace with custom icon assets

### D.2 — Cards

#### D.2.1 — PanelCard (Standard Container)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `PanelCardModifier` |
| **Purpose** | General-purpose content container |
| **Background** | `bgSecondary` (#1A1A2E) |
| **Padding** | 16px (`LayoutConstants.cardPadding`) |
| **Corner Radius** | 12px (`LayoutConstants.cardRadius`) |
| **Border** | 1px `borderSubtle` (default), 2px `borderGold` (highlighted) |
| **Top Highlight** | 1px `borderMedium` metallic highlight |
| **Shadow** | Black 40% radius 4 y 2 (default), gold glow radius 12 (highlighted) |
| **Variants** | `panelCard()` (default), `panelCard(highlight: true)` (gold selected) |
| **Where Used** | Stat panels, info blocks, quest cards, leaderboard rows, reward lists |
| **Code** | `.panelCard()` or `.panelCard(highlight: true)` |

#### D.2.2 — RarityCard (Item Container)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `RarityCardModifier` |
| **Purpose** | Items with rarity classification |
| **Background** | `bgTertiary` (#16213E) |
| **Border** | 2px rarity color |
| **Shadow** | Rarity glow (8px standard, 12px legendary) |
| **Variants** | 5 rarity levels (common/uncommon/rare/epic/legendary) |
| **Where Used** | Inventory item cards, loot cards, shop item cards, equipment slots |
| **Code** | `.rarityCard(.epic)` |

#### D.2.3 — InfoPanel (Read-Only Data)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `InfoPanelModifier` |
| **Purpose** | Read-only information display |
| **Background** | `bgPrimary` (#0D0D12) — darker than PanelCard |
| **Border** | 1px `borderSubtle` + metallic top highlight |
| **Corner Radius** | 8px (`LayoutConstants.panelRadius`) |
| **Where Used** | Derived stats, equipment bonuses, reward summaries |
| **Code** | `.infoPanel()` |

#### D.2.4 — ModalOverlay (Full-Screen Overlay)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `ModalOverlayModifier` |
| **Purpose** | Modal dialogs, item detail, confirmations |
| **Background** | `bgSecondary` (#1A1A2E) |
| **Border** | 3px `borderOrnament` (#B8860B) |
| **Corner Radius** | 16px (`LayoutConstants.modalRadius`) |
| **Shadow** | Black 80%, radius 32, y 8 |
| **Backdrop** | `bgModal` (black 75%) |
| **Animation** | Scale 0.9→1.0 + fade, 300ms ease-out |
| **Where Used** | ItemDetailSheet, LevelUpModal, DailyLoginPopup, confirmation dialogs |
| **Code** | `.modalOverlay()` |

#### D.2.5 — HubCharacterCard (Hero Summary)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `HubCharacterCard` |
| **Purpose** | Character summary with avatar, HP, currencies |
| **Background** | Custom gradient (#1C1C30 → #2A2A40) |
| **Border** | 1px #3A3A55 |
| **Corner Radius** | 16px |
| **Components** | Avatar with XP ring, name + status, HP bar + potion button, currencies |
| **Where Used** | Hub screen only |
| **ISSUE** | Uses hardcoded colors instead of theme tokens |
| **FIX REQUIRED** | Replace Color(hex: 0x1C1C30) with DarkFantasyTheme.bgSecondary gradient |

#### D.2.6 — OpponentCard (Arena Opponent)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `OpponentCardView` |
| **Purpose** | Display arena opponent with fight action |
| **Container** | `.panelCard()` ✓ |
| **Components** | Avatar, name, class/race, rating, FIGHT button |
| **Where Used** | ArenaDetailView opponents list |
| **Status** | ✓ Fully compliant |

#### D.2.7 — HubBannerCard (Hub Promotional Banners)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `DailyQuestsCard`, `BattlePassCard`, `FirstWinBonusCard`, `DailyLoginCard` |
| **Purpose** | Promotional/status banners on Hub |
| **Layout** | HStack: icon (34px) + VStack(title + subtitle) + Spacer + progress bar (80×10) |
| **Background** | `bgSecondary` with `panelRadius` |
| **Border** | 1px accent color at 40-70% opacity |
| **Padding** | 14px |
| **ISSUE** | Padding is 14px, not `LayoutConstants.cardPadding` (16px) |
| **CANONICAL DECISION** | Standardize all hub banners to 14px padding (exception to 16px rule for compact cards) |

### D.3 — Navigation Components

#### D.3.1 — ScreenLayout (Screen Wrapper)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `ScreenLayout` |
| **Purpose** | Standard screen wrapper with toolbar |
| **Background** | `bgPrimary` full bleed |
| **Toolbar Leading** | `HubLogoButton` (40×40px hexbound-logo, 48×48 touch target) |
| **Toolbar Center** | Screen title (Oswald 18px, `goldBright`) |
| **Where Used** | All non-Hub, non-Combat screens |
| **Not Used On** | Hub (custom layout), Combat (fullscreen immersive), Onboarding (step-based) |

#### D.3.2 — TabSwitcher (Section Tabs)

| Property | Canonical Value |
|----------|----------------|
| **Name** | `TabSwitcher` |
| **Purpose** | Switch between content sections within a screen |
| **Layout** | HStack, equal-width tabs |
| **Active State** | `goldBright` text + `bgElevated` background + 2px gold bottom bar |
| **Inactive State** | `textTertiary` text + transparent background |
| **Background** | `bgSecondary` with `panelRadius` border |
| **Animation** | 200ms ease-in-out |
| **Where Used** | Arena (Opponents/Revenge/History), Achievements (categories), Leaderboard (Rating/Level/Gold), Shop (categories) |
| **Code** | `TabSwitcher(tabs: ["Tab1", "Tab2"], selectedIndex: $index)` |

#### D.3.3 — Bottom Navigation (NOT IMPLEMENTED IN CODE)

**CRITICAL FINDING:** The design document specifies a 3-tab bottom navigation bar (Hub / Hero / Leader) with 64px height, but the **actual implementation uses no bottom nav**. Instead, navigation is through the Hub's CityMapView (interactive city buildings) and HubLogoButton for back navigation.

**CANONICAL DECISION:** The CityMapView approach is the **correct implementation** for this game. The design doc bottom nav is superseded. Document this decision explicitly.

### D.4 — Progress Bars

#### D.4.1 — HP Bar

| Property | Canonical Value |
|----------|----------------|
| **CANONICAL DECISION** | Use the HubCharacterCard gradient system (green → amber → red based on percentage) for ALL HP bars across the app |
| **Track** | `bgTertiary` (#16213E), corner radius 7px |
| **Fill ≥100%** | #2ECC71 → #55EFC4 (bright green) |
| **Fill ≥75%** | #2ECC71 → #7BED9F (green) |
| **Fill ≥25%** | #E67E22 → #F1C40F (amber to yellow) |
| **Fill <25%** | #C0392B → #E74C3C (red) + pulse animation |
| **Height** | 16px (Hub), 12px (Combat), 10px (compact) |
| **Text** | "current / max" inside bar, Inter Bold 10px, white 90% |

**REJECTED:** `DarkFantasyTheme` blood-red unified HP bars (`hpHighGradient`, `hpMidGradient`, `hpLowGradient`) — they reduce information density by making all HP states red.

#### D.4.2 — XP Bar

| Property | Canonical Value |
|----------|----------------|
| **Gradient** | `DarkFantasyTheme.xpGradient` (#9B59B6 → #8E44AD, purple) |
| **Track** | `bgTertiary` |
| **Height** | 10px (standard), 4px ring stroke (Hub avatar) |

#### D.4.3 — Stamina Bar

| Property | Canonical Value |
|----------|----------------|
| **Gradient** | `DarkFantasyTheme.staminaGradient` (#E67E22 → #D35400, orange) |
| **Component** | `StaminaBarView` |
| **Display** | Icon + "STA" label + bar + "X/Y" text + timer |

### D.5 — Dividers

| Type | Implementation | Usage |
|------|----------------|-------|
| **GoldDivider** | Gradient: clear → goldDim → gold → goldDim → clear, 1px height | Between major sections |
| **OrnamentalDivider** | 1px lines + "---" text in goldDim | Between subsections |
| **Simple Border** | 1px `borderSubtle` | Card internal separation |

### D.6 — Toast Notifications

| Property | Canonical Value |
|----------|----------------|
| **Component** | `ToastOverlayView` |
| **Position** | Top-center, 80px from top |
| **Animation** | Slide down + fade in (300ms), hold 3s, slide up + fade out (200ms) |
| **Types** | success (green), error (red), info (blue), warning (gold), reward (rarity color) |
| **Container** | `.panelCard()` |

### D.7 — Loading States

| Property | Canonical Value |
|----------|----------------|
| **Component** | `LoadingOverlay` |
| **Background** | Semi-transparent dark overlay |
| **Spinner** | Pulsing animation |
| **ISSUE** | Uses hardcoded `Color(hex: 0x0A0A14)` instead of theme |
| **FIX** | Replace with `DarkFantasyTheme.bgAbyss` or `.bgPrimary.opacity(0.9)` |

### D.8 — Empty States

| Property | Canonical Value |
|----------|----------------|
| **Layout** | Centered: Icon (64px) + Title (Oswald 18px) + Subtitle (Inter 14px) + Optional CTA Button |
| **Icon** | SF Symbol or custom asset, `textTertiary` color |
| **Title** | Descriptive, e.g., "No opponents found" |
| **Subtitle** | Actionable, e.g., "Pull to refresh or try again later" |
| **CTA** | Optional `SecondaryButtonStyle` button |

---

## E. LAYOUT RULES

### E.1 — Screen Structure

```
┌─────────────────────────────────────┐
│ Safe Area Top (59px)                │
├─────────────────────────────────────┤
│ Toolbar: [HubLogo] [TITLE] [Action]│ ← 48px height
├─────────────────────────────────────┤
│ ← 16px padding →                   │
│                                     │
│ [Scrollable Content]                │ ← Main content area
│                                     │
│ ← 16px padding →                   │
├─────────────────────────────────────┤
│ [Sticky CTA Zone] (if applicable)  │ ← Bottom-pinned primary button
├─────────────────────────────────────┤
│ Safe Area Bottom (34px)             │
└─────────────────────────────────────┘
```

### E.2 — Header Rules

| Rule | Standard |
|------|----------|
| **Back navigation** | `HubLogoButton` (hexbound-logo, 40×40px, 48×48 touch) — ALWAYS top-left |
| **Screen title** | Centered, Oswald 18px, `goldBright`, UPPERCASE |
| **Right action** | Optional icon button (settings, notifications, filter) |
| **Exceptions** | Hub (no header, uses CityMapView), Combat (fullscreen, no header) |

### E.3 — Content Width & Padding

| Rule | Value |
|------|-------|
| **Screen horizontal padding** | 16px (`LayoutConstants.screenPadding`) |
| **Card internal padding** | 16px (`LayoutConstants.cardPadding`) |
| **Hub banner padding** | 14px (compact card exception) |
| **Modal padding** | 24px (`LayoutConstants.spaceLG`) |
| **Content max width** | Full screen width minus 2×16px padding |

### E.4 — Spacing Between Sections

| Context | Spacing |
|---------|---------|
| Between cards in a list | 8px (`spaceSM`) |
| Between sections (e.g., Stats → Derived Stats) | 16px (`spaceMD`) |
| Between major sections (e.g., Character → Actions) | 24px (`spaceLG`) |
| Screen top gap (below header) | 16px (`screenTopGap`) |

### E.5 — Grid Configurations

| Grid | Columns | Gap | Usage |
|------|---------|-----|-------|
| Inventory | 4 | 8px | Item cards |
| Equipment | 3 | 12px | Equipment slots |
| Hub Navigation | 2 | 12px | Nav tiles |
| Class/Race Selection | 2 | 12px | Onboarding grids |
| Shop | 4 | 10px | Shop item cards |

### E.6 — CTA Placement Rules

| Context | Placement |
|---------|-----------|
| Single primary CTA | Bottom of scrollable content, full-width, 16px side padding |
| Dual CTA (primary + secondary) | Stacked vertically: primary on top, secondary below, 8px gap |
| Dual CTA (action + destructive) | Side-by-side: action left (primary), destructive right (danger) |
| Modal CTA | Inside modal, bottom, full modal width |

### E.7 — Modal Layout

| Rule | Standard |
|------|----------|
| **Backdrop** | Black 75% opacity |
| **Panel** | `bgSecondary`, 3px ornamental border, 16px corner radius |
| **Padding** | 24px |
| **Shadow** | Black 80%, radius 32, y 8 |
| **Entry animation** | Scale 0.9→1.0 + fade, 300ms ease-out |
| **Exit animation** | Scale 1.0→0.95 + fade, 200ms ease-in |
| **Close** | X button top-right OR tap backdrop |

### E.8 — Scroll Behavior

| Rule | Standard |
|------|----------|
| **Primary CTA** | Sticky at bottom when content scrolls (if applicable) |
| **Tabs** | Sticky at top below header |
| **Header** | Always visible (ScreenLayout toolbar) |
| **Content** | Vertical scroll only (no horizontal scroll except CityMapView) |

### E.9 — Safe Area Rules

| Area | Handling |
|------|----------|
| **Top** | 59px (Dynamic Island), toolbar content below |
| **Bottom** | 34px (Home indicator), CTA above |
| **Background** | `.ignoresSafeArea()` for `bgPrimary` only |
| **Content** | Never ignore safe areas |

---

## F. INTERACTION RULES

### F.1 — Tap / Press States

| Component | Default | Pressed | Timing |
|-----------|---------|---------|--------|
| Primary Button | Gold gradient | Darker gold, scale 0.97 | 150ms ease-out |
| Secondary Button | Transparent + gold border | 10% gold fill | 150ms ease-out |
| Danger Button | Crimson | Darker crimson, scale 0.97 | 150ms ease-out |
| Nav Tile | bgSecondary | scale 0.95 | 150ms ease-out |
| Card (selectable) | Default border | scale 0.98 | 150ms |
| Icon Button | Default color | scale 0.9, brighter color | 150ms |
| List Row | Default | 5% white overlay | 100ms |

### F.2 — Loading States

| Context | Behavior |
|---------|----------|
| **Screen data fetch** | Skeleton views (gray shimmer placeholders) |
| **Button action** | Button text → spinner, button disabled |
| **Combat generation** | `LoadingOverlay` with "Preparing battle..." text |
| **Network request** | Global toast after 5s: "Taking longer than expected..." |

### F.3 — Success Feedback

| Action | Feedback |
|--------|----------|
| Item equipped | Toast "Equipped [item name]" (success), slot highlight animation |
| Item sold | Toast "+X gold" (reward), gold counter animation |
| Quest completed | Toast "Quest complete!" (success), progress bar fill animation |
| Level up | `LevelUpModalView` (full screen), scale + particle animation |
| Reward claimed | Gold particle burst, value count-up animation |
| Stat saved | Button text → "Saved!" for 1s, then reset |

### F.4 — Disabled States

| Component | Visual | Behavior |
|-----------|--------|----------|
| Button | 40% opacity, bg #333340, text #555566, no shadow | No press effect, no action |
| Card | 40% opacity, grayscale | No tap response |
| Input | 50% opacity | No keyboard, no focus |
| Tab | Same as inactive (textTertiary) | No tap response |

### F.5 — Locked States

| Component | Visual | Behavior |
|-----------|--------|----------|
| Dungeon card | Grayscale + padlock overlay, 50% opacity | Tap shows "Reach Level X to unlock" toast |
| Achievement | Gray border, padlock icon | Shows progress toward unlock |
| Shop item | Gray overlay + "Locked" label | Shows unlock requirements |

### F.6 — Selection States

| Component | Selected Visual | Deselection |
|-----------|----------------|-------------|
| Race/Class card | 2px gold border + gold glow + checkmark | Tap another card |
| Gender toggle | Gold fill + dark text | Tap other option |
| Avatar card | Gold border + glow | Tap another avatar |
| Stance zone | Zone color at 100% + colored text | Tap another zone |
| Tab | Gold text + bgElevated + 2px gold bottom bar | Tap another tab |
| Inventory filter | Gold fill + dark text | Tap another filter |

### F.7 — Equipped States

| Visual | Behavior |
|--------|----------|
| Rarity-colored 2px border on slot | Tap opens ItemDetailSheet with "Unequip" option |
| [E] badge top-left of item card | Cannot sell while equipped |
| Star icon on equipped item | — |
| Rarity glow shadow | Enhanced for legendary |

### F.8 — Reward Claim States

| State | Visual |
|-------|--------|
| **Claimable** | Pulsing gold border, notification dot, "CLAIM" button enabled |
| **Claimed** | Green checkmark, "Claimed" text, button disabled |
| **Locked/Future** | Gray border, padlock or timer, "Day X" label |

### F.9 — Destructive Actions

| Action | Required Pattern |
|--------|-----------------|
| Sell item | Confirmation dialog: "Sell [item] for X gold?" with Cancel + Confirm |
| Logout | Confirmation: "Are you sure? Guest progress may be lost" |
| Allocate stats (reset) | "Reset all changes?" with Cancel + Reset |
| Spend premium currency | "Spend X gems?" with Cancel + Confirm |

### F.10 — Confirmation Dialog Pattern

```
┌─────────────────────────────────────┐
│ [Black 75% backdrop]                │
│                                     │
│   ┌─────────────────────────┐       │
│   │ CONFIRM ACTION          │       │  ← Oswald 18px gold
│   │ ──── ornamental ────    │       │
│   │                         │       │
│   │ Are you sure you want   │       │  ← Inter 16px white
│   │ to sell Iron Helmet?    │       │
│   │                         │       │
│   │ [  CANCEL  ] [ CONFIRM ]│       │  ← Secondary + Primary buttons
│   └─────────────────────────┘       │
│                                     │
└─────────────────────────────────────┘
```

---

## G. STANDARDIZATION MATRIX

| Current Element | Where Found | Issue | UX Risk | Canonical Standard | Required Fix |
|----------------|-------------|-------|---------|-------------------|-------------|
| `Color(hex: 0x1C1C30)` gradient | HubCharacterCard | Hardcoded colors bypass theme | Theme changes won't propagate | `DarkFantasyTheme.bgSecondary` gradient variant | Add `bgCardGradient` to theme |
| `Color(hex: 0x5DADE2)` XP ring | HubCharacterCard, ArenaDetailView | Hardcoded blue not in theme | Inconsistent XP color | Add `xpRing` color to theme (#5DADE2) | Add token + replace |
| `Color(hex: 0x0A0A14)` bg | LoadingOverlay, CombatDetailView | Hardcoded dark background | Inconsistent backgrounds | `DarkFantasyTheme.bgAbyss` (#08080C) | Replace with token |
| `Color(hex: 0x7BED9F)` status | HubCharacterCard | Hardcoded status green | Inconsistent success color | `DarkFantasyTheme.textSuccess` (#5DECA5) | Replace with token |
| `Color(hex: 0xFFA502)` warning | HubCharacterCard | Hardcoded warning amber | No theme amber | Add `textWarning` to theme | Add token + replace |
| `Color(hex: 0xFF6B6B)` critical | HubCharacterCard | Hardcoded critical red | Similar to `textDanger` but different | Use `DarkFantasyTheme.textDanger` (#FF6B6B) — already matches | Replace with token |
| `AppearanceButtonStyle` | OnboardingDetailView | Custom button style outside system | Breaks consistency on first screen | `PrimaryButtonStyle` / `SecondaryButtonStyle` | Refactor onboarding |
| HP gradient (blood-red) | DarkFantasyTheme | Conflicts with green/amber/red in HubCharacterCard | Two different HP visual languages | Green→amber→red percentage-based | Deprecate blood-red variants |
| Emoji icons (🎖️🎯) | BattlePassCard, FirstWinBonusCard | Emoji inconsistent with custom icon system | Visual inconsistency with hud-* icons | Custom HUD icon assets | Create hud-battlepass, hud-firstwin icons |
| Hardcoded padding 14px | Hub banner cards | Not in LayoutConstants | Magic number in code | Document as `bannerPadding` in LayoutConstants | Add constant |
| 3-letter status codes (BLD, BRN) | CombatDetailView | Requires memorization | Players must recall abbreviations | Full words + colored icons | Add status effect icon component |
| Custom inline tab styling | ArenaDetailView (arena header) | Not using TabSwitcher | Inconsistent tab behavior | `TabSwitcher` component | Refactor arena tabs |
| `Font.system(size: 30)` emoji | Hub banner cards (🎖️🎯) | System font, not theme font | Typography inconsistency | Custom icon asset (no emoji) | Replace with Image() |
| `.primary(enabled:)` pattern | LoginView | Custom parameter not standard | Deviation from button system | Use `.primary` + `.disabled()` modifier | Standardize approach |
| Hardcoded hex in DurabilityRing | ItemCardView | Theme colors available but unused | Minor inconsistency | Theme success/stamina/danger colors | Replace with tokens |

---

## H. SCREEN-BY-SCREEN REVIEW

### H.1 — Splash Screen
- ✅ What works: Simple, focused, brand introduction
- ✅ What should stay: Loading bar, auto-login flow
- ⚠️ Issue: No entry in codebase reviewed (likely native or separate)

### H.2 — Login Screen
- ✅ What works: Clear form hierarchy, primary/secondary/ghost buttons, error display
- ❌ Breaks consistency: `.primary(enabled:)` custom parameter
- ❌ Breaks consistency: Hardcoded `Color.black` for OAuth buttons
- 🔧 Fix: Use standard `.primary` + `.disabled()`, add OAuth button style to ButtonStyles

### H.3 — Onboarding (Character Creation)
- ✅ What works: Step-by-step wizard, progress dots, clear flow
- ❌ **CRITICAL:** 30+ hardcoded hex colors instead of theme tokens
- ❌ Breaks consistency: Custom `AppearanceButtonStyle` not in design system
- ❌ Breaks consistency: Hardcoded font sizes (14, 12, 10, 22px)
- ❌ Breaks consistency: 1019-line monolith with no extracted components
- 🔧 Fix: Major refactor — extract step components, replace all hardcoded values

### H.4 — Hub Screen
- ✅ What works: CityMapView is immersive, character card is informative, floating icons are accessible
- ✅ What works: Prefetch system for instant navigation
- ⚠️ Issue: BattlePassCard uses mock data (TODO)
- ⚠️ Issue: Emoji icons on some banners
- ⚠️ Issue: Currency display duplicated (TopCurrencyBar vs HubCharacterCard.currencyRow)
- 🔧 Fix: Wire BattlePass data, replace emoji with custom icons, choose single currency display

### H.5 — Character Screen (HeroDetailView)
- ✅ What works: Stat allocation UI clear, derived stats visible, uses `panelCard()`, proper button styles
- ✅ Fully compliant with design system

### H.6 — Stance Selector
- ✅ What works: Clear zone selection, visual feedback, `panelCard(highlight:)` usage
- ✅ Fully compliant

### H.7 — Inventory Screen
- ✅ What works: 10 filter tabs, 4-column grid, rarity-based styling
- ⚠️ Issue: DurabilityRingOverlay hardcoded colors
- 🔧 Fix: Replace with theme tokens

### H.8 — Item Detail Sheet
- ✅ What works: Comparison deltas (▲/▼), proper button hierarchy, `panelCard()` usage
- ⚠️ Minor: One hardcoded hex (0x60A5FA)
- 🔧 Fix: Add `info` shade to theme

### H.9 — Equipment Screen
- ✅ Fully compliant

### H.10 — Arena Screen
- ✅ What works: Tab system, opponent cards with FIGHT CTA, rating display
- ⚠️ Issue: Hardcoded colors in stamina bar gradient
- ⚠️ Issue: No loading feedback when initiating combat
- 🔧 Fix: Replace hardcoded colors, add loading state to FIGHT flow

### H.11 — Combat Screen
- ✅ What works: Immersive fullscreen, speed controls, animated turn log
- ⚠️ Issue: Hardcoded background color (0x0A0A14)
- ⚠️ Issue: 3-letter status codes require memorization
- ⚠️ Issue: Custom inline button styling for speed controls
- 🔧 Fix: Use theme bgAbyss, add full status names, extract speed button style

### H.12 — Combat Result Screen
- ✅ Fully compliant — proper gradient backgrounds, button styles, layout

### H.13 — Loot Screen
- ✅ Fully compliant — animated reveal, rarity styling, proper CTAs

### H.14 — Dungeon Select
- ✅ Fully compliant — difficulty tabs, dungeon cards with progress, proper theming

### H.15 — Dungeon Room
- ✅ Fully compliant

### H.16 — Shop Screen
- ✅ Fully compliant — tab system, item cards, currency display

### H.17 — Battle Pass
- ✅ What works: Track visualization, claim system
- ⚠️ Issue: `AnyShapeStyle` wrapper is verbose
- 🔧 Minor cleanup

### H.18 — Achievements
- ✅ Fully compliant — category tabs, achievement cards, progress bars

### H.19 — Daily Quests
- ✅ Fully compliant — quest cards, progress tracking, claim system

### H.20 — Daily Login
- ✅ What works: 7-day grid, streak tracking, claim flow
- ⚠️ Issue: `Color(red:green:blue:)` instead of theme colors in day circles
- 🔧 Fix: Replace with theme tokens

### H.21 — Leaderboard
- ✅ Fully compliant — rank styling, player highlighting, tab filters

### H.22 — Settings
- ✅ Fully compliant — custom `.settingsCard()` helper well-implemented

### H.23 — Shell Game
- ✅ Fully compliant — proper theming, animation states

### H.24 — Gold Mine
- ✅ Fully compliant

### H.25 — Dungeon Rush
- ✅ Fully compliant

### H.26 — Level Up Modal
- ✅ What works: Dramatic animation, reward display
- ⚠️ Issue: Hardcoded font sizes (64, 44)
- 🔧 Fix: Add `textCelebration` sizes to LayoutConstants

---

## I. FINAL MANDATORY RULES

These rules are **non-negotiable** for all current and future screens:

### I.1 — Color Rules
1. **ZERO hardcoded `Color(hex:)`** in any View file — ALL colors from `DarkFantasyTheme`
2. If a new color is needed, add it to `DarkFantasyTheme` first, then reference the token
3. Rarity colors ONLY via `DarkFantasyTheme.rarityColor(for:)` helper
4. Class colors ONLY via `DarkFantasyTheme.classColor(for:)` helper
5. Stat colors ONLY via `DarkFantasyTheme.statColor(for:)` helper

### I.2 — Typography Rules
6. ALL fonts from `DarkFantasyTheme.*` font properties
7. ALL font sizes from `LayoutConstants.text*` constants
8. Minimum font size: 11px (badge only), 12px (caption), 16px (body/buttons)
9. Minimum font weight: 500 (Medium)
10. ALL button and screen title text: UPPERCASE with proper letter-spacing

### I.3 — Spacing Rules
11. ALL spacing from `LayoutConstants.space*` constants
12. Screen horizontal padding: ALWAYS `LayoutConstants.screenPadding` (16px)
13. Card internal padding: ALWAYS `LayoutConstants.cardPadding` (16px) or 14px for hub banners
14. No magic numbers for spacing — if a new spacing is needed, add it to LayoutConstants

### I.4 — Component Rules
15. ALL buttons MUST use one of 5 canonical `ButtonStyle` implementations
16. ALL content containers MUST use `panelCard()`, `rarityCard()`, `infoPanel()`, or `modalOverlay()`
17. ALL screen wrappers MUST use `ScreenLayout` (exceptions: Hub, Combat, Onboarding — documented)
18. ALL tab interfaces MUST use `TabSwitcher` component
19. ALL toasts MUST use `ToastOverlayView` system
20. ALL loading states MUST use `LoadingOverlay` or skeleton views

### I.5 — Interaction Rules
21. ALL buttons MUST have press state (scale 0.97 for primary, 0.95 for nav) with 150ms animation
22. ALL destructive actions MUST show confirmation dialog BEFORE execution
23. ALL API calls MUST show loading indicator (spinner or skeleton)
24. ALL API errors MUST show error toast with actionable message
25. ALL successful actions MUST provide visual + optional haptic feedback

### I.6 — Navigation Rules
26. Back navigation: ALWAYS `HubLogoButton` in toolbar leading position
27. Maximum navigation depth: 3 levels (Hub → Screen → Sub-screen)
28. Hub reachable in 1 tap from any screen
29. No dead-end screens — always provide back/continue/close action

### I.7 — Accessibility Rules
30. ALL interactive elements: minimum 48×48pt touch target
31. Primary text contrast: ≥7:1 (WCAG AAA)
32. Secondary text contrast: ≥4.5:1 (WCAG AA)
33. No information conveyed by color alone — always pair with text/icon

### I.8 — Game-Specific Rules
34. Currencies ALWAYS displayed with icon + formatted number (comma-separated for gold)
35. Rarity ALWAYS indicated by both border color AND glow shadow
36. Equipped items ALWAYS show [E] badge
37. Progress bars ALWAYS show numeric "X/Y" or "X%" label
38. Rewards ALWAYS shown with "+" prefix and green/gold color
39. Costs ALWAYS shown with "−" prefix or red color
40. Locked content ALWAYS shows unlock requirement text

---

## J. CRITICAL UI/UX INCONSISTENCIES

### J.1 — Priority: CRITICAL (Fix before next release)

| ID | Inconsistency | Files Affected | Impact | Fix |
|----|---------------|----------------|--------|-----|
| C-01 | OnboardingDetailView uses 30+ hardcoded colors, fonts, and custom button style | `OnboardingDetailView.swift` | First impression screen breaks design language | Full refactor: extract components, use theme tokens |
| C-02 | HP bar gradient has 3 conflicting implementations | `DarkFantasyTheme.swift`, `HubCharacterCard.swift`, design doc | Players see different HP colors on different screens | Standardize on green→amber→red, deprecate blood-red |
| C-03 | No loading feedback on combat initiation | `ArenaDetailView.swift`, `HubView.swift` | Player sees no response for 0.5-2s after FIGHT tap | Add `LoadingOverlay` to combat flow |

### J.2 — Priority: HIGH (Fix within 2 sprints)

| ID | Inconsistency | Files Affected | Impact | Fix |
|----|---------------|----------------|--------|-----|
| H-01 | 15-20 hardcoded `Color(hex:)` values across views | Arena, Combat, ItemCard, Loading, DailyLogin, HubChar | Theme changes don't propagate, maintenance debt | Replace all with theme tokens |
| H-02 | Currency display duplicated with different layouts | `TopCurrencyBar`, `HubCharacterCard.currencyRow` | Same data shown differently | Choose single canonical currency component |
| H-03 | Emoji icons (🎖️🎯) on Hub banners while custom icons exist | `BattlePassCard`, `FirstWinBonusCard` | Visual inconsistency with hud-* icon system | Create custom icon assets |
| H-04 | BattlePassCard uses hardcoded mock data | `HubView.swift` | Player sees fake progress | Wire real data from BattlePassService |

### J.3 — Priority: MEDIUM (Fix within quarter)

| ID | Inconsistency | Files Affected | Impact | Fix |
|----|---------------|----------------|--------|-----|
| M-01 | Arena tabs use custom implementation instead of TabSwitcher | `ArenaDetailView.swift` | Different tab behavior/look vs other screens | Refactor to use TabSwitcher |
| M-02 | Status effect abbreviations (BLD, BRN, STN) | `CombatDetailView.swift` | Requires memorization, breaks "recognition over recall" | Use full words + colored icons |
| M-03 | No confirmation before stamina-cost actions | Arena FIGHT flow | Accidental stamina spending | Add "Spend X STA?" dialog |
| M-04 | LoginView uses `.primary(enabled:)` custom parameter | `LoginView.swift` | Different button pattern than rest of app | Standardize to `.primary` + `.disabled()` |

---

## K. APPROVED CANONICAL COMPONENTS

### K.1 — APPROVED: Use These Everywhere

| Component | File | Usage |
|-----------|------|-------|
| `PrimaryButtonStyle` | `ButtonStyles.swift` | All primary CTAs |
| `SecondaryButtonStyle` | `ButtonStyles.swift` | All secondary actions |
| `DangerButtonStyle` | `ButtonStyles.swift` | All destructive actions |
| `GhostButtonStyle` | `ButtonStyles.swift` | All tertiary/text-only actions |
| `NavGridButtonStyle` | `ButtonStyles.swift` | Hub navigation tiles only |
| `PanelCardModifier` (.panelCard()) | `CardStyles.swift` | All standard containers |
| `RarityCardModifier` (.rarityCard()) | `CardStyles.swift` | All item/loot containers |
| `InfoPanelModifier` (.infoPanel()) | `CardStyles.swift` | All read-only data panels |
| `ModalOverlayModifier` (.modalOverlay()) | `CardStyles.swift` | All modal dialogs |
| `ScreenLayout` | `ScreenLayout.swift` | All standard screens |
| `HubLogoButton` | `ScreenLayout.swift` | Back navigation (all screens) |
| `TabSwitcher` | `TabSwitcher.swift` | All tabbed interfaces |
| `GoldDivider` | `CardStyles.swift` | Major section dividers |
| `OrnamentalDivider` | `CardStyles.swift` | Sub-section dividers |
| `LoadingOverlay` | `LoadingOverlay.swift` | All loading states |
| `ToastOverlayView` | `ToastOverlayView.swift` | All feedback notifications |
| `StaminaBarView` | `StaminaBarView.swift` | Stamina display |
| `CurrencyDisplay` | `CurrencyDisplay.swift` | Currency display |
| `FloatingActionIcon` | `HubView.swift` | Hub floating buttons |
| `LevelUpModalView` | `LevelUpModalView.swift` | Level up celebrations |
| `AvatarImageView` | `AvatarImageView.swift` | Character avatar display |
| `ItemImageView` | `ItemImageView.swift` | Item icon display |
| `ActiveQuestBanner` | `ActiveQuestBanner.swift` | Quest progress indicators |
| `SkeletonViews` | `SkeletonViews.swift` | Data loading placeholders |

### K.2 — DEPRECATED: Do Not Use

| Component | Replacement | Reason |
|-----------|-------------|--------|
| `AppearanceButtonStyle` | `PrimaryButtonStyle` | Non-standard, onboarding only |
| Hardcoded `Color(hex:)` in views | `DarkFantasyTheme.*` | Bypasses theme system |
| Emoji icons (🎖️🎯🟢) | Custom `Image("hud-*")` assets | Inconsistent with icon system |
| `Font.system(size:)` | `DarkFantasyTheme.*` font helpers | Bypasses typography system |
| `DarkFantasyTheme.hpHighGradient` (blood-red) | HP gradient function in HubCharacterCard | Conflicting HP visual language |
| `DarkFantasyTheme.hpMidGradient` | ↑ | ↑ |
| `DarkFantasyTheme.hpLowGradient` | ↑ | ↑ |
| `DarkFantasyTheme.hpRed` | `DarkFantasyTheme.danger` | Legacy alias, confusing |
| `DarkFantasyTheme.hpGreen` | Deprecated — use HP gradient function | Named "green" but actually red |
| `DarkFantasyTheme.xpBlue` | `DarkFantasyTheme.purple` | Misleading name |

### K.3 — NEW TOKENS TO ADD

| Token Name | Value | Purpose |
|------------|-------|---------|
| `DarkFantasyTheme.xpRing` | `Color(hex: 0x5DADE2)` | XP ring on avatar (currently hardcoded) |
| `DarkFantasyTheme.textWarning` | `Color(hex: 0xFFA502)` | Warning/amber status text |
| `DarkFantasyTheme.bgCardGradient` | `LinearGradient(#1C1C30 → #2A2A40)` | Character card gradient |
| `DarkFantasyTheme.bgCardBorder` | `Color(hex: 0x3A3A55)` | Character card border |
| `LayoutConstants.bannerPadding` | `14` | Hub banner internal padding |
| `LayoutConstants.textCelebration` | `44` | Level up / victory large text |
| `LayoutConstants.textHero` | `64` | Level up number display |

---

## L. MIGRATION PLAN TO UNIFIED MOBILE GAME UI SYSTEM

### Phase 1: Token Consolidation (1-2 days)

**Goal:** Zero hardcoded values in any view file.

| Task | Files | Effort |
|------|-------|--------|
| Add missing tokens to `DarkFantasyTheme` (xpRing, textWarning, bgCardGradient, bgCardBorder) | `DarkFantasyTheme.swift` | 30 min |
| Add missing constants to `LayoutConstants` (bannerPadding, textCelebration, textHero) | `LayoutConstants.swift` | 15 min |
| Replace all `Color(hex:)` in `HubCharacterCard.swift` with theme tokens | `HubCharacterCard.swift` | 1 hour |
| Replace all `Color(hex:)` in `ArenaDetailView.swift` | `ArenaDetailView.swift` | 30 min |
| Replace `Color(hex:)` in `LoadingOverlay.swift` | `LoadingOverlay.swift` | 15 min |
| Replace `Color(hex:)` in `CombatDetailView.swift` | `CombatDetailView.swift` | 30 min |
| Replace `Color(hex:)` in `ItemCardView.swift` | `ItemCardView.swift` | 20 min |
| Replace `Color(hex:)` in `DailyLoginDetailView.swift` | `DailyLoginDetailView.swift` | 20 min |
| Replace `Color(hex:)` in `LevelUpModalView.swift` | `LevelUpModalView.swift` | 15 min |
| Deprecate blood-red HP gradient variants in DarkFantasyTheme | `DarkFantasyTheme.swift` | 15 min |
| Deprecate misleading aliases (hpGreen, xpBlue) | `DarkFantasyTheme.swift` | 10 min |

### Phase 2: Component Standardization (2-3 days)

**Goal:** All screens use canonical components.

| Task | Files | Effort |
|------|-------|--------|
| Refactor OnboardingDetailView — extract step components, use theme/layout constants | `OnboardingDetailView.swift` | 4-6 hours |
| Replace `AppearanceButtonStyle` with `PrimaryButtonStyle` | `OnboardingDetailView.swift` | 30 min |
| Standardize LoginView button pattern (remove `.primary(enabled:)`) | `LoginView.swift` | 30 min |
| Refactor Arena tabs to use `TabSwitcher` | `ArenaDetailView.swift` | 1 hour |
| Replace emoji icons with custom assets on Hub banners | `BattlePassCard`, `FirstWinBonusCard` | 1 hour (including asset creation) |
| Add `LoadingOverlay` to combat initiation flow | `ArenaDetailView.swift`, `HubView.swift` | 1 hour |
| Wire real BattlePass data into `BattlePassCard` | `BattlePassCard`, `BattlePassService` | 2 hours |
| Extract CombatDetailView speed buttons into `CombatSpeedButtonStyle` | `CombatDetailView.swift`, `ButtonStyles.swift` | 1 hour |
| Unify currency display — choose canonical component | `CurrencyDisplay.swift`, `HubCharacterCard.swift`, `TopCurrencyBar` | 2 hours |

### Phase 3: UX Improvements (3-5 days)

**Goal:** Close all heuristic review gaps.

| Task | Priority | Effort |
|------|----------|--------|
| Add confirmation dialog for stamina-cost PvP actions | High | 2 hours |
| Replace 3-letter status codes with full words + icons in combat | Medium | 3 hours |
| Add "Forfeit" option to combat screen | Medium | 2 hours |
| Add empty state CTAs (inventory empty → Arena, no opponents → refresh) | Medium | 3 hours |
| Add item comparison indicators on inventory grid cards | Medium | 4 hours |
| Hide "Prestige: 0" when prestige is zero | Low | 15 min |
| Add tooltip/info for stat abbreviations on first view | Low | 2 hours |
| Improve error toasts with actionable messages | Low | 2 hours |

### Phase 4: Documentation & Enforcement (1-2 days)

**Goal:** Prevent regression.

| Task | Effort |
|------|--------|
| Create SwiftUI Preview catalog (already partially exists in `ScreenCatalogView`) | 4 hours |
| Add SwiftLint rules to flag `Color(hex:)` in View files | 2 hours |
| Document exempt screens (Hub, Combat, Onboarding) with reasons in ScreenLayout | 1 hour |
| Create Figma component library matching Swift implementations | Ongoing |
| Add PR review checklist for UI consistency | 1 hour |

### Migration Timeline

```
Week 1: Phase 1 (Token Consolidation) + Phase 2 start
Week 2: Phase 2 (Component Standardization) complete
Week 3: Phase 3 (UX Improvements)
Week 4: Phase 4 (Documentation) + QA pass
```

**Total estimated effort: 8-12 developer-days**

---

## APPENDIX: DESIGN SYSTEM FILE MAP

```
Hexbound/
├── Theme/
│   ├── DarkFantasyTheme.swift    ← 262 lines, 60+ color tokens, fonts, gradients, helpers
│   ├── ButtonStyles.swift        ← 146 lines, 5 button styles + extensions
│   ├── CardStyles.swift          ← 171 lines, 4 card modifiers + dividers + screen bg
│   └── LayoutConstants.swift     ← 78 lines, all spacing/sizing/grid constants
├── Views/
│   └── Components/
│       ├── ScreenLayout.swift    ← Screen wrapper + HubLogoButton
│       ├── TabSwitcher.swift     ← Reusable tab component
│       ├── LoadingOverlay.swift  ← Loading spinner overlay
│       ├── ToastOverlayView.swift← Toast notification system
│       ├── StaminaBarView.swift  ← Stamina display component
│       ├── CurrencyDisplay.swift ← Currency display component
│       ├── LevelUpModalView.swift← Level up celebration modal
│       ├── AvatarImageView.swift ← Character avatar component
│       ├── ItemImageView.swift   ← Item icon component
│       ├── ActiveQuestBanner.swift← Quest progress indicator
│       └── SkeletonViews.swift   ← Loading placeholder views
└── App/
    └── AppRouter.swift           ← Navigation routing (NavigationStack-based)
```

---

> **Document Status:** COMPLETE
> **Next Review:** After Phase 2 migration completion
> **Owner:** Lead Designer / UX Director
> **Enforcement:** All PRs touching UI must pass consistency checklist
