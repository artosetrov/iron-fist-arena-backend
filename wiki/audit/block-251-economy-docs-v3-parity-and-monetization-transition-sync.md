---
title: Audit Block 251 — Economy Docs V3 Parity and Monetization Transition Sync
category: audit
tags: [audit, docs, economy, balance, monetization]
sources:
  - docs/02_product_and_features/ECONOMY.md
  - docs/06_game_systems/BALANCE_CONSTANTS.md
  - backend/src/lib/game/balance.ts
  - backend/src/app/api/minigames/gold-mine/boost/route.ts
  - backend/src/lib/game/premium.ts
  - Hexbound/Hexbound/Views/Shop/PremiumPurchaseView.swift
updated: 2026-04-29
status: Fixed
---

# Audit Block 251 — Economy Docs V3 Parity and Monetization Transition Sync

## Scope

- `docs/02_product_and_features/ECONOMY.md`
- `docs/06_game_systems/BALANCE_CONSTANTS.md`
- verification against:
  - `backend/src/lib/game/balance.ts`
  - `backend/src/app/api/minigames/gold-mine/boost/route.ts`
  - `backend/src/lib/game/premium.ts`
  - `Hexbound/Hexbound/Views/Shop/PremiumPurchaseView.swift`

## Why this block

The active economy docs had drifted in two directions at once:

- `ECONOMY.md` still framed the live system as “Economy v2” and listed stale premium / gem-sink values
- `BALANCE_CONSTANTS.md` already knew about several v3 changes at the top, but its narrative tables still contradicted those same changes lower in the file
- monetization transition truth was split: backend/runtime already carries `premium_pass_monthly` and subscription entitlement logic, while the iOS premium storefront copy is still mostly one-time-premium language

That left the docs arguing with code on concrete player-facing facts like:

- `Upgrade Protection` cost (`40`, not `50`)
- `Battle Pass Premium` cost (`700`, not `500`)
- `Gold Mine Boost` cost/effect (`15`, reward doubler, not a timer skip)
- disabled flat gold packs
- `Monthly Gem Card` total (`350`, not `500`)
- win/loss streak caps, CHA cap, upgrade chances, stamina cap, and free-PvP summary values

## Fix applied

- rewrote `ECONOMY.md` to present the current system as live Economy v3, while keeping older v2 / W3.D3 sections explicitly historical
- updated `ECONOMY.md` gem-sink table to the live values from `balance.ts`
- replaced live-looking flat `Gold Packs` wording with a disabled/legacy section and added the live Adventurer's Bundles replacement
- clarified premium transition in `ECONOMY.md`:
  - `Premium Forever` is legacy / grandfathered
  - `premium_pass_monthly` exists as the successor runtime path
  - storefront rollout is still mixed while older client copy is retired
- synced `BALANCE_CONSTANTS.md` narrative tables with live code for:
  - win streak bonuses
  - loss streak bonuses
  - CHA cap
  - `+9/+10` upgrade success odds
  - gem costs
  - Gold Mine boost semantics
  - inventory max slots
  - Battle Pass premium price
  - stamina/reference summary values
  - monetization summary values
- removed the stale “Phase 2 / currency-only” Adventurer's Bundle note now that bundle extras are already represented in live `IAP_PRODUCTS`

## Result

The two active economy docs now agree with the live v3 constants instead of each other’s older snapshots. They also stop over-simplifying the premium transition: backend/runtime subscription support is real, but the iOS premium storefront language has not fully caught up yet.

## Verification

- repo search against stale values (`125%`, `500 gems`, `10 gems`, `×5 per day`, `500 total`)
- code checks in `balance.ts`, `gold-mine/boost/route.ts`, and `premium.ts`
- `git diff --check`
