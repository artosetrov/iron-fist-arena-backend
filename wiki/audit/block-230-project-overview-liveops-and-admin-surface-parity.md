---
title: Audit Block 230 — Project Overview Liveops And Admin Surface Parity
category: audit
tags: [audit, docs, source-of-truth, admin, liveops]
sources:
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - wiki/features/daily-login.md
  - wiki/features/shop.md
  - wiki/features/auth.md
  - admin/src/lib/feature-flags.ts
  - admin/src/actions/feature-flags.ts
  - admin/src/app/(dashboard)/flags/flags-client.tsx
  - admin/src/actions/push.ts
  - admin/src/lib/push-campaigns.ts
  - admin/src/app/(dashboard)/push/push-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 230 — Project Overview Liveops And Admin Surface Parity

## Scope

- `docs/01_source_of_truth/PROJECT_OVERVIEW.md`
- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `wiki/features/daily-login.md`
- `wiki/features/shop.md`
- `wiki/features/auth.md`
- `admin/src/lib/feature-flags.ts`
- `admin/src/actions/feature-flags.ts`
- `admin/src/app/(dashboard)/flags/flags-client.tsx`
- `admin/src/actions/push.ts`
- `admin/src/lib/push-campaigns.ts`
- `admin/src/app/(dashboard)/push/push-client.tsx`

## Why this block

Once the admin capability map became much more accurate, `PROJECT_OVERVIEW.md` still had an older, broader picture of the same surfaces:

- daily login still read like a `30`-day cycle even though the live client/runtime now center on the `7`-day cycle
- feature flags still sounded like a full A/B experimentation platform
- push wording still implied delivered-state analytics rather than the current sent/failed plus token-count surface
- IAP wording still blurred receipt validation with auth
- the admin summary still described broader character-management, audit, simulation, and scheduling tooling than the current dashboard actually ships

## Fix applied

### Core systems / liveops

- changed daily login from `30-day cycle` to the live `7-day cycle with streak tracking`
- narrowed mail attachments wording to the current admin-composed attachment surface
- rewrote feature flags as gradual rollout / targeted override tooling instead of a full A/B testing platform
- rewrote push wording to the current sent/failed + token-count review model
- rewrote IAP wording around backend receipt verification instead of “Supabase Auth receipt validation”

### Admin panel summary

- rewrote the dashboard section around the real KPI + alert + review surfaces
- narrowed character-management wording to the real player list + detail actions
- removed stale `CSV`, prestige-reset, respec-reset, early-unlock, and broad bulk-grant claims
- separated battle-pass reward authoring from season management
- narrowed push, feature flags, live config, admin logs, and balance simulation sections to the actual live surfaces
- removed the implied standalone searchable audit dashboard

### Architecture section

- narrowed the live-config decision to “large share of balance/config values” instead of every live value
- rewrote feature flags as gradual rollouts / targeted overrides instead of A/B testing
- narrowed async-processing wording so push/mail no longer read like a universal queue platform
- updated RBAC wording to the real fixed-role + per-route/per-action guard model

## Result

`PROJECT_OVERVIEW.md` now matches the cleaned admin/liveops truth much better instead of preserving an older “full liveops suite” picture after the repo had already converged on narrower real surfaces.

## Verification

- compared the overview against the cleaned admin capability doc and feature maps for daily login, shop, and auth
- compared feature-flag and push wording against the current admin flag/push codepaths
- `git diff --check`

This closes the next source-of-truth drift block adjacent to the admin capability cleanup.
