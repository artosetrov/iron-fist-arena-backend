---
title: Audit Block 214 — Delete Orphan Admin Review Routes
category: audit
tags: [audit, backend, admin, docs, cleanup]
sources:
  - backend/src/app/api/admin/economy/route.ts
  - backend/src/app/api/admin/iap/route.ts
  - backend/src/app/api/admin/stats/route.ts
  - backend/src/app/api/admin/iap-products/route.ts
  - admin/src/app/(dashboard)/economy/page.tsx
  - admin/src/app/(dashboard)/iap-products/page.tsx
  - admin/src/app/api/admin/iap-products/route.ts
  - docs/03_backend_and_api/API_REFERENCE.md
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - wiki/_generated/api-routes.json
updated: 2026-04-19
status: Fixed
---

# Audit Block 214 — Delete Orphan Admin Review Routes

## Scope

- `backend/src/app/api/admin/economy/route.ts`
- `backend/src/app/api/admin/iap/route.ts`
- `backend/src/app/api/admin/stats/route.ts`
- `backend/src/app/api/admin/iap-products/route.ts`
- `admin/src/app/(dashboard)/economy/page.tsx`
- `admin/src/app/(dashboard)/iap-products/page.tsx`
- `admin/src/app/api/admin/iap-products/route.ts`
- `docs/03_backend_and_api/API_REFERENCE.md`
- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `wiki/_generated/api-routes.json`

## Why this block

The recent analytics/admin doc cleanup exposed one more truth gap:

- `stats`, `economy`, and `iap` still existed as backend admin review routes
- but the live admin review surface no longer consumed them
- the dashboard already used admin-owned server actions and direct read-side queries instead

At the same time, `iap-products` turned out to be different:

- it is still a live admin page
- it still proxies a dedicated backend admin route

So this was not a blanket “delete all admin review routes” pass. It was a narrower cleanup:

- delete the three orphan review routes
- keep the one still-consumed catalog route

## Fix applied

### Deleted orphan backend routes

- deleted `backend/src/app/api/admin/economy/route.ts`
- deleted `backend/src/app/api/admin/iap/route.ts`
- deleted `backend/src/app/api/admin/stats/route.ts`

### Retained live catalog route

- kept `backend/src/app/api/admin/iap-products/route.ts`
- kept `admin/src/app/api/admin/iap-products/route.ts`
- kept `admin/src/app/(dashboard)/iap-products/page.tsx`

### Docs and generated route map sync

#### `docs/03_backend_and_api/API_REFERENCE.md`

- removed the stale backend rows for:
  - `/admin/economy`
  - `/admin/stats`
  - `/admin/iap`
- added the retained live catalog row for:
  - `/admin/iap-products`
- rewrote the admin analytics note so it no longer implies those orphan backend review routes still exist

#### `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

- changed the current repo note so analytics review is described as:
  - dashboard/economy surfaces
  - admin-owned server-action/read-side flow
  - dedicated `IAP Products` catalog page via `/api/admin/iap-products`

#### `wiki/_generated/api-routes.json`

- removed deleted backend review routes from the generated route map
- kept the live `iap-products` backend route visible there

## Result

The admin review corridor is cleaner and more honest now:

- dead backend review routes are gone
- docs no longer point at endpoints that the live admin UI does not use
- `iap-products` remains as the intentional narrow backend admin catalog surface

## Verification

- repo-wide `rg` confirmed no live code consumers for `/api/admin/stats`, `/api/admin/economy`, or `/api/admin/iap`
- compared the live admin review flow in `admin/src/app/(dashboard)/economy/page.tsx`
- confirmed `iap-products` still has a real page + proxy route + backend route chain
- `git diff --check`

This closes the orphan admin review route tail without breaking the still-live IAP Products catalog page.
