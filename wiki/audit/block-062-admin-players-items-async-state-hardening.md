---
title: Block 062 — admin players and items async-state hardening
category: audit
tags: [audit, admin, players, items, async-state, operator-ui]
sources:
  - admin/src/app/(dashboard)/players/players-client.tsx
  - admin/src/app/(dashboard)/players/[id]/player-client.tsx
  - admin/src/app/(dashboard)/items/items-client.tsx
  - admin/src/app/(dashboard)/items/_components/item-editor-client.tsx
updated: 2026-04-15
status: Fixed
---

# Block 062 — admin players and items async-state hardening

## Scope

- `admin/src/app/(dashboard)/players/players-client.tsx`
- `admin/src/app/(dashboard)/players/[id]/player-client.tsx`
- `admin/src/app/(dashboard)/items/items-client.tsx`
- `admin/src/app/(dashboard)/items/_components/item-editor-client.tsx`

## Why this block

After the last admin live-editor pass, the same false-loading pattern was still sitting in two operator-critical areas:

1. player moderation and account interventions
2. item catalog management and item media upload

These surfaces are higher-risk than cosmetic settings screens because they drive bans, grants, inventory resets, item saves, and catalog deletes. If the UI lies about whether the request is still running, operators can easily repeat actions or misread the result.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-061-admin-live-editors-async-state-hardening]]
- [[bug-patterns]]

## File notes

### `admin/src/app/(dashboard)/players/players-client.tsx`

- **Zone:** admin / player search and moderation list
- **Purpose:** search players, paginate results, and ban/unban accounts
- **Problems found:**
  - search and moderation mutations both depended on `useTransition(async ...)`
  - there was no explicit error surface for failed search or failed ban/unban requests
- **What was fixed:**
  - replaced transition-based pseudo-loading with explicit `isSearching` and `isMutating`
  - added a visible error banner for failed list actions
  - made dialog buttons and pagination controls reflect the real request lifecycle
- **Status:** Fixed

### `admin/src/app/(dashboard)/players/[id]/player-client.tsx`

- **Zone:** admin / player detail
- **Purpose:** inspect a user account and run high-impact actions like grants, ban/unban, and inventory reset
- **Problems found:**
  - all destructive actions shared one false transition state
  - the UI could show the wrong button state while account mutations were still running
- **What was fixed:**
  - replaced transition usage with a real `activeAction` state
  - wired per-action button labels like `Granting...`, `Banning...`, `Resetting...`
  - kept existing success/error banners but aligned them with real request completion
- **Status:** Fixed

### `admin/src/app/(dashboard)/items/items-client.tsx`

- **Zone:** admin / item catalog list
- **Purpose:** browse items, preview them, and delete catalog rows
- **Problems found:**
  - delete dialog relied on transition-driven loading instead of the real fetch lifecycle
- **What was fixed:**
  - replaced it with explicit `isDeleting`
  - tied delete dialog controls and labels to the actual request state
- **Status:** Fixed

### `admin/src/app/(dashboard)/items/_components/item-editor-client.tsx`

- **Zone:** admin / item editor
- **Purpose:** edit item stats/effects/economy/media and upload catalog art
- **Problems found:**
  - both image upload and item save used `useTransition(async ...)`
  - upload controls could stay interactive even while save/upload was in flight
- **What was fixed:**
  - replaced transition usage with explicit `isUploading` and `isSaving`
  - disabled conflicting image/save controls while a request is active
  - kept success/error feedback, but now it maps to the real request lifecycle
- **Status:** Fixed

## Problems found

1. **Moderation and grant actions still had false loading semantics**
   - Risk: operators could repeat player-affecting actions because the UI stopped looking busy too early.
   - Fix: replaced transition-driven pseudo-loading with explicit action states.

2. **Item upload and save were not isolated as separate operations**
   - Risk: operators could click around during upload/save overlap and end up with misleading feedback or partially stale UI state.
   - Fix: split upload/save state and disabled conflicting controls during in-flight operations.

3. **Player search had no visible failure surface**
   - Risk: a failed moderation list refresh could look like “nothing happened” rather than an actual error.
   - Fix: added explicit error rendering on the list screen.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/players/players-client.tsx`
  - `src/app/(dashboard)/players/[id]/player-client.tsx`
  - `src/app/(dashboard)/items/items-client.tsx`
  - `src/app/(dashboard)/items/_components/item-editor-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`
- `rg -n "useTransition\\(|startTransition\\(async|isPending"` confirms the old async-state pattern is gone from this slice

## Follow-up

- the remaining admin async-state debt is now narrower and more predictable
- the next logical follow-up is the remaining older operator shells like `flags`, `item-balance`, `tables`, and any other screens that still mix transition-only routing state with real mutations
