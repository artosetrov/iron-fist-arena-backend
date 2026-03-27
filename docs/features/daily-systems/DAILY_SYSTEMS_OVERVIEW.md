# Feature: Daily Systems (Login + Quests)

> **Status:** Complete
> **Owner:** Retention / Progression
> **Last updated:** 2026-03-26
> **Source of truth:** `backend/src/lib/game/daily-quests.ts` + `daily-login.ts`

---

## Overview

Ежедневные системы для retention: Daily Login (календарь наград за вход) и Daily Quests (задания с прогрессом).

---

## Daily Login

**iOS Views:**
- `Views/DailyLogin/DailyLoginPopupView.swift` — popup при запуске
- `Views/DailyLogin/DailyLoginDetailView.swift` — полный календарь

**ViewModel:** `DailyLoginPopupViewModel.swift`
**Service:** `Services/DailyLoginService.swift`
**Model:** `Models/DailyLoginData.swift`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/daily-login` | Календарь наград |
| `POST` | `/api/daily-login/claim` | Забрать награду дня |

**Logic:** `backend/src/lib/game/daily-login.ts`

---

## Daily Quests

**iOS Views:**
- `Views/Quests/DailyQuestsDetailView.swift` — список квестов с прогрессом
- `Views/Components/ActiveQuestBanner.swift` — баннер на Hub

**ViewModel:** `DailyQuestsViewModel.swift` — requires `cache: GameDataCache` in init
**Service:** `Services/QuestService.swift`
**Model:** `Models/Quest.swift`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/quests/daily` | Активные квесты |
| `POST` | `/api/quests/daily/bonus` | Забрать бонус |

**Logic:** `backend/src/lib/game/daily-quests.ts` — atomic progress increments

## Quest Types (enum)

`pvp_wins`, `dungeons_complete`, `gold_spent`, `item_upgrade`, `consumable_use`, `shell_game_play`, `gold_mine_collect`

НЕТ `pvp_win` или `pvp_fight` — не существуют.

## Rules

- Atomic increments для прогресса (raw SQL, не read-then-write)
- Optimistic UI: mark claimed instantly
- Emoji → assets для наград
- Cache TTL: 60s для daily quests

## Key Files

| Layer | Files |
|-------|-------|
| iOS Views | `DailyLoginPopupView.swift`, `DailyLoginDetailView.swift`, `DailyQuestsDetailView.swift`, `ActiveQuestBanner.swift` |
| ViewModels | `DailyLoginPopupViewModel.swift`, `DailyQuestsViewModel.swift` |
| Services | `DailyLoginService.swift`, `QuestService.swift` |
| Models | `DailyLoginData.swift`, `Quest.swift` |
| Backend | `backend/src/lib/game/daily-login.ts`, `backend/src/lib/game/daily-quests.ts` |

## Related Docs

- `docs/rules/rules-economy.md`, `docs/rules/rules-backend.md`
