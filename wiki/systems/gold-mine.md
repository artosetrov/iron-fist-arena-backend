---
title: Gold Mine
category: systems
tags: [minigames, gold-mine, passive-income, slots]
sources: [Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift, backend/src/lib/game/gold-mine-expedition.ts, docs/06_game_systems/BALANCE_CONSTANTS.md]
updated: 2026-10-16
---

# Gold Mine

Passive income system. No stamina cost. Timer-based slots.

## Slot Mechanics

- **Slots:** start with 1, buy up to **3** (`MAX_GOLD_MINE_SLOTS`)
- **Buy extra slot:** 50 gems each (server-configurable)
- **Lifecycle:** `idle` → `mining` (4h timer) → `ready` (collect)
- Per-slot stats tracked: `totalGoldMined`, `sessionsCompleted`, `bestHaul`, `currentStreak`

## Rewards

- A cart (one 4 h run) brings **40–100 gold**, with a **10% chance of 1–3 gems**; the amount is revealed when it is ready
- Double haul (boost): **15 gems** (live config) — doubles that cart's gold and gems; works while mining or ready
- Everything the screen prints (ranges, prices, chest, bonus terms) comes from the `economy` block of `GET /status`

## Expedition chest (2026-10-16)

- Every collected cart is one haul — single collect and Collect All count the same
- **5 hauls** open the chest: **150 gold + 2 gems** (`gold-mine-expedition.ts`); extra carts carry over
- The next expedition starts on its own — no shaft picker (shafts only change the bonus-round backdrop)

## Bonus round (optional)

- 60 s coin rush per cart; up to +15% gold at mine level 1 (+19% at level 3), plus 1 gem at ≥75% catch
- Never required: a ready cart is collected whether or not it was played

## Collection Flow

1. Send a cart → optimistic (cart starts riding the rails), API in background
2. Timer ends → the screen asks `/status` once for the revealed haul
3. **Collect one** — cart empties, "+N" over the tunnel; the modal appears only if the chest opened
4. **Collect All** (2+ full carts) — drains every full cart; reward modal, chest opened by tap when the expedition fills

## Screen (2026-10-16 rework)

- Surface: head-frame art + Mine Foreman with a live line (full carts, empty tunnel, next cart time); tap him for tips
- Expedition track: 5 cart stops + chest
- Shaft: one tunnel level per slot down a ladder; empty cart parked = send, cart riding = mining, full cart = collect; sealed level (padlock) while under the slot cap
- Removed: fake gold/hour numbers, live coin flights, shaft picker, per-card stats grid

## Design Intent

Targets casual players who can't commit to PvP sessions. Rewards daily login without combat. **No stamina cost** — pure time-gated passive income.

Gold mine boost price raised 3→15 gems in [[rebalance-w3d3]] — was essentially free, no real decision involved.

## See Also

- [[economy]] (passive income)
- [[stamina]] (mine is stamina-free)
- [[minigames]]
