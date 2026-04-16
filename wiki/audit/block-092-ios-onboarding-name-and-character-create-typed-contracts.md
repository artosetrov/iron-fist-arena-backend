---
title: Block 092 — iOS onboarding name and character-create typed contracts
category: audit
tags: [audit, ios, onboarding, character-create, contracts]
sources:
  - Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift
  - backend/src/app/api/characters/route.ts
  - backend/src/app/api/characters/check-name/route.ts
updated: 2026-04-16
status: Fixed
---

# Block 092 — iOS onboarding name and character-create typed contracts

## Scope

- `Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift`
- `backend/src/app/api/characters/route.ts`
- `backend/src/app/api/characters/check-name/route.ts`

## Why this block

Right next to the newly typed auth flows, onboarding still carried two old raw boundaries:

- name availability check through `getRaw(...)`
- character creation through `postRaw(...)` and manual `JSONSerialization` back into `Character`

That meant the very first hero-creation flow still depended on ad hoc JSON plumbing even after the surrounding auth stack had been cleaned up.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-091-ios-oauth-signin-and-guest-upgrade-typed-contracts]]
- [[hero]]

## File notes

### `Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift`

- **Zone:** iOS / auth / onboarding
- **Purpose:** drives class selection, appearance selection, name validation, and first-hero creation
- **Problems found:**
  - name-check path manually built a query string and decoded a raw dictionary
  - character creation still used raw body dictionaries and manual JSON re-decoding
  - the create-character response handling duplicated backend compatibility logic inside the view model
- **What was fixed:**
  - added typed `NameAvailabilityResponse`
  - added typed `CharacterCreateRequest`
  - added compatibility-aware `CharacterCreateResponse`
  - moved both name-check and character creation onto typed `APIClient.get/post(...)`
- **Status:** Fixed

### `backend/src/app/api/characters/route.ts`

- **Zone:** backend / hero lifecycle
- **Purpose:** creates heroes and returns the created character snapshot
- **Problems found:**
  - no backend code change was required in this block, but the client had been reimplementing its response compatibility locally
- **What was fixed:**
  - client-side contract now matches the backend’s canonical `character` envelope while still tolerating older fallback shapes in one typed decoder
- **Status:** OK

### `backend/src/app/api/characters/check-name/route.ts`

- **Zone:** backend / onboarding validation
- **Purpose:** validates whether a hero name is available
- **Problems found:**
  - no server-side code change was required, but the client treated the endpoint as raw untyped JSON
- **What was fixed:**
  - the client now consumes the endpoint through a typed response instead of a string-built raw path
- **Status:** OK

## Problems found

1. **Onboarding still depended on raw query-string and dictionary parsing**
   - Risk: the app’s first-play hero flow could drift independently from the rest of the typed client layer.
   - Fix: moved name availability to a typed request/response path.

2. **Character creation used manual JSON round-tripping after the POST**
   - Risk: response-shape drift would fail later and more opaquely than a typed decode.
   - Fix: introduced a compatibility-aware typed create-character response that understands canonical `character`, legacy `data.character`, and direct character payloads.

3. **The onboarding VM owned backend compatibility details that belonged in a DTO**
   - Risk: every future caller would have to rediscover the same shape fallbacks.
   - Fix: localized that compatibility into `CharacterCreateResponse`.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization|\\[String: Any\\]' Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift`

## Follow-up

- The next nearby live raw-contract slice is `ShopService`, not onboarding.
- `OnboardingViewModel` still has normal UI/business logic complexity, but its network boundary is no longer the weak point.
