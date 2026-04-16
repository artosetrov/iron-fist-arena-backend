---
title: Block 083 — iOS character service typed contract cleanup
category: audit
tags: [audit, ios, character, services, contracts, hero]
sources:
  - Hexbound/Hexbound/Services/CharacterService.swift
updated: 2026-04-16
status: Fixed
---

# Block 083 — iOS character service typed contract cleanup

## Scope

- character runtime service:
  - `Hexbound/Hexbound/Services/CharacterService.swift`

## Why this block

Even after the dungeon and loot cleanup, one very central iOS service still lived on the old decode pattern:

- `getRaw(...)`
- `postRaw(...)`
- `JSONSerialization.data(withJSONObject:)`

That pattern sat on top of:

- character load
- stat allocation
- stat respec
- stat-point purchases
- purchase status
- stance updates

So the service worked, but it still carried unnecessary raw-contract fragility in one of the most reused character entry points.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[hero]]
- [[combat]]
- [[block-071-ios-hub-daily-login-and-levelup-contract-cleanup]]
- [[block-082-ios-pending-loot-typed-presentation-contract]]

## File notes

### `Hexbound/Hexbound/Services/CharacterService.swift`

- **Zone:** iOS / services / character runtime
- **Purpose:** loads and mutates the current hero state used by hub, profile, stats, and combat-adjacent UI
- **Problems found:**
  - live character endpoints still used raw JSON parsing plus local `JSONSerialization`
  - stance update only did an optimistic local write even though the backend returned an authoritative character snapshot
  - `train()` still pointed at a deprecated backend route and would only fail at runtime if ever reached again
- **What was fixed:**
  - added typed envelopes for character load, purchases, and stance updates
  - moved load / allocate / respec / buy-stat-points / purchase-status / stance onto typed `APIClient.get/post(...)`
  - changed stance save to apply the authoritative returned character instead of a partial optimistic patch
  - replaced the dead `train()` network path with an explicit “unavailable” result instead of silently calling a deprecated endpoint
- **Status:** Fixed

## Problems found

1. **Core character mutations still depended on raw JSON bridges**
   - Risk: any response-shape drift in a high-traffic service could break multiple hero-facing screens at once.
   - Fix: moved the main character endpoints onto typed envelopes.

2. **Stance save was only locally patched**
   - Risk: if the backend character payload ever changed adjacent fields, the client would keep a partial local state instead of the authoritative one.
   - Fix: used the returned typed character snapshot as the write-back source.

3. **Dead training path still referenced a deprecated backend route**
   - Risk: if the path became reachable again, the player would hit a runtime failure rather than a clear product-state message.
   - Fix: turned it into an explicit unavailable path and documented it as a future product decision instead of a hidden broken request.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`
- `rg -n 'getRaw\\(|postRaw\\(|JSONSerialization' Hexbound/Hexbound/Services/CharacterService.swift`

## Follow-up

- `CharacterService` is now typed for its live character flows, but neighboring services like `GameInitService`, `AuthService`, and `CharacterSelectionViewModel` still contain older raw-decode paths
- `train()` is now honestly disabled rather than secretly broken; if the product wants a training fight again, it should come back as a fresh contract against a live backend route instead of reviving the deprecated simulate endpoint
