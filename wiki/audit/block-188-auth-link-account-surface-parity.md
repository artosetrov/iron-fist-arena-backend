---
title: Audit Block 188 — Auth Link Account Surface Parity
category: audit
tags: [audit, auth, backend, ios, docs]
sources:
  - backend/src/app/api/auth/link-account/route.ts
  - Hexbound/Hexbound/Views/Settings/SettingsViewModel.swift
  - docs/03_backend_and_api/API_REFERENCE.md
  - wiki/features/auth.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 188 — Auth Link Account Surface Parity

> Later follow-up: [block-189-backend-link-account-duplicate-email-guard](/Users/artosetrov/Documents/Cursor%20AI/PVP%20RPG/wiki/audit/block-189-backend-link-account-duplicate-email-guard.md) added runtime protection so this compatibility route now returns `409` on duplicate-email collisions instead of falling through to a generic update failure.

## Scope

- `backend/src/app/api/auth/link-account/route.ts`
- `Hexbound/Hexbound/Views/Settings/SettingsViewModel.swift`
- `docs/03_backend_and_api/API_REFERENCE.md`
- `wiki/features/auth.md`

## Why this block

The auth docs still described `/auth/link-account` like the live guest-to-social merge path.

But the current repo reality is narrower:

- iOS settings sends guests to `upgradeGuest`
- `link-account` is not called by the current client
- the backend route only syncs local `email`, `username`, and `authProvider` on an already-authenticated user row

That made the route look more powerful than it really is.

## Fix applied

### `backend/src/app/api/auth/link-account/route.ts`

- added an explicit compatibility note at the top of the route
- clarified that it is not the primary guest-upgrade flow

### `docs/03_backend_and_api/API_REFERENCE.md`

- changed the route purpose from the misleading “Merge guest with social” wording to “Legacy local profile-link sync compatibility route”

### `wiki/features/auth.md`

- updated the auth feature map entry for `/auth/link-account`
- added a gotcha explaining that the live iOS settings flow uses `upgradeGuest`, not this route

## File records

| Path | Role | Status |
|------|------|--------|
| `backend/src/app/api/auth/link-account/route.ts` | Legacy compatibility route for local profile sync after provider linking | Fixed |
| `Hexbound/Hexbound/Views/Settings/SettingsViewModel.swift` | Current iOS settings flow; guests are routed to `upgradeGuest` | OK |
| `docs/03_backend_and_api/API_REFERENCE.md` | Public route catalog | Fixed |
| `wiki/features/auth.md` | Auth feature map and gotchas | Fixed |

## Result

The auth truth layer is honest again:

- `upgrade-guest` / `upgrade-guest-oauth` remain the real upgrade surfaces
- `link-account` is documented as a narrower compatibility route
- the current iOS settings UX no longer looks like it secretly depends on a route it does not call

## Verification

- `rg -n "link-account|upgradeGuest" Hexbound backend docs wiki -S`
- `git diff --check`

Both passed for this block.
