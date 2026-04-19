---
title: Audit Block 221 — Admin Items CRUD Surface Parity
category: audit
tags: [audit, docs, admin, items]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/app/(dashboard)/items/items-client.tsx
  - admin/src/app/(dashboard)/items/_components/item-editor-client.tsx
  - admin/src/app/(dashboard)/items/_components/item-preview-modal.tsx
  - admin/src/app/api/items/route.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 221 — Admin Items CRUD Surface Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/app/(dashboard)/items/items-client.tsx`
- `admin/src/app/(dashboard)/items/_components/item-editor-client.tsx`
- `admin/src/app/(dashboard)/items/_components/item-preview-modal.tsx`
- `admin/src/app/api/items/route.ts`

## Why this block

The `Items (CRUD)` section in `ADMIN_CAPABILITIES.md` was still describing a richer content-pipeline tool than the current repo actually ships:

- CSV import/export
- duplicate item flow
- change history
- soft delete with circulation warnings
- 3D preview

But the live admin items surface is narrower and more concrete:

- list/filter items
- create/edit through the form editor
- upload or assign image assets
- preview the item in the live card-style modal
- hard delete through the admin item route

## Fix applied

### `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

- expanded the create/edit description with the live editor fields:
  - description
  - image upload / URL / image key
  - upgrade config
- changed preview wording to the actual card-style preview modal
- changed delete wording to direct delete through the admin item route
- removed the implied batch toolchain:
  - CSV import/export
  - duplicate item
  - change history
  - circulation warnings
  - 3D preview

## Result

The items admin docs now describe the real CRUD/editor surface instead of a bigger content-ops suite that the current dashboard does not ship.

## Verification

- compared the docs against `items-client.tsx`, `item-editor-client.tsx`, `item-preview-modal.tsx`, and `api/items/route.ts`
- `git diff --check`

This closes the next stale capability block inside `ADMIN_CAPABILITIES.md`.
