# Hexbound Simulator Playtest — Bug Report

*Historical simulator session snapshot from 2026-04-09. Several findings here have since been fixed or superseded by later audit blocks, so treat this as evidence/history rather than the current bug backlog. For live status, use `wiki/log.md`, `wiki/audit/audit-index.md`, and the newer audit blocks covering auth, daily quests, shop metadata, tutorial overlays, and iOS contract/runtime parity. Updated: 2026-04-16*

**Date:** 2026-04-09
**Tester:** Claude (automated playthrough via iOS Simulator)
**Device:** iPhone 17 Pro Max, iOS 26.3
**Character:** Ravenfury — Male Orc Warrior (guest account)
**Session goal:** Level up from 1 → 10 via Training Camp
**Session outcome:** 🔴 BLOCKED at Lv.4 by critical guest-progress wipe (Bug #19)

---

## Severity Legend

- 🔴 **CRITICAL** — blocks core progression, data loss, crashes
- 🟠 **HIGH** — broken feature, bad UX, player confusion
- 🟡 **MEDIUM** — polish, copy, inconsistency
- 🟢 **LOW** — nitpick, cosmetic

---

## Critical Bugs

### 🔴 Bug #19 — Guest progress wiped on session expire
**Severity:** CRITICAL — game-breaking for guest players
**Area:** Auth, GuestGateView, character persistence
**Flow:**
1. Play the game as guest, create character, grind to Lv.4
2. Leave app idle for ~30 min (or trigger any 401)
3. Session expired modal → Log In → back → Play as Guest
4. **Result:** Character creation wizard opens fresh — Ravenfury, all gold, items, stats, quests GONE

**Expected:** Play as Guest should restore existing guest profile via stable deviceId / local token. Only explicit "new character" action should wipe.

**Impact:** Any guest player who loses session (idle, token expiry, network blip) loses entire progress. For a game relying on retention/progression, this is catastrophic.

**Fix direction:**
- Guest token must be persistent (keychain, not memory/session cookie)
- Backend should reissue guest session from deviceId
- Session Expired modal should trigger silent re-auth for guest, not force logout
- If progress really cannot be restored, show explicit "Your guest progress cannot be recovered" warning with option to Sign Up *before* wiping

---

### 🔴 Bug #18 — Training Camp shows generic "Failed to Load" on 401 instead of Session Expired modal
**Severity:** CRITICAL — confusing, blocks navigation
**Area:** TrainingCampView error handling
**Flow:**
1. Idle session long enough for token to expire
2. Tap Training Camp from Adventures
3. **Result:** Generic `ErrorStateView("Failed to Load / Something went wrong loading this content")` with only RETRY button. No back button, no nav bar. Retry still hits 401 and shows same error.

**Expected:** When backend returns 401, global interceptor should trigger Session Expired modal (which already exists — seen on Bug #19 flow) instead of letting the screen render its own generic error.

**Sub-bug #18a:** The error state has no back button or navigation bar, so the player is stuck unless they kill the app via system home button.

**Fix direction:**
- API client should intercept 401 globally → dispatch Session Expired modal
- ErrorStateView template should always render inside a nav container with a back button
- Add "Contact Support" or error code for non-401 errors to help debugging

---

## High-Severity Bugs (from earlier in session)

### 🟠 Bug #10 — Alchemist daily quest ✓ Done but no Claim button, no gold credit
**Area:** Daily quests, Alchemist NPC
**Flow:** Complete the "alchemist" daily objective → quest shows ✓ Done → no Claim CTA appears → gold reward never credited.
**Fix direction:** Daily quest claim endpoint must be wired; verify `dailyQuestProgress.completed` transitions to `claimable` state and ClaimButton surfaces.

### 🟠 Bug #13 — Large Stamina Potion rarity mismatch
**Area:** Shop vs Inventory consistency
**Flow:** In Shop, Large Stamina Potion is labeled **RARE ★★★**. In Inventory after purchase, same item is **COMMON ★**.
**Fix direction:** Single source of truth for rarity — check `Items` table and `shop_config.ts`.

### 🟠 Bug #17 — Dungeon Guide popup re-appears after every Adventures return
**Area:** Tutorial/Guide overlay
**Flow:** Dismiss Dungeon Guide → navigate away → return → popup shows again. "Don't show again" button exists but is ignored.
**Fix direction:** Persist dismissal in `tutorial_progress` or local UserDefaults; check the flag before rendering the popup.

---

## Medium-Severity Bugs

### 🟡 Bug #11 — Shop "Starter Pack" contains raw DB key `health_potion_large`
**Area:** Shop bundle display
**Flow:** Shop → Bundles → Starter Pack description shows raw key instead of localized name.
**Fix direction:** Resolve item keys through item catalog lookup before rendering bundle contents.

### 🟡 Bug #12 — Medium Stamina Potion header says "+50" but description says "60", raw key `stamina_potion_medium`
**Area:** Consumable item metadata
**Flow:** Item detail sheet header: "+50 Stamina"; body copy: "Restores 60 Stamina". Also raw DB key leaks to UI.
**Fix direction:** Reconcile `items.effect_value` with description template; fix item name resolution.

### 🟡 Bug #14 — Straw Dummy (Lv.1 training dummy) marked as "BOSS" in detail view
**Area:** Training Camp enemy metadata
**Flow:** Tap Straw Dummy → detail screen shows "BOSS" tag. But it is the tutorial dummy, not a boss.
**Fix direction:** `is_boss` flag on training monsters should be false; only tier 10 culmination should be boss.

### 🟡 Bug #15 — Placeholder lore text on Training Camp monsters
**Area:** Enemy descriptions
**Flow:** All Training Camp monsters show generic "Legends speak of this creature..." instead of unique lore.
**Fix direction:** Populate `monster_catalog.lore` for all training monsters; add CMS/admin QA.

### 🟡 Bug #16 — Training Camp uses "Dungeon Progress 1/10" terminology
**Area:** Copy, Training Camp UI
**Flow:** Training Camp progress bar labeled "Dungeon Progress". Training Camp is not a dungeon.
**Fix direction:** Use "Training Progress" or specific label per PvE track.

---

## UX / Feature Requests (from Artem)

### 🟠 Bug #20 — Shop: нет опции купить несколько зелий сразу
**Severity:** HIGH — friction в core loop покупки consumables
**Area:** `ShopDetailView.swift`, `ItemDetailSheet.swift` (shopMode), `ShopViewModel.swift`
**Current:** В ItemDetailSheet при покупке зелья есть только одна кнопка "Buy for X" — надо нажимать confirm dialog каждый раз, чтобы купить 5 health potions = 5 circles таппинга.
**Expected:** Для stackable consumables (потенциально любых items с `maxStack > 1` или `type == .consumable`) показывать quantity selector (−/+ или x1/x5/x10) перед кнопкой Buy. Цена и итог динамически пересчитываются. Backend bulk-purchase endpoint (или цикл в ShopViewModel с optimistic state + error rollback).
**Fix direction:**
- iOS: расширить `ItemDetailSheet.ShopMode` полем `quantity: Binding<Int>` + `maxQuantity` (по affordability и stack cap)
- iOS: добавить `QuantityStepperView` компонент (−/+ с динамичным total price)
- Backend: `POST /api/shop/buy` принимает `quantity: number`, серверная транзакция умножает цену и добавляет N штук
- Confirm dialog должен показывать "Buy 5× Health Potion for 500g?"

---

### 🟠 Bug #21 — Shop: daily reward widget не на всю ширину + не исчезает после claim
**Severity:** MEDIUM — визуальная непоследовательность + stale UI
**Area:** `ShopDetailView.swift` — banner section (ActiveQuestBanner / ShopOfferBannerView / daily reward widget)
**Current:** Виджет с наградой (дневной/shop reward) в магазине рендерится узко (как другие banner'ы) и после клика Claim остаётся на экране.
**Expected:**
- Widget должен быть **full-width** (от edge до edge, padding только по screen edges)
- После `onClaim()` widget должен **исчезнуть** с анимацией (`.move(edge: .top).combined(with: .opacity)` или snappy scale-out)
- State: сохранять `isClaimed` в VM → `if !vm.rewardClaimed { RewardWidget(...) }`
**Fix direction:**
- Найти widget в `ShopDetailView.mainContent` — вероятно в том же месте где `ActiveQuestBanner`
- Обернуть в conditional `if !vm.dailyRewardClaimed`
- `.frame(maxWidth: .infinity)` + `.padding(.horizontal, LayoutConstants.screenPadding)` вместо фиксированной ширины
- ShopViewModel: добавить `@Observable var dailyRewardClaimed: Bool`, выставлять в `true` после успешного claim API call

---

### 🟡 Bug #22 — Hub: Achievements building badge (4 достижения) не мерцает
**Severity:** MEDIUM — discoverability, пользователь не замечает pending достижения
**Area:** `CityMapView.swift`, `CityBuildingConfig.swift`, `Views/Hub/*Building*.swift`
**Current:** Над зданием Achievements на hub висит золотой badge с числом "4" (количество claimable достижений), но он статичный. Player легко его не замечает.
**Expected:** Badge должен **пульсировать** как free stat points dots у hero widget (который уже мерцает gold/glow). Тот же эффект — `glowPulse(color: .gold, intensity: 0.5, isActive: hasClaimable)` + лёгкий scale breathe или opacity pulse (0.7 → 1.0 → 0.7).
**Fix direction:**
- Найти pulsing эффект у UnifiedHeroWidget для stat points — вероятно `glowPulse` modifier или `.modifier(PulsingGlowModifier())`
- Переиспользовать тот же modifier на Achievement building badge
- Trigger условие: `isActive: achievementsViewModel.claimableCount > 0`
- Тот же подход применить **ко всем building badges** с pending действиями (Inbox, Quests, Battle Pass) для consistency

---

## Balance Concerns (not bugs, for review)

- **Lv.4 Warrior Ravenfury takes 112 HP damage from Lv.1 Straw Dummy** (160 → 48 HP after one fight). Straw Dummy is the starter target — should feel trivial. Verify damage formula against `DEVELOPMENT_RULES.md` balance constants.
- **PvP Arena not accessible at Lv.4** — checked all hub buildings. Is this gated by level or hidden? Document gate clearly.

---

## Unverified / Pending Investigation

- **Bug #2 (carried from earlier session):** Welcome gift gold=0 was not applied to wallet after reward claim. Needs repro after auth fix.
- **Daily quest system:** Could not verify claim flow end-to-end due to Bug #10. Needs manual backend check.
- **Battle Pass XP attribution:** Unclear whether Training Camp fights award BP XP. Spec in `backend/CLAUDE.md` says yes for dungeon floors — is Training Camp treated as dungeon?

---

## Recommended Priorities

1. **Fix Bug #19 IMMEDIATELY** — guest retention is zero without persistent sessions
2. **Fix Bug #18** — 401 handling must be global
3. **Fix Bug #10** — daily quest claim is core daily loop
4. **Fix Bug #13** — rarity inconsistency breaks trust in item system
5. Batch fix #11, #12, #14, #15, #16 — copy/metadata pass

---

## Session Metrics

- **Playtime:** ~45 min before blocker
- **Max level reached:** 4 (XP 912/1000 — one fight away from Lv.5)
- **Gold earned:** ~1,617
- **Stamina potions consumed:** 1× Large
- **Bugs documented:** 22 (of which 2 critical, 5 high, 8 medium, + 3 feature requests from Artem)
- **Session-ending bug:** #19 Guest progress wipe
