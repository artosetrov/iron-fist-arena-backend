---
title: Audit Block 320 — Screen Entity Arena Flow Parity
category: audit
tags: [audit, wiki, arena, navigation]
sources:
  - wiki/entities/screens.md
  - docs/07_ui_ux/SCREEN_INVENTORY.md
  - docs/features/arena/ARENA_OVERVIEW.md
  - wiki/features/pvp-combat.md
updated: 2026-05-06
status: Fixed
---

# Audit Block 320 — Screen Entity Arena Flow Parity

## Scope

This block updates the higher-level `wiki/entities/screens.md` page so its
Arena row agrees with the newer screen inventory and the live Arena runtime.

## Why this block

The repo already had the newer Arena truth in checked-in sources:

- `SCREEN_INVENTORY.md` names the Arena screen as:
  - hero widget
  - compact rating summary
  - stance CTA
  - opponents / revenge / history tabs
- `ARENA_OVERVIEW.md` now says the same
- `wiki/features/pvp-combat.md` frames Arena as the launcher surface for rating,
  stance access, and the newer PvP flow

But `wiki/entities/screens.md` still reduced Arena to the older shorthand:

- `Opponent selection → Comparison → Fight`

That summary was now too narrow for the live app.

## Changes shipped

- Updated the `sources` line so the entity page points at all three current
  Arena-adjacent truth surfaces:
  - `docs/07_ui_ux/SCREEN_INVENTORY.md`
  - `docs/features/arena/ARENA_OVERVIEW.md`
  - `wiki/features/pvp-combat.md`
- Refreshed the page timestamp to `2026-05-06`.
- Replaced the old Arena flow row with:
  - `Arena overview → rating / stance drill-down → opponents / revenge / history → fight`

## Result

The higher-level screen entity map no longer understates Arena as just an
opponent-pick funnel; it now reflects the live Arena surface as a broader PvP
hub with rating visibility, stance access, and multiple tabbed entry paths.
