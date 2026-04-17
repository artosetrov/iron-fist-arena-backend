---
title: Block 123 — UI review and plan docs historical boundaries
category: audit
tags: [audit, docs, ui, ux, historical-boundary, source-of-truth]
sources:
  - docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md
  - docs/07_ui_ux/COMIC_ONBOARDING_PLAN.md
  - docs/07_ui_ux/DAILY_LOGIN_CAROUSEL_REVIEW.md
  - docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md
  - docs/07_ui_ux/PROTOTYPE_INSIGHTS.md
  - docs/07_ui_ux/QA_FIX_PLAN_2026-04-10.md
  - docs/07_ui_ux/QA_PLAYTHROUGH_2026-04-10.md
  - docs/07_ui_ux/SOCIAL_FLOWS_UX_SPEC.md
updated: 2026-04-16
status: Fixed
---

# Block 123 — UI review and plan docs historical boundaries

## Scope

- `docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md`
- `docs/07_ui_ux/COMIC_ONBOARDING_PLAN.md`
- `docs/07_ui_ux/DAILY_LOGIN_CAROUSEL_REVIEW.md`
- `docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md`
- `docs/07_ui_ux/PROTOTYPE_INSIGHTS.md`
- `docs/07_ui_ux/QA_FIX_PLAN_2026-04-10.md`
- `docs/07_ui_ux/QA_PLAYTHROUGH_2026-04-10.md`
- `docs/07_ui_ux/SOCIAL_FLOWS_UX_SPEC.md`

## Why this block

This slice of `docs/07_ui_ux/` contains genuinely useful product thinking: audits, redesign concepts, playthroughs, and roadmap proposals. The problem was not low quality. The problem was boundary drift.

Several of these docs still read like active source-of-truth or live implementation guidance even though they are dated exploratory artifacts, review snapshots, or approval-gated plans. That makes them easy to over-trust during future work.

## Related pages

- [[block-115-operations-figma-and-historical-doc-boundaries]]
- [[block-116-source-of-truth-doc-index-parity]]
- [[block-120-ui-audit-artifacts-historical-boundary-cleanup]]
- [[interactive-combat]]
- [[social]]

## File notes

### `docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md`

- **Zone:** UI/UX proposal
- **Purpose:** combat-screen redesign concept for the active fight screen and result reveal
- **Problems found:**
  - read like a live spec instead of a dated proposal snapshot
- **What was fixed:**
  - added an explicit historical/proposal boundary and redirected readers to current `wiki/` + `prototypes/` truth surfaces
- **Status:** Fixed

### `docs/07_ui_ux/COMIC_ONBOARDING_PLAN.md`

- **Zone:** art/spec proposal
- **Purpose:** comic-onboarding concept and art prompt plan
- **Problems found:**
  - lacked a boundary between concept art planning and live onboarding/tutorial implementation
- **What was fixed:**
  - marked it as a historical concept plan and pointed readers at the current tutorial/character feature maps for live truth
- **Status:** Fixed

### `docs/07_ui_ux/DAILY_LOGIN_CAROUSEL_REVIEW.md`

- **Zone:** UI redesign review
- **Purpose:** redesign rationale for one daily-login reward presentation iteration
- **Problems found:**
  - could be mistaken for the current implementation contract of the daily-login screen
- **What was fixed:**
  - added a dated review boundary and explicit reminder to re-check live Swift/runtime state
- **Status:** Fixed

### `docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md`

- **Zone:** motion/game-feel audit
- **Purpose:** broad emotional-feedback and motion direction for the product
- **Problems found:**
  - large count-based claims and coverage statements were presented without a historical boundary
- **What was fixed:**
  - framed it as a historical audit snapshot requiring revalidation before operational reuse
- **Status:** Fixed

### `docs/07_ui_ux/PROTOTYPE_INSIGHTS.md`

- **Zone:** prototype archive
- **Purpose:** retained lessons from deleted prototype files
- **Problems found:**
  - called itself the canonical reference, which is too strong for an extracted archive
- **What was fixed:**
  - reframed it as a historical prototype-insight archive, not live source-of-truth
- **Status:** Fixed

### `docs/07_ui_ux/QA_FIX_PLAN_2026-04-10.md`

- **Zone:** execution roadmap snapshot
- **Purpose:** historical 4-week remediation roadmap derived from a specific audit run
- **Problems found:**
  - still read like an active sprint/release plan
- **What was fixed:**
  - added a historical execution-boundary note making clear that many items may now be shipped or superseded
- **Status:** Fixed

### `docs/07_ui_ux/QA_PLAYTHROUGH_2026-04-10.md`

- **Zone:** forensic audit report
- **Purpose:** detailed simulator/code audit snapshot
- **Problems found:**
  - severity/count language could be mistaken for the current product-health readout
- **What was fixed:**
  - added a historical snapshot boundary and explicit revalidation guidance
- **Status:** Fixed

### `docs/07_ui_ux/SOCIAL_FLOWS_UX_SPEC.md`

- **Zone:** UX proposal/spec
- **Purpose:** early social feature design proposal for friends, messaging, and challenges
- **Problems found:**
  - proposal language was clear, but the file lacked a strong boundary against the now-shipped social runtime
- **What was fixed:**
  - marked it as a historical proposal/spec and redirected readers to the live social feature map plus current code
- **Status:** Fixed

## Problems found

1. **High-value review docs were easy to mistake for live truth**
   - Risk: future work can anchor on proposal-era assumptions instead of the current product.
   - Fix: added explicit status-boundary notes at the top of each file.

2. **Historical artifacts were not consistently tied back to current source-of-truth**
   - Risk: readers consume a good old doc without checking whether the repo moved on.
   - Fix: pointed readers back to current `wiki/` feature/system pages and live code where appropriate.

3. **One archive overstated itself as canonical**
   - Risk: an extracted prototype summary becomes harder to challenge than the code that replaced it.
   - Fix: downgraded `PROTOTYPE_INSIGHTS.md` from canonical reference language to historical archive language.

## Verification

- inspected the top matter and leading context of all eight docs
- confirmed each now declares its historical/proposal boundary explicitly
- `git diff --check`

## Follow-up

- Continue the same source-of-truth boundary cleanup through the remaining dated `docs/07_ui_ux/` review/design files.
- Keep proposal docs useful, but never let them out-rank the current feature maps and live code.
