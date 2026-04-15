---
title: Audit Block 027 — Shop Legacy Client Surface and Pricing Docs
category: audit
tags: [audit, ios, backend, shop, docs, economy, legacy]
sources:
  - Hexbound/Hexbound/Network/APIEndpoints.swift
  - Hexbound/Hexbound/Services/ShopService.swift
  - backend/src/app/api/shop/buy-potion/route.ts
  - docs/features/shop/SHOP_OVERVIEW.md
  - wiki/systems/economy.md
  - wiki/decisions/rebalance-w3d3.md
updated: 2026-04-15
---

# Audit Block 027 — Shop Legacy Client Surface and Pricing Docs

## Scope

This block follows [[block-026-backend-shop-consumable-pricing-parity]]. Once shop pricing and allowlists were made consistent, the remaining questions were:

1. does the current iOS client still use the legacy `/api/shop/buy-potion` route at all?
2. what do project docs now claim about potion pricing and rebalance rollout state?

The answer to the first was clear: the live iOS client no longer used that route. The answer to the second was muddier: wiki language implied higher potion prices were already the baseline, while the visible code fallback still reflected the seeded catalog unless `GameConfig` overrides were present.

- **Files audited in this block:** 6
- **Primary file types:** iOS service/endpoint files, backend legacy route, product docs, wiki system/decision pages
- **Status:** dead iOS legacy shop code removed, backend legacy potion route documented as compatibility-only, and wiki pricing policy now distinguishes current fallback baseline from intended rebalance rollout
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[economy]], [[rebalance-w3d3]], [[block-026-backend-shop-consumable-pricing-parity]]

## Summary

- `ShopService.buyPotion(...)` and `APIEndpoints.shopBuyPotion` existed in the iOS client but had no live callers.
- The backend `buy-potion` route still exists, so the safest move was not to delete the server surface but to remove the dead client path and document the route as legacy compatibility.
- `wiki/systems/economy.md` presented potion prices as if the +25% rebalance were already the code baseline.
- `wiki/decisions/rebalance-w3d3.md` stated the consumable price increase as a flat “after” value without clarifying that repo-visible fallback code still uses seeded prices unless `GameConfig` overrides are present.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P2 | Dead iOS `buyPotion` client path remained in `ShopService` and `APIEndpoints`. | Extra unused surface makes future audits harder and creates the false impression that the app still depends on the legacy route. | Removed the unused iOS endpoint constant and service method. |
| P2 | Shop feature docs listed `/api/shop/buy-potion` like a normal current purchase route. | Readers could treat the legacy route as canonical instead of compatibility-only. | Updated the shop overview doc to mark `buy-consumable` as canonical and `buy-potion` as legacy compatibility. |
| P1 | Wiki economy/rebalance pages implied higher potion prices were already the guaranteed code baseline. | Architecture and QA decisions could be made off a false assumption about the actual fallback source of truth. | Updated wiki economy + rebalance pages to distinguish current seeded fallback pricing from intended `GameConfig`-driven rollout policy. |

## Cross-File Safe Fixes Applied

- Removed dead iOS legacy shop references from:
  - `Hexbound/Hexbound/Network/APIEndpoints.swift`
  - `Hexbound/Hexbound/Services/ShopService.swift`
- Updated `docs/features/shop/SHOP_OVERVIEW.md` to describe:
  - `/api/shop/buy-consumable` as the canonical direct-sale consumable route
  - `/api/shop/buy-potion` as legacy compatibility for older stamina-potion clients
- Updated `wiki/systems/economy.md` so potion pricing is described as:
  - live-configurable via `GameConfig`
  - seeded-code fallback baseline `100/250/500` and `150/350/700`
  - with the W3.D3 +25% increase treated as rollout policy, not guaranteed baked-in fallback
- Updated `wiki/decisions/rebalance-w3d3.md` with an explicit implementation note explaining the same distinction.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `Hexbound/Hexbound/Network/APIEndpoints.swift` | iOS endpoint registry | Central string constants for backend routes used by the client. | Used by every iOS service. | Should expose only live client-consumed routes unless a legacy route is still intentionally needed. | Removed unused `shopBuyPotion` constant after confirming no callers remained. | Fixed |
| `Hexbound/Hexbound/Services/ShopService.swift` | iOS shop service | Loads shop catalog and performs purchase flows used by the shop UI. | Used by `ShopViewModel`. Depends on `APIClient`, `AppState`, backend contracts. | Client purchase flows should point at canonical backend routes, not dead compatibility paths. | Removed the unused `buyPotion` method; live consumable purchases already use `buyConsumable`. | Fixed |
| `backend/src/app/api/shop/buy-potion/route.ts` | Backend legacy stamina-potion route | Compatibility path for older stamina-potion purchase callers. | Not used by the current iOS client; still present on backend for compatibility. | Should remain aligned with canonical pricing while considered for future retirement. | Re-audited in light of dead client code; no server deletion yet because compatibility risk remains. | Needs review |
| `docs/features/shop/SHOP_OVERVIEW.md` | Product/shop feature doc | Human-readable overview of shop surfaces and responsibilities. | Used by humans, onboarding, and audit context. | Current docs should separate canonical runtime paths from compatibility leftovers. | Marked `buy-consumable` as canonical and `buy-potion` as legacy compatibility. | Fixed |
| `wiki/systems/economy.md` | Wiki source-of-truth system page | Summarizes currencies, sinks, monetization, and economy health. | Used as current architecture/source-of-truth summary. | Must distinguish visible code fallback from intended live-config policy to avoid source-of-truth drift. | Rewrote potion-pricing note so it no longer claims the +25% rebalance is automatically baked into fallback code. | Fixed |
| `wiki/decisions/rebalance-w3d3.md` | Wiki decision page | Captures the W3.D3 rebalance intent and rationale. | Used by economy and QA readers. | Decision pages should record rollout intent without overstating what is already guaranteed by current code. | Added implementation note clarifying that potion-price uplift is still a rollout requirement unless explicit `GameConfig` overrides exist. | Fixed |

## Duplicate / Split Logic Found

- The route surface itself still has legacy/canonical split: `buy-consumable` is the live direct-sale flow, while `buy-potion` remains only for compatibility. That split is now explicit instead of accidental.
- Pricing policy had been split between intent docs (“+25%”) and visible fallback code (seed-aligned baseline). This block makes the distinction explicit in wiki.

## Files Without Clear Current Role

- None, but `backend/src/app/api/shop/buy-potion/route.ts` is now clearly a compatibility-only route rather than a primary product surface.

## Candidates For Refactor

- `backend/src/app/api/shop/buy-potion/route.ts` is a real deprecation candidate once backend compatibility requirements are known. It duplicates the purchase transaction shape even though pricing is now shared.

## Documentation Missing Or Stale

- Non-wiki product docs still do not point at a concrete `GameConfig` rollout artifact for potion price overrides. The wiki now records the ambiguity; broader docs can catch up later.

## Requires Separate Decision

- Decide whether `/api/shop/buy-potion` should remain indefinitely as a compatibility route or be formally deprecated and removed after a client-version cutoff.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- `git diff --check` passes after the iOS cleanup and doc/wiki updates.
