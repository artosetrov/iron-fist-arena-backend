---
title: Block 041 — IAP compatibility aliases, restore surface, and iOS endpoint drift
category: audit
tags: [audit, backend, ios, iap, compatibility, docs]
sources:
  - backend/src/app/api/iap/restore-purchases/route.ts
  - backend/src/app/api/iap/restore/route.ts
  - backend/src/app/api/iap/verify/route.ts
  - backend/tests/api/iap-restore-purchases.test.ts
  - backend/tests/api/iap-verify-receipt.test.ts
  - Hexbound/Hexbound/Network/APIEndpoints.swift
  - Hexbound/Hexbound/Views/Shop/CurrencyPurchaseView.swift
  - Hexbound/Hexbound/Views/Shop/PremiumPurchaseView.swift
  - docs/03_backend_and_api/API_REFERENCE.md
updated: 2026-04-15
status: Fixed
---

# Block 041 — IAP compatibility aliases, restore surface, and iOS endpoint drift

## Scope

- `backend/src/app/api/iap/restore-purchases/route.ts`
- `backend/src/app/api/iap/restore/route.ts`
- `backend/src/app/api/iap/verify/route.ts`
- `backend/tests/api/iap-restore-purchases.test.ts`
- `backend/tests/api/iap-verify-receipt.test.ts`
- `Hexbound/Hexbound/Network/APIEndpoints.swift`
- `Hexbound/Hexbound/Views/Shop/CurrencyPurchaseView.swift`
- `Hexbound/Hexbound/Views/Shop/PremiumPurchaseView.swift`
- `docs/03_backend_and_api/API_REFERENCE.md`

## Why this block

After `Block 040`, the IAP runtime itself was safer, but the compatibility surface around it still had drift:

1. current iOS purchase flows were hitting the live compatibility route `/api/iap/verify` through raw strings instead of the shared endpoint catalog
2. `APIEndpoints.iapRestore` existed in the client but had no real callers
3. the restore/verify alias routes were not covered in tests or described clearly as canonical-vs-compatibility surfaces

## File notes

### `backend/src/app/api/iap/restore-purchases/route.ts`

- **Zone:** backend / IAP restore
- **Purpose:** returns verified purchase history for the authenticated user
- **What it does:** lists verified `iap_transactions` in reverse chronological order
- **Important note:** this is a history surface, not a full entitlement rebuild endpoint
- **What was fixed:** added focused API coverage so the route contract is now explicit
- **Status:** Fixed

### `backend/src/app/api/iap/restore/route.ts`

- **Zone:** backend / IAP compatibility
- **Purpose:** compatibility alias for `/api/iap/restore-purchases`
- **What it does:** re-exports the canonical restore handler
- **What was fixed:** added alias coverage through route tests and clarified its role in docs
- **Status:** Fixed

### `backend/src/app/api/iap/verify/route.ts`

- **Zone:** backend / IAP compatibility
- **Purpose:** compatibility alias for `/api/iap/verify-receipt`
- **What it does:** re-exports the canonical verify handler
- **Important note:** this alias is still live because the current iOS storefront calls it
- **What was fixed:** added an alias regression test in the IAP verify suite
- **Status:** Fixed

### `backend/tests/api/iap-restore-purchases.test.ts`

- **Zone:** backend tests / IAP restore
- **Purpose:** locks the restore history contract and alias wiring
- **What it covers now:**
  - unauthorized restore rejection
  - canonical restore history response
  - legacy `/api/iap/restore` alias wiring
- **Status:** Fixed

### `backend/tests/api/iap-verify-receipt.test.ts`

- **Zone:** backend tests / IAP verify
- **Purpose:** now also protects the live `/api/iap/verify` alias path used by iOS
- **Status:** Fixed

### `Hexbound/Hexbound/Network/APIEndpoints.swift`

- **Zone:** iOS / network contract catalog
- **Purpose:** central endpoint source of truth for the client
- **Problems found:**
  - `iapVerify` existed but live views still used raw strings
  - `iapRestore` was dead code with no active callers
- **What was fixed:** switched the live purchase flows to `APIEndpoints.iapVerify` and removed dead `iapRestore`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Shop/CurrencyPurchaseView.swift`

- **Zone:** iOS / shop
- **Purpose:** gem/gold/monthly card purchases
- **Problem found:** backend path string was duplicated inline
- **What was fixed:** now uses `APIEndpoints.iapVerify`
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Shop/PremiumPurchaseView.swift`

- **Zone:** iOS / premium shop
- **Purpose:** premium purchase flow
- **Problem found:** backend path string was duplicated inline
- **What was fixed:** now uses `APIEndpoints.iapVerify`
- **Status:** Fixed

### `docs/03_backend_and_api/API_REFERENCE.md`

- **Zone:** docs / backend API
- **Purpose:** public route index
- **Problem found:** IAP rows did not distinguish canonical routes from compatibility aliases
- **What was fixed:** the table now marks `verify-receipt` / `restore-purchases` as canonical and `verify` / `restore` as compatibility aliases
- **Status:** Fixed

## Problems found

1. **Live client used raw verify path strings**
   - Risk: the endpoint catalog can drift away from the real purchase flow without anyone noticing.
   - Fix: switched live purchase views to `APIEndpoints.iapVerify`.

2. **Dead restore endpoint constant in iOS**
   - Risk: dead network constants make it harder to tell which compatibility surfaces are truly still alive.
   - Fix: removed unused `APIEndpoints.iapRestore`.

3. **Alias policy was implicit**
   - Risk: a future cleanup could remove `/api/iap/verify` even though current iOS still depends on it.
   - Fix: documented canonical vs compatibility routes and added route-level alias tests.

## Verification

- targeted backend `vitest`:
  - `tests/api/iap-verify-receipt.test.ts`
  - `tests/api/iap-apple-notifications.test.ts`
  - `tests/api/iap-restore-purchases.test.ts`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

## Follow-up

- current iOS restore UX still uses StoreKit local restore directly and does not consume `/api/iap/restore-purchases`; that may be fine, but the product intent should be documented explicitly before anyone tries to delete or expand the backend restore surface.
