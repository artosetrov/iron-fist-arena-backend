---
title: Block 095 — iOS battle preloader typed PvP contracts
category: audit
tags: [audit, ios, pvp, combat, contracts]
sources:
  - Hexbound/Hexbound/Services/BattlePreloader.swift
  - Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift
  - backend/src/app/api/pvp/prepare/route.ts
  - backend/src/app/api/pvp/resolve/route.ts
updated: 2026-04-16
status: Fixed
---

# Block 095 — iOS battle preloader typed PvP contracts

## Scope

- `Hexbound/Hexbound/Services/BattlePreloader.swift`
- `Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift`
- `backend/src/app/api/pvp/prepare/route.ts`
- `backend/src/app/api/pvp/resolve/route.ts`

## Why this block

After the broader iOS service cleanup, the live arena prepare/resolve pipeline still depended on raw `postRaw(...)` calls and dictionary unpacking inside `BattlePreloader`.

That was a particularly sharp remaining edge because `BattlePreloader` sits on the hot path for:

- PvP battle start
- optimistic arena playback
- reward presentation
- stamina and durability reconciliation

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-094-ios-inventory-service-sell-use-expand-typed-contracts]]
- [[combat]]
- [[pvp-rating]]

## File notes

### `Hexbound/Hexbound/Services/BattlePreloader.swift`

- **Zone:** iOS / PvP / battle orchestration
- **Purpose:** prepares deterministic arena combat, runs client-side simulation, and resolves the fight against the server
- **Problems found:**
  - both `prepare(...)` and `resolve(...)` still used raw request bodies and raw response dictionaries
  - `durability_changes` crossed the boundary as untyped dictionaries all the way into arena UI
  - this kept a central live combat service behind the typed contract standard used elsewhere
- **What was fixed:**
  - added typed prepare and resolve request DTOs
  - added typed prepare and resolve response DTOs
  - typed the `durability_changes` payload into `DurabilityChangeSnapshot`
  - removed the raw network boundary first; the remaining internal engine bridge was tracked separately and later eliminated in [[block-104-ios-battle-preloader-combat-engine-typed-handoff]]
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift`

- **Zone:** iOS / arena / resolve consumer
- **Purpose:** applies server-authoritative arena results into local character state and post-battle UI
- **Problems found:**
  - broken-item detection still assumed `durabilityDegraded` was a dictionary array
- **What was fixed:**
  - switched broken-item detection to typed durability snapshots
- **Status:** Fixed

### `backend/src/app/api/pvp/prepare/route.ts`

- **Zone:** backend / PvP / prepare contract
- **Purpose:** validates stamina and HP, issues a battle ticket, and returns deterministic combat inputs
- **Problems found:**
  - no backend code change was required here, but the iOS side was still treating the route as raw JSON
- **What was fixed:**
  - the client now consumes the prepare contract through a typed response model
- **Status:** OK

### `backend/src/app/api/pvp/resolve/route.ts`

- **Zone:** backend / PvP / authoritative resolve
- **Purpose:** re-runs combat, consumes the battle ticket, applies rewards, degrades equipment, and returns the final authoritative result
- **Problems found:**
  - no server-side bug was fixed in this block; the weakness was on the client decode boundary
- **What was fixed:**
  - the client now consumes the resolve response as typed result/stamina/HP/durability payloads
- **Status:** OK

## Problems found

1. **Arena prepare/resolve still bypassed the typed client boundary**
   - Risk: one of the app’s most important live combat paths could drift silently even after the rest of the iOS service layer had been typed.
   - Fix: moved both prepare and resolve onto typed request/response DTOs.

2. **Durability degradation crossed into UI as raw dictionaries**
   - Risk: broken-item notifications and post-fight repair guidance depended on stringly typed fields.
   - Fix: introduced `DurabilityChangeSnapshot` and updated `ArenaViewModel` to consume it directly.

3. **The initial cleanup stopped at the network boundary, not the engine handoff**
   - Risk: without a follow-up pass, the remaining local bridge could still keep combat-specific contract drift alive inside the app.
   - Fix: this block removed the raw network layer first; the engine handoff itself was completed in [[block-104-ios-battle-preloader-combat-engine-typed-handoff]].

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- Hexbound/Hexbound/Services/BattlePreloader.swift Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift`
- `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization|rawDictionary:' Hexbound/Hexbound/Services/BattlePreloader.swift Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift`

## Follow-up

- The network-contract cleanup from this block is now fully paired with the engine-internal cleanup in [[block-104-ios-battle-preloader-combat-engine-typed-handoff]].
