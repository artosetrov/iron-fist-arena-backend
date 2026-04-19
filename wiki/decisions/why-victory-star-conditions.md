---
title: "Decision: Victory Stars Show Labelled Conditions, Not a Silent 1-3★ Score"
category: decisions
tags: [ui, ux, victory, stars, dungeons, pvp, progression]
sources: [Hexbound/Hexbound/Views/Components/BattleResultModels.swift, Hexbound/Hexbound/Views/Components/BattleResultSections.swift, Hexbound/Hexbound/Views/Components/BattleResultAnimations.swift, Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift, Hexbound/Hexbound/Views/Combat/CombatResultDetailView.swift]
updated: 2026-04-19
---

# Why Victory Stars Show Labelled Conditions

## Decision

The Victory screen's three-star row is now a set of **named `StarCondition` slots**, not an opaque 1–3★ score. Every slot — earned or missed — is rendered with its label so the player can see *why* they got the stars they got, and what they need to try next time.

Applies to **both** Dungeon victory (`DungeonVictoryView`) and PvP / Arena victory (`CombatResultDetailView`).

## Star conditions

### Dungeon (derived from `hpFractionAfterBattle`)
1. **Claim victory** — always earned on the win path
2. **Stay above 50% HP** — `hpFraction > 0.5`
3. **Flawless (75%+ HP)** — `hpFraction > 0.75`

### PvP / Arena (derived from `CombatData.combatLog`)
1. **Claim victory** — always earned on the win path
2. **Stay above 50% HP** — `(playerMaxHp − damageTaken + playerHeals) / playerMaxHp > 0.5`
3. **Land a critical hit** — any `combatLog` entry where `attackerId == player.id && isCrit == true`

## Why client-side derivation (for now)

The backend currently returns only aggregate result data (`isWin`, `xpReward`, `goldReward`, `ratingChange`, `leveledUp`, etc.) — no per-condition breakdown array. Both screens already have access to the inputs needed to compute the conditions client-side:
- Dungeon: `DungeonRoomViewModel.hpFractionAfterBattle`
- PvP: `CombatData.combatLog` plus `player.maxHp`

Deriving on the client avoids a schema change on a surface that is UI flourish, not reward authority. Stars do **not** affect gold/XP/rating — they are a retention / replayability hook. If stars ever drive rewards, the breakdown must move server-side.

## Animation

Reveals happen after the title slams in (0.5s offset, 0.28s stagger per slot).

- **Earned**: rotation −60° → 0°, offset y −24 → 0, opacity 0 → 1, gold shadow + post-reveal `glowPulse`, `HapticManager.medium()`
- **Missed**: fade-in only (no rotation/drop, no glow), `HapticManager.light()`
- **No `.scaleEffect`** — per `Hexbound/CLAUDE.md` Animation Rules, reveal motion uses opacity/rotation/offset only. Scale is reserved for particle effects.

## Tradeoffs

**Pros:**
- Readable — player instantly sees what they missed; the third star reads as a goal, not a mystery.
- Drives replayability — `Flawless` and `Land a critical hit` are explicit "come back and try for it" hooks.
- Same component works for PvP and PvE — one shared `StarCondition[]` contract.

**Cons:**
- Client-derived conditions can drift from server reward logic if rewards ever start depending on them. Mitigation: today stars are purely visual; a future server-authoritative breakdown would replace the derive step with a response field.
- Three-slot visual rhythm assumes exactly three conditions per screen. Adding a fourth tier would require layout rework (the current `HStack` is sized to fit three comfortably at 390pt width).

## Implementation notes

- `StarCondition { label, earned }` in `BattleResultModels.swift`.
- `BattleResultConfig.starConditions: [StarCondition]?` replaces the old `starRating: Int?` scalar. Legacy `starRating` field is gone — both call sites migrated.
- `victoryStarsView(conditions:)` in `BattleResultSections.swift` renders `HStack` of `victoryStarSlot(condition:index:)` cells — star + label stacked vertically, `minHeight: icon2XL + 40`.
- Reveal sequence in `BattleResultAnimations.swift` iterates **all** slots (so missed stars animate in too) and dispatches a differentiated haptic per `cond.earned`.

## See Also

- [[dungeons]] — Dungeon Victory screen consumer
- [[pvp-combat]] — PvP/Arena Victory screen consumer
- [[why-reward-modal-over-toast]] — sibling decision on how earn-points surface reward ceremonies
- [[design-principles]] — 3-second rule, no dead ends
