---
title: Block 121 — Prototypes link parity and transition state
category: audit
tags: [audit, prototypes, combat, legal, source-of-truth]
sources:
  - COMBAT_UX_AUDIT.md
  - COMBAT_UX_IMPLEMENTATION_PLAN.md
  - prototypes/combat-prototypes.html
  - prototypes/combat-proto-A.html
  - prototypes/combat-proto-B.html
  - prototypes/combat-proto-B2.html
  - prototypes/combat-proto-B2-v2.html
  - prototypes/combat-proto-B2-v3.html
  - prototypes/combat-proto-C.html
  - prototypes/hero-card-delete-rings-layout.html
  - prototypes/hero-card-rings-deepdive.html
  - prototypes/privacy.html
  - prototypes/terms.html
  - prototypes/victory-rewards/index.html
  - prototypes/victory-rewards/assets/reward-gold.png
  - prototypes/victory-rewards/assets/reward-xp.png
  - prototypes/victory-rewards/assets/reward-rating-up.png
updated: 2026-04-16
status: Fixed
---

# Block 121 — Prototypes link parity and transition state

## Scope

- `COMBAT_UX_AUDIT.md`
- `COMBAT_UX_IMPLEMENTATION_PLAN.md`
- `prototypes/combat-prototypes.html`
- `prototypes/combat-proto-A.html`
- `prototypes/combat-proto-B.html`
- `prototypes/combat-proto-B2.html`
- `prototypes/combat-proto-B2-v2.html`
- `prototypes/combat-proto-B2-v3.html`
- `prototypes/combat-proto-C.html`
- `prototypes/hero-card-delete-rings-layout.html`
- `prototypes/hero-card-rings-deepdive.html`
- `prototypes/privacy.html`
- `prototypes/terms.html`
- `prototypes/victory-rewards/index.html`
- `prototypes/victory-rewards/assets/reward-gold.png`
- `prototypes/victory-rewards/assets/reward-xp.png`
- `prototypes/victory-rewards/assets/reward-rating-up.png`

## Why this block

This slice is no longer “random loose HTML.” It is a real transition state:

- the older combat/legal prototypes are being moved out of the repo root into `prototypes/`
- the docs still carry historical rationale and implementation plans for those prototype files
- some links had quietly broken during the move

So the goal here was not to redesign the prototypes. It was to make the transition truthful and keep the docs navigable.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-001-root-files]]
- [[block-120-ui-audit-artifacts-historical-boundary-cleanup]]

## File notes

### `COMBAT_UX_AUDIT.md`

- **Zone:** root historical combat UX discovery doc
- **Purpose:** records the original A/B/C rationale and recommendation set
- **Problems found:**
  - all prototype links still pointed at the old root paths
- **What was fixed:**
  - updated links to `prototypes/combat-proto-A.html`, `prototypes/combat-proto-B.html`, `prototypes/combat-proto-C.html`, and `prototypes/combat-prototypes.html`
- **Status:** Fixed

### `COMBAT_UX_IMPLEMENTATION_PLAN.md`

- **Zone:** root historical combat implementation plan
- **Purpose:** describes the B2-oriented implementation push that followed the initial audit
- **Problems found:**
  - still pointed at deleted root prototype paths for B2 and the A/B/C comparison index
- **What was fixed:**
  - updated the prototype references to `prototypes/combat-proto-B2.html` and `prototypes/combat-prototypes.html`
- **Status:** Fixed

### `prototypes/combat-prototypes.html`

- **Zone:** prototype index / review launcher
- **Purpose:** side-by-side launcher for the exploratory A/B/C combat proposals
- **Depends on:** `combat-proto-A.html`, `combat-proto-B.html`, `combat-proto-C.html`, `../COMBAT_UX_AUDIT.md`
- **Used by:** manual review only; linked from the combat audit docs
- **Problems found:**
  - its audit-report links still assumed `COMBAT_UX_AUDIT.md` lived in the same folder
  - wording still sounded slightly present-tense for what is now a historical proposal set
- **What was fixed:**
  - repointed the audit links to `../COMBAT_UX_AUDIT.md`
  - clarified the link label as a historical audit report
- **What changed later:** deleted from the working tree in `block-139` after the A/B/C set was judged fully superseded by the retained B2/B2-v3 history
- **Status:** Fixed

### `prototypes/combat-proto-A.html`

- **Zone:** historical combat prototype
- **Purpose:** Variant A vertical ownership / integrated STRIKE concept
- **Depends on:** Google Fonts, remote DiceBear avatar images
- **Used by:** `prototypes/combat-prototypes.html`, manual design review
- **Review outcome:**
  - clear role as historical design exploration
  - no runtime consumers in app/admin/backend
- **What changed later:** deleted from the working tree in `block-139` after confirming no live consumer beyond the historical audit trail
- **Status:** Fixed

### `prototypes/combat-proto-B.html`

- **Zone:** historical combat prototype
- **Purpose:** Variant B hotbar / side-portrait concept
- **Depends on:** Google Fonts, remote DiceBear avatar images
- **Used by:** `prototypes/combat-prototypes.html`, manual design review
- **Review outcome:**
  - same role as a historical exploration artifact
  - no live product consumer
- **What changed later:** deleted from the working tree in `block-139` after confirming no live consumer beyond the historical audit trail
- **Status:** Fixed

### `prototypes/combat-proto-B2.html`

- **Zone:** historical combat prototype
- **Purpose:** revised B2 direction that fed the older implementation plan
- **Depends on:** Google Fonts, remote DiceBear avatar images
- **Used by:** `COMBAT_UX_IMPLEMENTATION_PLAN.md`, manual review
- **Review outcome:**
  - still useful as transition evidence between A/B/C and B2-v3
  - but not a current source of truth by itself
- **What changed later:** deleted from the working tree in `block-147` after the historical implementation plans stopped needing the raw HTML artifact itself
- **Needs separate decision:** keep for implementation history or archive once B2-v3 history is captured elsewhere
- **Status:** Needs review

### `prototypes/combat-proto-B2-v2.html`

- **Zone:** historical combat prototype
- **Purpose:** intermediate B2 iteration with stance bonuses and always-on talents
- **Depends on:** Google Fonts, remote DiceBear avatar images
- **Used by:** manual review only
- **Review outcome:**
  - exploratory iteration with no direct live consumer
  - still valuable only as design-history evidence
- **What changed later:** deleted from the working tree in `block-139` because it was only an intermediate branch and B2/B2-v3 remain as the better retained reference points
- **Status:** Fixed

### `prototypes/combat-proto-B2-v3.html`

- **Zone:** historical combat prototype
- **Purpose:** later B2-v3 round-log direction, closest to the eventual shipped interaction ideas
- **Depends on:** Google Fonts, remote DiceBear avatar images, inline demo JS
- **Used by:** manual review only
- **Review outcome:**
  - strongest candidate to keep among the combat prototypes because it is the nearest historical bridge to the shipped direction
  - still not a live source of truth
- **What changed later:** deleted from the working tree in `block-147` after the implementation record and shipped code were treated as the retained history surface
- **Needs separate decision:** keep as reference artifact or archive after a fuller current-state combat spec exists
- **Status:** Needs review

### `prototypes/combat-proto-C.html`

- **Zone:** historical combat prototype
- **Purpose:** stance-silhouette concept
- **Depends on:** Google Fonts, remote DiceBear avatar images
- **Used by:** `prototypes/combat-prototypes.html`, manual review
- **Review outcome:**
  - clearly exploratory and high-risk by design
  - no live consumer
- **What changed later:** deleted from the working tree in `block-139` after confirming no live consumer beyond the historical audit trail
- **Status:** Fixed

### `prototypes/hero-card-delete-rings-layout.html`

- **Zone:** historical UI prototype
- **Purpose:** layout study for hero-card delete affordance plus HP/energy ring placement
- **Used by:** manual design review only
- **Review outcome:**
  - clear local role
  - no app/admin consumer detected
- **What changed later:** deleted from the working tree in `block-138` after confirming no live consumer beyond audit history
- **Status:** Fixed

### `prototypes/hero-card-rings-deepdive.html`

- **Zone:** historical UI prototype
- **Purpose:** deeper exploration of hero-card ring layouts and stat presentation
- **Used by:** manual design review only
- **Review outcome:**
  - still useful as UI exploration evidence
  - not wired into any live screen or docs beyond inventory/audit history
- **What changed later:** deleted from the working tree in `block-138` after confirming no live consumer beyond audit history
- **Status:** Fixed

### `prototypes/privacy.html`

- **Zone:** prototype / legal static surface
- **Purpose:** privacy-policy HTML draft in the new `prototypes/` location
- **Depends on:** Google Fonts
- **Used by:** manual review; transitional replacement for the deleted working-tree root copy
- **Problems found:**
  - this lives in a move-in-progress state alongside a deleted tracked root counterpart
  - top “home” link still assumes a root landing contract that is not defined here
- **What was fixed:**
  - no mechanical change in this pass; the only safe fix was on the Terms side where a local cross-link was clearly intended
- **What changed later:** deleted from the working tree in `block-146` after the app and docs no longer needed local legal HTML copies
- **Needs separate decision:** finalize the legal-page move and define the real landing/static deploy contract
- **Status:** Needs review

### `prototypes/terms.html`

- **Zone:** prototype / legal static surface
- **Purpose:** terms-of-service HTML draft in the new `prototypes/` location
- **Depends on:** Google Fonts
- **Used by:** manual review; transitional replacement for the deleted working-tree root copy
- **Problems found:**
  - footer linked to `/privacy`, which is wrong for the local prototype move and easy to break in subpath previews
  - like `prototypes/privacy.html`, it still assumes a root landing contract for the logo link
- **What was fixed:**
  - changed the footer link to `privacy.html`
- **What changed later:** deleted from the working tree in `block-146` after the app and docs no longer needed local legal HTML copies
- **Needs separate decision:** finalize the legal-page move and define the real landing/static deploy contract
- **Status:** Fixed

### `prototypes/victory-rewards/index.html`

- **Zone:** standalone prototype
- **Purpose:** before/after reward animation comparison and interaction study
- **Depends on:** local reward PNG assets, Google Fonts, inline animation JS
- **Used by:** manual design review only
- **Review outcome:**
  - self-contained and internally consistent
  - empty `alt=""` on reward icons looks intentional for decorative icon treatment in a visual prototype
- **What changed later:** deleted from the working tree in `block-144` after it no longer had any named live consumer beyond audit history
- **Needs separate decision:** keep as animation reference or archive once the final reward-motion spec lives elsewhere
- **Status:** OK

### `prototypes/victory-rewards/assets/reward-gold.png`

- **Zone:** prototype asset
- **Purpose:** gold reward icon for the victory-rewards prototype
- **Used by:** `prototypes/victory-rewards/index.html`
- **Review outcome:** correct self-contained prototype asset, `128x128 PNG`
- **What changed later:** deleted from the working tree in `block-144` together with the enclosing prototype set
- **Status:** OK

### `prototypes/victory-rewards/assets/reward-xp.png`

- **Zone:** prototype asset
- **Purpose:** XP reward icon for the victory-rewards prototype
- **Used by:** `prototypes/victory-rewards/index.html`
- **Review outcome:** correct self-contained prototype asset, `128x128 PNG`
- **What changed later:** deleted from the working tree in `block-144` together with the enclosing prototype set
- **Status:** OK

### `prototypes/victory-rewards/assets/reward-rating-up.png`

- **Zone:** prototype asset
- **Purpose:** rating-change icon for the victory-rewards prototype
- **Used by:** `prototypes/victory-rewards/index.html`
- **Review outcome:** correct self-contained prototype asset, `128x128 PNG`
- **What changed later:** deleted from the working tree in `block-144` together with the enclosing prototype set
- **Status:** OK

## Problems found

1. **Prototype move broke doc navigation**
   - Risk: combat rationale docs point at files that no longer exist in the working tree, so review history becomes harder to trust.
   - Fix: updated the combat audit/plan links plus the reverse link from `prototypes/combat-prototypes.html`.

2. **Legal prototype move is only half-finished**
   - Risk: the repo now has deleted tracked root legal pages and untracked replacements under `prototypes/`, which is easy to misunderstand during deploy or legal review.
   - Fix: did not revert or force the move; instead documented the transition state and fixed the one clearly local cross-link in `prototypes/terms.html`.

3. **Most prototype HTML files are historical artifacts, not live product surfaces**
   - Risk: someone treats them as source of truth instead of design-history material.
   - Fix: captured their roles and marked the archive/keep decision explicitly instead of silently leaving them ambiguous.

## Verification

- inspected all git-visible prototype HTML files and reward PNG assets in `prototypes/`
- checked relative link targets for the git-visible prototype HTML set
- verified the combat docs now point at the moved prototype paths
- `git diff --check`

## Follow-up

- Finish the root → `prototypes/` move explicitly instead of leaving deleted tracked root copies and untracked replacements in parallel.
- Decide which combat/hero/reward prototypes are worth keeping as design history and which should be archived.
- Define the real repo-local contract for legal/static page deployment so `privacy` / `terms` are no longer half prototype and half production assumption.
