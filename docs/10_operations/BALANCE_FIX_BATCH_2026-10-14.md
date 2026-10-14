# Balance fix batch — 2026-10-14

Follows the 2026-10-14 balance audit ("Hexbound Balance Ledger"). Working tree only, not committed. Backend: 73 files / 486 tests green, `tsc` clean apart from the known stale-Prisma-client errors for new columns, schema drift / secrets / ladder parity OK, admin `tsc` clean. **No Swift compiled here** — five iOS files changed.

**Six migrations must be applied to prod BEFORE deploying the backend** (all additive or idempotent):

```
20261014_warrior_ult_magnitudes        -- 60/50 → 0.6/0.5 on the two warrior ultimates
20261014_upgrade_config_to_design      -- game_config upserts: exponential/150/1.4, threshold 8, 40 gems, chances 30/20
20261014_milestone_claims_per_account  -- milestone_claims.user_id + unique(user,level); backfill + dedup
20261014_gem_pack_daily_cap            -- users.gem_pack_purchases_today / _date
20261014_price_appearance_skins        -- 36 skins priced (rows still at 0/0 only)
20261014_ticket_attacker_stance        -- pvp_battle_tickets.attacker_stance
```

---

## Ships broken — fixed

**Warrior ultimates.** `unleash` seeded magnitude 60 (×61 damage), `champion` 50 (hit reduced to 0). Seeds now 0.6 / 0.5; `active-handlers.ts` clamps every magnitude to [0, 1] via `clampFraction`, so a repeat of the seed mistake degrades to ×2 / full block instead of a one-shot / immunity. 27 handler tests.

**Premium Pass.** Advertised nine benefits, delivered two. Implemented: **+20% arena XP** (`xpBonusMultiplier`, at the same point in the stack as the gold bonus, in fight/resolve/match-complete/revenge) and **5 free PvP/day** (`freePvpPerDay(user, base)` in match/start, prepare, fight, resolve, game/init — the client's "x of y" counter and stamina gate read the account's real allowance). The purchase screen and comparison table now list exactly what the server grants: +20% arena XP, +10% battle gold, 5 free PvP, 300 gems/renewal, +25 gems on daily login (that one existed and was unadvertised). Removed: 6-minute regen, exclusive cosmetics, priority matchmaking, badge, +50 daily gold. **App Store Connect's subscription description must match this list.**

**Solvable combat.** Three closures:
- `GET /characters/[id]/profile` (unauthenticated) no longer returns `combatStance`.
- `/pvp/prepare` still has to return the opponent's stance (the client replays the fight locally), so the attacker's stance is now **snapshotted on the battle ticket** and `/pvp/resolve` fights with the ticketed stance, not the live row. Prepare → read → counter-stance → resolve no longer works. Tested.
- Interactive PvP zone picks were `hash(match_id, strikeIndex, const)` — all client-known. `COMBAT_SEED_SECRET` (falls back to `BOT_TICKET_SECRET`) is folded into the seed. Warns at boot in production if neither is set.

## Economy

| Change | Before | After |
|---|---|---|
| Upgrade cost (DB config) | `linear`, base 100 → +1..+10 = 5 500 | `exponential`, 150 × N^1.4 → 17 623, as designed |
| Downgrade-on-fail threshold | from the +6 attempt | +9/+10 only |
| Upgrade chances | roll 25/15, UI shows 30/20 | one table, 30/20, seeded |
| Protection scroll | 30 / 40 / 50 (three sources) | 40 |
| Gold→gem packs | unlimited at 30 g/gem | **1 pack per account per day** (`GEM_PACK_DAILY_PURCHASE_CAP`) |
| Milestone rewards | per character ×5, reset by delete | **once per account** (`MilestoneClaim.userId`), survives character deletion |
| Self-referral | guard compared character ids | compares `user_id` |
| Defender payout | full base (150/50), no stamina, no action | `DEFENDER_REWARD_SHARE` 0.34 of base, gold and XP, all four PvP routes |
| Revenge (classic path) | 0 stamina + free slot + ×1.5 gold | costs stamina, no free slot (matches `pvp/revenge/[id]` and prepare's gate) |
| Cosmetics | 48 skins at 0/0 | default free; 2 500 g / 8 000 g / 400 gems per (origin, gender); **free-only at character creation** |
| XP curve | 54 880 to L50 (~12 days) | ×3 = 164 640 (~35 days) via `XP_CURVE_SCALE`, mirrored in `Character.xpCurveScale` |

The economy simulator imported a `balance.ts` upgrade formula (150 × 1.4^N) that the route never used; `upgradeCost` now matches the route (150 × N^1.4) and the simulator pays for the *next* plus level like the route does.

## Combat

**Armor cap.** `100/(100+resist)` had no floor; effective HP outgrew damage ×2.5 and L50 mirrors timed out ~100%. `COMBAT.MAX_RESIST_REDUCTION` caps the absorbed share. Swept on the real engine (`tests/lib/combat-ttk.test.ts`): 0.75 still timed out 40% of L50 mirrors; **0.6** ends L25 and L50 mirrors in ~10 rounds with the cap essentially never reached, and leaves armor below ~150 (around L15) untouched. The test pins both bounds (7–13 rounds, <10% timeouts). Mirrored in the client replay (`CombatEngine.resistMultiplier`, `BattleCombatConfigPayload.maxResistReduction`, `combat_config.max_resist_reduction` from `/pvp/prepare`) — without that the client would show one winner and the server pay another.

**Fatigue in interactive PvP.** `resolveSingleStrike` hard-coded turn 1, so the anti-stall mechanic never fired in the one mode where stalling is worst. `SingleStrikeInput.turn` carries `strikeIndex + 1`.

**Defensive talents survived nothing.** Eight routes called a derived-stats recalculation that knew nothing about passives; combat reads the persisted `maxHp`. `recalculateDerivedStats` now delegates to `recalculateFullDerivedStats` (passives included), which in turn derives base HP/armor/MR from the same config as the item pipeline instead of a hardcoded 80/5/3. Tested with a percent_hp node surviving a recalculation.

## iOS (not compiled)

- `CombatEngine.swift`, `BattlePreloader.swift` — armor cap in the local replay.
- `PremiumPurchaseView.swift` — benefits list and comparison table.
- `ArenaViewModel.swift` — stamina gate skipped while free fights remain (it used to paywall a free fight with a one-tap 50-gem refill).
- `HubView.swift` — `staminaRecoveryText` reads the server's regen interval (it is currently dead code; the "Full in 15h" the audit described is not shown anywhere); potion toast estimates per potion size instead of a flat 30% of max.
- `ShopService.swift` — the gem-pack daily-cap message (429) reaches the player instead of "check your gold balance".
- `Character.swift` — `xpCurveScale`.
- `AppConstants.swift` — `staminaRegenMinutes` fallback.

## Review

One adversarial pass over the batch. It caught: the armor cap missing from the client replay (desync — fixed), skin pricing bypassed at character creation (fixed), `pvp/revenge/[id]` missed by the defender-share and premium-XP changes (fixed), the gem-cap 429 swallowed by the iOS error mapping (fixed), the stance still readable via prepare (fixed with the ticket snapshot), a wrong formula in a migration comment and the simulator (fixed), a test mock producing NaN (fixed), and a P2002 race on the new per-account milestone unique (caught and skipped).

## What you need to do

1. Apply the six migrations above via Supabase MCP, then deploy.
2. Vercel env: `COMBAT_SEED_SECRET` (any long random string; `BOT_TICKET_SECRET` is used if absent).
3. Build in Xcode.
4. App Store Connect: the Premium Pass subscription description must list the five real benefits only.
5. `git add` the six migration folders and five new test files.

## Not done — content, not tuning

- The seven dead level zones (16–19, 22–24, …). ×3 XP makes them three times longer in wall-clock. The natural filler is the `skills` table, which has no seed in the repo at all; items at itemLevel 41–50 (the catalog stops at 40 against a cap of 50); milestones every 2–3 levels.
- Prestige is still a 27% damage loss and a full talent wipe for +3.5%. Needs a design, not a constant.
- Set bonuses (0 of 28 pieces exist), per-copy stat rolls (`rolledStats` never written), class-targeted loot (`classRestriction` NULL on all 100 items), per-dungeon drop tables (seeded, served, unread).
- Protection Scrolls and Legendary Shards are still sold in bundles and spent by nothing.
- Tank still dominates warrior (`str×1.3 + vit×0.3` + 15% DR vs `str×1.5`) — the armor cap changes the numbers; re-run the class matrix before touching formulas.
- Premium stamina regen (6 min) and cosmetics — removed from the screen rather than built.
