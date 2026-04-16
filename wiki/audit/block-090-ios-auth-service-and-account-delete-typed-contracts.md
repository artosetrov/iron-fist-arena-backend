---
title: Block 090 — iOS auth service and account delete typed contracts
category: audit
tags: [audit, ios, auth, settings, contracts]
updated: 2026-04-16
---

# Block 090 — iOS auth service and account delete typed contracts

## Scope

- `Hexbound/Hexbound/Services/AuthService.swift`
- `Hexbound/Hexbound/Views/Settings/SettingsViewModel.swift`

## Why this block existed

Even after character bootstrap became typed, the main auth entry service still parsed login, register, guest-login, and forgot-password responses through raw dictionaries. That kept the app’s front-door session flow on a weaker contract than the rest of the client.

Settings had one more small version of the same problem: account deletion still used `postRaw` even though the route already returned a stable JSON envelope.

## What the files do

### `Hexbound/Hexbound/Services/AuthService.swift`

- Handles email login, registration, guest login, forgot password, auto-login, and logout
- Persists tokens to keychain
- Loads characters after session creation/restoration
- Installs the global unauthorized handler

### `Hexbound/Hexbound/Views/Settings/SettingsViewModel.swift`

- Drives settings screen interactions
- Handles account linking, logout, and permanent account deletion

## Dependencies

- `APIClient`
- `APIError`
- `APIEndpoints`
- `KeychainManager`
- `SupabaseAuthClient`
- `AppState`
- `GameDataCache`

## Inbound usage

- `Hexbound/Hexbound/Views/Auth/*`
- `Hexbound/Hexbound/App/AppRouter.swift`
- `Hexbound/Hexbound/Views/Settings/SettingsDetailView.swift`

## Fixes made

1. Added typed request/response envelopes for email login, registration, guest login, and forgot password.
2. Replaced raw auth request bodies with typed `Encodable` requests.
3. Replaced raw auth response parsing with a shared typed session envelope.
4. Replaced account deletion `postRaw` with a typed delete-account response.
5. Kept the existing token/keychain and navigation behavior intact while removing raw JSON parsing from the main auth service.

## Problems found

### 1. The app’s core auth boundary still depended on raw dictionaries

- **Problem:** `AuthService` manually unpacked `access_token`, `refresh_token`, `needs_confirmation`, and guest restore data from `[String: Any]`.
- **Risk:** contract drift on the auth boundary would break login and guest recovery at runtime instead of compile time.
- **Fix:** introduced typed auth envelopes and switched login/register/guest/forgot-password to `APIClient.post(...)`.

### 2. Account deletion used a raw one-off path

- **Problem:** settings account deletion still used `postRaw("/api/user/delete")`.
- **Risk:** this tiny one-off raw path kept a live destructive action outside the typed contract surface.
- **Fix:** added a typed delete-account response and moved the view model to the shared typed client path.

## What was intentionally left alone

- This block did not widen into Apple/Google sign-in view models or guest-upgrade OAuth flows; those still deserve their own typed contract pass.
- Token refresh in `SupabaseAuthClient` remains separate because it talks directly to Supabase, not the project API routes.

## Keep / fix / delete

- **Keep:** shared typed auth session envelope for core email/guest flows
- **Keep:** typed account deletion response
- **Fix next:** Apple/Google/guest-upgrade view models still carry raw auth route payload handling
- **Delete later:** no delete candidate in this block

## Status

**Fixed**
