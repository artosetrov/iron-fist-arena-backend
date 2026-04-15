---
title: Audit Block 011 — Backend Passives and Interactive Combat Runtime
category: audit
tags: [audit, backend, passives, pvp, interactive-combat, cache]
sources:
  - backend/src/app/api/passives/
  - backend/src/app/api/pvp/
  - backend/src/lib/game/
updated: 2026-04-15
---

# Audit Block 011 — Backend Passives and Interactive Combat Runtime

## Scope

This block audits the runtime consumers of the active-slot and interactive-combat migrations: passive tree APIs, active-slot equip/save flows, match-start snapshotting, strike resolution, and the helper modules they depend on.

- **Files audited in this block:** 11
- **Primary file types:** Next.js route handlers, TypeScript gameplay helpers
- **Status:** Core flow is sound, but cache invalidation and per-round active handling had real correctness bugs
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-010-prisma-migrations-hotfixes-stash-interactive-premium]], [[interactive-combat]], [[passive-tree]], [[stamina]]

## Summary

- The passives/active-slots layer is generally in good shape: single-slot equip, atomic full-loadout save, and passive respec all line up with the DB constraints added in the recent migrations.
- The biggest runtime defect was a cache-key split: `passives/character` reads `passives:char:v2:${characterId}`, but shared helper `invalidatePassiveCache()` only deleted `passives:char:${characterId}`. That meant some stat/equipment/prestige flows could leave the client reading stale passive data.
- The most important interactive-combat defect was in `pvp/strike`: the fired active's cooldown was being set and then immediately decremented in the same round. That shortens every cooldown by one turn and makes `cooldown_max = 1` effectively instant-refresh.
- I also found an AI behavior bug: opponent logic could choose `stun_enemy`, but there is no second-actor stun effect implemented for the opponent path, so the AI could burn a cooldown on a no-op.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | `invalidatePassiveCache()` deleted `passives:char:${id}` while `passives/character` served `passives:char:v2:${id}`. | Clients could receive stale passive nodes after prestige, stat allocation, gear changes, dungeon fights, or any other flow using the shared invalidator. | Updated the helper to delete both legacy and v2 cache keys. |
| P1 | `pvp/strike` decremented cooldowns for the just-fired active in the same round. | All active cooldowns became one turn shorter than configured; `cooldown_max = 1` effectively became zero. | Replaced the blanket cooldown tick with per-slot post-round advancement that sets the fired slot correctly and ticks only the others. |
| P2 | Opponent AI could pick `stun_enemy` even though the second-actor stun path has no runtime effect. | The AI could waste a round and cooldown on a fake action, making PvP behavior inconsistent and misleading. | Excluded `stun_enemy` from opponent AI selection until a real next-turn stun state exists. |

## Cross-File Safe Fixes Applied

- `backend/src/lib/game/combat-loader.ts` now invalidates both passive cache key versions.
- `backend/src/app/api/pvp/strike/route.ts` now advances active state correctly after each round and no longer lets AI pick a no-op stun action.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/lib/game/passives.ts` | Passive-tree rules helper | Aggregates passive bonuses and validates whether a node is unlockable from current graph state. | Used by passive unlock logic, combat/build-stat aggregation. | Non-start nodes must be adjacent to an already unlocked node; bonuses aggregate by `bonusType`. | Clear small helper module. No issue found here. | OK |
| `backend/src/lib/game/combat-loader.ts` | Combat character loader + cache invalidation helper | Loads combat-ready character state, applies HP regen, aggregates passive bonuses, and exposes cache invalidators. | Used by PvP/combat routes and several stat/equipment mutation endpoints. | Combat uses persisted derived stats plus passive bonus aggregation; HP regen is applied and persisted on read. | Fixed cache invalidation drift: `invalidatePassiveCache()` now clears both legacy and v2 passive cache keys. | Fixed |
| `backend/src/lib/game/consumable-effects.ts` | Shared consumable math | Central source of truth for stamina/heal potion values and consumable HP-heal math. | Used by consumables API, PvP match snapshotting, and strike resolution. | GameConfig keys override hardcoded fallback values; health values are exposed both as percent and fraction forms. | Good cohesion; no issue found. | OK |
| `backend/src/app/api/passives/tree/route.ts` | Passive-tree read API | Returns the full passive graph for clients. | Depends on `prisma.passiveNode`, `prisma.passiveConnection`, cache layer. Used by passive-tree UI. | Tree payload is cached under `passives:tree:v2`; only active nodes are served. | Clean read route. Future admin/content workflows should explicitly invalidate this cache when node metadata changes. | OK |
| `backend/src/app/api/passives/character/route.ts` | Character passive-state read API | Returns unlocked passive nodes plus passive points for one character. | Depends on auth, Prisma passive relations, cache layer. Used by hero/passive UI. | Ownership enforced per character; payload includes active-slot-related node metadata. | The route itself was correct, but it depended on a shared invalidator that targeted the wrong key. Fixed via `combat-loader.ts`. | Fixed |
| `backend/src/app/api/passives/unlock/route.ts` | Passive unlock mutation | Unlocks one passive node, checks class/path/points, recalculates derived stats, and invalidates cache. | Depends on `canUnlockNode()`, `recalculateFullDerivedStats()`, auth, Prisma. | Node must exist, be active, match class, be connected, and the character must have enough passive points. | Solid transactional flow. No issue found in this block. | OK |
| `backend/src/app/api/passives/respec/route.ts` | Passive reset mutation | Refunds passive points, clears unlocked passives and active slots, charges gems, recalculates stats, invalidates caches. | Depends on live config, build-stats recalculation, auth, Prisma, cache layer. | Respec is gem-gated and wipes active slots because they depend on unlocked passives. | Coherent route; no new bug found. | OK |
| `backend/src/app/api/passives/active-slots/route.ts` | Single-slot active-loadout API | Lists equipped active slots, exposes consumable picker metadata, equips one slot, and clears one slot. | Depends on auth, cache, rate-limit, active-slot table, passive unlock state, item catalog, game config. | Exactly one of `node_id` or `consumable_type`; at most one consumable in the loadout; only unlocked activatable nodes may be equipped. | Re-audited later in [[block-025-backend-active-slot-consumable-ownership-reconciliation]]: shared active-slot constants/cache helper added, zero-quantity potion slots are now reconciled on read, and server-side equip now validates real ownership before accepting a consumable slot. | Fixed |
| `backend/src/app/api/passives/active-slots/batch/route.ts` | Atomic full-loadout save API | Replaces all three active slots in one transaction to avoid intermediate invalid states. | Depends on auth, rate-limit, cache, active-slot table, passive unlock state. | Payload must fully cover slots `0..2`; max one consumable; duplicate node IDs are rejected. | Re-audited later in [[block-025-backend-active-slot-consumable-ownership-reconciliation]]: the route now shares the canonical active-slot allowlist/cache helper and rejects batch saves that reference potions the character does not actually own. | Fixed |
| `backend/src/app/api/pvp/match/start/route.ts` | Interactive match bootstrap | Creates an in-progress PvP match, reserves stamina/free entry, snapshots both fighters' active slots, and returns the initial duel state. | Depends on auth, rate-limit, stamina/live-config helpers, combat loader, active-slot data, pvp match persistence. | Interactive duel starts both fighters at full HP for the match UI while still enforcing the 30% persisted HP gate for entry. | Works, but still carries raw-SQL/manual typing and `as any` Prisma-client workarounds from the stale-client incident. Those are survivable, but worth cleaning once Prisma generation is fully trustworthy in every environment. | Needs review |
| `backend/src/app/api/pvp/strike/route.ts` | Interactive round resolver | Resolves one duel round, applies actives, persists round history, updates active cooldown/consumed state, and decrements consumables atomically when fired. | Depends on auth, rate-limit, combat engine, combat loader, interactive match snapshot state, consumable inventory. | Player stun suppresses the counter this round; consumables are 1/battle and also decremented from real inventory when used. | Fixed two real defects: fired cooldowns were one turn too short, and opponent AI could choose a stun action that had no effect. Still contains some intentional v1 asymmetry and manual state shaping that should stay under close review. | Fixed |

## Duplicate / Split Logic Found

- Follow-up in [[block-025-backend-active-slot-consumable-ownership-reconciliation]] consolidated the active-slot consumable allowlist/cache key into a shared helper. Follow-up in [[block-026-backend-shop-consumable-pricing-parity]] then centralized the remaining consumable fallback pricing shared by shop and active-slot routes.
- Passive cache versioning is split across route-local cache keys and shared invalidation helpers. The mismatch caused a live stale-cache bug.
- `pvp/match/start` and `pvp/strike` both still carry workaround code for locally stale Prisma client generation (`as any`, raw typed rows) even though migration/schema parity is now much stronger.

## Files Without Clear Current Role

- None in this block. Every file has a live runtime role.

## Candidates For Refactor

- Centralize passive cache keys in one helper module so future cache-version changes cannot drift again.
- Replace the remaining local `as any` Prisma-client workarounds in interactive PvP once generated-client freshness is enforced in all environments.

## Documentation Missing Or Stale

- No current page defines passive cache-key versioning or invalidation ownership.
- No current interactive-combat doc clearly states that opponent AI does not yet have a persistent next-turn stun mechanic.
- Follow-up in [[block-025-backend-active-slot-consumable-ownership-reconciliation]] created a canonical helper for the active-slot consumable allowlist/cache key, and [[block-026-backend-shop-consumable-pricing-parity]] centralized fallback pricing. The remaining gap is documentation of that pricing policy.

## Verification

- `bash -lc 'cd backend && npx eslint src/app/api/pvp/strike/route.ts src/lib/game/combat-loader.ts src/app/api/passives/character/route.ts src/app/api/passives/active-slots/route.ts src/app/api/passives/active-slots/batch/route.ts src/app/api/passives/respec/route.ts src/app/api/passives/unlock/route.ts src/app/api/passives/tree/route.ts src/app/api/pvp/match/start/route.ts src/lib/game/consumable-effects.ts src/lib/game/passives.ts'` passes.
- `git diff --check` passes after the fixes in this block.
- No focused automated PvP-active test existed for the cooldown/stun bug, so this block is verified by code-path review plus lint rather than dedicated regression tests.
