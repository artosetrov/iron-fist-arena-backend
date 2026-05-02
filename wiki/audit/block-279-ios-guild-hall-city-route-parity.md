---
title: Audit Block 279 — iOS Guild Hall City Route Parity
category: audit
tags: [audit, ios, hub, social, routing]
sources:
  - Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift
  - Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift
  - Hexbound/Hexbound/Views/Hub/CityMapView.swift
  - Hexbound/Hexbound/App/AppRouter.swift
  - wiki/features/social.md
updated: 2026-04-30
status: Fixed
---

# Audit Block 279 — iOS Guild Hall City Route Parity

## Scope

This block fixes the fallback city-building route for Guild Hall on iOS.

## Why this block

The repo had drifted into an inconsistent state:

- `AppRoute.guildHall` exists
- multiple live entry points already navigate into Guild Hall
- `wiki/features/social.md` correctly says players can enter via the Hub

But the fallback hub building config still marked `guild-hall` as
`route: nil`, which made the city-map layer treat it as a Coming Soon surface.

That meant the doc/runtime story said "Guild Hall is live", while the hub map
fallback config still behaved like it was not.

## Changes shipped

### `Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift`

- Changed `guild-hall` from `route: nil` to `route: .guildHall`.
- Updated the surrounding comment so the remaining route-less surface example
  is `black-market`, not Guild Hall.

### `Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift`

- Updated the editor comment to stop calling Guild Hall a Coming Soon surface.

## Result

Guild Hall is now aligned across:

- hub fallback route config
- city-map lock logic
- live `AppRoute` navigation
- the social feature map

So the code no longer claims, in one place, that Guild Hall is still Coming
Soon while the rest of the app treats it as a shipped social hub.
