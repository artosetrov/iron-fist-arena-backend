# Feature: Arena (PvP)

> **Status:** In production
> **Owner:** Core gameplay
> **Last updated:** 2026-05-06
> **Source of truth:** `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift`, `backend/src/app/api/pvp/`, `wiki/features/pvp-combat.md`

---

## Overview

Arena is the live ranked PvP entry surface. Players browse recent opponents,
launch fights, revisit revenge/history tabs, adjust combat stance from the
same screen, and transition into either classic combat fallback or the newer
Interactive Combat flow.

## User Value

- Competitive progression through PvP rating
- Quick access to new opponents, revenge matches, and recent match history
- Direct stance editing before queueing into a fight

## Systems Involved

| System | Role | Source file |
|--------|------|-------------|
| Arena screen | Hero widget, compact rating summary, stance CTA, tabs | `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift` |
| Arena VM | Loads opponents, history, revenge data, fight preparation | `Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift` |
| PvP opponents | Carousel list for the Arena screen | `backend/src/app/api/pvp/opponents/route.ts` |
| PvP fight | Classic compatibility start path | `backend/src/app/api/pvp/fight/route.ts` |
| Interactive start | Newer Interactive Combat match start | `backend/src/app/api/pvp/match/start/route.ts` |
| PvP prepare | Pre-fight lock / validation | `backend/src/app/api/pvp/prepare/route.ts` |
| PvP revenge | Rematch against prior opponent | `backend/src/app/api/pvp/revenge/route.ts` |
| PvP history | Recent results for history/revenge tabs | `backend/src/app/api/pvp/history/route.ts` |
| Leaderboard | Full rank table / drill-down destination | `Hexbound/Hexbound/Views/Leaderboard/LeaderboardDetailView.swift` |
| Admin review | Match review, player drill-down, adjacent economy context | `admin/src/app/(dashboard)/matches/page.tsx`, `admin/src/app/(dashboard)/players/page.tsx`, `admin/src/app/(dashboard)/players/[id]/page.tsx`, `admin/src/app/(dashboard)/economy/page.tsx` |

## Key Files

- iOS views:
  - `Hexbound/Hexbound/Views/Arena/ArenaDetailView.swift`
  - `Hexbound/Hexbound/Views/Arena/ArenaCarouselView.swift`
  - `Hexbound/Hexbound/Views/Arena/ArenaOpponentCard.swift`
  - `Hexbound/Hexbound/Views/Arena/ArenaComparisonSheet.swift`
- iOS models/services:
  - `Hexbound/Hexbound/Views/Arena/ArenaViewModel.swift`
  - `Hexbound/Hexbound/Services/PvPService.swift`
  - `Hexbound/Hexbound/Models/Character.swift`
- Backend:
  - `backend/src/app/api/pvp/opponents/route.ts`
  - `backend/src/app/api/pvp/fight/route.ts`
  - `backend/src/app/api/pvp/match/start/route.ts`
  - `backend/src/app/api/pvp/prepare/route.ts`
  - `backend/src/app/api/pvp/revenge/route.ts`
  - `backend/src/app/api/pvp/history/route.ts`
  - `backend/src/app/api/pvp/resolve/route.ts`
  - `backend/src/lib/game/combat.ts`
  - `backend/src/lib/game/elo.ts`

## Current Live Arena Layout

- Sticky header: title + inline tab switcher (`OPPONENTS / REVENGE / HISTORY`)
- Scrollable body:
  - quest banner (when present)
  - hero widget
  - compact PvP rating summary widget
  - dedicated combat stance CTA
  - low-HP potion banner (when applicable)
  - tab content
- Opponents tab: carousel + fight CTA
- Revenge tab: recent revenge candidates
- History tab: recent match log

This is no longer the older stance-preview-first layout. The summary slot now
belongs to the compact PvP rating widget, while stance editing stays available
as a smaller dedicated CTA beneath it.

## Gameplay Rules

- Rating is ELO-style and resolves server-side
- Matchmaking uses the live widened search model described in `wiki/features/pvp-combat.md`
- Revenge is its own server-backed flow, not just a local UI filter
- Arena can still fall back through the classic fight path when that
  compatibility route is needed
- Interactive Combat is the primary modern combat branch behind the Arena flow,
  but Arena remains the launcher surface for both modes

## API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/pvp/opponents` | Fetch Arena opponent list |
| `POST` | `/api/pvp/fight` | Classic compatibility fight start |
| `POST` | `/api/pvp/match/start` | Start interactive PvP match |
| `POST` | `/api/pvp/prepare` | Validate/lock combat state before fight |
| `POST` | `/api/pvp/revenge` | Start revenge rematch |
| `GET` | `/api/pvp/history` | Fetch recent matches |
| `POST` | `/api/pvp/resolve` | Resolve match and award rating/rewards |
| `GET` | `/api/leaderboard` | Full ranking table |

## UI States

- **Loading:** skeleton/loading shell while Arena data is not ready
- **Empty opponents:** no available opponents + refresh path
- **Revenge/history empty:** tab-specific empty states
- **Low HP:** warning banner and potion guidance
- **Success:** compact rating summary, stance CTA, opponent/revenge/history content

## Dependencies

- Depends on: PvP combat, stamina, character/equipment stats, leaderboard
- Adjacent systems: tutorial stance anchor, revenge history, admin match review
- Depended by: achievements, quests, rating progression, social challenge context

## Related Docs

- `wiki/features/pvp-combat.md`
- `docs/06_game_systems/COMBAT.md`
- `docs/06_game_systems/BALANCE_CONSTANTS.md`
- `docs/07_ui_ux/SCREEN_INVENTORY.md`
- `qa-reports/2026-05-04-arena-rating-widget-proposal.md` — historical restore proposal, not the live source of truth
