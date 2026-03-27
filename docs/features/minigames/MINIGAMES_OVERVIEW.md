# Feature: Minigames (Shell Game + Fortune Wheel)

> **Status:** Complete
> **Owner:** Economy / Engagement
> **Last updated:** 2026-03-26
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

---

## Dungeon Rush

Dungeon Rush — тоже в `Views/Minigames/`, но документация в `docs/features/dungeons/DUNGEONS_OVERVIEW.md`.

## Dependencies

- Depends on: Economy system, Loot system
- Depended by: Daily quests (shell_game_play)

## Key Files

| Layer | Files |
|-------|-------|
| iOS Views | `ShellGameDetailView.swift`, `FortuneWheelDetailView.swift` |
| ViewModels | `ShellGameViewModel.swift`, `FortuneWheelViewModel.swift` |
| Backend | `backend/src/app/api/minigames/shell-game/`, `backend/src/app/api/minigames/fortune-wheel/` |

## Related Docs

- `docs/rules/rules-swift.md` (animation gotchas), `docs/rules/rules-economy.md`
