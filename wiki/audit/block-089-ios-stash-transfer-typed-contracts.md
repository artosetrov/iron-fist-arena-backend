---
title: Block 089 — iOS stash transfer typed contracts
category: audit
tags: [audit, ios, stash, inventory, contracts]
updated: 2026-04-16
---

# Block 089 — iOS stash transfer typed contracts

## Scope

- `Hexbound/Hexbound/Services/StashService.swift`

## Why this block existed

Stash loading was already typed, but the two live mutations that players actually hit from inventory and the tavern still went through raw dictionary bodies and `postRaw`. That split one small service into two contract styles and kept deposit/withdraw on a weaker runtime-only path.

Because stash is part of the live equipment flow, this was worth cleaning up while the service was still compact and easy to reason about.

## What the file does

### `Hexbound/Hexbound/Services/StashService.swift`

- Loads the account-level stash
- Deposits unequipped inventory items into stash
- Withdraws stash items back into character inventory
- Maps typed stash payloads into shared `Item` models

## Dependencies

- `APIClient`
- `APIError`
- `APIEndpoints`
- `AppState`
- shared `Item` model
- inventory and tavern stash screens

## Inbound usage

- `Hexbound/Hexbound/Views/Inventory/InventoryViewModel.swift`
- `Hexbound/Hexbound/Views/Minigames/StashViewModel.swift`
- `Hexbound/Hexbound/Views/Minigames/TavernDetailView.swift`

## Fixes made

1. Added typed stash action request and response DTOs.
2. Replaced raw deposit request body with a typed `Encodable` request.
3. Replaced raw withdraw request body with a typed `Encodable` request.
4. Removed the remaining `postRaw` usage from `StashService`.

## Problems found

### 1. Stash writes lagged behind the typed read contract

- **Problem:** `loadStash()` used typed decoding, but `deposit()` and `withdraw()` still used raw dictionaries.
- **Risk:** the same service had two separate encoding/decoding rules, making future stash changes easier to break on one side.
- **Fix:** moved both mutations onto typed request/response DTOs using the shared `APIClient` snake_case encoder.

## What was intentionally left alone

- This block did not widen into inventory or stash view-model orchestration.
- Backend stash race fixes were already handled earlier in the audit, so this pass stayed client-side.

## Keep / fix / delete

- **Keep:** typed stash payload and item mapping
- **Keep:** typed stash mutation requests
- **Fix next:** broader inventory/shop raw-contract cleanup remains outside this block
- **Delete later:** no delete candidate in this block

## Status

**Fixed**
