---
title: Audit Block 321 — Project Overview Stamina and Reward Bounds Parity
category: audit
tags: [audit, docs, balance, stamina, source-of-truth]
sources:
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
  - docs/06_game_systems/BALANCE_CONSTANTS.md
  - docs/02_product_and_features/ECONOMY.md
  - wiki/systems/stamina.md
updated: 2026-05-06
status: Fixed
---

# Audit Block 321 — Project Overview Stamina and Reward Bounds Parity

## Scope

This block refreshes the stamina-and-rewards summary slice in
`PROJECT_OVERVIEW.md` so it stops contradicting the current balance-owned
stamina model and stops presenting brittle reward ranges as overview truth.

## Why this block

The old `PROJECT_OVERVIEW.md` section was still carrying stale numbers:

- `Max 120 (upgradeable), regenerates 1/min`
- `PvP matches cost 20 stamina`
- hand-written reward ranges like:
  - `PvP: 50–150 XP + 10–100 gold`
  - `Dungeons: 100–500 XP + 50–500 gold`

The checked-in balance layer already said otherwise:

- `BALANCE_CONSTANTS.md` and `wiki/systems/stamina.md` both describe:
  - max stamina `180`
  - regen `1 per 8 min`
  - first `3` PvP fights free
  - paid PvP cost `10`
- the exact reward values live in the balance/economy docs and are not stable
  enough to keep duplicating casually in the high-level overview

## Changes shipped

- Updated the overview freshness marker to `Last verified against codebase:
  2026-05-06`.
- Replaced the stale stamina snapshot with the current live model:
  - max stamina `180`
  - regen `1 / 8 min`
  - `3` free PvP fights per day, then `10` stamina per match
  - training `5` stamina
  - dungeon costs are difficulty-based
- Replaced the brittle reward-number bullets with a clearer boundary:
  - PvP / dungeons / training use server-authoritative live balance formulas
  - exact current numbers belong to `BALANCE_CONSTANTS.md` and `ECONOMY.md`

## Result

`PROJECT_OVERVIEW.md` no longer claims the old `120 / 1 min / 20 stamina PvP`
model, and it no longer freezes mutable reward numbers into the top-level
overview where they were guaranteed to drift again.
