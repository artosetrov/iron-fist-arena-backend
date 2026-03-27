# Feature: Gold Mine

> **Status:** Complete
> **Owner:** Economy / Idle gameplay
> **Last updated:** 2026-03-26
> **Source of truth:** `backend/src/lib/game/gold-mine.ts`

---

## Overview

Idle-система добычи gold. Слоты с таймерами, collect когда ready. Boost за gems, unlock дополнительных слотов.

## Key Files

**iOS View:** `Views/Minigames/GoldMineDetailView.swift`
**ViewModel:** `GoldMineViewModel.swift`
**Backend Logic:** `backend/src/lib/game/gold-mine.ts`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/minigames/gold-mine/status` | Состояние слотов |
| `POST` | `/api/minigames/gold-mine/start` | Начать добычу |
| `POST` | `/api/minigames/gold-mine/collect` | Собрать gold |
| `POST` | `/api/minigames/gold-mine/buy-slot` | Разблокировать слот (gems) |
| `POST` | `/api/minigames/gold-mine/boost` | Ускорить (gems) |

## Hub Badge

Building `gold-mine` → `"READY"` когда есть слоты с status `"ready"` в `cache.goldMineSlots`

## Dependencies

- Depends on: Economy system
- Depended by: Daily quests (gold_mine_collect)

## Related Docs

- `docs/rules/rules-economy.md`
