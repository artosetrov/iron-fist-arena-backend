---
title: Audit Block 232 — Source of Truth Documentation Index Admin Workflow Parity
category: audit
tags: [audit, docs, source-of-truth, admin]
sources:
  - docs/01_source_of_truth/DOCUMENTATION_INDEX.md
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - docs/03_backend_and_api/API_REFERENCE.md
updated: 2026-04-19
status: Fixed
---

# Audit Block 232 — Source of Truth Documentation Index Admin Workflow Parity

## Scope

- `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`
- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `docs/03_backend_and_api/API_REFERENCE.md`

## Why this block

The master documentation index still carried an older assumption that `ADMIN_CAPABILITIES.md` was both:

- a near-universal registry of config keys
- and the default execution path for balancing, entity creation, push, battle pass, and other workflows

That was no longer true after the admin surface cleanup:

- some flows are live admin-backed
- some are backend-owned or code/config-backed
- and `ADMIN_CAPABILITIES.md` is now a capability map, not a promise that every operation exists as a live editor

## Fix applied

- refreshed the master-index freshness banner to `2026-04-19`
- rewrote the admin-panel and operations quick-reference sections so they no longer point people at `ADMIN_CAPABILITIES.md` as an all-config-key registry
- rewrote topic lookup entries for economy, battle pass, achievements, push, mail, and admin panel to describe the real live admin surfaces
- narrowed the workflow checklists:
  - balance changes now explicitly confirm whether a value is admin-backed before telling people to edit it there
  - entity creation now explicitly confirms whether the flow is admin-backed or code/config-backed before routing the work

## Result

`DOCUMENTATION_INDEX.md` now behaves like a real source-of-truth entry point again, instead of a stale workflow script that overroutes people into the admin panel.

## Verification

- compared `DOCUMENTATION_INDEX.md` against the cleaned `ADMIN_CAPABILITIES.md`
- checked referenced backend/admin ownership boundaries against `API_REFERENCE.md`
- `git diff --check`

This closes the next source-of-truth index drift adjacent to the admin capability cleanup.
