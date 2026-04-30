---
title: Audit Block 263 — Combat Historical Doc Memory Boundary Sync
category: audit
tags: [audit, docs, combat, ui-ux, source-of-truth]
sources:
  - docs/07_ui_ux/COMBAT_UX_REFACTOR_3_STATE.md
  - docs/07_ui_ux/COMBAT_UX_INTEGRATION_PLAN.md
  - docs/features/combat/COMBAT_V3_IMPLEMENTATION_PLAN.md
  - docs/features/combat/COMBAT_UX_IMPLEMENTATION_PLAN.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 263 — Combat Historical Doc Memory Boundary Sync

## Scope

This block cleans the remaining external memory-note dependency from the
checked-in combat UX planning docs.

## Why this block

The combat feature maps were already moved off external memory notes in
`block-260`, but the historical implementation plans still depended on
references like `feedback_no_scale_animations`,
`feedback_pbxproj_unique_ids`, `project_pvp_fight_routing_shipped`, and
other off-repo notes to explain their rules.

That made the docs harder to trust in isolation and quietly reintroduced the
same "repo truth vs memory truth" split we had just removed from the feature
maps.

## Changes shipped

### `docs/07_ui_ux/COMBAT_UX_REFACTOR_3_STATE.md`

- Replaced the top-level external-note references with checked-in runtime context:
  `wiki/features/interactive-combat.md` and
  `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`.
- Converted the pbxproj rule into plain repo-owned wording: unique random hex
  IDs, no external note required.
- Rewrote the caller-scan reminder as a generic repo-wide grep rule.
- Rewrote the animation rule as direct guidance: opacity/position only, no
  scale transforms.

### `docs/07_ui_ux/COMBAT_UX_INTEGRATION_PLAN.md`

- Removed memory-note wording from the design-approval guard, pbxproj rule,
  no-scale rule, reusability rule, English-only copy rule, and caller-scan
  reminder.
- Replaced the environment-specific `.git-trigger` instruction with a clean
  handoff to the repo's current `docs/10_operations/` workflow.
- Rephrased the feature-flag location note so it points at the checked-in
  app/config pattern instead of an external rollout memory note.

### `docs/features/combat/COMBAT_V3_IMPLEMENTATION_PLAN.md`

- Removed memory-note wording from the animation rules and the force-quit
  edge-case note.
- Replaced the old sandbox-specific commit instruction with generic "publish
  through the repo's current git workflow" wording.
- Rephrased the pbxproj note so it stands on the repo's own guidance.

### `docs/features/combat/COMBAT_UX_IMPLEMENTATION_PLAN.md`

- Removed memory-note wording from the pbxproj guidance and the reduced-motion
  / no-scale reminder.
- Rewrote the Figma drift row so it describes the actual sync expectation
  without depending on an external feedback note name.

## Result

The remaining historical combat UX plans are now self-contained checked-in
documents again. They still preserve the design and rollout logic, but they no
longer require external memory-note context to explain animation policy,
pbxproj hygiene, caller verification, or git/publish workflow boundaries.
