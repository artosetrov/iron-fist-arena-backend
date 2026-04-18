---
title: block-168-backend-character-progression-derived-stats-transaction-parity
category: audit
tags: [audit, backend, progression, stats, transactions]
sources:
  - backend/src/app/api/characters/[id]/allocate-stats/route.ts
  - backend/src/app/api/characters/[id]/buy-stat-points/route.ts
  - backend/src/app/api/characters/[id]/respec-stats/route.ts
  - backend/src/app/api/prestige/route.ts
  - backend/src/lib/game/equipment-stats.ts
  - backend/tests/api/character-progression-derived-stats.test.ts
  - wiki/audit/block-038-backend-utility-routes-and-character-warning-cleanup.md
updated: 2026-04-17
---

# Block 168 - backend character progression derived-stats transaction parity

## Why this block exists

Several adjacent progression routes still shared the same unsafe pattern:

- mutate base progression state in a transaction
- commit successfully
- call `recalculateDerivedStats(...)` only afterwards
- return `500` if the recomputation step failed

That meant the player-facing write had already happened, but the route could still surface as a failure after commit. The risk had already been noted earlier for `respec-stats`, and the same shape was still present in:

- stat allocation
- bought stat points
- prestige

We already had a safer local precedent in equipment routes, where derived stats are recalculated inside the same transaction.

## What changed

### `backend/src/app/api/characters/[id]/allocate-stats/route.ts`

- moved `await recalculateDerivedStats(id, tx)` inside the write transaction, directly after the stat update
- cache invalidation remains post-commit

### `backend/src/app/api/characters/[id]/buy-stat-points/route.ts`

- moved `await recalculateDerivedStats(id, tx)` inside the purchase transaction after character + wallet mutation
- removed the old post-transaction recompute call

### `backend/src/app/api/characters/[id]/respec-stats/route.ts`

- moved `await recalculateDerivedStats(id, tx)` inside the respec transaction after stat reset + gem deduction
- removes the old “commit succeeded but recompute failed later” gap recorded in [[block-038-backend-utility-routes-and-character-warning-cleanup]]

### `backend/src/app/api/prestige/route.ts`

- moved `await recalculateDerivedStats(character_id, tx)` inside the prestige transaction after prestige state reset and passive wipe
- keeps prestige bonus recomputation coupled to the prestige write itself

### `backend/tests/api/character-progression-derived-stats.test.ts`

- added focused regression coverage for all four routes
- each test verifies `recalculateDerivedStats(..., tx)` is called with the live transaction client, not after commit

## Result

These progression routes now follow the same transactional derived-stat standard as equipment mutation routes:

- if recomputation fails, the progression write does not commit
- successful commits no longer have a second chance to masquerade as a server failure
- combat-cache invalidation remains post-commit where it belongs

## Verification

- `cd backend && npx vitest run tests/api/character-progression-derived-stats.test.ts`
- `cd backend && npx eslint 'src/app/api/characters/[id]/allocate-stats/route.ts' 'src/app/api/characters/[id]/buy-stat-points/route.ts' 'src/app/api/characters/[id]/respec-stats/route.ts' 'src/app/api/prestige/route.ts' tests/api/character-progression-derived-stats.test.ts`
- `cd backend && npm run build`
- `git diff --check`

All passed after this change.
