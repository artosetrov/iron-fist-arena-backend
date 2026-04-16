---
title: Block 099 — iOS editor layout save typed contracts
category: audit
tags: [audit, ios, admin-tools, editor, contracts]
sources:
  - Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift
  - Hexbound/Hexbound/Views/Dungeon/DungeonMapEditorView.swift
  - Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift
  - admin/src/app/api/admin/dungeon-map-layout/route.ts
  - admin/src/app/api/admin/hub-layout/route.ts
updated: 2026-04-16
status: Fixed
---

# Block 099 — iOS editor layout save typed contracts

## Scope

- `Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift`
- `Hexbound/Hexbound/Views/Dungeon/DungeonMapEditorView.swift`
- `Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift`
- adjacent admin layout save routes

## Why this block

Once the Gold Mine action layer was typed, the last obvious editor-shell `postRaw(...)` save paths were the debug/admin layout tools for the hub and dungeon map. They are not player-facing runtime, but they were still live project code and worth bringing in line.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-060-admin-dungeon-map-and-editor-runtime-cleanup]]

## File notes

### `Hexbound/Hexbound/Views/Dungeon/DungeonMapEditorView.swift`

- **Zone:** iOS / debug editor / dungeon map
- **Purpose:** saves admin-authored node positions to the backend
- **Problems found:**
  - save path still posted a raw dictionary
- **What was fixed:**
  - switched save flow to typed `AdminLayoutSaveRequest/Response`
  - kept the existing local-cache-first behavior unchanged
- **Status:** Fixed

### `Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift`

- **Zone:** iOS / debug editor / hub layout
- **Purpose:** saves hub building positions and sizes to the backend
- **What else it owns now:**
  - co-located `AdminLayoutSnapshot`
  - co-located `AdminLayoutSaveRequest`
  - co-located `AdminLayoutSaveResponse`
- **Problems found:**
  - save path still used raw mutation transport
- **What was fixed:**
  - switched save flow to typed `AdminLayoutSaveRequest/Response`
  - preserved local cache updates and fallback toast behavior
- **Status:** Fixed

## Problems found

1. **Editor save routes still used raw transport**
   - Risk: small but unnecessary drift between runtime services and debug/editor tools.
   - Fix: introduced a typed layout-save DTO surface and co-located it with surviving editor code so the Xcode target did not depend on a separate unregistered file.

2. **The last editor-shell raw save paths were easy to forget**
   - Risk: they could silently diverge because they were outside the main product flow.
   - Fix: aligned them with the same typed `APIClient.post(...)` pattern used elsewhere.

## Verification

- `git diff --check -- Hexbound/Hexbound/Views/Dungeon/DungeonMapEditorView.swift Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `rg -n 'postRaw\\(|getRaw\\(|patchRaw\\(' Hexbound/Hexbound/Views/Dungeon/DungeonMapEditorView.swift Hexbound/Hexbound/Views/Hub/HubEditorDetailView.swift`

## Follow-up

- After this block, residual raw transport in `Hexbound` is no longer sitting in editor save paths.
- The remaining non-infrastructure tails are internal cache/error bridges, not live editor transport.
