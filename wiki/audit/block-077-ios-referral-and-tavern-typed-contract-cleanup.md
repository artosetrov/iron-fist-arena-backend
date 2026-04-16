---
title: Block 077 — iOS referral and tavern typed contract cleanup
category: audit
tags: [audit, ios, tutorial, referral, minigames, contracts]
sources:
  - Hexbound/Hexbound/Models/MinigameSession.swift
  - Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift
  - Hexbound/Hexbound/Views/Minigames/FortuneWheelViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/ShellGameViewModel.swift
updated: 2026-04-16
status: Fixed
---

# Block 077 — iOS referral and tavern typed contract cleanup

## Scope

- shared iOS minigame DTO surface:
  - `Hexbound/Hexbound/Models/MinigameSession.swift`
- referral settings flow:
  - `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`
- tavern minigames:
  - `Hexbound/Hexbound/Views/Minigames/FortuneWheelViewModel.swift`
  - `Hexbound/Hexbound/Views/Minigames/ShellGameViewModel.swift`

## Why this block

Even after the backend tutorial/referral and minigame routes were cleaned up, several live iOS surfaces were still talking to them through raw dictionaries:

- `getRaw(...)`
- `postRaw(...)`
- stringly-typed field access
- message-substring parsing instead of typed error payloads

That is exactly the kind of drift that tends to survive for weeks and then break quietly during a backend contract cleanup.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-073-tutorial-scripted-fight-contract-and-victory-parity]]
- [[block-074-tutorial-referral-rate-limit-and-storage-parity]]
- [[block-075-referral-qualification-rewards-and-idempotency]]
- [[block-076-referral-reward-backfill-tooling]]

## File notes

### `Hexbound/Hexbound/Models/MinigameSession.swift`

- **Zone:** iOS / models / minigames
- **Purpose:** shared typed DTOs for minigame responses
- **Problems found:**
  - Fortune Wheel and Shell Game still lacked canonical response/request DTOs
  - live view models were forced to parse raw dictionaries inline
- **What was fixed:**
  - added typed request/response models for:
    - Fortune Wheel status/spin
    - Shell Game status/start/guess
  - kept the new DTOs alongside the existing minigame-session models so the contract stays discoverable in one place
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`

- **Zone:** iOS / settings / referral UI
- **Purpose:** referral code display and "apply friend code" flow
- **Problems found:**
  - GET and POST referral calls used raw JSON dictionaries
  - error handling guessed state from substring matching in server messages
  - load failure wrote debug noise instead of keeping the UI state clean
- **What was fixed:**
  - switched to typed `ReferralStatusResponse` and `ReferralApplyResponse`
  - switched apply request to a typed `Encodable` body
  - uses `APIError.responsePayload` for `alreadyReferred` and `invalidCode` instead of brittle message guessing
  - keeps UI state explicit: clears the input after success and avoids console noise on normal failures
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/FortuneWheelViewModel.swift`

- **Zone:** iOS / tavern / fortune wheel
- **Purpose:** status load and spin flow for the Fortune Wheel
- **Problems found:**
  - status call manually concatenated `?character_id=...` onto the URL string
  - the screen parsed raw dictionaries for a route that already has a stable contract
  - bypassing `params:` also bypassed the normal GET request-shape discipline
- **What was fixed:**
  - switched status to typed `APIClient.get(...)` with `params:`
  - switched spin to typed `APIClient.post(...)`
  - now reads `gold`, `spinsRemaining`, `spinsLimit`, and spin result fields from DTOs instead of dictionary casts
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Minigames/ShellGameViewModel.swift`

- **Zone:** iOS / tavern / shell game
- **Purpose:** daily status, session start, and guess resolution for Shell Game
- **Problems found:**
  - start/guess/status still depended on raw dictionaries even though the backend contract is stable
  - inline dictionary parsing made optimistic gold reconciliation and daily-limit state easier to drift
- **What was fixed:**
  - switched status, start, and guess to typed request/response DTOs
  - replaced raw body dictionaries with typed `Encodable` request models
  - now updates session ID, daily plays counters, winning cup, win amount, and authoritative gold through DTO fields
- **Status:** Fixed

## Problems found

1. **Live iOS referral/minigame surfaces still used raw dictionaries**
   - Risk: backend cleanup could silently break these screens without compiler help.
   - Fix: moved them to typed request/response DTOs.

2. **Referral error handling depended on message text**
   - Risk: harmless server copy changes could break "already referred" and "invalid code" UX.
   - Fix: switched to typed error payload inspection where the backend already returns explicit flags.

3. **Fortune Wheel status built query strings manually**
   - Risk: request construction drift and less predictable APIClient behavior.
   - Fix: switched to `params:`-based typed GET.

## Verification

- `rg -n "getRaw\\(|postRaw\\(|JSONSerialization" Hexbound/Hexbound/Views/Minigames/FortuneWheelViewModel.swift Hexbound/Hexbound/Views/Minigames/ShellGameViewModel.swift Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift Hexbound/Hexbound/Models/MinigameSession.swift`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

## Follow-up

- `DungeonService.swift`, `DungeonSelectViewModel.swift`, and `DungeonRushViewModel.swift` are the next obvious typed-contract cleanup slice on iOS
- `TutorialManager.swift` still carries raw tutorial-state parsing and should be aligned to the same contract discipline in a separate block
