---
title: Block 063 — admin feature flags operator feedback hardening
category: audit
tags: [audit, admin, feature-flags, operator-ui, feedback, async-state]
sources:
  - admin/src/app/(dashboard)/flags/flags-client.tsx
updated: 2026-04-15
status: Fixed
---

# Block 063 — admin feature flags operator feedback hardening

## Scope

- `admin/src/app/(dashboard)/flags/flags-client.tsx`

## Why this block

After the broader admin async-state cleanup, the feature-flag editor was still carrying a smaller but important operator-facing debt:

- save/delete errors still went through `alert(...)`
- toggle failures fell into `console.error(...)`
- row toggles had no explicit pending state

That is not just style debt. Feature flags are one of the sharpest tools in the admin surface. If something fails there, the operator needs immediate in-UI feedback and an obvious sense of what is still running.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-054-admin-settings-role-guards-and-feature-flag-contracts]]
- [[block-062-admin-players-items-async-state-hardening]]

## File notes

### `admin/src/app/(dashboard)/flags/flags-client.tsx`

- **Zone:** admin / feature flags
- **Purpose:** create, edit, seed, toggle, and delete runtime flags
- **Problems found:**
  - save and delete failures still used blocking `alert(...)`
  - toggle failures were only logged to console
  - no dedicated row-pending state existed for toggle operations
  - feedback paths were inconsistent across save, seed, toggle, and delete
- **What was fixed:**
  - replaced `alert(...)` and console-only failure paths with inline error messaging
  - added positive success feedback for save, toggle, delete, and seed actions
  - introduced `togglingFlagId` so the row being flipped shows an `Updating...` state
  - split delete state from save state so destructive dialogs no longer borrow unrelated pending flags
- **Status:** Fixed

## Problems found

1. **Feature-flag failures were not surfaced consistently**
   - Risk: operators could miss failed mutations on one of the most sensitive live-control screens.
   - Fix: unified errors into on-screen feedback instead of `alert` and `console.error`.

2. **Toggle operations had no row-scoped pending model**
   - Risk: an operator could click the same flag repeatedly without a clear in-flight indicator.
   - Fix: added `togglingFlagId` and per-row pending copy.

3. **Delete and save shared one ambiguous pending path**
   - Risk: dialog state could feel misleading during destructive operations.
   - Fix: split delete state from save state.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/flags/flags-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- the remaining admin cleanup is now less about missing feedback on core liveops screens and more about finishing consistency across a smaller set of older shells
- `tables` and a few `item-balance` screens still deserve a final consistency pass, but the higher-risk mutation surfaces are now in much better shape
