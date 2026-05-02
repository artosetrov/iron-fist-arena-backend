---
title: Audit Block 301 — Talents v2 Polish Tail Boundary Sync
category: audit
tags: [audit, combat, talents, ios, docs]
sources:
  - Hexbound/Hexbound/Models/CombatLogEvent.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift
  - wiki/features/interactive-combat.md
  - wiki/features/passive-tree.md
  - docs/06_game_systems/SKILL_TREE_DESIGN_V2.md
  - wiki/audit/block-262-talents-v2-ult-action-types-and-class-trees.md
  - wiki/audit/block-288-pre-release-audit-bounded-todo-followup.md
updated: 2026-05-01
status: Fixed
---

# Audit Block 301 — Talents v2 Polish Tail Boundary Sync

## Scope

This block aligns the live Talents v2 feature maps and active design reference
with the exact remaining follow-up still visible in code.

## Why this block

The repo already had the real implementation truth:

- `stealth`, `aoe_damage`, `cooldown_reset`, and `aoe_stun` are shipped
- the strike resolver and iOS exhaustive switches already support them
- the remaining TODOs are bounded presentation follow-ups in:
  - `CombatLogEvent.swift`
  - `InteractiveBattleViewModel.swift`

But that remaining tail was still described more explicitly in older audit/docs
than in the current live feature maps, which made the source-of-truth layer a
little too quiet about what is actually left.

## Changes shipped

- Updated `wiki/features/interactive-combat.md` so it now states the precise
  bounded polish tail: the four Talents v2 ult action types are live, while
  dedicated Vanish / Cataclysm / Rewind / Quake VFX/SFX remain unshipped.
- Updated `wiki/features/passive-tree.md` so the passive-tree map no longer
  stops at the slot/runtime contract and now also records the same
  presentation-only follow-up.
- Updated `docs/06_game_systems/SKILL_TREE_DESIGN_V2.md` so the active design
  reference keeps the same runtime-vs-polish boundary near the top of the
  document instead of leaving that nuance buried only in older audit notes.

## Result

The repo now tells one consistent truth about Talents v2:

- gameplay/runtime support for the four new ult action types is shipped
- the remaining tail is bounded to dedicated combat presentation assets
- the open follow-up is polish, not a missing combat contract or missing
  resolver behavior
