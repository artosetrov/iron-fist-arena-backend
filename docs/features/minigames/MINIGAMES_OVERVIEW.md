# Feature: Minigames (Shell Game + Fortune Wheel + Fortune's Table)

> **Status:** Complete
> **Owner:** Economy / Engagement
> **Last updated:** 2026-10-17
> **Source of truth:** `Hexbound/Hexbound/Views/Minigames/`

---

## Overview

Мини-игры для дополнительного engagement и gold/gem sink: Shell Game (угадай стакан) и Fortune Wheel (крутить колесо).

---

## Shell Game

**iOS View:** `Views/Minigames/ShellGameDetailView.swift`
**ViewModel:** `ShellGameViewModel.swift`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/api/minigames/shell-game/start` | Инициализировать |
| `POST` | `/api/minigames/shell-game/play` | Сделать выбор |

**Quest type:** `shell_game_play` (для daily quests)

---

## Fortune Wheel

**iOS View:** `Views/Minigames/FortuneWheelDetailView.swift`
**ViewModel:** `FortuneWheelViewModel.swift`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/api/minigames/fortune-wheel/spin` | Крутить, получить награду |

**Animation note:** `.transaction { $0.animation = nil }` на parent убивает `withAnimation()`. Для spin используй `.animation(.timingCurve(...), value: rotation)` на самом колесе.

**Баланс (2026-10-17):** веса LOSE 20 ×6, x1.5 25 ×3, x2 20, x3 10, x5 4 (всего 229). RTP 88.4 % + Казна ≈ 91 % (симуляция 90.8 %; было 59.3 %). 47.6 % спинов платят.

**Казна Фортуны** (`WHEEL_TREASURY` в `lib/game/fortune-wheel.ts`): общий прогрессивный джекпот. 2 % каждой ставки → казна (строка `game_config` key `fortune_wheel_treasury`, category `runtime`, атомарный upsert). Сектор x5 платит `0.2 × казна × min(1, ставка / 1000)`; казна не падает ниже 5 000 (сид), в среднем держится ~6.5 k. Почему 20 %, а не вся казна: при «макс. ставка забирает всё» казна почти всегда стоит на полу 5 000, x5 на 1 000 платил ~x10, и RTP выходил ≈ 98 % (дом доливал ~7.6 % ставок). Admin restore конфига не трогает `runtime`-строки.

**Отображение:** арт `fortune-wheel-face` уже нарисован (12 слотов), клиент мапит серверные сектора на нарисованные слоты (`FortuneWheelLayout`). Угол остановки считается от текущего положения колеса. Золото и казна обновляются только после остановки колеса.

---

## Fortune's Table (Стол Фортуны)

Джекпот-колесо на 4–6 мест. Ставка = доля колеса, один спин решает, кто забирает банк минус 5 % «десятины» + сундук Фортуны. Этап 1 — остальные места занимают боты-завсегдатаи (виртуальные, из сида раунда).

**iOS:** `Views/Minigames/FortuneTableDetailView.swift`, `FortuneTableViewModel.swift`, `FortuneTableWheel.swift`, `Models/FortuneTableModels.swift`. Вход — карточка «FORTUNE'S TABLE» на экране колеса; deep link `fortune-table`.

**Backend:** `lib/game/fortune-table.ts` (чистый движок), `lib/game/fortune-table-server.ts` (БД), роуты `api/minigames/fortune-table/{status,join,topup,state}`. Раунды — `MinigameSession` с `gameType = 'fortune_table'` (миграции нет).

| Параметр | Значение |
|---|---|
| Столы | Медный 50–500 (ур. 1), Серебряный 300–3 000 (ур. 10), Золотой 2 000–20 000 (ур. 20) |
| Лобби | 20 с; докупка закрывается за 1 с до конца |
| Рейк | 5 % банка; ожидание игрока всегда −5 % ставки |
| Сундук | предмет с шансом `clamp(банк / 10 000, 0.02, 1)` → на раунд ≈ ставка / 10 000, одинаково на всех столах |
| Лимит | 20 раундов в день |
| Боты | 3–5, суммарно 1.5–5× ставки игрока; 1–2 уже сидят; «азартные» докупают в конце; расписание фиксируется при открытии |

**Честность (commit-reveal):** при открытии раунда показывается `sha256(seed)`; билет = `HMAC-SHA256(seed, "ticket")` → [0, 1); победитель — чей клин содержит билет; после розыгрыша сид раскрывается, клиент проверяет хэш и билет на устройстве (CryptoKit).

**Розыгрыш:** первый `/state` (или `/status`, `/join`) после конца лобби рассчитывает раунд под `FOR UPDATE` на строке сессии — повторные вызовы ничего не делают. Раунды, брошенные игроком, добирает cron `/api/cron/fortune-table-settle` (каждые 15 мин, `vercel.json`, нужен `CRON_SECRET`). Join/top-up — Serializable с повтором на P2034; порядок блокировок везде «сессия → пользователь».

**Клиент:** исход (сид, указатель, «Verified») показывается только после остановки колеса; золото — тоже. Опрос `/state` раз в 1 с, у лока — 0.5 с, при ошибках — экспоненциальный бэкофф, после 8 ошибок — возврат к выбору стола (раунд всё равно будет выплачен).

---

## Dungeon Rush

Dungeon Rush — тоже в `Views/Minigames/`, но документация в `docs/features/dungeons/DUNGEONS_OVERVIEW.md`.

## Dependencies

- Depends on: Economy system, Loot system
- Depended by: Daily quests (shell_game_play)

## Key Files

| Layer | Files |
|-------|-------|
| iOS Views | `ShellGameDetailView.swift`, `FortuneWheelDetailView.swift`, `FortuneTableDetailView.swift`, `FortuneTableWheel.swift` |
| ViewModels | `ShellGameViewModel.swift`, `FortuneWheelViewModel.swift`, `FortuneTableViewModel.swift` |
| Backend | `backend/src/app/api/minigames/shell-game/`, `.../fortune-wheel/`, `.../fortune-table/`, `lib/game/fortune-wheel.ts`, `lib/game/fortune-table*.ts` |
| Tests | `backend/tests/lib/fortune-wheel.test.ts`, `backend/tests/lib/fortune-table.test.ts` |

## Related Docs

- `docs/rules/rules-swift.md` (animation gotchas), `docs/rules/rules-economy.md`
