---
title: Audit Block 285 — iOS Push Deep-Link Route Parity
category: audit
tags: [audit, ios, push, admin, docs]
sources:
  - Hexbound/Hexbound/App/AppDelegate.swift
  - Hexbound/Hexbound/App/AppRouter.swift
  - Hexbound/Hexbound/App/HexboundApp.swift
  - Hexbound/Hexbound/App/AppState.swift
  - admin/src/app/(dashboard)/push/push-client.tsx
  - docs/03_backend_and_api/API_REFERENCE.md
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
updated: 2026-04-30
status: Fixed
---

# Audit Block 285 — iOS Push Deep-Link Route Parity

## Scope

This block closes the gap between admin push route strings and iOS deep-link handling.

## Why this block

The admin push sender already let operators attach a free-form `route` string,
but the iOS client only printed that payload in `AppDelegate` and then dropped
it on the floor behind a TODO. The admin UI also suggested `events` as an
example even though the current iOS router has no such route.

## Changes shipped

- Added a bounded `AppRoute.pushDeepLink(from:)` parser for no-extra-payload
  routes.
- Wired `AppDelegate` into a real route handler instead of the old deep-link
  TODO.
- Added queue/consume behavior in `AppState` so push routes can survive
  pre-game states and open once the app enters `.game`.
- Updated the admin push placeholder from `inbox, shop, events` to
  `inbox, shop, guild-hall`.
- Synced docs so the push route contract now describes the supported bounded
  subset instead of implying arbitrary route strings are accepted.

## Result

Push campaigns can now open supported iOS destinations instead of logging and
dropping the payload, and the admin/docs layer no longer suggests unsupported
route names.
