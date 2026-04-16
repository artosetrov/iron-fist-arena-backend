---
title: Block 065 — admin snapshots and item-balance editor async-state hardening
category: audit
tags: [audit, admin, snapshots, item-balance, async-state, liveops]
sources:
  - admin/src/app/(dashboard)/snapshots/snapshots-client.tsx
  - admin/src/app/(dashboard)/item-balance/config/config-editor-client.tsx
  - admin/src/app/(dashboard)/item-balance/profiles/profiles-client.tsx
updated: 2026-04-15
status: Fixed
---

# Block 065 — admin snapshots and item-balance editor async-state hardening

## Scope

- `admin/src/app/(dashboard)/snapshots/snapshots-client.tsx`
- `admin/src/app/(dashboard)/item-balance/config/config-editor-client.tsx`
- `admin/src/app/(dashboard)/item-balance/profiles/profiles-client.tsx`

## Why this block

The previous admin async-state cleanup had already covered most live mutation surfaces, but a smaller cluster still remained in tooling that operators use for rollback and balance tuning:

- `snapshots` still used one generic transition state for create, rollback, and delete
- `item-balance` editors still mixed explicit save state with transition-driven refresh state

That meant the screens could still lie about what was actually running. On rollback and live item-balance edits, that is exactly the kind of ambiguity we want to remove.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-053-admin-snapshots-restore-runtime-hardening]]
- [[block-048-admin-item-balance-backend-proxy-alignment]]
- [[block-064-admin-config-and-balance-editor-async-state-hardening]]

## File notes

### `admin/src/app/(dashboard)/snapshots/snapshots-client.tsx`

- **Zone:** admin / snapshots
- **Purpose:** create config backups, rollback to a snapshot, and delete old snapshots
- **Problems found:**
  - one generic pending flag was shared by create, rollback, and delete
  - row dialogs could not tell the operator which snapshot action was actually running
- **What was fixed:**
  - replaced transition-based flow with explicit `isCreating`, `rollingBackId`, and `deletingId`
  - create/rollback/delete buttons now show state for the actual operation in flight
  - destructive dialogs now disable conflicting actions without freezing the whole screen ambiguously
- **Status:** Fixed

### `admin/src/app/(dashboard)/item-balance/config/config-editor-client.tsx`

- **Zone:** admin / item balance / config
- **Purpose:** edit live item-balance configuration keys
- **Problems found:**
  - save flow mixed explicit `savingKey` with transition-driven refresh
  - the save button still depended on a generic pending model
- **What was fixed:**
  - removed `useTransition`
  - kept the screen on explicit `savingKey`
  - save buttons now reflect real per-key save lifecycle and refresh afterward
- **Status:** Fixed

### `admin/src/app/(dashboard)/item-balance/profiles/profiles-client.tsx`

- **Zone:** admin / item balance / profiles
- **Purpose:** edit stat-weight and power-weight profiles per item type
- **Problems found:**
  - save flow still borrowed transition semantics even though the screen already had `savingId`
  - cancel/save controls mixed row-local state with a generic pending state
- **What was fixed:**
  - removed `useTransition`
  - kept save lifecycle on explicit `savingId`
  - made row controls depend on actual save state rather than an unrelated global pending flag
- **Status:** Fixed

## Problems found

1. **Rollback tooling still had ambiguous loading semantics**
   - Risk: an operator could not reliably tell whether the screen was creating a backup, rolling back a specific snapshot, or deleting one.
   - Fix: introduced dedicated state for each mutation path and tied button copy/disabled state to that exact operation.

2. **Item-balance editors still mixed explicit save state with transition refresh state**
   - Risk: the editor could look idle or globally blocked for the wrong reason during live balance changes.
   - Fix: removed `useTransition` and leaned fully on per-row save identifiers already present in the UI.

3. **Older admin tooling still borrowed one generic pending flag too broadly**
   - Risk: destructive and non-destructive actions could visually interfere with each other.
   - Fix: split state by operation so the screen communicates what is actually happening.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/snapshots/snapshots-client.tsx`
  - `src/app/(dashboard)/item-balance/config/config-editor-client.tsx`
  - `src/app/(dashboard)/item-balance/profiles/profiles-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`
- `rg -n "startTransition\\(async|isPending|useTransition"` on the touched files

## Follow-up

- the next obvious async-state cleanup is now concentrated in `skills`, `passives`, and `tables`
- rollback/config tooling is now much more honest about what is actually running, which is exactly what we want from admin-only operational surfaces
