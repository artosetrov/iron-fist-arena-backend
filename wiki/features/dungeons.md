# Feature: Dungeons

> Single-file map of every file that touches the classic (PvE) dungeon system — multi-room runs with combat, boss, loot.

## One-liner

Players select a dungeon, enter a room, fight enemies round-by-round, progress through rooms to the boss, clear for loot + XP + gold.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Dungeon/DungeonSelectDetailView.swift` — dungeon list / selection
  - `Hexbound/Hexbound/Views/Dungeon/DungeonMapView.swift` — in-run progression map
  - `Hexbound/Hexbound/Views/Dungeon/DungeonRoomDetailView.swift` — active room combat
  - `Hexbound/Hexbound/Views/Dungeon/DungeonVictoryView.swift` / `DungeonDefeatView.swift` — run resolution
  - `Hexbound/Hexbound/Views/Dungeon/BossDetailSheet.swift`, `DungeonInfoSheet.swift`, `LootPreviewSheet.swift` — info modals
  - `Hexbound/Hexbound/Views/Dungeon/DungeonMapEditorView.swift` — dev/admin map tuning UI
- **Player action:** Hub → Dungeon building → select dungeon → Start → advance rooms

## Backend

### Routes

- `GET  /api/dungeons`              — `backend/src/app/api/dungeons/route.ts` — list available dungeons
- `GET  /api/dungeons/list`         — `backend/src/app/api/dungeons/list/route.ts` — alternate list endpoint
- `POST /api/dungeons/start`        — `backend/src/app/api/dungeons/start/route.ts` — begin run, allocate seed
- `POST /api/dungeons/fight`        — `backend/src/app/api/dungeons/fight/route.ts` — resolve a room fight
- `POST /api/dungeons/run`          — `backend/src/app/api/dungeons/run/route.ts` — continue/advance run
- `POST /api/dungeons/abandon`      — `backend/src/app/api/dungeons/abandon/route.ts` — forfeit active run

### Business logic

- `backend/src/lib/game/dungeons.ts` — room generation, encounter roll, boss logic
- `backend/src/lib/game/combat.ts` — shared combat core (see [[pvp-combat]])
- `backend/src/lib/game/loot.ts` — drop tables per dungeon tier

### Prisma models touched

- `Dungeon` (line 1343) — dungeon catalog
- `DungeonProgress` (line 607) — per-character per-dungeon clear progress
- `DungeonRun` (line 624) — active run state (rooms cleared, HP, seed)
- `Character.dungeonClearsToday` (line 361), `dungeonClearsDate` (line 362) — daily throttle
- `Character.dungeonRuns` (line 412) — back-relation

### Balance constants

- `backend/src/lib/game/balance.ts` → `DUNGEON_DAILY_LIMIT`, `DUNGEON_TIERS`, loot rates

## iOS

### Views

- `Hexbound/Hexbound/Views/Dungeon/*` — 14 files (select, map, room, victory/defeat, sheets, editor)
- `Hexbound/Hexbound/Views/Dungeon/DungeonBossCard.swift` — boss preview card (3 variants in Figma DS)
- `Hexbound/Hexbound/Views/Dungeon/DungeonMapBuildingView.swift` + `DungeonMapBuildingConfig.swift` — map building layout

### ViewModels

- `Hexbound/Hexbound/Views/Dungeon/DungeonSelectViewModel.swift` — list state
- `Hexbound/Hexbound/Views/Dungeon/DungeonRoomViewModel.swift` — per-room combat state

### Services

- `Hexbound/Hexbound/Services/DungeonService.swift` — start/fight/run/abandon wrapper
- `Hexbound/Hexbound/Services/CombatEngine.swift` — shared animation driver

### Cache

- `GameDataCache.dungeons` — catalog + per-dungeon progress

## Admin

- `admin/src/app/(dashboard)/dungeons/` — dungeon editor, room config, drop rate tuning

## Docs

- `docs/06_game_systems/COMBAT.md` — shared combat foundation
- `docs/06_game_systems/GAME_SYSTEMS.md` — PvE progression

## Notable gotchas

- **Daily throttle.** `dungeonClearsToday` + `dungeonClearsDate` gate entries. Day-boundary rollover is server UTC.
- **Run state authority.** `DungeonRun` is server-authoritative — resuming a run re-fetches from backend, never trusts client state.
- **Seed determinism.** Run seed chosen at start; rooms/drops derive from seed so admin can replay for bug investigation.
- **Achievement hook.** `dungeons_complete` quest + achievement counters fire on final boss clear, not on individual rooms.
- **Loot only on clear.** Abandon = no loot. Defeat = no loot. Victory = full drop table roll.
- **Boss reveal ceremony.** On first `.current` open of a real boss (`isRealBoss == true`), `BossDetailSheet.onAppear` fires `AppState.presentBossReveal(_:)` once per boss (UserDefaults `bossRevealSeen_<name>_<id>`). Practice enemies (Training Camp dummies) are skipped. See [[why-boss-reveal-ceremony]].

## Tests / fixtures

- `backend/src/__tests__/dungeons/*` (if present)

## Related features

- [[pvp-combat]] — shared combat core
- [[dungeon-rush]] — sibling PvE, time-attack variant (lives in minigames)
- [[inventory]] — loot lands in inventory
- [[quests]] — `dungeons_complete` is a quest type
- [[achievements]] — progression category tracks dungeon clears
