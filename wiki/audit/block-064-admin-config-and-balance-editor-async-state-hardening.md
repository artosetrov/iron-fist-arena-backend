---
title: Block 064 — admin config and balance editor async-state hardening
category: audit
tags: [audit, admin, config, balance, consumables, loot, settings, async-state]
sources:
  - admin/src/app/(dashboard)/settings/settings-client.tsx
  - admin/src/app/(dashboard)/config/config-client.tsx
  - admin/src/app/(dashboard)/consumables/consumables-client.tsx
  - admin/src/app/(dashboard)/loot/loot-client.tsx
  - admin/src/app/(dashboard)/balance/balance-client.tsx
updated: 2026-04-15
status: Fixed
---

# Block 064 — admin config and balance editor async-state hardening

## Scope

- `admin/src/app/(dashboard)/settings/settings-client.tsx`
- `admin/src/app/(dashboard)/config/config-client.tsx`
- `admin/src/app/(dashboard)/consumables/consumables-client.tsx`
- `admin/src/app/(dashboard)/loot/loot-client.tsx`
- `admin/src/app/(dashboard)/balance/balance-client.tsx`

## Why this block

After the previous admin cleanup, the older config-oriented dashboards were still carrying the same operator-risk pattern:

- `useTransition(async ...)` was being used as if it tracked the real network lifecycle
- save and seed buttons could look idle while writes were still in flight
- row-level and bulk actions borrowed one generic pending flag

That is not harmless UI polish debt. These screens mutate live balance and config state. If their loading model lies, operators can double-submit, change multiple controls mid-save, or lose confidence in whether the live config actually updated.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-051-admin-active-config-editors-consistency]]
- [[block-052-admin-balance-schema-parity-and-auth-hardening]]
- [[block-063-admin-feature-flags-operator-feedback-hardening]]

## File notes

### `admin/src/app/(dashboard)/settings/settings-client.tsx`

- **Zone:** admin / settings / roles
- **Purpose:** seed default config and manage admin roles
- **Problems found:**
  - seed and role changes shared a false transition-based busy state
  - role updates had no row-scoped pending model
- **What was fixed:**
  - replaced transition-based flow with explicit `isSeeding`
  - added `updatingUserId` for row-scoped role updates
  - disabled the active select while its own update is in flight
- **Status:** Fixed

### `admin/src/app/(dashboard)/config/config-client.tsx`

- **Zone:** admin / generic config editor
- **Purpose:** edit arbitrary `GameConfig` keys by category
- **Problems found:**
  - seed and save actions used transition state instead of the real request lifecycle
  - operator feedback around seeding was not isolated from per-key saves
- **What was fixed:**
  - added explicit `savingKey` and `isSeeding`
  - each config row now reflects its actual save lifecycle
  - seed now waits for the real request before clearing UI state
- **Status:** Fixed

### `admin/src/app/(dashboard)/consumables/consumables-client.tsx`

- **Zone:** admin / consumable live config
- **Purpose:** edit fallback price and restore-value overrides for consumables
- **Problems found:**
  - the bulk save button used generic transition state instead of actual write completion
  - operators could get misleading feedback on whether the batch write finished
- **What was fixed:**
  - replaced transition usage with explicit `isSaving`
  - the bulk save button now stays busy until the batch update and refresh complete
- **Status:** Fixed

### `admin/src/app/(dashboard)/loot/loot-client.tsx`

- **Zone:** admin / loot tables
- **Purpose:** edit drop chances and rarity distribution
- **Problems found:**
  - drop and rarity saves shared one generic pending flag
  - section-level actions could not communicate which save was actually running
- **What was fixed:**
  - added `savingSection: 'drops' | 'rarities' | null`
  - each section now reports its own in-flight state and disables conflicting writes
- **Status:** Fixed

### `admin/src/app/(dashboard)/balance/balance-client.tsx`

- **Zone:** admin / curated balance editor
- **Purpose:** edit high-value live balance keys and grouped system parameters
- **Problems found:**
  - single-field save, seed, and save-all all leaned on false transition semantics
  - field buttons could not distinguish row save vs bulk save vs seed
  - operators could trigger overlapping writes on a live balance screen
- **What was fixed:**
  - added explicit `savingKey`, `isSavingAll`, and `isSeeding`
  - single-field buttons now show a row spinner only for the active key
  - bulk save and discard controls are disabled while any real save/seed is running
  - seed now reflects the real request lifecycle instead of optimistic transition timing
- **Status:** Fixed

## Problems found

1. **Live config editors were still pretending transition state was request state**
   - Risk: operators could double-submit writes or keep editing while a live balance/config mutation was still in flight.
   - Fix: replaced transition-based flows with explicit awaited state per action or per row.

2. **Bulk and row actions were sharing ambiguous pending models**
   - Risk: one save could block or visually mask another in a way that made the screen feel nondeterministic.
   - Fix: split busy state into `savingKey`, `savingSection`, `isSaving`, `isSavingAll`, `isSeeding`, and `updatingUserId` depending on the screen.

3. **Config authoring screens were not consistently truthful about completion**
   - Risk: liveops operators could think a config change was done before the authoritative refresh completed.
   - Fix: every touched save/seed path now waits for the real async write and refresh before clearing the busy state.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/settings/settings-client.tsx`
  - `src/app/(dashboard)/config/config-client.tsx`
  - `src/app/(dashboard)/consumables/consumables-client.tsx`
  - `src/app/(dashboard)/loot/loot-client.tsx`
  - `src/app/(dashboard)/balance/balance-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`
- `rg -n "startTransition\\(async|isPending|useTransition"` on the touched files

## Follow-up

- the remaining admin async-state debt is now smaller and more concentrated in older editor shells like `snapshots`, `skills`, `passives`, and `tables`
- the core live config/balance editors are now much closer to being trustworthy operator surfaces rather than optimistic shells
