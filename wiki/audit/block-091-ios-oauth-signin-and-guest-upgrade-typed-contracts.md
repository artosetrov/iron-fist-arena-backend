---
title: Block 091 — iOS OAuth sign-in and guest-upgrade typed contracts
category: audit
tags: [audit, ios, auth, oauth, guest-upgrade, contracts]
sources:
  - Hexbound/Hexbound/Services/AuthService.swift
  - Hexbound/Hexbound/Views/Auth/LoginViewModel.swift
  - Hexbound/Hexbound/Views/Auth/RegisterViewModel.swift
  - Hexbound/Hexbound/Views/Auth/UpgradeGuestView.swift
updated: 2026-04-16
status: Fixed
---

# Block 091 — iOS OAuth sign-in and guest-upgrade typed contracts

## Scope

- `Hexbound/Hexbound/Services/AuthService.swift`
- `Hexbound/Hexbound/Views/Auth/LoginViewModel.swift`
- `Hexbound/Hexbound/Views/Auth/RegisterViewModel.swift`
- `Hexbound/Hexbound/Views/Auth/UpgradeGuestView.swift`

## Why this block

After `block-090`, the email and guest session service was typed, but the live Apple/Google sign-in and guest-upgrade screens still stitched together raw bodies and raw auth envelopes on their own.

That left the most sensitive account-linking and provider-login paths on a weaker contract than the rest of auth.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-090-ios-auth-service-and-account-delete-typed-contracts]]

## File notes

### `Hexbound/Hexbound/Services/AuthService.swift`

- **Zone:** iOS / auth / shared session contracts
- **Purpose:** owns the canonical typed auth envelopes used across the app
- **Problems found:**
  - `AuthSessionEnvelope` and `AuthUserEnvelope` were scoped too tightly for the provider-login view models to reuse
- **What was fixed:**
  - widened the shared auth envelope visibility from private to internal so the rest of the auth layer can reuse the same typed contract instead of copying shapes
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Auth/LoginViewModel.swift`

- **Zone:** iOS / auth / login UI
- **Purpose:** handles email login, guest login, Apple sign-in, and Google sign-in from the main login screen
- **Problems found:**
  - Apple and Google flows still used raw `postRaw(...)` payloads and manually unpacked tokens from dictionary responses
- **What was fixed:**
  - added typed OAuth sign-in request DTO
  - moved Apple and Google login onto `APIClient.post(...)` with `AuthSessionEnvelope`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Auth/RegisterViewModel.swift`

- **Zone:** iOS / auth / registration UI
- **Purpose:** handles registration and provider-based account creation from the register screen
- **Problems found:**
  - provider-based sign-up was still a local raw JSON island
- **What was fixed:**
  - added typed OAuth register request DTO
  - moved Apple and Google registration paths onto the shared typed auth session envelope
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Auth/UpgradeGuestView.swift`

- **Zone:** iOS / settings / guest conversion
- **Purpose:** upgrades a guest account to email/password or linked OAuth without losing progress
- **Problems found:**
  - guest email upgrade and guest OAuth upgrade still used raw request bodies and raw token dictionaries
- **What was fixed:**
  - added typed guest-upgrade request DTOs
  - moved both upgrade paths onto `APIClient.post(...)` with `AuthSessionEnvelope`
  - kept the existing success-toasts and navigation behavior intact
- **Status:** Fixed

## Problems found

1. **Provider sign-in still bypassed the typed auth boundary**
   - Risk: Apple/Google contract drift could break only one sign-in surface while email auth kept working.
   - Fix: moved both provider flows in login and register onto shared typed request/response DTOs.

2. **Guest-upgrade flows duplicated raw auth envelope parsing**
   - Risk: account-linking is high-impact and should not depend on ad hoc token extraction in a view file.
   - Fix: reused `AuthSessionEnvelope` for guest email upgrade and guest OAuth upgrade.

3. **The shared auth session contract existed, but nearby screens could not reuse it**
   - Risk: auth shape drift would keep spawning local envelope copies.
   - Fix: exposed the shared auth envelopes to the rest of the auth module instead of keeping them file-private.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization|\\[String: Any\\]' Hexbound/Hexbound/Views/Auth/LoginViewModel.swift Hexbound/Hexbound/Views/Auth/RegisterViewModel.swift Hexbound/Hexbound/Views/Auth/UpgradeGuestView.swift Hexbound/Hexbound/Services/AuthService.swift`

## Follow-up

- `OnboardingViewModel` was still a neighboring raw-contract island after this block and needed its own pass.
- This block intentionally did not widen into the larger onboarding character-creation flow.
