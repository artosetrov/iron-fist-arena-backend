---
title: Block 084 — iOS character list typed envelope parity
category: audit
tags: [audit, ios, auth, character-select, contracts]
sources:
  - Hexbound/Hexbound/Models/Character.swift
  - Hexbound/Hexbound/Services/AuthService.swift
  - Hexbound/Hexbound/Views/Auth/CharacterSelectionViewModel.swift
updated: 2026-04-16
status: Fixed
---

# Block 084 — iOS character list typed envelope parity

## Scope

- shared character list DTO:
  - `Hexbound/Hexbound/Models/Character.swift`
- auth-side character bootstrap:
  - `Hexbound/Hexbound/Services/AuthService.swift`
- character selection screen loader:
  - `Hexbound/Hexbound/Views/Auth/CharacterSelectionViewModel.swift`

## Why this block

After `block-083`, the main single-character service was typed, but the multi-character entry still had duplicated raw parsing in two different places:

- auth auto-login character bootstrap
- character selection screen load

Both were manually decoding the same endpoint with slightly different raw fallback logic. That is exactly the kind of drift that turns one backend change into two client bugs later.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[hero]]
- [[block-083-ios-character-service-typed-contract-cleanup]]

## File notes

### `Hexbound/Hexbound/Models/Character.swift`

- **Zone:** iOS / models / hero
- **Purpose:** shared runtime character model used across auth, hub, profile, and combat-adjacent screens
- **Problems found:**
  - there was no shared typed response for the character-list endpoint, so each consumer kept its own raw fallback logic
- **What was fixed:**
  - added `CharactersListResponse` with compatibility handling for:
    - canonical `characters`
    - legacy `data`
    - single-character direct payload
- **Status:** Fixed

### `Hexbound/Hexbound/Services/AuthService.swift`

- **Zone:** iOS / auth / post-login bootstrap
- **Purpose:** decides whether the session goes to hero select, auto-select, or straight into the game shell
- **Problems found:**
  - `loadCharacters()` still used `getRaw` plus manual per-row JSON serialization
- **What was fixed:**
  - moved the auth bootstrap path to typed `CharactersListResponse`
  - kept the same sort and auto-select behavior, but without raw decode duplication
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Auth/CharacterSelectionViewModel.swift`

- **Zone:** iOS / auth / character selection
- **Purpose:** loads the hero roster for the selection screen and manages delete/select UI state
- **Problems found:**
  - repeated the same raw endpoint parsing as `AuthService`
  - carried its own decode-failure bookkeeping for a contract the app already conceptually understood
- **What was fixed:**
  - switched the screen loader to the shared typed list envelope
  - kept sort and just-created auto-selection behavior intact
- **Status:** Fixed

## Problems found

1. **Character list parsing was duplicated across auth and UI**
   - Risk: one endpoint shape change could break auto-login and character selection differently.
   - Fix: added a shared typed list envelope with compatibility fallback in one place.

2. **Character list still used manual JSONSerialization bridges**
   - Risk: the endpoint looked stable, but the client boundary was still noisier and more fragile than necessary.
   - Fix: moved both consumers onto typed `APIClient.get(...)`.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'getRaw\\(|JSONSerialization' Hexbound/Hexbound/Services/AuthService.swift Hexbound/Hexbound/Views/Auth/CharacterSelectionViewModel.swift`

## Follow-up

- `AuthService` still has broader raw contract debt in the login/register/provider flows; this block only cleaned the shared hero-roster loader
- `GameInitService` remains one of the next larger raw bootstrap surfaces on the iOS side
