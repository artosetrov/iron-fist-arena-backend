---
title: Audit Block 234 — Feature Maps Leaderboard and Dungeon Rush Admin Boundary Sync
category: audit
tags: [audit, wiki, feature-map, leaderboard, dungeon-rush, admin]
sources:
  - wiki/features/leaderboard.md
  - wiki/features/dungeon-rush.md
  - admin/src/app/(dashboard)/matches/page.tsx
  - admin/src/app/(dashboard)/players/[id]/page.tsx
  - admin/src/app/(dashboard)/minigame-sessions/page.tsx
  - admin/src/app/(dashboard)/minigame-sessions/minigame-sessions-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 234 — Feature Maps Leaderboard and Dungeon Rush Admin Boundary Sync

## Scope

- `wiki/features/leaderboard.md`
- `wiki/features/dungeon-rush.md`
- `admin/src/app/(dashboard)/matches/page.tsx`
- `admin/src/app/(dashboard)/players/[id]/page.tsx`
- `admin/src/app/(dashboard)/minigame-sessions/page.tsx`
- `admin/src/app/(dashboard)/minigame-sessions/minigame-sessions-client.tsx`

## Why this block

Two feature maps still pointed at speculative or deleted admin shapes:

- `leaderboard.md` implied a dedicated leaderboard admin page with manual rating adjustments
- `dungeon-rush.md` implied a rush catalog / room-balance admin page “if present”

That language no longer matched the live dashboard, which now routes adjacent review through existing matches, players, and minigame-session surfaces.

## Fix applied

- `leaderboard.md`
  - replaced the phantom leaderboard admin page with the real nearby review surfaces:
    - PvP match history page
    - player detail page
  - added an explicit note that there is no standalone manual rating-adjust tool today
- `dungeon-rush.md`
  - replaced the vague “if present” admin note with the real minigame-sessions review page
  - made the current boundary explicit: there is no rush-specific room-catalog editor; related tuning lives in broader dungeon/config/balance surfaces

## Result

The leaderboard and Dungeon Rush feature maps now describe the live admin boundary honestly instead of hinting at richer admin tools that are not in the repo.

## Verification

- verified the referenced admin pages exist
- verified there is no dedicated `leaderboard/` or `dungeon-rush/` admin route tree
- `git diff --check`

This closes the next pair of stale admin-boundary tails in the feature-map layer.
