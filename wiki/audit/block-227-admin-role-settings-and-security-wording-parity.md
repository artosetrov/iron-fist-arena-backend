---
title: Audit Block 227 — Admin Role Settings And Security Wording Parity
category: audit
tags: [audit, docs, admin, auth, roles, security]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/lib/auth.ts
  - admin/src/app/api/auth/login/route.ts
  - admin/src/app/(dashboard)/settings/page.tsx
  - admin/src/app/api/settings/role/route.ts
  - admin/src/actions/item-balance.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 227 — Admin Role Settings And Security Wording Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/lib/auth.ts`
- `admin/src/app/api/auth/login/route.ts`
- `admin/src/app/(dashboard)/settings/page.tsx`
- `admin/src/app/api/settings/role/route.ts`
- `admin/src/actions/item-balance.ts`

## Why this block

The next stale cluster in `ADMIN_CAPABILITIES.md` was the bottom-of-doc access model:

- role descriptions sounded like a precise permission matrix, but the live repo mostly relies on a simpler split between authenticated admin-session access, `canModifyConfig`, and a small number of strict admin-only flows
- `Item Balance History` sounded like a full item change-log with rollback, while the live surface is simulation-run history
- authentication/security wording still implied optional 2FA, OAuth-style admin login, short inactivity timeout, IP tracking, and universal rollback/approval flows that are not expressed as current live admin behavior

## Fix applied

### Roles & Permissions

- rewrote `Admin`, `Moderator`, and `Developer` around the actual helper model:
  - allowed dashboard roles are `admin` / `moderator` / `developer`
  - many content/config mutations are guarded by `canModifyConfig`
  - Settings + role mutation are admin-only
  - several review/ops surfaces still allow any authenticated admin-session role unless a stricter guard is applied
- removed over-precise capability claims that were not reliable as a page-by-page matrix

### Settings & System

- rewrote `Item Balance History` as simulation-run history instead of item edit history with rollback
- clarified that the live Settings page is admin-only

### Access Control & Security

- rewrote authentication around the real admin login path:
  - Supabase-backed email/password sign-in
  - `admin-token` cookie
  - fixed allowed roles
- rewrote authorization wording to the actual fixed-role + per-route guard model
- narrowed audit/security wording so it no longer claims:
  - custom-role security model
  - optional 2FA as a current live admin feature
  - 30-minute inactivity timeout
  - universal IP tracking
  - universal approval workflow
  - rollback on most actions

## Result

The bottom-of-doc roles/settings/security section now matches the real admin auth/guard model much more closely instead of reading like a stricter enterprise permissions matrix than the repo currently ships.

## Verification

- compared the docs against the live auth helpers, admin login route, admin-only settings page, role mutation route, and item-balance history source
- `git diff --check`

This closes the next stale access-model block inside `ADMIN_CAPABILITIES.md`.
