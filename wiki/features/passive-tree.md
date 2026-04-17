# Feature: Passive Tree

> Single-file map of every file that touches passive talents + active skills — node-based talent tree + active-skill slot binding (shared with [[interactive-combat]]).

## One-liner

Players allocate talent points into a node-based passive tree for permanent stat bonuses, and bind active skills to combat slots used in Interactive Combat.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screen:** `Hexbound/Hexbound/Views/Hero/HeroDetailView.swift` → Talents tab
- **iOS host:** `Hexbound/Hexbound/Views/Hero/Talents/TalentsTabView.swift`
- **Player action:** Hero screen → Talents tab → tap node → allocate / respec; tap Active Slots → bind skill

## Backend

### Routes

#### Passives
- `GET  /api/passives/tree`          — `backend/src/app/api/passives/tree/route.ts` — full tree catalog (nodes + connections)
- `GET  /api/passives/character`     — `backend/src/app/api/passives/character/route.ts` — this character's allocated nodes
- `POST /api/passives/unlock`        — `backend/src/app/api/passives/unlock/route.ts` — allocate a point to a node
- `POST /api/passives/respec`        — `backend/src/app/api/passives/respec/route.ts` — refund + reset all allocations

#### Active slots
- `GET  /api/passives/active-slots`         — `backend/src/app/api/passives/active-slots/route.ts` — list current slot bindings
- `POST /api/passives/active-slots`         — same file — slot change / persist
- `POST /api/passives/active-slots/batch`   — `backend/src/app/api/passives/active-slots/batch/route.ts` — bulk slot persist

#### Skills (active skill catalog + equip)
- `GET  /api/skills/character`       — `backend/src/app/api/skills/character/route.ts` — learned skills
- `POST /api/skills/learn`           — `backend/src/app/api/skills/learn/route.ts` — learn a skill (unlock for binding)
- `POST /api/skills/equip`           — `backend/src/app/api/skills/equip/route.ts` — equip to active slot
- `POST /api/skills/upgrade`         — `backend/src/app/api/skills/upgrade/route.ts` — level up a learned skill

### Business logic

- `backend/src/lib/game/passive-tree.ts` — node unlock rules, prerequisite walker, respec cost calc
- `backend/src/lib/game/active-slots.ts` — slot CRUD, validation, effect resolution (shared with [[interactive-combat]])
- `backend/src/lib/game/skills.ts` — skill catalog, upgrade rules

### Prisma models touched

- `PassiveNode` (line 1255) — tree catalog: id, class, effect, cost, position
- `PassiveConnection` (line 1291) — tree edges (prerequisite graph)
- `CharacterPassive` (line 1303) — per-character per-node allocation row
- `Skill` (line 1212) — skill catalog (id, effect, tier, class restriction)
- `CharacterActiveSlot` (line 1325) — per-character per-slot binding (exact-one-kind DB check constraint)

### DB constraints (important)

`character_active_slots_exactly_one_kind_chk` and partial indexes enforce that each slot binds exactly one kind of thing (skill OR passive, not both) — see schema comment around line 1320.

### Balance constants

- `backend/src/lib/game/balance.ts` → respec costs, per-level point grants

## iOS

### Views

- `Hexbound/Hexbound/Views/Hero/Talents/TalentsTabView.swift` — tab host
- `Hexbound/Hexbound/Views/Hero/Talents/TalentTreeCanvas.swift` — zoom/pan node canvas
- `Hexbound/Hexbound/Views/Hero/Talents/TalentNodeView.swift` — single node
- `Hexbound/Hexbound/Views/Hero/Talents/TalentDetailSheet.swift` — tap-node modal
- `Hexbound/Hexbound/Views/Hero/Talents/ActiveSlotsBar.swift` — active-slot row
- `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift` + `ActiveSkillPickerRow.swift` — skill picker

### ViewModel

- `Hexbound/Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift` — tree state, allocation, picker state

### Services

- `Hexbound/Hexbound/Services/PassiveTreeService.swift` — tree / character / unlock / respec + active-slot persistence

### Cache

- `GameDataCache.passiveTree` — static tree catalog
- `GameDataCache.characterPassives` — allocated nodes (per character)
- `GameDataCache.activeSlots` — slot bindings

## Admin

- `admin/src/app/(dashboard)/passives/` — tree editor (nodes, connections, effects)

## Docs

- `docs/06_game_systems/COMBAT.md` — how passives/active skills affect combat
- `docs/06_game_systems/BALANCE_CONSTANTS.md` — respec cost + point grants

## Notable gotchas

- **Prerequisite walk.** `PassiveConnection` is a directed graph — unlock must verify all required predecessors are already allocated. Bug = allocation past gated nodes.
- **Respec is scorched-earth.** Refunds all points, unbinds all active slots derived from passives. Gold/gem cost escalates per respec.
- **DB constraint ensures slot kind.** Active-slot row cannot hold skill+passive simultaneously — backend writers must choose one.
- **Server-authoritative effects.** Client NEVER simulates passive effects in combat — backend computes.
- **Active slot count is tier-gated.** Max slots typical = 5 (see [[interactive-combat]] Phase 3.B).
- **Migration-before-deploy rule.** New nodes / connections added to schema → must apply migration via Supabase MCP BEFORE code deploy (see memory `feedback_migration_mcp_apply_to_prod`).

## Tests / fixtures

- `backend/src/__tests__/passive-tree/*` (if present)

## Related features

- [[interactive-combat]] — consumes active-slot bindings for round-by-round firing
- [[characters]] — allocation points come from leveling
- [[pvp-combat]] — passives modify all combat math
- [[prestige]] — prestige resets allocations
