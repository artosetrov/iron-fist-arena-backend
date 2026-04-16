---
title: Block 087 — iOS tutorial service typed scripted-fight contracts
category: audit
tags: [audit, ios, tutorial, onboarding, contracts]
updated: 2026-04-16
---

# Block 087 — iOS tutorial service typed scripted-fight contracts

## Scope

- `Hexbound/Hexbound/Services/TutorialService.swift`
- `Hexbound/Hexbound/Views/Onboarding/TutorialFightViewModel.swift`

## Why this block existed

Even after the backend scripted-fight contract was normalized, the live iOS tutorial fight still used `postRaw`, manual dictionary extraction, and ad hoc alias fallback. That kept onboarding on a separate contract dialect even though the shared `APIClient` decoder already knew how to bridge snake_case into the client’s camelCase DTOs.

This also leaked raw dictionaries into the view model even though the screen only needed a tiny typed preview: hero class, hero HP, opponent name, opponent HP, rewards, and level-up metadata.

## What the files do

### `Hexbound/Hexbound/Services/TutorialService.swift`

- Preloads the scripted tutorial fight
- Resolves the deterministic onboarding fight
- Maps backend rewards and level-up data into client-facing tutorial DTOs

### `Hexbound/Hexbound/Views/Onboarding/TutorialFightViewModel.swift`

- Owns the scripted tutorial-fight state machine
- Reads preload preview data
- Stores resolve rewards onto `AppState.tutorialRewards`
- Drives transition into the victory overlay

## Dependencies

- `APIClient`
- `APIError`
- `AppState`
- `CharacterClass`
- onboarding screens under `Views/Onboarding`

## Inbound usage

- `Hexbound/Hexbound/Views/Onboarding/TutorialFightView.swift`
- `Hexbound/Hexbound/Views/Onboarding/VictoryOverlayView.swift`

## Fixes made

1. Replaced raw scripted-fight preload with typed request/response DTOs.
2. Replaced raw scripted-fight resolve with typed request/response DTOs.
3. Removed `postRaw`, `JSON` dictionary extraction, and ad hoc alias reads from `TutorialService`.
4. Converted preload preview data from raw `[String: Any]` dictionaries to typed hero/opponent preview models.
5. Updated `TutorialFightViewModel` to read hero class/name/HP from typed preview payloads instead of dictionary lookups.
6. Kept compatibility with both snake_case canonical fields and camelCase legacy aliases by leaning on the shared `APIClient` `convertFromSnakeCase` decoder instead of keeping a second manual bridge.

## Problems found

### 1. Onboarding still had a local raw-contract fork

- **Problem:** the tutorial fight service manually unpacked `forced_stance`, `rewards`, `level_up`, and item fields from raw dictionaries.
- **Risk:** onboarding could silently drift from backend contract changes even after the backend route had already been normalized and tested.
- **Fix:** moved preload and resolve onto typed request/response DTOs.

### 2. The view model only needed a tiny preview but depended on raw payloads

- **Problem:** `TutorialFightViewModel` reached into dictionaries for hero class, hero HP, opponent name, and opponent HP.
- **Risk:** any field-name change in onboarding preview data would break the screen through runtime dictionary lookups instead of compile-time DTO checks.
- **Fix:** introduced typed preview models and switched the view model to property access.

### 3. Alias compatibility logic was duplicated in client code

- **Problem:** the service manually checked both `forced_stance` and `forcedStance`, plus both `level_up` and `levelUp`.
- **Risk:** more places to forget once rollout compatibility is no longer needed.
- **Fix:** centralized compatibility back into the shared decoder path where snake_case and camelCase both land on the same typed fields.

## What was intentionally left alone

- This block did not widen into the full tutorial manager or the later lore-intro routing.
- The backend `combat` and `sanity_check_passed` fields are still ignored on iOS because the current onboarding flow intentionally skips full replay and only shows the victory/result surface.

## Keep / fix / delete

- **Keep:** typed scripted-fight preload/resolve DTOs
- **Keep:** deterministic onboarding fight flow with rewards parked on `AppState`
- **Fix next:** decide whether `combat` or `sanityCheckPassed` should become visible in onboarding diagnostics or remain backend-only
- **Delete later:** no delete candidate in this block

## Status

**Fixed**
