---
title: Block 078 — iOS tutorial manager typed contract cleanup
category: audit
tags: [audit, ios, tutorial, onboarding, hub, contracts]
sources:
  - Hexbound/Hexbound/Tutorial/TutorialManager.swift
  - Hexbound/Hexbound/Views/Hub/HubView.swift
  - Hexbound/Hexbound/Views/Hub/CityMapView.swift
updated: 2026-04-16
status: Fixed
---

# Block 078 — iOS tutorial manager typed contract cleanup

## Scope

- server-synced onboarding state:
  - `Hexbound/Hexbound/Tutorial/TutorialManager.swift`
- hub tutorial quest consumers:
  - `Hexbound/Hexbound/Views/Hub/HubView.swift`
  - `Hexbound/Hexbound/Views/Hub/CityMapView.swift`

## Why this block

After the referral and tavern cleanup in `block-077`, the next obvious iOS contract holdout was `TutorialManager`.

The live onboarding manager still used:

- `getRaw(...)`
- `postRaw(...)`
- `[[String: Any]]` quest state
- stringly-typed quest reward reads in the hub

That meant the first guided quest chain could still drift quietly even though the backend tutorial routes had already been cleaned up.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-073-tutorial-scripted-fight-contract-and-victory-parity]]
- [[block-077-ios-referral-and-tavern-typed-contract-cleanup]]

## File notes

### `Hexbound/Hexbound/Tutorial/TutorialManager.swift`

- **Zone:** iOS / onboarding / tutorial state
- **Purpose:** owns server-backed tutorial step, skip state, referral code, quest state, and tutorial quest mutations
- **Problems found:**
  - tutorial GET/POST flows still used raw dictionaries even though the route contract is stable
  - `tutorialQuests` and `availableQuests` were stored as `[[String: Any]]`
  - quest claim/progress requests were hand-built dictionaries instead of typed request bodies
  - normal failure paths printed unscoped debug noise in release-shaped flows
- **What was fixed:**
  - added typed DTOs for tutorial state, init, skip, step advance, quest progress, and quest claim
  - converted `tutorialQuests` to `[TutorialQuestState]`
  - converted `availableQuests` to `[AvailableTutorialQuest]`
  - moved tutorial request bodies onto typed `Encodable` payloads
  - kept failure handling quiet by default and limited console output to `#if DEBUG`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Hub/HubView.swift`

- **Zone:** iOS / hub / onboarding quest banner
- **Purpose:** renders the first active tutorial quest and handles reward claim feedback
- **Problems found:**
  - still unpacked tutorial quest rows as raw dictionaries
  - claim toast looked for `goldAwarded`, but the backend tutorial quest route returns `goldDelta`
  - result: gold rewards were granted correctly, but the player-facing success copy underreported them
- **What was fixed:**
  - switched the quest banner path to typed `TutorialQuestState`
  - switched reward success copy to `goldDelta`
  - preserved title/NPC-message fallback mapping for old rows that do not carry inline copy
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Hub/CityMapView.swift`

- **Zone:** iOS / hub / city map
- **Purpose:** highlights the building targeted by the current tutorial quest
- **Problems found:**
  - still inspected tutorial quest state as raw dictionaries
  - that kept the city-map hint path on a weaker contract than the banner path above it
- **What was fixed:**
  - switched the active tutorial quest lookup to typed `TutorialQuestState`
  - kept the existing quest-id to building-id mapping unchanged
- **Status:** Fixed

## Problems found

1. **TutorialManager still lived on raw JSON**
   - Risk: tutorial step/quest drift would surface only at runtime, not at compile time.
   - Fix: introduced typed tutorial DTOs and request bodies.

2. **Tutorial quest state was stored as dictionary arrays**
   - Risk: multiple hub surfaces had to reinterpret the same quest payload independently.
   - Fix: centralized that shape as `TutorialQuestState`.

3. **Tutorial reward toast was reading the wrong backend field**
   - Risk: players could receive gold correctly but see a weaker success message, which is subtle trust damage.
   - Fix: updated the hub claim flow from `goldAwarded` to the real `goldDelta` contract.

## Verification

- `rg -n "getRaw\\(|postRaw\\(|\\[String: Any\\]" Hexbound/Hexbound/Tutorial/TutorialManager.swift`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

## Follow-up

- `DungeonService.swift` is still the next biggest iOS raw-contract holdout
- `DungeonSelectViewModel.swift` and `DungeonRushViewModel.swift` should follow once the service layer is typed
