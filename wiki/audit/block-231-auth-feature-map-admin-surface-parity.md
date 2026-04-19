---
title: Audit Block 231 — Auth Feature Map Admin Surface Parity
category: audit
tags: [audit, wiki, auth, admin, feature-map]
sources:
  - wiki/features/auth.md
  - admin/src/app/login/page.tsx
  - admin/src/app/(dashboard)/players/page.tsx
  - admin/src/app/(dashboard)/players/[id]/page.tsx
  - admin/src/app/(dashboard)/settings/page.tsx
  - admin/src/app/api/settings/role/route.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 231 — Auth Feature Map Admin Surface Parity

## Scope

- `wiki/features/auth.md`
- `admin/src/app/login/page.tsx`
- `admin/src/app/(dashboard)/players/page.tsx`
- `admin/src/app/(dashboard)/players/[id]/page.tsx`
- `admin/src/app/(dashboard)/settings/page.tsx`
- `admin/src/app/api/settings/role/route.ts`

## Why this block

The auth feature map still pointed to a non-existent legacy admin surface:

- `admin/src/app/(dashboard)/users/` no longer exists in the live repo
- that stale path made the auth feature page sound like there was a dedicated account-unlocking/manual-email-verify dashboard route, which is not the current admin shape

## Fix applied

- replaced the dead `users/` path with the real auth-adjacent admin surfaces:
  - admin login page
  - players list/detail pages used for live player/account review
  - admin-only settings page
  - role-mutation route

## Result

The auth feature map now points at live admin surfaces instead of a deleted `users/` route tree.

## Verification

- verified the listed admin paths exist in the current repo
- `git diff --check`

This closes the next stale admin-path tail in the auth feature map.
