---
title: Audit Block 173 — Admin Design System Dead Preview Export Removal
category: audit
tags: [audit, admin, design-system, cleanup]
sources:
  - admin/src/app/(dashboard)/design-system/ds-components-2.tsx
  - admin/src/app/(dashboard)/design-system/design-system-client.tsx
  - wiki/audit/block-059-admin-design-system-residual-debt-and-warning-cleanup.md
updated: 2026-04-17
---

# Audit Block 173 — Admin Design System Dead Preview Export Removal

## Why this block exists

`block-059` left one small but honest `Needs review` tail in the admin design-system surface:

- `HeroWidgetPreviews`
- `StanceDisplayPreviews`

Both still lived in `ds-components-2.tsx`, but the design-system page had already moved to the Figma-derived preview set:

- `HeroWidgetAllVariants`
- `StanceDisplayAllVariants`

That made the legacy exports dead weight rather than useful fallback coverage.

## What changed

- confirmed there were no live imports of:
  - `HeroWidgetPreviews`
  - `StanceDisplayPreviews`
- deleted both dead exports from `admin/src/app/(dashboard)/design-system/ds-components-2.tsx`
- updated the old audit note in `block-059` so the file is no longer left in a stale `Needs review` state

## Result

`ds-components-2.tsx` is still a mixed legacy preview surface, but it no longer carries obviously dead hero/stance exports that the page stopped using.

That means the remaining residue in this file is now genuinely “still used or needs separate review”, not “we already know these two exports are dead but have not removed them yet.”
