---
title: Audit Block 021 — Item Stat Authority and Shared Consumable Catalog
category: audit
tags: [audit, ios, backend, inventory, stash, consumables, stats]
sources:
  - backend/src/lib/game/inventory-response.ts
  - backend/src/app/api/stash/route.ts
  - Hexbound/Hexbound/Models/ConsumableCatalog.swift
  - Hexbound/Hexbound/Models/Item.swift
  - Hexbound/Hexbound/Models/ShopItem.swift
  - Hexbound/Hexbound/Models/ShopOffer.swift
  - Hexbound/Hexbound/Services/InventoryService.swift
  - Hexbound/Hexbound/Services/StashService.swift
  - Hexbound/Hexbound/Views/Inventory/ItemDetailActions.swift
updated: 2026-04-17
---

# Audit Block 021 — Item Stat Authority and Shared Consumable Catalog

## Scope

This block continues the inventory/stash cleanup from [[block-020-inventory-typed-snapshots-legacy-consumables]]. After the typed snapshot pass, two cross-file drift sources were still active:

1. iOS still duplicated consumable display metadata in multiple files, so names, rarity, icons, and asset keys could quietly diverge between inventory, shop, offers, and item-detail UI;
2. inventory/stash responses already carried backend `effectiveStats`, but the client still recomputed upgrade math locally and hard-coded `+1` preview rules in several places.

- **Files audited in this block:** 9
- **Primary file types:** Swift models, Swift services, Swift inventory UI, backend snapshot helpers
- **Status:** Shared consumable metadata now lives in one iOS helper, inventory/stash items now preserve backend-authored `effectiveStats`, and upgrade previews no longer hard-code `+1` when authoritative stat data is already available
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-020-inventory-typed-snapshots-legacy-consumables]], [[bug-patterns]], [[progression]]

## Summary

- `Item`, `ShopItem`, `ShopOffer`, and `InventoryService` each still carried their own consumable naming or image-resolution rules. That meant a single catalog change could leave inventory, shop cards, offer descriptions, and modal UI disagreeing about the same item.
- The typed snapshot work in block 020 fixed decoding, but iOS still dropped the backend `effectiveStats` field on the floor. That made the client keep guessing upgrade math locally even though the server already returned a more authoritative answer.
- `StashService` still used the old raw-dictionary flattening path, which meant stash and inventory had drifted into two different contract-consumption styles for nearly the same payload shape.
- `ItemDetailActions` still rendered upgrade previews as `+1` per stat. That was only accidentally correct while `upgrade_stat_bonus_per_level == 1`.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Consumable metadata was duplicated across multiple iOS models/services. | Inventory, shop, and offer UI could disagree on names, rarity, icons, or asset keys for the same catalog item. | Added shared `ConsumableCatalog` and moved consumable name/icon/image/rarity resolution onto that single helper. |
| P1 | Inventory/stash DTOs decoded `effectiveStats` but did not preserve them on `Item`. | Client-side stat display and upgrade previews could drift from backend config changes. | Added `authoritativeEffectiveStats` to `Item` and threaded backend `effectiveStats` through `InventoryService` and `StashService`. |
| P2 | `StashService` still used raw JSON flattening while inventory had already moved to typed DTOs. | Same domain concept was maintained through two different parsing styles; stash contract changes were easier to miss. | Replaced stash raw parsing with typed DTOs and mapped nested stash payloads directly into `Item`. |
| P2 | Upgrade preview UI still hard-coded `(+1)` stat deltas. | Misleading upgrade preview if backend config changes away from 1, or if an item already carries non-default authoritative upgrade totals. | Added `Item.upgradeIncrementPerStat` and used it in item-detail preview rows. |

## Cross-File Safe Fixes Applied

- Added `Hexbound/Hexbound/Models/ConsumableCatalog.swift` as the canonical iOS catalog for consumable display name, rarity, asset key, SF Symbol, tint color, and legacy `pot_*` remaps.
- Updated `Item`, `ShopItem`, and `ShopOffer` to resolve consumable presentation through `ConsumableCatalog` instead of parallel local maps.
- Added `authoritativeEffectiveStats` to `Item` and taught inventory/stash typed DTOs to pass backend `effectiveStats` through instead of discarding them.
- Replaced `StashService` raw `JSONSerialization`/flattening with typed DTOs, matching the contract style already adopted in `InventoryService`.
- Switched item-detail upgrade preview rows from hard-coded `+1` to a best-effort per-level increment derived from authoritative server stats when available.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/lib/game/inventory-response.ts` | Backend inventory snapshot helper | Builds the canonical inventory payload for inventory GET/equip/unequip. | Used by inventory routes; consumed by `InventoryService`. | Snapshot owns `effectiveStats` for equipment rows and should remain the server contract source of truth. | Re-audited again in [[block-158-backend-item-stat-authority-rolled-stats-parity]]; snapshot `effectiveStats` now include `rolledStats` through the shared backend item-stat helper. | Fixed |
| `backend/src/app/api/stash/route.ts` | Backend stash snapshot API | Returns account-level stash items plus slot counts. | Used by `StashService`. Depends on Prisma and item-balance config. | Stash snapshot should follow the same stat-authority rules as inventory snapshots. | Re-audited again in [[block-158-backend-item-stat-authority-rolled-stats-parity]]; stash `effectiveStats` now follow the same merged `baseStats + rolledStats` rule as inventory. | Fixed |
| `Hexbound/Hexbound/Models/ConsumableCatalog.swift` | iOS shared consumable presentation helper | Centralizes consumable display metadata and legacy key normalization. | Used by `Item`, `ShopItem`, `ShopOffer`, and `InventoryService`. | Canonical place for consumable names, rarity, image keys, icons, and legacy remaps on iOS. | New helper removed repeated metadata tables from multiple files. | Fixed |
| `Hexbound/Hexbound/Models/Item.swift` | iOS shared item model | Represents equipment and consumables across inventory, loot, shop, and comparison UI. | Used broadly across the app. | Should prefer authoritative server stats when present without regressing legacy callers. | Added `authoritativeEffectiveStats`, consumed server stats when available, and exposed best-effort upgrade preview increment. [[block-159-ios-game-init-item-stat-preview-parity]] fixed the rolled-gear preview drift by deriving preview bonus from merged `base + rolled` stats, and [[block-165-ios-upgrade-stat-bonus-config-fallback-parity]] removed the last hard-coded `+1` fallback by seeding local preview math from backend config. The remaining client question is only whether local preview should exist at all in zero-level / partial contexts. | Fixed |
| `Hexbound/Hexbound/Models/ShopItem.swift` | iOS shop catalog DTO | Represents shop items and consumables in store surfaces. | Used by `ShopService` and shop UI. | Consumable presentation must stay aligned with inventory/item-detail UI. | Removed duplicated consumable remap/icon logic and delegated to `ConsumableCatalog`. | Fixed |
| `Hexbound/Hexbound/Models/ShopOffer.swift` | iOS special-offer DTO | Renders bundle offers and human-readable offer descriptions. | Used by shop offer UI and purchase flows. | Offer descriptions should not leak raw catalog ids to the player. | Replaced local known-item table with shared catalog display resolution. | Fixed |
| `Hexbound/Hexbound/Services/InventoryService.swift` | iOS inventory service | Loads full inventory snapshots and performs inventory mutations. | Used by `InventoryViewModel`, hero, and inventory surfaces. | Contract consumer should preserve authoritative server stat payloads instead of recomputing everything locally. | Threaded backend `effectiveStats` into `Item` and switched consumable mapping to the shared catalog helper. | Fixed |
| `Hexbound/Hexbound/Services/StashService.swift` | iOS stash service | Loads stash contents and performs deposit/withdraw calls. | Used by stash UI and inventory-adjacent flows. | Stash should consume the same typed-contract style as inventory. | Replaced raw parsing with typed DTOs and preserved authoritative stats on mapped `Item` models. | Fixed |
| `Hexbound/Hexbound/Views/Inventory/ItemDetailActions.swift` | iOS inventory item-detail action UI | Renders upgrade/repair/sell action panel and preview rows. | Used by item-detail sheets in inventory and loot flows. | Upgrade preview should reflect backend upgrade math as closely as the client can know. | Removed hard-coded `+1` preview and now uses `Item.upgradeIncrementPerStat`. | Fixed |

## Duplicate / Split Logic Found

- Consumable presentation metadata was duplicated in four separate client files before this block. That duplication is now collapsed into `ConsumableCatalog`.
- Stat authority is better than before: backend rolled-stat parity is closed by [[block-158-backend-item-stat-authority-rolled-stats-parity]], cold-start item hydration/rolled preview parity is closed by [[block-159-ios-game-init-item-stat-preview-parity]], and config-driven fallback preview parity is closed by [[block-165-ios-upgrade-stat-bonus-config-fallback-parity]]. A local client fallback still exists for item flows that do not carry authoritative snapshot data yet.

## Files Without Clear Current Role

- None in this block. All touched files sit on active inventory/stash/shop UI paths.

## Candidates For Refactor

- None in this block after [[block-165-ios-upgrade-stat-bonus-config-fallback-parity]] closed the config-exposed upgrade preview tail.

## Documentation Missing Or Stale

- There is still no dedicated wiki page describing the exact stat-authority contract for items: when the client should trust `effectiveStats`, when it can recompute locally, and how rolled stats are supposed to participate.

## Requires Separate Decision

- The remaining decision is now very narrow and client-focused: in zero-level or partial/local-only item contexts, should iOS keep rendering a best-effort fallback preview, or should those surfaces wait for authoritative backend `effectiveStats` before showing upgrade deltas?

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- `rg -n "consumableDisplayNames|consumableImageKeys|knownItemKeys|legacyKeyRemap|pot_stamina_small|pot_health_small" Hexbound/Hexbound -g '*.swift'` now reports the new shared helper instead of parallel metadata tables across the app.
- `git diff --check` passes after the item/stat/catalog changes.
