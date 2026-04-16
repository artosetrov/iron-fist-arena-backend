---
title: Block 093 — iOS shop service typed purchase and repair contracts
category: audit
tags: [audit, ios, shop, contracts, repair, upgrades]
sources:
  - Hexbound/Hexbound/Services/ShopService.swift
  - backend/src/app/api/shop/buy/route.ts
  - backend/src/app/api/shop/buy-consumable/route.ts
  - backend/src/app/api/shop/buy-gems/route.ts
  - backend/src/app/api/shop/repair/route.ts
  - backend/src/app/api/shop/upgrade/route.ts
updated: 2026-04-16
status: Fixed
---

# Block 093 — iOS shop service typed purchase and repair contracts

## Scope

- `Hexbound/Hexbound/Services/ShopService.swift`
- `backend/src/app/api/shop/buy/route.ts`
- `backend/src/app/api/shop/buy-consumable/route.ts`
- `backend/src/app/api/shop/buy-gems/route.ts`
- `backend/src/app/api/shop/repair/route.ts`
- `backend/src/app/api/shop/upgrade/route.ts`

## Why this block

After the auth, onboarding, dungeon, and inventory slices were typed, the live shop mutation layer was still one of the last central iOS services using ad hoc purchase bodies and raw response dictionaries.

That was especially risky because the shop is where currency integrity, repair flows, upgrade outcomes, and consumable purchasing all meet.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-092-ios-onboarding-name-and-character-create-typed-contracts]]
- [[economy]]

## File notes

### `Hexbound/Hexbound/Services/ShopService.swift`

- **Zone:** iOS / economy / shop runtime
- **Purpose:** loads shop items and executes live purchase, consumable, gems, repair, and upgrade actions
- **Problems found:**
  - item purchase, consumable purchase, gem purchase, repair, and upgrade still depended on raw bodies or raw currency extraction
  - repair and upgrade each had their own nested-vs-flat currency reconciliation logic
  - this left a core economy service behind the rest of the typed client boundary
- **What was fixed:**
  - added typed DTOs for buy, consumable buy, gems buy, repair, and upgrade flows
  - moved the live shop mutation paths onto `APIClient.post(...)`
  - centralized flat-vs-nested currency resolution into one helper
  - kept the existing quest-refresh and toast behavior intact
- **Status:** Fixed

### `backend/src/app/api/shop/buy/route.ts`

- **Zone:** backend / shop / item purchase
- **Purpose:** sells equipment and item catalog entries
- **Problems found:**
  - no server-side code change was needed here, but the client had still been treating the route as a raw untyped response
- **What was fixed:**
  - client now consumes the canonical shop-buy contract through a typed DTO
- **Status:** OK

### `backend/src/app/api/shop/buy-consumable/route.ts`

- **Zone:** backend / shop / consumable purchase
- **Purpose:** sells direct-sale consumables
- **Problems found:**
  - no new backend defect in this block; the problem was client-side raw handling
- **What was fixed:**
  - iOS now uses a typed consumable purchase request and response instead of raw dictionaries
- **Status:** OK

### `backend/src/app/api/shop/buy-gems/route.ts`

- **Zone:** backend / shop / gold-to-gems conversion
- **Purpose:** converts gold into gems using catalog-backed gem packs
- **Problems found:**
  - the response shape is intentionally flat, unlike some neighboring nested character responses
- **What was fixed:**
  - the client now models that flat contract explicitly instead of guessing from a raw payload
- **Status:** OK

### `backend/src/app/api/shop/repair/route.ts`

- **Zone:** backend / equipment maintenance
- **Purpose:** repairs inventory equipment and returns updated durability plus wallet totals
- **Problems found:**
  - no backend defect here in this block, but the iOS side had been unpacking a mixed nested response manually
- **What was fixed:**
  - added a typed repair response with authoritative durability snapshot and canonical currency reconciliation
- **Status:** OK

### `backend/src/app/api/shop/upgrade/route.ts`

- **Zone:** backend / equipment progression
- **Purpose:** upgrades equipment, returning success state, protection usage, and updated wallet totals
- **Problems found:**
  - upgrade outcome handling still depended on local raw response plumbing
- **What was fixed:**
  - client now uses a typed upgrade response instead of a raw dictionary path
- **Status:** OK

## Problems found

1. **Live shop mutations still bypassed the typed network boundary**
   - Risk: purchases and repairs are high-impact economy flows and should not depend on ad hoc JSON extraction.
   - Fix: moved all central shop mutations to typed request/response DTOs.

2. **Currency reconciliation was duplicated across multiple purchase flows**
   - Risk: one route returning nested `character.gold/gems` and another returning flat `gold/gems` could silently desync the wallet on only one action.
   - Fix: localized flat-vs-nested currency resolution into one helper in `ShopService`.

3. **Repair and upgrade flows treated inventory/economy contracts as raw blobs**
   - Risk: durability and price state could drift more opaquely than a normal typed decode failure.
   - Fix: added explicit repair and upgrade DTOs with authoritative fields for durability, price, level, and protection state.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- Hexbound/Hexbound/Services/ShopService.swift`
- `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(|JSONSerialization' Hexbound/Hexbound/Services/ShopService.swift`

## Follow-up

- `InventoryService` was still the next neighboring live raw-contract slice after this block.
- `ShopService` no longer owns a raw network boundary, but the broader shop/view-model presentation layer still deserves a later keep/simplify pass.
