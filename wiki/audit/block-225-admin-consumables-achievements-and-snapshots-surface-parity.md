---
title: Audit Block 225 — Admin Consumables Achievements And Snapshots Surface Parity
category: audit
tags: [audit, docs, admin, consumables, achievements, snapshots]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/app/(dashboard)/consumables/consumables-client.tsx
  - admin/src/app/(dashboard)/achievements/achievements-client.tsx
  - admin/src/app/(dashboard)/snapshots/snapshots-client.tsx
  - admin/src/actions/snapshots.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 225 — Admin Consumables Achievements And Snapshots Surface Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/app/(dashboard)/consumables/consumables-client.tsx`
- `admin/src/app/(dashboard)/achievements/achievements-client.tsx`
- `admin/src/app/(dashboard)/snapshots/snapshots-client.tsx`
- `admin/src/actions/snapshots.ts`

## Why this block

The next capability cluster in `ADMIN_CAPABILITIES.md` was still broader than the live admin surfaces:

- Consumables still sounded like a standalone CRUD editor
- Achievements still sounded like a smaller definition schema with a richer template-builder story than the page actually provides
- Snapshots still implied diff tooling and general automatic snapshotting that the current page does not expose

## Fix applied

### Consumables

- rewrote the section around the live split surface:
  - catalog review for consumable items already present in the item catalog
  - live `GameConfig` editing for prices and restore values
- removed the implication that the page is a separate consumable CRUD system

### Achievements

- rewrote the section around the live achievement-definition form:
  - key / title / description / category / target
  - reward type / amount / optional reward id
  - icon / sort order / active toggle
- documented the real management actions:
  - create/edit/delete
  - activate/deactivate
  - seed defaults
  - stats tab
- removed the implication of a broader free-form batch-template builder

### Config Snapshots

- kept the real create/list/rollback flow
- added delete to the documented actions
- removed diff-view wording
- narrowed automation wording to what really exists:
  - manual snapshot creation
  - automatic backup when rolling back
- removed the broader claim that the page guarantees auto-snapshot before every config update

## Result

The consumables/achievements/snapshots slice in `ADMIN_CAPABILITIES.md` now matches the real admin tools much more closely instead of promising broader CRUD, template, and snapshot-analysis workflows than the repo currently ships.

## Verification

- compared the docs against the live consumables, achievements, and snapshots screens plus snapshot actions
- `git diff --check`

This closes the next stale capability block inside `ADMIN_CAPABILITIES.md`.
