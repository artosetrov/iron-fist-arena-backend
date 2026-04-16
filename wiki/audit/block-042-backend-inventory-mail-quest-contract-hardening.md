---
title: Block 042 — backend inventory/mail/quest contract hardening
category: audit
tags: [audit, backend, inventory, mail, quests, tests]
sources:
  - backend/src/app/api/inventory/equip/route.ts
  - backend/src/app/api/inventory/unequip/route.ts
  - backend/src/app/api/mail/route.ts
  - backend/src/app/api/quests/daily/route.ts
  - backend/src/lib/game/equipment-stats.ts
  - backend/src/lib/rate-limit.ts
  - backend/tests/api/inventory-equip.test.ts
  - backend/tests/api/inventory-unequip.test.ts
  - backend/tests/api/mail-list.test.ts
updated: 2026-04-15
status: Fixed
---

# Block 042 — backend inventory/mail/quest contract hardening

## Scope

- `backend/src/app/api/inventory/equip/route.ts`
- `backend/src/app/api/inventory/unequip/route.ts`
- `backend/src/app/api/mail/route.ts`
- `backend/src/app/api/quests/daily/route.ts`
- `backend/src/lib/game/equipment-stats.ts`
- `backend/src/lib/rate-limit.ts`
- `backend/tests/api/inventory-equip.test.ts`
- `backend/tests/api/inventory-unequip.test.ts`
- `backend/tests/api/mail-list.test.ts`

## Why this block

This warning-heavy backend slice was no longer just cosmetic:

1. `inventory/equip` and `inventory/unequip` could commit the equipment mutation and then still return `500` if `recalculateDerivedStats(...)` failed after the write.
2. `mail/route.ts` claimed to rate-limit at 30 requests per minute, but it was actually passing `60` to a helper that expects milliseconds.
3. `quests/daily/route.ts` still depended on broad `any` shapes around quest definitions and locked quest rows, which made the live contract harder to reason about and easier to drift.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-038-backend-utility-routes-and-character-warning-cleanup]]
- [[block-015-claim-progression-achievements-quests-battle-pass]]
- [[progression]]
- [[bug-patterns]]

## File notes

### `backend/src/app/api/inventory/equip/route.ts`

- **Zone:** backend / inventory mutations
- **Purpose:** equips an inventory item into the correct slot under row locks and returns the authoritative inventory snapshot
- **Depends on:** `getAuthUser`, `rateLimit`, Prisma transaction/locks, `recalculateDerivedStats`, combat cache invalidators, `buildInventoryResponse`
- **Used by:** iOS inventory/equipment flows
- **Problems found:**
  - locked inventory/equipped-row shapes were hidden behind `any`
  - derived-stat recompute happened after commit, so a stat failure could bubble a false `500` after the equip already stuck
- **What was fixed:**
  - typed the locked SQL row shapes
  - moved `recalculateDerivedStats(charId, tx)` inside the equipment transaction
  - kept cache invalidation post-commit, where it belongs
- **Status:** Fixed

### `backend/src/app/api/inventory/unequip/route.ts`

- **Zone:** backend / inventory mutations
- **Purpose:** unequips an item and returns the same authoritative snapshot shape as `GET /api/inventory`
- **Depends on:** `getAuthUser`, `rateLimit`, Prisma, `recalculateDerivedStats`, combat cache invalidators, `buildInventoryResponse`
- **Used by:** iOS inventory/equipment flows
- **Problems found:**
  - same post-commit false-`500` risk as `equip`
- **What was fixed:**
  - wrapped the unequip write and derived-stat recompute in one transaction
  - left cache invalidation outside the transaction
- **Status:** Fixed

### `backend/src/app/api/mail/route.ts`

- **Zone:** backend / inbox
- **Purpose:** lists paginated mail for a character
- **Depends on:** `getAuthUser`, `rateLimit`, Prisma mail/message relations
- **Used by:** iOS inbox list loader
- **Problems found:**
  - the route passed `60` instead of `60_000` to the shared rate-limit helper, which effectively turned the documented minute window into 60 ms
  - recipient mapping still carried explicit `any`
- **What was fixed:**
  - restored the correct 1-minute rate-limit window
  - removed the explicit `any` callback casts
- **Status:** Fixed

### `backend/src/app/api/quests/daily/route.ts`

- **Zone:** backend / quests
- **Purpose:** generates daily quests, lists the current set, and claims rewards
- **Depends on:** `getAuthUser`, Prisma quest tables, battle pass config, shared reward grants, cache invalidation
- **Used by:** iOS quest list and quest-claim flows
- **Problems found:**
  - broad `any` shapes hid the real contract for live quest definitions, formatted quest rows, and locked claim rows
- **What was fixed:**
  - introduced explicit quest pool/meta/view/lock row types
  - guarded DB-backed quest definitions through `isQuestType(...)`
  - removed the remaining `catch (error: any)` branch
- **Status:** Fixed

### `backend/tests/api/inventory-equip.test.ts`

- **Zone:** backend tests / inventory
- **Purpose:** protects the new equip transactional invariant
- **What it covers now:** successful equip recomputes derived stats inside the transaction and still returns the authoritative snapshot
- **Status:** Fixed

### `backend/tests/api/inventory-unequip.test.ts`

- **Zone:** backend tests / inventory
- **Purpose:** protects the new unequip transactional invariant
- **What it covers now:** successful unequip recomputes derived stats inside the transaction and still returns the authoritative snapshot
- **Status:** Fixed

### `backend/tests/api/mail-list.test.ts`

- **Zone:** backend tests / inbox
- **Purpose:** locks the mail listing rate-limit window and basic payload shape
- **What it covers now:** the route uses the documented `30 / 60_000 ms` rate limit and returns the inbox payload
- **Status:** Fixed

## Problems found

1. **Inventory mutations could return false `500`s after a committed write**
   - Risk: the client sees a failure and may retry or roll back local state even though the equip/unequip already committed.
   - Fix: moved derived-stat recomputation into the same transaction as the equipment mutation.

2. **Mail rate limit window was off by three orders of magnitude**
   - Risk: the endpoint was effectively almost unthrottled despite claiming a one-minute guard.
   - Fix: changed the window from `60` to `60_000` and added a route test.

3. **Daily quest route still hid its live data contract behind `any`**
   - Risk: future reward/config changes become harder to review and easier to break silently.
   - Fix: added explicit route-local types for quest definition loading, quest formatting, and locked claim rows.

## Verification

- targeted backend `eslint`:
  - `src/app/api/inventory/equip/route.ts`
  - `src/app/api/inventory/unequip/route.ts`
  - `src/app/api/mail/route.ts`
  - `src/app/api/quests/daily/route.ts`
  - `tests/api/inventory-equip.test.ts`
  - `tests/api/inventory-unequip.test.ts`
  - `tests/api/mail-list.test.ts`
- targeted backend `vitest`:
  - `tests/api/inventory-equip.test.ts`
  - `tests/api/inventory-unequip.test.ts`
  - `tests/api/mail-list.test.ts`
- full backend `npx vitest run`
- `npm run build` in `backend/`
- `git diff --check`

## Follow-up

- `social/*`, `shell-game/*`, and a few shared gameplay helpers are now the next obvious warning-heavy backend block.
- `inventory/equip` and `inventory/unequip` now share the right transaction boundary, but they still deserve dedicated race-focused tests if the inventory mutation layer gets refactored again.
