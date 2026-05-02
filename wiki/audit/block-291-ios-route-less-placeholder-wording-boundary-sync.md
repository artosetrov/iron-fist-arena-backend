---
title: Audit Block 291 — iOS Route-Less Placeholder Wording Boundary Sync
category: audit
tags: [audit, ios, hub, tutorial, comments]
sources:
  - Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift
  - Hexbound/Hexbound/Views/Hub/CityBuildingView.swift
  - Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift
  - backend/src/lib/game/tutorial.ts
  - Hexbound/Hexbound/App/AppState.swift
  - Hexbound/CLAUDE.md
updated: 2026-05-01
status: Fixed
---

# Audit Block 291 — iOS Route-Less Placeholder Wording Boundary Sync

## Scope

This block normalizes the remaining hub/tutorial wording around route-less
buildings that are intentionally editor-only.

## Why this block

The runtime had already moved away from the older generic "Coming Soon" model:

- Guild Hall is now a live route.
- Black Market is intentionally hidden from the normal hub until it has a real
  route.
- the editor still needs to keep route-less surfaces visible for layout work.

But a small set of adjacent comments and helper docs still described `route =
nil` as generic "Coming Soon" behavior, which no longer matched the shipped
runtime boundary.

## Changes shipped

- Reworded the `CityBuilding` model comment so `route: nil` is described as a
  route-less editor/config placeholder rather than a generic Coming Soon slot.
- Reworded the adjacent lock-overlay and building-view comments so `requiredLevel
  = nil` is clearly tied to the `"SOON"` pill for route-less placeholder
  surfaces only.
- Rewrote the backend tutorial unlock comments and the client `AppState`
  unlock-queue note so the level-99 Black Market case is described as a
  route-less placeholder until a real runtime route ships.
- Updated `Hexbound/CLAUDE.md` so the house rule now matches reality: `route:
  nil` is for hidden editor/config placeholders, not a player-facing Coming Soon
  affordance.

## Result

The hub/tutorial/client-doc layer now uses one consistent model:

- live routes stay live,
- route-less surfaces stay editor/config-only,
- and "SOON" wording is limited to that bounded placeholder case instead of
  reading like a broader product promise.
