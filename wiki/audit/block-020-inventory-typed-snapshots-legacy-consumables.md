---
title: Audit Block 020 — Inventory Typed Snapshots and Legacy Consumable Parity
category: audit
tags: [audit, ios, backend, inventory, dto, consumables, api-contracts]
sources:
  - backend/src/app/api/inventory/route.ts
  - backend/src/app/api/inventory/equip/route.ts
  - backend/src/app/api/inventory/unequip/route.ts
  - backend/src/app/api/inventory/use/route.ts
  - backend/src/lib/game/inventory-response.ts
  - Hexbound/Hexbound/Models/Item.swift
  - Hexbound/Hexbound/Services/InventoryService.swift
  - Hexbound/Hexbound/Views/Inventory/InventoryViewModel.swift
updated: 2026-04-15
---

# Audit Block 020 — Inventory Typed Snapshots and Legacy Consumable Parity

## Scope

This block moved one step deeper into the item/inventory layer after [[block-019-ios-contract-fixes-battle-pass-shop-leaderboard]]. The inventory stack had two separate issues:

1. the iOS client still parsed inventory snapshots through raw dictionaries plus `JSONSerialization`, even though the backend already emitted a fairly stable shape;  
2. the legacy `/api/inventory/use` path still used hand-written consumable logic keyed by `itemName` and only really understood stamina potions.

- **Files audited in this block:** 8
- **Primary file types:** Next.js route handlers, backend helpers, Swift services, Swift view models
- **Status:** Inventory snapshots are now decoded through typed DTOs on iOS, equip/unequip now apply the full authoritative snapshot instead of a client-side merge workaround, and legacy equipment-inventory consumables now follow the shared backend consumable rules for both stamina and health potions
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-019-ios-contract-fixes-battle-pass-shop-leaderboard]], [[bug-patterns]], [[progression]]

## Summary

- `InventoryService` still had one of the classic raw-client patterns in the codebase: fetch `[String: Any]`, manually flatten nested equipment rows, serialize them back into JSON, then decode `Item`.
- That raw path was especially awkward because backend equip/unequip already returned the canonical full inventory snapshot through `buildInventoryResponse(...)`, but iOS still threw away everything except equipment rows and forced `InventoryViewModel` to preserve consumables by hand.
- The result was extra local merge logic, more cognitive load, and more room for subtle drift between backend truth and the UI cache.
- Separately, the legacy `/api/inventory/use` route still resolved consumable effects from `itemName` and only had stamina restore tables. That meant older consumable items stored in `equipment_inventory` could diverge from the canonical consumable system used by `/api/consumables/use`.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Legacy `/api/inventory/use` only understood stamina potions via `itemName` lookup. | Old consumables in `equipment_inventory` could apply the wrong effect or reject valid health potions. | Switched the route to derive a canonical `ConsumableType` from `catalogId` with a legacy item-name fallback, then routed it through shared consumable helpers. |
| P2 | `InventoryService.loadInventory()` still used raw dictionaries plus manual flattening and JSON re-encoding. | Brittle parsing, weak contracts, and unnecessary client-side transformation glue. | Added typed inventory snapshot DTOs in the service and moved inventory decoding to `APIClient.get(...)`. |
| P2 | Equip/unequip client flow still assumed the server returned only equipment rows and had to merge consumables locally. | Stale workaround logic remained even after backend started returning full snapshots; easier to regress cache correctness. | Switched `InventoryService.equip/unequip` to typed full-snapshot decoding and simplified `InventoryViewModel` to apply the authoritative response directly. |
| P3 | Inventory snapshot contract existed on backend (`buildInventoryResponse`) but iOS still treated it like a partially trustworthy payload. | Cross-file architecture drift and higher maintenance cost. | Re-aligned the client with the backend helper’s actual contract. |

## Cross-File Safe Fixes Applied

- `Hexbound/Hexbound/Services/InventoryService.swift` now decodes inventory/equip/unequip responses through typed DTOs instead of raw dictionaries and manual flattening.
- `Hexbound/Hexbound/Views/Inventory/InventoryViewModel.swift` no longer needs the `mergeEquipmentResponse(...)` workaround because equip/unequip now return the full authoritative inventory snapshot.
- `backend/src/app/api/inventory/use/route.ts` now resolves legacy consumables through canonical `ConsumableType` logic and shared restore helpers, so health potions are handled consistently with the modern consumables flow.
- Re-audited the canonical backend snapshot shape across `GET /api/inventory`, equip, unequip, and `buildInventoryResponse(...)` to confirm the client can trust one consistent structure.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/app/api/inventory/route.ts` | Backend inventory GET API | Returns the player inventory snapshot with equipment, consumables, and slot count. | Used by `InventoryService`. Depends on auth, Prisma, item-balance helper, item constants. | Snapshot must stay structurally aligned with equip/unequip so the client can decode one authoritative contract. | Re-audited here; current shape is stable enough for typed client decoding. | OK |
| `backend/src/app/api/inventory/equip/route.ts` | Backend equip mutation API | Equips an item with slot validation, two-handed rules, and cache invalidation. | Used by `InventoryService.equip()`. Depends on auth, Prisma transaction, inventory snapshot helper, combat cache invalidators. | Must return the same canonical inventory snapshot as GET after mutation. | Re-audited here; no code change in this block, but its full-snapshot contract is now actually consumed by the client. | OK |
| `backend/src/app/api/inventory/unequip/route.ts` | Backend unequip mutation API | Unequips an item and returns the canonical inventory snapshot. | Used by `InventoryService.unequip()`. Depends on auth, Prisma, inventory snapshot helper. | Must converge optimistic state back to authoritative inventory without dropping consumables. | Re-audited here; no code change in this block, but its full-snapshot contract is now actually consumed by the client. | OK |
| `backend/src/app/api/inventory/use/route.ts` | Backend legacy equipment-inventory consumable use API | Consumes old consumable items that still live in `equipment_inventory`. | Used by `InventoryService.useItem(...)` when `consumableType` is absent. Depends on auth, Prisma, stamina/hp helpers, quest progress. | Legacy path must still obey the same consumable-effect rules as the main consumables system. | Replaced `itemName`-only stamina logic with canonical `ConsumableType` resolution plus shared stamina/health helpers. | Fixed |
| `backend/src/lib/game/inventory-response.ts` | Backend shared inventory snapshot helper | Builds the canonical `{ equipment, consumables, inventorySlots }` payload for GET/equip/unequip. | Used by inventory GET/equip/unequip routes. Depends on Prisma, item-balance helper, item constants. | This helper is the contract source of truth for inventory snapshots. | Re-audited here; client is now aligned with it instead of reinterpreting partial slices. | OK |
| `Hexbound/Hexbound/Models/Item.swift` | iOS inventory/shop item model | Shared item model used across inventory, loot, hero, arena, and comparison UI. | Used broadly across item-facing views and services. | Must remain compatible with equipment inventory items and client-side consumable mapping. | Re-audited here. The old `+1` fallback warning was later closed by [[block-159-ios-game-init-item-stat-preview-parity]] and [[block-165-ios-upgrade-stat-bonus-config-fallback-parity]], which aligned authoritative stat hydration and config-backed local fallback math. | Fixed |
| `Hexbound/Hexbound/Services/InventoryService.swift` | iOS inventory service | Loads inventory and executes equip/unequip/sell/use/expand actions. | Used by `InventoryViewModel`, hero/inventory surfaces, and other cache-warming paths. Depends on `APIClient` and `AppState`. | Inventory reads and equip/unequip writes should consume the backend snapshot contract directly. | Added typed snapshot DTOs, removed raw flatten/serialize decode path, and switched equip/unequip to full authoritative snapshot decoding. | Fixed |
| `Hexbound/Hexbound/Views/Inventory/InventoryViewModel.swift` | iOS inventory view model | Owns optimistic UI flows and inventory-grid state. | Used by hero/inventory screens. Depends on `InventoryService`, `ShopService`, `AppState`. | Optimistic actions should collapse back to authoritative server state cleanly and with minimal merge logic. | Removed the now-stale equipment-only merge workaround and now applies the full server snapshot after equip/unequip. | Fixed |

## Duplicate / Split Logic Found

- Client-side consumable display metadata still exists in more than one place (`InventoryService`, `ShopItem`, `Item`, `ShopOffer`), which means display names, rarity, and image-key rules can still drift over time.
- Inventory stat presentation still splits responsibility between backend-returned `effectiveStats` and client-side recomputation in `Item.effectiveStats`, but the old hard-coded upgrade-bonus drift was closed later by [[block-159-ios-game-init-item-stat-preview-parity]] and [[block-165-ios-upgrade-stat-bonus-config-fallback-parity]].

## Files Without Clear Current Role

- None in this block. All touched files sit on active inventory or consumable flows.

## Candidates For Refactor

- Extract a shared iOS consumable catalog helper so inventory/shop/item-detail flows stop carrying parallel display-name / rarity / image-key maps.
- Normalize `Item` stat presentation around authoritative backend `effectiveStats` everywhere possible, or document where best-effort local preview is still intentionally allowed for partial/offline item contexts.

## Documentation Missing Or Stale

- The wiki still lacks a dedicated page for item/inventory response contracts and client stat-authority rules; right now that knowledge is spread across code comments and audit blocks.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- `npx eslint src/app/api/inventory/use/route.ts` passes from `/backend`.
- `git diff --check` passes after the inventory changes.
