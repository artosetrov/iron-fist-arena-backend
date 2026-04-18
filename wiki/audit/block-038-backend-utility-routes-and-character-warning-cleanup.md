---
title: Block 038 — Backend utility routes and character warning cleanup
category: audit
tags: [audit, backend, routes, characters, cleanup]
sources:
  - backend/src/app/api/characters/[id]/appearance/route.ts
  - backend/src/app/api/characters/[id]/respec-stats/route.ts
  - backend/src/app/api/combat/simulate/route.ts
  - backend/src/app/api/design-tokens/route.ts
  - backend/src/app/api/events/active/route.ts
  - backend/src/app/api/iap/products/route.ts
  - backend/src/app/api/minigames/shell-game/play/route.ts
updated: 2026-04-17
status: Fixed
---

# Block 038 — Backend utility routes and character warning cleanup

## Scope

- `backend/src/app/api/characters/[id]/appearance/route.ts`
- `backend/src/app/api/characters/[id]/respec-stats/route.ts`
- `backend/src/app/api/combat/simulate/route.ts`
- `backend/src/app/api/design-tokens/route.ts`
- `backend/src/app/api/events/active/route.ts`
- `backend/src/app/api/iap/products/route.ts`
- `backend/src/app/api/minigames/shell-game/play/route.ts`

## Why this block

This slice came up from the production build warning list. The warnings themselves were mostly small, but they were sitting in user-facing runtime files, so this was a good place to do a careful pass instead of treating them as pure lint noise.

The result was mixed:

- several files only needed safe dead-code cleanup
- two character routes were worth documenting more carefully because they still carry behavior and architecture questions beyond the warning itself

## File notes

### `backend/src/app/api/characters/[id]/appearance/route.ts`

- **Zone:** backend / character customization
- **Purpose:** changes origin, gender, and avatar, and charges gold when the origin changes
- **What it does:** locks user + character rows, validates the chosen avatar against the skin catalog, recalculates origin-based stats when needed, deducts gold for origin changes, and returns the updated character payload
- **Depends on:** auth, Prisma transaction locks, `appearanceSkin` catalog, origin/gender enums
- **Used by:** character customization client flows
- **Problems found:**
  - dead local `updatedUser` variable after the gold deduction
  - user-facing error text still said “change race” while the route now works in terms of `origin`
  - the route still mixes wallet data into the returned `character` object shape, which is convenient for clients but muddles entity boundaries
- **What was fixed:** removed the dead variable, aligned the error text to `origin`, and later added a canonical top-level `wallet.gold` field while keeping `character.gold` as a compatibility alias for existing callers
- **Later follow-up:** re-audited in [[block-170-backend-appearance-wallet-response-boundary]]; the route now exposes a clean wallet boundary without breaking the existing iOS decode path
- **Status:** Fixed

### `backend/src/app/api/characters/[id]/respec-stats/route.ts`

- **Zone:** backend / character progression
- **Purpose:** resets allocated stats to origin-adjusted base values and refunds the spent points for gems
- **What it does:** validates ownership and gems, calculates base stats from origin bonuses, refunds allocated points, charges gems, then recalculates derived stats and invalidates combat caches
- **Depends on:** auth, rate limit, Prisma, derived-stat recomputation, combat cache invalidation
- **Used by:** stat-respec client flow
- **Problems found:**
  - dead constants `STAT_POINTS_PER_LEVEL` and `INITIAL_STAT_POINTS`
  - post-transaction `recalculateDerivedStats(...)` and cache invalidation are still outside the transaction, so a downstream failure can turn a successful respec into a `500` response even though the respec already committed
- **What was fixed:** removed the dead constants
- **Later follow-up:** re-audited in [[block-168-backend-character-progression-derived-stats-transaction-parity]]; derived-stat recomputation now runs inside the same transaction as the stat reset
- **Status:** Fixed

### `backend/src/app/api/combat/simulate/route.ts`

- **Zone:** backend / deprecated compatibility route
- **Purpose:** hard-deprecates the old simulate endpoint and points callers to `/api/pvp/fight`
- **What it does:** always returns `410`
- **Problems found:** unused request parameter/import only
- **What was fixed:** removed the unused request parameter/import
- **Status:** Fixed

### `backend/src/app/api/design-tokens/route.ts`

- **Zone:** backend / design-system support
- **Purpose:** exposes persisted design tokens from the `designToken` table
- **What it does:** returns the `global` token row or `{ tokens: {} }`
- **Problems found:** unused request parameter/import only
- **What was fixed:** removed the unused request parameter/import
- **Status:** Fixed

### `backend/src/app/api/events/active/route.ts`

- **Zone:** backend / events
- **Purpose:** returns currently active events based on time window and `isActive`
- **What it does:** queries active events ordered by `startAt`
- **Problems found:** unused request parameter/import only
- **What was fixed:** removed the unused request parameter/import
- **Status:** Fixed

### `backend/src/app/api/iap/products/route.ts`

- **Zone:** backend / monetization catalog
- **Purpose:** returns the filtered IAP product catalog for new purchases
- **What it does:** hides `enabled === false` products while preserving them in the source catalog
- **Problems found:** unused request parameter/import only
- **What was fixed:** removed the unused request parameter/import
- **Status:** Fixed

### `backend/src/app/api/minigames/shell-game/play/route.ts`

- **Zone:** backend / deprecated compatibility route
- **Purpose:** blocks the legacy one-step shell game flow
- **What it does:** always returns `410` and points callers at `/start` + `/guess`
- **Problems found:** unused request parameter/import only
- **What was fixed:** removed the unused request parameter/import
- **Status:** Fixed

## Verification

- targeted backend `eslint` on the touched routes
- `git diff --check`

## Follow-up

- `respec-stats` still deserves a deeper runtime pass around post-transaction recomputation semantics
- `appearance` still carries a temporary compatibility alias (`character.gold`) for older callers even though `wallet.gold` is now the canonical boundary
