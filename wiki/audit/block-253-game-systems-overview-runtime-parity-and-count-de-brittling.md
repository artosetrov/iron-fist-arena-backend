---
title: Audit Block 253 — Game Systems Overview Runtime Parity and Count De-Brittling
category: audit
tags: [audit, docs, source-of-truth, gameplay-systems]
sources:
  - docs/02_product_and_features/GAME_SYSTEMS.md
  - docs/02_product_and_features/ECONOMY.md
  - docs/06_game_systems/BALANCE_CONSTANTS.md
  - docs/06_game_systems/COMBAT.md
  - backend/src/lib/game/balance.ts
  - wiki/features/daily-login.md
  - wiki/features/battle-pass.md
  - wiki/features/dungeons.md
  - wiki/features/gold-mine.md
  - wiki/features/passive-tree.md
  - wiki/features/prestige.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 253 — Game Systems Overview Runtime Parity and Count De-Brittling

## Scope

- `docs/02_product_and_features/GAME_SYSTEMS.md`
- verification against the narrower live source-of-truth docs and feature maps

## Why this block

`GAME_SYSTEMS.md` had become a stale hybrid of old product copy, legacy reward
tables, and very specific numeric claims that no longer matched the live repo.

The problem was not one wrong number. It was structural drift:

- PvP still described an older ELO/decay framing
- classic dungeons and Dungeon Rush carried fixed floor/reward tables that were
  too brittle for the current runtime
- skills/passives still described old costs, rank formulas, and respec rules
- inventory, Gold Mine, daily login, battle pass, prestige, and leaderboard
  sections each embedded their own stale mini-source-of-truth
- the file duplicated numbers that already have better homes in:
  - `ECONOMY.md`
  - `BALANCE_CONSTANTS.md`
  - `COMBAT.md`
  - `wiki/features/*.md`

That made `GAME_SYSTEMS.md` expensive to keep correct and likely to drift again
after every economy or runtime change.

## Fix applied

- rewrote `GAME_SYSTEMS.md` into a durable, overview-first system map
- removed brittle legacy tables and exact reward/price/count claims that belong
  in narrower canonical docs
- kept the document focused on:
  - what systems exist
  - how they relate
  - where authority lives
  - which downstream docs own the exact details
- added an explicit source-of-truth handoff near the top:
  - `ECONOMY.md`
  - `BALANCE_CONSTANTS.md`
  - `COMBAT.md`
  - `wiki/features/*.md`
- updated the progression/prestige wording so it no longer over-claims a broad
  shipped client prestige CTA when the current repo shows a narrower reality

## Result

`GAME_SYSTEMS.md` is now useful again as a live orientation document without
pretending to be the canonical home for every numeric tuning table in the game.

The narrower docs keep exact numbers; this file now explains the live gameplay
shape and points readers to the right place for detail.

## Verification

- live file review of:
  - `docs/02_product_and_features/ECONOMY.md`
  - `docs/06_game_systems/BALANCE_CONSTANTS.md`
  - `docs/06_game_systems/COMBAT.md`
  - `backend/src/lib/game/balance.ts`
  - `wiki/features/daily-login.md`
  - `wiki/features/battle-pass.md`
  - `wiki/features/dungeons.md`
  - `wiki/features/gold-mine.md`
  - `wiki/features/passive-tree.md`
  - `wiki/features/prestige.md`
- `git diff --check`
