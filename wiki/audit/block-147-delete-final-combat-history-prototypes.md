---
title: Block 147 — delete final combat-history prototypes
category: audit
tags: [audit, prototypes, combat, docs, deletion]
sources:
  - prototypes/combat-proto-B2.html
  - prototypes/combat-proto-B2-v3.html
  - COMBAT_UX_IMPLEMENTATION_PLAN.md
  - COMBAT_V3_IMPLEMENTATION_PLAN.md
  - wiki/audit/block-001-root-files.md
  - wiki/audit/block-121-prototypes-link-parity-and-transition-state.md
updated: 2026-04-17
status: Fixed
---

# Block 147 — delete final combat-history prototypes

## Scope

- `prototypes/combat-proto-B2.html`
- `prototypes/combat-proto-B2-v3.html`
- `COMBAT_UX_IMPLEMENTATION_PLAN.md`
- `COMBAT_V3_IMPLEMENTATION_PLAN.md`

## Why this block

These were the last two files left in `prototypes/`, and they were no longer functioning as live design dependencies:

- `COMBAT_UX_IMPLEMENTATION_PLAN.md` is already explicitly superseded
- `COMBAT_V3_IMPLEMENTATION_PLAN.md` is already explicitly implemented-in-workspace history
- no current feature spec, runtime code, or review flow still depends on the HTML files themselves

At that point, keeping the raw prototype files added more residue than value. The plans and audit history are enough to preserve the decision trail.

## What changed

### `prototypes/combat-proto-B2.html`

- **Previous role:** revised B2 direction used by the older v2 implementation plan
- **Why removal was safe:** only historical planning docs still named it, and those docs no longer require the HTML artifact itself
- **Result:** removed from the working tree

### `prototypes/combat-proto-B2-v3.html`

- **Previous role:** final combat-history prototype nearest to the shipped round-log direction
- **Why removal was safe:** the implementation record and shipped code preserve the useful history without needing the standalone HTML
- **Result:** removed from the working tree

### `COMBAT_UX_IMPLEMENTATION_PLAN.md`

- reframed the prototype note as historical rather than live
- removed the clickable dependency on `prototypes/combat-proto-B2.html`

### `COMBAT_V3_IMPLEMENTATION_PLAN.md`

- reframed the approved-prototype language as historical context
- removed wording that still depended on the HTML file being present as an active artifact

## Problems resolved

1. **Prototype directory still looked like an active source bucket**
   - Risk before: even with only two files left, `prototypes/` still implied a maintained combat HTML surface.
   - Resolution: removed the final pair and left the history in docs/audit instead of raw artifacts.

2. **Historical plans still leaned on local HTML files**
   - Risk before: a reader could treat the files as required current references.
   - Resolution: the plans now keep the rationale while clearly treating the prototypes as removed history.

## Verification

- confirmed both `prototypes/combat-proto-B2.html` and `prototypes/combat-proto-B2-v3.html` no longer exist in the working tree
- confirmed `COMBAT_UX_IMPLEMENTATION_PLAN.md` and `COMBAT_V3_IMPLEMENTATION_PLAN.md` now treat those prototypes as historical context, not live dependencies
- `git diff --check`

## Follow-up

- `prototypes/` is now empty; from here on, combat design history should live in tracked docs and audit records instead of detached HTML artifacts.

