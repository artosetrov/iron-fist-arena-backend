# Feature: Session Summary

> Single-file map of every file that touches the "since-you-last-played" session summary screen — what happened offline (rewards accrued, rating changes, mine/quest deltas).

## One-liner

On app foreground after an idle period, players see a Session Summary: combat since last login, rewards accrued, quest progress made by offline/background systems, rating delta. Uses cached per-character baselines to compute the diff server-side.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screen:** `Hexbound/Hexbound/Views/SessionSummary/SessionSummaryView.swift` — modal / hub-entry presentation
- **Trigger:** App foreground after idle threshold OR explicit tap from hub
- **Player action:** Dismiss OR claim aggregated rewards

## Backend

### Routes

- `GET  /api/session-summary`   — `backend/src/app/api/session-summary/route.ts` — diff-computed summary since `lastSeenAt`

### Business logic

- The route stitches together per-domain deltas: combat (wins/losses/rating), gold mine collected, quest progress, daily quest state, new mail, etc.
- Uses the character's `lastSeenAt` (or analogous) timestamp as the baseline anchor
- After presenting, client bumps the baseline so subsequent summaries don't double-count

### Prisma models touched

- `Character` — reads latest state + updates last-seen anchor
- Read-only touches: `PvpMatch`, `DailyQuest`, `MailRecipient`, `GoldMineSession`, etc.

## iOS

### Views

- `Hexbound/Hexbound/Views/SessionSummary/SessionSummaryView.swift` — host with multiple cards:
  - `combatCard(summary:)` — wins/losses/rating
  - `rewardsCard(summary:)` — accrued gold/gems/XP
  - `questCard(summary:)` — quest progress delta
  - `ratingCard(summary:)` — rating / rank movement

### ViewModel

- `Hexbound/Hexbound/Views/SessionSummary/SessionSummaryViewModel.swift` — fetches `SessionSummaryData` from `/api/session-summary`
- Model: `SessionSummaryData: Codable` (line 3)

### Services

- No dedicated service — calls `/api/session-summary` directly from the ViewModel via `APIClient`

### Cache

- Not cached long-term; fetched per foreground event to stay authoritative

## Admin

- No admin controls; summary is derived state

## Docs

- `docs/03_backend_and_api/API_REFERENCE.md` — `/session-summary` route reference

## Notable gotchas

- **Baseline anchor is load-bearing.** The summary is a DIFF since a specific timestamp. Advancing the anchor too early (before user sees the summary) = user misses the screen on next foreground.
- **Read-only by design.** Summary must NOT double-grant rewards that were already credited by their owning system. Rewards accrued (gold mine collection, quest claims) remain owned by those systems; summary just REPORTS them.
- **Idempotent fetch.** Repeated calls within the same session should return the same data — don't re-anchor on every GET.
- **Domain churn.** Every new feature that accrues offline progress (new minigame, new event type) needs a corresponding slice in the summary response. Silent omission = player never learns they earned something.
- **Trigger threshold.** Show the summary only when the idle period is meaningful — thrashing foreground/background should NOT pop the modal every 30 seconds.

## Tests / fixtures

- No dedicated session-summary backend test file is checked in today

## Related features

- [[gold-mine]] — biggest source of offline gold → appears in rewards card
- [[daily-login]] — separate modal, NOT session-summary
- [[mail]] — new mail count surfaces in summary, but doesn't claim rewards
- [[quests]] — quest progress delta shown, claim happens in quests screen
- [[pvp-combat]] — combat deltas since last session
