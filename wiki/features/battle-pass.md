# Feature: Battle Pass

> Single-file map of every file that touches the Battle Pass — seasonal XP track with free + premium tiers, weekly challenges, season-end summary.

## One-liner

Players earn Battle Pass XP from play; climb a 50-tier track with free + premium reward lanes; weekly challenges drop bonus XP; season-end summary shows total progress + unlocked rewards.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/BattlePass/BattlePassDetailView.swift` — main track screen
  - `Hexbound/Hexbound/Views/BattlePass/SeasonSummaryModalView.swift` — season-end wrap
- **Player action:** Hub → Battle Pass building → browse track → claim reward OR buy premium

## Backend

### Routes

- `GET  /api/battle-pass`                      — `backend/src/app/api/battle-pass/route.ts` — current pass state: track, XP, premium flag
- `POST /api/battle-pass/claim`                — `backend/src/app/api/battle-pass/claim/route.ts` — claim single or batch tier reward
- `POST /api/battle-pass/buy-premium`          — `backend/src/app/api/battle-pass/buy-premium/route.ts` — gem-purchase premium lane
- `GET  /api/battle-pass/weekly-challenges`    — `backend/src/app/api/battle-pass/weekly-challenges/route.ts` — current week's challenge set + progress

### Business logic

- `backend/src/lib/game/battle-pass.ts` — XP accrual, tier calc, reward granting
- `backend/src/lib/game/weekly-challenges.ts` — weekly challenge catalog + rotation logic
- Cross-cutting: `backend/src/app/api/pvp/resolve`, `/api/dungeons/complete`, `/api/minigames/*` — fire BP XP on events

### Prisma models touched

- `BattlePass` (line 762) — active season row, XP + premium flag per character
- `BattlePassReward` (line 780) — tier + lane + reward definition
- `BattlePassClaim` (line 797) — per-(pass, tier, lane) claim record
- `WeeklyChallengeProgress` (line 814) — per-character per-week progress

### Balance constants

- `backend/src/lib/game/balance.ts` → `BATTLE_PASS_XP_PER_TIER`, `BATTLE_PASS_TIERS`, `WEEKLY_CHALLENGE_XP_BONUS` — values live in the catalog / balance module

## iOS

### Views

- `Hexbound/Hexbound/Views/BattlePass/BattlePassDetailView.swift` — track view, reward nodes, claim CTA
- `Hexbound/Hexbound/Views/BattlePass/BPRewardNodeView.swift` — single reward tile (4 variants in Figma DS)
- `Hexbound/Hexbound/Views/BattlePass/SeasonSummaryModalView.swift` — end-of-season recap modal

### ViewModel

- `Hexbound/Hexbound/Views/BattlePass/BattlePassViewModel.swift` — track state, claim queue, premium CTA

### Services

- `Hexbound/Hexbound/Services/BattlePassService.swift` — API wrapper
- `Hexbound/Hexbound/Services/BattlePreloader.swift` — prefetches BP assets on launch to avoid scroll stutter

### Cache

- `GameDataCache.battlePass` — full track + claim state, invalidated on claim

## Admin

- `admin/src/app/(dashboard)/battle-pass/page.tsx` — battle-pass rewards/admin page
- `admin/src/app/(dashboard)/battle-pass/battle-pass-client.tsx` — live reward and track editing surface

## Docs

- `docs/02_product_and_features/ECONOMY.md` — BP is a gem sink (premium purchase)
- `docs/06_game_systems/BALANCE_CONSTANTS.md` — XP curve + tier counts

## Notable gotchas

- **Server-authoritative XP.** Client NEVER computes BP XP — backend accrues on event. iOS just re-fetches.
- **Claim idempotency.** `(pass, tier, lane, characterId)` must be unique — double-tap CTA must not double-grant.
- **Premium purchase is gem sink only.** No real-money IAP here — gems flow from `/api/iap/*`.
- **Weekly challenge rotation.** `WeeklyChallengeProgress` rows are per-week-key — new week = new rows. Don't reuse old rows.
- **Season end timing.** Summary modal triggers once per character per season — guard by `seasonId` flag to avoid showing twice.

## Tests / fixtures

- `backend/tests/api/battle-pass-claim.test.ts` — claim-path contract coverage
- `backend/tests/prisma/battle-pass-reward-repair.test.ts` — reward repair/backfill safety coverage
- No broader dedicated `battle-pass/*` route suite is checked in today beyond these focused tests

## Related features

- [[quests]] — daily quests feed BP XP
- [[pvp-combat]] — wins feed BP XP + some weekly challenges
- [[shop]] — premium BP purchase uses gems from shop
