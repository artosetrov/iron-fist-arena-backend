---
title: Block 124 — W1-W3 plan docs historical boundaries
category: audit
tags: [audit, docs, ui, ux, roadmap, historical-boundary]
sources:
  - docs/07_ui_ux/W1_CHECKPOINT.md
  - docs/07_ui_ux/W1_D3_GAMECONFIG_SSOT_REVIEW.md
  - docs/07_ui_ux/W1_D4_BALANCE_DOCS_AUTOGEN.md
  - docs/07_ui_ux/W1_D5_DRIFT_GUARD.md
  - docs/07_ui_ux/W2_D1_REALITY_CHECK.md
  - docs/07_ui_ux/W2_D1_REVIEW.md
  - docs/07_ui_ux/W2_D2_LORE_AUDIT.md
  - docs/07_ui_ux/W2_D2_REALITY_CHECK.md
  - docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md
  - docs/07_ui_ux/W2_D4_BUILDING_GATING_DESIGN.md
  - docs/07_ui_ux/W2_D5_BADGE_PRIORITY_DESIGN.md
  - docs/07_ui_ux/W3_D1_REVIEW.md
  - docs/07_ui_ux/W3_D5_REVIEW_PLAN.md
updated: 2026-04-16
status: Fixed
---

# Block 124 — W1-W3 plan docs historical boundaries

## Scope

- `docs/07_ui_ux/W1_CHECKPOINT.md`
- `docs/07_ui_ux/W1_D3_GAMECONFIG_SSOT_REVIEW.md`
- `docs/07_ui_ux/W1_D4_BALANCE_DOCS_AUTOGEN.md`
- `docs/07_ui_ux/W1_D5_DRIFT_GUARD.md`
- `docs/07_ui_ux/W2_D1_REALITY_CHECK.md`
- `docs/07_ui_ux/W2_D1_REVIEW.md`
- `docs/07_ui_ux/W2_D2_LORE_AUDIT.md`
- `docs/07_ui_ux/W2_D2_REALITY_CHECK.md`
- `docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md`
- `docs/07_ui_ux/W2_D4_BUILDING_GATING_DESIGN.md`
- `docs/07_ui_ux/W2_D5_BADGE_PRIORITY_DESIGN.md`
- `docs/07_ui_ux/W3_D1_REVIEW.md`
- `docs/07_ui_ux/W3_D5_REVIEW_PLAN.md`

## Why this block

The `W1/W2/W3` docs are not junk. They capture valuable reasoning: why tasks were closed, what was already built, where architecture had drifted from plan, and how specific implementation slices were framed at the time.

The problem was that many of them still presented themselves as live checkpoints, active approval queues, or current roadmap slices. After the much larger audit pass, that is too ambiguous.

## Related pages

- [[block-123-ui-review-and-plan-docs-historical-boundaries]]
- [[block-045-backend-tutorial-achievement-and-weekly-contracts]]
- [[block-073-tutorial-scripted-fight-contract-and-victory-parity]]
- [[rebalance-w3d3]]

## File notes

### `docs/07_ui_ux/W1_CHECKPOINT.md`

- **Zone:** dated checkpoint report
- **Purpose:** records what W1 believed complete and ready for manual QA
- **Problem found:** sounded too close to a current readiness verdict
- **Fix:** added an explicit historical checkpoint boundary
- **Status:** Fixed

### `docs/07_ui_ux/W1_D3_GAMECONFIG_SSOT_REVIEW.md`

- **Zone:** pre-code review artifact
- **Purpose:** captures reasoning for the W1.D3 GameConfig rollout
- **Problem found:** still read like an active approval queue
- **Fix:** added a historical review boundary
- **Status:** Fixed

### `docs/07_ui_ux/W1_D4_BALANCE_DOCS_AUTOGEN.md`

- **Zone:** completion report
- **Purpose:** records the first balance-doc autogen rollout
- **Problem found:** completion language could be mistaken for current tooling truth
- **Fix:** added a historical completion boundary
- **Status:** Fixed

### `docs/07_ui_ux/W1_D5_DRIFT_GUARD.md`

- **Zone:** completion report
- **Purpose:** records the first iOS/backend drift-guard rollout
- **Problem found:** could be read as the current guard/CI state without rechecking live scripts
- **Fix:** added a historical completion boundary
- **Status:** Fixed

### `docs/07_ui_ux/W2_D1_REALITY_CHECK.md`

- **Zone:** plan-correction note
- **Purpose:** explains why one onboarding task was closed without code
- **Problem found:** lacked an explicit “historical closure evidence” framing
- **Fix:** added a historical reality-check boundary
- **Status:** Fixed

### `docs/07_ui_ux/W2_D1_REVIEW.md`

- **Zone:** pre-implementation recon
- **Purpose:** records the W2 onboarding decision space
- **Problem found:** still read like an active approval gate
- **Fix:** added a historical review boundary
- **Status:** Fixed

### `docs/07_ui_ux/W2_D2_LORE_AUDIT.md`

- **Zone:** audit/decision memo
- **Purpose:** reviews lore intro placement and rewrite scope
- **Problem found:** could be mistaken for the current onboarding narrative contract
- **Fix:** added a historical audit boundary
- **Status:** Fixed

### `docs/07_ui_ux/W2_D2_REALITY_CHECK.md`

- **Zone:** plan-correction memo
- **Purpose:** captures a cinematic architecture mismatch discovered during review
- **Problem found:** lacked a clear historical-planning boundary
- **Fix:** added an explicit plan-correction snapshot note
- **Status:** Fixed

### `docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md`

- **Zone:** design doc
- **Purpose:** proposes the scripted tutorial fight before implementation
- **Problem found:** still read like the active source of truth despite later shipped tutorial/runtime work
- **Fix:** added a historical design boundary and pointed readers back to live tutorial truth
- **Status:** Fixed

### `docs/07_ui_ux/W2_D4_BUILDING_GATING_DESIGN.md`

- **Zone:** design doc
- **Purpose:** proposes a building-unlock schedule iteration
- **Problem found:** unlock schedule ideas could be mistaken for current shipped gating rules
- **Fix:** added a historical design boundary
- **Status:** Fixed

### `docs/07_ui_ux/W2_D5_BADGE_PRIORITY_DESIGN.md`

- **Zone:** design doc
- **Purpose:** proposes hub badge priority tiers
- **Problem found:** proposal could be confused with the current hub badge policy
- **Fix:** added a historical proposal boundary
- **Status:** Fixed

### `docs/07_ui_ux/W3_D1_REVIEW.md`

- **Zone:** balance recon review
- **Purpose:** captures the W3 balance sprint decision space
- **Problem found:** could be mistaken for the current balance roadmap
- **Fix:** added a historical recon boundary
- **Status:** Fixed

### `docs/07_ui_ux/W3_D5_REVIEW_PLAN.md`

- **Zone:** review-before-code plan
- **Purpose:** late-sprint scope proposal for ELO / BP / IAP work
- **Problem found:** still read like an active implementation plan
- **Fix:** added a dated planning boundary
- **Status:** Fixed

## Problems found

1. **Dated sprint artifacts still looked live**
   - Risk: later work can accidentally treat old sprint framing as the current plan.
   - Fix: added explicit historical/review/proposal boundaries at the top of each file.

2. **Approval-state wording had gone stale**
   - Risk: “awaiting approval” language survives long after the repo moved on.
   - Fix: preserved the historical status while clarifying that it belongs to the original planning moment.

3. **Historical reasoning was not clearly separated from live feature truth**
   - Risk: readers skip the current wiki/code and re-open old design assumptions.
   - Fix: reframed these docs as evidence/rationale and pointed attention back to current audited surfaces.

## Verification

- inspected the opening metadata/context of all 13 docs
- confirmed each now carries an explicit historical or proposal boundary
- `git diff --check`

## Follow-up

- Continue the same cleanup through the remaining dated `docs/07_ui_ux/` artifacts that still sound like current roadmap material.
- Keep the historical review trail; just do not let it outrank the live feature maps and current code.
