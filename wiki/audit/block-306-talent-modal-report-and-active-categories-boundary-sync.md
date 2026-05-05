---
title: Audit Block 306 — Talent-Modal Report and Active-Categories Boundary Sync
category: audit
tags: [audit, talents, combat, qa, docs]
sources:
  - qa-reports/2026-05-01_talent_modal_redesign.md
  - docs/features/combat/ACTIVE_CATEGORIES_V1.md
  - Hexbound/Hexbound/Views/Hero/Talents/TalentDetailSheet.swift
  - Hexbound/Hexbound/Views/Hero/Talents/TalentsTabView.swift
  - Hexbound/Hexbound/Views/Combat/ActiveSkillsHUD.swift
  - backend/prisma/migrations/20260501_passive_node_flavor/migration.sql
  - wiki/features/interactive-combat.md
updated: 2026-05-04
status: Fixed
---

# Audit Block 306 — Talent-Modal Report and Active-Categories Boundary Sync

## Scope

This block cleans the next historical combat/talents seam: a fresh redesign
report that had already slipped back into external `feedback_*` shorthand, and
an older active-categories proposal that still read like a pending live combat
contract.

## Why this block

Two adjacent docs had drifted in different ways:

1. `qa-reports/2026-05-01_talent_modal_redesign.md` was useful, but it had
   started leaning on external feedback-note names to explain migration order,
   motion rules, Figma sync, and deploy flow even though the repo now has
   checked-in runtime files, a checked-in migration, and a checked-in retro for
   the eventual shipped outcome.
2. `docs/features/combat/ACTIVE_CATEGORIES_V1.md` still opened as a proposal
   "awaiting approval" even though the live `ActiveFireStyle` surface later
   shipped its own checked-in label vocabulary and then expanded again for the
   Talents v2 ult action types.

## Changes shipped

- Rewrote the talent-modal redesign report so it now points to checked-in repo
  truth instead of external `feedback_*` note names.
- Added an explicit historical boundary to the same report, with current truth
  handed back to:
  - `TalentDetailSheet.swift`
  - `TalentsTabView.swift`
  - `PassiveTree.swift`
  - `20260501_passive_node_flavor/migration.sql`
  - `RETRO_2026-05-04.md`
- Reframed `ACTIVE_CATEGORIES_V1.md` as a historical proposal snapshot rather
  than a live runtime contract.
- Made the current runtime authority explicit there too:
  - `Hexbound/Hexbound/Views/Combat/ActiveSkillsHUD.swift`
  - `wiki/features/interactive-combat.md`
- Preserved the useful design reasoning in both files while removing the parts
  that falsely implied a still-pending approval or depended on off-repo memory.

## Result

The new talent-modal redesign report now stands on checked-in repo truth, and
the older active-categories writeup reads as design history rather than a live
combat contract. That keeps the combat/talents documentation layer supportive
without letting it drift back into external memory shorthand or stale approval
language.
