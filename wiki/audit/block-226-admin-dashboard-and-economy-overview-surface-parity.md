---
title: Audit Block 226 — Admin Dashboard And Economy Overview Surface Parity
category: audit
tags: [audit, docs, admin, dashboard, economy]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/app/(dashboard)/dashboard-client.tsx
  - admin/src/actions/dashboard.ts
  - admin/src/app/(dashboard)/economy/economy-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 226 — Admin Dashboard And Economy Overview Surface Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/app/(dashboard)/dashboard-client.tsx`
- `admin/src/actions/dashboard.ts`
- `admin/src/app/(dashboard)/economy/economy-client.tsx`

## Why this block

The next overview cluster in `ADMIN_CAPABILITIES.md` was still speaking in older dashboard language:

- Dashboard still implied an “active PvP matches” KPI, inline leaderboard, and broader alert set than the live page exposes
- Economy Overview still described 30-day circulation charts, faucet/sink time series, and automatic exploit alerts that the current economy page does not ship

## Fix applied

### Dashboard (Home)

- rewrote the KPI list to the live values:
  - active today
  - new users
  - total users
  - PvP today
  - gold circulation
  - gems circulation
- rewrote alerts to the actual generated alert families:
  - class win-rate imbalance
  - DAU drop
  - PvP volume drop
- rewrote the page structure around the real sections:
  - KPI grid
  - alerts list
  - economy charts
  - PvP & balance charts
  - player charts
  - system health
  - quick links
- removed the implication of inline leaderboard and real-time ops-console behavior

### Economy Overview

- rewrote the section around the actual `/economy` review dashboard:
  - summary cards
  - wealth distribution + gini
  - economy by class
  - gold by level
  - top holders
  - IAP review
  - offer sales review
- removed the implication of 30-day circulation charts, faucet/sink time series, and automated exploit alerts from this page

### Economy Review Surface

- clarified that this is the dedicated `/economy` dashboard
- kept the narrower “review dashboard, not full analytics suite” framing consistent with the live page

## Result

The top-level dashboard/economy section in `ADMIN_CAPABILITIES.md` now describes the real admin overview surfaces much more closely instead of promising a broader liveops analytics console than the repo currently ships.

## Verification

- compared the docs against the live dashboard client, dashboard data action, and economy client
- `git diff --check`

This closes the next stale overview block inside `ADMIN_CAPABILITIES.md`.
