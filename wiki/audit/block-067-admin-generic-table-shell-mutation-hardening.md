---
title: Block 067 — admin generic table shell mutation hardening
category: audit
tags: [audit, admin, tables, generic-shell, mutations, async-state]
sources:
  - admin/src/app/(dashboard)/tables/[tableName]/table-client.tsx
  - admin/src/components/data-table/data-table.tsx
  - admin/src/components/forms/dynamic-form.tsx
updated: 2026-04-15
status: Fixed
---

# Block 067 — admin generic table shell mutation hardening

## Scope

- `admin/src/app/(dashboard)/tables/[tableName]/table-client.tsx`
- `admin/src/components/data-table/data-table.tsx`
- `admin/src/components/forms/dynamic-form.tsx`

## Why this block

By this point most concrete admin editors had already been cleaned up, but the generic CRUD table shell still sat underneath a whole class of fallback admin surfaces.

That makes it important even if it is only one “shell” file: if its mutation lifecycle is sloppy, every table-backed admin screen inherits the same weakness.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-032-backend-api-tests-nextrequest-helper]]
- [[block-065-admin-snapshots-and-item-balance-editor-async-state-hardening]]
- [[bug-patterns]]

## File notes

### `admin/src/app/(dashboard)/tables/[tableName]/table-client.tsx`

- **Zone:** admin / generic CRUD shell
- **Purpose:** provide search, pagination, sort, create, edit, and delete UI for arbitrary tables
- **Problems found:**
  - mutation handlers cleared `isMutating` only on the happy path
  - if `createRecord`, `updateRecord`, or `deleteRecord` threw instead of returning `{ error }`, the screen could get stuck in a permanent loading state
  - one `useTransition` state name was blending navigation-pending and mutation-pending concepts
- **What was fixed:**
  - wrapped create/update/delete in `try/catch/finally`
  - guaranteed `isMutating` reset even on thrown failures
  - kept `useTransition` only for navigation/refresh and renamed it conceptually to `isNavigating/startNavigation`
  - limited table dimming to navigation state, while mutation dialogs remain driven by `isMutating`
- **Status:** Fixed

### `admin/src/components/data-table/data-table.tsx`

- **Zone:** admin / shared table view
- **Purpose:** reusable table rendering, search, sort, pagination, and delete-confirm shell
- **What was checked:**
  - delete intent is still staged locally before bubbling to the parent shell
  - sort/search interactions are purely UI events and do not own async mutation state
- **Status:** OK

### `admin/src/components/forms/dynamic-form.tsx`

- **Zone:** admin / shared CRUD form
- **Purpose:** generic form builder for table-backed create/edit dialogs
- **What was checked:**
  - loading state is delegated in through `isLoading`
  - form submission still cleans and normalizes values consistently by column type
- **Status:** OK

## Problems found

1. **Generic CRUD shell could leave admin dialogs stuck in loading state after thrown errors**
   - Risk: one unexpected thrown error from a server action could lock the generic create/edit/delete shell for the rest of that interaction.
   - Fix: wrapped all mutation handlers in `try/catch/finally` so `isMutating` always resets.

2. **Navigation pending and mutation pending were mixed together conceptually**
   - Risk: it was harder to reason about whether the UI was refreshing table data or actively mutating a record.
   - Fix: kept transition state only for routing/refresh and separated it from mutation state.

3. **Fallback admin screens inherited shell-level async ambiguity**
   - Risk: even if custom editors were cleaned up, generic table-backed pages could still behave inconsistently.
   - Fix: hardened the generic shell itself.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/tables/[tableName]/table-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`
- `rg -n "isPending|startTransition\\(|useTransition"` on the table shell after the change to confirm remaining transition usage is navigation-only

## Follow-up

- after this block, the remaining admin work is much less about broad async-state cleanup and much more about small residual surfaces and product/docs consistency
- `flags` and `item-balance/dashboard` still use transition-wrapped refresh helpers, but those are now narrow navigation refresh cases rather than misleading mutation-state shells
