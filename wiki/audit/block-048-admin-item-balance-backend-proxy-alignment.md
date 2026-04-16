---
title: Block 048 — admin item balance backend proxy alignment
category: audit
tags: [audit, admin, item-balance, backend-proxy, validation, simulation]
sources:
  - admin/src/lib/backend-api.ts
  - admin/src/app/api/admin/item-balance/config/route.ts
  - admin/src/app/api/admin/item-balance/profiles/route.ts
  - admin/src/app/api/admin/item-balance/validate/route.ts
  - admin/src/app/api/admin/item-balance/suggest/route.ts
  - admin/src/app/api/admin/item-balance/apply-suggestions/route.ts
  - admin/src/app/api/admin/item-balance/simulate/combat/route.ts
  - admin/src/app/api/admin/item-balance/simulate/item-impact/route.ts
  - admin/src/app/api/admin/item-balance/simulate/matchups/route.ts
  - admin/src/app/(dashboard)/item-balance/config/config-editor-client.tsx
  - admin/src/app/(dashboard)/item-balance/profiles/profiles-client.tsx
  - admin/src/app/(dashboard)/item-balance/dashboard-client.tsx
  - admin/src/app/(dashboard)/item-balance/simulation/simulation-client.tsx
  - admin/src/app/(dashboard)/item-balance/validation/validation-client.tsx
  - admin/src/actions/item-balance.ts
updated: 2026-04-15
status: Fixed
---

# Block 048 — admin item balance backend proxy alignment

## Scope

- `admin/src/lib/backend-api.ts`
- `admin/src/app/api/admin/item-balance/config/route.ts`
- `admin/src/app/api/admin/item-balance/profiles/route.ts`
- `admin/src/app/api/admin/item-balance/validate/route.ts`
- `admin/src/app/api/admin/item-balance/suggest/route.ts`
- `admin/src/app/api/admin/item-balance/apply-suggestions/route.ts`
- `admin/src/app/api/admin/item-balance/simulate/combat/route.ts`
- `admin/src/app/api/admin/item-balance/simulate/item-impact/route.ts`
- `admin/src/app/api/admin/item-balance/simulate/matchups/route.ts`
- `admin/src/app/(dashboard)/item-balance/config/config-editor-client.tsx`
- `admin/src/app/(dashboard)/item-balance/profiles/profiles-client.tsx`
- `admin/src/app/(dashboard)/item-balance/dashboard-client.tsx`
- `admin/src/app/(dashboard)/item-balance/simulation/simulation-client.tsx`
- `admin/src/app/(dashboard)/item-balance/validation/validation-client.tsx`
- `admin/src/actions/item-balance.ts`

## Why this block

This pass started as a follow-up to the backend `item-balance` fixes, but it exposed a bigger operational drift:

1. the admin item-balance UI was not consistently talking to the canonical backend admin routes;
2. validation and simulation endpoints in the admin app were running their own duplicate math/runtime instead of the backend source of truth.

That meant the tuning tool itself could say an item was fine or broken based on formulas that production did not actually use.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[bug-patterns]]
- [[design-principles]]
- [[balance-audit-findings]]

## File notes

### `admin/src/lib/backend-api.ts`

- **Zone:** admin / backend integration
- **Purpose:** forwards authenticated admin requests from the admin app to canonical backend admin routes
- **Depends on:** admin cookie auth, backend API base URL, `admin-token`
- **What was fixed:** added a shared proxy helper that forwards the same bearer token backend admin auth expects
- **Status:** Fixed

### `admin/src/app/api/admin/item-balance/*`

- **Zone:** admin / item-balance API surface
- **Purpose:** powers validation, suggestions, simulations, config saves, and profile saves for the item-balance dashboard
- **Problems found:** these routes were split between duplicate local math and direct DB writes, drifting away from backend runtime behavior
- **What was fixed:** all live item-balance admin routes now proxy to the canonical backend admin endpoints instead of maintaining a second runtime
- **Status:** Fixed

### `admin/src/app/(dashboard)/item-balance/config/config-editor-client.tsx`

- **Zone:** admin / item-balance config UI
- **Purpose:** edits `item_balance.*` config values
- **Problems found:**
  - writes went through local server actions instead of the backend route that owns cache invalidation
  - error handling only surfaced a generic local message
- **What was fixed:** saves now go through the admin proxy route backed by backend canonical logic, and backend error messages are surfaced cleanly
- **Status:** Fixed

### `admin/src/app/(dashboard)/item-balance/profiles/profiles-client.tsx`

- **Zone:** admin / item-balance profile UI
- **Purpose:** edits per-item-type stat-weight and power-weight profiles
- **Problems found:**
  - writes bypassed backend cache invalidation
  - failures could be swallowed silently
- **What was fixed:** profile saves now go through the canonical backend route via the admin proxy and show actionable error text on failure
- **Status:** Fixed

### `admin/src/app/(dashboard)/item-balance/dashboard-client.tsx`, `simulation-client.tsx`, `validation-client.tsx`

- **Zone:** admin / item-balance UI
- **Purpose:** dashboard, simulation, and validation shells
- **Problems found:** stale `adminId` props and small dead locals survived after earlier routing changes
- **What was fixed:** removed dead props/locals so warning noise stops hiding real admin-panel issues
- **Status:** Fixed

### `admin/src/actions/item-balance.ts`

- **Zone:** admin / server actions
- **Purpose:** loads item-balance summary, configs, profiles, and simulation history
- **Problems found:** it still contained mutation actions after the UI had been moved off them
- **What was fixed:** removed dead mutation actions and left only the read-side actions that are still actually used by the pages
- **Status:** Fixed

### `admin/src/lib/item-validator.ts` and `admin/src/lib/combat-sim.ts`

- **Zone:** admin / legacy duplicate runtime
- **Purpose:** previously duplicated validation and combat simulation logic inside the admin app
- **Problems found:** these files had drifted badly from backend contracts and no longer had live callers after the proxy cutover
- **What was fixed:** both duplicate runtimes were removed from the live admin path and deleted as dead code
- **Status:** Deprecated

## Problems found

1. **Admin validation/simulation was running on a second, divergent runtime**
   - Risk: balance decisions could be made from numbers that did not match live gameplay math or config semantics.
   - Fix: moved the live admin API surface to backend proxies.

2. **Primary config/profile saves bypassed backend cache ownership**
   - Risk: admin users could save a change and still observe stale backend behavior immediately afterward.
   - Fix: routed config/profile mutations through backend canonical endpoints.

3. **Dead duplicate runtimes were still present in the repo**
   - Risk: future edits could accidentally revive the wrong implementation.
   - Fix: removed the dead duplicate validator/simulator files after the proxy migration.

## Verification

- targeted admin `eslint` on touched item-balance routes, clients, pages, helper, and action file
- `npx next build` in `admin/`
- `rg -n "updateBalanceConfig\\(|updateBalanceProfile\\(" admin/src -g '*.ts' -g '*.tsx'` to confirm the dead mutation path no longer has live callers
- `git diff --check`

## Follow-up

- the remaining read-side actions in `admin/src/actions/item-balance.ts` still query Prisma directly; that is acceptable for summary/list screens, but if we ever need strict backend-shape parity for those read surfaces too, the same proxy pattern should be considered
- this block removed the live callers from the duplicate admin runtime, but any future reintroduction of local `item-validator` or `combat-sim` logic in the admin app should be treated as architecture drift by default
