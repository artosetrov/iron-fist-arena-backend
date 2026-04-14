---
title: "Decision: Auto-Generated Balance Docs"
category: decisions
tags: [balance, docs, automation, drift, ci]
sources: [docs/retro/RETRO_2026-04-10.md]
updated: 2026-04-14
---

# Why Auto-Generated Balance Docs

## Decision

`BALANCE_CONSTANTS_AUTO.md` is auto-generated from `balance.ts`. CI guard `check_ios_backend_drift.sh` catches iOS ↔ backend constant drift.

## Problem

Manual balance docs drifted from code after every rebalance. Docs said `freePvpPerDay = 5` while code had 3. iOS hardcoded `maxStamina = 120` while backend had 180. Players saw different numbers in-game vs what docs promised.

The 2026-04-10 CRIT was caused by exactly this: iOS showed wrong free PvP count after a balance change because the constant was hardcoded client-side.

## Solution

1. **Auto-generate** `BALANCE_CONSTANTS_AUTO.md` from `balance.ts` on every build
2. **CI guard** diffs iOS constants against backend — fails the build on mismatch
3. **iOS reads from server config** (`GameConfig`) at runtime, not hardcoded values

## Tradeoffs

**Pros:** Single source of truth. Zero manual maintenance. Drift caught before deploy.

**Cons:** Auto-generated docs are less readable than hand-written. Requires CI infrastructure.

## See Also

- [[design-principles]] (single source of truth)
- [[bug-patterns]] (iOS ↔ backend constant drift)
- [[rebalance-w3d3]]
