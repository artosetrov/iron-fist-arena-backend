# Hexbound — Full Economy Audit & Redesign

**Date:** 2026-04-13
**Author:** CDO (economy pass)
**Scope:** Complete economy — earnings, sinks, progression, shop, IAP, premium, passives
**Source of truth:** Extracted from `backend/src/lib/game/*.ts`, `docs/06_game_systems/BALANCE_CONSTANTS.md`, `docs/02_product_and_features/ECONOMY.md`, W3.D5 state (2026-04-10)

> **Status boundary:** historical economy audit/redesign snapshot from `2026-04-13`. Keep it as detailed reasoning and evidence, but do not treat every diagnosis or target rule below as live economy truth without revalidating against current backend constants, current `wiki/` audit blocks, and current runtime behavior.

---

## 0. How to read this document

Everything below is grounded in the actual numbers compiled in the extraction report (see appendix at bottom). Where a number is assumed because it is not defined in code, I mark it **[ASSUMED]**. Where code and docs disagree, I mark it **[CONFLICT]** and resolve to the code value.

The document is organized as:

1. Systemic diagnosis — layer by layer, what's wrong and why.
2. Progression loop model — what the economy feels like at every stage.
3. Shop and monetization — where the money is left on the table.
4. Block 1 — main problems (the executive list).
5. Block 2 — new economy rules (the constitution).
6. Block 3 — concrete change list (the ticket backlog).
7. Block 4 — target model.
8. Appendix — raw numbers.

---

## 1. Systemic diagnosis

### 1.1 Top-level economic frame

Hexbound has **two currencies (gold, gems)**, a **stamina gate**, a **passive gold source (Gold Mine)**, and **one major gold-exit system (upgrades)** that is exponential. The structure is sound. The tuning is not.

Three structural issues dominate everything else:

1. **Late-game reward scaling (+2%/level) is far weaker than cost scaling (repairs +80%/50 levels, upgrades exponential ×1.4^N).** The player earns harder as they progress. This is the opposite of what a retention-focused economy should do. It creates the "brick wall" at L25-30.
2. **`Premium Forever` at $9.99 one-time is a catastrophic monetization leak.** It gives 25 gems/day + 10% gold forever. In three months it already out-delivers the $4.99/mo gem card, and then it keeps paying out forever with zero recurring revenue. It destroys the LTV curve.
3. **F2P gem income is too high for premium feature value, and too low for shop relevance.** F2P gets ~260–320 gems/month. Battle Pass Premium is 500 gems/season (8 wks → 62 gems/mo equivalent). After BP, F2P has 200–250 gems/mo — enough to use stamina refills casually, not enough to feel pressure to buy. The shop never becomes compelling.

Everything else in this document is a consequence of these three problems, or a local tuning miss.

---

### 1.2 Starting resources — too tight and unfriendly

- **300 gold + 2 small HP potions + 1 starter weapon.**
- Cheapest stamina potion (small) = **125g**. Cheapest HP potion (small) = **190g**. The first potion purchase eats 63% of starting gold.
- The first repair at L3 common gear ≈ **140g × 1.0 = 140g**. Another 47% of the starting pool.
- Player has no defensive gear, no offensive upgrade path, and after 1 potion + 1 repair is at ~35g.

**Verdict:** Too tight. The first session is about managing deficit, not about spending. That's a weak emotional entry. Industry norm for mobile RPGs: new player should have **"first spend feels powerful"** moment within the first 15 minutes — a visible upgrade, a gear piece, or a meaningful unlock. Hexbound currently has none of this in the starting bundle.

**[ASSUMED]** New-player 7-day retention is almost certainly suppressed by this; verify in analytics.

---

### 1.3 Combat rewards — good base, broken scaling

**PvP Win 150g + 150 XP base** is tuned well for L1–L15. Streak, CHA, first-win multipliers are healthy and readable.

The scaling formula is the problem:

```
reward = base × (1 + 0.02 × (level − 1))
```

- L1 → L50 reward multiplier: **1.00× → 1.98×** — only doubles.
- L1 → L50 repair cost multiplier: 140g → 1,220g (×8.7) × legendary 5.0 = **×43.6**.
- L1 → L50 +5 upgrade: **+5 = 807g flat** (does not level-scale) — so this one is fine.
- L1 → L50 +8 upgrade: **2,214g** (does not level-scale).

Late-game reward does NOT keep pace with late-game costs. Players compensate by farming more PvP at scale, which chews stamina, which pushes them into gem refills — which is actually the monetization channel, so it's working partially. But it's cloaked as "grind pressure", not "buy relief".

**Fix:** Reward scaling should be **+4% to +5% per level**, not +2%. At +4% the L50 multiplier is 3.00×, which is closer to repair and upgrade scaling.

---

### 1.4 Dungeon rewards — bottom-heavy, top-light

| Floor | Gold | XP |
|---|---|---|
| 1 | 50 | 20 |
| 5 (boss) | 150 | 60 |
| 10 (boss) | 300 | 150 |

Dungeon floor 10 boss (a full run) gives **300g**. One PvP win at L25 gives **222g**. A dungeon run costs 10 stamina segments (≈10×20 = 200 stamina) and takes real time, vs 10 stamina and 30 seconds for PvP. **PvP dominates dungeons on gold/stamina and gold/time.**

Dungeons only win on:
- XP efficiency (150 XP for boss vs 150 for PvP win — equal).
- Item drops (variable, most are vendor trash).

**Verdict:** Dungeons are economically dominated by PvP. This collapses the content mix, which is bad for retention (players who want the PvE fantasy churn).

**Fix:** Dungeons need **~2× PvP gold-per-stamina** (PvE is slower per-real-time but deeper per-stamina), **first-clear-of-day bonus (2×)**, and **guaranteed rarity floor at boss floors**.

---

### 1.5 Daily quests and login — too safe, too low

- Daily quests: **3 per day, ~375g average total + 165 XP + ~5 gems.**
- Login weekly: **950g + 250 stamina + 25 gems.**
- Achievement dispense: front-loaded in first 2-3 weeks; trails to 0 for veterans.
- Level milestone rewards: one-time; L10 = 1000g + 20 gems, L50 = 10000g + 150 gems. Reasonable but invisible to the player because there's no flag/banner showing "5% to next milestone".

**Daily floor for an Active L20 player:** ~375g quests + ~135g login + 3 × 150g × 1.4 = ~1,140g daily floor. Healthy.

**Weekly gem floor:** 25 login + ~8 BP free + ~3 achievements + ~30 mine (10% × 2/day × 3) = **~66 gems/week ≈ 285/month**. Matches my earlier estimate.

**Problem:** Daily quest rewards don't scale with level. A L50 earning 375g from dailies is negligible; a L5 earning 375g is transformational. The system is most generous where players need it least.

**Fix:** Apply the same level scaling to daily quest gold rewards (**+4%/level**).

---

### 1.6 Item economy — flat stat bands, vendor-trash problem

- Rarity drop distribution: 50/30/15/4/1 (C/U/R/E/L). Fine.
- Rarity sell prices: 10/25/60/150/400. **Sell prices are too low and barely compensate for inventory clutter.**
- Stat bands per level:
  - L1–5: 1–8
  - L36–50: 28–75

**Problem 1 — Stat band compression**. An epic at L5 rolls stats in band 1–8 (same as common at L5). There is no rolled-stat differentiation by rarity — only the power multiplier (×2.0 for epic). That means rarity is a cosmetic-plus-multiplier, not a distinct roll tier. Playtesters will not feel the fantasy of "found an epic".

**Problem 2 — No stat roll floor at high rarity**. An unlucky epic is worse than a lucky rare. This is OK in hardcore loot games (Diablo, POE) but **hostile in a mobile RPG where RNG frustration kills retention**.

**Fix:** Rarity should define **roll floor** (minimum stat as % of max):
- Common: 40% floor
- Uncommon: 55% floor
- Rare: 65% floor
- Epic: 75% floor
- Legendary: 85% floor

**Problem 3 — Vendor trash.** Sell price of a common = 10g. Player gets 3-5 commons per dungeon. Sells for 30-50g. Meaningless.

**Fix:** Auto-dismantle → shards, with shards → new sink (enchanting / reroll / reforge). Shards are a secondary soft currency with a clear use case.

---

### 1.7 Upgrade system — costly in the wrong way

Expected gold to fully +10 a single item (Monte Carlo):

| Level | Base cost | Success % | Expected cost (w/retries) |
|---|---|---|---|
| +1 to +5 | 210 → 807 | 100% | 2,299 |
| +6 | 1,130 | 80% | 1,413 |
| +7 | 1,582 | 60% | 2,637 |
| +8 | 2,214 | 40% | 5,535 |
| +9 | 3,100 | 25% | 12,400 |
| +10 | 4,340 | 15% | 28,948 |
| **Total per item** | | | **~53,232g** |
| **Total for 9 slots** | | | **~479,088g** |

Active L30 (3,746g/day) → **128 days to fully +10 one character** assuming 100% of gold goes to upgrades. This is too long without a gem-assisted path. Also — upgrade failure destroys (or resets) the item at +6+, which means the 28,948g expected cost is actually much higher if "failure = downgrade" not just "failure = try again".

**Observation:** Upgrade Protection Scroll exists (50 gems) but only for +6+. Good hook. Needs better surfacing.

**Fix:**
- Add a **"+X guaranteed" IAP consumable** (e.g., "+1 guaranteed upgrade token" = 75 gems, or bundle).
- Lower the +9 and +10 variance slightly (25% → 30%, 15% → 20%).
- Expose protection scrolls as a BP track reward, monthly card reward, and achievement reward. They should feel obtainable.

---

### 1.8 Stamina system — the critical monetization choke, tuned wrong

- Max: 120. Regen: 1/8 min → 120 in 16h. **Overflow wasted in sleep.**
- PvP cost: 10 (after 3 free/day).
- Refill escalation: 30 / 45 / 75 / 120 gems (max 4/day = 270 gems/day).

**Diagnosis:**

1. **Stamina cap 120 with 16h regen is wrong on mobile.** Players sleep 8h, work 8h. A player checking in twice a day (morning + evening) loses 4h of regen overnight if cap 120 is reached at 8h. Cap should allow ~24h of passive regen so that a once-a-day player doesn't feel they're losing value. **Cap should be 180 (24h of regen)**.

2. **First refill at 30 gems is too cheap.** Any player earning 8–10 gems/day from logins/BP will refill every other day. This pushes gems out of the shop ecosystem. First refill should be the "emergency button", not the habitual button.

3. **4 refills/day (270 gems) hard cap is sensible, but the curve starts too shallow.** Whales who want to commit should be able to refill more, just at accelerating cost.

**Fix:**
- Stamina cap **120 → 180**. (More forgiving for casuals; no whale benefit since they refill.)
- Refill curve **50 / 80 / 140 / 240** (first refill costs more; whale ceiling 510g/day gem equivalent).
- Regen rate unchanged.

---

### 1.9 Gold Mine — strong idea, under-tuned

- 3 slots (base 1 + 2 unlocks at 50 gems each) × 6 sessions/day × 40–100g = **720–1,800g/day** passive if played optimally.
- 10% gem drop × 3 slots × 6 sessions = **1.8 gem drops/day × 1–3 = 1.8–5.4 gems/day** ≈ **54–162 gems/month**.
- Gold Mine Boost: 3 gems for instant completion. **Too cheap.** Over a day, a whale can spend 3 gems × 17 skips = 51 gems to turn the mine into **~5,000g/day** instead of 1,260g/day. That's **4× gold-per-day for 51 gems ≈ 1.5%** of a $9.99 pack. **Severely under-priced.**

**Fix:**
- Gold Mine Boost: **3 → 10 gems** (restore W3.D4 value, align with doc).
- Gold Mine passive yield: slight buff at high level (+10% per 5 character levels) so it remains relevant.
- Consider "Premium Mine" at +50% yield, unlocked by any paid product — creates a clean premium hook.

---

### 1.10 Gem economy — F2P floor and Premium conflict

**F2P gem income per month:**

| Source | Gems/month (realistic F2P) |
|---|---|
| Daily login | 107 |
| Achievements (amortized, first 2 mos) | ~40 |
| Achievements (veteran) | ~0–5 |
| Battle Pass Free Track | 25 |
| Gold Mine | 54–162 |
| Shop Packs | 0 |
| **Total F2P new (month 1–2)** | **~260** |
| **Total F2P veteran (month 6+)** | **~190–220** |

**Gem costs per month (whale behavior):**

| Sink | Gems/month |
|---|---|
| Stamina refills (1/day avg casual; 4/day avg whale) | 900–8,100 |
| Battle Pass Premium (amortized) | 62 |
| Upgrade Protection scrolls | 200–500 |
| Gold Mine Boost (3 gems) | 50–150 |
| Passive respec | occasional |

A F2P player has enough gems for **~5–7 stamina refills/month + 1 BP purchase every other season.** That's essentially zero pressure.

**Critical insight:** The gap between F2P gem intake and "nice to have" gem spend is the monetization surface. Right now that gap is narrow because stamina refill #1 is 30 gems (cheap) and BP is 500 gems/2-months. Widening this gap is where revenue lives.

---

### 1.11 Shop packs — under-incentivized scaling

| Pack | USD | Gems | $/gem |
|---|---|---|---|
| Small | $0.99 | 100 | 0.0099 |
| Medium | $4.99 | 550 | 0.0091 |
| Large | $9.99 | 1,200 | 0.0083 |
| Huge | $19.99 | 2,500 | 0.0080 |
| Mega | $49.99 | 6,500 | 0.0077 |

Discount from smallest to largest pack: **23%**. Industry benchmark: **40–60%**. The Mega pack ($49.99) should give ~**8,000–9,000 gems** to feel meaningfully rewarding.

Also: **no $99 "ultra" pack.** Whale ceiling is $49.99. Missing the top 2–5% of spenders entirely.

**Fix:**
- Rebalance: 100 / 600 / 1,400 / 3,200 / 9,000 gems at current prices.
- Add **Ultra pack** at $99.99 → 20,000 gems + premium feature (e.g., 1 month free Monthly Gem Card, or guaranteed legendary drop token).
- Add **double-gems-on-first-purchase** per SKU (industry standard).

---

### 1.12 Gold packs — existential question

Selling gold directly is **unusual and risky**. It creates:
- Direct P2W perception (players paying for combat stat advantage via upgrades).
- Undercuts gem→gold conversion paths (Gold Mine Boost, etc.).
- Reduces "why buy gems" when you can buy gold directly.

**Options:**

A) **Remove gold packs entirely.** Force gold purchase through gems (Gold Mine Boost becomes the only path). Cleaner economy, stronger gem incentive. Risk: loss of some low-intent spenders.

B) **Keep but scope them narrowly.** Only sold in specific shop slots (e.g., "daily deal" rotation), never as a main offer. Reduces dominance.

C) **Replace gold packs with "resource bundles"** — gold + upgrade materials + a specific high-demand consumable. More packaged value.

**My recommendation:** Option C. Remove SKUs `gold_500`, `gold_1200`, `gold_3500`, `gold_8000`, `gold_20000`. Replace with tiered **Adventurer's Bundles** at similar prices that contain gold + scrolls + consumables + a small gem bonus. This retains the low-intent buyer's price point while removing pure P2W signaling.

---

### 1.13 Premium Forever — the monetization disaster

$9.99 **one-time** for:
- +10% gold multiplier forever
- 25 gems/day forever (= 750 gems/month = ~$6.50/mo equivalent at pack rates)
- "Chosen" title

**LTV analysis:**
- Month 1: buyer gets $6.50 gem equivalent + 10% gold bonus. Already 65% return on $9.99.
- Month 2: $13 total gem value. **Buyer is ahead.**
- Year 1: $78 gem value delivered for $9.99 paid.
- Year 3: $234 gem value delivered. **Studio has given away 2,340% of revenue.**

And this product **cannibalizes** the Monthly Gem Card ($4.99/mo for 350 gems) — a F2P player who buys Premium Forever gets 2.14× the gem card's output for 2× the one-time cost.

**Fix (urgent):**

Option 1 — **Convert to subscription.** "Premium Pass" $9.99/month OR $79.99/year. Same benefits. Add additional perks: double daily quests, exclusive cosmetics, priority matchmaking queue.

Option 2 — **If keeping one-time**, raise price to **$29.99–49.99** AND strip some benefits:
  - Reduce daily gems from 25 → 10.
  - Keep +10% gold.
  - Add time-limit: 1 year of gems, then only gold bonus + title persist.

**My recommendation:** Option 1 (subscription). This aligns with mobile RPG monetization norms and creates recurring revenue.

**Migration for existing buyers:** Grandfather them in at current benefits forever (avoid trust breakage). This is a 1-time PR cost worth paying.

---

### 1.14 Battle Pass — under-priced, under-leveraged

- Premium track: 500 gems (= ~$4.16 at pack rates, ~$5 at small pack rate).
- Duration: 8 weeks.
- Levels: 150 total (100 + 50 premium).

**Diagnosis:**
- Price is fine relative to value IF the content is good. Need to verify content density.
- Weekly Challenges give 150 BP XP each × 5 slots = 750 BP XP/week. BP levels cost 100 + N×50 XP. At L10, level-up = 600 XP. So weekly challenges provide ~1.25 levels/week from challenges alone. **Very marginal contribution for active players** — most BP XP comes from combat. Good.
- **No "BP Boost" buy-to-level.** Industry standard: let late-joining players skip 10, 25, 50 levels at gem cost. Missing revenue.

**Fix:**
- Add "+10 BP levels" IAP = 300 gems.
- Add "+25 BP levels" IAP = 700 gems.
- Add "Instant Unlock (skip to L50 + premium)" = $14.99.
- Raise premium BP cost 500 → 700 gems to align with skip offers.

---

### 1.15 IAP product ladder — missing rungs

Current ladder:
- $0.99 small gems
- $0.99 small gold
- $1.99 gold
- $2.99 starter (one-time)
- $4.99 gem card / medium gems / gold
- $9.99 large gems / gold / premium forever
- $19.99 huge gems / gold
- $49.99 mega gems

**Missing:**
- **No $14.99 tier** (battle pass skip).
- **No $29.99 tier** ("commander's chest", premium pack with gear).
- **No $99.99 tier** (whale pack).
- **No repeatable starter offers** — player hits starter, then nothing similar.
- **No weekly/monthly limited-time offers** — no urgency.
- **No first-purchase bonus** — industry standard missing.

---

## 2. Progression loop model

Below is the realistic experience at each stage, with the deficit points each stage should hit in a healthy economy.

### 2.1 Levels 1–3 (Tutorial / First Session, ~30 minutes)

**What the player should experience:**
- Gets starter weapon, 2 HP potions, wins first 3 PvP battles (free).
- First visible shop purchase ("buy common armor for 50g") within minutes.
- One upgrade of starter weapon to +1 (210g).
- First daily quest clear (50g).

**What they currently experience:**
- 300g feels like nothing. First potion wipes 63%.
- Starter weapon is the only offensive gear — nothing meaningful to buy at shop for <300g.
- First upgrade at 210g is affordable but feels small (+stat).

**Required deficit:** none. Should feel **abundance** — player should end session feeling "I got stronger and I have things to try next time."

**Change:**
- Starting bundle: **500g + 3 HP potions + 1 starter weapon + 1 basic common armor piece (chest) pre-equipped.**
- First session completion unlocks "First Victory Chest" → 200g + 1 uncommon item + 20 gems.

---

### 2.2 Levels 3–10 (Early Game, Day 1–3)

**Should feel:** acquisition, experimentation, first class identity.

**Current:**
- Gold flow: ~1,000–1,500g/day (mostly daily quests + PvP).
- Upgrade path: +1 to +5 all gear = affordable (each item ~2,300g to +5 flat).
- Player explores dungeons, Gold Mine, shop.
- First potion shortage around day 2-3 when frequent PvP outpaces potion stock.

**Required deficit:** light. Player should hit **first stamina squeeze** around day 2-3 (wants more than 3 free PvP + 120 stamina allows). This is the hook for first refill.

**Change:**
- First stamina refill offer via in-game popup: "First refill — 15 gems (50% off)." (Currently 30.)
- Quest reward scaling to reward more in this window (+20% for L3-10 to smooth).

---

### 2.3 Levels 10–20 (Mid-early Game, Day 4–10)

**Should feel:** commitment, build identity, first gear shortage.

**Current:**
- Gold flow: ~2,000–3,000g/day.
- Player starts pushing into +6, +7 upgrades — first variance frustration.
- Full set repair costs ~500–900g per cycle.
- Legendary items are mathematically rare (1% drop) and feel invisible.
- First real gem sink pressure: BP premium (500 gems) if player sees value.

**Required deficit:** **First moderate gold deficit.** Player should be choosing between: "save for +7 upgrade" vs "buy potion stack" vs "buy cosmetic." Resource management becomes interesting.

**Change:**
- Introduce "Artisan's Token" at L10 (BP reward + shop): guarantees next upgrade up to +5 succeeds.
- Introduce "Legendary Shard" (5 shards → 1 guaranteed legendary). Obtainable via dailies, weekly, BP. Makes legendaries feel **chaseable** rather than RNG-only.

---

### 2.4 Levels 20–30 (Mid Game, Day 10–25)

**Should feel:** specialization, investment, mid-game wall.

**Current:**
- Gold flow: ~3,500g/day.
- First serious repair cost: ~800–1,200g/cycle at L25.
- Trying to push +8 upgrades → frustration (40% success).
- PvP rating in Silver/Gold — first ranked pressure.
- Gem income stabilizing at ~10g/day F2P.
- **THIS IS THE FIRST MONETIZATION DECISION POINT.** Player thinks about: Monthly Gem Card, BP Premium, a gem pack.

**Required deficit:** **Gold tight, gems tighter.** Stamina whole-day-hours feel wasted above cap 120. Upgrade frustration compounds.

**Change:**
- This is where the economy should have the **hardest friction** — it's the primary conversion window.
- Do NOT add quality-of-life systems to ease this. Add offers instead.
- Show an L25 "Mid-Game Offer" (one-time): $9.99 → 1,500 gems + 5,000g + 3 protection scrolls + 2 legendary shards. This is the "first big purchase" hook.

---

### 2.5 Levels 30–40 (Late Game, Day 25–60)

**Should feel:** end-of-core-content, prestige preparation, long-term grind.

**Current:**
- Gold flow: ~5,000–7,000g/day.
- +9 upgrade attempts → expected cost 12,400g each. Multiple items = week-long projects.
- Daily quest rewards negligible relative to combat.
- No new content unlocks post-30 (dungeon floors cap at 10; new difficulties?).
- Engagement risk: **plateau phase**.

**Required deficit:** **Sustained. The player must always see a big gold goal ahead.**

**Change:**
- Add new content: Mythic dungeon difficulty (3× multiplier already defined but not surfaced).
- Add "Legendary forging" sink: 100,000g + 5 legendary shards → craft specific legendary.
- Add prestige shop (prestige tokens → unique cosmetics/skills).

---

### 2.6 Levels 40–50 (End Game / Prestige, Day 60+)

**Should feel:** mastery, vanity, community.

**Current:**
- Gold flow: ~10,000g/day.
- +10 upgrade projects (~29,000g each, 15% rate).
- Prestige reset (×1.05 per prestige, stacks to 3.5× at P50) is the only real long-term loop.
- Gems become primarily stamina refill fuel.

**Required deficit:** **Whale pressure.** Player has beaten content, only wants cosmetic / bragging / social. Monetization here is guilds, titles, boosters, skins.

**Change:**
- Guild system (already drafted in spec) should launch here with gold + gem sinks (guild hall upgrades, guild raids, guild shop).
- Prestige bonuses should include cosmetic options (wings, weapon skins) gated by prestige level.
- Introduce "Leaderboard Shop" — seasonal currency earned by ranked performance, spent on exclusive skins.

---

## 3. Shop & monetization redesign

### 3.1 Target IAP ladder

| Price | SKU | Contents | Purpose |
|---|---|---|---|
| $0.99 | Starter Nudge (one-time) | 100 gems + 500g + 1 protection scroll | Frictionless first purchase |
| $2.99 | Starter Bundle (one-time) | 200 gems + 3,000g + 2 uncommon items + 1 BP level | Current, keep |
| $4.99 | Monthly Gem Card | 50 instant + 10/day × 30 | Best value subscription; keep |
| $4.99 | Adventurer's Bundle I | 600 gems + 3,000g + 3 scrolls | Medium first-spend |
| $9.99 | Commander's Chest | 1,400 gems + 10,000g + 1 legendary shard + 5 scrolls | Big bundle sweet spot |
| $9.99/mo | Premium Pass (sub) | +10% gold, +20 gems/day, 2× daily quest gold, cosmetic title, exclusive daily shop slot | **Convert from Premium Forever** |
| $14.99 | BP Instant Unlock | Premium BP + skip 50 levels | Late-season monetization |
| $19.99 | Huge Bundle | 3,200 gems + 20,000g + 2 legendary shards + 10 scrolls | |
| $29.99 | Warlord's Chest | 5,000 gems + 40,000g + 1 guaranteed legendary + 25 scrolls | New tier |
| $49.99 | Mega Bundle | 9,000 gems + 80,000g + 2 guaranteed legendaries | Rebalanced |
| $99.99 | Sovereign Pack | 20,000 gems + 200,000g + 5 legendary shards + 1 month free Premium Pass | New whale tier |

Remove: all pure gold packs.

### 3.2 Shop rotation structure

Replace flat "buy pack anytime" model with:

- **Daily Shop** — 3 rotating offers (cosmetic, small gem/gold, consumable bundle). Reset 00:00 UTC. Player sees urgency.
- **Weekly Shop** — 5 larger bundles. Reset Monday. Mix of consumables, skins, scrolls.
- **Seasonal Shop** — Battle Pass + seasonal cosmetics. Reset every 8 weeks.
- **Event Shop** — Limited-time themed currency, unique cosmetics.
- **Hard-locked packs** — Starter, Commander's Chest, Premium Pass — always available.

Daily/weekly slots should include **"pay with gems"** and **"pay with gold"** options alongside IAP, to create the last-mile pressure on F2P gem reserves.

---

## 4. Block 1 — Main problems (the hit list)

1. **Premium Forever $9.99 one-time = monetization catastrophe.** Must convert to subscription immediately. Single biggest revenue problem in the economy.

2. **Reward scaling (+2%/level) is weaker than cost scaling.** Late-game feels like a treadmill going backwards.

3. **F2P gem floor too high, shop incentive too low.** Player has enough gems to feel OK without spending.

4. **IAP ladder missing $14.99, $29.99, $99.99 tiers** and missing whale products.

5. **Starting resources (300g) too tight — weak first-session feeling.** No "I got something good" moment.

6. **Upgrade system back-loads all pain at +8 to +10.** No gem-assisted path; players who don't RNG through feel cheated rather than challenged.

7. **Dungeons are economically dominated by PvP.** Content mix collapsing.

8. **Daily quests don't scale with level.** Fixed value becomes invisible at L30+.

9. **Stamina cap 120 too low for mobile once-a-day-players.** Overnight regen wasted.

10. **Gold Mine Boost (3 gems) too cheap** — whales turn passive into active for under 1% of a pack.

11. **Shop pack scaling** gives only 23% discount largest-vs-smallest (industry 40–60%). Whales don't see the value.

12. **Gold packs sold directly creates P2W perception** and cannibalizes gem economy.

13. **No first-purchase bonus, no repeatable starter ladder, no time-limited offers.** No urgency anywhere.

14. **Rarity roll bands overlap** — an epic at L5 can roll worse than a common. RNG frustration.

15. **Vendor trash commons (10g sell)** are functionally worthless. No auto-dismantle → no shard currency → no depth.

16. **Achievement ELO targets mismatched with current ladder** (Diamond/GM targets in achievement catalog are from old rating system).

17. **Battle Pass has no "buy levels" option.** Late-joining players abandon BP → lost revenue.

18. **Mid-game wall at L25-30 has no targeted offer to convert.** The single best monetization window is unmonetized.

19. **No guild / clan economy** — spec exists, not live. Missing long-term sink + retention hook.

20. **No "premium mine" or other passive-boost premium product.** One of the easiest monetization surfaces unused.

---

## 5. Block 2 — New economy rules (the constitution)

### Rule 1 — Reward scaling must match cost scaling

Any reward that scales with level uses `reward × (1 + 0.04 × (level − 1))`. Any non-linear cost (repairs, upgrades) must be checked against this curve; gap > 1.5× triggers a rebalance.

### Rule 2 — Two-currency purity

- **Gold** is the F2P grind currency. Earned only through play. **Not sold directly** (pure gold packs removed).
- **Gems** are the premium currency. Earned sparingly through play; primarily bought.
- Gold can only be purchased via gem sinks (Gold Mine Boost, consumable bundles).
- Shards (new secondary) are a craft/enchant currency obtained from auto-dismantle. Non-tradable, non-purchasable.

### Rule 3 — Sink targets

- Daily sink ratio must stay in **60–80%** of income per archetype. Lower = no pressure, higher = rage quit.
- Each archetype (Casual, Active, Whale) should have visible **negative 14-day balance** on at least one non-core system (e.g., "can't afford all upgrades without choosing") but **positive total balance** (never insolvent on essentials).

### Rule 4 — Deficit staging

Three deficit waves, each tied to a monetization offer:

1. **Stamina wall at L7–10** — offer: first cheap stamina refill.
2. **Upgrade variance wall at L20–25** — offer: mid-game bundle with protection scrolls.
3. **Legendary grind wall at L35–40** — offer: warlord's chest, legendary shards, guaranteed craft.

Each wall must be telegraphed (UI hint, soft cap, "resource low" animation). Each must be solvable by grind OR by payment; neither path should feel absent.

### Rule 5 — Reward philosophy

- **Rare things must be visible.** Legendary drops should be *chaseable* (shards + craft), not RNG-only.
- **First-of-day bonus on every repeatable activity** (first PvP, first dungeon, first quest): 2× reward. Pulls players back daily.
- **Streaks are emotional, not economic.** Cap streak bonus at +50% (current). Don't let streaks become a farming optimization.

### Rule 6 — Cost rules

- **Repair cost = `(100 + level × 15) × rarity_mult`** (flattened from 120+lvl×20 and +20% lvl ramp). Repair should be a constant headache, not a late-game crisis.
- **Upgrade success** clamped: +9 at 30% (was 25%), +10 at 20% (was 15%). Expected +10 cost drops from 29k to 21.7k.
- **Upgrade failure at +6+ downgrades item by 1 level** rather than destroys it. Protects player from complete loss; player still loses gold + a level.
- **Consumables: 90% of their value should come from premium content (dungeons, arena, events), 10% from F2P cash.** Players who don't care don't need to buy consumables; players who push hard do.

### Rule 7 — Gem valuation

A gem is worth approximately **1¢ of real money** (at pack blended rate). Every gem price in the economy must be sanity-checked against:

- "Is this a 10-minute-of-play action?" → price ≤ 10 gems (~10 min of F2P gems).
- "Is this a daily action?" → price = 30–60 gems.
- "Is this a weekly-event action?" → price = 300–800 gems.
- "Is this a one-time unlock?" → price = 500–2,000 gems.

Anything outside these bands requires explicit design justification.

### Rule 8 — Premium ≠ pay-to-win

- Premium Pass gives: gold multipliers (up to +10%), convenience (auto-claim, extended cap), cosmetic perks. **Never combat stats.**
- Paid legendaries from bundles must be **≤ 90th percentile** in stats; same distribution as any other legendary. No "paid-only" power.
- Protection scrolls, BP skips, stamina refills: acceptable (time-savers, not power-buyers).

### Rule 9 — First-time-user economy

- Every new player gets an emotional "abundance" moment within the first session.
- Starter Bundle ($2.99) must be **3×–4× value** of any other pack per dollar, because it's one-time.
- First upgrade/dungeon clear/PvP win must show clear progress UI (progress bar, "you got +X power").

### Rule 10 — Transparency

- **Every price in the shop must show a "value comparison"** ("This bundle would cost 1,400 gems at pack rate — save 30%").
- **Every upgrade must display expected cost to next level.**
- **Every IAP must show the breakdown** of what's inside + equivalent gem value.

Transparency reduces regret and increases repeat purchase rate.

---

## 6. Block 3 — Concrete change list (the ticket backlog)

Order: critical → high → medium. Numbers assume W3.D5 baseline. All changes surface as one migration + balance bump.

### Critical (ship immediately)

**C1. Convert Premium Forever → Premium Pass (subscription $9.99/mo).**
- Keep current buyers grandfathered (flag: `premiumLegacyFlag = true`).
- New SKU: `premium_pass_monthly` ($9.99/mo), `premium_pass_yearly` ($79.99/yr).
- Benefits: +10% gold, +20 gems/day (from 25, reduce), 2× daily quest gold, exclusive shop slot, cosmetic title.
- Remove from shop: `premium_forever` SKU goes dark immediately.
- Migration: existing `premium_forever` owners keep all current benefits indefinitely. No recurring cost.

**C2. Raise stamina refill curve.**
- `REFILL_COSTS`: 30/45/75/120 → **50/80/140/240**.
- Keep 4/day cap.

**C3. Raise reward scaling +2% → +4%/level.**
- Update `LEVEL_REWARD_SCALE` constant. Verify all PvP/daily-quest/dungeon reward paths use it. Lens test: L50 PvP win = 297g (old) → 450g (new).

**C4. Revoke direct gold pack SKUs.**
- Disable `gold_500`, `gold_1200`, `gold_3500`, `gold_8000`, `gold_20000`.
- Replace with bundles: `adventurer_bundle_I` ($4.99), `adventurer_bundle_II` ($9.99), etc. Each includes gold + scrolls + small gems.

**C5. Fix achievement ELO targets.**
- `rank_diamond` target 1800 → **3000**.
- `rank_grandmaster` target 2200 → **4250**.
- Audit all `achievement-catalog.ts` ELO targets against new ladder.

### High (ship within 1-2 sprints)

**H1. Starting bundle upgrade.**
- `TUTORIAL.WELCOME_GIFT.gold`: 300 → **500**.
- Add starter chest armor common, pre-equipped.
- Add 1 extra small HP potion (total 3).

**H2. Upgrade success buff and protection improvement.**
- `+9 success`: 25% → **30%**.
- `+10 success`: 15% → **20%**.
- `+6+ failure` changes from "destroy" to "downgrade by 1 level" (new `UPGRADE_FAILURE_MODE = DOWNGRADE`).
- Protection Scroll price: 50 → 40 gems (make it more accessible).

**H3. Shop pack rebalance.**
- Small: 100 gems @ $0.99 (unchanged).
- Medium: 550 → **600** gems @ $4.99.
- Large: 1,200 → **1,400** gems @ $9.99.
- Huge: 2,500 → **3,200** gems @ $19.99.
- Mega: 6,500 → **9,000** gems @ $49.99.
- New: Ultra (20,000 gems + 1 month Premium Pass + 5 legendary shards) @ $99.99.

**H4. Stamina cap 120 → 180.**
- Corresponding change: `STAMINA.MAX = 180`. Verify UI displays, regen calculations.

**H5. Rarity roll floors.**
- Implement in `item-balance.ts`: per-rarity minimum stat roll = `rarityFloorPercent × maxStatForLevel`.
- Floors: Common 40%, Uncommon 55%, Rare 65%, Epic 75%, Legendary 85%.

**H6. Daily quest level scaling.**
- Apply `(1 + 0.04 × (level − 1))` to daily quest gold rewards.

**H7. Dungeon rewards uplift.**
- Per-floor gold × 1.25.
- First-clear-of-day bonus: **2× gold + 1 guaranteed uncommon+ drop**.
- Dungeon floor 10 boss drop: guaranteed rare+ (current: RNG).

**H8. First-purchase-per-SKU double-gems bonus.**
- Standard industry pattern. Flag in `CharacterIAPHistory` table.

**H9. Gold Mine Boost: 3 → 10 gems.**
- Revert to original cost. Add "bulk skip" (5× for 45 gems = 10% discount).

### Medium (ship within 1–3 months)

**M1. Legendary shard system.**
- New currency: `legendary_shards`. Earned via: dailies (1/week), BP premium (10/season), achievements (20 total), shop daily rotation.
- Craft: 5 shards → 1 guaranteed legendary of chosen slot.
- Bundle: $9.99 "Commander's Chest" includes 1 legendary shard.

**M2. Auto-dismantle + shards.**
- Common/Uncommon items below player level auto-dismantle into `essence_shards`.
- Shards spend on: reroll stats (100 shards), enchant (200 shards), transmog (50 shards).

**M3. IAP ladder additions.**
- Add $14.99 (BP Instant Unlock), $29.99 (Warlord's Chest), $99.99 (Sovereign Pack).

**M4. Shop rotation structure.**
- Daily Shop (3 slots), Weekly Shop (5 slots), Event Shop.
- Add "pay with gold" option in daily slots (creates last-mile gold sink).

**M5. Mid-game one-time offer at L25.**
- Triggered event: at character hits L25, shows a **one-time offer popup** valid 48 hours.
- Price: $9.99. Contents: 1,500 gems + 5,000g + 3 protection scrolls + 2 legendary shards + 1 month Premium Pass trial (7 days).

**M6. BP skip levels.**
- `+10 BP levels` IAP: 300 gems.
- `+25 BP levels` IAP: 700 gems.
- `BP Instant (50 levels + Premium)`: $14.99.

**M7. Stamina-off-peak regeneration.**
- While offline (> 4h since last action), stamina regens 1/4 min (2× normal).
- Cap still 180. This compensates for sleep without letting dedicated whales exploit it.

**M8. Daily quest bonus at 3/3.**
- Currently 3/3 quests = 3 separate rewards. Add **"All quests" bonus**: 1× bonus chest with 200g × (1 + 0.04 × (lvl − 1)) + 5 gems + 1 BP level.

**M9. Guild economy.**
- Per existing spec. Launch with: guild gold bank, guild shop (consumable bundles at discount), guild challenges (gold sink per member), guild raids (weekly gold/gem drop).

**M10. Leaderboard seasonal shop.**
- New currency: `ranking_crystals`. Earned per weekly PvP performance. Spend on exclusive skins, titles, cosmetic mounts.

### Low (opportunistic)

**L1. Premium Mine.** Additional 4th slot at +50% yield, gated by Premium Pass subscription.

**L2. First-to-hit achievements with seasonal flag.** E.g., "First to L50 this season" → title + 1,000 gems.

**L3. Cosmetic marketplace.** Player-to-player trade of cosmetics (no stats).

**L4. Referral rewards.** Both referrer and referred get 500g + 100 gems after referred reaches L10.

**L5. Gem-economy diagnostic dashboard.** Admin panel tool showing live aggregate gem flow per source/sink, updated daily.

---

## 7. Block 4 — Target economic model

A healthy Hexbound economy looks like this.

### 7.1 Early game (L1–10, Day 1–3) — Abundance

- Every session ends with the player feeling they gained something.
- Shop has multiple affordable targets (weapons, armor, consumables) at every visit.
- Upgrades succeed 100% through +5 — smooth positive feedback.
- First-time-player "wow" moment in first 15 minutes (First Victory Chest, L10 milestone gem grant).
- Light stamina pressure around L7–10 — player wants more PvP than free stamina allows. Offered cheap first refill (15 gems, 50% off).

**Target feel:** "I'm getting stronger and there's always something to buy."

### 7.2 Mid-early game (L10–20, Day 4–10) — Interesting choices

- Gold is plentiful enough to choose WHAT to upgrade, not whether to upgrade.
- First RNG encounter at +6–+7 upgrades — acceptable occasional failure.
- First hit at Battle Pass decision point: buy premium or keep grinding.
- F2P gem reserve (~50–80) sufficient for 1 refill + BP consideration.
- Legendary shards introduced as a chase goal; player sees shards dripping in from various sources.

**Target feel:** "I have a plan. I know what I want next."

### 7.3 Mid game (L20–30, Day 10–25) — Controlled friction

- **Primary monetization window.** Gold tight, gems tighter, upgrade variance biting.
- Player sees mid-game one-time offer — highest conversion point.
- Premium Pass evaluation happens here. Value is obvious (gold multiplier + gems + convenience).
- Players who don't convert still have a workable grind path; it's just slower.

**Target feel:** "I want more. I'm considering whether to spend."

### 7.4 Late game (L30–40, Day 25–60) — Long-term commitment

- Gold flow high enough that +8 upgrades feel achievable; +10 is a 1-2 week project per item.
- Prestige and Mythic dungeons unlock as new grind loops.
- Premium Pass subscribers pay monthly for compounding value.
- Whales push IAP ladder through Commander's Chest, Warlord's Chest.
- Legendary crafting becomes the primary long-term goal.

**Target feel:** "I am mastering this game. I see the endgame."

### 7.5 End game / prestige (L40+, Day 60+) — Vanity + social

- Combat power mostly horizontal (prestige multiplier, late legendary drops).
- Revenue primarily from: cosmetics, guild systems, seasonal leaderboards, event shops.
- Veteran F2P retention through social features and cosmetic chase.
- Whale retention through exclusive Ultra/Sovereign packs and limited-time event exclusives.

**Target feel:** "This is my game. I play for my guild / my rank / my look."

### 7.6 Health metrics (what to track in analytics)

- **D1 / D7 / D30 retention** — the ultimate judges.
- **Conversion window**: % of non-payers who spend before L25 (target: >25%).
- **ARPDAU split** by archetype (Casual / Active / Whale).
- **Sink ratio per archetype** (maintain 60–80% target band).
- **Gem bank median per archetype** — if F2P median climbs above 400 gems, we're too generous.
- **Upgrade abandonment rate** at +7, +8, +9 — if > 40% at any stage, tuning is off.
- **Dungeon/PvP session ratio** — target 40/60 or 50/50; if < 25% dungeon, dungeons are dead content.
- **Premium Pass churn rate** — target < 15%/month.
- **First purchase → second purchase conversion** — if < 40%, the IAP ladder has a broken rung.

### 7.7 The shape of a healthy Hexbound economy (one paragraph)

A new player lands in a game that feels generous for the first two days — they win, upgrade, try new classes. By day three, the first soft pressure arrives: they want more stamina than they can regenerate, and a 15-gem offer makes them consider their first purchase. By the end of week one, they've hit L15, seen the battle pass, and either subscribed to the gem card or committed to the grind. From week two to week four, the game systematically tightens: repair costs rise, upgrade variance kicks in, and a mid-game offer at L25 creates the primary conversion event. Past L30, the game opens back up — new difficulty tiers, legendary crafting, guilds, prestige. The whale has a clear ladder of products and events that keep getting bigger. The F2P has a slow but visible path to everything. No one ever feels cheated, because every premium benefit is convenience, not combat power. The grind is real but always in motion. The shop is a place of urgency, not a dead catalog. That is the target.

---

## Appendix A — Raw number dump (ground truth)

Maintained in the extraction report. Key deltas from this document versus current W3.D5 state are captured in Block 3.

## Appendix B — Open questions for design / product

1. **Are current D7 and D30 analytics available?** We're operating on estimation; conversion modeling needs real data.
2. **What is realized ARPDAU today?** Should be measurable from `CharacterIAPHistory`.
3. **Guild system launch date?** Block 3 depends on this for long-term sinks.
4. **Willingness to grandfather Premium Forever owners indefinitely** (necessary for C1 migration without trust damage)?
5. **Content roadmap past floor 10 dungeons?** Late-game economy depends on new content cadence.
6. **Cosmetic art pipeline capacity?** Cosmetic-driven monetization depends on art throughput.

---

*End of audit.*
