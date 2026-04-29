---
title: Audit Block 260 — Combat Feature-Map Memory Boundary Sync
category: audit
tags: [audit, wiki, combat, pvp, interactive-combat, docs]
sources:
  - wiki/features/interactive-combat.md
  - wiki/features/pvp-combat.md
  - docs/features/combat/INTERACTIVE_COMBAT_PLAN.md
  - wiki/features/combat-unification-remaining.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 260 — Combat Feature-Map Memory Boundary Sync

## Scope

- `wiki/features/interactive-combat.md`
- `wiki/features/pvp-combat.md`

## Why this block

The combat feature maps still depended on memory-note references for rollout
history and migration context:

- interactive-combat phase notes
- PvP interactive rollout notes
- a few implementation incidents that were already understandable from the
  checked-in repo without pointing outside it

That made the feature-map layer weaker than it needed to be: the current repo
already has checked-in plan/deferred-work docs for this corridor.

## Fix applied

- replaced the memory-note docs section in `interactive-combat.md` with:
  - `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`
  - `wiki/features/combat-unification-remaining.md`
- did the same in `pvp-combat.md`
- rewrote the remaining memory-backed gotchas in `pvp-combat.md` and
  `interactive-combat.md` into plain checked-in runtime truth:
  - UUID ids must decode as strings
  - widened matchmaking is the current live search model
  - `/pvp/fight` fallback still exists as a compatibility path
  - migration-before-deploy is the same manual-first schema rule already
    learned elsewhere in the repo

## Result

The combat feature maps now stand on checked-in repo sources instead of
external memory notes. Rollout history and deferred work are still visible, but
they are anchored in files that actually ship with the project.

## Verification

- repo search confirmed the removed memory-note references
- checked-in replacements exist in `docs/features/combat/` and `wiki/features/`
- `git diff --check`
