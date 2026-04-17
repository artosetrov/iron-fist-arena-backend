# Hexbound — Design System Master Audit

> **Date:** 2026-04-01
> **Scope:** CODE ↔ TOKENS ↔ COMPONENTS ↔ FIGMA DS ↔ FIGMA SCREENS ↔ SHIPPED APP
> **Method:** Automated forensic analysis — 7 parallel agents, full codebase scan
>
> **Status boundary:** this is a historical forensic audit snapshot, not the live source of truth. Use `wiki/`, `DESIGN_SYSTEM.md`, `SCREEN_INVENTORY.md`, and current code/Figma exports for current-state decisions.

---

## Table of Contents

- [A. Audit Methodology](#a-audit-methodology)
- [B. Required Inputs](#b-required-inputs)
- [C. System Map](#c-system-map)
- [D. Findings](#d-findings)
- [E. Gap Matrix](#e-gap-matrix)
- [F. Canonical Design System Structure](#f-canonical-design-system-structure)
- [G. Governance Policy](#g-governance-policy)
- [H. Implementation Roadmap](#h-implementation-roadmap)
- [I. Acceptance Criteria](#i-acceptance-criteria)

---

## A. Audit Methodology

### How We Inspected

7 parallel agents performed forensic grep/read/glob analysis across the entire codebase:

| Agent | Scope | Method |
|-------|-------|--------|
| Token Auditor | DarkFantasyTheme.swift, LayoutConstants.swift, ButtonStyles.swift, CardStyles.swift, OrnamentalStyles.swift | Full file read, property enumeration |
| Component Auditor | 44 files in Views/Components/ | Struct analysis, prop model, token dependency mapping |
| Screen Auditor | 93 screen files across 18 directories | Anti-pattern grep (`.font(.system`, `Color(hex:`, hardcoded padding/radius) |
| Asset Auditor | Assets.xcassets (362 imagesets), Audio/ (138 SFX + 6 BGM), SF Symbols | Cross-reference with code Image() usage |
| Hardcode Scanner | All 235 .swift files | Regex for Color(), .font(.system), .padding(literal), .cornerRadius(literal), .shadow(inline), .opacity(literal) |
| Figma DS Auditor | DESIGN_SYSTEM.md, SCREEN_INVENTORY.md, UX_AUDIT.md, memory | Documentation comparison with code state |
| Motion Auditor | MotionConstants.swift, HapticManager.swift, all .animation()/.withAnimation() | Tokenization rate analysis, delay choreography audit |

### What We Compared

- Code tokens vs Figma DS variables (162 Figma vars vs 199+ code tokens)
- Code components vs Figma component sets (44 code vs 24 Figma)
- Code screens vs documented screens (93 code vs 38 Figma)
- Tokenized values vs hardcoded values (per category)
- Motion token adoption vs inline animations

### Evidence Classification

| Severity | Definition |
|----------|------------|
| **CRITICAL** | System-level failure. Value exists outside token governance. Breaks consistency at scale. |
| **HIGH** | Significant drift. Repeated pattern without tokenization. Requires refactoring. |
| **MEDIUM** | Localized issue. One-off hardcode or missing state. Fix in normal workflow. |
| **LOW** | Polish item. Edge case, naming inconsistency, or documentation gap. |

---

## B. Required Inputs

### Artifacts Used

| Artifact | Location | Status |
|----------|----------|--------|
| DarkFantasyTheme.swift | `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift` | ✅ Read (199+ color tokens) |
| LayoutConstants.swift | `Hexbound/Hexbound/Theme/LayoutConstants.swift` | ✅ Read (120+ sizing/spacing tokens) |
| ButtonStyles.swift | `Hexbound/Hexbound/Theme/ButtonStyles.swift` | ✅ Read (8 button styles) |
| CardStyles.swift | `Hexbound/Hexbound/Theme/CardStyles.swift` | ✅ Read (5 card styles) |
| OrnamentalStyles.swift | `Hexbound/Hexbound/Theme/OrnamentalStyles.swift` | ✅ Read (12 ornamental overlays) |
| MotionConstants.swift | `Hexbound/Hexbound/Theme/MotionConstants.swift` | ✅ Read (30+ motion tokens) |
| HapticManager.swift | `Hexbound/Hexbound/Theme/HapticManager.swift` | ✅ Read (12 haptic patterns) |
| Views/Components/ (44 files) | `Hexbound/Hexbound/Views/Components/` | ✅ Read all |
| Views/ (93 screen files) | `Hexbound/Hexbound/Views/` | ✅ Grep-scanned all |
| Assets.xcassets | `Hexbound/Hexbound/Resources/Assets.xcassets/` | ✅ Inventoried (362 imagesets) |
| Audio/SFX + BGM | `Hexbound/Hexbound/Resources/Audio/` | ✅ Inventoried (138 SFX + 6 BGM) |
| Figma DS file | [Hexbound-DS](https://www.figma.com/design/uDjXIz7CdJxcEOI5jCBcjY/Hexbound-DS) | ✅ Documentation read (162 vars, 24 components, 105 variants) |
| DESIGN_SYSTEM.md | `docs/07_ui_ux/DESIGN_SYSTEM.md` | ✅ Read |
| SCREEN_INVENTORY.md | `docs/07_ui_ux/SCREEN_INVENTORY.md` | ✅ Read |
| UX_AUDIT.md | `docs/07_ui_ux/UX_AUDIT.md` | ✅ Read |
| figma-assets/ | `/figma-assets/` (335 source PNGs) | ✅ Compared with xcassets |

### Artifacts Still Needed for Full Figma Parity

| Artifact | Purpose | How to Obtain |
|----------|---------|---------------|
| Figma DS live variable export | Verify 162 vars match code hex values | `figma-use` → `get_variable_defs` on fileKey `uDjXIz7CdJxcEOI5jCBcjY` |
| Figma screen file screenshots | Visual comparison with shipped app | `get_screenshot` per screen node |
| App screenshots (all 93 screens) | Ground truth for shipped UI | iOS Simulator capture or TestFlight |
| Figma component instance audit | Detect local overrides in screens | `audit-design-system` skill per screen |

---

## C. System Map

### C.1 Token Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PRIMITIVES (91)                        │
│  Raw hex colors: 0x08080C, 0x0D0D12, 0xD4A537...       │
│  Figma: Primitives collection, hidden scope []           │
└──────────────────────┬──────────────────────────────────┘
                       │ aliases
┌──────────────────────▼──────────────────────────────────┐
│              SEMANTIC TOKENS (57 + gradients)             │
│  bgPrimary, gold, textPrimary, danger, borderSubtle...  │
│  16 gradient tokens (hpFull, goldGradient, etc.)        │
│  Figma: Color collection, Dark mode                      │
└──────────────────────┬──────────────────────────────────┘
                       │ consumed by
┌──────────────────────▼──────────────────────────────────┐
│              COMPONENT TOKENS (per-component)            │
│  pill*, arena*, widget*, hero*, npc*, btn*              │
│  Code: DarkFantasyTheme.swift + LayoutConstants.swift   │
│  Figma: NOT in variable collections (gap)               │
└──────────────────────┬──────────────────────────────────┘
                       │ applied in
┌──────────────────────▼──────────────────────────────────┐
│              SCREEN COMPOSITIONS (93 screens)            │
│  Auth (11) │ Hub (6) │ Arena (7) │ Shop (7)            │
│  Dungeon (12) │ Combat (4) │ Minigames (10) │ ...      │
└─────────────────────────────────────────────────────────┘
```

### C.2 Token Inventory Summary

| Category | Code Count | Figma Count | Synced? |
|----------|-----------|-------------|---------|
| Color (semantic) | 199+ | 57 | ⚠️ Partial — code has 142+ tokens NOT in Figma |
| Spacing | 8 scale + 60 component | 8 scale | ⚠️ Component spacing not in Figma |
| Radius | 6 scale + 8 component | 6 scale | ⚠️ Component radii not in Figma |
| Typography | 9 font tokens | 9 text styles | ✅ Synced |
| Shadows | 4 effect styles | 4 effect styles | ✅ Synced |
| Gradients | 16 | 0 | ❌ Not in Figma variables |
| Opacity | ~15 discrete values | 0 | ❌ Not tokenized |
| Motion | 30+ tokens | 0 | ❌ Not in Figma (expected) |
| Icon sizes | 0 formal tokens | 0 | ❌ No icon size scale exists |

### C.3 Component Architecture

| Layer | Code | Figma DS | Gap |
|-------|------|----------|-----|
| **Theme primitives** | DarkFantasyTheme (199+ tokens) | 162 variables | Code has 37+ more tokens |
| **Ornamental system** | OrnamentalStyles (12 overlays) | Not componentized | ❌ Missing from Figma |
| **Button styles** | ButtonStyles (8 styles, 20+ variants) | Button component (18 variants) | ⚠️ Code has 2+ more styles |
| **Card styles** | CardStyles (5 modifiers) | Card component (9 variants) | ✅ Roughly aligned |
| **Progress bars** | HPBarView, XPBarView, StaminaBarView | Progress Bar (15 variants) | ✅ Aligned |
| **Widget Pill** | WidgetPill (10 styles) | Widget Pill (10 variants) | ✅ Aligned |
| **Toast** | ToastOverlayView (7 types) | Toast (7 variants) | ✅ Aligned |
| **Celebration** | CelebrationBannerView (5 types) | Celebration Banner (5 variants) | ✅ Aligned |
| **Item Card** | ItemCardView (5 rarities) | Item Card (5 variants) | ✅ Aligned |
| **State Views** | EmptyStateView + ErrorStateView | State View (4 variants) | ✅ Aligned |
| **Currency** | CurrencyDisplay (3 sizes) | Currency Display (3 variants) | ✅ Aligned |
| **Avatar** | AvatarImageView (3 sizes) | Avatar (3 variants) | ✅ Aligned |
| **Skeleton** | SkeletonViews (12 variants) | Skeleton (3 variants) | ⚠️ Code has 9 more variants |
| **PvP Stats** | PvPStatsWidget (2 layouts) | PvP Stats Widget (2 variants) | ✅ Aligned |
| **NPC Guide** | NPCGuideWidget (2 modes) | NPC Guide Widget (2 variants) | ✅ Aligned |
| **Tab Switcher** | TabSwitcher | Tab Switcher (2 variants) | ✅ Aligned |
| **Hero Widget** | UnifiedHeroWidget (4 contexts) | Hero Widget (1 variant) | ⚠️ Code has 3 more contexts |
| **Hero Card** | HeroIntegratedCard | Not in Figma | ❌ Missing |
| **Active Quest** | ActiveQuestBanner | Not in Figma | ❌ Missing |
| **Battle Result** | BattleResultCardView | Not in Figma | ❌ Missing |
| **Guest Gate** | GuestGateView | Not in Figma | ❌ Missing |
| **Guest Nudge** | GuestNudgeBanner | Not in Figma | ❌ Missing |
| **Offline Banner** | OfflineBannerView | Not in Figma | ❌ Missing |
| **Session Expired** | SessionExpiredModalView | Not in Figma | ❌ Missing |
| **Opponent Card** | ArenaOpponentCard | Not in Figma as DS component | ❌ Missing |
| **Leaderboard Row** | LeaderboardRowView | Not in Figma as DS component | ❌ Missing |
| **Inbox Row** | InboxRowView | Not in Figma as DS component | ❌ Missing |
| **Achievement Card** | AchievementCardView | Not in Figma as DS component | ❌ Missing |
| **BP Reward Node** | BPRewardNodeView | Not in Figma as DS component | ❌ Missing |
| **Dungeon Boss Card** | DungeonBossCard | Not in Figma as DS component | ❌ Missing |
| **Tutorial Step** | TutorialStepCard | Not in Figma as DS component | ❌ Missing |

### C.4 Screen Inventory

| Category | Screens | Files | Components | Figma Screens |
|----------|---------|-------|------------|---------------|
| Auth | 11 | 11 | LoginView, RegisterDetailView, WelcomeView, OnboardingDetailView, LoreIntroView, EmailConfirmationView, CharacterSelectionView, UpgradeGuestView, AppearanceStepView, ClassSelectionStepView, NameStepView | 6 |
| Hub | 6 | 6 | HubView, HubEditorDetailView, CityMapView, StanceSelectorDetailView + 2 VMs | 8 |
| Arena | 7 | 7 | ArenaDetailView, ArenaComparisonSheet, RankUpCeremonyView, ArenaOpponentCard, ArenaCarouselView, OpponentCardView + VM | 5 |
| Shop | 7 | 7 | ShopDetailView, CurrencyPurchaseView, PremiumPurchaseView, ShopOfferBannerView, MerchantStripView + VM + Tips | 4 |
| Dungeon | 12 | 12 | DungeonSelectDetailView, DungeonMapView, DungeonRoomDetailView, DungeonVictoryView, DungeonDefeatView, DungeonMapEditorView, DungeonBossCard, BossDetailSheet, DungeonInfoSheet, LootPreviewSheet + 2 VMs | 5 |
| Combat | 4 | 4 | CombatDetailView, CombatResultDetailView, LootDetailView + VM | 4 |
| Inventory | 4 | 4 | ItemDetailSheet, ItemCardView + 2 VMs | 2 |
| Profile | 4 | 4 | CharacterProfileView, AppearanceEditorDetailView, HeroDetailView + VM | 3 |
| Quests | 2 | 2 | DailyQuestsDetailView + VM | 1 |
| Battle Pass | 4 | 4 | BattlePassDetailView, BPRewardNodeView, SeasonSummaryModalView + VM | 1 |
| Social | 2 | 2 | GuildHallDetailView + VM | 0 ❌ |
| Leaderboard | 4 | 4 | LeaderboardDetailView, LeaderboardPlayerDetailSheet, LeaderboardRowView + VM | 1 |
| Minigames | 10 | 10 | GoldMine, DungeonRush, ShellGame, Tavern, FortuneWheel + overlays + VMs | 4 |
| Daily Login | 3 | 3 | DailyLoginDetailView, DailyLoginPopupView + VM | 2 |
| Inbox | 3 | 3 | InboxDetailView, InboxRowView + VM | 1 |
| Settings | 2 | 2 | SettingsDetailView + VM | 1 |
| Achievements | 3 | 3 | AchievementsDetailView, AchievementCardView + VM | 2 |
| Tutorial | 3 | 3 | TutorialView, TutorialStepCard, NPCSpeechBubble | 0 ❌ |
| Dev | 3 | 3 | DesignSystemPreview, ScreenCatalogView, MockData | 0 (expected) |
| Session | 1 | 1 | SessionSummaryView | 0 ❌ |
| **TOTAL** | **93** | **93** | — | **~50** |

### C.5 Asset Inventory

| Category | Count | Naming Convention | DS Presence |
|----------|-------|-------------------|-------------|
| Bosses | 40 | `boss-*` (hyphens) | Figma placeholder page |
| Dungeon Rush enemies | 56 | `rush-*` (hyphens) | Figma placeholder page |
| Equipment items | 71 | `wpn_*`, `helm_*`, etc. (underscores) | Figma placeholder page |
| Icons | 48 | `icon-*` (hyphens) | Figma placeholder page |
| Backgrounds | 37 | `bg-*` (hyphens) | Figma placeholder page |
| Buildings | 16 | `building-*` (hyphens) | Figma placeholder page |
| VFX | 30 | `fx-*` (hyphens) | Figma placeholder page |
| Characters/Avatars | 8 | `avatar_*` (underscores) | Figma placeholder page |
| Rewards/Results | 11 | `reward-*`, `result-*` (hyphens) | Figma placeholder page |
| Minigame assets | 13 | mixed | Figma placeholder page |
| Races | 5 | `race-icon-*` (hyphens) | Figma placeholder page |
| Shop packages | 5 | `shop-*` (hyphens) | Figma placeholder page |
| UI controls | 9 | `hud-*`, `ui-*` (hyphens) | Figma placeholder page |
| SF Symbols | 60+ | System | N/A |
| SFX audio | 138 | `snake_case.wav` | N/A |
| BGM audio | 6 | `kebab-case.mp3` | N/A |
| Custom fonts | 3 | Cinzel-Bold, Oswald-Regular, Inter-Regular | Figma text styles |
| **TOTAL** | **362 images + 144 audio + 3 fonts** | — | — |

---

## D. Findings

### D.1 CRITICAL Findings

#### D.1.1 Typography: 0% Tokenized in Screens (277 violations)

**Impact:** Every screen uses `.font(.system(size: X))` instead of DarkFantasyTheme font tokens. Any typography scale change requires editing 277 locations across 40+ files.

**Evidence (top offenders):**

| File | Violations | Sizes Used |
|------|-----------|------------|
| GuildHallDetailView.swift | 32 | 8, 9, 10, 11, 12, 14, 16, 20, 24, 32, 40 |
| HubView.swift | 17 | 11, 12, 14, 18, 20, 24, 30 |
| InboxRowView.swift | 12 | 10, 11, 12, 14, 16, 18 |
| DungeonSelectDetailView.swift | 9 | 10, 11, 12, 14, 16, 24 |
| ItemDetailSheet.swift | 8 | 10, 11, 12, 14, 16 |
| CombatDetailView.swift | 6 | 12, 14, 72 |
| HubEditorDetailView.swift | 7 | 8, 9, 10, 12, 14, 24 |
| CharacterSelectionView.swift | 8+ | 12, 14, 16, 18, 64 |

**Hardcoded font sizes found:** 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24, 28, 30, 32, 36, 40, 44, 48, 64, 72

**Note:** DarkFantasyTheme defines `title(size:)`, `section(size:)`, `body(size:)` helper functions — but screens bypass them entirely with `.font(.system(size:))`.

**CLAUDE.md rules violated:**
- "NEVER use font(size:) functions" (these create Swift compilation name collisions)
- "Always use the static token properties"
- Minimum font size 11px (violations at 8pt, 9pt found)

#### D.1.2 Corner Radius: 20% Tokenized (450 violations)

**Impact:** 450+ `RoundedRectangle(cornerRadius: X)` calls with raw numbers instead of `LayoutConstants.radiusXS/SM/MD/LG/XL/2XL`. Radius scale cannot be updated from a single source.

**Evidence:** Radius scale exists (radiusXS=3, radiusSM=6, radiusMD=8, radiusLG=12, radiusXL=16, radius2XL=22) but ~80% of usages hardcode the number directly.

#### D.1.3 Shadow: 20% Tokenized (250 violations)

**Impact:** 250+ `.shadow()` calls with inline `radius:`, `x:`, `y:` values. Shadow patterns are duplicated across 76 files with no reusable presets.

**Dual shadow pattern (glow + depth) appears 15+ times:**
```swift
.shadow(color: DarkFantasyTheme.gold.opacity(0.15), radius: 8, y: 2)
.shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 1)
```

**No shadow presets exist** despite clear tiers: small (r:2-4), medium (r:6-8), large (r:10-20), elevation (r:32+).

#### D.1.4 Animation: 85-93% Hardcoded (325 violations)

**Impact:** MotionConstants defines 30+ tokens but adoption is critically low.

| API | Total Calls | Using MotionConstants | Hardcoded | Adoption |
|-----|------------|----------------------|-----------|----------|
| `.animation()` | 71 | 5 | 66 | **7%** |
| `.withAnimation()` | 254 | 38 | 216 | **15%** |
| `DispatchQueue.main.asyncAfter` | 96 | ~10 | ~86 | **10%** |

#### D.1.5 Code-Only Components Not in Figma DS (13 components)

These reusable components exist in code but have NO Figma DS counterpart:

1. **HeroIntegratedCard** — equipment-first character display
2. **ActiveQuestBanner** — quest progress with action
3. **BattleResultCardView** — victory/defeat with rewards
4. **GuestGateView** — auth blocking overlay
5. **GuestNudgeBanner** — sign-in nudge
6. **OfflineBannerView** — network status
7. **SessionExpiredModalView** — 401 auth modal
8. **ArenaOpponentCard** — opponent card in carousel
9. **LeaderboardRowView** — leaderboard entry
10. **InboxRowView** — mail message row
11. **AchievementCardView** — achievement entry
12. **BPRewardNodeView** — battle pass node
13. **DungeonBossCard** — dungeon boss entry

### D.2 HIGH Findings

#### D.2.1 Figma Token Gap: 142+ Code Tokens Missing from Figma

Code has 199+ semantic color tokens. Figma has 57. Missing categories:

| Missing Token Group | Count | Examples |
|---------------------|-------|---------|
| Pill colors (bg/border/text × 10 styles) | 30 | `pillHealBg`, `pillUrgentBorder`, `pillStatText` |
| Button chrome colors | 15 | `btnOrangePrimary`, `btnDangerFill`, `btnPurpleDark` |
| Arena-specific colors | 8 | `bgArenaCard`, `arenaShimmerColor`, `arenaCardInnerGlow` |
| Dungeon colors | 12 | `bgDungeonDeep`, `bossBorderPurple`, `lootGold` |
| City map colors | 15 | `skyNight`, `moonGlowOuter1`, `fogLight`, `glowFire` |
| VFX colors | 3 | `vfxPoisonGlow`, `vfxBurnGlow`, `vfxStunGlow` |
| Hub character card | 8 | `xpRing`, `bgCardGradientStart`, `textDimLabel` |
| Premium colors | 4 | `premiumPink`, `bgPremium`, `bgPremiumDeep` |
| Daily login | 4 | `dailyGradientTopGold`, `dailyGradientBottomGold` |
| Toast indicator | 7 | `toastLevelUp`, `toastRankUp`, `toastQuest` |
| Difficulty colors | 3 | `difficultyEasy`, `difficultyMedium`, `difficultyHard` |
| Durability colors | 3 | `durabilityGood`, `durabilityMedium`, `durabilityLow` |
| Building glow | 10 | `glowArena`, `glowMystic`, `glowForge` |
| Misc | 20+ | `upgradeBlue`, `healFlash`, `arenaRankGold` |

#### D.2.2 No Icon Size Scale

No formal icon sizing tokens exist. Code uses ad-hoc sizes: 12, 14, 16, 18, 20, 24, 28, 32, 36, 40, 44, 48, 56px — all hardcoded per-instance.

**Recommended scale:** iconXS=12, iconSM=16, iconMD=20, iconLG=24, iconXL=32, icon2XL=48

#### D.2.3 No Opacity Scale

156+ hardcoded `.opacity()` values. Common values: 0.04, 0.06, 0.08, 0.10, 0.12, 0.15, 0.20, 0.25, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90. No tokenized opacity scale exists.

#### D.2.4 Deprecated/Legacy Tokens Still in Theme (18 tokens)

| Token | Status | Replacement |
|-------|--------|-------------|
| `bgDark` | alias → bgPrimary | Legacy |
| `bgCard` | alias → bgSecondary | Legacy |
| `goldLight` | alias → goldBright | Legacy |
| `hpRed` | alias → danger | Legacy |
| `hpGreen` | DEPRECATED (was blood-red, confusing name) | Use `hpBlood` |
| `xpBlue` | alias → purple | DEPRECATED |
| `gems` | alias → cyan | Legacy |
| `textMuted` | alias → textTertiary | Legacy |
| `borderDefault` | alias → borderSubtle | Legacy |
| `statSTR` through `statCHA` | 8 tokens DEPRECATED | Use unified gold palette |
| `merchantAvatarSize` | alias → npcAvatarSize | Legacy |
| `merchantMiniSize` | alias → npcMiniSize | Legacy |
| `merchantBarHeight` | alias → npcBarHeight | Legacy |
| `merchantBubbleRadius` | alias → npcBarRadius | Legacy |

#### D.2.5 Figma Screens Gap: 43+ Screens Missing

Code has 93 screens. Figma documents ~50. Missing:

| Missing Screen | Priority |
|---------------|----------|
| GuildHallDetailView | HIGH — 1845-line social system |
| TutorialView + TutorialStepCard | HIGH — onboarding critical |
| SessionSummaryView | HIGH — session end flow |
| FortuneWheelDetailView | MEDIUM — minigame |
| TavernDetailView | MEDIUM — minigame hub |
| DungeonMapEditorView | LOW — dev tool |
| HubEditorDetailView | LOW — dev tool |
| ScreenCatalogView | LOW — dev tool |
| DesignSystemPreview | LOW — dev tool |
| Multiple sheets (BossDetail, DungeonInfo, LootPreview, LeaderboardPlayerDetail) | MEDIUM |

#### D.2.6 Missing Assets (3 files)

| Asset Name | Referenced In | Issue |
|-----------|---------------|-------|
| `bg-rush-miniboss` | DungeonRushDetailView.swift | Image() will silently fail |
| `bg-rush-shop` | DungeonRushDetailView.swift | Image() will silently fail |
| `rush-ui-escape` | DungeonRushDetailView.swift | Image() will silently fail |

#### D.2.7 Asset Naming Conflict

| Code Reference | Actual Asset Name | File |
|---------------|-------------------|------|
| `"icon-gem"` | `"icon-gems"` (plural) | HeroDetailView.swift:813, 845 |

### D.3 MEDIUM Findings

#### D.3.1 Hardcoded Padding (12 violations)

| File | Line | Value | Should Be |
|------|------|-------|-----------|
| HubEditorDetailView.swift | 415 | `.padding(-4)` | Proper offset/spacing |
| HubEditorDetailView.swift | 502 | `.padding(-4)` | Proper offset/spacing |
| CityBuildingLabel.swift | 26 | `.padding(.vertical, 1)` | `space2XS` (2) |
| OpponentCardView.swift | 114 | `.padding(.horizontal, 8)` | `spaceSM` |
| OpponentCardView.swift | 115 | `.padding(.vertical, 2)` | `space2XS` |
| CelebrationBannerView.swift | 19 | `.padding(.top, 94)` | SafeAreaInsets |
| InboxDetailView.swift | 258 | `.padding(.horizontal, 7)` | `spaceSM` (8) |
| ItemCardView.swift | 382 | `.padding(20)` | `spaceMD` (16) |
| FortuneWheelDetailView.swift | 383 | `.padding(.top, 14)` | `spaceMS` (12) |
| FortuneWheelDetailView.swift | 384 | `.padding(.bottom, 22)` | `spaceLG` (24) |
| DungeonMapEditorView.swift | 72 | `.padding(.vertical, 10)` | `spaceSM` (8) or `spaceMS` (12) |
| HubEditorDetailView.swift | 98 | `.padding(.bottom, 140)` | Computed safe area |

#### D.3.2 Raw Color Usage (6 violations)

| File | Line | Value | Should Be |
|------|------|-------|-----------|
| HubView.swift | 1519 | `.white.opacity(0.08)` | Theme ornamental token |
| HubView.swift | 1521 | `.black.opacity(0.12)` | Theme ornamental token |
| HubEditorDetailView.swift | 383 | `.red.opacity(0.8)` | `DarkFantasyTheme.danger` |
| HubEditorDetailView.swift | 393 | `.red.opacity(0.4)` | `DarkFantasyTheme.danger.opacity(0.4)` |
| HubEditorDetailView.swift | 393 | `.orange.opacity(0.3)` | `DarkFantasyTheme.stamina.opacity(0.3)` |
| CurrencyPurchaseView.swift | 498 | Conditional `.clear` glow | Acceptable |

#### D.3.3 Missing Component States

| Component | Missing States |
|-----------|---------------|
| UnifiedHeroWidget | disabled, offline |
| HPBarView | disabled, debuff strikethrough |
| XPBarView | overflow, skip-to-next |
| StaminaBarView | full indication, low glow |
| CardLevelBadge | locked |
| TabSwitcher | >4 tabs scrolling, badge counts, disabled tabs |
| CurrencyDisplay | insufficient funds highlight |
| WidgetPill | size variants |
| EmptyStateView | illustration support |
| ErrorStateView | auto-retry |
| LoadingOverlay | cancel button, timeout |

#### D.3.4 Skeleton Variants Gap

Code has 12 skeleton variants. Figma DS has 3. Missing from Figma:

SkeletonQuestCard, SkeletonLeaderboardRow, SkeletonShopItemCard, SkeletonAchievementCard, SkeletonBPNode, SkeletonDungeonCard, SkeletonConversationCard, SkeletonRevengeCard

> **Note:** SkeletonMineSlot removed from this list — MineSlotCard (3 variants), LockedMineCard, and MiningOutputCard added to Figma DS on "Components / Minigames" page (2026-04-04).

#### D.3.5 Asset Naming Inconsistency

Equipment items use underscores (`wpn_sword_iron`, `helm_plate_epic`) while all other assets use hyphens (`icon-gold`, `bg-arena`, `boss-lich`). This creates a dual convention.

### D.4 LOW Findings

#### D.4.1 Gradient Tokens Not in Figma Variables

16 gradient tokens defined in code but not representable as Figma variables (Figma limitation — variables don't support gradients). Tracked via effect styles instead.

#### D.4.2 Motion Tokens Not in Figma

30+ MotionConstants exist in code. Figma has no motion token system. This is expected (Figma limitation) but should be documented in handoff specs.

#### D.4.3 matchedGeometryEffect Underutilized

Only 1 instance (TabSwitcher indicator). Missing opportunities: hero portrait expansion, loot item zoom, equipment slot transitions.

#### D.4.4 DispatchQueue Choreography Not Centralized

96 hardcoded `DispatchQueue.main.asyncAfter` delays. Ceremony sequences (LevelUp 7 phases, RankUp 5 phases, BattleResult 15+ phases) use raw delay chains instead of choreography helpers.

---

## E. Gap Matrix

### E.1 Token Gap Matrix

| Token | Type | In Code | In Figma DS | Tokenized | Issue | Action | Priority |
|-------|------|---------|-------------|-----------|-------|--------|----------|
| Font sizes (8-72pt) | typography | Hardcoded | ✅ Text styles | ❌ | 277 `.font(.system)` calls | Replace with DarkFantasyTheme tokens | CRITICAL |
| Corner radii | radius | ✅ Scale exists | ✅ | 20% | 450 raw `cornerRadius:` | Replace with LayoutConstants.radius* | CRITICAL |
| Shadow presets | effect | ❌ No presets | ✅ 4 styles | ❌ | 250 inline shadows | Create ShadowPreset enum | CRITICAL |
| Animation durations | motion | ✅ MotionConstants | N/A | 10% | 325 hardcoded | Replace with MotionConstants | CRITICAL |
| Opacity scale | opacity | ❌ | ❌ | ❌ | 156 hardcoded values | Create opacity scale | HIGH |
| Icon sizes | sizing | ❌ | ❌ | ❌ | Ad-hoc per instance | Create icon size scale | HIGH |
| Pill colors (30) | color | ✅ | ❌ | ✅ in code | Not in Figma | Add to Figma Color collection | HIGH |
| Button chrome (15) | color | ✅ | ❌ | ✅ in code | Not in Figma | Add to Figma Color collection | HIGH |
| Arena colors (8) | color | ✅ | ❌ | ✅ in code | Not in Figma | Add to Figma Color collection | MEDIUM |
| Dungeon colors (12) | color | ✅ | ❌ | ✅ in code | Not in Figma | Add to Figma Color collection | MEDIUM |
| City map colors (15) | color | ✅ | ❌ | ✅ in code | Not in Figma | Add to Figma Color collection | MEDIUM |
| Deprecated tokens (18) | color/sizing | ✅ (aliases) | ❌ | N/A | Dead weight | Remove after audit usage | LOW |

### E.2 Component Gap Matrix

| Component | In Code | In App | In Figma DS | In Figma Screens | Tokenized | Synced | Issue | Action | Priority |
|-----------|---------|--------|-------------|-----------------|-----------|--------|-------|--------|----------|
| Button (8 styles) | ✅ | ✅ | ✅ (18 variants) | ✅ | ✅ | ⚠️ | Code has .getMore, .premium not in Figma | Add to Figma | MEDIUM |
| Card (5 styles) | ✅ | ✅ | ✅ (9 variants) | ✅ | ✅ | ✅ | — | — | — |
| Progress Bar (3 types) | ✅ | ✅ | ✅ (15 variants) | ✅ | ✅ | ✅ | — | — | — |
| Widget Pill (10 styles) | ✅ | ✅ | ✅ (10 variants) | ✅ | ✅ | ✅ | — | — | — |
| Toast (7 types) | ✅ | ✅ | ✅ (7 variants) | ✅ | ✅ | ✅ | — | — | — |
| Celebration Banner (5) | ✅ | ✅ | ✅ (5 variants) | ✅ | ✅ | ✅ | — | — | — |
| Item Card (5 rarities) | ✅ | ✅ | ✅ (5 variants) | ✅ | ✅ | ✅ | — | — | — |
| State View (4) | ✅ | ✅ | ✅ (4 variants) | ✅ | ✅ | ✅ | — | — | — |
| Currency Display (3) | ✅ | ✅ | ✅ (3 variants) | ✅ | ✅ | ✅ | — | — | — |
| Avatar (3 sizes) | ✅ | ✅ | ✅ (3 variants) | ✅ | ✅ | ✅ | — | — | — |
| Skeleton (12 variants) | ✅ | ✅ | ⚠️ (3 variants) | ✅ | ✅ | ⚠️ | 9 variants missing | Add to Figma | MEDIUM |
| HeroIntegratedCard | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | HIGH |
| ActiveQuestBanner | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | HIGH |
| BattleResultCardView | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | HIGH |
| ArenaOpponentCard | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | HIGH |
| LeaderboardRowView | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | MEDIUM |
| InboxRowView | ✅ | ✅ | ❌ | ❌ | ⚠️ | ❌ | Not in Figma + font issues | Create + fix tokens | HIGH |
| AchievementCardView | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | MEDIUM |
| BPRewardNodeView | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | MEDIUM |
| DungeonBossCard | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | MEDIUM |
| GuestGateView | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | LOW |
| GuestNudgeBanner | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | LOW |
| OfflineBannerView | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | LOW |
| SessionExpiredModal | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | LOW |
| TutorialStepCard | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Not in Figma | Create DS component | LOW |
| NumberTickUpView | ✅ | ✅ | ❌ | N/A | ✅ | N/A | Animation component | Document behavior | LOW |
| OrnamentalTitle (2) | ✅ | ✅ | ✅ (2 variants) | ✅ | ✅ | ✅ | — | — | — |

### E.3 Screen Gap Matrix

| Screen | In Code | In Figma | Components Used | Hardcoded Values | Priority |
|--------|---------|----------|----------------|-----------------|----------|
| GuildHallDetailView | ✅ | ❌ | 5+ | 32 font violations | CRITICAL |
| HubView | ✅ | ✅ | 12+ | 17 font + 40 opacity | HIGH |
| InboxRowView | ✅ | ❌ | 3+ | 12 font violations | HIGH |
| DungeonSelectDetailView | ✅ | ✅ | 8+ | 9 font violations | HIGH |
| CombatDetailView | ✅ | ✅ | 6+ | 6 font violations | HIGH |
| ItemDetailSheet | ✅ | ✅ | 4+ | 8 font violations | HIGH |
| TutorialView | ✅ | ❌ | 3+ | Multiple hardcodes | HIGH |
| SessionSummaryView | ✅ | ❌ | Unknown | Unknown | MEDIUM |
| FortuneWheelDetailView | ✅ | ❌ | 4+ | Padding violations | MEDIUM |
| TavernDetailView | ✅ | ❌ | Unknown | Unknown | MEDIUM |

---

## F. Canonical Design System Structure

### F.1 Token Hierarchy (Canonical)

```
Layer 0: PRIMITIVES (raw values)
├── Colors: hex values (0x08080C, 0xD4A537, etc.)
├── Numbers: spacing (2, 4, 8, 12, 16, 24, 32, 48)
├── Numbers: radii (3, 6, 8, 12, 16, 22)
├── Numbers: font sizes (11, 12, 14, 16, 18, 22, 28, 40)
└── Numbers: durations (0.12, 0.25, 0.4, 0.6, 1.2)

Layer 1: SEMANTIC TOKENS (meaning)
├── Colors: bgPrimary, gold, textPrimary, danger, borderSubtle
├── Spacing: space2XS, spaceXS, spaceSM, spaceMS, spaceMD, spaceLG, spaceXL, space2XL
├── Radii: radiusXS, radiusSM, radiusMD, radiusLG, radiusXL, radius2XL
├── Typography: title, section, cardTitle, buttonLabel, body, uiLabel, caption, badge
├── Motion: instant, fast, normal, reward, epic
├── Opacity: opacityMicro(0.04), opacitySoft(0.08), opacityLight(0.12), opacityMedium(0.25), opacityStrong(0.5), opacityHeavy(0.75)
├── Icons: iconXS(12), iconSM(16), iconMD(20), iconLG(24), iconXL(32), icon2XL(48)
└── Shadows: shadowSM, shadowMD, shadowLG, shadowElevation, shadowGlow(color)

Layer 2: COMPONENT TOKENS (scoped to component)
├── Pill: pillHeight, pillRadius, pillPaddingH, pillIconSize, pillGap
├── Widget: widgetPadding, widgetGap, widgetBarHeight, widgetAvatarSize
├── Arena: arenaCardRadius, arenaCardPadding, arenaAvatarSize
├── Hero: heroSlotSize, heroBarHeight, heroPortraitNameFont
├── NPC: npcAvatarSize, npcBarHeight, npcBarRadius
└── ... (per component)

Layer 3: SCREEN TOKENS (exceptions for specific screens)
├── Should be ZERO — screens compose from components only
└── If exception needed → formalize as component token first
```

### F.2 Naming Model

```
{category}{Semantic}{Modifier}

Categories: bg, text, border, gold, danger, success, info, rarity, class, rank, pill, btn, stat, zone, glow, vfx, toast
Semantics: Primary, Secondary, Tertiary, Subtle, Medium, Strong, Bright, Dim, Disabled
Modifiers: Glow, Gradient, Light, Dark, Deep

Examples:
  bgPrimary, textSecondary, borderSubtle, goldBright, dangerGlow
  pillHealBg, pillHealBorder, pillHealText
  btnOrangePrimary, btnDangerFill
```

### F.3 Component Classification (Canonical)

| Level | Components |
|-------|-----------|
| **Primitives** | DarkFantasyTheme (tokens), LayoutConstants (sizing), MotionConstants (timing), HapticManager (feedback) |
| **Atoms** | AvatarImageView, CardLevelBadge, CurrencyDisplay, NumberTickUpView, SkeletonRect, OrnamentalTitle |
| **Molecules** | HPBarView, XPBarView, StaminaBarView, WidgetPill, TabSwitcher, ItemCardView, EventBannerView |
| **Organisms** | UnifiedHeroWidget, HeroIntegratedCard, PvPStatsWidget, ArenaOpponentCard, NPCGuideWidget, StanceDisplayView |
| **Templates** | ScreenLayout, EmptyStateView, ErrorStateView, LoadingOverlay |
| **Overlays** | ToastOverlayView, CelebrationBannerView, LevelUpModalView, SessionExpiredModalView, GuestGateView |
| **Styles** | ButtonStyles (8), CardStyles (5), OrnamentalStyles (12) |

### F.4 State Model (Canonical)

Every interactive component MUST define:

| State | Required? | Visual Treatment |
|-------|-----------|-----------------|
| **default** | ✅ Always | Normal appearance |
| **pressed** | ✅ Interactive | `brightness(-0.06)` + haptic + SFX |
| **disabled** | ✅ Interactive | `bgDisabled` + `textDisabled` + no interaction |
| **loading** | ⚠️ Async | Skeleton or spinner replacement |
| **empty** | ⚠️ Lists | EmptyStateView |
| **error** | ⚠️ Network | ErrorStateView |
| **selected** | ⚠️ Toggles | `borderGold` + `bgElevated` |
| **focused** | ❌ iOS rare | — |
| **hover** | ❌ iOS N/A | — |

### F.5 Screen Composition Rules

1. Every screen MUST use `ScreenLayout` wrapper OR `bgPrimary.ignoresSafeArea()` background
2. Every screen MUST compose from DS components — NO inline styling
3. Every screen MUST use `DarkFantasyTheme` font tokens — NO `.font(.system)`
4. Every screen MUST use `LayoutConstants` spacing — NO literal padding/frame values
5. Every screen with async data MUST show skeleton → content → error states
6. Every screen with actions MUST use ButtonStyles — NO custom button frames
7. Every screen MUST be representable in Figma using only DS components

---

## G. Governance Policy

### G.1 Forbidden Practices

| Practice | Detection | Consequence |
|----------|-----------|-------------|
| `.font(.system(size:))` in Views/ | Grep scan | Block commit |
| `Color(hex:)` in Views/ | Grep scan | Block commit |
| `Color.red/green/blue/orange` in Views/ | Grep scan | Block commit |
| `.padding(literal)` not from LayoutConstants | Manual review | Fix before merge |
| `RoundedRectangle(cornerRadius: literal)` | Grep scan | Fix before merge |
| `.shadow(` with inline values (no preset) | Manual review | Fix before merge |
| `.animation(.easeInOut(duration: literal))` | Manual review | Prefer MotionConstants |
| New component without Figma counterpart | Manual review | Create Figma component before merge |
| New token without Figma variable | Manual review | Add to Figma before merge |
| Copy-paste of modifier chains | Manual review | Extract to extension |

### G.2 Required Practices

| Practice | When | How |
|----------|------|-----|
| Use DarkFantasyTheme tokens for ALL colors | Every .swift file | `DarkFantasyTheme.tokenName` |
| Use LayoutConstants for ALL spacing/sizing | Every .swift file | `LayoutConstants.spaceMD` etc. |
| Use DarkFantasyTheme font tokens | Every .swift file | `.font(DarkFantasyTheme.body)` etc. |
| Use ButtonStyles for ALL buttons | Every .swift file | `.buttonStyle(.primary)` etc. |
| Use CardStyles for ALL cards | Every .swift file | `.panelCard()` etc. |
| Use MotionConstants for animations | Every .swift file | `MotionConstants.fast` etc. |
| Verify token names before use | Before writing code | Open theme file, confirm token exists |
| Add new components to Figma | When creating reusable component | Use `figma-use` skill |
| Add new tokens to Figma | When creating new token | Add to Primitives + Color collections |
| Run CDO verification scan | After every task | Grep scan from CLAUDE.md |

### G.3 Change Management

| Change Type | Required Steps |
|-------------|---------------|
| New color token | 1. Add to DarkFantasyTheme.swift → 2. Add to Figma Primitives → 3. Alias in Figma Color collection → 4. Document in DESIGN_SYSTEM.md |
| New component | 1. Create .swift file → 2. Add to pbxproj → 3. Create Figma component → 4. Document in SCREEN_INVENTORY.md |
| New screen | 1. Build from DS components only → 2. Create Figma screen → 3. Add to SCREEN_INVENTORY.md |
| Token value change | 1. Update DarkFantasyTheme.swift → 2. Update Figma Primitive variable → 3. Verify all consumers |
| Deprecate token | 1. Add `// DEPRECATED: use X instead` comment → 2. Create alias → 3. Migrate all usages → 4. Remove in next major version |

### G.4 Review Gates

| Gate | Check | Tool |
|------|-------|------|
| Pre-commit | No hardcoded fonts, colors, SF currency icons | CDO verification scan |
| Pre-merge | All new components have Figma counterparts | Manual review |
| Weekly | Token sync between code and Figma | `audit-design-system` skill |
| Monthly | Full DS compliance scan | This audit (re-run) |

---

## H. Implementation Roadmap

### Phase 1: IMMEDIATE FIXES (1-2 days)

**Priority: CRITICAL — blocks all other work**

| # | Task | Files | Effort |
|---|------|-------|--------|
| 1.1 | Replace 277 `.font(.system(size:))` with DarkFantasyTheme tokens | 40+ files | 4-6h |
| 1.2 | Fix 6 raw Color violations (HubEditorDetailView, HubView) | 3 files | 30min |
| 1.3 | Fix 3 missing assets (bg-rush-miniboss, bg-rush-shop, rush-ui-escape) | Asset creation | 1h |
| 1.4 | Fix icon-gem → icon-gems naming conflict | HeroDetailView.swift | 5min |

### Phase 2: SHORT-TERM CLEANUP (3-5 days)

**Priority: HIGH — establishes token authority**

| # | Task | Files | Effort |
|---|------|-------|--------|
| 2.1 | Create ShadowPreset enum (small/medium/large/elevation/glow) | New file + 76 files | 3h |
| 2.2 | Replace 450 hardcoded cornerRadius with LayoutConstants.radius* | 50+ files | 4-6h |
| 2.3 | Create opacity scale tokens and replace 156 hardcoded values | DarkFantasyTheme + 40+ files | 2-3h |
| 2.4 | Create icon size scale (iconXS-icon2XL) | LayoutConstants + 30+ files | 2h |
| 2.5 | Replace 325 hardcoded animation values with MotionConstants | 60+ files | 4-6h |
| 2.6 | Fix 12 hardcoded padding violations | 8 files | 1h |
| 2.7 | Remove 18 deprecated/legacy token aliases | DarkFantasyTheme | 2h (+ migration) |

### Phase 3: MEDIUM-TERM REFACTOR (1-2 weeks)

**Priority: HIGH — component governance**

| # | Task | Files | Effort |
|---|------|-------|--------|
| 3.1 | Create 13 missing Figma DS components | Figma file | 2-3 days |
| 3.2 | Add 142+ missing code tokens to Figma variables | Figma file | 1 day |
| 3.3 | Extract 15+ duplicate modifier chains into reusable extensions | New style extensions | 1 day |
| 3.4 | Add missing component states (disabled, loading, error) | Component files | 2 days |
| 3.5 | Create choreography helpers for ceremony sequences | MotionConstants + ceremony views | 1 day |
| 3.6 | Standardize asset naming (resolve underscore vs hyphen) | xcassets + code references | 0.5 day |

### Phase 4: FULL FIGMA PARITY (2-3 weeks)

**Priority: MEDIUM — design-first workflow enablement**

| # | Task | Effort |
|---|------|--------|
| 4.1 | Create 43+ missing Figma screens | 1-2 weeks |
| 4.2 | Add 9 missing skeleton variants to Figma | 1 day |
| 4.3 | Create Figma screen templates (auth, hub, detail, modal) | 2 days |
| 4.4 | Visual comparison: Figma screens vs app screenshots (all 93 screens) | 2-3 days |
| 4.5 | Fix all visual mismatches found in comparison | Variable |

### Phase 5: GOVERNANCE ROLLOUT (1 week)

**Priority: MEDIUM — prevents future drift**

| # | Task | Effort |
|---|------|--------|
| 5.1 | Add CDO font/radius/shadow scan to pre-commit hook | 2h |
| 5.2 | Document governance policy in CLAUDE.md (root + iOS) | 1h |
| 5.3 | Create DS change management checklist | 1h |
| 5.4 | Set up weekly token sync review | 1h |
| 5.5 | Train on `audit-design-system` and `figma-use` skills for ongoing compliance | 2h |

### Phase 6: MAINTENANCE WORKFLOW (ongoing)

| Cadence | Activity |
|---------|----------|
| Every commit | CDO verification scan (automated) |
| Every PR | Manual DS compliance check (reviewer) |
| Weekly | Token sync audit (code ↔ Figma) |
| Monthly | Full audit re-run (this document) |
| Per feature | New component → Figma first → Code second |

---

## I. Acceptance Criteria

### Definition of Done

The design system is considered fully governed when ALL of the following are true:

| Criterion | Current State | Target | Gap |
|-----------|--------------|--------|-----|
| Shipped screens covered by DS components | ~70% | 100% | 30% |
| Reusable visual elements in DS | 24/37 (65%) | 37/37 (100%) | 13 components |
| Screen construction from approved components | ~70% | 100% | 277 font + 450 radius violations |
| Visual values tokenized (colors) | 95% | 100% | 6 violations |
| Visual values tokenized (typography) | 0% | 100% | 277 violations |
| Visual values tokenized (spacing) | 92% | 100% | 12 violations |
| Visual values tokenized (radii) | 20% | 100% | 450 violations |
| Visual values tokenized (shadows) | 20% | 100% | 250 violations |
| Visual values tokenized (animations) | 10% | 100% | 325 violations |
| Visual values tokenized (opacity) | 60% | 100% | 156 violations |
| Undocumented UI elements in code | 13 | 0 | 13 components |
| Figma/code token mismatches | 142+ | 0 | 142 tokens |
| Figma/code screen mismatches | 43+ | 0 | 43 screens |
| Deprecated tokens in codebase | 18 | 0 | 18 aliases |
| Missing assets | 3 | 0 | 3 images |
| Governance hooks active | 0 | 3+ | 3 hooks |

### Compliance Scorecard (Current)

| Category | Violations | Total Uses | Compliance | Target |
|----------|-----------|-----------|-----------|--------|
| Colors | 6 | 2000+ | **99.7%** | 100% |
| Typography | 277 | 277 | **0%** | 100% |
| Spacing/Padding | 12 | 1500+ | **99.2%** | 100% |
| Frame Dimensions | 150 | 1097 | **86%** | 95% |
| Corner Radius | 450 | 561 | **20%** | 100% |
| Shadows | 250 | 312 | **20%** | 100% |
| Animations | 325 | 325 | **10%** | 80% |
| Opacity | 156 | 1512 | **90%** | 100% |
| **OVERALL** | **1626** | **7584** | **~70%** | **≥95%** |

### Success Metrics

These were audit target metrics for the 2026-04-01 pass. They should not be read as guaranteed current repo state without revalidation.

1. **Zero hardcoded `.font(.system)` in Views/** — verified by grep
2. **Zero hardcoded `cornerRadius:` literals in Views/** — verified by grep
3. **Shadow presets cover 100% of `.shadow()` calls** — verified by grep
4. **MotionConstants adoption ≥80%** — verified by grep
5. **All 37 reusable components exist in Figma DS** — verified by component count
6. **All 162+ code tokens exist in Figma variables** — verified by variable export
7. **All 93 screens have Figma counterparts** — verified by screen count
8. **CDO verification scan passes on every commit** — verified by pre-commit hook
9. **Zero deprecated tokens remain in codebase** — verified by grep for "DEPRECATED"
10. **Asset naming is 100% consistent** — verified by convention check

---

## Appendix: Complete Token Inventory

### A.1 Color Tokens (199+)

<details>
<summary>Background & Surface (11)</summary>

| Token | Hex | Purpose |
|-------|-----|---------|
| bgAbyss | #08080C | Deepest black — behind modals |
| bgPrimary | #0D0D12 | Main screen background |
| bgSecondary | #1A1A2E | Panel backgrounds, cards |
| bgTertiary | #16213E | Card interiors, form fields |
| bgElevated | #1E2240 | Active cards, selected items |
| bgModal | black@75% | Modal overlay |
| bgBackdrop | black@85% | Heavy backdrop for sheets |
| bgBackdropLight | black@70% | Lighter backdrop for popups |
| bgScrim | black@50% | Semi-transparent scrim fill |
| bgDisabled | #333340 | Disabled button background |
| bgDarkPanel | #141428 | Dark panel bg, arena header |
</details>

<details>
<summary>Gold Accent System (6)</summary>

| Token | Hex | Purpose |
|-------|-----|---------|
| gold | #D4A537 | Primary CTA, gold buttons |
| goldBright | #FFD700 | Highlighted text, important values |
| goldDim | #8B6914 | Disabled gold, inactive |
| goldGlow | #F39C12@40% | Orange glow for shadows |
| glowOrange | #F39C12 | Unified orange glow |
| arenaRankGold | #F39C12 | Arena rank display |
</details>

<details>
<summary>Feedback (9)</summary>

| Token | Hex | Purpose |
|-------|-----|---------|
| danger | #E63946 | Danger, defeat, HP critical |
| dangerGlow | #E63946@25% | Danger glow |
| success | #2ECC71 | Victory, HP high |
| successGlow | #2ECC71@25% | Success glow |
| info | #3498DB | Info, links, mana |
| cyan | #00D4FF | Enchanted/premium accents |
| purple | #9B59B6 | XP, magic, epic |
| stamina | #E67E22 | Orange stamina |
| healFlash | #2ECC71 | Heal flash overlay |
</details>

<details>
<summary>Text (10)</summary>

| Token | Hex | Purpose |
|-------|-----|---------|
| textPrimary | #F5F5F5 | Main readable text |
| textSecondary | #A0A0B0 | Subtitles, labels |
| textTertiary | #6B6B80 | Hints, placeholders |
| textTertiaryAA | #8A8AA0 | WCAG AA compliant tertiary |
| textDisabled | #555566 | Disabled states |
| textGold | #FFD700 | Currency, highlighted values |
| textOnGold | #1A1A2E | Dark text ON gold backgrounds |
| textDanger | #FF6B6B | Error messages |
| textSuccess | #5DECA5 | Positive changes, buffs |
| textWarning | #FFA502 | Warning/amber status text |
</details>

<details>
<summary>Border (6)</summary>

| Token | Hex | Purpose |
|-------|-----|---------|
| borderSubtle | #2A2A3E | Panel borders, dividers |
| borderMedium | #3A3A50 | Metallic highlight |
| borderStrong | #4A4A60 | Active element borders |
| borderGold | = gold | Selected items, active tabs |
| borderOrnament | #B8860B | Ornamental engravings |
| bgDarkPanelBorder | #252545 | Dark panel border |
</details>

<details>
<summary>Rarity (10)</summary>

| Token | Hex | Purpose |
|-------|-----|---------|
| rarityCommon | #999999 | Common items |
| rarityUncommon | #4DCC4D | Uncommon items |
| rarityRare | #4D80FF | Rare items |
| rarityEpic | #A64DE6 | Epic items |
| rarityLegendary | #FFBF1A | Legendary items |
| rarityCommonGlow | #999999@13% | Common glow |
| rarityUncommonGlow | #4DCC4D@19% | Uncommon glow |
| rarityRareGlow | #4D80FF@25% | Rare glow |
| rarityEpicGlow | #A64DE6@31% | Epic glow |
| rarityLegendaryGlow | #FFBF1A@38% | Legendary glow |
</details>

<details>
<summary>Class Colors (4)</summary>

| Token | Hex | Purpose |
|-------|-----|---------|
| classWarrior | #E68C33 | Ember Orange |
| classRogue | #4DD958 | Venom Green |
| classMage | #6680FF | Arcane Blue |
| classTank | #9999B2 | Iron Gray |
</details>

<details>
<summary>Rank Colors (6)</summary>

| Token | Hex | Purpose |
|-------|-----|---------|
| rankBronze | #B38040 | Bronze tier |
| rankSilver | #BFBFCC | Silver tier |
| rankGold | #FFD600 | Gold tier |
| rankPlatinum | #66CCCC | Platinum tier |
| rankDiamond | #99CCFF | Diamond tier |
| rankGrandmaster | #FF4D4D | Grandmaster tier |
</details>

<details>
<summary>Full remaining tokens: Pill (30), Button Chrome (15), Arena (8), Dungeon (12), City Map (15), VFX (3), Toast (7), Hub Card (8), Premium (4), Daily Login (4), Difficulty (3), Durability (3), Stance Zone (3), Building Glow (10)</summary>

See DarkFantasyTheme.swift for complete definitions. Total: 199+ semantic tokens.
</details>

### A.2 Spacing Tokens (8 + 60 component)

| Token | Value | Use |
|-------|-------|-----|
| space2XS | 2 | Micro gaps |
| spaceXS | 4 | Badge padding |
| spaceSM | 8 | Card internal |
| spaceMS | 12 | Compact padding |
| spaceMD | 16 | Standard padding |
| spaceLG | 24 | Section separation |
| spaceXL | 32 | Section breaks |
| space2XL | 48 | Hero areas |

Plus 60+ component-specific sizing tokens (see LayoutConstants.swift).

### A.3 Radius Tokens (6)

| Token | Value | Use |
|-------|-------|-----|
| radiusXS | 3 | Progress bars, tiny indicators |
| radiusSM | 6 | Badges, stat bars |
| radiusMD | 8 | Buttons, panels, pills |
| radiusLG | 12 | Cards, widgets |
| radiusXL | 16 | Modals, featured cards |
| radius2XL | 22 | Capsule-like, large CTAs |

### A.4 Typography Tokens (9)

| Token | Font | Size | Use |
|-------|------|------|-----|
| cinematicTitle | Oswald | 40 | Full-screen ceremonies |
| title | Oswald | 28 | Screen titles |
| section | Oswald | 22 | Sub-section headers |
| cardTitle | Oswald | 18 | Card headers |
| buttonLabel | Oswald | 18 | Button text |
| body | Inter | 16 | Body text |
| uiLabel | Inter | 14 | Labels |
| caption | Inter | 12 | Captions |
| badge | Inter | 11 bold | Badges |

### A.5 Motion Tokens (30+)

| Token | Value | Use |
|-------|-------|-----|
| instant | 0.12s | Button press, toggle |
| fast | 0.25s | Tab switch, card appear |
| normal | 0.4s | Screen transition, progress fill |
| reward | 0.6s | Loot reveal, level up |
| epic | 1.2s | Legendary drop, ceremony |
| snappy | easeOut 0.2s | Quick snap |
| smooth | easeInOut 0.35s | Smooth transition |
| spring | response 0.3, damping 0.7 | Standard spring |
| springBouncy | response 0.4, damping 0.55 | Bouncy spring |
| dramatic | response 0.5, damping 0.6 | Hero reveal |
| breathing | easeInOut 2.5s repeat | Ambient pulse |
| pulse | easeInOut 1.8s repeat | Alert pulse |
| glowLoop | easeInOut 3.0s repeat | Glow cycle |
| tickUpDuration | 0.5s | Number counter |
| tickUpShort | 0.3s | Quick counter |
| tickUpLong | 0.8s | Slow counter |
| sheetSpring | response 0.35, damping 0.72 | Sheet presentation |
| tabIndicatorSlide | spring response 0.25, damping 0.75 | Tab indicator |

---

*Generated by Design System Master Audit — 2026-04-01*
*7 parallel forensic agents, full codebase scan*
*1626 total violations found across 7584 token usage points*
*Overall compliance: ~70% → Target: ≥95%*
