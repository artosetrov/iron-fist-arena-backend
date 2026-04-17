# Feature: Daily Login

> Single-file map of every file that touches the daily-login reward system — calendar-based streak rewards for launching the app.

## One-liner

On first launch of each new game-day, players see a popup awarding the day's reward and advancing their streak position.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupView.swift` — auto-shown modal on first session of the day
  - `Hexbound/Hexbound/Views/DailyLogin/DailyLoginDetailView.swift` — full calendar view (viewable any time)
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

- `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupView.swift` — celebration modal, single-day focus
- `Hexbound/Hexbound/Views/DailyLogin/DailyLoginDetailView.swift` — full calendar grid

### ViewModel

- `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupViewModel.swift` — popup visibility gating, claim action

### Services

- Reuses `APIClient` directly (no dedicated service file) OR `DailyLoginService.swift` if present

### Cache

- `GameDataCache.dailyLogin` — calendar state + today's claim flag

## Admin

- `admin/src/app/(dashboard)/daily-login/` — calendar reward editor (if present)

## Docs

- `docs/02_product_and_features/ECONOMY.md` — daily-login rewards are a gold/gem source
- `docs/06_game_systems/GAME_SYSTEMS.md` — retention systems

## Notable gotchas

- **Day-boundary.** Server-authoritative UTC comparison. If client-side time check disagrees, UI must trust server response, not device clock.
- **Streak break.** Skipping a day resets position to 1 (not to 0) — verify in `daily-login.ts`.
- **Popup gating.** Show popup ONLY on first session of the day. `GameDataCache.dailyLogin.todayClaimed` must gate re-display.
- **Claim idempotency.** `POST /claim` must be safe on double-tap — server returns same payload if already claimed today.
- **Calendar length.** Typical calendar is 7 or 30 days — rotate position on loop or stop at max (check config).

## Tests / fixtures

- `backend/src/__tests__/daily-login/*` (if present)

## Related features

- [[shop]] — daily-login rewards include gold/gems
- [[session-summary]] — popup is one of the "first-launch" UI slots; priority matters
- [[events]] — seasonal events can override/boost calendar rewards
