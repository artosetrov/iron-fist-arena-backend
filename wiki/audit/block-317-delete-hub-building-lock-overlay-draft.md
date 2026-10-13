---
title: Audit Block 317 — Delete Hub BuildingLockOverlay Draft
category: audit
tags: [audit, ios, hub, cleanup]
sources:
  - Hexbound/Hexbound/Views/Hub/BuildingLockOverlay.swift
  - Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift
  - Hexbound/Hexbound.xcodeproj/project.pbxproj
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-05-06
status: Fixed
---

# Audit Block 317 — Delete Hub BuildingLockOverlay Draft

## Scope

This block removes one more dead Swift draft from the working tree: an empty
`Views/Hub/BuildingLockOverlay.swift` file that no longer served any live code,
docs, or project-file purpose.

## Why this block

The repo already had one real canonical implementation:

- `Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift`

The extra `Views/Hub/BuildingLockOverlay.swift` file was only:

- an empty draft note
- absent from the current `project.pbxproj` runtime path
- unreferenced by checked-in docs or code outside the inventory itself

Keeping it around next to the live component made the tree noisier and made the
basename look more ambiguous than it actually is.

## Changes shipped

- Deleted `Hexbound/Hexbound/Views/Hub/BuildingLockOverlay.swift` from the
  working tree.
- Kept the canonical checked-in component at
  `Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift` untouched.
- Rolled the inventory forward so the removed draft is now recorded as deleted
  in the working tree and block `317` is listed in the audit trail.

## Result

The Hub/Components split no longer carries two `BuildingLockOverlay.swift`
basenames in the working tree. The live source of truth is now cleaner and more
obvious: only the reusable Components implementation remains as active code.
