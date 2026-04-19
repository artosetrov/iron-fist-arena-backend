---
title: ADR — Balance v3.2 proposals (from Audit 2026-04-17)
status: Proposed — pending product review
date: 2026-04-19
owner: Audit 2026-04-17 (P5)
supersedes: —
---

# ADR — Balance v3.2 proposals

## Context

Audit 2026-04-17 Zone 8 (Game Systems) flagged three balance issues with
concrete numbers but did **not** apply them because production balance
changes must satisfy `docs/06_game_systems/ECONOMY_RULES.md` R1–R19 and be
validated against `scripts/economy-simulator` before shipping. This ADR is
the write-up; no `balance.ts` changes attached.

## Proposal 1 — Reduce legendary repair cost rarity multiplier (5.0× → 3.5×)

### Observed

- L50 PvP win: **444g** (150 base × 2.96× scaling)
- L50 legendary full-set repair: **~5,500g** (120 + 49 × 20 per item × 5 rarity × 5 items)
- Ratio: **12.4×** — one PvP win covers 8% of a single repair cycle.
- Post-durability-audit, sink ratio sits at 70.4% (healthy target 65–75%),
  but anecdotal "logout anxiety" surfaces at L50 when players defer PvP
  until they can afford the next repair.

### Proposed change

- `REPAIR.RARITY_MULTIPLIERS.legendary`: `5.0 → 3.5`
- Keep other rarities unchanged.
- L50 legendary item repair: 5,500g → **3,850g** (-30%).
- Full-set repair: ~27,500g → ~19,250g.

### Expected impact

- Sink ratio: 70.4% → **~66%** (still healthy, closer to floor).
- Active-player net income per day at L40: +800g (buys one extra +8→+9
  upgrade attempt every ~3 days).
- Does NOT affect rare/epic repair, so low-leverage segment (early-mid game)
  is unchanged.

### Validation gate

Run `economy-simulator` cohort projection for 30 days with the new
multiplier. Need: sink ratio in [60%, 75%], no runaway gold inflation in
top-1% cohort, no new soft-lock path for F2P L50+.

### R-rules touched

- R2 (progression gates) — unchanged
- R8.cap (stamina) — unchanged
- R9 (currency sinks) — **affected**; needs simulator green light

---

## Proposal 2 — F2P gem income buff (Gold Mine 10% → 15% drop rate)

### Observed

- F2P monthly gems: **~217** (100 login + 25 BP free + 90 mine drops)
- Cost of 1× daily stamina refill: **1,500 gems/month** (50g × 30)
- Shortfall: **7×** — F2P can afford refills ~once per 10 days, not daily.
- Battle Pass Premium (700g in Economy v3) costs 25–35 days of F2P gem
  income — premium adoption funnel is bottlenecked by gem scarcity, not
  intrinsic interest.

### Proposed change

- `GOLD_MINE.GEM_DROP_CHANCE`: `0.10 → 0.15` (+50% relative)
- `GOLD_MINE.GEM_DROP_RANGE`: `[1, 3] → [1, 4]` inclusive (widens upper bound)

### Expected impact

- F2P monthly gems: 217 → **~280** (+29%)
- Still 5× short of daily refill cost — pressure on refill purchase
  preserved.
- BP Premium reachable in ~20 days F2P grinding vs 25–35 previously —
  materially improves F2P→paying-user conversion funnel.

### Validation gate

- Simulator: ensure daily gem inflation per DAU < 5 (current: ~3.2).
- Monitor over 30 days post-change: if IAP gem-pack conversion drops >
  15% relative, revert. (Hypothesis: ARPDAU goes UP because BP Premium
  becomes reachable and BP buyers spend 3–4× non-buyers.)

### R-rules touched

- R10.3 (bundle economy) — unchanged; these still beat mine drops
- R13 (minigame yield) — **affected**; needs telemetry baseline before
  and after

---

## Proposal 3 — First-dungeon-clear-of-day 2× gold (parity with PvP first win)

### Observed

- PvP dominance over PvE at retention tails:
  - L25 PvP win (first of day): 294 × 2 = 588g
  - L25 10-floor dungeon clear: 300g
- Dungeons take 5–8× longer per clear than a PvP match.
- Content-mix telemetry (ad-hoc SQL 2026-03-28): 68% of active-player
  stamina spend goes to PvP, 14% to dungeons. Target per
  `ECONOMY_RULES.md` R6: 45/40 PvP/PvE.

### Proposed change

- New constant `FIRST_DUNGEON_CLEAR_BONUS.GOLD_MULT: 2.0` (mirrors
  `FIRST_WIN_BONUS.GOLD_MULT`).
- Applied once per UTC day to the first dungeon completion; tracked via
  existing `firstWinDate` analogue or new `firstDungeonDate` character
  column (R8 DR system already has the pattern).

### Expected impact

- First daily dungeon reward at L25: 300g → **600g**, beats PvP first win
  (588g) by 2%.
- Adds ~200g/day per active player (budget impact: 20k gold × DAU over 100
  days ≈ 200m gold sink — need to absorb via repair / upgrade increase
  OR accept slightly higher inflation).
- W3.D4 training XP DR already throttles endgame dungeon farming, so
  whales can't stack this.

### Validation gate

- Simulator: content-mix shift toward 30/30 PvP/dungeon over 60 days?
  (Target: close the gap by half.)
- Player-facing comms: message-in-app announcing the buff so engagement
  spike attributes correctly.

### R-rules touched

- R3 (reward scaling) — **affected**; new bonus multiplier
- R6 (content-mix target) — the explicit knob

---

## Ordering

Recommended rollout:

1. **Proposal 3 first** (content-mix fix — lowest risk, highest
   engagement upside, runs independent of gem/gold sink economy).
2. **Proposal 2 next** (gem drop buff — F2P quality of life + premium BP
   funnel).
3. **Proposal 1 last** (repair cost cut — only after proposal 2 has
   shown no gem-pack revenue cliff; repair cost reduction is the
   easiest to reverse).

Each landing should go through the standard balance-review loop:
`economy-simulator → PR → 1-week staging cohort → ship`.

## Rollback

All three are single-line changes in `balance.ts`. Reversion takes 5
minutes + admin live-config override (`gold_mine.gem_drop_chance` key)
for proposal 2 — no DB migration needed.

## References

- Audit 2026-04-17 Zone 8 findings
- `docs/06_game_systems/BALANCE_CONSTANTS.md`
- `docs/06_game_systems/ECONOMY_RULES.md` (R1–R19)
- `scripts/economy-simulator/` (validation harness)
