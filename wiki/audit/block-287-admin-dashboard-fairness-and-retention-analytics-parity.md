---
title: Audit Block 287 — Admin Dashboard Fairness and Retention Analytics Parity
category: audit
tags: [audit, admin, analytics, dashboard, pvp]
sources:
  - admin/src/actions/dashboard.ts
  - admin/src/components/dashboard/pvp-charts.tsx
  - admin/src/components/dashboard/player-charts.tsx
  - admin/src/types/dashboard.ts
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
updated: 2026-04-30
status: Fixed
---

# Audit Block 287 — Admin Dashboard Fairness and Retention Analytics Parity

## Scope

This block closes the remaining placeholder analytics drift in the admin home dashboard.

## Why this block

The dashboard still mixed two different kinds of truth:

- `matchmakingFairness` was a hardcoded `0.75` with a TODO instead of a value derived from live PvP data.
- retention tiles rendered `0%`-style placeholders even though the current repo does not yet have dedicated return-event tracking to support real D1/D7/D30 reporting.

That was not catastrophic, but it made the dashboard look more authoritative than it really was.

## Changes shipped

- Replaced the hardcoded fairness placeholder with a live derived score based on recent `player*_rating_before` gaps from PvP matches.
- Made dashboard fairness nullable when recent PvP data is absent, so the UI can show `N/A` instead of implying fake precision.
- Made retention fields nullable in the typed dashboard contract.
- Changed the retention badges to show `Pending` instead of fake `0%` values.
- Updated the retention card copy to describe the current state as pending dedicated return-event tracking.
- Synced the admin/source-of-truth docs so they describe:
  - matchmaking fairness as a recent rating-gap-derived review signal
  - retention as a future instrumentation surface rather than a live dashboard metric

## Result

The admin dashboard now distinguishes between:

- metrics that are truly derived from live runtime data
- metrics that still need deeper instrumentation before they should be presented as real numbers

That makes the home dashboard more trustworthy for operators and keeps the analytics layer aligned with the current repo reality.
