# Feature: Daily Login

> Single-file map of every file that touches the daily-login reward system — calendar-based streak rewards for launching the app.

## One-liner

On first launch of each new game-day, players see a popup awarding the day's reward and advancing their streak position.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/DailyLogin/DailyLoginDetailView.swift` — the Daily Tribute: root overlay (`AppState.showDailyLoginPopup`, BUG-53), auto-shown on the first session of the day and from the hub tile
  - `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupView.swift` — legacy modal, not mounted anywhere
- **Player action:** None (auto-triggers on launch) OR Hub → Daily Login calendar

## Backend

### Routes

- `GET  /api/daily-login`        — `backend/src/app/api/daily-login/route.ts` — current streak + today's reward + calendar
- `POST /api/daily-login/claim`  — `backend/src/app/api/daily-login/claim/route.ts` — claim today's reward, advance streak

### Business logic

- `backend/src/lib/game/daily-login.ts` — streak rotation, day-boundary check, reward grant
- Day-boundary reference: server UTC midnight (or configured zone) — NOT client time

### Prisma models touched

- `DailyLoginReward` (line 877) — per-character streak state: position in calendar, last claim date
- `Character` back-relation → `dailyLoginRewards`

### Balance constants

- `backend/src/lib/game/balance.ts` → `DAILY_LOGIN_CALENDAR` — ordered list of per-day rewards (or embedded in `daily-login.ts`)

## iOS

### Views

- `Hexbound/Hexbound/Views/DailyLogin/DailyLoginDetailView.swift` — "A · chests of the week" (2026-11-04): DAY N OF 7 + streak pill over the treasure vault (`DescentBackdrop`, night grade), today's chest, the week of seven chests, OPEN THE CHEST / TO THE CASTLE, "Tomorrow: … · wooden chest"
- `Hexbound/Hexbound/Views/DailyLogin/DailyTributeViews.swift` — `TributeChestStage` (rocks until tapped; opened: rays, burst, reward rises), `TributeWeekStrip`, `TributeStreakPill`, chest tiers (days 1–3 wood, 4–5 iron, 6–7 gold — `rush2-chest-*`, presentation only)
- `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupView.swift` — legacy, unused

### ViewModel

- `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupViewModel.swift` — popup visibility gating, claim action

### Services

- `Hexbound/Hexbound/Services/DailyLoginService.swift` — fetches daily-login status and claim payloads, then applies authoritative reward state to `AppState`

### Cache

- `GameDataCache.dailyLogin` — calendar state + today's claim flag

## Admin

- `admin/src/app/(dashboard)/daily-login/page.tsx` — live daily-login rewards page
- `admin/src/app/(dashboard)/daily-login/daily-login-client.tsx` — 7-day reward-cycle editor backed by `daily_login_rewards`

## Docs

- `docs/02_product_and_features/ECONOMY.md` — daily-login rewards are a gold/gem source
- `docs/02_product_and_features/GAME_SYSTEMS.md` — high-level retention/engagement systems overview

## Notable gotchas

- **Day-boundary.** Server-authoritative UTC comparison. If client-side time check disagrees, UI must trust server response, not device clock.
- **Streak break.** Skipping a day resets position to 1 (not to 0) — verify in `daily-login.ts`.
- **Popup gating.** Show popup ONLY on first session of the day. `GameDataCache.dailyLogin.todayClaimed` must gate re-display.
- **Claim idempotency.** `POST /claim` must be safe on double-tap — server returns same payload if already claimed today.
- **One day number.** Title, chest, week and reward card all read `vm.displayDay`. Before the claim it is the day the server will grant (`expectedClaimDay`: after a missed day that is day 1, not the stored pointer).
- **Chest first, card second.** The tribute reward card opens `DailyLoginPopupViewModel.chestOpenBeat` (0.9 s) after the tap, so the lid, rays and rising reward play first. A server-side swap (streak reset) replaces the waiting card.
- **Labels are spelled out.** "1 Stamina Potion", not "1 S. Potion" (`balance.ts` + the iOS fallback). If admin overrides `daily_login_rewards`, fix the names there too. Potions show `stamina_potion_*`, not the stamina bolt.
- **Calendar length.** Live admin/config today is a 7-day reward cycle. Keep docs/UI aligned with the 7-entry editor unless the backend/admin surface is widened together.

## Tests / fixtures

- No dedicated backend daily-login test file is checked in today; verify runtime behavior against the two live routes plus `daily-login.ts`.

## Related features

- [[shop]] — daily-login rewards include gold/gems
- [[session-summary]] — popup is one of the "first-launch" UI slots; priority matters
- [[events]] — seasonal events can override/boost calendar rewards
