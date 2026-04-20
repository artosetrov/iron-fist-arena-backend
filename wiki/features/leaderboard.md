# Feature: Leaderboard

> Single-file map of every file that touches the global leaderboard — ELO rating ranking with search, player detail, revenge/challenge hooks.

## One-liner

Global ranked list of players by PvP rating; search, browse top, tap row to open player profile with Challenge / Message / AddFriend actions.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Leaderboard/LeaderboardDetailView.swift` — main ranked list
  - `Hexbound/Hexbound/Views/Leaderboard/LeaderboardPlayerDetailSheet.swift` — tap a row → opponent profile modal
- **Player action:** Hub → Leaderboard building → scroll / search / tap row

## Backend

### Routes

- `GET  /api/leaderboard`         — `backend/src/app/api/leaderboard/route.ts` — paginated top-N + current player rank
- `GET  /api/leaderboard/search`  — `backend/src/app/api/leaderboard/search/route.ts` — search by character name

### Business logic

- `backend/src/lib/game/leaderboard.ts` — query builder, rank calc, cached top-N
- Query reads `Character` ordered by `rating` desc with filters (active, non-guest, etc.)

### Prisma models touched

- `Character` — primary source (rating, name, class, level, prestige)
- No dedicated leaderboard table — live query with index on `rating`

## iOS

### Views

- `Hexbound/Hexbound/Views/Leaderboard/LeaderboardDetailView.swift` — host screen, list + search bar
- `Hexbound/Hexbound/Views/Leaderboard/LeaderboardRowView.swift` — single row (2 Figma variants: self/other)
- `Hexbound/Hexbound/Views/Leaderboard/LeaderboardPlayerDetailSheet.swift` — opponent profile modal reusing `IntegratedCharacterCard`

### ViewModel

- `Hexbound/Hexbound/Views/Leaderboard/LeaderboardViewModel.swift` — list state, search debounce, pagination

### Services

- `Hexbound/Hexbound/Services/LeaderboardService.swift` — fetch + search wrapper

### Cache

- `GameDataCache.leaderboardTop` — top-N page cached briefly for hot-reload

## Admin

- No dedicated leaderboard admin page today.
- `admin/src/app/(dashboard)/matches/page.tsx` — PvP match history and rating-delta review surface
- `admin/src/app/(dashboard)/players/[id]/page.tsx` — account/player drill-down for adjacent moderation and purchase review

## Docs

- `docs/06_game_systems/COMBAT.md` — ELO mechanics tie-in
- `docs/02_product_and_features/GAME_SYSTEMS.md` — ranking system overview

## Notable gotchas

- **Live-query pressure.** Global sort-by-rating needs an index on `Character.rating` — verify index exists or scan will cost.
- **Guest exclusion.** Leaderboard filters out guest accounts / banned / soft-deleted — changing filter = rank shift visible to users.
- **Tap-row actions work.** Challenge / Message / AddFriend from leaderboard row route through the shared [[opponent-profile]] surface.
- **Search is name-prefix.** Full-text search is not implemented — just `startsWith` (case-insensitive). Don't promise substring matching.
- **Achievement hook.** `ranking` category achievements fire on PvP resolve based on rank milestones reached.
- **No admin rating-adjust tool today.** Rating review exists in admin, but there is no standalone manual leaderboard/rating editor page in the live dashboard.

## Tests / fixtures

- No dedicated leaderboard backend test file is checked in today
- Adjacent PvP/rating review coverage lives in:
  - `backend/tests/api/pvp-history.test.ts`
  - `backend/tests/api/pvp-resolve.test.ts`

## Related features

- [[pvp-combat]] — source of rating changes
- [[social]] — AddFriend / Message actions from leaderboard row
- [[achievements]] — Ranking tab category
