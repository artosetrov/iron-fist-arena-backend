# Feature: Dungeon Rush

> Single-file map of every file that touches Dungeon Rush — roguelite 12-room endless-attack minigame, distinct from classic Dungeons.

## One-liner

12-room fixed-layout roguelite run: combat, elite, miniboss, treasure, event, shop rooms — player pushes through a seeded sequence for escalating loot until death.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushStartView.swift` — pre-run loadout / start
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushDetailView.swift` — main run host
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushRoomView.swift` — per-room interaction
  - `Hexbound/Hexbound/Views/Minigames/DungeonRushGameOver.swift` — run resolution
- **Player action:** Hub → Minigames → Dungeon Rush → Start

## Backend

### Routes

- `POST /api/dungeon-rush/start`      — `backend/src/app/api/dungeon-rush/start/route.ts` — begin run, seed 12-room layout
- `GET  /api/dungeon-rush/status`     — `backend/src/app/api/dungeon-rush/status/route.ts` — current run state
- `POST /api/dungeon-rush/fight`      — `backend/src/app/api/dungeon-rush/fight/route.ts` — resolve combat room
- `POST /api/dungeon-rush/resolve`    — `backend/src/app/api/dungeon-rush/resolve/route.ts` — resolve non-combat room (event/treasure/shop)
- `POST /api/dungeon-rush/shop-buy`   — `backend/src/app/api/dungeon-rush/shop-buy/route.ts` — purchase from in-run shop room
- `POST /api/dungeon-rush/abandon`    — `backend/src/app/api/dungeon-rush/abandon/route.ts` — forfeit run

### Business logic

- `backend/src/lib/game/dungeon-rush.ts` — 12-room fixed layout, room-type logic, seed-driven generation
- `backend/src/lib/game/dungeon.ts` — shared Enemy type + base dungeon helpers
- `backend/src/lib/game/dungeon-run-lock.ts` — concurrent-run lock guard
- `backend/src/lib/game/combat.ts` — shared combat core

### Room layout (from `dungeon-rush.ts`)

Fixed 12-room sequence: `combat, event, combat, treasure, elite, miniboss, shop, combat, event, elite, ...` — exact layout in source.

### Room types

`combat` / `elite` / `miniboss` / `treasure` / `event` / `shop`

### Prisma models touched

- `MinigameSession` (line 695) — reused for Dungeon Rush runs (`gameType = "dungeon_rush"` or similar); holds run state
- May reference `DungeonRun` model indirectly for combat reuse

### Balance constants

- `backend/src/lib/game/balance.ts` → rush-specific drop / encounter tuning

## iOS

### Views

- `Hexbound/Hexbound/Views/Minigames/DungeonRushStartView.swift` — entry gate, stamina cost display
- `Hexbound/Hexbound/Views/Minigames/DungeonRushDetailView.swift` — run host, room progression
- `Hexbound/Hexbound/Views/Minigames/DungeonRushRoomView.swift` — per-room UI (combat delegates to CombatEngine)
- `Hexbound/Hexbound/Views/Minigames/DungeonRushGameOver.swift` — post-run summary

### ViewModel

- `Hexbound/Hexbound/Views/Minigames/DungeonRushViewModel.swift` — run state, current room index

### Services

- Reuses `DungeonService.swift` or dedicated rush endpoints via `APIClient`
- `Hexbound/Hexbound/Services/CombatEngine.swift` — combat animation shared with classic dungeons

### Cache

- `GameDataCache.activeRushRun` — current run if resumable

## Admin

- `admin/src/app/` — rush catalog / room balance (if present)

## Docs

- `docs/06_game_systems/COMBAT.md` — combat foundation shared
- Enum `ConsumableTier` values `boss_rush`, `gold_rush` hint at rush-tier rewards

## Notable gotchas

- **Seed stability.** 12-room layout is FIXED; only encounter contents vary by seed. Changing `ROOM_LAYOUT` = breaking change.
- **Concurrent-run guard.** `dungeon-run-lock.ts` prevents starting a new rush while one is active — if lock leaks, players get "already in run" 409.
- **Death = loss.** No continue on death; all in-run loot banks at run end only. Check `resolve` semantics.
- **Shop room in-run.** Distinct from main [[shop]] — uses gold earned during run; unlock via `shop-buy` endpoint.
- **Stamina gated.** Run start consumes stamina; check `DUNGEON_RUSH_STAMINA_COST` in balance.
- **Miniboss reveal ceremony.** `DungeonRushDetailView` watches `currentRoom?.type` and fires `AppState.presentBossReveal(_:)` the first time the miniboss room becomes current in a given run (tracked by `revealedMinibossIdx`). Compact ~1.2s variant of the shared overlay; CTA commits directly to `vm.fight()`. See [[why-boss-reveal-ceremony]].

## Tests / fixtures

- `backend/src/__tests__/dungeon-rush/*` (if present)

## Related features

- [[dungeons]] — sibling PvE system (longer runs, non-roguelite)
- [[stamina]] — entry cost
- [[inventory]] — loot lands here post-run
- [[minigames]] — rush is hosted under the Minigames section
