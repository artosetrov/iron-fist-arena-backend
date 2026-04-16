---
title: Block 071 — iOS hub, daily login, and level-up contract cleanup
category: audit
tags: [audit, ios, hub, battle-pass, daily-login, progression, residual-ui]
sources:
  - Hexbound/Hexbound/Views/Hub/HubInfoCards.swift
  - Hexbound/Hexbound/Views/BattlePass/BattlePassDetailView.swift
  - Hexbound/Hexbound/Models/DailyLoginRewardDef.swift
  - Hexbound/Hexbound/Views/Components/LevelUpModalView.swift
  - Hexbound/Hexbound/Models/ConsumableCatalog.swift
  - Hexbound/Hexbound/Services/GameDataCache.swift
  - backend/src/lib/game/progression.ts
updated: 2026-04-15
status: Fixed
---

# Block 071 — iOS hub, daily login, and level-up contract cleanup

## Scope

- `Hexbound/Hexbound/Views/Hub/HubInfoCards.swift`
- `Hexbound/Hexbound/Views/BattlePass/BattlePassDetailView.swift`
- `Hexbound/Hexbound/Models/DailyLoginRewardDef.swift`
- `Hexbound/Hexbound/Views/Components/LevelUpModalView.swift`
- reference-only:
  - `Hexbound/Hexbound/Models/ConsumableCatalog.swift`
  - `Hexbound/Hexbound/Services/GameDataCache.swift`
  - `backend/src/lib/game/progression.ts`

## Why this block

After the admin-heavy passes, the next high-value drift was back in the live iOS client: a few residual UI surfaces were still presenting either mock data or invented rewards.

These were not all equally severe, but they shared one pattern: the UI looked polished while quietly diverging from runtime truth.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[progression]]
- [[block-016-backend-daily-login-battle-pass-reward-contracts]]
- [[block-017-ios-claim-services-authoritative-reward-sync]]
- [[block-018-ios-typed-achievements-quests-loaders]]

## File notes

### `Hexbound/Hexbound/Views/Hub/HubInfoCards.swift`

- **Zone:** iOS / hub / residual info widgets
- **Purpose:** shared mini-cards for hub-side informational surfaces
- **Problems found:**
  - `BattlePassCard` was still hardcoded to `Season 1 • Level 7/30`
  - the file still carried a stale TODO instead of live data wiring
  - `TopCurrencyBar` had an unused `SettingsManager` reference
  - inbound-usage grep suggests these card views are currently residual rather than active hub UI
- **What was fixed:**
  - wired `BattlePassCard` to `GameDataCache.cachedBattlePass()`
  - removed the mock season/level values and replaced them with safe live/fallback rendering
  - removed the dead `SettingsManager` local
- **What still needs attention:**
  - this file remains a likely candidate for a keep/delete pass, because the card structs appear unreferenced in the current live hub
- **Status:** Fixed

### `Hexbound/Hexbound/Views/BattlePass/BattlePassDetailView.swift`

- **Zone:** iOS / battle pass
- **Purpose:** detailed battle-pass screen
- **Problems found:**
  - carried a stale TODO comment claiming the ViewModel had no error property, even though the screen already uses `vm.errorMessage`
- **What was fixed:**
  - removed the misleading comment
- **Status:** Fixed

### `Hexbound/Hexbound/Models/DailyLoginRewardDef.swift`

- **Zone:** iOS / daily login / reward DTO
- **Purpose:** authoritative client-side display mapping for server-authored daily-login rewards
- **Problems found:**
  - HP potion reward icons were still mapped to the stamina icon
  - fallback asset resolution for consumables ignored the existing `ConsumableCatalog`, so newer consumable display paths could silently regress back to generic stamina art
- **What was fixed:**
  - mapped `icon-hp-potion-small` to `health_potion_small`
  - mapped `icon-hp-potion-large` to `health_potion_large`
  - routed consumable fallback asset resolution through `ConsumableCatalog.resolvedImageKey(...)`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Components/LevelUpModalView.swift`

- **Zone:** iOS / progression / ceremony UI
- **Purpose:** level-up celebration modal
- **Problems found:**
  - the modal showed hardcoded `+1 Passive Point` and `+120 Stamina Refill`
  - those values were not carried by the active iOS reward/progression contract
  - this made the ceremony visually rich but not trustworthy
- **What was fixed:**
  - removed the fake passive-point and stamina-refill reward rows
  - kept the modal focused on server-backed `Stat Points` plus derived building unlocks
  - updated comments so the file explicitly documents the “only show what the active contract actually returns” rule
- **What still needs attention:**
  - backend progression already computes `passivePointsAwarded`, but that value is not yet consistently exposed through the iOS-facing claim/level-up surfaces
  - if product wants passive points back in the ceremony, that should come from a real contract pass, not another hardcoded UI default
- **Status:** Fixed

### `Hexbound/Hexbound/Models/ConsumableCatalog.swift`

- **Zone:** iOS / shared consumable metadata
- **Purpose:** canonical consumable image/name mapping
- **Why it mattered here:**
  - it already knew the correct health-potion asset keys, so daily-login fallback logic should have reused it instead of inventing a separate icon rule
- **Status:** OK

### `Hexbound/Hexbound/Services/GameDataCache.swift`

- **Zone:** iOS / cache
- **Purpose:** short-lived authoritative cache for hub-prefetched data
- **Why it mattered here:**
  - `BattlePassCard` now reads from the existing battle-pass cache instead of shipping its own mock state
- **Status:** OK

### `backend/src/lib/game/progression.ts`

- **Zone:** backend / progression reference
- **Purpose:** authoritative level-up calculation
- **Why it mattered here:**
  - confirms that passive points are a real backend concept, but not yet part of the active iOS level-up ceremony contract
- **Status:** OK

## Problems found

1. **Residual hub battle-pass widget still showed mock progression**
   - Risk: future reuse of the component would silently reintroduce fake live-state into the hub.
   - Fix: wired the widget to cached battle-pass data and removed hardcoded season/level values.

2. **Daily login still rendered HP potion rewards with stamina art**
   - Risk: users could receive one reward but visually read another, which is especially bad in a daily reward flow.
   - Fix: pointed HP potion icon keys at the real health-potion assets and reused the shared consumable catalog for fallback asset resolution.

3. **Level-up ceremony advertised reward rows the active contract did not provide**
   - Risk: player-facing misinformation; the client was effectively making up part of the reward summary.
   - Fix: removed the fake passive/stamina rows and kept the ceremony limited to server-backed stat points plus legitimate unlocks.

4. **`HubInfoCards.swift` still looks like a residual surface**
   - Risk: dead or half-dead UI files drift quietly because they are no longer exercised by normal navigation.
   - Fix in this block: removed the most misleading mock; full keep/delete decision is deferred to a later residual-surface pass.

## Verification

- targeted grep across touched files for stale `TODO`, hardcoded `Season 1`, and fake level-up reward labels
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

## Follow-up

- do a dedicated iOS progression-contract pass so `passivePointsAwarded` can either be exposed end-to-end or deliberately omitted everywhere, instead of existing only in backend internals
- audit `HubInfoCards.swift` as a residual/unused surface and decide whether to keep it as a library file or deprecate it explicitly
