---
title: Audit Block 256 — Active Skill Picker Spec and Passive-Tree Slot Parity
category: audit
tags: [audit, docs, passive-tree, combat, historical-boundary]
sources:
  - docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md
  - wiki/features/passive-tree.md
  - Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift
  - Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift
  - Hexbound/Hexbound/Services/PassiveTreeService.swift
  - backend/src/app/api/passives/active-slots/route.ts
  - backend/src/app/api/passives/active-slots/batch/route.ts
  - backend/src/app/api/passives/active-slots/unlock-premium/route.ts
updated: 2026-04-29
status: Fixed
---

# Audit Block 256 — Active Skill Picker Spec and Passive-Tree Slot Parity

## Scope

- `docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md`
- `wiki/features/passive-tree.md`
- adjacent live picker/runtime files

## Why this block

The active-skill picker spec sat in an awkward middle state:

- it still read like a live delivery plan for a Phase 4 rollout
- but the shipped native picker already exists and has moved past parts of that
  framing
- the passive-tree feature map also still carried an old broad slot-count note
  that no longer matched the shipped base-3 + premium-fourth-slot model

That created two kinds of drift:

- implementation-plan text looking like current runtime authority
- feature-map wording that preserved an older “typical = 5 slots” idea after the
  shipped premium-slot path landed

## Fix applied

- reframed `ACTIVE_SKILL_PICKER_SPEC.md` as a **historical implementation
  snapshot**
- added a clear top-level handoff to the live source-of-truth files:
  - `ActiveSkillPickerSheet.swift`
  - `PassiveTreeViewModel.swift`
  - `PassiveTreeService.swift`
  - active-slots backend routes
  - `wiki/features/passive-tree.md`
- documented that the live picker now includes behavior beyond the original
  “3-slot Phase 4” framing, including slot-aware replacement, inline potion
  buy, and an optional premium fourth slot
- updated `wiki/features/passive-tree.md`:
  - added the picker spec as a historical-reference doc
  - replaced the stale “typical = 5 slots” gotcha with the live base-3 +
    premium-fourth-slot truth

## Result

The picker spec remains useful as rollout history and design rationale, but it
no longer masquerades as the current runtime contract. The passive-tree feature
map also now tells the truth about the shipped slot model.

## Verification

- live file review of:
  - `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift`
  - `Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift`
  - `Hexbound/Hexbound/Services/PassiveTreeService.swift`
  - `backend/src/app/api/passives/active-slots/route.ts`
  - `backend/src/app/api/passives/active-slots/batch/route.ts`
  - `backend/src/app/api/passives/active-slots/unlock-premium/route.ts`
- `git diff --check`
