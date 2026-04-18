---
title: Audit Block 153 — iOS Talent Detail Sheet Slot-Aware Picker Unification
category: audit
tags: [audit, ios, talents, passive-tree, active-slots, ux]
sources:
  - Hexbound/Hexbound/Views/Hero/Talents/TalentsTabView.swift
  - Hexbound/Hexbound/Views/Hero/Talents/TalentDetailSheet.swift
  - Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift
  - Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift
  - Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerRow.swift
updated: 2026-04-17
---

# Audit Block 153 — iOS Talent Detail Sheet Slot-Aware Picker Unification

## Scope

This block closes the last live UX tail left open in [[block-022-ios-active-skill-picker-passive-tree-contracts]]. The main problem was no longer data-contract drift, but ownership drift: the talent detail sheet still had a direct equip CTA while the picker had become the real loadout editor.

- **Files audited in this block:** 5
- **Primary file types:** SwiftUI views and view-model flow
- **Status:** detail-sheet equip now stays deterministic when a free slot exists and routes into the slot-aware picker when the loadout is full; the picker itself now lets the player choose the replacement slot directly
- **Related pages:** [[block-022-ios-active-skill-picker-passive-tree-contracts]], [[passive-tree]], [[interactive-combat]], [[audit-index]], [[project-file-inventory]]

## Summary

- `TalentsTabView` no longer calls the old generic `equipActive(node:)` path from the detail sheet.
- `PassiveTreeViewModel` now owns the detail-sheet equip decision through `beginEquipActive(node:)`: direct equip when a free slot exists, picker handoff when the loadout is full.
- `ActiveSkillPickerSheet` no longer depends on a one-shot external focus only. The player can now tap a slot in the preview strip to target it for replacement, and tap the focused slot again to clear it.
- `ActiveSkillPickerRow` copy now matches the real behavior: when the loadout is full, the UI tells the player to choose a slot, not to unequip blindly.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Detail-sheet equip still used the legacy direct equip path. | Full loadouts degraded into an info-toast dead end instead of offering a real replacement flow. | `TalentsTabView` now routes the CTA through `PassiveTreeViewModel.beginEquipActive(node:)`. |
| P1 | The picker could honor a focused slot only when it was opened with one already chosen. | Opening the picker from the detail sheet while full still left the player without a replacement target. | `ActiveSkillPickerSheet` now maintains local slot focus and lets the player choose the replacement slot directly from the preview strip. |
| P2 | Row copy still implied "unequip first" even though replacement is now slot-aware. | UI wording lagged behind the fixed behavior and could push players toward the wrong mental model. | `ActiveSkillPickerRow` now shows `CHOOSE SLOT` with an accessibility label that matches the slot-selection flow. |

## Cross-File Safe Fixes Applied

- `PassiveTreeViewModel.beginEquipActive(node:)` now handles the detail-sheet CTA as a product-level entry point instead of letting the view own replacement semantics.
- `TalentsTabView` closes the detail sheet and either equips into a free slot or opens the picker for slot-aware replacement.
- `ActiveSkillPickerSheet` now:
  - seeds local focus from the original slot hint or first free slot;
  - keeps focus locally while editing;
  - lets the player tap filled slots to focus them for replacement;
  - lets the player tap the focused slot again to clear it;
  - shows a replacement hint when all slots are filled and no target is selected.
- `ActiveSkillPickerRow` copy now reflects the new replacement contract.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `Hexbound/Hexbound/Views/Hero/Talents/TalentsTabView.swift` | iOS passive-tree container | Hosts the tree canvas, detail sheet, picker, and sticky confirm flow. | Used by hero detail UI; depends on `PassiveTreeViewModel`. | Detail-sheet actions should delegate mutation ownership instead of inventing slot rules locally. | Detail-sheet equip now routes through `beginEquipActive(node:)` instead of the old generic direct equip call. | Fixed |
| `Hexbound/Hexbound/Views/Hero/Talents/TalentDetailSheet.swift` | iOS node detail modal | Presents node details plus unlock / equip / unequip CTAs. | Used by `TalentsTabView`. | It may keep an equip CTA, but slot choice must live elsewhere. | No structural code change needed here; its equip CTA now lands on a unified slot-aware path through the view model. | OK |
| `Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift` | iOS passive-tree orchestration | Owns tree state, unlock staging, active-slot state, and picker orchestration. | Used by talent UI and picker. | View model should decide whether equip is deterministic or requires editor handoff. | Added `beginEquipActive(node:)` to unify the detail-sheet equip path and route full loadouts into the picker instead of a dead end. | Fixed |
| `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift` | iOS loadout editor | Atomic editor for active talent / potion loadouts. | Used by `TalentsTabView`; depends on `PassiveTreeViewModel`. | Player should be able to choose which slot to replace inside the picker itself. | Added local slot focus, replacement hinting, preview-strip targeting, and clean focus reset on dismiss/reset. | Fixed |
| `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerRow.swift` | iOS picker row | Presentational row for active talents and consumables. | Used by `ActiveSkillPickerSheet`. | UI labels should match the real editor semantics. | Reworded the full-loadout chip from `SLOTS FULL` to `CHOOSE SLOT` and updated accessibility text. | Fixed |

## Remaining Risk

- The detail sheet still exposes an equip CTA, so the picker is not the *only* surface players can start from. That is now an acceptable UX split because the slot-selection logic is centralized and deterministic again.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- `git diff --check` passes after the talent-flow and wiki updates.
