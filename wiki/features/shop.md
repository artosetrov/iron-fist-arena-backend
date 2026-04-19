# Feature: Shop

> Single-file map of every file that touches Shop — item buying, currency purchase (IAP), contraband, offers.

## One-liner

Player-facing store: buy consumables and gear with gold, buy currency with real money via StoreKit, browse time-limited contraband and offer bundles.

## Status

- **Phase:** In production
- **Last major change:** 2026-04-13 — Stash/shop schema fixes; flat response shape rule
- **Owner / last hands:** Artem

## Entry points

- **iOS screen:** `Hexbound/Hexbound/Views/Shop/ShopDetailView.swift`
- **Navigation route:** `AppRouter` → tap Merchant building on `HubView`
- **Player action:** Tap Merchant → browse tabs → buy / purchase currency

## Backend

### Routes (all under `/api/shop/`)

- `POST /buy`              — `backend/src/app/api/shop/buy/route.ts` — buy an item
- `POST /buy-consumable`   — `backend/src/app/api/shop/buy-consumable/route.ts`
- `POST /buy-gems`         — `backend/src/app/api/shop/buy-gems/route.ts` — StoreKit verification + gem grant
- `POST /buy-gold`         — `backend/src/app/api/shop/buy-gold/route.ts` — gems → gold exchange
- `POST /buy-potion`       — `backend/src/app/api/shop/buy-potion/route.ts`
- `GET  /contraband`       — `backend/src/app/api/shop/contraband/route.ts` — time-limited items
- `GET  /items`            — `backend/src/app/api/shop/items/route.ts` — regular shop inventory
- `GET  /offers`           — `backend/src/app/api/shop/offers/route.ts` — offer bundles
- `POST /repair`           — `backend/src/app/api/shop/repair/route.ts` — repair durability
- `POST /upgrade`          — `backend/src/app/api/shop/upgrade/route.ts` — gear upgrade

### Business logic

- `backend/src/lib/iap/` — StoreKit receipt verification (also used by premium-pass)
- `backend/src/lib/game/balance.ts` — shop pricing constants
- `backend/src/lib/game/items.ts` / `items catalog` — item definitions

### Prisma models touched

- `IapTransaction` (line 1001) — StoreKit receipt records
- `ShopOffer` (line 1455) — bundle definitions
- `ShopOfferPurchase` (line 1502) — per-player bundle purchase history
- `Character` — gold, gems balances
- `Item` — inventory grants
- `Inventory` — per-character item rows

## iOS

### Views

- `Hexbound/Hexbound/Views/Shop/ShopDetailView.swift` — main shop screen
- `Hexbound/Hexbound/Views/Shop/CurrencyPurchaseView.swift` — gems/gold purchase
- `Hexbound/Hexbound/Views/Shop/PremiumPurchaseView.swift` — premium currency/bundles
- `Hexbound/Hexbound/Views/Shop/ContrabandWidget.swift` — limited-time rotation
- `Hexbound/Hexbound/Views/Shop/MerchantStripView.swift` — merchant NPC strip
- `Hexbound/Hexbound/Views/Shop/MerchantTipProvider.swift` — merchant NPC hint lines
- `Hexbound/Hexbound/Views/Shop/ShopOfferBannerView.swift` — promoted offer banner

### ViewModels

- `Hexbound/Hexbound/Views/Shop/ShopViewModel.swift`

### Services

- `Hexbound/Hexbound/Services/ShopService.swift` — API wrapper; consumes flat `{ gold, gems, ... }` response (see gotchas)
- `Hexbound/Hexbound/Services/StoreKitService.swift` — Apple StoreKit integration
- `Hexbound/Hexbound/Services/InventoryService.swift` — receives granted items after buy

### Cache

- `GameDataCache.shopItems` — shop inventory
- `GameDataCache.shopOffers` — offer bundles

## Admin

- `admin/src/app/(dashboard)/iap-products/page.tsx` — read-only IAP Products catalog page for live SKU/state review
- `admin/src/app/(dashboard)/iap-products/iap-products-client.tsx` — filterable catalog table for enabled/disabled SKUs
- `admin/src/app/api/admin/iap-products/route.ts` — admin proxy route used by the page
- `backend/src/app/api/admin/iap-products/route.ts` — backend source for the admin catalog view
- `admin/src/app/` — broader shop tuning: item prices, offer schedules, contraband rotation, IAP reconciliation

## Docs

- `docs/02_product_and_features/ECONOMY.md` — currencies and sinks
- `docs/06_game_systems/ECONOMY_RULES.md`
- `docs/06_game_systems/BALANCE_CONSTANTS.md` — pricing constants

## Notable gotchas

- **Flat response shape.** Shop endpoints MUST return flat `{ gold, gems, ... }` — NOT nested `{ character: { gold, gems } }`. `ShopService.updateCharacter` assumes flat. See memory `feedback_flat_response_shape.md`.
- **Optimistic UI.** Buy mutations update UI instantly, rollback on failure. Memory `feedback_optimistic_ui_everywhere.md`.
- **IAP receipt verification.** Backend must validate Apple receipt via shared `lib/iap`. Never trust client-reported gem amounts.
- **IAP Products admin surface is read-only.** The page reflects `IAP_PRODUCTS` from `backend/src/lib/game/balance.ts`; changing SKU enablement/pricing still requires editing balance config/code and deploying.
- **Premium Pass Phase 2** (2026-04-14) shares the IAP verify infrastructure — don't break one without checking the other. Memory `project_premium_pass_phase2.md`.

## Tests / fixtures

- `backend/src/__tests__/` — shop/IAP tests
- Seed: admin shop catalog seeder

## Related features

- [[gold-mine]] — gold source that funds shop buys
- [[pvp-combat]] — consumes shop potions/consumables
