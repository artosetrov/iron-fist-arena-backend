---
title: Audit Block 216 — Admin Monetization Wording Vs Live IAP Products Surface
category: audit
tags: [audit, docs, admin, iap, monetization]
sources:
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/app/(dashboard)/iap-products/page.tsx
  - admin/src/app/(dashboard)/iap-products/iap-products-client.tsx
  - backend/src/app/api/admin/iap-products/route.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 216 — Admin Monetization Wording Vs Live IAP Products Surface

## Scope

- `docs/01_source_of_truth/PROJECT_OVERVIEW.md`
- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/app/(dashboard)/iap-products/page.tsx`
- `admin/src/app/(dashboard)/iap-products/iap-products-client.tsx`
- `backend/src/app/api/admin/iap-products/route.ts`

## Why this block

After `block-214` and `block-215`, one small wording drift was still hanging around:

- `PROJECT_OVERVIEW.md` still sounded like admins could actively manage IAP products from the monetization surface
- role wording in `ADMIN_CAPABILITIES.md` still compressed everything into a vague “IAP review” phrase

But the live repo is narrower and more specific:

- there is a dedicated `IAP Products` page
- it is read-only
- changing SKU enablement/pricing still goes through code/config + deploy

## Fix applied

### `docs/01_source_of_truth/PROJECT_OVERVIEW.md`

- changed `Gem pricing tiers (manage IAP products)` to:
  - `Gem pricing tiers (review live IAP catalog; edits remain code/config-driven)`

### `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

- refined role wording so it now names:
  - IAP transaction review
  - IAP Products catalog review
- removed the last implication that there is a broader live SKU-management surface in the dashboard

## Result

Admin monetization docs now match the live repo more closely:

- there is a real `IAP Products` admin page
- it is part of the review surface
- it is not a live SKU editor

## Verification

- compared the wording against the live `IAP Products` page/client and backend route
- `git diff --check`

This closes the last small wording gap in the admin monetization corridor after the orphan review-route cleanup.
