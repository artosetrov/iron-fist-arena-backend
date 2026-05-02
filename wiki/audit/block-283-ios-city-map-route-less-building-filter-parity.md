---
title: Audit Block 283 — iOS City Map Route-Less Building Filter Parity
category: audit
tags: [audit, ios, hub, routing, docs]
sources:
  - Hexbound/Hexbound/Views/Hub/CityMapView.swift
  - Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift
  - Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift
  - docs/10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md
updated: 2026-04-30
status: Fixed
---

# Audit Block 283 — iOS City Map Route-Less Building Filter Parity

## Scope

This block fixes the normal iOS hub map so route-less placeholder buildings stay
editor-only.

## Why this block

The repo already had a clear split:

- `resolvedCityBuildings(... includeComingSoon: true)` lets the hub editor place
  route-less surfaces like Black Market.
- normal hub helpers and comments say route-less buildings should stay hidden.

But `CityMapView.applyOverrides` ignored that split and always started from
`defaultCityBuildings`, which meant Black Market could still appear as a dead-end
surface in the live hub.

## Changes shipped

- Changed `CityMapView.applyOverrides` to start from the route-bearing building
  set instead of the full fallback array.
- Tightened the adjacent comments so the normal hub is documented as
  progression-locked, while route-less placeholder buildings stay editor-only.
- Updated `HEXBOUND_PRE_RELEASE_AUDIT.md` so its historical follow-up no longer
  claims that Black Market is still a visible live placeholder in the current
  runtime.

## Result

The normal city map now matches the intended shipped model again:

- Guild Hall routes live.
- Black Market stays out of the player-facing hub until it has a real runtime
  route.
- The historical release audit now reflects that later follow-up accurately.
