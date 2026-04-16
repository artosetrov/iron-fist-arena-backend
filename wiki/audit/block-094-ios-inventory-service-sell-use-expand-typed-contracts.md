---
title: Block 094 — iOS inventory service sell, use, and expand typed contracts
category: audit
tags: [audit, ios, inventory, consumables, contracts]
sources:
  - Hexbound/Hexbound/Services/InventoryService.swift
  - backend/src/app/api/inventory/sell/route.ts
  - backend/src/app/api/inventory/use/route.ts
  - backend/src/app/api/consumables/use/route.ts
  - backend/src/app/api/inventory/expand/route.ts
updated: 2026-04-16
status: Fixed
---

# Block 094 — iOS inventory service sell, use, and expand typed contracts

## Scope

- `Hexbound/Hexbound/Services/InventoryService.swift`
- `backend/src/app/api/inventory/sell/route.ts`
- `backend/src/app/api/inventory/use/route.ts`
- `backend/src/app/api/consumables/use/route.ts`
- `backend/src/app/api/inventory/expand/route.ts`

## Why this block

Once `ShopService` was typed, `InventoryService` still had one residual raw mutation tail:

- sell
- consumable use
- inventory expansion

That meant a core player-state service still mixed typed inventory snapshots with raw mutation handling.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-093-ios-shop-service-typed-purchase-and-repair-contracts]]
- [[progression]]

## File notes

### `Hexbound/Hexbound/Services/InventoryService.swift`

- **Zone:** iOS / inventory / live character state
- **Purpose:** loads inventory, equips items, sells items, consumes items, and expands bag capacity
- **Problems found:**
  - sell, use, and expand still used raw mutation plumbing even after equip/unequip and load paths were typed
  - HP/stamina updates from consumable use still depended on loosely unpacked response shape
  - this left one of the most central character-state services partially outside the typed client boundary
- **What was fixed:**
  - added typed DTOs for sell, consumable use, and inventory expansion
  - moved those mutation paths onto `APIClient.post(...)`
  - updated HP/stamina reconciliation to read typed resource deltas
  - kept the existing optimistic-update and quest-refresh behavior intact
- **Status:** Fixed

### `backend/src/app/api/inventory/sell/route.ts`

- **Zone:** backend / inventory / selling
- **Purpose:** sells an inventory item and returns authoritative wallet totals
- **Problems found:**
  - no backend code change was required here in this block
- **What was fixed:**
  - the client now consumes the route through a typed sell DTO instead of raw JSON
- **Status:** OK

### `backend/src/app/api/inventory/use/route.ts`

- **Zone:** backend / inventory / consumable item use
- **Purpose:** consumes equipment-backed usable items
- **Problems found:**
  - no new backend defect here in this block; the client side was the lagging contract consumer
- **What was fixed:**
  - the inventory-item consumable path is now typed on iOS
- **Status:** OK

### `backend/src/app/api/consumables/use/route.ts`

- **Zone:** backend / consumables / direct consumable inventory
- **Purpose:** uses stored consumables like potions from the consumable inventory layer
- **Problems found:**
  - resource-delta parsing on iOS was still weaker than the rest of the typed client boundary
- **What was fixed:**
  - the response is now consumed as typed stamina/health deltas instead of loosely unpacked dictionaries
- **Status:** OK

### `backend/src/app/api/inventory/expand/route.ts`

- **Zone:** backend / inventory capacity
- **Purpose:** expands inventory slots and returns updated bag size plus gold total
- **Problems found:**
  - no backend change was needed, but iOS had still been treating this live mutation as a raw body/response path
- **What was fixed:**
  - the expand-inventory path is now typed end to end on the client
- **Status:** OK

## Problems found

1. **`InventoryService` still mixed typed snapshots with raw live mutations**
   - Risk: sell/use/expand could drift independently from equip/load behavior and fail later than a normal typed decode.
   - Fix: moved the remaining live mutation paths onto typed DTOs.

2. **Consumable resource updates still depended on weak response parsing**
   - Risk: HP/stamina corrections after consumable use could silently break if the server adjusted shape or nesting.
   - Fix: introduced typed resource-delta DTOs for stamina and health.

3. **Bag-capacity expansion still relied on a raw body/response pair**
   - Risk: a core monetization/progression flow remained harder to reason about than adjacent typed services.
   - Fix: added explicit request and response models for inventory expansion.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- Hexbound/Hexbound/Services/InventoryService.swift`
- `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization' Hexbound/Hexbound/Services/InventoryService.swift`

## Follow-up

- The next central live raw-contract slice after this block was `BattlePreloader`.
- `InventoryService` still contains normal business logic and optimistic-state rules, but its network mutation boundary is no longer the weak point.
