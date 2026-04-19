---
title: Audit Block 220 — Admin Balance And Offers Surface Parity
category: audit
tags: [audit, docs, admin, balance, loot, offers]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/app/(dashboard)/loot/loot-client.tsx
  - admin/src/app/(dashboard)/offers/offers-client.tsx
  - admin/src/app/(dashboard)/balance/balance-client.tsx
  - admin/src/app/(dashboard)/config/config-client.tsx
  - admin/src/app/(dashboard)/item-balance/page.tsx
  - admin/src/app/(dashboard)/item-balance/dashboard-client.tsx
  - admin/src/app/(dashboard)/item-balance/simulation/simulation-client.tsx
  - admin/src/app/(dashboard)/item-balance/config/config-editor-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 220 — Admin Balance And Offers Surface Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/app/(dashboard)/loot/loot-client.tsx`
- `admin/src/app/(dashboard)/offers/offers-client.tsx`
- `admin/src/app/(dashboard)/balance/balance-client.tsx`
- `admin/src/app/(dashboard)/config/config-client.tsx`
- `admin/src/app/(dashboard)/item-balance/page.tsx`
- `admin/src/app/(dashboard)/item-balance/dashboard-client.tsx`
- `admin/src/app/(dashboard)/item-balance/simulation/simulation-client.tsx`
- `admin/src/app/(dashboard)/item-balance/config/config-editor-client.tsx`

## Why this block

The next stale docs cluster in `ADMIN_CAPABILITIES.md` was the admin balance/monetization toolbox:

- Loot Tables still sounded like a full item-pool editor with scheduled changes
- Shop Offers still implied A/B pricing and a richer sale-state machine than the UI actually has
- Upgrade & Repair sounded like a dedicated forecasting tool instead of live config knobs
- Configuration Manager still promised impact calculators and scheduled apply
- Item Balance Simulator still implied named experiment profiles and deeper meta-analysis flows that are not present in the current dashboard

## Fix applied

### `Loot Tables`

- rewrote the section to the actual live screen:
  - drop chances by source
  - rarity distribution weights
  - validation that rarity sums to 100
  - immediate save
  - seeding defaults
- removed the implication that the screen edits specific item pools, gold/gem payouts, or future schedules

### `Shop Offers`

- rewrote create/manage fields to the live offer form:
  - key/title/description
  - offer type
  - bundle contents
  - price/currency/discount
  - max purchases
  - level window
  - sort order
  - image key
  - tags
  - active toggle
  - start/end dates
- removed the implication of A/B pricing experiments
- narrowed metrics wording to aggregate purchases/revenue totals

### `Upgrade & Repair Controls`

- replaced the fantasy dedicated pricing simulator with the real live controls:
  - repair config on the main Balance page
  - `upgrade_chances` on the main Balance page
  - upgrade economy controls in the item-balance config editor
- documented that rollback lives through snapshots, not a local per-page undo/forecast system

### `Configuration Manager`

- rewrote UI actions to the real live model:
  - edit
  - save per-key / per-section
  - seed defaults
  - rollback through snapshots
- removed automatic scheduling / built-in impact-calculator claims

### `Item Balance Simulator`

- rewrote the section around the live suite:
  - overview dashboard
  - config editor
  - profiles editor
  - validation
  - combat sim
  - class matchups
  - item impact
- removed the implication of named experiment profiles, meta-usage analytics, or A/B comparisons between saved simulation profiles

## Result

The admin balance/monetization docs now match the actual dashboard much more closely:

- current admin = concrete config + validation + simulation tooling
- not a broader scheduling/forecasting/experimentation suite than the repo really ships

## Verification

- compared the docs against the live loot/offers/balance/config/item-balance screens and supporting code
- `git diff --check`

This closes the next large overstatement cluster inside `ADMIN_CAPABILITIES.md`.
