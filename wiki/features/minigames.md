# Feature: Minigames (Tavern hub + Shell Game + Fortune Wheel)

> Single-file map of every file that touches the secondary minigame suite — Tavern hub, Shell Game (bet-pick-reveal), Fortune Wheel (daily/gem spin). Gold Mine and Dungeon Rush are MUCH larger and live in their own feature files.

## One-liner

Tavern building surfaces three minigames: Shell Game (guess-the-shell betting), Fortune Wheel (daily free spin + paid gem spin), and entry to Dungeon Rush. Gold Mine is its own building but shares the `MinigameSession` backend table.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Minigames/TavernDetailView.swift` — hub of the 3 minigames
  - `Hexbound/Hexbound/Views/Minigames/ShellGameDetailView.swift` — shell game
  - `Hexbound/Hexbound/Views/Minigames/FortuneWheelDetailView.swift` — wheel spin
  - `Hexbound/Hexbound/Views/Minigames/TreasureRewardOverlay.swift` — shared reveal overlay
  - `Hexbound/Hexbound/Views/Minigames/MinigameCatchEffect.swift` — shared fx layer
- **Player action:** Hub → Tavern → pick game OR Hub → Gold Mine building (separate, see [[gold-mine]]) OR Hub → Dungeon Rush building (see [[dungeon-rush]])

## Backend

### Routes

#### Shell Game
- `POST /api/minigames/shell-game/start`  — `backend/src/app/api/minigames/shell-game/start/route.ts` — create session, seed secret
- `GET  /api/minigames/shell-game/status` — poll active session
- `POST /api/minigames/shell-game/guess`  — submit shell choice
- `POST /api/minigames/shell-game/play`   — legacy all-in-one play endpoint

#### Fortune Wheel
- `GET  /api/minigames/fortune-wheel/status` — today's free-spin availability + gem-spin cost
- `POST /api/minigames/fortune-wheel/spin`   — execute spin (free or gem)

#### Gold Mine (documented separately, lives in same namespace)
- See [[gold-mine]] for the 9 Gold Mine routes

### Business logic

- `backend/src/lib/game/balance.ts` — Shell Game bet tiers, Fortune Wheel reward distribution, gem cost
- Per-game resolvers live in-route

### Prisma models touched

- `MinigameSession` (line 695, `@@map("minigame_sessions")`) — shared session row for all minigames
  - `gameType: String` — discriminator (`shell_game`, `fortune_wheel`, `gold_mine_rush`)
  - `betAmount`, `secretData: Json?` (seed for shell positions, etc.)
  - `status`: `active` / `resolved` / `expired`
  - `result: Json?` — full result payload
  - Gold-Mine-specific fields nullable (lines 706–714)
- `Character.minigameSessions` (line 407) — relation

### Seed / server authority

- **Shell Game:** secret position is stored in `secretData` server-side at `/start`; client NEVER receives it until `/guess` resolves
- **Fortune Wheel:** RNG happens in `/spin`; client shows animation but authoritative reward comes back in the response
- **Quest hook:** `QuestType.shell_game_play` increments on a resolved shell session — see [[quests]]

## iOS

### Views

- `TavernDetailView.swift` — grid of minigame tiles
- `ShellGameDetailView.swift` + `ShellGameViewModel.swift` — shell UI + bet input + reveal
- `FortuneWheelDetailView.swift` + `FortuneWheelViewModel.swift` — wheel spin UI
- `TreasureRewardOverlay.swift` — shared reward reveal overlay
- `MinigameCatchEffect.swift` — particle / catch fx reused across games
- Mine-specific shared components: `MineResourceHeader.swift`, `MineClaimRewardView.swift` (used by Gold Mine, kept together in this folder historically)

### Services

- No shared `MinigameService.swift` today.
- `Hexbound/Hexbound/Views/Minigames/ShellGameViewModel.swift` — shell-game API calls live directly in the view model
- `Hexbound/Hexbound/Views/Minigames/FortuneWheelViewModel.swift` — fortune-wheel API calls live directly in the view model

### Cache

- `GameDataCache.dailyMinigameState` — "did you play today" flags for the Fortune Wheel free-spin
- No global cache for Shell Game — stateless (session-per-play)

## Admin

- `admin/src/app/(dashboard)/economy/` — adjust reward distributions / bet tiers via config
- `admin/src/app/(dashboard)/config/` — feature flags and event overrides for minigames

## Docs

- `docs/06_game_systems/GAME_SYSTEMS.md` — minigame overview
- `docs/02_product_and_features/ECONOMY.md` — sinks and payouts for shell/wheel

## Notable gotchas

- **One table, many games.** `MinigameSession.gameType` distinguishes. Always filter by `gameType` in queries — `WHERE characterId = ? AND gameType = 'shell_game'`.
- **Server authority.** Secret data and RNG seed NEVER flow to client before resolution. Client just renders animations.
- **Day-bound free spin.** Fortune Wheel has one free spin per UTC day; subsequent spins cost gems. Day-rollover reset is server-side.
- **Shell bet tiers.** Bet amount is constrained to a server whitelist; client must not pass arbitrary amounts — backend rejects unknown tiers.
- **Quest hook gotcha.** Quest enum is `shell_game_play`, NOT `shell_play` or `shellgame`. See [[quests]].
- **Sessions can expire.** `MinigameSession.status = 'expired'` for abandoned sessions; don't rely on "active" forever.
- **Gold Mine is separate UX.** Even though it shares `MinigameSession`, Gold Mine is its own building with its own mine-slot system. Tavern does NOT surface Gold Mine.
- **Dungeon Rush is separate UX.** Same principle — own building, shares the session table but has its own state machine (see [[dungeon-rush]]).

## Tests / fixtures

- `backend/tests/api/shell-game-start.test.ts`
- `backend/tests/api/shell-game-guess.test.ts`
- `backend/tests/api/shell-game-play-deprecated.test.ts`
- No single broad `minigames/*` backend suite is checked in today; coverage is per-route

## Related features

- [[gold-mine]] — larger cousin, shares `MinigameSession` but has own building + own loop
- [[dungeon-rush]] — larger cousin, shares `MinigameSession` + own state machine
- [[quests]] — shell_game_play fires on shell resolve
- [[daily-login]] — parallel daily engagement mechanic, not a minigame
- [[battle-pass]] — wheel/shell wins grant BP XP
