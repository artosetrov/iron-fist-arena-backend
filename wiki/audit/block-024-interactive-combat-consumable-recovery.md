---
title: Audit Block 024 — Interactive Combat Consumable Recovery
category: audit
tags: [audit, backend, ios, combat, consumables, recovery, contracts]
sources:
  - backend/src/app/api/pvp/match/start/route.ts
  - backend/src/app/api/pvp/strike/route.ts
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift
  - Hexbound/Hexbound/Models/InteractiveCombatModels.swift
  - Hexbound/Hexbound/Network/APIError.swift
updated: 2026-04-15
---

# Audit Block 024 — Interactive Combat Consumable Recovery

## Scope

This block follows directly from [[block-023-ios-interactive-combat-terminal-state-and-round-log]]. Once terminal-state handling was corrected, the next unstable edge in interactive combat was the consumable mismatch path:

- a potion slot can exist in the match snapshot,
- the real inventory can change out of band before the strike resolves,
- `/pvp/strike` then throws `OUT_OF_CONSUMABLE`.

Before this block, that mismatch collapsed the whole duel into a terminal error path on iOS even though the match itself was still perfectly recoverable.

- **Files audited in this block:** 6
- **Primary file types:** backend PvP routes, Swift interactive-combat runtime and contract handling
- **Status:** interactive combat now recovers in-place from out-of-band potion depletion instead of terminating the match, and `/match/start` no longer snapshots empty consumable slots into the duel
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[interactive-combat]], [[block-023-ios-interactive-combat-terminal-state-and-round-log]], [[block-022-ios-active-skill-picker-passive-tree-contracts]]

## Summary

- `/pvp/match/start` previously snapshotted consumable slots from `character_active_slots` without checking whether the player still had any quantity in `consumable_inventory`.
- `/pvp/strike` detected the problem late, after the player tried to fire the potion, and returned a plain 400 error with no recovery payload.
- `InteractiveBattleViewModel.resolveStrike()` treated that like any other failure and moved the route into `.error`, which popped the player out of the fight for what should have been a recoverable state reconciliation.
- The result was a poor UX and a broken server/client contract boundary: the server knew exactly what went wrong, but did not provide enough state for the client to continue.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | `/pvp/strike` returned a plain terminal error for `OUT_OF_CONSUMABLE`. | A recoverable inventory mismatch ejected the player from a live duel. | Server now returns a structured 409 recovery payload with `code`, reconciled `actives`, and removed slot metadata. |
| P1 | iOS treated potion-depletion mismatch as a fatal strike failure. | Match route popped to an error state even though no round had been consumed yet. | `InteractiveBattleViewModel` now recognizes the recovery payload, updates actives, clears the pending slot, restarts predict, and shows an informational toast. |
| P2 | `/pvp/match/start` snapshotted potion slots even when quantity was already zero. | Match could start with an impossible consumable slot and fail on the first use attempt. | Start route now joins `consumable_inventory` and only snapshots consumable slots with `quantity > 0`. |

## Cross-File Safe Fixes Applied

- `backend/src/app/api/pvp/match/start/route.ts` now filters consumable snapshots through `consumable_inventory.quantity > 0`, so empty potion slots do not enter a fresh match.
- `backend/src/app/api/pvp/strike/route.ts` now reconciles `OUT_OF_CONSUMABLE` by removing the impossible slot from the persisted match `interactiveActives` snapshot and returning a recoverable 409 payload instead of a dead-end 400.
- `InteractiveBattleViewModel` now branches on `APIError.responsePayload.code == "OUT_OF_CONSUMABLE"`, decodes reconciled actives, clears the queued slot, restarts the predict timer, and keeps the fight alive.
- `InteractiveBattleView` route-wrapper behavior did not need code changes; the fix works by preventing this mismatch from ever reaching terminal `.error`.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/app/api/pvp/match/start/route.ts` | Backend interactive match bootstrap | Starts a duel and snapshots active slots into match state. | Used by `InteractiveBattleViewModel.startMatch()`. Depends on stamina logic, combat loader, and active-slot snapshot queries. | Fresh match snapshots should only include consumables that are actually usable at match start. | Fixed consumable snapshot query to require positive inventory quantity. | Fixed |
| `backend/src/app/api/pvp/strike/route.ts` | Backend per-round resolver | Resolves one interactive strike, mutates active slots, decrements consumables, and returns updated match state. | Used by `InteractiveBattleViewModel.resolveStrike()`. Depends on persisted `interactiveActives` and inventory rows. | Inventory mismatch on a consumable fire should reconcile state instead of poisoning the whole duel. | Fixed `OUT_OF_CONSUMABLE` path to strip the impossible slot from match state and return structured recovery data. | Fixed |
| `Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift` | iOS interactive combat orchestration | Handles match start, strike resolution, reveal, summary, and completion phases. | Used by `InteractiveBattleView`; depends on interactive combat DTOs and `APIClient`. | Recoverable contract errors should restore `predict` flow instead of collapsing the route into terminal `.error`. | Added typed recovery handling for `OUT_OF_CONSUMABLE`, including actives decode + timer restart. | Fixed |
| `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift` | iOS route host and terminal router | Hosts the combat screen and reacts to terminal phases. | Used by router/navigation. Depends on `InteractiveBattleViewModel`. | Terminal handler should only fire for actual terminal phases, not recoverable mid-match reconciliation. | Re-audited; fix achieved by keeping VM out of `.error`, so no code change required here. | OK |
| `Hexbound/Hexbound/Models/InteractiveCombatModels.swift` | iOS interactive combat DTOs | Decodes match start/strike payloads and local state. | Used by VM and combat UI. | Contract payloads must remain decodable when `actives` arrive through normal success path or recoverable error path. | Re-audited alongside the recovery decode path; existing DTOs were sufficient. | OK |
| `Hexbound/Hexbound/Network/APIError.swift` | iOS API error wrapper | Carries parsed 4xx payloads for client-side branching. | Used across the app; directly consumed by `InteractiveBattleViewModel` here. | Parsed 4xx body is the mechanism that enables safe contract-aware recovery on the client. | Re-audited; existing `responsePayload` / `statusCode` support was already the right abstraction. | OK |

## Duplicate / Split Logic Found

- Consumable-slot validity was previously checked twice, but too late in the lifecycle: once implicitly by the match snapshot and once explicitly on fire. This block moves the first check earlier and makes the second one recoverable.
- Client/server recovery responsibility is now cleaner: backend reconciles authoritative match state, client restores UI state.

## Files Without Clear Current Role

- None. All files in this block are on the active interactive-combat runtime path.

## Candidates For Refactor

- The out-of-combat loadout editor still allows a potion to remain equipped even when owned quantity drops to zero. Combat now recovers safely, but the editor/runtime contract would be cleaner if zero-quantity consumable slots were surfaced and cleaned up earlier.
- If more recoverable error codes appear in combat, `InteractiveBattleViewModel` may deserve a small typed `RecoverableCombatError` decoder/helper instead of local payload branching.

## Documentation Missing Or Stale

- There is still no dedicated wiki page documenting which interactive-combat errors are terminal versus recoverable, and what payload shape each recoverable code must return.

## Requires Separate Decision

- Resolved in [[block-025-backend-active-slot-consumable-ownership-reconciliation]]: zero-quantity potion slots are now cleaned up server-side outside combat as well. The remaining product decision is narrower: whether repurchasing a potion should auto-restore the previously pruned slot or continue requiring manual re-equip.

## Verification

- `npx eslint src/app/api/pvp/match/start/route.ts src/app/api/pvp/strike/route.ts` passes.
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- `git diff --check` passes after the recovery-path changes and wiki updates.
