---
title: Gold Mine
category: systems
tags: [minigames, gold-mine, passive-income, slots]
sources: [Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift, docs/06_game_systems/BALANCE_CONSTANTS.md]
updated: 2026-04-14
---

# Gold Mine

Passive income system. No stamina cost. Timer-based slots.

## Slot Mechanics

- **Base slots:** 3
- **Buy extra slot:** 50 gems each (server-configurable)
- **Lifecycle:** `idle` → `mining` (4h timer) → `ready` (collect)
- Per-slot stats tracked: `totalGoldMined`, `sessionsCompleted`, `bestHaul`, `currentStreak`

## Rewards

- Average **70 gold per 4h session** per slot (~0.00486 gold/sec)
- **10% gem drop** chance per session (~0.2 gems per 4h)
- Boost: **15 gems** per slot (was 3) — doubles reward or reduces timer

## Shaft System (Variant D Phase 2)

6 named mines with themes:
- Amethyst Cavern, Emerald Vein, Molten Forge, Frozen Depths, Blood Quarry, King's Treasury

Player chooses shaft before collection. Each shaft has a 15-second bonus minigame round.

## Collection Flow

1. Start mining → optimistic UI (timer starts), API background
2. When timer complete → slot status = `ready`
3. **Collect single slot** — mark idle, display claimed gold
4. **Collect All** — requires bonus minigame completion on at least one ready slot
   - 409 `NO_PLAYABLE_SLOTS` if no slots played bonus yet
5. Reward celebration modal with delta display

## Live Visuals

- Coins emit from active slots as particle animations
- Gems fly separately
- Visual counters tick up in real-time (`LiveMineFlight` system)
- Mining sparkles overlay on active slots (`MiningSparklesOverlay`)

## Design Intent

Targets casual players who can't commit to PvP sessions. Rewards daily login without combat. **No stamina cost** — pure time-gated passive income.

Gold mine boost price raised 3→15 gems in [[rebalance-w3d3]] — was essentially free, no real decision involved.

## See Also

- [[economy]] (passive income)
- [[stamina]] (mine is stamina-free)
- [[minigames]]
