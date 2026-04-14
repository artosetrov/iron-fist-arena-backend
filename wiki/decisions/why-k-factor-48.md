---
title: "Decision: K-factor 48 for Calibration"
category: decisions
tags: [pvp, elo, rating, matchmaking, calibration]
sources: [backend/src/lib/game/balance.ts, backend/src/lib/game/elo.ts, docs/06_game_systems/COMBAT.md]
updated: 2026-04-14
---

# Why K-factor 48 for Calibration

## Decision

K=48 for the first 10 games (calibration), then K=32 permanently.

## Rationale

Higher K during calibration **accelerates rating convergence** for new players. A new player's first 10 games shouldn't lock them into an inaccurate rating.

- K=48 means a single win/loss shifts rating by ~30–40 points (vs ~20–25 at K=32)
- After 10 games, players land within ~100 points of their true skill
- K=32 post-calibration is the industry standard (used by FIDE chess, many games)

## Why Not Higher?

K=64 (used by some games) creates too much volatility — a bad streak of 3 games could drop you 200+ points, which feels punishing and random. K=48 is aggressive enough to calibrate fast without causing ladder anxiety.

## Why Not Lower?

K=32 from the start means ~20 games to find true rating instead of ~10. New players stuck in wrong brackets for too long will churn — especially if a Diamond-skill player is grinding through Bronze for their first 20 games.

## Implementation

```typescript
// backend/src/lib/game/elo.ts
const K = gamesPlayed < CALIBRATION_GAMES ? 48 : 32;
```

`CALIBRATION_GAMES = 10` in `balance.ts`.

## See Also

- [[pvp-rating]]
- [[combat]]
