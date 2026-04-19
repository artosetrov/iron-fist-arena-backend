---
title: Audit Block 217 — Admin Economy Review Vs Fantasy Analytics Dashboard
category: audit
tags: [audit, docs, admin, economy, analytics]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
  - admin/src/app/(dashboard)/economy/page.tsx
  - admin/src/app/(dashboard)/economy/economy-client.tsx
  - admin/src/actions/economy.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 217 — Admin Economy Review Vs Fantasy Analytics Dashboard

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `docs/01_source_of_truth/PROJECT_OVERVIEW.md`
- `admin/src/app/(dashboard)/economy/page.tsx`
- `admin/src/app/(dashboard)/economy/economy-client.tsx`
- `admin/src/actions/economy.ts`

## Why this block

One more monetization/docs drift was still hanging around after the recent analytics cleanup:

- `ADMIN_CAPABILITIES.md` still described a broad analytics dashboard with retention, churn, session metrics, LTV, combat-balance analytics, and export tooling
- but the live repo surface is much narrower and more concrete:
  - economy summary cards
  - wealth distribution / gini
  - economy by class
  - gold by level
  - top holders
  - IAP-by-product review
  - recent transactions
  - offer purchase analytics

At the same time, `PROJECT_OVERVIEW.md` still implied a dedicated live `Daily Gem Card config` surface, while the current repo only exposes that product through the read-only `IAP Products` catalog view.

## Fix applied

### `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

- replaced the fantasy “Analytics Dashboard” section with the current live economy review surface
- documented the actual views exposed by the admin app:
  - circulation summary
  - wealth distribution / gini
  - economy by class
  - gold by level
  - top holders
  - IAP by product
  - recent transactions
  - offer purchase analytics
- explicitly noted that retention, churn, sessions, LTV/cohort analytics, combat telemetry, and export tooling are not separate live dashboard views today

### `docs/01_source_of_truth/PROJECT_OVERVIEW.md`

- changed `Daily Gem Card config` to:
  - `Daily Gem Card visibility via the live IAP catalog (product config remains code/config-driven)`

## Result

The monetization/admin docs now match the live repo much more closely:

- current admin = economy review dashboard
- not a full product analytics suite
- daily gem card remains visible through IAP catalog review, not a dedicated live config screen

## Verification

- compared `ADMIN_CAPABILITIES.md` against `economy/page.tsx`, `economy-client.tsx`, and `actions/economy.ts`
- `git diff --check`

This closes the remaining fantasy-analytics wording in the admin monetization corridor.
