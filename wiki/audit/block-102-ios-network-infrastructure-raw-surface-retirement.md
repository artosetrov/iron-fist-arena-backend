---
title: Block 102 — iOS network infrastructure raw surface retirement
category: audit
tags: [audit, ios, network, auth, contracts]
sources:
  - Hexbound/Hexbound/Network/APIClient.swift
  - Hexbound/Hexbound/Network/SupabaseAuthClient.swift
updated: 2026-04-16
status: Fixed
---

# Block 102 — iOS network infrastructure raw surface retirement

## Scope

- `Hexbound/Hexbound/Network/APIClient.swift`
- `Hexbound/Hexbound/Network/SupabaseAuthClient.swift`

## Why this block

By the time blocks `077–101` landed, live product callers in `Hexbound` had already stopped depending on `getRaw(...)`, `postRaw(...)`, and `patchRaw(...)`. The remaining raw surface was infrastructure-shaped: dead helper APIs still exported from `APIClient`, plus manual Supabase auth JSON parsing that had never been brought into the same typed contract style as the rest of the app.

That made this the right moment to retire the old escape hatch instead of leaving it around to invite the next drift later.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-090-ios-auth-service-and-account-delete-typed-contracts]]
- [[block-091-ios-oauth-signin-and-guest-upgrade-typed-contracts]]
- [[block-100-ios-game-config-daily-login-parse-bridge-cleanup]]
- [[block-101-ios-interactive-combat-reconcile-payload-bridge-cleanup]]

## File notes

### `Hexbound/Hexbound/Network/APIClient.swift`

- **Zone:** iOS / shared networking
- **Purpose:** canonical typed HTTP client used by live app services
- **Problems found:**
  - dead raw helpers (`getRaw`, `postRaw`, `patchRaw`) were still exported even though live callers were already gone
  - request plumbing still carried a `rawBody` branch only to support that dead path
  - the file still looked more permissive than the real app contract had become
- **What was fixed:**
  - removed `getRaw`, `postRaw`, and `patchRaw`
  - removed `rawBody` support from the request pipeline
  - removed the dead `parseJSON(...)` helper
  - kept `JSONSerialization` only for generic error-body extraction in `4xx` handling
- **Status:** Fixed

### `Hexbound/Hexbound/Network/SupabaseAuthClient.swift`

- **Zone:** iOS / auth infrastructure
- **Purpose:** refreshes Supabase sessions, validates access tokens, and resends signup confirmation
- **Problems found:**
  - refresh, get-user, and resend-confirmation still used manual JSON handling instead of typed DTOs
  - a dead anonymous sign-in helper remained in the file without live callers
- **What was fixed:**
  - added typed request/response DTOs for refresh token, user lookup, and resend confirmation
  - switched the actor to shared `JSONDecoder` / `JSONEncoder`
  - removed the dead anonymous sign-in helper
- **Status:** Fixed

## Problems found

1. **Raw networking escape hatches outlived their callers**
   - Risk: future code could quietly regress back to ad hoc JSON transport because the old helper surface still looked available and supported.
   - Fix: deleted the unused raw helper API from `APIClient`.

2. **Supabase auth sat outside the typed contract cleanup**
   - Risk: auth infrastructure would remain a separate local dialect, making failures and future edits harder to reason about than the rest of the app.
   - Fix: moved refresh/user/resend flows onto typed DTOs.

3. **Residual JSON parsing needed a clear boundary**
   - Risk: once most raw bridges are gone, any remaining `JSONSerialization` starts to look suspicious unless its role is explicit.
   - Fix: narrowed the remaining raw parsing to generic error-payload extraction only.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- Hexbound/Hexbound/Network/APIClient.swift Hexbound/Hexbound/Network/SupabaseAuthClient.swift`
- `rg -n '\\.getRaw\\(|\\.postRaw\\(|\\.patchRaw\\(' Hexbound/Hexbound -g'*.swift'`
- `rg -n 'JSONSerialization' Hexbound/Hexbound/Network/APIClient.swift Hexbound/Hexbound/Network/SupabaseAuthClient.swift`

## Follow-up

- Residual `JSONSerialization` in `Hexbound` is now intentional infrastructure code for generic error extraction, not a live product transport path.
- The next honest iOS tails are smaller contract-shape cleanup items, not a wide raw-network layer anymore.
