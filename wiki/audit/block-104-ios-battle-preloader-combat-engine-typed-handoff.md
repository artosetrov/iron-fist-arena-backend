---
title: Block 104 — iOS battle preloader and combat engine typed handoff
category: audit
tags: [audit, ios, combat, pvp, contracts]
sources:
  - Hexbound/Hexbound/Services/BattlePreloader.swift
  - Hexbound/Hexbound/Services/CombatEngine.swift
updated: 2026-04-16
status: Fixed
---

# Block 104 — iOS battle preloader and combat engine typed handoff

## Scope

- `Hexbound/Hexbound/Services/BattlePreloader.swift`
- `Hexbound/Hexbound/Services/CombatEngine.swift`

## Why this block

After block `095`, arena prepare/resolve networking was already typed, but the hot path between `BattlePreloader` and `CombatEngine` still did a quiet round-trip through `[String: Any]`.

That meant the raw network boundary was gone while the most important local combat handoff still looked like:

- typed prepare DTO
- foundation dictionary bridge
- legacy combat-engine parsing

That is exactly the kind of internal drift that eventually turns a clean API migration into “we still kind of have JSON everywhere”.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[combat]]
- [[block-095-ios-battle-preloader-typed-pvp-contracts]]
- [[block-101-ios-interactive-combat-reconcile-payload-bridge-cleanup]]

## File notes

### `Hexbound/Hexbound/Services/BattlePreloader.swift`

- **Zone:** iOS / PvP / battle orchestration
- **Purpose:** decodes arena prepare payloads and feeds deterministic client-side combat inputs into the local simulator
- **Problems found:**
  - typed prepare DTOs were still converted into `[String: Any]` before entering the engine
  - `BattleJSONValue` and `foundationObject` helpers kept a local JSON dialect alive after the network boundary was already cleaned up
  - `rank_scaling` was modeled as an object-shaped payload locally even though backend prepare emits a scalar
- **What was fixed:**
  - removed `BattleJSONValue`
  - replaced dictionary-building with direct typed conversion into `CombatConfig`, `FighterStats`, `PassiveBonus`, `ParsedZoneStance`, and `CombatSkill`
  - corrected `rankScaling` to a scalar `Double?`
  - narrowed self-buff effect decoding to the actual engine-owned `heal` contract instead of a generic foundation object
- **Status:** Fixed

### `Hexbound/Hexbound/Services/CombatEngine.swift`

- **Zone:** iOS / combat simulation
- **Purpose:** deterministic local arena combat simulator that mirrors backend PvP combat rules
- **Problems found:**
  - combat models still depended on legacy dictionary initializers
  - `FighterStats` stored stance and skill data as raw dictionary payloads
  - skill selection and damage calculation parsed dynamic dictionaries instead of engine-owned types
- **What was fixed:**
  - introduced typed `CombatSkill` and `CombatSkillEffect`
  - moved `FighterStats` to typed `combatStance`, typed `equippedSkills`, and typed `PassiveBonus`
  - removed legacy dictionary constructors for `CombatConfig`, `FighterStats`, `PassiveBonus`, and `ParsedZoneStance`
  - updated skill selection, cooldown handling, self-buff handling, and damage calculation to operate on typed combat models directly
- **Status:** Fixed

## Problems found

1. **Arena combat still crossed an internal dictionary bridge after the network cleanup**
   - Risk: a central combat flow would continue to accept silent shape drift even after the external API boundary was cleaned up.
   - Fix: converted the `BattlePreloader -> CombatEngine` handoff to direct typed models.

2. **The local prepare decoder carried a wrong `rank_scaling` shape**
   - Risk: rank-based skill damage could silently fall back to defaults because the client was prepared to decode the wrong payload kind.
   - Fix: changed local decoding to scalar `Double?`, matching backend `pvp/prepare`.

3. **Combat simulation logic still depended on stringly typed skill and stance payloads**
   - Risk: changes in client combat math would remain harder to reason about and easier to break than the rest of the typed contract stack.
   - Fix: introduced engine-owned combat types and removed the remaining dictionary parsing from the engine entry surface.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- Hexbound/Hexbound/Services/BattlePreloader.swift Hexbound/Hexbound/Services/CombatEngine.swift`
- `rg -n 'BattleJSONValue|foundationObject|init\\(from dict: \\[String: Any\\]\\)' Hexbound/Hexbound/Services/BattlePreloader.swift Hexbound/Hexbound/Services/CombatEngine.swift`

## Follow-up

- `CombatEngine` is now typed at its handoff boundary, but it still owns combat-specific models that are local to arena simulation rather than shared across every combat surface in `Hexbound`.
- The next honest iOS tail is smaller again: residual combat-contract reuse and any remaining narrow typed-vs-foundation bridges outside the arena path.
