---
title: Audit Block 313 — Active-Slot Shell and Passive-Tree Surface Parity
category: audit
tags: [audit, ios, combat, passive-tree, retro]
sources:
  - Hexbound/Hexbound/Views/Components/ActiveSlotTile.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift
  - docs/retro/RETRO_2026-05-05.md
  - wiki/features/interactive-combat.md
  - wiki/features/passive-tree.md
  - wiki/systems/passive-tree.md
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-05-06
status: Fixed
---

# Audit Block 313 — Active-Slot Shell and Passive-Tree Surface Parity

## Scope

This block closes the next live terminology seam in the Active Slot wave:

- `ActiveSlotTile.swift` and `InteractiveBattleView.swift` still used older
  `stub` / `placeholder` language for the 4th combat tile
- the fresh 2026-05-05 retro repeated that wording
- passive-tree / interactive-combat wiki pages did not yet spell out that the
  Talents tab premium 4th slot and the combat HUD's locked consumable shell are
  two different runtime surfaces
- `wiki/features/passive-tree.md` still pointed at the orphaned
  `ActiveSlotsBar.swift` file instead of the live `TalentsSummaryCard` +
  `ActiveSlotTile` path

## Why this block

The live runtime model is already cleaner than the wording suggested:

- **Talents tab:** base 3 active-talent slots + optional premium 4th slot
- **Combat predict HUD:** 3 active-talent buttons + a separate locked
  consumable shell tile that reserves space for a future consumable-in-combat
  path

Both surfaces intentionally reuse `ActiveSlotTile` chrome, but they are not the
same gameplay capability. Leaving the older `stub` wording in place made that
distinction harder to read.

## Changes shipped

- Rewrote the top comment and convenience-init comment in
  `ActiveSlotTile.swift` so the combat use case is now described as a locked
  consumable shell instead of a `stub`.
- Rewrote the adjacent comments in `InteractiveBattleView.swift` to the same
  bounded model and made the distinction from the Talents premium slot explicit.
- Updated `RETRO_2026-05-05.md` so its Active Slot unification notes now use
  the same locked-consumable-shell language.
- Updated `wiki/features/interactive-combat.md` with a dedicated gotcha about
  the combat HUD's 4th tile.
- Updated `wiki/features/passive-tree.md` and `wiki/systems/passive-tree.md`
  so they now:
  - point at the live `TalentsSummaryCard.swift` / `ActiveSlotTile.swift`
    surface instead of the orphaned `ActiveSlotsBar.swift`
  - explicitly separate the Talents premium 4th slot from the combat HUD's
    locked consumable shell
- Rolled the inventory forward again so it includes block `313` and the latest
  tracked/untracked totals.

## Result

The Active Slot layer now speaks with one voice across code comments, retro
notes, feature maps, and systems docs: the premium 4th talent slot and the
combat HUD's locked consumable shell share UI chrome, but they are not the same
runtime feature.
