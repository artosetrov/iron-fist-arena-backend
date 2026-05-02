---
title: PvP Rating (ELO)
category: systems
tags: [pvp, elo, rating, matchmaking, ranks]
sources: [docs/06_game_systems/COMBAT.md, docs/06_game_systems/BALANCE_CONSTANTS.md]
updated: 2026-04-29
---

# PvP Rating System

ELO-based rating with calibration phase.

## Constants

- Starting rating: 1000
- K-factor (calibration, games 1–10): **48**
- K-factor (post-calibration): **32**
- Revenge gold multiplier: **1.5×**
- Free PvP fights per day: **3**
- Stamina cost per fight: **10**

## Rank Ladder

| Rank | Rating Range |
|------|-------------|
| Bronze | 0–749 |
| Silver | 750–1,499 |
| Gold | 1,500–2,249 |
| Platinum | 2,250–2,999 |
| Diamond | 3,000–3,749 |
| Master | 3,750–4,249 |
| Grandmaster | 4,250+ |
| Challenger | 4,250+ **AND** top-100 leaderboard |

**Note:** Achievement rank ceilings were corrected — Diamond 1800→3000, Grandmaster 2200→4250.

## Design Decisions

- High K-factor during calibration (48) creates dramatic early swings — intentional, makes first 10 games exciting
- Challenger requires both rating AND leaderboard position — prevents inactive high-rated players from holding title
- Revenge multiplier (1.5×) encourages rematches without being exploitable (one revenge per loss)

## Resolve API contract

`/api/pvp/resolve` exposes the full rating delta on every result for both
PvP and bot fights:

- `rating_change` — signed delta applied to the attacker's rating.
- `rating_before` — attacker's rating *before* the fight (= `attacker.pvpRating`).
- `rating_after` — attacker's rating *after* the fight (= `attackerNewRating`).

The absolute pair was added 2026-04-29 (Combat V2 D-1) so the iOS END-screen
`RewardsBlock` can render *delta + new total* (`+24 / 1248`) instead of
delta-only. Bot fights surface the pair too so the iOS view does not branch
on opponent type.

`rating_before` / `rating_after` are also stored on the `PvpMatch` record
itself (`player1RatingBefore` / `player1RatingAfter` /
`player2RatingBefore` / `player2RatingAfter`) — that pair is the source for
PvP history responses and battle-mail rating cards. The resolve response
just surfaces the attacker-perspective view of the same numbers.

Plumbing audit: `block-275-backend-pvp-resolve-rating-bounds-parity`.

## See Also

- [[combat]]
- [[economy]] (PvP gold rewards)
- [[why-k-factor-48]]
