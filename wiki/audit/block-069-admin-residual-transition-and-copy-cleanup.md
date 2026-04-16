---
title: Block 069 — admin residual transition and copy cleanup
category: audit
tags: [audit, admin, flags, dashboards, copy, residual-debt]
sources:
  - admin/src/app/(dashboard)/flags/flags-client.tsx
  - admin/src/components/dashboard/player-charts.tsx
updated: 2026-04-15
status: Fixed
---

# Block 069 — admin residual transition and copy cleanup

## Scope

- `admin/src/app/(dashboard)/flags/flags-client.tsx`
- `admin/src/components/dashboard/player-charts.tsx`

## Why this block

By this point most of the admin mutation debt was already fixed. What remained here was much smaller, but still worth cleaning because it affected polish and operator trust:

- `flags` still carried an unnecessary transition wrapper around a plain `router.refresh()`
- `player-charts` still surfaced an internal `TODO` as visible product copy

Neither issue was catastrophic, but both made the admin surface feel a little less intentional than it should.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-054-admin-settings-role-guards-and-feature-flag-contracts]]
- [[block-063-admin-feature-flags-operator-feedback-hardening]]
- [[block-068-admin-achievements-and-item-balance-operator-feedback]]

## File notes

### `admin/src/app/(dashboard)/flags/flags-client.tsx`

- **Zone:** admin / feature flags
- **Purpose:** create, edit, toggle, seed, and delete runtime flags
- **Problems found:**
  - after the larger cleanup, the screen still kept a `useTransition` helper only to wrap `router.refresh()`
- **What was fixed:**
  - removed the unnecessary transition wrapper
  - kept refresh straightforward and synchronous with the already explicit save/toggle/delete/seed state
- **Status:** Fixed

### `admin/src/components/dashboard/player-charts.tsx`

- **Zone:** admin / dashboard / players
- **Purpose:** show registration and retention summaries
- **Problems found:**
  - user-visible retention card description still exposed an internal `TODO`
- **What was fixed:**
  - replaced the internal note with honest product-facing copy: retention becomes available once login event tracking is enabled
- **Status:** Fixed

## Problems found

1. **A tiny leftover transition helper remained after the broader cleanup**
   - Risk: small, but it kept the code less consistent than the surrounding screens.
   - Fix: removed the transition wrapper from the feature-flag screen refresh path.

2. **Internal engineering notes were leaking into operator-facing UI**
   - Risk: admin users saw implementation debt instead of product truth.
   - Fix: replaced `TODO` copy with clear, user-facing wording.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/flags/flags-client.tsx`
  - `src/components/dashboard/player-charts.tsx`
- `npx next build` in `admin/`
- `git diff --check`
- `rg -n "useTransition|startTransition\\(|TODO:"` on the touched files

## Follow-up

- after this block, the broad admin async-state/polish cleanup is essentially in residual mode
- what remains is now mostly localized technical debt, deliberate server-side logging, and broader whole-project file-by-file completion outside the just-cleaned admin surfaces
