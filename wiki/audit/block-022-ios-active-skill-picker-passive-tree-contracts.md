---
title: Audit Block 022 — iOS Active Skill Picker and Passive Tree Contracts
category: audit
tags: [audit, ios, passive-tree, active-slots, talents, contracts]
sources:
  - Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerRow.swift
  - Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift
  - Hexbound/Hexbound/Views/Hero/Talents/ActiveSlotsBar.swift
  - Hexbound/Hexbound/Views/Hero/Talents/TalentsTabView.swift
  - Hexbound/Hexbound/Views/Hero/Talents/TalentDetailSheet.swift
  - Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift
  - Hexbound/Hexbound/Services/PassiveTreeService.swift
  - Hexbound/Hexbound/Models/PassiveTree.swift
  - backend/src/app/api/passives/active-slots/route.ts
  - backend/src/app/api/passives/active-slots/batch/route.ts
updated: 2026-04-15
---

# Audit Block 022 — iOS Active Skill Picker and Passive Tree Contracts

## Scope

This block continues the passive-tree and interactive-combat cleanup from [[block-011-backend-passives-interactive-combat-runtime]]. The backend active-slot contract was already mostly solid, but the iOS editor flow still had two important mismatches:

1. the picker had a `focusedSlotIndex` concept, but replacement behavior still mostly acted like "find first free slot";
2. the detail sheet could call `equipActive(node:)` directly, which meant a full loadout could silently mutate the wrong slot.

- **Files audited in this block:** 10
- **Primary file types:** Swift UI, Swift view model/service/model files, backend route contracts
- **Status:** Picker replacement semantics now honor the tapped slot, direct full-loadout equip no longer silently overwrites slot 0, and `PassiveTreeService` now uses typed contracts for unlock/respec/equip/save flows
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[passive-tree]], [[bug-patterns]], [[block-011-backend-passives-interactive-combat-runtime]]

## Summary

- `ActiveSlotsBar` already pushed users toward the picker as the main editor, but the actual picker logic still preferred "first free slot" unless the slot happened to be empty. That made slot-focused replacement unreliable.
- `TalentsTabView` and `TalentDetailSheet` still exposed a direct equip path. When all slots were full, that path could silently replace slot 0 instead of asking which slot should change.
- `PassiveTreeService` had partially migrated to typed `APIClient` calls, but active-slot mutations still used raw dictionaries and `saveLoadout` still carried a `JSONSerialization` workaround that the backend no longer needed.
- Two active picker UI files are compiled product code but still remain untracked in git after the file-graph reshuffle. That is not a runtime bug, but it is a repository hygiene risk and should stay visible.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Picker replacement still mostly used "first free slot" semantics. | Tapping a filled slot could replace the wrong slot or make the editor feel nondeterministic. | `ActiveSkillPickerSheet` now treats the focused slot as the explicit replacement target and visually highlights it in the preview strip. |
| P1 | Direct equip from talent details could silently overwrite slot 0 when the loadout was full. | Player loses the wrong active skill without being asked which slot to replace. | `PassiveTreeViewModel.equipActive(node:)` now refuses the mutation in that case and shows an informational toast instead of mutating the loadout. |
| P2 | `PassiveTreeService` still mixed typed DTOs with raw request bodies. | Higher contract-drift risk, weaker compile-time coverage, and more fragile snake_case/null handling. | Converted unlock/respec plus active-slot equip/save flows onto typed `Encodable` / `Decodable` contracts. |
| P2 | Picker "room available" checks treated replacement and insertion as the same thing. | Full loadout incorrectly disabled valid replacements and made the focused-slot UX inconsistent. | `hasRoomForTalent()` / `hasRoomForConsumable()` now allow replacement mode when a focused slot exists. |

## Cross-File Safe Fixes Applied

- `ActiveSkillPickerSheet` now uses the focused slot as the preferred insert target, highlights it in the preview strip, and replaces the occupant of that exact slot when equipping a talent or potion.
- `PassiveTreeViewModel` now exposes `firstFreeActiveSlotIndex()` and blocks silent fallback replacement when the detail sheet tries to equip into a full loadout without an explicit slot target.
- `PassiveTreeService` now uses typed bodies for unlock, respec, single-slot equip, and batch save. The old `NSNull`/raw JSON workaround is gone.
- The active-slot contract remains mirrored from backend rules: max 3 slots, at most 1 potion, activatable/unlocked/class-valid talents only, and atomic batch save for the full loadout.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerRow.swift` | iOS talent-loadout picker row | Presentational row for activatable talents and eligible potions. | Used by `ActiveSkillPickerSheet`; depends on `PassiveNode`, `ConsumableMeta`, theme tokens. | Row should reflect whether the item is already equipped, buyable, or can replace a focused slot. | Re-audited against the new replacement semantics; row logic is now consistent with focused-slot `hasRoom` decisions. | OK |
| `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift` | iOS active-loadout editor | Main editor for the 3-slot active loadout and inline potion buys. | Used by `TalentsTabView`; depends on `PassiveTreeViewModel`, `ShopService`, `AppState`. | Picker is the safest place to edit the whole loadout because backend prefers atomic batch save. | Fixed slot-focused replacement, preview highlighting, and replacement-aware room checks. | Fixed |
| `Hexbound/Hexbound/Views/Hero/Talents/ActiveSlotsBar.swift` | iOS active-slot entry surface | Shows current 3-slot loadout above the tree and opens the picker. | Used by `TalentsTabView`; depends on `PassiveTreeViewModel`. | Slot taps should route into the picker instead of doing hidden mutations inline. | Re-audited; current "open picker for any tap" behavior matches the single-editor direction. | OK |
| `Hexbound/Hexbound/Views/Hero/Talents/TalentsTabView.swift` | iOS passive-tree screen container | Hosts the passive tree, active slots bar, detail sheet, picker sheet, and respec flow. | Used by hero detail UI; depends on `PassiveTreeViewModel` and talent subviews. | Should keep unlock staging and active-slot editing coherent across multiple sheets. | Still routes detail-sheet equip directly to `vm.equipActive(node:)`, so full-loadout editing degrades to an info toast instead of opening slot selection. | Needs review |
| `Hexbound/Hexbound/Views/Hero/Talents/TalentDetailSheet.swift` | iOS node detail modal | Shows node details plus unlock / equip / unequip actions. | Used by `TalentsTabView`. Depends on `PassiveNode` and view-model callbacks. | For activatable nodes, equip semantics should stay aligned with picker semantics. | No runtime bug remains after the view-model guard, but the sheet still represents a second edit path with less context than the picker. | Needs review |
| `Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift` | iOS passive-tree orchestration | Coordinates tree loading, unlock staging, active-slot state, picker state, and commit flows. | Used by `TalentsTabView`, picker, active slots bar, detail sheet. Depends on `PassiveTreeService`. | View model owns mutation guards and should prevent accidental slot replacement. | Added first-free-slot helper and blocked silent slot-0 replacement when no explicit target exists. | Fixed |
| `Hexbound/Hexbound/Services/PassiveTreeService.swift` | iOS passive-tree API client | Loads tree/character/active-slot data and performs unlock/respec/loadout mutations. | Used by `PassiveTreeViewModel`; depends on `APIClient`. | Should consume backend contracts in a typed, snake_case-safe way. | Converted remaining mutation flows from raw dictionaries to typed request/response bodies. | Fixed |
| `Hexbound/Hexbound/Models/PassiveTree.swift` | iOS passive-tree contract models | Defines tree nodes, unlocked nodes, active-slot DTOs, and loadout entries. | Used by `PassiveTreeService`, `PassiveTreeViewModel`, and talent UI. | Must stay compatible with `convertFromSnakeCase` and older payloads that may omit active-slot fields. | Re-audited; current defaults and decoder notes still correctly document forward-compat behavior. | OK |
| `backend/src/app/api/passives/active-slots/route.ts` | Backend active-slot single-slot API | GET/POST/DELETE for active-slot CRUD and potion picker metadata. | Used by iOS passive-tree runtime. Depends on auth, Prisma, cache, game config. | Owns server validation for allowed consumables, unlocked activatable talents, class restriction, and slot bounds. | Re-audited as the contract source of truth; no safe code change needed in this block. | OK |
| `backend/src/app/api/passives/active-slots/batch/route.ts` | Backend atomic loadout save API | Saves the full 3-slot loadout in one transaction. | Used by `ActiveSkillPickerSheet` via `PassiveTreeService.saveLoadout`. | Requires exactly 3 entries, max 1 potion, unique node ids, and atomic rewrite semantics. | Re-audited to confirm typed omission of nil optionals is accepted; that let iOS drop the raw `NSNull` workaround safely. | OK |

## Duplicate / Split Logic Found

- Active-slot editing is still split between the picker and the talent detail sheet. The risk is much smaller now because the view model blocks silent replacement, but the UX is still not fully unified.
- Backend and iOS contract naming are in better shape here than in earlier reward/inventory areas. `PassiveTree.swift` already documents the `convertFromSnakeCase` rule clearly, and this block removes the last raw request bodies from the service layer.

## Files Without Clear Current Role

- None. Every file in this block sits on the current hero/talent runtime path.

## Repository Hygiene Risk

- `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerRow.swift`
- `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift`

Both files are active compiled product source but still untracked in git after the file-graph move. They have a clear runtime role, but fresh clones would miss them until the repository state is finalized.

## Candidates For Refactor

- Route all active-slot edits through the picker, even when starting from `TalentDetailSheet`, so slot choice always happens in one place.
- If the detail sheet keeps an equip CTA, pass an explicit slot target or open the picker pre-focused instead of using a generic "equip if possible" action.

## Documentation Missing Or Stale

- There is still no dedicated wiki page describing the intended UX contract for active-skill editing: whether the picker is the single editor, when the detail sheet may mutate slots directly, and how replacement should be explained to the player.

## Requires Separate Decision

- Should `TalentDetailSheet` keep direct equip / unequip controls, or should it always route into `ActiveSkillPickerSheet` for slot-aware editing?
- Should the current untracked picker source files be normalized as tracked product code now that the graph/file move has settled?

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- `rg -n "postRaw|getRaw|JSONSerialization|NSNull" Hexbound/Hexbound/Services/PassiveTreeService.swift` now returns no matches.
- `git diff --check` passes after the passive-tree and wiki updates.
