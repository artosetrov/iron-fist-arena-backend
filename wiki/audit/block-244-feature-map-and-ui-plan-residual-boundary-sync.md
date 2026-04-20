---
title: Audit Block 244 — Feature Map and UI Plan Residual Boundary Sync
category: audit
tags: [audit, wiki, docs, feature-maps, ui]
sources:
  - wiki/features/stash.md
  - wiki/features/achievements.md
  - docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md
  - admin/src/app/(dashboard)/items/page.tsx
  - admin/src/app/(dashboard)/items/items-client.tsx
  - admin/src/app/(dashboard)/achievements/page.tsx
  - admin/src/app/(dashboard)/achievements/achievements-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 244 — Feature Map and UI Plan Residual Boundary Sync

## Scope

- `wiki/features/stash.md`
- `wiki/features/achievements.md`
- `docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md`

## Why this block

After the larger feature-map and API-reference cleanup, a few tiny but still real residual tails remained:

- `stash.md` still used a broad `admin/src/app/(dashboard)/items/` directory shorthand instead of the exact live files
- `achievements.md` named the client/editor file but skipped the page route itself
- `STRIKE_REVEAL_SHAPE_B_PLAN.md` still said to run snapshot tests “if present,” even though no dedicated `HexboundUI` snapshot target is checked into the current tree

## Fix applied

- narrowed the stash admin note to the exact adjacent items page and client files
- added the achievements page route beside the existing client/action/lib references
- rewrote the Strike Reveal manual QA step to the current truth: use captured screenshots for visual review because there is no checked-in snapshot-test target for that flow today

## Result

The remaining small shorthand and “if present” style tails are gone from this slice, so both the feature-map layer and the UI plan now point at the current repo more precisely.

## Verification

- live file existence checks for the referenced admin page/client files
- repository search confirming no dedicated `HexboundUI` snapshot target is checked in today
- `git diff --check`
