---
title: Audit Block 219 — Admin Feature Flags Targeting Surface Parity
category: audit
tags: [audit, docs, admin, feature-flags]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/lib/feature-flags.ts
  - admin/src/actions/feature-flags.ts
  - admin/src/app/(dashboard)/flags/flags-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 219 — Admin Feature Flags Targeting Surface Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/lib/feature-flags.ts`
- `admin/src/actions/feature-flags.ts`
- `admin/src/app/(dashboard)/flags/flags-client.tsx`

## Why this block

After the push-surface cleanup, the next neighboring drift was feature flags:

- docs still described “segment” targeting in broad cohort language like beta testers / platform / region
- but the live repo supports a narrower and more concrete targeting model:
  - environment
  - min level
  - max level
  - class
  - explicit user IDs

The docs were also underselling some live controls:

- tags
- environment
- default-flag seeding

## Fix applied

### `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

- rewrote segment targeting to match the actual feature-flag model
- added live environment support:
  - all
  - production
  - staging
  - development
- documented optional targeting fields:
  - min level
  - max level
  - class
  - explicit user IDs
- documented tags and default-flag seeding
- removed the implication that the current dashboard ships a richer cohort builder for beta testers / platform / region
- added an explicit note that automated impact monitoring and crash-log-linked rollout analytics are not live dashboard features today

## Result

The feature-flags section now matches the actual admin tooling:

- current dashboard = practical rollout control with environment + simple targeting
- not a full experimentation/observability platform

## Verification

- compared the docs against `flags-client.tsx`, `actions/feature-flags.ts`, and `lib/feature-flags.ts`
- `git diff --check`

This closes the feature-flags targeting drift in the admin docs corridor.
