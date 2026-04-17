---
title: Block 149 — root combat history doc relocation
category: audit
tags: [audit, docs, combat, relocation]
sources:
  - docs/features/combat/COMBAT_UX_AUDIT.md
  - docs/features/combat/COMBAT_UX_IMPLEMENTATION_PLAN.md
  - docs/features/combat/COMBAT_V3_IMPLEMENTATION_PLAN.md
  - wiki/audit/block-001-root-files.md
  - wiki/audit/project-file-inventory.md
updated: 2026-04-17
status: Fixed
---

# Block 149 — root combat history doc relocation

## Scope

- `COMBAT_UX_AUDIT.md` -> `docs/features/combat/COMBAT_UX_AUDIT.md`
- `COMBAT_UX_IMPLEMENTATION_PLAN.md` -> `docs/features/combat/COMBAT_UX_IMPLEMENTATION_PLAN.md`
- `COMBAT_V3_IMPLEMENTATION_PLAN.md` -> `docs/features/combat/COMBAT_V3_IMPLEMENTATION_PLAN.md`

## Why this block

These files are still useful, but only as combat design history:

- UX audit rationale
- v2 implementation history
- v3 implementation record

They no longer belonged in root, and after the prototype deletions they still carried dead prototype-link language that needed one more cleanup pass.

## What changed

### Combat history docs

- moved all three combat history docs under `docs/features/combat/`
- kept their cross-links local so the historical chain remains navigable inside the combat feature folder

### Dead prototype references

- removed the last live-looking link to the deleted `combat-prototypes.html` launcher from `COMBAT_UX_IMPLEMENTATION_PLAN.md`
- converted the deleted A/B/C prototype references in `COMBAT_UX_AUDIT.md` into historical notes instead of broken links

## Problems resolved

1. **Root still implied an active combat-planning surface**
   - Resolution: the combat planning/audit lineage now lives beside the rest of the combat feature docs.

2. **Historical combat docs still pointed at deleted HTML artifacts**
   - Resolution: those references now read as historical context instead of clickable dead paths.

## Verification

- confirmed all three combat docs no longer exist in root
- confirmed the moved files exist under `docs/features/combat/`
- confirmed no `prototypes/combat-proto-*` or `prototypes/combat-prototypes.html` references remain in the moved combat docs
- `git diff --check`

## Follow-up

- combat history now has a coherent home; future cleanup there should be about content truth, not path chaos.
