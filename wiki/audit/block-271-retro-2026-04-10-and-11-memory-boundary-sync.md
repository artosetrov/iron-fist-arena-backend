---
title: Audit Block 271 — Retro 2026-04-10 and 2026-04-11 Memory Boundary Sync
category: audit
tags: [audit, docs, retro, historical-boundary]
sources:
  - docs/retro/RETRO_2026-04-10.md
  - docs/retro/RETRO_2026-04-11.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 271 — Retro 2026-04-10 and 2026-04-11 Memory Boundary Sync

## Scope

This block cleans the remaining external memory-note shorthand from the two
dated retro journals for 2026-04-10 and 2026-04-11.

## Why this block

Both retros were already clearly historical, but they still depended on
external note names for a few recurring engineering lessons:

- `IntegratedCharacterCard` unification provenance
- git-watcher trigger workflow
- ViewModel init-preservation recurrence
- the broader rule that repeated manual lessons should move into scanners

The historical substance was useful; the off-repo file-name shorthand was not.

## Changes shipped

### `docs/retro/RETRO_2026-04-10.md`

- Removed the direct external-note pointer from the `IntegratedCharacterCard`
  unification note.
- Rephrased the update note so it now points back to the checked-in component
  and adjacent UI/design-system documentation instead of an off-repo memory
  filename.

### `docs/retro/RETRO_2026-04-11.md`

- Rewrote the git-watcher lesson so it now refers to the checked-in
  operational workflow rather than naming external memory files.
- Rephrased the recurring `@Observable` init-preservation lesson without
  external note names.
- Rewrote the meta-rule around scanner automation so it now stands directly on
  checked-in prose instead of off-repo shorthand.
- Reworded the follow-up task list so it refers to concrete patterns
  (`AvatarImageView` determinism, flat-vs-nested response shapes) instead of
  memory filenames.

## Result

The 2026-04-10 and 2026-04-11 retros now preserve the same lessons in
repo-owned prose, without leaning on external memory-note breadcrumbs.
