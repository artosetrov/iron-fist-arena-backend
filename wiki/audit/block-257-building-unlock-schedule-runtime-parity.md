---
title: Audit Block 257 — Building Unlock Schedule Runtime Parity
category: audit
tags: [audit, ios, backend, tutorial, hub, progression]
sources:
  - backend/src/lib/game/tutorial.ts
  - Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift
  - Hexbound/Hexbound/Views/Hub/CityMapView.swift
  - Hexbound/Hexbound/App/AppState.swift
  - Hexbound/Hexbound/Views/Components/LevelUpModalView.swift
  - docs/07_ui_ux/W2_D4_BUILDING_GATING_DESIGN.md
  - wiki/features/tutorial.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 257 — Building Unlock Schedule Runtime Parity

## Scope

- live backend unlock schedule
- iOS hub lock/unlock mirror
- adjacent tutorial/building-gating docs

## Why this block

We found a real runtime drift, not just stale prose:

- backend `BUILDING_UNLOCK_LEVELS` in `tutorial.ts` had already moved to the
  current shipped cadence
- iOS `BuildingUnlockConfig` still carried an older local table
- that local table powers both hub lock visibility and level-up unlock pills

So the player could get contradictory signals:

- backend progression said one thing
- the City hub and local unlock ceremony logic said another

The adjacent W2.D4 design doc also still had a header that read like an active
approval-stage plan even after we started treating it as historical rationale.

## Fix applied

- updated `Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift` so
  `BuildingUnlockConfig.levels` matches the current backend unlock cadence:
  - `shop` at level `1`
  - `achievements` at level `2`
  - `dungeon` at level `4`
  - `gold-mine` and `tavern` at level `6`
  - `battlepass` and `ranks` at level `8`
  - `guild-hall` at level `12`
- added an explicit source-of-truth note in that file documenting the client ↔
  backend key-name mismatch (`battlepass` vs `battle_pass`, `ranks` vs
  `leaderboard`, `guild-hall` vs `guild`) so future edits align levels even
  when identifiers differ
- updated `docs/07_ui_ux/W2_D4_BUILDING_GATING_DESIGN.md` so its header now
  clearly reads as a **historical archived proposal**, matching the boundary
  note already added there
- updated `wiki/features/tutorial.md`:
  - added a gotcha about the mirrored unlock table
  - replaced the dead extra docs pointer with live/historical references that
    actually exist in the repo

## Result

The server-owned tutorial/progression unlock schedule and the client-owned hub
lock mirror now agree again. That removes a subtle class of drift where
players could see the wrong required levels or the wrong "new building"
ceremony timing even though backend progression was already correct.

## Verification

- reviewed live authority and consumers:
  - `backend/src/lib/game/tutorial.ts`
  - `Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift`
  - `Hexbound/Hexbound/Views/Hub/CityMapView.swift`
  - `Hexbound/Hexbound/App/AppState.swift`
  - `Hexbound/Hexbound/Views/Components/LevelUpModalView.swift`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
