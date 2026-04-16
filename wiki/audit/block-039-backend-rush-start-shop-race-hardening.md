---
title: Block 039 — Backend rush start/shop race hardening
category: audit
tags: [audit, backend, dungeon-rush, pvp, dungeons, shop, concurrency]
sources:
  - backend/src/app/api/dungeon-rush/start/route.ts
  - backend/src/app/api/dungeon-rush/shop-buy/route.ts
  - backend/src/app/api/dungeons/start/route.ts
  - backend/src/app/api/pvp/find-match/route.ts
  - backend/src/app/api/pvp/prepare/route.ts
  - backend/src/app/api/shop/buy-gems/route.ts
  - backend/src/lib/game/dungeon-run-lock.ts
updated: 2026-04-15
status: Fixed
---

# Block 039 — Backend rush start/shop race hardening

## Scope

- `backend/src/app/api/dungeon-rush/start/route.ts`
- `backend/src/app/api/dungeon-rush/shop-buy/route.ts`
- `backend/src/app/api/dungeons/start/route.ts`
- `backend/src/app/api/pvp/find-match/route.ts`
- `backend/src/app/api/pvp/prepare/route.ts`
- `backend/src/app/api/shop/buy-gems/route.ts`
- `backend/src/lib/game/dungeon-run-lock.ts`

## Why this block

This started as a warning-cleanup pass around start/shop routes, but the deeper read found two real concurrency bugs in the Dungeon Rush runtime:

1. `rush-start` checked for an active rush run before the transaction, then created a new run inside the transaction without rechecking under the character-row lock.
2. `rush-shop-buy` validated run state and purchased slots outside the transaction, then only locked the user row for gold deduction.

Both issues could let parallel requests spend resources twice against stale pre-transaction state.

## File notes

### `backend/src/app/api/dungeon-rush/start/route.ts`

- **Zone:** backend / dungeon rush
- **Purpose:** resumes an active rush or creates a new one after charging stamina
- **What it does now:** locks the character row first, checks for an active rush run inside the transaction, resumes safely if present, deletes only truly legacy runs, and only then deducts stamina + creates a fresh run
- **Problem found:** duplicate parallel `/start` requests could both miss the pre-transaction active-run check and create/spend twice
- **What was fixed:** moved active-run resolution inside the locked transaction and returned either a `resumed` or `created` result from one atomic path
- **Status:** Fixed

### `backend/src/app/api/dungeon-rush/shop-buy/route.ts`

- **Zone:** backend / dungeon rush / shop
- **Purpose:** buys one shop slot during a rush
- **What it does now:** locks the run row and user row inside one transaction, revalidates the room type and purchased slots from the locked run snapshot, deducts gold, and updates the run state atomically
- **Problem found:** duplicate parallel purchase requests could both pass the stale pre-transaction slot check and charge gold twice
- **What was fixed:** moved run-state validation and run update under `lockDungeonRunForUpdate(...)`
- **Status:** Fixed

### `backend/src/app/api/dungeons/start/route.ts`

- **Zone:** backend / standard dungeons
- **Purpose:** starts a non-rush dungeon run
- **Problem found:** stale unused imports from the older hardcoded floor generator path
- **What was fixed:** removed dead imports while keeping the DB-backed fallback path intact
- **Status:** Fixed

### `backend/src/app/api/pvp/find-match/route.ts`

- **Zone:** backend / PvP matchmaking
- **Purpose:** returns the best nearby opponents by level and gear proximity
- **Problem found:** `candidates` was mutable only because it reused the original query array
- **What was fixed:** made it an explicit copied array and kept the later merge logic unchanged
- **Status:** Fixed

### `backend/src/app/api/pvp/prepare/route.ts`

- **Zone:** backend / PvP prepare
- **Purpose:** prepares the authoritative fight payload before resolve
- **Problem found:** stale unused live-config imports remained from an older reward surface
- **What was fixed:** removed the dead imports
- **Status:** Fixed

### `backend/src/app/api/shop/buy-gems/route.ts`

- **Zone:** backend / shop
- **Purpose:** converts account gold into gem packs via catalog IDs
- **Problem found:** unused catalog guard import
- **What was fixed:** removed the dead import
- **Status:** Fixed

## Problems found

1. **Rush start race**
   - Risk: duplicate active rush runs and double stamina spending under parallel taps/retries.
   - Fix: recheck active rush inside the locked transaction.

2. **Rush shop double-charge race**
   - Risk: the same slot could be bought twice before `shopPurchased` was committed.
   - Fix: lock the run row and validate slot purchase state from the locked snapshot.

3. **Small dead-code drift in adjacent start/match/shop routes**
   - Risk: warning noise hides the real problems and makes later audits slower.
   - Fix: remove the dead imports/mutable locals while touching the same slice.

## Verification

- targeted backend `eslint` on the touched routes
- `git diff --check`

## Follow-up

- `dungeon-rush/start` still serializes resume/create through the character row rather than a dedicated uniqueness constraint on active rush runs; that is safe enough for now, but a DB uniqueness rule would make the invariant stronger.
