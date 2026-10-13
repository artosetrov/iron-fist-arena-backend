# Sprint 3 — client reliability, 2026-09-15

Working tree only, not committed. **No Xcode on this machine — none of this has been compiled.**

---

## Five screens could not report a failure, and a failed refresh destroyed good data

Leaderboard, Shop, Dungeon Select, Achievements and Inventory all followed the same cache-first shape: show warm cache, refresh in the background. Each of their services caught its network error and returned `[]`. The view model then assigned *and cached* that empty array. One offline refresh therefore:

1. wiped good data off the screen,
2. persisted the emptiness, so it survived a relaunch, and
3. looked exactly like "you own nothing" — every one of those screens has an `ErrorStateView` that was unreachable, because `errorMessage` was only ever assigned `nil`.

Fixing five screens one at a time would have meant writing the same bug five ways, so the fix is one type.

### `Models/LoadOutcome.swift` (new)

```
case loaded(Value)   // the server answered — authoritative, empty or not
case skipped         // never ran (no character yet) — assign nothing, cache nothing
case failed(Error)   // keep whatever is on screen
```

`apply(assign:cache:setError:)` holds the rules in one place: assign and cache only on success, do nothing on skip, and on failure set the error while leaving the previous value **and the cache** untouched. A stale list the player can still read beats an empty one.

`userMessage` derives the player-facing string through `APIError.userMessage` (not `errorDescription`, which can carry decode and SQL detail) and returns nil for a 401 — session expiry is handled globally by the session-expired modal, and a local error page would render behind it.

`LeaderboardService`, `AchievementService`, `ShopService` and `InventoryService` now return `LoadOutcome`; all 23 call sites were updated, including the retry-toast self-calls and the two `HubView` prefetches, which now cache only a real success.

### An error is not automatically an error page

The first version of this fix made things worse: with `errorMessage` finally assigned, every screen's `if errorMessage != nil { ErrorStateView }` branch started firing, so a failed refresh replaced a readable list with a full-screen error. Before, it showed a stale list; after, a blank error page. The data was hidden either way.

Each view model now exposes `showsErrorState` — failed **and** nothing to show — and the five views branch on that. Dungeon Select needed its own answer: `dungeons` is seeded from `DungeonInfo.fallback` before the fetch, so it is never empty, and gating on it would have made that screen's error state unreachable all over again. It gates on `dungeonProgress`, which is empty exactly in the cold-start-plus-failure case.

`ErrorStateView.loadFailed` gained an optional `message`, so the reason is actually shown instead of "Something went wrong loading this content." The five untouched call sites still compile unchanged.

`InventoryService` now shows its failure toast only when there is no warm cache — a toast *and* an error page for one failed refresh is two interruptions for one event.

---

## The mine minigame no longer promises rewards it did not deliver

The summary showed `caughtGold` / `caughtGems` — the player's local tally of what fell into the basket. Since the server started deriving the reward from the share of spawned coins caught, that number could exceed what the account actually received: catch everything you see, miss 40% of spawns, get told "+150, +1 gem", be credited less.

The summary now reads `bonusGold` / `bonusGems` off the submit response. When the submit failed and there is no response, it says so — "Not saved — connection lost. Your mine keeps the gold; try collecting again." — instead of showing a reward that was never credited.

---

## Review

Two adversarial review passes over the diff. The first caught the error-page regression described above, plus: the missing-character path still cached `[]`, `userMessage` using the raw error string, and 401 painting a page behind the session modal. The second caught that the `LoadOutcome.swift` edit had silently not landed on disk — the enum still had two cases while three services already returned `.skipped`, which would have been a hard build break. All fixed and re-verified.

`project.pbxproj`: 342 `.swift` on disk, 342 in the Sources phase, no duplicates.

---

## What you need to do

1. **Build in Xcode.** Nothing here has been through a compiler.
2. `git add Hexbound/Hexbound/Models/LoadOutcome.swift`.
3. Worth a manual check with the network off: open Leaderboard / Shop / Inventory with warm cache, pull to refresh, and confirm the list stays and the screen does not blank.

## Still open on the client

- **Rating tiers are computed twice.** The server knows 8 tiers with divisions; `PvPRank.swift` re-derives 6 with different thresholds, so the leaderboard says "Silver II" and the arena says "Silver" on the same account. One source of truth means deleting the client derivation and taking the tier from the server.
- **Dungeon soft-lock.** `/dungeons/abandon` exists on the server and is never called from iOS, so a run left in one dungeon blocks every other one with no way out.
- **Battle Pass dies on a date.** The season is seeded for 90 days and nothing rolls it over; after that the building returns 404.
- **Dungeons 1–29 are not in the seeds at all**, four map slugs have no dungeon, and three seeded dungeons require levels above the cap.
