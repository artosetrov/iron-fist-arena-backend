---
title: Block 101 — iOS interactive combat reconcile payload bridge cleanup
category: audit
tags: [audit, ios, interactive-combat, contracts]
sources:
  - Hexbound/Hexbound/Models/InteractiveCombatModels.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift
  - backend/src/app/api/pvp/strike/route.ts
updated: 2026-04-16
status: Fixed
---

# Block 101 — iOS interactive combat reconcile payload bridge cleanup

## Scope

- `Hexbound/Hexbound/Models/InteractiveCombatModels.swift`
- `Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift`
- `backend/src/app/api/pvp/strike/route.ts`

## Why this block

The last non-infrastructure `JSONSerialization` tail in `Hexbound` sat inside the recoverable `OUT_OF_CONSUMABLE` strike path. The route already returned a parsed error payload through `APIError.responsePayload`, but the client still re-encoded `payload["actives"]` back into JSON just to decode it again.

That was exactly the kind of tiny bridge worth removing once the bigger contract work was done.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-024-interactive-combat-consumable-recovery]]
- [[block-025-backend-active-slot-consumable-ownership-reconciliation]]

## File notes

### `Hexbound/Hexbound/Models/InteractiveCombatModels.swift`

- **Zone:** iOS / combat / DTOs
- **Purpose:** typed transport and local state models for interactive PvP combat
- **Problems found:**
  - there was no direct parser for a server-supplied reconciled `actives` payload that already lived as `[String: Any]`
- **What was fixed:**
  - added a narrow payload bridge for `InteractiveActivesState`
  - added a narrow payload bridge for `InteractiveActiveSlotSnapshot`
  - made accepted snake_case and camelCase keys explicit
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift`

- **Zone:** iOS / combat / interactive PvP
- **Purpose:** owns the live predict/reveal duel state
- **Problems found:**
  - recoverable 409 reconcile flow still performed a JSON round-trip for `actives`
- **What was fixed:**
  - switched the reconcile path to `InteractiveActivesState.fromPayload(...)`
  - removed the local `decodeActivesState` JSON bridge
- **Status:** Fixed

### `backend/src/app/api/pvp/strike/route.ts`

- **Zone:** backend / interactive PvP
- **Purpose:** resolves one strike and returns authoritative combat state
- **Problems found:**
  - no backend code change was required here; the client-side recoverable error bridge was the lagging piece
- **What was fixed:**
  - the iOS client now consumes the reconcile payload directly instead of re-serializing it
- **Status:** OK

## Problems found

1. **Recoverable reconcile logic still used a JSON round-trip**
   - Risk: not a product-wide drift anymore, but it kept the last combat-specific raw bridge alive in a hot runtime path.
   - Fix: added a direct payload parser for reconciled actives.

2. **The accepted reconcile payload shape was hidden in decoder magic**
   - Risk: future changes would be harder to reason about than a direct bridge with named keys.
   - Fix: centralized key handling in `InteractiveCombatModels.swift`.

## Verification

- `git diff --check -- Hexbound/Hexbound/Models/InteractiveCombatModels.swift Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `rg -n 'JSONSerialization' Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift Hexbound/Hexbound/Models/InteractiveCombatModels.swift`

## Follow-up

- After this block, residual `JSONSerialization` in `Hexbound` is isolated to networking/auth infrastructure plus a small cache bridge, not player-facing combat reconciliation code.
