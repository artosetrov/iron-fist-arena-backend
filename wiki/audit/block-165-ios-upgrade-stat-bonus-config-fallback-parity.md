---
title: Audit Block 165 — iOS Upgrade Stat Bonus Config Fallback Parity
category: audit
tags: [audit, ios, backend, game-init, items, stats, config]
sources:
  - backend/src/app/api/game/init/route.ts
  - Hexbound/Hexbound/Models/Item.swift
  - Hexbound/Hexbound/Services/GameInitService.swift
  - Hexbound/Hexbound/Services/GameDataCache.swift
  - wiki/audit/block-021-item-stat-authority-consumable-catalog.md
  - wiki/audit/block-159-ios-game-init-item-stat-preview-parity.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 165 — iOS Upgrade Stat Bonus Config Fallback Parity

## Scope

- `backend/src/app/api/game/init/route.ts`
- `Hexbound/Hexbound/Models/Item.swift`
- `Hexbound/Hexbound/Services/GameInitService.swift`
- `Hexbound/Hexbound/Services/GameDataCache.swift`
- `wiki/audit/block-021-item-stat-authority-consumable-catalog.md`
- `wiki/audit/block-159-ios-game-init-item-stat-preview-parity.md`

## Why this block

[[block-158-backend-item-stat-authority-rolled-stats-parity]] and [[block-159-ios-game-init-item-stat-preview-parity]] tightened the stat-authority chain a lot, but one small client lie was still alive:

- iOS fallback math still assumed upgrade bonus was always `+1` per stat level when `authoritativeEffectiveStats` was missing
- backend had already moved to config-driven `upgrade_stat_bonus_per_level`
- cache reset/logout could keep a stale locally remembered fallback value unless that path was reset too

That left a narrow but real parity gap for zero-level or partial item contexts, especially around preview UI and offline-ish cached flows.

## What changed

### `backend/src/app/api/game/init/route.ts`

- added `upgradeStatBonusPerLevel` to the `config` payload returned by `/api/game/init`
- the bootstrap response now exports the same upgrade-bonus authority the backend uses for live item math

### `Hexbound/Hexbound/Services/GameInitService.swift`

- added `upgradeStatBonusPerLevel` to the typed init config payload
- stores the value in `GameConfig`
- updates `Item.fallbackUpgradeStatBonusPerLevel` during bootstrap so local fallback math is seeded from live backend config instead of a hard-coded default

### `Hexbound/Hexbound/Models/Item.swift`

- local fallback `effectiveStats` math now uses `level * fallbackUpgradeStatBonusPerLevel` instead of the old implicit `+1`
- `upgradeBonusPerStat` and `upgradeIncrementPerStat` now use that same config-backed fallback path when no authoritative snapshot exists
- cleaned up comments so the file no longer describes the fallback as a legacy `+1` rule

### `Hexbound/Hexbound/Services/GameDataCache.swift`

- `invalidateAll()` now resets `Item.fallbackUpgradeStatBonusPerLevel` back to `1`
- avoids stale live-config bonus values leaking across logout/cache reset boundaries

## Problems resolved

1. **Client fallback preview still assumed `+1` per upgrade level**
   - Resolution: fallback preview now uses backend-provided `upgradeStatBonusPerLevel`.

2. **Bootstrap config did not expose the upgrade-bonus source of truth**
   - Resolution: `/api/game/init` now includes the value in typed config.

3. **Cache reset could retain a stale fallback bonus**
   - Resolution: `GameDataCache.invalidateAll()` resets the static fallback to the safe default.

## Verification

- `cd backend && npm run build`
- `xcodebuild -project /Users/artosetrov/Documents/Cursor\ AI/PVP\ RPG/Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- backend/src/app/api/game/init/route.ts Hexbound/Hexbound/Models/Item.swift Hexbound/Hexbound/Services/GameInitService.swift Hexbound/Hexbound/Services/GameDataCache.swift`

All passed after the change.

## Follow-up

- This closes the specific `upgrade_stat_bonus_per_level` bootstrap gap called out in [[block-021-item-stat-authority-consumable-catalog]].
- The only remaining review question in this area is product-facing, not contract-facing:
  - should zero-context item surfaces keep showing best-effort local preview at all,
  - or should they hide upgrade deltas until authoritative backend stats exist?
