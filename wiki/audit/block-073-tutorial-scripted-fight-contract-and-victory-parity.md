---
title: Block 073 — tutorial scripted-fight contract and victory parity
category: audit
tags: [audit, backend, ios, tutorial, onboarding, progression, contracts]
sources:
  - backend/src/app/api/tutorial/scripted-fight/preload/route.ts
  - backend/src/app/api/tutorial/scripted-fight/resolve/route.ts
  - backend/tests/api/tutorial-scripted-fight-contracts.test.ts
  - Hexbound/Hexbound/Services/TutorialService.swift
  - Hexbound/Hexbound/Views/Onboarding/TutorialFightViewModel.swift
  - Hexbound/Hexbound/Views/Onboarding/VictoryOverlayView.swift
  - Hexbound/Hexbound/App/AppState.swift
  - backend/src/lib/game/progression.ts
updated: 2026-04-15
status: Fixed
---

# Block 073 — tutorial scripted-fight contract and victory parity

## Scope

- backend tutorial scripted-fight API:
  - `backend/src/app/api/tutorial/scripted-fight/preload/route.ts`
  - `backend/src/app/api/tutorial/scripted-fight/resolve/route.ts`
- backend regression coverage:
  - `backend/tests/api/tutorial-scripted-fight-contracts.test.ts`
- iOS onboarding consumer chain:
  - `Hexbound/Hexbound/Services/TutorialService.swift`
  - `Hexbound/Hexbound/Views/Onboarding/TutorialFightViewModel.swift`
  - `Hexbound/Hexbound/Views/Onboarding/VictoryOverlayView.swift`
- reference files:
  - `Hexbound/Hexbound/App/AppState.swift`
  - `backend/src/lib/game/progression.ts`

## Why this block

After Block 072, the main game progression contract was finally honest about passive-point awards.

The tutorial scripted fight was still living on its own little island:

- backend tutorial routes used a separate camelCase response dialect
- the iOS client parsed those payloads as raw dictionaries
- the onboarding victory overlay showed `LEVEL N REACHED`, but still hid the actual stat/passive point awards from the player

That meant onboarding was no longer broken, but it was still a weaker, less truthful version of the live progression experience.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[progression]]
- [[block-045-backend-tutorial-achievement-and-weekly-contracts]]
- [[block-072-progression-passive-points-contract-parity]]

## File notes

### `backend/src/app/api/tutorial/scripted-fight/preload/route.ts`

- **Zone:** backend / tutorial / preload
- **Purpose:** preload the scripted opponent and forced stance for the first onboarding fight
- **Problems found:**
  - the route exposed only `forcedStance`, while the rest of the API surface has standardized on snake_case
  - this made tutorial preload an outlier contract
- **What was fixed:**
  - added canonical `forced_stance`
  - preserved `forcedStance` as a legacy compatibility alias
- **Status:** Fixed

### `backend/src/app/api/tutorial/scripted-fight/resolve/route.ts`

- **Zone:** backend / tutorial / resolve
- **Purpose:** resolve the scripted first fight, grant rewards, and mark onboarding progress
- **Problems found:**
  - response shape was still tutorial-specific camelCase: `levelUp`, `itemCatalogKey`, `sanityCheckPassed`
  - this drifted from the now-established snake_case progression contract used across the rest of the game
- **What was fixed:**
  - added canonical `level_up`
  - added canonical `rewards.item_catalog_key`
  - added canonical `sanity_check_passed`
  - preserved `levelUp`, `itemCatalogKey`, and `sanityCheckPassed` as compatibility aliases
- **What still needs attention:**
  - tutorial still keeps a nested `level_up` object while the rest of the live reward routes mostly use top-level progression fields
  - it is now internally consistent enough to be safe, but still a distinct contract family
- **Status:** Fixed

### `backend/tests/api/tutorial-scripted-fight-contracts.test.ts`

- **Zone:** backend / tests / tutorial
- **Purpose:** lock the scripted tutorial API boundary under regression coverage
- **Problems found:**
  - there was no direct test coverage for the tutorial scripted-fight preload/resolve contract shape
  - that made it easy for onboarding response keys to drift silently
- **What was fixed:**
  - added focused tests for preload stance keys and resolve progression/reward keys
- **Status:** Fixed

### `Hexbound/Hexbound/Services/TutorialService.swift`

- **Zone:** iOS / onboarding / service layer
- **Purpose:** wraps the tutorial preload and resolve endpoints
- **Problems found:**
  - parsed tutorial responses as raw dictionaries with tutorial-only key assumptions
  - still expected only camelCase keys
  - carried dead fields (`combat`, `sanityCheckPassed`) that the onboarding UI did not consume
- **What was fixed:**
  - service now reads canonical snake_case first and falls back to legacy camelCase aliases
  - removed the dead `combat` and `sanityCheckPassed` fields from the local `ResolveResult`
  - documented the transition rule directly in the file
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Onboarding/TutorialFightViewModel.swift`

- **Zone:** iOS / onboarding / scripted fight state
- **Purpose:** drives the first fight flow and parks reward data on `AppState`
- **Problems found:**
  - tutorial rewards payload carried level-up state, but not the actual stat/passive point awards
  - that kept the next screen from showing the full reward truth
- **What was fixed:**
  - added `statPointsAwarded`
  - added `passivePointsAwarded`
  - filled both from the resolved tutorial fight result
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Onboarding/VictoryOverlayView.swift`

- **Zone:** iOS / onboarding / victory ceremony
- **Purpose:** reward reveal after the scripted first fight
- **Problems found:**
  - the overlay showed gold, XP, item, and `LEVEL N REACHED`
  - it still hid the actual stat/passive point awards even when the tutorial fight leveled the player up
- **What was fixed:**
  - added truthful reward rows for stat points and passive points
  - preserved the staggered reveal pattern, so the overlay remains visually consistent
- **Status:** Fixed

### `Hexbound/Hexbound/App/AppState.swift`

- **Zone:** iOS / app state
- **Purpose:** shared reward and modal state
- **Why it mattered here:**
  - `tutorialRewards` is the bridge that lets onboarding survive the screen transition into the victory overlay
- **Status:** OK

### `backend/src/lib/game/progression.ts`

- **Zone:** backend / progression reference
- **Purpose:** canonical source of stat/passive point awards on level-up
- **Why it mattered here:**
  - confirmed that tutorial level-ups should expose the same passive-point truth as the rest of the game
- **Status:** OK

## Problems found

1. **Tutorial API contract had drifted into its own camelCase dialect**
   - Risk: onboarding could silently diverge from the rest of the game’s reward/progression conventions.
   - Fix: added canonical snake_case fields while preserving compatibility aliases.

2. **Tutorial iOS service still hardcoded the old response shape**
   - Risk: the client would be brittle during staggered rollout and would keep reintroducing raw-parser debt.
   - Fix: service now accepts canonical snake_case first, then legacy camelCase.

3. **Tutorial victory overlay still under-reported level-up rewards**
   - Risk: first-time players could level up without seeing the stat/passive point awards they actually earned.
   - Fix: carried the real values through `TutorialRewardsPayload` and rendered them in the overlay.

4. **Tutorial resolve service exposed dead fields not consumed by onboarding**
   - Risk: extra raw payload plumbing increases the chance of stale assumptions surviving future refactors.
   - Fix: removed the unused `combat` and `sanityCheckPassed` fields from the local service result.

## Verification

- `npx vitest run tests/api/tutorial-scripted-fight-contracts.test.ts tests/api/tutorial-quest.test.ts` in `backend/`
- `npm run build` in `backend/`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

## Follow-up

- if we do one more tutorial pass later, the next nice cleanup is to move `TutorialService` off raw dictionary parsing entirely
- the bigger remaining contract debt is still that tutorial progression uses a nested object while live reward routes mostly expose top-level progression fields
