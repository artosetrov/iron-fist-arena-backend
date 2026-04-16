---
title: Block 052 — admin balance schema parity and auth hardening
category: audit
tags: [audit, admin, balance, config, auth, live-config]
sources:
  - admin/src/actions/config.ts
  - admin/src/actions/balance.ts
  - admin/src/app/(dashboard)/balance/balance-client.tsx
  - admin/src/app/(dashboard)/balance/page.tsx
updated: 2026-04-15
status: Fixed
---

# Block 052 — admin balance schema parity and auth hardening

## Scope

- `admin/src/actions/config.ts`
- `admin/src/actions/balance.ts`
- `admin/src/app/(dashboard)/balance/balance-client.tsx`
- `admin/src/app/(dashboard)/balance/page.tsx`

## Why this block

Once the active editors were cleaned up, the next drift was more structural:

1. `getConfig()` was the odd one out among admin read helpers and skipped the admin auth guard entirely;
2. the curated `Balance` screen claimed to manage all balance parameters, but it omitted several live categories that were already seeded into `GameConfig`;
3. a few displayed defaults in `BalanceClient` had drifted away from the canonical seed values, which meant reset buttons and “customized” badges could lie to the team;
4. the array config `stamina_refill_dr.cost_multipliers` had no dedicated admin editor even though it was a live economy control.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[economy]]
- [[pvp-rating]]
- [[stamina]]
- [[bug-patterns]]

## File notes

### `admin/src/actions/config.ts`

- **Zone:** admin / config actions
- **Purpose:** shared read/write helpers for generic `GameConfig` screens
- **Problems found:**
  - `getConfig()` skipped the admin auth guard used by neighboring read helpers
  - `updateConfig()` still exposed a dead optional `adminId` parameter after the write path moved server-side
- **What was fixed:** added the missing auth check to `getConfig()` and removed the dead `adminId` argument from `updateConfig()`
- **Status:** Fixed

### `admin/src/actions/balance.ts`

- **Zone:** admin / balance actions
- **Purpose:** read the curated balance slice shown in the balance dashboard
- **Problems found:** the category allowlist omitted several live balance surfaces already seeded into `GameConfig`
- **What was fixed:** expanded the read allowlist to include `loss_streak`, `pvp_ranks`, `training_xp_dr`, `stamina_refill_dr`, `charisma`, and `repair`
- **Status:** Fixed

### `admin/src/app/(dashboard)/balance/balance-client.tsx`

- **Zone:** admin / balance editor UI
- **Purpose:** curated editor for high-frequency gameplay tuning
- **Problems found:**
  - stale hardcoded defaults for combat crit tuning and win-streak bonuses
  - no UI for several live balance categories already present in the seed config
  - no editor for `stamina_refill_dr.cost_multipliers`
  - summary/copy overstated the screen as “all balance parameters” even though specialized potion config lives elsewhere
- **What was fixed:**
  - corrected hardcoded defaults to the current seeded values
  - added sections for PvP ranks, training XP DR, stamina refill DR, loss-streak recovery, charisma gold-cap, and repair costs
  - added a dedicated editor for refill cost multipliers
  - updated summary text so the page is honest about adjacent specialized config surfaces
- **Status:** Fixed

### `admin/src/app/(dashboard)/balance/page.tsx`

- **Zone:** admin / balance page shell
- **Purpose:** server-side entrypoint for the curated balance editor
- **Problems found:** the page copy overpromised full balance coverage
- **What was fixed:** rewrote the page description to distinguish curated balance surfaces from the specialized Consumables screen and raw Live Config
- **Status:** Fixed

## Problems found

1. **Balance reset/default UI had drifted from canonical seeded values**
   - Risk: admins could “reset to default” and silently land on the wrong value, or see a correct live value incorrectly marked as customized.
   - Fix: synced the hardcoded defaults in `BalanceClient` with the canonical seeded config.

2. **Several live balance categories were missing from the curated balance screen**
   - Risk: important economy and ladder knobs existed in runtime but were effectively hidden from the main tuning UI.
   - Fix: expanded both the read-side category allowlist and the editor schema to cover those live categories.

3. **`stamina_refill_dr.cost_multipliers` had no purpose-built editor**
   - Risk: one of the main gem-sink guardrails could only be changed through raw config editing.
   - Fix: added a dedicated array editor alongside the other special balance arrays.

4. **`getConfig()` skipped auth**
   - Risk: this helper was easier to reuse incorrectly than the rest of the admin read layer.
   - Fix: aligned it with the same admin auth boundary as the neighboring config read helpers.

## Verification

- targeted admin `eslint`:
  - `src/actions/config.ts`
  - `src/actions/balance.ts`
  - `src/app/(dashboard)/balance/balance-client.tsx`
  - `src/app/(dashboard)/balance/page.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- the curated `Balance` screen is now aligned with the seeded live config it claims to represent, but specialized potion pricing/effect knobs intentionally remain on `Consumables`
- `snapshots` and a few other admin read-side surfaces still query Prisma directly; that is acceptable for now, but they remain the next likely consistency pass
