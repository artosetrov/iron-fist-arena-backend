---
title: Audit Block 299 — iOS Unavailable Route Copy Parity
category: audit
tags: [audit, ios, routing, copy]
sources:
  - Hexbound/Hexbound/App/AppRouter.swift
  - Hexbound/Hexbound/Views/Auth/CharacterSelectionView.swift
  - Hexbound/Hexbound/Views/Hub/CityMapView.swift
updated: 2026-05-01
status: Fixed
---

# Audit Block 299 — iOS Unavailable Route Copy Parity

## Scope

This block removes the last generic live `Coming Soon` runtime copy from the
iOS routing and city-map fallback layer.

## Why this block

The repo had already moved away from the old model where hidden or
route-less surfaces were treated as generic player-facing "Coming Soon"
buttons.

But two live runtime paths still used that language:

- the shared route fallback view in `AppRouter.swift`
- the city-map fallback toasts in `CityMapView.swift`

That left the checked-in docs/comments and the shipped runtime speaking two
different languages about unavailable screens.

## Changes shipped

- Renamed the shared fallback view from `PlaceholderView` to
  `UnavailableRouteView`.
- Replaced the live title/body copy from generic `Coming Soon` text to a more
  honest unavailable-screen message.
- Updated the character-selection auth stack to use the renamed fallback view.
- Replaced the city-map fallback toasts with `is not available right now`
  wording instead of generic `Coming Soon`.

## Result

The remaining live iOS fallback surfaces now describe unavailable routes
plainly instead of reviving the older "Coming Soon" model that the rest of the
repo has already retired.
