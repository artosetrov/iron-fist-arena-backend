---
title: Audit Block 177 — Stale Audit Tail Item Balance Cross-Process Sync
category: audit
tags: [audit, backend, admin, item-balance, truth-sync]
sources:
  - wiki/audit/block-047-backend-dungeon-item-balance-live-config-hardening.md
  - wiki/audit/block-048-admin-item-balance-backend-proxy-alignment.md
  - admin/src/app/api/admin/item-balance/profiles/route.ts
  - admin/src/lib/backend-api.ts
  - backend/src/app/api/admin/item-balance/profiles/route.ts
updated: 2026-04-17
---

# Audit Block 177 — Stale Audit Tail Item Balance Cross-Process Sync

## Why this block exists

`block-047` correctly flagged one remaining risk at the time:

- the separate admin app could still write item-balance profiles through its own process
- backend profile-cache invalidation was only guaranteed inside the backend process
- cross-process freshness therefore depended on TTL rather than immediate canonical invalidation

That warning stopped being accurate after the later admin proxy cutover in [[block-048-admin-item-balance-backend-proxy-alignment]].

## What changed

- re-checked the current admin profile write path
- confirmed `admin/src/app/api/admin/item-balance/profiles/route.ts` now proxies to the backend canonical route
- confirmed `backend/src/app/api/admin/item-balance/profiles/route.ts` still invalidates the touched profile cache immediately after upsert
- updated the stale `Needs review` note in `block-047` to reflect that the cross-process write concern was already resolved by the proxy migration

## Result

The old open risk in `block-047` is no longer real:

- the admin app no longer performs an independent direct write for item-balance profile edits
- profile mutation ownership now lives with the backend route that also owns cache invalidation
- the remaining TTL is now just a fallback freshness boundary, not the primary synchronization mechanism
