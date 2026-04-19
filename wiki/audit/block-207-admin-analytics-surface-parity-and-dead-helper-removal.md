---
title: Audit Block 207 — Admin Analytics Surface Parity And Dead Helper Removal
category: audit
tags: [audit, admin, analytics, docs, cleanup]
sources:
  - admin/src/actions/analytics.ts
  - backend/src/app/api/admin/stats/route.ts
  - backend/src/app/api/admin/economy/route.ts
  - backend/src/app/api/admin/iap/route.ts
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - docs/03_backend_and_api/API_REFERENCE.md
updated: 2026-04-19
status: Fixed
---

# Audit Block 207 — Admin Analytics Surface Parity And Dead Helper Removal

## Scope

- `admin/src/actions/analytics.ts`
- `backend/src/app/api/admin/stats/route.ts`
- `backend/src/app/api/admin/economy/route.ts`
- `backend/src/app/api/admin/iap/route.ts`
- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `docs/03_backend_and_api/API_REFERENCE.md`

## Why this block

The admin analytics story had split into two conflicting realities:

- docs still talked like the project had a broad dedicated analytics dashboard
- but the live repo surface was narrower:
  - aggregate stats
  - economy review
  - IAP transaction review

On top of that, `admin/src/actions/analytics.ts` was dead code:

- no imports
- no route consumers
- no live dashboard page using it

## Fix applied

### Dead helper removal

- deleted `admin/src/actions/analytics.ts`
- confirmed it had no live imports in `admin/src`

### Docs parity

#### `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

- changed role wording from broad “analytics” access to the narrower live surface:
  - stats
  - economy review
  - IAP review
- clarified that there is no standalone analytics dashboard route in the current repo
- reframed the page-surface inventory so it no longer promises a separate telemetry platform or performance dashboard as if they already exist

#### `docs/03_backend_and_api/API_REFERENCE.md`

- changed:
  - `/admin/stats` → aggregate admin stats
  - `/admin/economy` → aggregate economy review
  - `/admin/iap` → IAP transaction review
- added a note that the current admin analytics surface is limited to those review endpoints, not a separate full analytics product

## Result

The admin analytics layer is now honest end to end:

- dead analytics helper code is gone
- docs describe the live review surfaces that actually exist
- `/admin/iap` is no longer mislabeled as generic analytics when it is really transaction review

## Later follow-up

This block was tightened further by `block-214-delete-orphan-admin-review-routes`:

- the standalone backend review routes for `stats`, `economy`, and `iap` were later deleted as orphan surfaces
- the retained live admin review path is now the dashboard's own server-action/read-side flow
- the dedicated backend admin route left in this corridor is `/api/admin/iap-products`

## Verification

- `rg` over `admin/src` confirmed `admin/src/actions/analytics.ts` had no imports
- inspected the live backend admin routes for `stats`, `economy`, and `iap`
- `git diff --check`

The cleanup removes dead code and tightens docs without changing live route behavior.
