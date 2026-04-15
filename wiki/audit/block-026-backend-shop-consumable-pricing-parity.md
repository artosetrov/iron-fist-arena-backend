---
title: Audit Block 026 — Backend Shop Consumable Pricing Parity
category: audit
tags: [audit, backend, shop, consumables, economy, contracts]
sources:
  - backend/src/app/api/shop/items/route.ts
  - backend/src/app/api/shop/buy-consumable/route.ts
  - backend/src/app/api/shop/buy-potion/route.ts
  - backend/src/app/api/passives/active-slots/route.ts
  - backend/src/lib/game/consumable-pricing.ts
  - Hexbound/Hexbound/Services/ShopService.swift
updated: 2026-04-15
---

# Audit Block 026 — Backend Shop Consumable Pricing Parity

## Scope

This block follows directly from [[block-025-backend-active-slot-consumable-ownership-reconciliation]]. Once active-slot ownership became server-authoritative, the next adjacent drift was pricing:

- shop listing fallback prices,
- shop transaction fallback prices,
- active-slot picker price metadata,
- and the set of consumables that are actually allowed to be bought directly.

That drift was no longer cosmetic. `ShopViewModel` deducts gold optimistically from the listed price, so if listing and transaction disagree, the client briefly lies to the player and then needs the server response to bail it out.

- **Files audited in this block:** 6
- **Primary file types:** backend shop/passive routes and one iOS consumer
- **Status:** direct-sale consumable pricing now has one backend source of truth, listing and transaction fallbacks agree again, and reward-only consumables can no longer be bought via direct API calls
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[economy]], [[passive-tree]], [[block-025-backend-active-slot-consumable-ownership-reconciliation]], [[block-019-ios-contract-fixes-battle-pass-shop-leaderboard]]

## Summary

- `shop/items` used one fallback price table, while `buy-consumable` and active-slot price metadata used another.
- In the fallback path, the shop could list a potion at one price and charge a different amount when purchased.
- `buy-consumable` validated against the full `ConsumableType` enum, not the "sold directly in shop" subset. That meant reward-only consumables like `protection_scroll` and `legendary_shard` could slip through direct API purchase paths.
- `buy-potion` carried its own legacy stamina-potion price table, which was another copy of the same balance rule.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Listing and transaction fallback prices for consumables disagreed. | Client optimistic currency updates and visible shop prices could diverge from what the server actually charged. | Added a shared backend consumable-pricing helper and moved listing, direct buy, legacy potion buy, and active-slot picker price metadata onto the same fallback source. |
| P1 | `buy-consumable` accepted the full `ConsumableType` enum. | Reward-only consumables could be purchased directly through API calls, including zero-price loopholes when fallback values were `0`. | Added a direct-sale allowlist and now reject non-shop consumable types at the route boundary. |
| P2 | `shop/items` listed every DB consumable, not only direct-sale ones plus gem packs. | Future reward-only consumables could accidentally appear in the regular consumable shop. | Shop listing now filters non-gem-pack consumables through the same direct-sale allowlist. |
| P2 | Legacy `buy-potion` route duplicated stamina pricing. | Yet another drift vector between old and new shop endpoints. | Legacy route now uses the shared pricing helper and explicitly limits itself to stamina potion types. |

## Cross-File Safe Fixes Applied

- Added `backend/src/lib/game/consumable-pricing.ts` as the canonical backend helper for:
  - direct-sale consumable allowlist,
  - fallback consumable prices,
  - GameConfig-backed consumable price lookup,
  - batch price-map loading for shop catalog routes.
- `backend/src/app/api/shop/items/route.ts` now loads direct-sale consumable prices from the shared helper and hides reward-only consumables from the normal shop list.
- `backend/src/app/api/shop/buy-consumable/route.ts` now accepts only direct-sale potion types and charges the same fallback values the listing uses.
- `backend/src/app/api/shop/buy-potion/route.ts` now reuses the shared pricing helper instead of keeping a separate stamina table.
- `backend/src/app/api/passives/active-slots/route.ts` now pulls picker `price_gold` metadata from the same helper, so the active-skill picker no longer has its own private fallback prices.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/lib/game/consumable-pricing.ts` | Backend shop pricing helper | Canonical helper for direct-sale consumable allowlist and GameConfig-backed fallback prices. | Used by shop listing, consumable purchase routes, and active-slot picker metadata. | Direct-sale shop consumables are a subset of the enum; listing and transaction pricing must agree. | New helper extracted to eliminate duplicated price tables and route-local allowlists. | Fixed |
| `backend/src/app/api/shop/items/route.ts` | Backend shop catalog API | Returns shop inventory for equipment, direct-sale consumables, and gem packs. | Used by `ShopService` and shop UI. Depends on auth, Prisma, gem pack constants, pricing helper. | Shop list must not advertise items the direct-purchase route will refuse or charge differently. | Fixed listing/transaction fallback drift and filtered reward-only consumables out of the direct-sale shop. | Fixed |
| `backend/src/app/api/shop/buy-consumable/route.ts` | Backend direct consumable purchase API | Sells potions into `consumable_inventory` for gold. | Used by `ShopService.buyConsumable()`. Depends on auth, rate limits, Prisma, pricing helper. | Only direct-sale potions belong here; reward-only consumables must never be buyable via this route. | Fixed full-enum validation bug and removed route-local fallback pricing table. | Fixed |
| `backend/src/app/api/shop/buy-potion/route.ts` | Backend legacy stamina-potion purchase API | Legacy alias-like route for stamina potion purchases. | Still reachable from older client code paths; depends on Prisma and quest progress helpers. | Must remain price-aligned with the canonical consumable shop until fully retired. | Fixed separate stamina price table and narrowed validation to stamina potion types only. | Fixed |
| `backend/src/app/api/passives/active-slots/route.ts` | Backend active-slot read/equip API | Exposes active-slot state and potion picker metadata for the passive-tree editor. | Used by iOS talent loadout editor. Depends on auth, cache, Prisma, active-slot helper, pricing helper. | Picker price metadata should match the same canonical backend consumable price logic as the shop. | Replaced route-local fallback pricing with shared helper usage. | Fixed |
| `Hexbound/Hexbound/Services/ShopService.swift` | iOS shop service | Loads the shop catalog and performs buy flows with optimistic currency updates. | Used by `ShopViewModel`. Depends on `APIClient`, `AppState`, and backend shop contracts. | Optimistic gold deduction assumes the listed price matches what the backend will actually charge. | Re-audited; no client code change needed once backend listing/transaction parity was restored. | OK |

## Duplicate / Split Logic Found

- Pricing and allowlist drift used to exist between shop listing, direct buy, legacy potion buy, and active-slot picker metadata. This block collapses those to one backend helper.
- Reward-only consumables still exist in the global enum, which is fine, but direct-sale routes must always validate against the smaller business-rule subset, not the enum itself.

## Files Without Clear Current Role

- None in this block. Every file is on a live shop, passive-tree, or client purchase path.

## Candidates For Refactor

- `buy-potion` is still legacy surface area. It is now aligned, but still looks like a candidate for eventual consolidation into `buy-consumable` once all callers are confirmed migrated.
- Fallback pricing is now centralized, but the higher-level "economy retune" story is still split between docs/specs/seed comments and live `GameConfig` rollout state.

## Documentation Missing Or Stale

- Product docs are ambiguous about fallback potion pricing: seed/spec sources still document `100/250/500` and `150/350/700`, while some economy notes reference a later +25–35% increase without a single rollout source. The code now follows the seeded transactional fallback until `GameConfig` overrides it, but that policy should be documented explicitly.

## Requires Separate Decision

- If the team wants the higher potion prices described in some economy notes to become the true baseline, that should be rolled out through explicit `GameConfig` values and docs updates, not by leaving route-local fallback tables to drift independently.

## Verification

- `npx eslint src/lib/game/consumable-pricing.ts src/app/api/passives/active-slots/route.ts src/app/api/shop/buy-consumable/route.ts src/app/api/shop/buy-potion/route.ts src/app/api/shop/items/route.ts` passes.
- `git diff --check` passes after the pricing/helper and wiki updates.
