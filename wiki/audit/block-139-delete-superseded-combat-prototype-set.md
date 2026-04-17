---
title: Block 139 — delete superseded combat prototype set
category: audit
tags: [audit, prototypes, combat, deletion, cleanup]
sources:
  - prototypes/combat-proto-A.html
  - prototypes/combat-proto-B.html
  - prototypes/combat-proto-C.html
  - prototypes/combat-prototypes.html
  - prototypes/combat-proto-B2-v2.html
  - COMBAT_UX_AUDIT.md
  - COMBAT_UX_IMPLEMENTATION_PLAN.md
  - COMBAT_V3_IMPLEMENTATION_PLAN.md
  - wiki/audit/block-121-prototypes-link-parity-and-transition-state.md
updated: 2026-04-16
status: Fixed
---

# Block 139 — delete superseded combat prototype set

## Scope

- `prototypes/combat-proto-A.html`
- `prototypes/combat-proto-B.html`
- `prototypes/combat-proto-C.html`
- `prototypes/combat-prototypes.html`
- `prototypes/combat-proto-B2-v2.html`

## Why this block

After the earlier root/prototype cleanup, the combat prototype set had become split into:

- a **retained reference path**: `B2` and `B2-v3`
- a **fully superseded exploration path**: `A`, `B`, `C`, the A/B/C launcher, and the extra `B2-v2` intermediate branch

These files no longer had any live consumer outside audit history, and their role was already described in the written combat audit docs. That made them strong deletion candidates without losing the core combat design story.

## Related pages

- [[block-001-root-files]]
- [[block-121-prototypes-link-parity-and-transition-state]]
- [[block-138-delete-deprecated-prototype-residue]]

## What was removed

### `prototypes/combat-proto-A.html`

- **Previous role:** Variant A vertical-ownership concept
- **Why removal was safe:** only served the old A/B/C comparison set; no live app/docs dependency remained
- **Result:** removed from the working tree

### `prototypes/combat-proto-B.html`

- **Previous role:** Variant B hotbar / side-portrait concept
- **Why removal was safe:** same superseded role as Variant A, fully covered by historical audit narrative
- **Result:** removed from the working tree

### `prototypes/combat-proto-C.html`

- **Previous role:** stance-silhouette concept
- **Why removal was safe:** explicitly exploratory/rejected branch with no retained consumer outside audit history
- **Result:** removed from the working tree

### `prototypes/combat-prototypes.html`

- **Previous role:** side-by-side launcher for A/B/C review
- **Why removal was safe:** once A/B/C are gone, the launcher is just dead scaffolding
- **Result:** removed from the working tree

### `prototypes/combat-proto-B2-v2.html`

- **Previous role:** intermediate B2 iteration before the retained `B2-v3` path
- **Why removal was safe:** `B2` and `B2-v3` already preserve the meaningful transition history; `B2-v2` added noise more than unique value
- **Result:** removed from the working tree

## What stays on purpose

- `prototypes/combat-proto-B2.html`
- `prototypes/combat-proto-B2-v3.html`

These remain as the retained historical bridge between the earlier concept work and the later combat implementation direction.

## Problems resolved

1. **Superseded combat history was too wide**
   - Risk before: too many near-duplicate prototype generations made the prototype layer harder to read.
   - Resolution: narrowed it to the retained B2/B2-v3 path.

2. **Dead A/B/C launcher scaffolding**
   - Risk before: `combat-prototypes.html` implied a maintained comparison surface even though the whole set was already historical-only.
   - Resolution: removed it together with its children.

3. **Intermediate branch overload**
   - Risk before: `B2-v2` sat between `B2` and `B2-v3` without providing enough unique value to justify more residue.
   - Resolution: removed the extra intermediate variant.

## Verification

- confirmed the five target combat prototype files no longer exist in the working tree
- confirmed `prototypes/combat-proto-B2.html` and `prototypes/combat-proto-B2-v3.html` still remain
- updated inventory and earlier audit blocks so the deletion is reflected instead of leaving deprecated rows stale
- `git diff --check`

## Follow-up

- Keep `B2`/`B2-v3` until the combat design history is either fully archived elsewhere or intentionally collapsed into a smaller single-reference package.
