---
title: Block 061 — admin live editors async-state hardening
category: audit
tags: [audit, admin, async-state, seasons, events, assets, dungeons]
sources:
  - admin/src/app/(dashboard)/seasons/seasons-client.tsx
  - admin/src/app/(dashboard)/events/events-client.tsx
  - admin/src/app/(dashboard)/assets/assets-client.tsx
  - admin/src/app/(dashboard)/dungeons/dungeons-client.tsx
updated: 2026-04-15
status: Fixed
---

# Block 061 — admin live editors async-state hardening

## Scope

- `admin/src/app/(dashboard)/seasons/seasons-client.tsx`
- `admin/src/app/(dashboard)/events/events-client.tsx`
- `admin/src/app/(dashboard)/assets/assets-client.tsx`
- `admin/src/app/(dashboard)/dungeons/dungeons-client.tsx`

## Why this block

After the dungeon editor pass, the next admin hotspot was not one specific domain. It was one repeated UI bug pattern across several live editors: `useTransition(async ...)` was being used like a truthful network loading state.

That pattern is especially risky in admin tooling because these are destructive or high-impact actions: create, update, delete, upload, and toggle. If the UI says an action is “done” before the actual request finishes, operators can double-submit, dismiss dialogs too early, or get misleading feedback during slower requests.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-060-admin-dungeon-map-and-editor-runtime-cleanup]]
- [[bug-patterns]]

## File notes

### `admin/src/app/(dashboard)/seasons/seasons-client.tsx`

- **Zone:** admin / season management
- **Purpose:** create, edit, and delete PvP seasons
- **Problems found:**
  - reused one transition state for both save and delete flows
  - relied on `useTransition(async ...)` even though the async request lifecycle is longer than the transition boundary
- **What was fixed:**
  - replaced transition usage with explicit `isSaving` and `isDeleting`
  - tied dialog buttons and labels to the real request lifecycle
- **Status:** Fixed

### `admin/src/app/(dashboard)/events/events-client.tsx`

- **Zone:** admin / live events
- **Purpose:** create, edit, delete, and activate/deactivate timed events
- **Problems found:**
  - save and delete dialogs used the same false transition loading pattern
  - event activation toggle had no dedicated in-flight state and no explicit error feedback path
- **What was fixed:**
  - added real `isSaving` and `isDeleting`
  - added `togglingEventId` so only the affected event row is locked during activation changes
  - surfaced toggle failures through the existing error banner instead of failing silently
- **Status:** Fixed

### `admin/src/app/(dashboard)/assets/assets-client.tsx`

- **Zone:** admin / asset browser
- **Purpose:** browse storage buckets, upload files, delete files, and inspect public URLs
- **Problems found:**
  - mixed load/upload/delete/get-url operations under transition-driven pseudo-loading
  - asset list refresh after upload/delete was not tied cleanly to the actual operation lifecycle
  - destructive actions could remain clickable while another storage operation was still running
- **What was fixed:**
  - introduced explicit `isLoading`, `isUploading`, `isResolvingUrl`, and `isDeleting`
  - made upload/delete await the follow-up `loadFiles()` refresh
  - disabled conflicting controls while an asset operation is in flight
- **Status:** Fixed

### `admin/src/app/(dashboard)/dungeons/dungeons-client.tsx`

- **Zone:** admin / dungeon index
- **Purpose:** list dungeons, create a new dungeon shell, and delete existing dungeons
- **Problems found:**
  - create and delete flows both relied on the same false transition loading state
  - the primary CTA could visually clear “Creating...” before the create request had actually finished
- **What was fixed:**
  - replaced transition state with explicit `isCreating` and `isDeleting`
  - wired labels and destructive dialog controls to the actual request lifecycle
- **Status:** Fixed

## Problems found

1. **Several admin mutation screens still had false loading semantics**
   - Risk: operators could retry, navigate away, or dismiss dialogs while requests were still active.
   - Fix: replaced transition-based pseudo-loading with explicit awaited state in each screen.

2. **Event activation had no per-row pending model**
   - Risk: one slow toggle could make the whole screen feel inconsistent while still not clearly identifying which event was being updated.
   - Fix: added `togglingEventId` and explicit toggle error handling.

3. **Asset operations were not coordinated as one live surface**
   - Risk: upload, refresh, delete, and URL lookup could overlap in ways that produced stale or misleading UI state.
   - Fix: separated operation states and disabled conflicting controls while storage operations are in flight.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/seasons/seasons-client.tsx`
  - `src/app/(dashboard)/events/events-client.tsx`
  - `src/app/(dashboard)/assets/assets-client.tsx`
  - `src/app/(dashboard)/dungeons/dungeons-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`
- `rg -n "useTransition\\(|startTransition\\(async|isPending"` confirms the old transition-driven loading path is gone from this block

## Follow-up

- the same audit pattern still appears in other admin screens, especially around players, tables, items, and a few remaining config editors
- after this block, the remaining admin debt is narrower: less about core mutation truthfulness, more about finishing the same cleanup pattern consistently across the rest of the operator UI
