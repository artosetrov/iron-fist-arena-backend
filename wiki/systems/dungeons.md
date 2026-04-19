---
title: Dungeons
category: systems
tags: [pve, dungeons, dungeon-rush, bosses, victory-stars]
sources: [docs/02_product_and_features/GAME_SYSTEMS.md, Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift]
updated: 2026-04-19
---

# Dungeons

Two PvE modes: structured Dungeons and endless Dungeon Rush.

## Dungeons (Structured)

- 10 floors, 4 difficulties
- Difficulty scaling: 1× → 2.5×
- Boss at each floor end
- Stamina cost: 15–25 per run

## Victory Stars (UI flourish, not a reward gate)

After each boss win the Victory screen shows three labelled `StarCondition` slots. Conditions are derived client-side from `DungeonRoomViewModel.hpFractionAfterBattle` — they do **not** affect gold/XP drops.

1. **Claim victory** — always earned on the win path
2. **Stay above 50% HP** — `hpFraction > 0.5`
3. **Flawless (75%+ HP)** — `hpFraction > 0.75`

Both earned and missed slots render with their label, so the player can see what the third star asks of them. Rationale and animation contract: [[why-victory-star-conditions]].

## Dungeon Rush (Endless)

- Infinite floors with escalating difficulty
- Shop between rounds (buy buffs, heal)
- Exponential reward scaling
- Artifacts: stat boosts, gold/XP multipliers that persist within the run
- Run ends on death — no continues

Design intent: high-risk/high-reward mode for experienced players. The shop creates interesting resource management decisions. Exponential rewards mean deep runs are disproportionately valuable.

## Boss Reveal Ceremony

Root-level ceremonial overlay introducing new bosses. Fires from two places:

- **Dungeons** — once per real boss, on first open of a `.current` boss card in `BossDetailSheet`. Gated by `UserDefaults["bossRevealSeen_<name>_<id>"]`. Practice enemies (Training Camp dummies, `isRealBoss == false`) are excluded. CTA dismisses the overlay; the player lands back on `BossDetailSheet` and chooses to commit.
- **Dungeon Rush** — every run, when the `miniboss` room becomes the current room. Compact ~1.2s choreography. CTA fires `vm.fight()` directly — no browse step.

Component: `Hexbound/Hexbound/Views/Components/BossRevealOverlayView.swift`. DTO: `BossRevealData` (decouples overlay from `BossInfo` / `RushRoom`). Mounted in `HexboundApp.swift` at `zIndex: 170` between DailyLogin (150) and HeroForge (200). Driven by `AppState.pendingBossReveal` + `isBossRevealing`.

Rationale and cadence choices (once-per-boss vs per-run, CTA behaviour, DS mapping): [[why-boss-reveal-ceremony]].

## See Also

- [[combat]]
- [[progression]] (drop rates)
- [[economy]] (dungeon gold)
- [[why-boss-reveal-ceremony]]
