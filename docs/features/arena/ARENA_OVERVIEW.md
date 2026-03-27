# Feature: Arena (PvP)

> **Status:** Complete
> **Owner:** Core gameplay
> **Last updated:** 2026-03-26
> **Source of truth:** `backend/src/app/api/pvp/` + `Hexbound/Hexbound/Views/Arena/`

---

## Overview

Арена — основная PvP-система. Игроки сражаются в ранговых матчах, зарабатывают ELO-рейтинг, получают награды. Revenge-система позволяет отыграться в течение 72 часов.

## User Value

Конкурентная игра, рейтинговое продвижение, лучшие награды за PvP.

## Systems Involved

| System | Role | Source file |
|--------|------|------------|
| Arena screen | UI: opponents, revenge, history | `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift` |
| PvP fight route | Combat execution | `backend/src/app/api/pvp/fight/route.ts` |
| PvP resolve route | Result resolution | `backend/src/app/api/pvp/resolve/route.ts` |
| PvP revenge route | Revenge matches | `backend/src/app/api/pvp/revenge/[id]/route.ts` |
| Combat engine | Turn-based battle | `backend/src/lib/game/combat.ts` |
| Matchmaking | Opponent selection | `backend/src/app/api/pvp/fight/route.ts` |
| Leaderboard | Ranking display | `Hexbound/Hexbound/Views/Leaderboard/LeaderboardDetailView.swift` |
| Admin PvP page | Config & monitoring | `admin/src/` |

## Key Files

- iOS Views: `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift`, `CombatDetailView.swift`, `CombatResultDetailView.swift`
- iOS VMs: `ArenaViewModel.swift`, `CombatViewModel.swift`
- iOS Models: `OpponentProfile.swift`, `PvPRank.swift`, `Character.swift` (contains `CombatStance` struct)
- Backend: `backend/src/app/api/pvp/fight/route.ts` (reference implementation)
- Game Logic: `backend/src/lib/game/combat.ts`, `balance.ts`, `progression.ts`
- Components: `StanceDisplayView.swift`, `UnifiedHeroWidget(.arena)`, `ArenaOpponentCard.swift`

## Game Design

- **ELO system:** Starting 1000, calibration phase, K-factor varies
- **Matchmaking:** ±10 levels, ±80% gear score, 3-phase cascade
- **Stance zones:** head/chest/legs, match bonus +15% DEF, miss bonus +5% OFF
- **Revenge:** 72h expiry, tracked separately
- **Stamina:** 1 stamina per fight
- **Free fights:** `AppConstants.freePvpPerDay` free fights, then stamina cost

## API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/api/pvp/fight` | Start PvP match (matchmaking + combat) |
| `POST` | `/api/pvp/resolve` | Resolve match, award ELO + rewards |
| `POST` | `/api/pvp/revenge/:id` | Start revenge match |
| `GET` | `/api/characters/:id/profile` | Opponent public profile |
| `GET` | `/api/leaderboard` | Ranked leaderboard |

## UI Layout (ArenaDetailView)

- Sticky: OrnamentalTitle + TabSwitcher (OPPONENTS / REVENGE / HISTORY)
- Scrollable: ActiveQuestBanner → UnifiedHeroWidget → PvP Stats Bar → LowHPBanner → StancePreview → Tab content
- Bottom: Refresh button (opponents tab only)

## UI States

- **Loading:** Skeleton cards
- **Empty:** "No opponents found" + refresh
- **Error:** Toast + retry
- **Success:** Opponent cards with fight buttons
- **Low HP:** Warning banner

## Dependencies

- Depends on: Combat system, Character model, Stamina system, Equipment
- Depended by: Achievements (PvP category), Leaderboard, Daily quests (pvp_wins)

## Related Docs

- Rules: `docs/rules/rules-combat-pvp.md`
- Combat deep-dive: `docs/06_game_systems/COMBAT.md`
- Balance: `docs/06_game_systems/BALANCE_CONSTANTS.md`
- Screen inventory: `docs/07_ui_ux/SCREEN_INVENTORY.md`
