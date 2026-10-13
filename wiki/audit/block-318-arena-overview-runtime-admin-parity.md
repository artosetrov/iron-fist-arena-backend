---
title: Audit Block 318 — Arena Overview Runtime / Admin Parity
category: audit
tags: [audit, docs, arena, pvp, admin]
sources:
  - docs/features/arena/ARENA_OVERVIEW.md
  - Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift
  - Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift
  - backend/src/app/api/pvp/opponents/route.ts
  - backend/src/app/api/pvp/fight/route.ts
  - backend/src/app/api/pvp/match/start/route.ts
  - backend/src/app/api/pvp/prepare/route.ts
  - backend/src/app/api/pvp/revenge/route.ts
  - backend/src/app/api/pvp/history/route.ts
  - wiki/features/pvp-combat.md
updated: 2026-05-06
status: Fixed
---

# Audit Block 318 — Arena Overview Runtime / Admin Parity

## Scope

This block refreshes the standalone Arena feature doc so it matches the current
live Arena runtime and the narrower checked-in admin review surface.

## Why this block

`docs/features/arena/ARENA_OVERVIEW.md` was still carrying a March snapshot:

- old `Status: Complete` / `Last updated: 2026-03-26` freshness
- older Arena layout wording centered on a PvP stats bar plus stance preview
- older backend route/path references
- broad shorthand like `admin/src/` instead of the precise checked-in review
  surfaces

By this point, the live repo truth had already moved:

- Arena summary slot now restores the compact rating widget
- direct stance editing survives as a smaller dedicated CTA
- Interactive Combat routes sit next to the classic compatibility flow
- admin review lives through specific `matches`, `players`, and adjacent
  `economy` pages

## Changes shipped

- Rewrote `ARENA_OVERVIEW.md` into a current live overview instead of a stale
  March snapshot.
- Updated the source-of-truth line to point at:
  - `ArenaDetailView.swift`
  - `backend/src/app/api/pvp/`
  - `wiki/features/pvp-combat.md`
- Replaced the old layout description with the live Arena structure:
  - hero widget
  - compact PvP rating summary
  - dedicated stance CTA
  - low-HP banner
  - opponents / revenge / history content
- Replaced stale route descriptions with the current Arena-adjacent PvP route
  surface (`opponents`, `fight`, `match/start`, `prepare`, `revenge`,
  `history`, `resolve`).
- Replaced the vague admin reference with the real checked-in review surfaces:
  - `admin/src/app/(dashboard)/matches/page.tsx`
  - `admin/src/app/(dashboard)/players/page.tsx`
  - `admin/src/app/(dashboard)/players/[id]/page.tsx`
  - `admin/src/app/(dashboard)/economy/page.tsx`

## Result

The standalone Arena feature doc now agrees with the live Arena screen, the
current PvP route family, and the actual checked-in admin review layer instead
of preserving an older stance-preview-first March snapshot.
