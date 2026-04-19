---
title: Audit Block 215 — Shop Feature Map IAP Products Admin Surface Parity
category: audit
tags: [audit, wiki, shop, admin, iap]
sources:
  - wiki/features/shop.md
  - admin/src/app/(dashboard)/iap-products/page.tsx
  - admin/src/app/(dashboard)/iap-products/iap-products-client.tsx
  - admin/src/app/api/admin/iap-products/route.ts
  - backend/src/app/api/admin/iap-products/route.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 215 — Shop Feature Map IAP Products Admin Surface Parity

## Scope

- `wiki/features/shop.md`
- `admin/src/app/(dashboard)/iap-products/page.tsx`
- `admin/src/app/(dashboard)/iap-products/iap-products-client.tsx`
- `admin/src/app/api/admin/iap-products/route.ts`
- `backend/src/app/api/admin/iap-products/route.ts`

## Why this block

After `block-214`, the `IAP Products` page became the only retained backend-backed admin surface in this shop/IAP corridor.

But the feature map was still lagging:

- `wiki/features/shop.md` only mentioned a generic `admin/src/app/` tuning surface
- it did not name the dedicated `IAP Products` page
- it did not describe the admin proxy/backend route chain that now matters more after the orphan review routes were deleted

## Fix applied

### `wiki/features/shop.md`

- added the dedicated admin page:
  - `admin/src/app/(dashboard)/iap-products/page.tsx`
- added the client table:
  - `admin/src/app/(dashboard)/iap-products/iap-products-client.tsx`
- added the admin proxy route:
  - `admin/src/app/api/admin/iap-products/route.ts`
- added the backend source route:
  - `backend/src/app/api/admin/iap-products/route.ts`
- documented that this surface is read-only and reflects `IAP_PRODUCTS` from `backend/src/lib/game/balance.ts`

## Result

The shop feature map now matches the current repo:

- the dedicated `IAP Products` admin page is visible as a first-class shop/admin surface
- the proxy/backend chain is documented
- the page is described honestly as read-only catalog verification, not live price/flag editing

## Verification

- compared `wiki/features/shop.md` against the live admin page, client, proxy route, and backend route
- `git diff --check`

This closes the “live but undocumented” gap left after the old admin review routes were removed.
