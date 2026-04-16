---
title: Block 054 — admin settings role guards and feature-flag contracts
category: audit
tags: [audit, admin, settings, feature-flags, auth, contracts]
sources:
  - admin/src/app/api/settings/role/route.ts
  - admin/src/app/(dashboard)/settings/settings-client.tsx
  - admin/src/actions/feature-flags.ts
  - admin/src/lib/feature-flags.ts
  - admin/src/app/(dashboard)/flags/flags-client.tsx
  - admin/src/actions/dashboard.ts
  - admin/src/app/(dashboard)/dashboard-client.tsx
  - admin/src/app/(dashboard)/economy/economy-client.tsx
updated: 2026-04-15
status: Fixed
---

# Block 054 — admin settings role guards and feature-flag contracts

## Scope

- `admin/src/app/api/settings/role/route.ts`
- `admin/src/app/(dashboard)/settings/settings-client.tsx`
- `admin/src/actions/feature-flags.ts`
- `admin/src/lib/feature-flags.ts`
- `admin/src/app/(dashboard)/flags/flags-client.tsx`
- `admin/src/actions/dashboard.ts`
- `admin/src/app/(dashboard)/dashboard-client.tsx`
- `admin/src/app/(dashboard)/economy/economy-client.tsx`

## Why this block

The next admin slice looked like routine cleanup, but it hid two real integrity problems:

1. the role-change route in `settings` allowed direct API callers to self-demote or remove the last remaining admin;
2. the feature-flag editor and its server actions accepted weak `flagType`, `environment`, `targeting`, and JSON payload shapes, which meant the admin app could store values the backend runtime later ignored or interpreted inconsistently.

There was also smaller warning noise in the adjacent `dashboard` and `economy` clients that made the admin layer harder to read while chasing real issues.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[bug-patterns]]
- [[design-principles]]

## File notes

### `admin/src/app/api/settings/role/route.ts`

- **Zone:** admin / settings API
- **Purpose:** authenticated role mutation surface for admin users
- **Problems found:**
  - direct callers could demote themselves out of admin
  - direct callers could remove the last remaining admin
  - target-user existence and no-op paths were not handled explicitly
- **What was fixed:**
  - added schema validation for the request body
  - moved role change under a transaction
  - forbids self-demotion away from `admin`
  - locks current admin rows before demoting an admin and blocks last-admin removal
  - logs successful role changes in `admin_logs`
- **Status:** Fixed

### `admin/src/app/(dashboard)/settings/settings-client.tsx`

- **Zone:** admin / settings UI
- **Purpose:** admin settings dashboard for system info, config seeding, and role management
- **Problems found:** dead icon/separator imports and UI code riding on the weaker role-route contract
- **What was fixed:** removed dead imports and kept the client on the now-hardened route contract
- **Status:** Fixed

### `admin/src/lib/feature-flags.ts`

- **Zone:** admin / shared feature-flag contract helpers
- **Purpose:** one canonical parsing/normalization layer for feature-flag UI and server actions
- **What was added:**
  - shared `flagType`, `environment`, and targeting unions
  - canonical key normalization
  - JSON value validation
  - strict targeting/environment/type parsing
  - consistent form/display helpers
- **Status:** Fixed

### `admin/src/actions/feature-flags.ts`

- **Zone:** admin / feature-flag server actions
- **Purpose:** list, create, update, delete, toggle, and seed feature flags
- **Problems found:**
  - `flagType`, `environment`, `value`, `targeting`, and `tags` were accepted with weak `any`-style shape
  - invalid admin inputs could drift away from the runtime contract
  - nullable JSON writes were relying on looser typing than Prisma actually expects
- **What was fixed:**
  - replaced weak inputs with shared normalization helpers
  - constrained writes to canonical environments and supported flag types
  - validated targeting structure and JSON payloads before persistence
  - normalized nullable targeting writes through Prisma’s explicit nullable JSON path
- **Status:** Fixed

### `admin/src/app/(dashboard)/flags/flags-client.tsx`

- **Zone:** admin / feature-flag editor UI
- **Purpose:** browse and edit live feature flags
- **Problems found:**
  - local parsing duplicated server logic
  - form/edit flow relied on `any`
  - filter/edit UI omitted the legacy `segment` type supported by the stored schema
- **What was fixed:**
  - moved form parsing and display logic onto the shared helper contract
  - removed the weak `any` targeting/value handling
  - exposed `segment` explicitly as a targeted boolean flag type
- **Status:** Fixed

### `admin/src/actions/dashboard.ts`

- **Zone:** admin / dashboard data loader
- **Purpose:** aggregate KPIs and operational charts for the overview dashboard
- **Problems found:** stale unused dashboard type import
- **What was fixed:** removed dead `TimeSeriesPoint` import noise
- **Status:** Fixed

### `admin/src/app/(dashboard)/dashboard-client.tsx`

- **Zone:** admin / dashboard overview UI
- **Purpose:** render KPI, alert, economy, PvP, and player summary sections
- **Problems found:** dead icon imports that no longer matched the rendered quick-link/system-health surface
- **What was fixed:** removed the dead imports so the file reflects the actual visible surface
- **Status:** Fixed

### `admin/src/app/(dashboard)/economy/economy-client.tsx`

- **Zone:** admin / economy dashboard UI
- **Purpose:** render economy analytics and wealth distribution views
- **Problems found:** dead `useState` and icon imports
- **What was fixed:** removed the dead imports to reduce warning noise without changing behavior
- **Status:** Fixed

## Problems found

1. **Role change API could lock the team out of admin access**
   - Risk: a direct API call or future UI change could remove the last admin or self-demote the acting admin.
   - Fix: added request validation, transaction-backed role change, self-demotion guard, and last-admin lock protection.

2. **Feature-flag admin writes were wider than the runtime contract**
   - Risk: the admin app could persist invalid `environment`, `targeting`, or JSON shapes that the backend runtime later ignored or misread.
   - Fix: introduced one shared helper module used by both the UI and the server actions.

3. **Feature-flag parsing was duplicated across client and server**
   - Risk: the form could accept/edit a value differently from how the action actually stores it.
   - Fix: moved key parsing, targeting parsing, value parsing, and display formatting onto the shared helper contract.

4. **Admin read-heavy clients still carried warning noise**
   - Risk: dead imports make real behavior harder to audit and hide new problems in lint output.
   - Fix: removed the touched warning noise from `settings`, `dashboard`, and `economy`.

## Verification

- targeted admin `eslint`:
  - `src/lib/feature-flags.ts`
  - `src/actions/feature-flags.ts`
  - `src/app/api/settings/role/route.ts`
  - `src/app/(dashboard)/flags/flags-client.tsx`
  - `src/app/(dashboard)/settings/settings-client.tsx`
  - `src/actions/dashboard.ts`
  - `src/app/(dashboard)/dashboard-client.tsx`
  - `src/app/(dashboard)/economy/economy-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- `settings/page.tsx`, `flags/page.tsx`, and other admin read shells still hydrate directly from Prisma-backed admin actions; that is acceptable for now because the higher-risk mutation paths are now stricter
- the admin app still lacks a dedicated route/action test harness, so this block is verified through targeted lint plus full `next build`
- broader warning-heavy admin surfaces remain in `push`, `shop-offers`, `quests`, `battle-pass`, and a few design-system/demo files
