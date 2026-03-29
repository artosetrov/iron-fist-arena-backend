# Game Balance Constants (Source of Truth)

*Derived from backend: `src/lib/game/balance.ts`, `live-config.ts`, `loot.ts`, `gold-mine.ts`*

---

## Stamina System

### Maximum & Regeneration

| Property | Value | Details |
|----------|-------|---------|
| Maximum Stamina | 120 | Hard cap |
| Regen Rate | 1 point | Per interval |
| Regen Interval | 8 minutes | Every 8 min → +1 stamina |
| Regen Duration | Infinite | Always regenerating |

**Regen Timeline:** At 0 stamina, reach full 120 in 960 minutes (16 hours)

### Stamina Costs by Activity

| Activity | Stamina Cost | Notes |
|----------|--------------|-------|
| PvP Match | 10 | Standard combat |
| Dungeon Easy | 15 | Tutorial difficulty |
| Dungeon Normal | 20 | Standard difficulty |
| Dungeon Hard | 25 | Challenging |
| Boss Fight | 40 | High-difficulty encounter |
| Training | 5 | Low-cost practice |
| Free PvP | 5 per match | Max 5/day (no cost) |
| Extra PvP (Gem) | +5 stamina | Purchased with 50 gems |

**Free PvP System:** Players get 5 free PvP matches per day (0 stamina), then must spend stamina or gems.

### Stamina Potion Types

| Type | Effect | Source | Rarity |
|------|--------|--------|--------|
| Small | +50 stamina | Daily login (Day 2, 4) | Common |
| Large | +100 stamina | Daily login (Day 6) | Uncommon |

**Stacking:** Potions add to current stamina (can exceed max temporarily in code, but capped at display).

---

## Gold Rewards

### Base Rewards

| Activity | Win Reward | Loss Reward | Notes |
|----------|-----------|-----------|-------|
| **PvP** | 200 gold | 70 gold | Standard ranked (buffed from 150/50, 2026-03-25) |
| **Training** | 50 gold | 20 gold | Practice mode |

### PvP Gold Multipliers

Rewards scale with **character level:**

```
Leveled Reward = Base × (1 + (level - 1) × 0.02)
```

| Level | Multiplier | Example (200 base) |
|-------|-----------|-------------------|
| 1 | 1.00× | 200 |
| 10 | 1.18× | 236 |
| 25 | 1.48× | 296 |
| 50 | 1.98× | 396 |

### Special Multipliers

| Bonus | Multiplier | Conditions | Stack? |
|-------|-----------|-----------|--------|
| **First Win of Day** | 2.0× | First PvP win daily | No |
| **Revenge Win** | 1.5× | Beat player who beat you | No |
| **Win Streak** | Variable | See below | Yes |
| **CHA Bonus** | Tiered (see below) | Hard cap +125% | Yes |
| **Loss Streak Recovery** | Variable | See below | Yes |

### Win Streak Bonuses

Gold reward multiplier based on consecutive wins:

| Streak | Multiplier | Threshold |
|--------|-----------|-----------|
| 0–2 | 0% | No bonus |
| 3 | +20% | 3-win streak |
| 4 | +20% | Streak continues |
| 5 | +50% | Significant milestone |
| 6–7 | +50% | Sustained streak |
| 8+ | +100% | Doubling rewards |

**Example (200 base gold, 3-win streak, CHA 30):**
- Level scaling: 200 × 1.0 = 200
- Streak bonus: 200 × 1.20 = 240
- CHA bonus: 240 × 1.75 = 420 gold
- **Total: 420 gold**

### Loss Streak Recovery Bonuses

When a losing streak is broken by a win, bonus gold is awarded:

| Streak | Multiplier | Threshold |
|--------|-----------|-----------|
| 0–2 | 0% | No bonus |
| 3–4 | +30% | Breaking 3+ loss streak |
| 5–6 | +50% | Significant recovery |
| 7+ | +80% | Major comeback bonus |

### CHA Gold Bonus (Diminishing Returns)

Charisma gold bonus uses tiered diminishing returns with a hard cap:

```
CHA 0-30:  +2.5% per point (max +75%)
CHA 31-60: +1.0% per point (max +105% cumulative)
CHA 61+:   +0.5% per point (hard cap +125%)
```

**Calculation:**
- CHA 25 → +62.5% gold (25 × 2.5%)
- CHA 30 → +75% gold (cap for tier 1)
- CHA 50 → +95% gold (75% + 20 × 1.0%)
- CHA 60 → +105% gold (75% + 30 × 1.0%)
- CHA 100 → +125% gold (75% + 30% + 40 × 0.5% = 125%, at hard cap)
- Hard cap: +125% regardless of CHA value

---

## XP Rewards

### Base XP Rewards

| Activity | Win XP | Loss XP | Notes |
|----------|---------|---------|-------|
| **PvP** | 150 XP | 50 XP | Ranked combat |
| **Training** | 60 XP | 20 XP | Practice mode |

**First Win Bonus:** 2× XP multiplier (same as gold)

### XP Formula

XP to reach level N (cumulative):

```
XP = 100N + 20N²
```

| Level | Total XP | From Prev | Hours (avg) |
|-------|----------|-----------|------------|
| 1 | 0 | — | — |
| 2 | 280 | 280 | 2.3 hrs |
| 5 | 1200 | 420 | 1.4 hrs |
| 10 | 3000 | 800 | 2.7 hrs |
| 25 | 14000 | 3200 | 10.7 hrs |
| 50 | 55000 | 8800 | 29.3 hrs |

**Avg XP/hour (PvP):** ~150 XP/win × 5 wins/hour = 750 XP/hour (varies by skill)

---

## Leveling System

### Level Progression

| Property | Value | Details |
|----------|-------|---------|
| Max Level | 50 | Hard cap |
| Stat Points/Level | 3 | Allocatable to STR/AGI/VIT/END/INT/WIS/LUK/CHA |
| Passive Points/Level | 1 | For passive tree |
| Total Stat Points | 147 | 3 × (levels 1-50) + starting 0 |
| Total Passive Points | 49 | 1 × (levels 2-50) |

### Level Cap Mechanics

At level 50:
- XP no longer increases level
- XP counter continues accumulating
- Must prestige to level up again
- Prestige resets level to 1, keeps XP

---

## Prestige System

### Prestige Mechanics

| Property | Value | Details |
|----------|-------|---------|
| Requirement | Level 50 | Must reach max level |
| Level Reset | Yes | Back to 1 |
| Stat Reset | Yes | Stat allocations reset |
| Equipment | Retained | All items stay |
| Gold | Retained | Currency unchanged |
| Passive Tree | Retained | All unlocked nodes remain |

### Prestige Bonuses

All stats multiplied by prestige factor:

```
Stat Multiplier = 1 + (Prestige Level × 0.05)
```

| Prestige | Multiplier | Example (Base 100) |
|----------|-----------|-------------------|
| 0 | 1.00× | 100 |
| 1 | 1.05× | 105 |
| 5 | 1.25× | 125 |
| 10 | 1.50× | 150 |
| 20 | 2.00× | 200 |
| 50 | 3.50× | 350 |

**Infinite scaling:** No prestige cap.

---

## Equipment Upgrade System

### Upgrade Chances

Equipment can be upgraded from +0 to +10:

| Upgrade Level | Success % | Attempts to Success (avg) |
|---------------|-----------|--------------------------|
| +1 | 100% | 1 |
| +2 | 100% | 1 |
| +3 | 100% | 1 |
| +4 | 100% | 1 |
| +5 | 100% | 1 |
| +6 | 80% | 1.25 |
| +7 | 60% | 1.67 |
| +8 | 40% | 2.5 |
| +9 | 25% | 4 |
| +10 | 15% | 6.7 |

**Expected cost to +10:** ~6.7 upgrade attempts (expensive!)

---

## Item Drop System

### Drop Chances by Difficulty

| Difficulty | Drop Chance | LUK Bonus | Cap |
|-----------|----------|----------|-----|
| PvP | 15% | 0.3% per LUK | Configurable |
| Training | 5% | 0.3% per LUK | Configurable |
| Dungeon Easy | 20% | 0.3% per LUK | Configurable |
| Dungeon Normal | 30% | 0.3% per LUK | Configurable |
| Dungeon Hard | 40% | 0.3% per LUK | Configurable |
| Boss | 75% | 0.3% per LUK | Configurable |

**LUK Calculation:**
```
Final Drop Chance = Base + (LUK × 0.003)
Capped at drop chance cap (live config)
```

**Example (20% base, LUK 50):**
- Chance = 20% + (50 × 0.3%) = 20% + 15% = 35%

### Rarity Distribution

Base distribution (no level bonus):

| Rarity | Chance |
|--------|--------|
| Common | 50% |
| Uncommon | 30% |
| Rare | 15% |
| Epic | 4% |
| Legendary | 1% |

**Level Bonus:** Higher level characters get better drops via live config tuning.

---

## Gem Costs

Premium currency sinks:

| Action | Cost | Notes |
|--------|------|-------|
| Stamina Refill | 30 gems | Instant full stamina |
| Extra PvP Combat | 50 gems | +5 stamina immediately |
| Battle Pass Premium | 500 gems | Unlocks premium track (100 levels) |
| Gold Mine Slot (buy) | 50 gems | Unlock 3rd mining slot |
| Gold Mine Boost | 10 gems | Speed up current slot by 2 hours |
| Passive Respec | 50 gems | Full passive tree reset |

### Gem Income

Players earn free gems from:
- Daily login (Day 7) = 25 gems/week
- Achievements = 5–50 gems per achievement
- Battle pass free track = 50+ gems per season

---

## Gold Mine (Passive Income)

### Mining Mechanics

| Property | Value | Details |
|----------|-------|---------|
| Duration per Slot | 4 hours | Timer per active mine |
| Max Slots | 3 | Can mine simultaneously |
| Reward Range | 60–150 gold | Per completed slot (nerfed from 100–250, 2026-03-25) |
| Gem Drop Chance | 10% | Per collection |
| Gem Drop Amount | 1–3 | If gems drop |

**Example (3 slots, all mining):**
- 4 hours later → collect 3 slots → ~315 gold + (30% chance) gems

### Boost Mechanics

| Cost | Effect |
|------|--------|
| 10 gems | Speed up slot by 2 hours (reduces remaining time) |
| Multiple boosts | Can stack (e.g., 2 boosts = 4 hours faster) |

---

## Inventory System

### Capacity Management

| Property | Value | Details |
|----------|-------|---------|
| Base Slots | 28 | Starting inventory |
| Max Slots | 100 | Hard cap |
| Expansion Amount | 10 slots per upgrade | +10 per purchase |
| Expansion Cost | 5000 gold per upgrade | Increases with levels |
| Max Expansions | 3 | 28 + (3 × 10) = 58 max |

**Actual Max:** 28 + 30 = 58 slots (not 100)

---

## In-App Purchase (IAP) Products

### Gem Packs

| SKU | Gems | Gold | Premium | Monthly Card | Price |
|-----|------|------|---------|-------------|-------|
| gems_small | 100 | 0 | No | No | $0.99 |
| gems_medium | 550 | 0 | No | No | $4.99 |
| gems_large | 1200 | 0 | No | No | $9.99 |
| gems_huge | 2500 | 0 | No | No | $19.99 |
| gems_mega | 6500 | 0 | No | No | $49.99 |

### Gold Packs

| SKU | Gems | Gold | Premium | Monthly Card | Price |
|-----|------|------|---------|-------------|-------|
| gold_500 | 0 | 500 | No | No | $0.99 |
| gold_1200 | 0 | 1200 | No | No | $1.99 |
| gold_3500 | 0 | 3500 | No | No | $4.99 |
| gold_8000 | 0 | 8000 | No | No | $9.99 |
| gold_20000 | 0 | 20000 | No | No | $19.99 |

### Special Products

| SKU | Gems | Gold | Premium | Monthly Card | Price |
|-----|------|------|---------|-------------|-------|
| monthly_gem_card | 50 | 0 | No | **Yes** | $4.99 |
| premium_forever | 0 | 0 | **Yes** | No | $9.99 |

**Monthly Gem Card:** 50 instant gems + 10 gems/day for 30 days (500 total)

**Premium Forever:** One-time unlock (server-side flag)

---

## Daily Login Rewards (7-Day Cycle)

### Reward Schedule

| Day | Reward Type | Amount | Equivalent |
|-----|-----------|--------|-----------|
| 1 | Gold | 200 | |
| 2 | Stamina Potion (Small) | 1 | +50 stamina |
| 3 | Gold | 500 | |
| 4 | Stamina Potions (Small) | 2 | +100 stamina |
| 5 | Gold | 1000 | |
| 6 | Stamina Potion (Large) | 1 | +100 stamina |
| 7 | Gems | 25 | Premium currency |

**Weekly Total:** 1700 gold + 250 stamina + 25 gems

### Streak System

| Condition | Result |
|-----------|--------|
| Claim within 24 hrs | Day progresses (day 1 → day 2) |
| Miss 48+ hrs | Streak resets to day 1 |

---

## Battle Pass System

### XP Sources

| Activity | BP XP | Scaling | Notes |
|----------|-------|---------|-------|
| PvP Combat | 20 XP | None | Any match |
| Dungeon Floor | 30 XP | None | Per floor cleared |
| Story/Daily Quest | 50 XP | None | Completion reward |
| Achievement | 100 XP | None | One-time bonus |

### BP Level Formula

XP required per level:

```
BP XP for Level N = 100 + N × 50
```

| Level | XP Required | Cumulative |
|-------|-----------|-----------|
| 1 | 100 | 100 |
| 10 | 600 | 5,050 |
| 50 | 2600 | 82,500 |
| 100 | 5100 | 305,000 |
| 150 | 7600 | 615,000 |

### Battle Pass Tiers

| Track | Levels | Cost | Contents |
|-------|--------|------|----------|
| Free | 50 | Free | Cosmetics, consumables, 5 gems |
| Premium | +100 | 500 gems | Rare items, 100+ gems, cosmetics |
| Total | 150 | — | Full seasonal reward set |

---

## Skill System

### Skill Slots & Learning

| Property | Value | Details |
|----------|-------|---------|
| Max Equipped Slots | 4 | Can use up to 4 at once |
| Learn Cost | 200 gold | One-time per skill |
| Upgrade Cost | 500 + (500 × rank) gold | Progressive cost |

**Example upgrade costs:**
- Rank 1 → 2: 500 + 500 = 1000 gold
- Rank 2 → 3: 500 + 1000 = 1500 gold
- Rank 5 → 6: 500 + 2500 = 3000 gold

---

## Passive Tree

### Points & Costs

| Property | Value | Details |
|----------|-------|---------|
| Points/Level | 1 point | 1 per level up |
| Max Points | 50 | Hard cap |
| Respec Cost | 50 gems | Full tree reset |
| Prestige Interaction | Preserved | Unlocked nodes stay |

---

## Shell Game (Minigame)

| Property | Value | Details |
|----------|-------|---------|
| Bet Range | 50–1000 gold | Player configurable |
| Win Payout | 2× bet | Double or nothing |
| RTP | 50% | Fair probability |

**Example:** Bet 100 gold → 50% win (200 gold), 50% loss (0 gold)

---

## PvP Matchmaking Parameters

Matchmaking uses a **3-phase cascade** — each phase widens the search if too few candidates are found.

| Parameter | `/pvp/opponents` | `/pvp/find-match` |
|-----------|-------------------|-------------------|
| Max returned | 5 | 3 |
| Level range | ±10 | ±10 |
| Gear score tolerance | ±80% | ±80% |
| Display (iOS) | 2 at a time (carousel) | N/A |

**Phase 1:** Level ±10 AND gear score ±80% → `take: 15`
**Phase 2 (fallback):** Level ±10 only (no gear filter) → merge without duplicates
**Phase 3 (final fallback):** ANY character (no level/gear filter) → merge without duplicates

Sorting: closest `levelDiff` first, then closest `gearDiff`. Top N returned.

**Why wide range:** Early-stage player pool is small. The cascade ensures opponents are always shown, with closest matches ranked first. Tighten ranges as player base grows.

**Note:** Matchmaking does NOT use `pvpRating` for filtering — rating is display-only. If rating-based matchmaking is added, see archive audit for smurf/manipulation concerns.

---

## Reference Table: Stamina Costs Summary

```
Training: 5 stamina
Free PvP: 0 stamina (×5 per day)
PvP: 10 stamina
Dungeon Easy: 15 stamina
Dungeon Normal: 20 stamina
Dungeon Hard: 25 stamina
Boss: 40 stamina
Max Stamina: 120 (regenerates 1 pt every 8 min)
```

---

## Reference Table: Gold Earning Rates

**PvP (Level 1, no bonuses):**
- Win: 200 gold
- Loss: 70 gold
- Avg per match: 135 gold

**PvP (Level 50, no bonuses):**
- Win: 200 × 1.98 = 396 gold
- Loss: 70 × 1.98 = 139 gold
- Avg per match: 268 gold

**Training (Level 1):**
- Win: 50 gold
- Loss: 20 gold
- Avg: 35 gold

**Gold Mine (passive):**
- ~105 gold per 4 hours = ~26 gold/hour (nerfed from ~200/4h)

---

## Monetization Summary

### Free-to-Play Paths

1. **Stamina Passive:** 8 minutes = 1 stamina (120 max)
2. **Gold Grinding:** 50–300 gold per match (PvP/Training)
3. **Loot Farming:** 5–75% drop chance per difficulty
4. **Daily Rewards:** 1700 gold + 250 stamina/week
5. **Gold Mine:** 60–150 gold per 4 hours (nerfed 2026-03-25)

### Pay-to-Accelerate Options

1. **Stamina Refills:** 30 gems = instant 120 stamina
2. **Extra PvP:** 50 gems = +5 stamina immediately
3. **Inventory Expansion:** 5000 gold = +10 slots (tradeable in time)
4. **Skill Upgrades:** 1000–3000 gold per rank
5. **Monthly Card:** $4.99 = 50 + 300 gems over 30 days

**Fair Play Guarantee:** No pay-to-win stat advantages; only acceleration/cosmetics.

---

## Guild Weekly Challenges

Server-wide cooperative goals. All players contribute to a shared target.

| Challenge | Goal Type | Target | Gold Reward | Gem Reward |
|-----------|-----------|--------|-------------|------------|
| Warpath | pvp_wins | 500 | 2000 | 50 |
| Gold Rush | gold_earned | 100000 | 3000 | 30 |
| Dungeon Crawl | dungeons_cleared | 200 | 2500 | 40 |
| Arms Race | items_upgraded | 300 | 2000 | 60 |
| Boss Hunters | bosses_killed | 150 | 3000 | 50 |

Duration: 7 days per challenge. Progress incremented atomically via SQL LEAST() cap.

---

## Dungeon Rush Artifacts

Roguelike artifacts offered as 3 choices after miniboss kills. Max 2 per run (2 minibosses).

| Artifact | Effect | Details |
|----------|--------|---------|
| Bloodstone Amulet | Lifesteal | 8% damage dealt healed |
| Goldweave Cloak | Gold mult | 1.5x all gold rewards |
| Scholar's Tome | XP mult | 1.4x all XP rewards |
| Iron Heart | Damage reduction | 12% less damage (cap 30%) |
| Razorfang Pendant | Crit damage | +30% critical hit damage |
| Thornmail Sigil | Thorns | 15% damage reflected |
| Soul Siphon | Heal on kill | 15% HP after each kill |
| Giant's Belt | Stat boost | +200 Max HP |
| Shadow Blade | Stat boost | +25 STR |
| Wind Walker Boots | Stat boost | +25 AGI |

---

## Item Sets

5 equipment sets with 2/3/5-piece bonuses. Set pieces drop from boss-exclusive loot table.

| Set | Theme | 2pc | 3pc | 5pc |
|-----|-------|-----|-----|-----|
| Shadow Assassin | AGI/Crit | +15 AGI, +5 Crit | +10 STR, +3 Dodge | +25 AGI, +12 Crit, +15 STR |
| Iron Bastion | Armor/VIT | +20 Armor, +10 VIT | +150 MaxHP, +8 END | +40 Armor, +300 MaxHP, +20 VIT |
| Arcane Scholar | INT/WIS | +15 INT, +10 WIS | +15 MRes, +10 INT | +30 INT, +20 WIS, +25 MRes |
| Berserker's Wrath | STR/Crit | +20 STR, +5 AGI | +8 Crit, +10 STR | +35 STR, +15 Crit, +200 MaxHP |
| Fortune Seeker | LUK/CHA | +15 LUK, +5 CHA | +20 LUK, +10% gold | +40 LUK, +15 CHA, +5% drops |
| Wanderer's Charm | CHA/LUK (early) | +8 CHA, +8 LUK | +15 CHA, +15 LUK, +3% gold, +2% drops | — (3-piece set) |

---

## Level Milestone Rewards

One-time rewards per character, targeting midgame dead zones.

| Level | Gold | Gems | Title |
|-------|------|------|-------|
| 10 | 1000 | 20 | Adventurer |
| 15 | 1500 | 25 | Veteran |
| 20 | 2500 | 40 | Champion |
| 25 | 3000 | 50 | Warlord |
| 30 | 4000 | 60 | Overlord |
| 35 | 5000 | 75 | Grandmaster |
| 40 | 7500 | 100 | Mythic |
| 50 | 10000 | 150 | Ascended |

Auto-awarded on level-up via `checkAndAwardMilestones()` in progression.ts.
DB model: `MilestoneClaim` (character_id + milestone_level, unique constraint).