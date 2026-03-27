# Feature: Dungeons

> **Status:** Complete
> **Owner:** PvE gameplay
> **Last updated:** 2026-03-26
> **Source of truth:** `Hexbound/Hexbound/Views/Dungeon/` + `backend/src/app/api/dungeons/`

---

## Overview

Подземелья — PvE контент с floor-by-floor прогрессией, боссами, лутом. 4 сложности (Easy/Normal/Hard/Nightmare) + режим Dungeon Rush (time-attack минигра).

## Key Files

**iOS Views:**
- `Views/Dungeon/DungeonSelectDetailView.swift` — выбор подземелья и сложности
- `Views/Dungeon/DungeonRoomDetailView.swift` — комната (бой с мобами)
- `Views/Dungeon/DungeonBossCard.swift` — карточка босса
- `Views/Dungeon/BossDetailSheet.swift` — детали босса
- `Views/Dungeon/DungeonMapView.swift` — визуализация карты
- `Views/Dungeon/DungeonVictoryView.swift` — экран победы
- `Views/Dungeon/LootPreviewSheet.swift` — предпросмотр лута
- `Views/Minigames/DungeonRushDetailView.swift` — Dungeon Rush режим

**ViewModels:** `DungeonSelectViewModel.swift`, `DungeonRoomViewModel.swift`, `DungeonRushViewModel.swift`
**Service:** `Services/DungeonService.swift`
**Model:** `Models/DungeonInfo.swift`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/dungeons` | Список подземелий |
| `GET` | `/api/dungeons/list` | Детальный список с прогрессом |
| `POST` | `/api/dungeons/start` | Начать забег |
| `POST` | `/api/dungeons/fight` | Бой в комнате |
| `POST` | `/api/dungeons/abandon` | Сдаться |
| `POST` | `/api/dungeon-rush/start` | Rush: начать |
| `POST` | `/api/dungeon-rush/fight` | Rush: бой |
| `POST` | `/api/dungeon-rush/resolve` | Rush: финализировать |
| `POST` | `/api/dungeon-rush/shop-buy` | Rush: внутренний магазин |

**Backend Logic:**
- `backend/src/lib/game/dungeon.ts` — room progression, enemy gen, rewards
- `backend/src/lib/game/dungeon-rush.ts` — rush mode logic
- `backend/src/lib/game/dungeon-run-lock.ts` — concurrency control

**DB Models:** `Dungeon`, `DungeonRun`, `DungeonProgress`, `DungeonBoss`, `DungeonWave`, `DungeonWaveEnemy`, `DungeonDrop`
**Seeds:** `prisma/seed-dungeons.ts`, `prisma/seed-dungeon-drops.ts`
**Tests:** `backend/tests/api/dungeon-rush-resolve.test.ts`

## Dependencies

- Depends on: Combat system, Loot system, Stamina, Equipment
- Depended by: Daily quests (dungeons_complete), Achievements

## Related Docs

- `docs/rules/rules-combat-pvp.md`, `docs/06_game_systems/COMBAT.md`, `docs/06_game_systems/BALANCE_CONSTANTS.md`
