---
title: Audit Block 158 — Backend Item Stat Authority and Rolled Stats Parity
category: audit
tags: [audit, backend, inventory, stash, items, stats, progression]
sources:
  - backend/src/lib/game/item-stats.ts
  - backend/tests/lib/item-stats.test.ts
  - backend/src/lib/game/inventory-response.ts
  - backend/src/app/api/inventory/route.ts
  - backend/src/app/api/stash/route.ts
  - backend/src/app/api/shop/upgrade/route.ts
  - backend/src/lib/game/equipment-stats.ts
  - backend/src/lib/game/build-stats.ts
  - wiki/audit/block-021-item-stat-authority-consumable-catalog.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 158 — Backend Item Stat Authority and Rolled Stats Parity

## Scope

- `backend/src/lib/game/item-stats.ts`
- `backend/tests/lib/item-stats.test.ts`
- `backend/src/lib/game/inventory-response.ts`
- `backend/src/app/api/inventory/route.ts`
- `backend/src/app/api/stash/route.ts`
- `backend/src/app/api/shop/upgrade/route.ts`
- `backend/src/lib/game/equipment-stats.ts`
- `backend/src/lib/game/build-stats.ts`
- `wiki/audit/block-021-item-stat-authority-consumable-catalog.md`

## Why this block

[[block-021-item-stat-authority-consumable-catalog]] left one real stat-authority tail open: backend inventory and stash snapshots still built `effectiveStats` from `baseStats` only, while client-side and gameplay-adjacent paths were already implicitly treating `rolledStats` as part of the live item.

That left the project in a bad middle state:

- inventory/stash snapshots underreported effective item power
- upgrade preview deltas ignored rolled stats
- derived stat recalculation and gear score still depended on older formulas in some paths
- `build-stats.ts` still used raw `+ upgradeLevel` instead of the config-driven `upgrade_stat_bonus_per_level`

## What changed

### `backend/src/lib/game/item-stats.ts`

- added a shared stat helper layer for backend item math:
  - `combineItemStats(...)`
  - `buildEffectiveItemStats(...)`
  - `sumCoreEquipmentStats(...)`
  - `calculateEffectiveItemPower(...)`
- normalizes unknown JSON payloads safely
- merges `baseStats + rolledStats`
- applies config-driven upgrade bonuses on top of the merged stat set

### `backend/src/lib/game/inventory-response.ts`
### `backend/src/app/api/inventory/route.ts`
### `backend/src/app/api/stash/route.ts`

- moved snapshot `effectiveStats` generation onto `buildEffectiveItemStats(...)`
- snapshots now treat rolled stats as authoritative item power, not as side-data the client has to guess about

### `backend/src/app/api/shop/upgrade/route.ts`

- upgraded before/after stat envelopes to use merged `baseStats + rolledStats`
- `effectiveStats`
- `previousEffectiveStats`
- `statChanges`

now all use the same shared helper instead of a route-local loop

### `backend/src/lib/game/equipment-stats.ts`

- equipped stat recomputation now includes `rolledStats`
- still respects broken-item suppression via durability
- still uses config-driven `getUpgradeStatBonus()`, but now applies it to the merged stat set instead of `baseStats` only

### `backend/src/lib/game/build-stats.ts`

- full derived-stat recomputation now includes `rolledStats`
- removed the stale raw `+ upgradeLevel` formula
- moved both equipment bonus aggregation and gear score calculation onto shared/config-aware helpers

### `backend/tests/lib/item-stats.test.ts`

- added focused coverage for:
  - merging base and rolled stats
  - effective-stat generation with upgrade bonus
  - core-stat aggregation
  - total effective item power
  - invalid stat payload handling

## Problems resolved

1. **Inventory and stash snapshots underreported real item power**
   - Resolution: snapshot `effectiveStats` now include rolled stats.

2. **Upgrade responses drifted from live item power**
   - Resolution: upgrade before/after/stat-change payloads now use the same merged stat authority.

3. **Derived stat and matchmaking gear score paths were not aligned**
   - Resolution: both `equipment-stats.ts` and `build-stats.ts` now pull from the same merged/config-aware stat math.

4. **Upgrade bonus config was not honored everywhere**
   - Resolution: the last `+ upgradeLevel` fallback in `build-stats.ts` is gone.

## Verification

- `cd backend && npx vitest run tests/lib/item-stats.test.ts`
- `cd backend && npx eslint src/lib/game/item-stats.ts src/lib/game/inventory-response.ts src/app/api/inventory/route.ts src/app/api/stash/route.ts src/app/api/shop/upgrade/route.ts src/lib/game/equipment-stats.ts src/lib/game/build-stats.ts tests/lib/item-stats.test.ts`
- `cd backend && npm run build`
- `git diff --check -- backend/src/lib/game/item-stats.ts backend/tests/lib/item-stats.test.ts backend/src/lib/game/inventory-response.ts backend/src/app/api/inventory/route.ts backend/src/app/api/stash/route.ts backend/src/app/api/shop/upgrade/route.ts backend/src/lib/game/equipment-stats.ts backend/src/lib/game/build-stats.ts`

All passed after the change.

## Follow-up

- This closes the backend side of the old stat-authority gap from block 021.
- The remaining review surface here is narrower and mostly client-facing:
  - when iOS should trust server `effectiveStats`
  - when iOS may still show local preview/fallback values for partially-known items
