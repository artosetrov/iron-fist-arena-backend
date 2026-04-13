# Hexbound — Economy Rules (Constitution)

**Version:** 1.0 (2026-04-13)
**Status:** Active. Supersedes ad-hoc tuning notes scattered through `balance.ts` comments and W3.D* changelogs.
**Owner:** Game Director + CDO.
**Companion docs:** [`ECONOMY_AUDIT_2026-04-13.md`](./ECONOMY_AUDIT_2026-04-13.md) (diagnosis), [`BALANCE_CONSTANTS.md`](./BALANCE_CONSTANTS.md) (current numbers), [`PREMIUM_PASS_MIGRATION.md`](./PREMIUM_PASS_MIGRATION.md) (one-time → subscription plan).

> This document defines **why** the economy looks the way it does. Every constant in `backend/src/lib/game/balance.ts` should be traceable to a rule below. If you are about to add or change a number and there is no matching rule, **add the rule first**, then change the number. Stale rules are worse than missing rules — fix or delete them.

---

## R1 — The four pillars

The economy must serve, in order:

1. **Retention** — every session ends with a player feeling they got stronger or got something interesting.
2. **Progression pacing** — the player always sees a goal that is reachable but not trivial.
3. **Monetization** — premium spend buys time, convenience, and cosmetics; never combat power.
4. **Fairness** — F2P always has a path to everything that matters; whales pay for the speed of that path, not for exclusive power.

**Conflict resolution:** Retention > Progression > Monetization > Fairness, but Fairness has veto power over Monetization. A monetization choice that breaks Fairness is rejected even if it passes the Retention test.

---

## R2 — Two currencies, no exceptions

- **Gold** is the F2P grind currency. Earned only through play.
- **Gems** are the premium currency. Earned sparingly through play; primarily bought.
- **Shards** (`essence_shards`, `legendary_shards`) are crafting currencies. Non-tradable, non-purchasable — only earned. They are NOT a third currency in the macroeconomic sense.

**Forbidden:**
- No direct sale of gold for real money. (W4 — `gold_*` IAP SKUs are deprecated.)
- No "premium-only" stat boosts that don't have a F2P path (even a slow one).
- No tradable currency between players. Ever.

**Allowed:**
- Gold ↔ Gem conversion in-game (Gold Mine Boost, Gem Pack shop). One-way: gold buys gems, gems buy stamina/scrolls/skips. Conversion rates are intentionally unfavorable for grinders so that whales aren't undercut.

---

## R3 — Reward scaling matches cost scaling

Any reward that scales with character level uses:

```
reward = base × (1 + 0.04 × (level − 1))
```

| Level | Reward multiplier |
|---|---|
| 1 | 1.00× |
| 10 | 1.36× |
| 25 | 1.96× |
| 50 | 2.96× |

This is `LEVEL_REWARD_SCALE = 0.04` in `balance.ts:levelScaledReward()`. The previous +2%/level was insufficient against repair/upgrade cost growth. Any new reward path that does not use this scale is suspect — flag it in code review.

**Cost scaling sanity check (must hold):**
- Repair cost L50 / L1 ≤ **10×** of reward L50 / L1 ratio. (Currently ~3× repair vs ~3× reward — passes.)
- Upgrade cost +N+1 / +N ≤ **2×**. (Current 1.4× — passes.)

If a tuning change pushes either ratio past these caps, rebalance both sides together.

---

## R4 — The 60–80% sink ratio

Per-archetype daily sink ratio (gold spent / gold earned, 30-day mean) must stay in:

| Archetype | Lower bound | Upper bound |
|---|---|---|
| Casual (L5–L20, ≤ 3 PvP/day) | 50% | 70% |
| Active (L20–L40, 5–10 PvP/day) | 60% | 75% |
| Whale (L40+, 10+ PvP/day) | 65% | 80% |

- Below the lower bound → economy is too generous; players have no buying decisions.
- Above the upper bound → economy is suffocating; players churn from frustration.

**Measurement:** `backend/src/lib/game/economy-simulator.ts` is the source of truth. CI must run the simulator on every balance.ts change and fail the build if any archetype falls outside its band.

---

## R5 — The three deficit waves

The economy must produce three distinct moments of friction, each tied to a monetization offer:

### Wave 1 — Stamina wall (L7–L10, day 2–3)
- Player wants more PvP than free stamina + 3 daily free fights allow.
- Surface offer: **first stamina refill at 15 gems (50% discount, one-time)**, then standard 50/80/140/240 escalating curve.
- Win condition: at least 30% of new players use the discounted refill within their first 5 days.

### Wave 2 — Upgrade variance wall (L20–L25, day 10–14)
- Player attempts +7 / +8 upgrades and hits failure variance.
- Surface offer: **mid-game one-time bundle ($9.99)** containing 1,500 gems + 5,000 gold + 3 protection scrolls + 2 legendary shards. Valid for 48 hours after L25.
- Win condition: at least 12% conversion on the L25 trigger.

### Wave 3 — Legendary grind wall (L35–L40, day 25–40)
- Player wants their dream legendary set; RNG is too slow.
- Surface offer: **Warlord's Chest** ($29.99) and **legendary shard crafting**.
- Win condition: at least 6% of L35+ players purchase Warlord's Chest within 7 days of unlock.

**Each wave must be telegraphed in UI** (resource indicator changes color, a quest hint appears, an offer popup is queued).

---

## R6 — Reward shape rules

### R6.1 — First-of-day bonus everywhere
Every repeatable activity grants 2× reward on first daily clear:
- First PvP win: 2× gold + 2× XP.
- First dungeon clear (any difficulty): 2× gold + 2× XP + guaranteed uncommon+ drop.
- First training match: 2× XP (gold unaffected — training is not income).
- First quest of each type completed.

This is the daily login hook **inside** the gameplay loop, not a separate UI element.

### R6.2 — Streak caps
Win streak gold bonus caps at **+50%** (`WIN_STREAK_BONUSES`). No exceptions. Streaks are emotional, not economic — don't let farming them outpace fresh daily clears.

### R6.3 — Loss recovery
Loss streak grants gold bonus on the next win, capped at **+50%** (`LOSS_STREAK_BONUSES`). Mirrors win streak cap intentionally — recovery is real but not exploitable.

### R6.4 — Rare-but-visible
Anything with < 5% drop rate must also have an alternate **deterministic acquisition path**:
- Legendary items: 1% RNG drop **OR** craft from 5 legendary shards.
- Specific set pieces: random loot **OR** boss-specific guaranteed drop on first weekly clear.

If a player cannot point to a deterministic ladder for any "rare" reward, the rare reward does not exist for them emotionally and they will churn.

---

## R7 — Cost shape rules

### R7.1 — Repair cost
```
repair_per_item = (BASE + level × PER_LEVEL) × rarity_multiplier
BASE = 120, PER_LEVEL = 20  (W3.D3, retained)
```

Repair is a **lumpy sink**, not a per-fight tax. Durability decays over many fights; a full-set repair cycle should land at 25–35% of gold earned during that cycle. If sink-ratio simulator shows repair contributing < 20% or > 45%, retune.

### R7.2 — Upgrade cost (gold)
```
upgrade_cost(N) = 150 × 1.4^N    (N is the target level, +1 through +10)
```

Exponential cost is intentional — late upgrades are the primary gold sink.

### R7.3 — Upgrade success and failure
| Level | Success % | Failure mode |
|---|---|---|
| +1 to +5 | 100% | — |
| +6 | 80% | Item unchanged |
| +7 | 60% | Item unchanged |
| +8 | 40% | Item unchanged |
| +9 | 30% | Downgrade by 1 level |
| +10 | 20% | Downgrade by 1 level |

**Rule:** failure at +6/+7/+8 wastes gold but does not lose progress. Failure at +9/+10 downgrades by exactly 1 (NEVER destroys). Protection Scroll (40 gems, was 50) prevents the downgrade.

This is a clean monetization surface: scroll cost is small enough to feel buyable, but spending 40 gems × 5 attempts = 200 gems per +10 push is real money pressure.

### R7.4 — Consumable cost
Consumable prices live on a **multiple-of-PvP-win** scale, level-scaled:
- Stamina Potion Small ≈ **0.85× one PvP win** at the player's level.
- Stamina Potion Large ≈ **1.7× one PvP win**.
- HP Potion Small ≈ **1.3× one PvP win**.
- HP Potion Large ≈ **2.6× one PvP win**.

If a consumable falls outside ±20% of its target ratio after a balance change, retune. Hardcoded prices are **deprecated** — consumables should level-scale via `levelScaledConsumableCost(baseRatio, level)`.

---

## R8 — Stamina rules

- Max stamina cap: **180** (W4 — was 120). Reasoning: a player checking in twice a day must not lose overnight regen.
- Regen rate: **1 per 8 minutes** (unchanged). Full 0 → 180 = 24 hours.
- Free PvP per day: **3** (unchanged).
- Refill curve: **50 / 80 / 140 / 240 gems** (W4 — was 30/45/75/120). Hard cap 4 refills/day. First refill is no longer the habitual button — it's the deliberate one.
- First refill in the player's lifetime: **15 gems** (one-time, served via offer). This is Wave 1's hook.
- Offline stamina regen bonus (M7 backlog): when the player has been offline 4+ hours, regen rate doubles to 1 per 4 minutes. Compensates for sleep without rewarding active grinders.

---

## R9 — Gem economy rules

### R9.1 — Gem valuation
A gem is worth approximately **1¢** of real money at blended pack rate. Sanity-check every gem-priced action against this:

| Action category | Gem range | Rationale |
|---|---|---|
| 10-minute QoL skip | ≤ 10 gems | Roughly = F2P daily gem income |
| Daily QoL action | 30–60 gems | Refill, single boost, scroll |
| Weekly event ticket | 300–800 gems | A real player decision |
| One-time unlock | 500–2,000 gems | BP premium, slot purchase, season pass |

Anything outside these bands needs explicit design justification in the rule note next to its constant.

### R9.2 — F2P gem floor
Target **F2P gem income: 250–320 gems / month** (excluding shop spend). Sources:
- Daily login (Day 7): 25 gems/week ≈ 107/month.
- Battle Pass free track: 50 gems / 8-week season ≈ 25/month.
- Achievements (amortized): ~30/month for new players, decaying.
- Gold Mine: 10% × 1–3 gems × 18 sessions/day total ≈ 50–150/month (most variable source).

If any single source contributes > 50% of F2P income, the economy is fragile to that source's tuning. Rebalance to spread income across 4+ sources.

### R9.3 — Gem sink discipline
- Stamina refill remains the primary sink (target 60–70% of whale gem spend).
- BP premium contributes 8–12%.
- Convenience/cosmetic contributes the rest.
- **No power-buying gems sinks.** Upgrade Protection Scrolls are the closest line — and are explicitly framed as "preserve progress", not "buy progress".

---

## R10 — IAP product ladder rules

### R10.1 — Required ladder (every tier must exist)

| Tier | Price | Purpose |
|---|---|---|
| Frictionless | $0.99 | First-purchase nudge — Starter Nudge or small gem pack |
| Habit-builder | $2.99–4.99 | Starter Bundle, Adventurer's Bundle I, Monthly Gem Card |
| Standard | $9.99 | Adventurer's Bundle II, Premium Pass (sub), BP skip |
| Big spender | $14.99–19.99 | BP Instant, Adventurer's Bundle III |
| Whale | $29.99–49.99 | Warlord's Chest, Mega Bundle |
| Apex whale | $99.99 | Sovereign Pack |

**Forbidden:** missing rungs in the ladder. If a tier between two adjacent tiers has > $10 gap, add a tier or accept the conversion floor at that gap.

### R10.2 — Pack scaling
Discount from smallest gem pack to largest must be **40–60%** of $/gem. Industry norm. Current state (23%) underprices whale conversion.

### R10.3 — One-time vs recurring
- **One-time SKUs** must have hard caps on long-term value (e.g., Starter Bundle once per account).
- **Subscriptions** have no value cap but provide continuous flow (Premium Pass, Monthly Gem Card).
- **Forbidden:** one-time SKUs with unbounded daily value. (W3.D5 `premium_forever` violated this; deprecated W4.)

### R10.4 — Bundle composition
Every $9.99+ bundle must include at least:
1. Premium currency (gems).
2. A consumable utility (scrolls, potions, BP levels).
3. A vanity/identity hook (cosmetic preview, unique title flag, or "shard of X").

Pure gem packs at $9.99+ are allowed but should be clearly priced AGAINST bundles to make the bundle feel like the better deal.

---

## R11 — Premium Pass (subscription) rules

(Effective once `PREMIUM_PASS_MIGRATION.md` is implemented; see that doc for migration sequence.)

- Price: $9.99/month or $79.99/year (~33% annual discount).
- Benefits:
  - **+10% gold multiplier** (applied LAST in reward stack — does not compound CHA).
  - **+20 gems / day** (claim via Daily Login UI).
  - **2× daily quest gold reward.**
  - **Exclusive daily shop slot** with a rotating subscriber-only deal (cosmetic / convenience).
  - **"Chosen" cosmetic title.**
- **Does NOT include:** combat stat boosts, exclusive items with stats, exclusive arena queue, exclusive matchmaking. Premium is a comfort product, not a power product.
- Existing `premium_forever` owners are **grandfathered indefinitely** at their current 25 gems/day + 10% gold benefit. Their entitlement does not lapse.

---

## R12 — Battle Pass rules

- Season length: **8 weeks**.
- Free track: **100 levels**, includes 50 gems total + cosmetics.
- Premium track: **+50 levels** (150 total), includes 100+ gems, rare items, BP-exclusive cosmetics.
- Premium price: **700 gems** (W4 — was 500; aligns with skip-level offers).
- BP XP: 100 + N × 50 to reach level N.
- Skip offers: **+10 levels @ 300 gems**, **+25 levels @ 700 gems**, **Instant unlock (+50 levels + premium) @ $14.99**.
- Weekly Challenges contribute ~750 BP XP/week for active players (5 slots × 150 each).

**Rule:** premium track must include ≥ 1.5× the gem value of its purchase price. (700 gems in → 1,050+ gems out across the season.) This is the recurring-purchase trust contract.

---

## R13 — Gold Mine and passive systems

- Base session: **4 hours**, **40–100 gold reward** (`Gold Mine Yield`).
- 10% chance of 1–3 gem drop per session.
- Slots: 1 base + 2 unlockable (50 gems each) = 3 max for F2P. Premium Pass unlocks a 4th at +50% yield.
- Boost cost: **10 gems** (W4 — was 3; restored to original W3.D4 value). Bulk skip available at 5 × 9 = 45 gems (10% bulk discount).
- Yield scales with character level: **+10% per 5 character levels**, capping at L40 (+80%).

**Rule:** Gold Mine income should never exceed 25% of an Active player's daily gold income. If it does, rebalance the slot count or yield, not the boost cost (boost cost is a monetization knob, not a yield control).

---

## R14 — Item economy rules

### R14.1 — Drop distribution (locked)
50% common, 30% uncommon, 15% rare, 4% epic, 1% legendary. Do not adjust without explicit Game Director approval — these ratios anchor every loot calculation.

### R14.2 — Stat roll floors per rarity
| Rarity | Roll floor (% of max) |
|---|---|
| Common | 40% |
| Uncommon | 55% |
| Rare | 65% |
| Epic | 75% |
| Legendary | 85% |

A higher rarity must always feel like an upgrade over a lower one. An unlucky epic must not roll below an average rare. Implementation: clamp roll to `floor × maxStatForLevel` after RNG.

### R14.3 — Sell prices
| Rarity | Sell price (gold) |
|---|---|
| Common | 10 |
| Uncommon | 25 |
| Rare | 60 |
| Epic | 150 |
| Legendary | 400 |

These are **trash-removal prices**, not economic value. Players who actually want to monetize a duplicate use the **shard system** (M2 backlog): auto-dismantle below player level → essence shards → reforge / reroll / transmog sinks.

### R14.4 — Set bonuses
A 5-piece set bonus must always feel **decision-worthy**, i.e. better than equipping the best individual pieces from across slots. If sets are dominated by mix-and-match in simulator, retune.

---

## R15 — Tutorial and starter rules

- Starting bundle: **500 gold + 3 small HP potions + starter weapon + 1 common chest armor (pre-equipped)**.
- First Victory Chest (after first PvP win): **200 gold + 1 uncommon item + 20 gems**.
- L10 milestone: gold + gems + a clear UI banner.
- Tutorial NPC quests pay out at ~3× normal daily quest rate to amplify abundance feel.

**Rule:** the first 30 minutes must contain at least one **"I got something rare"** moment (uncommon+ item, gem grant, or class-defining unlock).

---

## R16 — Live-tuning safety

Any change to `balance.ts` constants is a balance change. It must:

1. Pass **economy-simulator** sink-ratio test for all 3 archetypes.
2. Update **`docs/06_game_systems/BALANCE_CONSTANTS.md`** in the same commit.
3. If reward/cost direction changes, post a note in `docs/06_game_systems/CHANGELOG.md` with the W-week number and rationale.
4. Not be deployed mid-season (8-week cadence). Changes go live at season boundaries unless flagged as P0 fix.

**Forbidden:** silent rebalancing through admin-panel live config without updating these docs. Live config is for emergency mitigation only.

---

## R17 — Anti-pay-to-win line

Premium spend can only buy:
- **Time** (skips, refills, instant completion).
- **Convenience** (extra slots, auto-claim, queue priority for subscribers).
- **Cosmetics** (titles, skins, banners, mounts).
- **Determinism** (legendary shards, protection scrolls — F2P-obtainable, premium-accelerated).

Premium spend cannot buy:
- **Combat stats** (no exclusive premium items with stats).
- **Matchmaking advantage** (no priority opponent selection).
- **Information advantage** (no exclusive opponent telemetry).
- **PvP-affecting consumables** (no buffs that activate during PvP combat).

This is the line. If a proposal walks up to it, reject the proposal — even at revenue cost.

---

## R18 — Health metric tripwires

These metrics are checked weekly by the analytics-lens agent. Crossing any tripwire opens a balance review ticket.

| Metric | Tripwire |
|---|---|
| D1 retention | < 35% |
| D7 retention | < 18% |
| D30 retention | < 8% |
| Conversion (any spend by day 14) | < 4% |
| ARPDAU (paid users only) | < $0.45 |
| Sink ratio (any archetype) | outside R4 bands for 14 consecutive days |
| Upgrade abandonment rate at +8 | > 60% |
| F2P median gem bank (L20+) | > 800 (too generous) or < 50 (too tight) |
| Premium Pass churn rate | > 18%/month |
| Dungeon vs PvP session ratio | < 25% dungeon (content collapse) |

---

## R19 — Document hygiene

- This document is the constitution. `BALANCE_CONSTANTS.md` is the current numbers. `CHANGELOG.md` is the diff log.
- If a rule changes here, **bump the version number at the top** and add a note explaining the change.
- Code comments in `balance.ts` should reference rule numbers (`R3`, `R7.3`, etc.) rather than re-explaining the rationale.
- If a constant in `balance.ts` is not referenced by any rule here, either: (a) add the rule, (b) remove the constant, or (c) move it to live-config. Orphan constants are how economies drift.

---

## Appendix — rule → constant map

Quick reference for code reviewers:

| Rule | Constants in balance.ts |
|---|---|
| R3 | `levelScaledReward()` (LEVEL_REWARD_SCALE) |
| R4 | (enforced by economy-simulator) |
| R6.2 | `WIN_STREAK_BONUSES` |
| R6.3 | `LOSS_STREAK_BONUSES` |
| R7.1 | `REPAIR_COSTS`, `repairCost()` |
| R7.2 | `UPGRADE_COSTS`, `upgradeCost()` |
| R7.3 | `UPGRADE_CHANCES`, `UPGRADE_FAILURE_MODE` (M-backlog) |
| R8 | `STAMINA`, `STAMINA_REFILL_DR`, `staminaRefillGemCost()`, `GEM_COSTS.STAMINA_REFILL` |
| R10 | `IAP_PRODUCTS` |
| R11 | `premium.ts` (PREMIUM_GOLD_MULTIPLIER, PREMIUM_DAILY_GEMS) |
| R12 | `BATTLE_PASS`, `BP_WEEKLY`, `bpXpForLevel()` |
| R13 | `GEM_COSTS.GOLD_MINE_*` |
| R14.1 | `RARITY_DISTRIBUTION` |
| R14.3 | item sell prices (in `loot.ts` / `item-balance.ts`) |
| R6.1, R15 | `tutorial.ts`, `daily-login.ts` |

---

*End of constitution.*
