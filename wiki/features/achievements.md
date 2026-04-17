# Feature: Achievements

> Single-file map of every file that touches the Achievements system — 3-category, 21-entry persistent goal list with claimable rewards.

## One-liner

Players earn achievements across PvP / Progression / Ranking categories; progress accrues automatically from gameplay events and rewards are claimed on completion.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screen:** `Hexbound/Hexbound/Views/Achievements/AchievementsDetailView.swift` (3-tab layout: PvP / Progress / Ranking)
- **Hub building:** `building-achievements` — Achievements pavilion on city hub
- **Player action:** Hub → Achievements building → browse by category → tap to claim

## Backend

### Routes

- `GET  /api/achievements`               — `backend/src/app/api/achievements/route.ts` — list achievements with progress + claim state
- `POST /api/achievements/claim`         — `backend/src/app/api/achievements/claim/route.ts` — batch claim completed entries
- `POST /api/achievements/[key]/claim`   — `backend/src/app/api/achievements/[key]/claim/route.ts` — claim single achievement by key
- `GET  /api/admin/achievements`         — `backend/src/app/api/admin/achievements/route.ts` — admin view / tuning
- Cross-cutting hooks: `backend/src/app/api/pvp/fight/route.ts`, `/api/prestige/route.ts`, `/api/game/init/route.ts`, `/api/characters/[id]/route.ts` — fire `updateMultipleAchievements()` on relevant events

### Business logic

- `backend/src/lib/game/achievement-catalog.ts` — canonical 21-achievement catalog (keys, targets, rewards, categories)
- `backend/src/lib/game/achievements.ts` — `updateMultipleAchievements()` with `absolute: true` semantics for ratings/levels/streaks
- `backend/src/lib/game/achievement-claims.ts` — reward granting on claim

### Prisma models touched

- `Achievement` (line 932) — per-character per-key progress row, `@@unique([characterId, achievementKey])`
- `AchievementDefinition` (line 1084) — admin-tunable definitions table (parallel to catalog for live tuning)
- `Character` back-relation → `achievements`

### Balance constants

- Targets + rewards embedded in `achievement-catalog.ts` (not in `balance.ts`)

## iOS

### Views

- `Hexbound/Hexbound/Views/Achievements/AchievementsDetailView.swift` — main screen, 3 tabs `["PvP", "Progress", "Ranking"]` → `["pvp", "progression", "ranking"]`
- `Hexbound/Hexbound/Views/Achievements/AchievementCardView.swift` — card row with progress bar + claim CTA (4 rarity variants in Figma DS)

### ViewModel

- `Hexbound/Hexbound/Views/Achievements/AchievementsViewModel.swift` — state: list, category tab, pending claims

### Model

- `Hexbound/Hexbound/Models/Achievement.swift` — decoding model, matches backend response

### Services

- `Hexbound/Hexbound/Services/AchievementService.swift` — list + claim API wrapper, cache updater

### Cache

- `GameDataCache.achievements` — cached list, invalidated on claim

## Admin

- `admin/src/app/(dashboard)/achievements/achievements-client.tsx` — definition editor (title, target, reward, category)
- `admin/src/actions/achievement-definitions.ts` — server actions
- `admin/src/lib/achievement-definitions.ts` — shared logic

## Docs

- `docs/06_game_systems/GAME_SYSTEMS.md` — Achievement system overview
- `wiki/systems/achievements.md` — legacy wiki entry
- `CLAUDE.md` → "Achievement System (CRITICAL)" section — canonical rules

## Notable gotchas

- **Tracking coverage is mandatory.** Adding a catalog entry without a corresponding `updateMultipleAchievements()` call = achievement stuck at 0/N forever. No fire-on-signup logic.
- **`absolute: true` semantics.** Streaks/ratings/levels that can DECREASE must use `absolute: true`; otherwise decrement is silently dropped.
- **Category → tab mapping.** iOS tab order `["PvP", "Progress", "Ranking"]` maps to backend categories `["pvp", "progression", "ranking"]`. Mismatched enum = empty tab.
- **Dual catalog source.** `achievement-catalog.ts` (code-first, deploy-gated) AND `achievement_definitions` table (admin-tunable) exist in parallel — keep them aligned manually.
- **pvp/fight vs pvp/resolve hooks.** Both endpoints fire tracking — avoid double-counting when touching either.

## Tests / fixtures

- `backend/tests/lib/achievement-catalog.test.ts` — catalog shape + reward validity

## Related features

- [[pvp-combat]] — most achievement events fire from PvP endpoints
- [[shop]] — claim rewards include gold / gems
- [[quests]] — sibling goal system with per-period resets
