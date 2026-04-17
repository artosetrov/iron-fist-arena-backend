---
title: Block 127 — dated product, economy, and architecture doc boundaries
category: audit
tags: [audit, docs, product, economy, architecture, historical-boundary]
sources:
  - docs/06_game_systems/ECONOMY_AUDIT_2026-04-13.md
  - docs/09_rules_and_guidelines/INLINE_API_AUDIT.md
  - docs/FULL_PRODUCT_AUDIT_2026-03-21.md
  - docs/MIGRATION_PLAN.md
  - docs/features/combat/INTERACTIVE_COMBAT_PLAN.md
updated: 2026-04-16
status: Fixed
---

# Block 127 — dated product, economy, and architecture doc boundaries

## Scope

- `docs/06_game_systems/ECONOMY_AUDIT_2026-04-13.md`
- `docs/09_rules_and_guidelines/INLINE_API_AUDIT.md`
- `docs/FULL_PRODUCT_AUDIT_2026-03-21.md`
- `docs/MIGRATION_PLAN.md`
- `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`

## Why this block

Once the UI/doc source-of-truth layer was mostly cleaned up, the next risky slice was the cross-domain “big thinking” docs:

- full-product audits
- architecture/code-smell audits
- economy redesign manifestos
- migration plans
- feature plans that predate the shipped runtime

These docs are valuable, but they become dangerous when they still sound like present-tense truth instead of dated reasoning.

## Related pages

- [[block-045-backend-tutorial-achievement-and-weekly-contracts]]
- [[block-046-backend-feature-flags-progression-and-runtime-cleanup]]
- [[block-073-tutorial-scripted-fight-contract-and-victory-parity]]
- [[block-109-operations-deploy-docs-reality-sync]]

## File notes

### `docs/06_game_systems/ECONOMY_AUDIT_2026-04-13.md`

- **Zone:** economy audit / redesign memo
- **Purpose:** deep diagnosis and redesign proposal for the full economy
- **Problems found:**
  - framed itself as a full redesign constitution without a clear boundary against later economy/runtime changes
- **What was fixed:**
  - added an explicit historical audit/redesign boundary and revalidation guidance
- **Status:** Fixed

### `docs/09_rules_and_guidelines/INLINE_API_AUDIT.md`

- **Zone:** architecture audit
- **Purpose:** records a pass over direct API/service calls inside SwiftUI views
- **Problems found:**
  - count-heavy framing (`181` files, `8` offenders) could be mistaken for current architecture state
- **What was fixed:**
  - added an explicit historical architecture-audit boundary
- **Status:** Fixed

### `docs/FULL_PRODUCT_AUDIT_2026-03-21.md`

- **Zone:** repo-wide forensic audit
- **Purpose:** captures a large early whole-product review across multiple agents
- **Problems found:**
  - still read like a current overall repo-health verdict despite major later cleanup
- **What was fixed:**
  - added a strong historical snapshot boundary and current-state revalidation reminder
- **Status:** Fixed

### `docs/MIGRATION_PLAN.md`

- **Zone:** documentation-process history
- **Purpose:** records the original docs reorganization plan and phase structure
- **Problems found:**
  - still read like an active documentation queue instead of provenance
- **What was fixed:**
  - added a historical migration-plan boundary clarifying that it is rollout history, not the live task board
- **Status:** Fixed

### `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`

- **Zone:** feature design plan
- **Purpose:** historical plan for interactive combat rollout
- **Problems found:**
  - still opened like a live combat implementation plan even though the codebase now has shipped/changed interactive-combat runtime
- **What was fixed:**
  - added a historical feature-plan boundary and redirected readers to current runtime/wiki truth
- **Status:** Fixed

## Problems found

1. **Cross-domain audits age badly when they keep present-tense authority**
   - Risk: people over-trust stale repo-wide diagnoses instead of checking what later fixes already changed.
   - Fix: added explicit historical boundaries to the dated audit docs.

2. **Design and migration plans can silently become fake backlogs**
   - Risk: teams start treating an old phased plan as the current execution queue.
   - Fix: reframed `MIGRATION_PLAN.md` and `INTERACTIVE_COMBAT_PLAN.md` as historical planning artifacts.

3. **Economy and architecture memos need stronger runtime disclaimers**
   - Risk: detailed, high-confidence prose can out-rank the actual code if it is not clearly dated.
   - Fix: added direct revalidation guidance back to live code and audited wiki surfaces.

## Verification

- inspected the opening sections of all five docs
- confirmed each now declares its historical scope explicitly
- `git diff --check`

## Follow-up

- Continue the same boundary cleanup through the remaining dated docs under `docs/11_archive/`, `docs/retro/`, and other audit/plan surfaces outside the main source-of-truth set.
- Keep these docs for reasoning history, but never let them pose as current release truth.
