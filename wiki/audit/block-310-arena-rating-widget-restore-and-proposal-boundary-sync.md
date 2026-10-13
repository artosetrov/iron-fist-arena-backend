---
title: Audit Block 310 — Arena Rating Widget Restore and Proposal Boundary Sync
category: audit
tags: [audit, ios, arena, pvp, qa]
sources:
  - Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift
  - Hexbound/Hexbound/Views/Components/PvPStatsWidget.swift
  - Hexbound/Hexbound/Views/Hero/HeroDetailView.swift
  - qa-reports/2026-05-04-arena-rating-widget-proposal.md
  - wiki/features/pvp-combat.md
  - docs/07_ui_ux/SCREEN_INVENTORY.md
updated: 2026-05-06
status: Fixed
---

# Audit Block 310 — Arena Rating Widget Restore and Proposal Boundary Sync

## Scope

This block closes the Arena summary-slot seam that had already been written up
as a restore proposal but was still not reflected in the live runtime or the
adjacent source-of-truth layer.

## Why this block

The checked-in proposal was clear:

- `PvPStatsWidget(.compact)` already existed
- `ArenaDetailView` still carried a historical marker saying PvP stats had
  once lived there
- the live slot was still occupied by the stance preview instead

At the same time, direct stance editing still mattered because:

- Arena tutorial step `.arenaStance` still points players at that control
- a direct route to `AppRoute.stanceSelector` is still useful even though Hero
  already exposes another stance entry point

So the safest finish was not a pure swap-to-zero, but a restore of the rating
widget plus a smaller dedicated stance CTA.

## Changes shipped

- Replaced the old Arena summary-slot surface with `PvPStatsWidget(.compact)`.
- Wired the widget as a button to the leaderboard route.
- Preserved direct stance editing as a smaller dedicated CTA underneath the
  rating widget.
- Kept the Arena tutorial anchor on that dedicated stance CTA so the
  onboarding hint still lands on the correct action.
- Reframed `qa-reports/2026-05-04-arena-rating-widget-proposal.md` as
  historical implementation context instead of a still-pending approval step.
- Updated the adjacent docs/wiki layer so Arena now reads as:
  - compact rating summary surface
  - dedicated stance CTA
  - opponent/revenge/history tabs

## Result

Arena now matches the already-checked-in intent: the summary slot shows the
rating widget again, stance editing remains discoverable and tutorial-safe, and
the neighboring proposal/doc layer no longer pretends this restore is still
waiting on approval.
