# Hexbound DS Ecosystem — Full Audit Report
**Date:** 2026-04-03 | **Agents:** ds-code-audit, ds-figma-sync, ds-extract-component, ds-qa-coverage

---

## Executive Summary

| Area | Score | Status |
|------|-------|--------|
| Swift Code DS Compliance | 91% | ⚠️ 7 critical issues |
| Code ↔ Figma Token Parity | 85% | ⚠️ Gradients + opacity missing in Figma |
| Inline Pattern Duplication | 7 patterns found | 🔴 3 EXTRACT + 4 PARAMETERIZE |
| Figma Screens Coverage | 9.4% (5/53) | 🔴 CRITICAL — 48 screens missing |
| State Coverage | 0% | 🔴 No Loading/Empty/Error states |

---

## 1. DS Code Audit (Swift)

### CDO Scan: 10/14 PASS

| # | Check | Status | Violations |
|---|-------|--------|------------|
| 1 | Invented font tokens | ✅ PASS | 0 |
| 2 | Invented spacing tokens | ✅ PASS | 0 |
| 3 | Hardcoded hex colors in Views | ✅ PASS | 0 |
| 4 | Hardcoded system fonts | 🔴 FAIL | 1 (ArenaOpponentCard:160) |
| 5 | Raw Color.xxx in Views | ✅ PASS | 0 |
| 6 | SF Symbol currency icons | ✅ PASS | 0 |
| 7 | Hardcoded cornerRadius | ✅ PASS | 0 |
| 8 | Junk files in xcodeproj | 🔴 FAIL | 1 (project.pbxproj.bak) |
| 9 | Merge conflict markers | ✅ PASS | 0 |
| 10 | Raw Divider() | 🔴 FAIL | 1 (GuildHallDetailView:438) |
| 11 | Font token function calls | 🔴 FAIL | 41 (ButtonStyles, AppRouter, Dev files) |
| 12 | Hardcoded VStack/HStack spacing | ⚠️ | 24 (mostly small values) |
| 13 | Hardcoded frame dimensions | ⚠️ | 30+ (mostly intentional icon/layout sizes) |
| 14 | Font(size:) function calls | ✅ PASS | 0 |

### P0 Fixes Required:
1. **41 font token function calls** — `DarkFantasyTheme.title(size:)` → `.title` (mostly in ButtonStyles.swift + Dev/ files)
2. **Remove project.pbxproj.bak** — junk file in xcodeproj
3. **1 raw Divider()** in GuildHallDetailView:438
4. **1 system font** in ArenaOpponentCard:160

### Orphaned Components: 14 with 0 callers
CelebrationBannerView, EventBannerView, GuestGateView, GuestNudgeBanner, InlineFeedback, LevelUpModalView, NPCHintOverlay, NumberTickUpView, OfflineBannerView, ScreenLayout, SessionExpiredModalView, ShimmerModifier, SkeletonViews, StaggeredAppearModifier

### Unused Tokens: 51
- DarkFantasyTheme: 30 unused (bgDisabled, dangerGlow, successGlow, healFlash, rarityCommon, etc.)
- LayoutConstants: 21 unused (textHero, screenTopGap, safeAreaTop, etc.)

---

## 2. Code ↔ Figma Token Parity

### Full Sync ✅
| Category | Swift | Figma | Parity |
|----------|-------|-------|--------|
| Spacing (base) | 8 | 8 | ✅ 100% |
| Radius (base) | 6 | 6 | ✅ 100% |
| Text Styles | 9 | 9 | ✅ 100% |
| Effect Styles | 4 | 4 | ✅ 100% |

### Missing from Figma ❌
| Category | Swift Count | Figma Count | Gap |
|----------|-------------|-------------|-----|
| Gradients | 21 | 0 | 21 missing (may stay code-only) |
| Opacity Scale | 9 | 0 | 9 missing |
| Icon Sizes | 6 | 0 | 6 missing |

### Figma DS Stats
- Total variables: 361
- Total components: 608 (45 sets, 230+ variants)
- Total text styles: 9
- Total effect styles: 4
- Pages: 37

---

## 3. Inline Pattern Extraction

### 7 Patterns Identified

| # | Pattern | Type | Files | Instances | Priority |
|---|---------|------|-------|-----------|----------|
| 1 | **Glass Stat Pill** | EXTRACT | 4 | 15+ | 🔴 CRITICAL |
| 2 | **Class Tag Pill** | EXTRACT | 3 | 3+ | HIGH |
| 3 | **Rarity Modal Border** | EXTRACT | 2 | 2 | HIGH |
| 4 | **Stat Comparison Delta** | PARAMETERIZE | 3 | 3 | HIGH |
| 5 | **Stat Row Label-Value** | PARAMETERIZE | 4+ | 4+ | MEDIUM |
| 6 | **Reward Pill** | PARAMETERIZE | 2 | 2 | MEDIUM |
| 7 | **Opponent Stat Cell** | PARAMETERIZE | 3 | 3 | MEDIUM |

### Top Priority: Glass Stat Pill (15+ instances)
Duplicated as private functions in ArenaOpponentCard, CharacterSelectionView, DungeonBossCard, and more. Each copy is 20+ lines identical. Extraction saves ~80 lines of duplicated code.

### Proposed New Components:
```
GlassStatPill.swift — value + label with glass background
ClassTagView.swift — colored pill with class name
RarityModalFrame (modifier) — ornamental modal border by rarity
DeltaBadgeView.swift — arrow + delta value badge
StatRowView.swift — label + value horizontal row
RewardPillView.swift — icon + amount capsule
OpponentStatComparisonCell.swift — stat cell with comparison delta
```

---

## 4. Figma Screens Coverage

### Current State: 5/53 screens (9.4%)

**Existing:**
1. Hub — Main Screen
2. Arena — PvP Screen
3. Hero Detail — Character Screen
4. Fortune Wheel
5. Shell Game — Idle

**Missing: 48 screens** across all categories

### State Coverage: 0/5 screens have ≥3 states
All existing screens have only 1 state (Default). Need Loading + Empty/Error minimum.

### Component Usage: Unknown
Existing screens may use local frames instead of DS library instances — needs verification.

---

## Action Plan (Priority Order)

### Phase A — Swift Code Fixes (P0, ~3 hours)
1. Fix 41 font token function calls in ButtonStyles.swift, AppRouter.swift, Dev/ files
2. Remove project.pbxproj.bak
3. Replace raw Divider() in GuildHallDetailView:438 with ornamental
4. Fix system font in ArenaOpponentCard:160
5. Run CDO scan → verify all PASS

### Phase B — Component Extraction (~4 hours)
1. Extract GlassStatPill.swift (15+ instances, highest ROI)
2. Extract ClassTagView.swift (3+ instances)
3. Create RarityModalFrame modifier (2 instances)
4. Parameterize DeltaBadgeView, StatRowView, RewardPillView
5. Add each to Figma DS as new component
6. Add each to pbxproj

### Phase C — Figma Token Gaps (~1 hour)
1. Add 6 icon size variables to Spacing collection
2. Add 9 opacity variables to Spacing/Color collection
3. Decide gradient strategy (code-only vs Figma representation)

### Phase D — Build 48 Missing Screens (~20 hours)
Use ds-screen-builder skill, priority order:
- Tier 1: Core Loop (CombatView, InventoryView, ShopView) — 7 screens
- Tier 2: Monetization (BattlePass, DailyQuests, DailyLogin) — 7 screens
- Tier 3: Auth (Welcome→LoreIntro) — 8 screens
- Tier 4: Secondary (Dungeon, Social, Minigames, Settings) — 26 screens

### Phase E — State Variants (~8 hours)
Add Loading + Empty/Error states to all 53 screens (minimum 3 states each)

### Phase F — Prototype Flows (~4 hours)
Connect 8 key flows (80+ connections) using ds-prototype skill

### Phase G — Final QA
Run ds-qa-coverage → target 95%+ overall score

---

## Total Estimated Effort: ~40 hours
- Code fixes: 7 hours (Phase A + B)
- Figma build: 33 hours (Phase C + D + E + F + G)
