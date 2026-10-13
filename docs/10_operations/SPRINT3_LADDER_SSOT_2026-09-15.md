# Sprint 3 — one PvP ladder, 2026-09-15

Working tree only, not committed. **No Xcode on this machine — none of the Swift has been compiled.**

Backend: 67 files / 430 tests green. `check_schema_drift.py` OK, `check_tracked_secrets.py` OK, backend/admin schemas in sync, `tsc --noEmit` clean in both apps. New: `check_ladder_parity.py`, wired into CI.

**One migration must be applied to prod before deploying the backend.**

---

## The same account had two ranks

The server placed a rating on an 8-tier × 3-division ladder — `backend/src/lib/game/tier.ts`, Silver starting at 750 — and attached the result to leaderboard entries only. Every other screen got a bare `pvpRating`, so the client classified it itself, in `PvPRank.swift`: six tiers, no divisions, Silver at 1200.

A player at 1000 rating read **Silver II** on the leaderboard and **Bronze** on the arena badge one screen away. Both numbers came from the same field. This also violates the root `CLAUDE.md` invariant — *shared gameplay rules must live in backend/runtime contracts, not be rederived separately in admin/iOS*.

Counting the copies as I went, the ladder was written down six times: `tier.ts`, `PvPRank.swift`, a third set of colour thresholds in `DarkFantasyTheme.rankColor(for:)`, a fourth colour map in `TierBadge`, a fifth in `RankUpCeremonyView`, and the rank achievement targets. Plus an admin panel that edited floors nothing read.

### The contract, not the answer

Attaching a resolved tier to every payload carrying a rating would have meant a dozen endpoints and their Swift models. The ladder itself is the smaller contract:

```
/api/game/init → config.pvpLadder → PvPLadder.current
```

`ladderContract()` serializes the tier table — key, display name, floor, bound, division count — plus the division labels and the Challenger rule (cutoff, and which tier it promotes out of, stated rather than assumed). The client renders it and holds no thresholds. `PvPLadder.fallback` exists only for the cold start before the first init answers.

`PvPRank` went from a `String`-backed enum with a `fromRating` table to a value the ladder produces. The tier→symbol and tier→colour maps live in one place each, so `TierBadge`, the inline arena pills and the ceremony can no longer look like three different games. Bronze and Silver had also shared a glyph, and Challenger wore Gold's crown; all eight are distinct now.

I ported both classifiers to a scratch script and compared them across ratings −500…6000 on five different ladders, including deliberately uneven tier widths: no mismatches in tier, division, label or sort index.

## The admin panel was editing nothing

`pvp_ranks.bronze … grandmaster` have been editable in the balance panel the whole time, described as "ELO thresholds that define visible ladder tiers". `tierFromRating` never read them. An operator could move Gold to 1400, see it saved, and change nothing anywhere in the game.

They are live now: `resolveTierRanges()` applies the stored floors, re-stitches the tier bounds, and every consumer — leaderboard, init payload, iOS — reads the resolved ladder. `PVP_RANKS` in `balance.ts` is derived from `tier.ts` rather than typed out again.

Live floors mean a floor can be wrong, so all three write paths now refuse a set that cannot form a ladder — **with the reason**:

| Path | What it refuses |
|---|---|
| config `PUT` / `POST` | the merged ladder (stored floors + this save) out of order, or not starting at 0 |
| config `DELETE` | removing one override where the remaining floors would then be out of order — delete Gold with Silver at 1600 and Gold snaps back to 1500, below Silver |
| snapshot restore | rolling back to a snapshot whose `pvp_ranks` rows predate the keys being live |

Rejecting silently would have been worse than not validating: `resolveTierRanges` falls back to the frozen ladder, which from the panel is indistinguishable from a save that worked and did nothing — exactly the bug being fixed.

Two smaller things that would have reintroduced it:

- The config value is a JSON column. A floor stored as the string `"1400"` read back as 1400 in the validator and was skipped as non-numeric by the ladder. One shared coercion (`asTierFloor`) now, and the endpoint normalizes what it stores.
- Next.js replaces the message of anything thrown out of a server action in a production build with an opaque digest. `batchUpdateBalanceConfigs` returns the reason as data instead, so the operator reads which floor and why. It also no longer leaves an "Auto-backup before balance update" snapshot behind for a save that was refused.

## The Silver achievement unlocked at Silver I

`rank_silver` had target 1200 — Silver I on the current ladder. It is the same defect that was corrected by hand for Diamond (1800 → 3000) and Grandmaster (2200 → 4250) in v3 and missed for Silver at the time, which is the argument for deriving them: they are now `minRatingForTier('silver')` and friends. The description string in `/api/achievements` that restated "(1,200 rating)" reads the floor too.

These follow the *frozen* floors, not an operator's live overrides: achievement rows carry a target copied at creation, so a live threshold would mean rows created before and after an edit disagreeing about what "Silver" costs. Moving a floor is a migration, and there is one.

## `check_ladder_parity.py`

Two copies of the numbers necessarily remain — the Swift cold-start fallback and the admin panel's displayed defaults — because neither can import from `tier.ts`. The script compares them, plus the admin's rank achievement targets, and fails CI on any disagreement. Verified it fails on a shifted floor, a wrong admin default, a missing tier and a stale achievement target.

---

## What you need to do

1. **Apply `20260915_rank_achievement_targets` to prod via Supabase MCP before deploying.** It realigns `achievement_definitions.target` and `achievements.target` for the four rank achievements and completes rows that now clear their target. Safe to re-run; lowering a target can only complete an achievement, never un-complete one.
2. **Build in Xcode.** Nothing here has been near a compiler.
3. `git add Hexbound/Hexbound/Models/PvPLadder.swift backend/src/lib/game/ladder-config.ts backend/tests/lib/tier-ladder.test.ts scripts/check_ladder_parity.py backend/prisma/migrations/20260915_rank_achievement_targets`
4. Worth checking by hand once built: a character around 1000 rating should read the same tier on the arena badge, the hero card and the leaderboard row.

## Notes

- `RankUpCeremonyView` has no call sites anywhere in the app. Its tier colours and glyph were fixed along with everything else, but nothing exercises them — worth deciding whether the ceremony is meant to ship.
- `TierBadge.init(rank:size:)` has no caller yet. It is the intended way to render a resolved rank; the leaderboard row uses the string initializer because the server attaches `tierKey`/`division` to those entries directly.
- The client badge on a cold start uses the bundled fallback until `/api/game/init` lands. With edited floors that is a brief disagreement on first launch only.

## Still open on the client

- **Dungeon soft-lock.** `/dungeons/abandon` exists on the server and is never called from iOS, so a run left in one dungeon blocks every other one with no way out.
- **Battle Pass dies on a date.** The season is seeded for 90 days and nothing rolls it over; after that the building returns 404.
- **Dungeons 1–29 are not in the seeds at all**, four map slugs have no dungeon, and three seeded dungeons require levels above the cap.
