---
title: Minigames
category: systems
tags: [minigames, gold-mine, shell-game, fortune-wheel, tavern]
sources: [docs/02_product_and_features/GAME_SYSTEMS.md, docs/06_game_systems/BALANCE_CONSTANTS.md]
updated: 2026-04-14
---

# Minigames

Casual gold sinks and passive income. No stamina cost.

## Gold Mine

- 4h mining sessions per slot
- Reward: 40–100g per session
- 10% gem drop chance
- Boost: 15 gems (was 3), doubles reward
- Buy extra slot: 50 gems (max 3 slots)
- **No stamina cost** — passive income

## Shell Game

- Bet range: 50–1,000g
- Payout: 2× on win
- RTP: ~50%
- Pure luck — no skill involved
- Design intent: gold sink disguised as entertainment

## Fortune Wheel

- Spin for random rewards
- Daily free spin + gem spins

## Tavern

- Central hub for minigames
- NPC merchant (MerchantStripView)

## Design Intent

Minigames serve dual purpose:
1. **Gold sinks** (Shell Game, Fortune Wheel) — remove gold from economy
2. **Passive income** (Gold Mine) — reward daily login without combat

The Gold Mine specifically targets casual players who can't commit to PvP sessions. See [[economy]] for sink ratios.

## See Also

- [[economy]]
- [[stamina]] (minigames are stamina-free)
