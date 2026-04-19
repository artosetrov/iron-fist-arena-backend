---
title: Audit Block 211 — Admin Settings And System Surface Parity
category: audit
tags: [audit, admin, docs, settings, roles]
sources:
  - admin/src/app/(dashboard)/settings/page.tsx
  - admin/src/app/(dashboard)/settings/settings-client.tsx
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
updated: 2026-04-19
status: Fixed
---

# Audit Block 211 — Admin Settings And System Surface Parity

## Scope

- `admin/src/app/(dashboard)/settings/page.tsx`
- `admin/src/app/(dashboard)/settings/settings-client.tsx`
- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

## Why this block

The admin capability doc was still describing a broader system/settings surface than the live dashboard actually exposes.

In the repo today, the settings area is narrower:

- basic database connectivity / config-count / admin-user info
- seeding default config keys
- admin role management for the existing fixed roles

But the doc still read like there were separate live pages for:

- User Activity Log
- Performance Monitoring
- System Status
- Audit Trail
- Custom role authoring

## Fix applied

### `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

- reframed `Custom Roles` as future-facing instead of current live functionality
- replaced the standalone “miscellaneous pages” section with a narrower description of the live settings/system surface
- rewrote the page-surface inventory around actual dashboard pages instead of phantom standalone surfaces
- clarified that:
  - server info is currently a small card inside Settings
  - role management is handled inside Settings for fixed roles
  - audit/performance/system-status style surfaces are still future/admin-adjacent rather than dedicated live pages

## Result

The admin capability doc now matches the current dashboard shape:

- no fake separate pages
- no implied custom-role builder
- settings/system behavior described at the granularity the code actually exposes

## Verification

- compared `ADMIN_CAPABILITIES.md` against the live settings page and settings client
- `git diff --check`

The doc now reflects the current admin surface honestly.
