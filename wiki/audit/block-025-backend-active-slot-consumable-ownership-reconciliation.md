---
title: Audit Block 025 — Backend Active-Slot Consumable Ownership Reconciliation
category: audit
tags: [audit, backend, passive-tree, active-slots, consumables, cache, contracts]
sources:
  - backend/src/app/api/passives/active-slots/route.ts
  - backend/src/app/api/passives/active-slots/batch/route.ts
  - backend/src/app/api/consumables/use/route.ts
  - backend/src/app/api/pvp/strike/route.ts
  - backend/src/lib/game/active-slots.ts
updated: 2026-04-15
---

# Audit Block 025 — Backend Active-Slot Consumable Ownership Reconciliation

## Scope

This block closes the open decision left in [[block-024-interactive-combat-consumable-recovery]]: what should happen to a potion slot when the player no longer owns that potion outside combat?

After re-auditing the full server path, the real issue was deeper than UI drift:

- the passive-tree editor contract allowed a potion slot to remain in `character_active_slots` after quantity dropped to zero,
- the server still accepted direct equip/save requests for potions the character did not own,
- the slot cache could keep returning that invalid state until TTL expiry,
- interactive combat had already started defending itself against the same bad state.

- **Files audited in this block:** 5
- **Primary file types:** backend routes, cache helper, active-slot runtime contracts
- **Status:** active-slot consumables are now server-authoritative on ownership; zero-quantity potion slots are auto-cleaned and cannot be re-saved without real inventory
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[passive-tree]], [[interactive-combat]], [[block-024-interactive-combat-consumable-recovery]], [[block-011-backend-passives-interactive-combat-runtime]]

## Summary

- `POST /api/passives/active-slots` and `POST /api/passives/active-slots/batch` previously validated only the potion type allowlist, not actual ownership.
- `GET /api/passives/active-slots` cached slot payloads separately from fresh `consumables_meta`, so a zero-quantity equipped potion could survive as a stale slot even after combat/use had already made it impossible.
- `/pvp/strike` now knows how to recover from `OUT_OF_CONSUMABLE`, but without out-of-combat cleanup the same invalid slot could remain the stored loadout source of truth.
- The safe resolution is now explicit: an active-slot consumable is valid only while the character owns at least one copy.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Active-slot equip/save APIs allowed potion slots with zero ownership. | Direct API callers, stale clients, or racey UIs could persist impossible loadouts that later broke combat assumptions. | Single-slot and batch save routes now require positive `consumable_inventory.quantity` before accepting a potion slot. |
| P1 | Active-slot GET cache could keep returning zero-quantity consumable slots. | Talents UI could present an invalid loadout for up to the cache TTL even after inventory depletion. | GET now reconciles cached/live slot payloads against fresh ownership metadata, deletes impossible potion rows, and rewrites the cache with the cleaned result. |
| P2 | Active-slot cache key and allowlist constants were duplicated across routes. | Validation and invalidation rules could drift between single-slot, batch, and combat cleanup flows. | Added shared `lib/game/active-slots.ts` for the canonical cache key, invalidator, and allowed active-slot consumable list. |
| P2 | Real potion depletion paths did not proactively invalidate active-slot cache. | Even with reconciliation on read, depleted slots could linger in cache until the next active-slot fetch. | `consumables/use` and `pvp/strike` now invalidate active-slot cache after health-potion depletion, and `pvp/strike` also deletes the impossible stored slot on `OUT_OF_CONSUMABLE`. |

## Cross-File Safe Fixes Applied

- `backend/src/lib/game/active-slots.ts` is now the shared source for:
  - `ACTIVE_SLOT_CONSUMABLES`
  - `activeSlotsCacheKey(characterId)`
  - `invalidateActiveSlotsCache(characterId)`
- `backend/src/app/api/passives/active-slots/route.ts` now:
  - validates real potion ownership before equipping a consumable slot,
  - reconciles cached/live slot payloads against fresh `owned_count`,
  - deletes impossible zero-quantity consumable rows from `character_active_slots`,
  - rewrites the cache with the cleaned slot payload.
- `backend/src/app/api/passives/active-slots/batch/route.ts` now rejects loadouts containing potion slots the character does not currently own.
- `backend/src/app/api/consumables/use/route.ts` now invalidates active-slot cache after health-potion depletion.
- `backend/src/app/api/pvp/strike/route.ts` now invalidates active-slot cache after potion consumption and deletes the impossible stored potion slot when recovering from `OUT_OF_CONSUMABLE`.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/lib/game/active-slots.ts` | Backend active-slot helper | Canonical helper for active-slot cache key, invalidation, and allowed potion list. | Used by passive-tree active-slot routes and combat/consumable mutation flows. | Active-slot consumable allowlist and cache invalidation should not drift across call sites. | New shared helper extracted to remove duplicated constants and cache-key strings. | Fixed |
| `backend/src/app/api/passives/active-slots/route.ts` | Backend single-slot active-loadout API | Reads, equips, and clears one active slot plus exposes potion picker metadata. | Used by iOS passive-tree runtime. Depends on auth, Prisma, cache, and game config. | A potion slot is valid only if the character currently owns that potion. Read path should not keep serving impossible cached slots. | Added ownership validation, read-side reconciliation, stale-row deletion, and shared invalidation helper usage. | Fixed |
| `backend/src/app/api/passives/active-slots/batch/route.ts` | Backend atomic loadout save API | Saves the full 3-slot loadout transactionally. | Used by `ActiveSkillPickerSheet` save flow. Depends on auth, Prisma, rate-limit, and active-slot constraints. | Full loadout save must enforce the same ownership rule as single-slot equip. | Added positive-quantity ownership validation for consumable slots and moved to shared invalidation helper/constants. | Fixed |
| `backend/src/app/api/consumables/use/route.ts` | Backend out-of-combat consumable-use API | Applies a consumable effect and decrements consumable inventory. | Used by inventory/overworld consumable flows. Depends on regen/effect helpers and quest progress. | Health-potion depletion can invalidate an equipped potion slot and should evict active-slot cache promptly. | Added active-slot cache invalidation after health-potion use. | Fixed |
| `backend/src/app/api/pvp/strike/route.ts` | Backend interactive round resolver | Resolves a live PvP round, decrements fired consumables, and returns updated duel state. | Used by interactive combat client. Depends on match snapshot, combat math, and inventory rows. | Recoverable potion depletion should also clean up the out-of-combat loadout source of truth, not only the match snapshot. | Added active-slot cache invalidation after potion fire and deletion of the impossible stored potion slot during `OUT_OF_CONSUMABLE` reconcile. | Fixed |

## Duplicate / Split Logic Found

- The active-slot consumable allowlist used to live in both single-slot and batch routes. This block consolidates that rule into one helper.
- Active-slot cache invalidation used to be passives-route-local even though consumable depletion also happens in combat and generic consumable-use flows.

## Files Without Clear Current Role

- None. All files touched here are on live passive-tree, consumable, or combat runtime paths.

## Candidates For Refactor

- Default price fallback metadata for active-slot consumables still lives in `active-slots/route.ts`, while shop pricing fallbacks live in shop routes. The allowlist is now centralized, but fallback pricing is still duplicated.
- If more systems need to reason about slot validity, a small shared server helper for "reconcile invalid active-slot consumables" may be worth extracting from the route-local implementation.

## Documentation Missing Or Stale

- There is still no dedicated wiki/system page that defines the full potion-slot lifecycle: equip requirements, depletion behavior, cleanup timing, and whether repurchase should ever auto-restore a prior slot.

## Requires Separate Decision

- Should repurchasing a potion auto-restore the previously pruned slot, or is manual re-equip the intended UX? Current server behavior is now explicit: once quantity reaches zero, the slot is removed and must be re-equipped later.

## Verification

- `npx eslint src/app/api/passives/active-slots/route.ts src/app/api/passives/active-slots/batch/route.ts src/app/api/consumables/use/route.ts src/app/api/pvp/strike/route.ts src/lib/game/active-slots.ts` passes.
- `git diff --check` passes after the backend/runtime changes and wiki updates.
