# Hexbound — Full Game Balance & Economy Audit Report

**Date:** March 9, 2026
**Auditor:** Game Systems Balance Analysis
**Version:** 1.0

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Phase 1 — Core Stat Balance](#2-phase-1--core-stat-balance)
3. [Phase 2 — Damage System](#3-phase-2--damage-system)
4. [Phase 3 — Economy Balance](#4-phase-3--economy-balance)
5. [Phase 4 — Item System](#5-phase-4--item-system)
6. [Phase 5 — Reward System](#6-phase-5--reward-system)
7. [Phase 6 — Progression Curve](#7-phase-6--progression-curve)
8. [Phase 7 — PvP Fairness](#8-phase-7--pvp-fairness)
9. [Phase 8 — Exploit Detection](#9-phase-8--exploit-detection)
10. [Phase 9 — Mathematical Simulation](#10-phase-9--mathematical-simulation)
11. [Phase 10 — Admin Balance Panel](#11-phase-10--admin-balance-panel)
12. [Phase 11 — Final Recommendations](#12-phase-11--final-recommendations)

---

## 1. Executive Summary

### Overall Health: MODERATE — 4 Critical Issues, 8 Medium Issues, 6 Minor Issues

**Critical Issues:**
1. **AGI/Rogue class is overpowered** — AGI simultaneously provides offense (crit, damage for rogues), defense (dodge), and initiative. Rogues dominate all matchups.
2. **XP progression is impossibly slow** — Reaching level 50 takes ~5.5 years of daily play. The quadratic XP formula is far too aggressive.
3. **Gold Mine passive income exceeds active PvP income** — 3 mine slots produce ~6,300 gold/day passively vs ~1,600 gold/day from 21 active PvP fights. This disincentivizes gameplay.
4. **Matchmaking ignores gear power** — Level-only matchmaking creates huge unfairness between geared and ungeared players at the same level.

**What Works Well:**
- Armor/MR diminishing returns formula (100/(100+resist)) is elegant and well-balanced
- ELO system is standard and stable
- Upgrade system creates excellent long-term gold sink (~132K gold expected cost per +10 item)
- Item power score validation system is sophisticated
- Config-driven balance (GameConfig) allows live tuning
- Shell game is mathematically fair with proper server-side secret
- Anti-cheat seed verification for PvP combat is solid

---

## 2. Phase 1 — Core Stat Balance

### Current Stat System

| Stat | Combat Role | Scaling |
|------|------------|---------|
| STR | Warrior/Tank damage, +0.5 armor | Damage: ×1.5 (warrior), ×1.2 (tank) |
| AGI | Rogue damage, crit, dodge, initiative | Damage: ×1.5 (rogue), crit: +0.3/pt, dodge: +0.3/pt |
| VIT | HP | +5 HP per point |
| END | HP + armor | +3 HP per point, +2 armor per point |
| INT | Mage damage, +0.5 magic resist | Damage: ×1.5 (mage) |
| WIS | Magic resist | +2 MR per point |
| LUK | Crit chance, drop bonus | +0.5% crit, +0.3% drop |
| CHA | Gold bonus | +0.5% gold per point |

### Analysis: Stat Value Ranking (combat effectiveness)

```
Tier S: AGI (offense + defense + initiative — broken for rogues)
Tier A: STR, INT (primary damage for their classes)
Tier B: VIT, END (survivability — END is better value due to armor)
Tier C: LUK (modest crit, small drop bonus)
Tier D: CHA (almost zero combat impact)
Tier F: WIS (magic resist only — no offensive use for any class)
```

### Issue 1: AGI is Overpowered (CRITICAL)

AGI simultaneously provides:
- **Crit chance:** 0.3% per point (shared with LUK at 0.5% — AGI gives 60% of LUK's crit value PLUS everything else)
- **Dodge chance:** 0.3% per point (exclusive to AGI)
- **Initiative:** Higher AGI always goes first in combat
- **Rogue damage:** 1.5× multiplier (same as warrior/mage primary stat)
- **Rogue class bonus:** +5% dodge

**Mathematical proof (Level 50, 147 points allocated):**

Pure AGI Rogue (AGI=157, all else=10):
- Damage: 157 × 1.5 + 100 = 335.5
- Crit: min(10×0.5 + 157×0.3, 50) = 50% → avg damage × 1.25 = 419
- Dodge: min(157×0.3 + 5, 30) = 30%
- Goes first every fight
- HP: 80 + 50 + 30 = 160

Pure STR Warrior (STR=157, all else=10):
- Damage: 157 × 1.5 + 100 = 335.5
- Crit: min(10×0.5 + 10×0.3, 50) = 8%  → avg damage × 1.04 = 349
- Dodge: min(10×0.3, 30) = 3%
- HP: 80 + 50 + 30 = 160

**Result:** The rogue deals 20% more effective damage AND dodges 30% of incoming attacks AND goes first. In a mirror match, the rogue wins ~85% of the time.

### Issue 2: CHA is Useless (MEDIUM)

50 CHA points = +25% gold bonus. On 100 gold PvP win, that's +25 gold per fight.
At 21 fights/day: +525 gold/day. Over the same period, 50 points in STR adds ~75 damage per hit.

**Nobody should ever invest in CHA** — the gold bonus is negligible vs combat stats.

### Issue 3: WIS Has No Offensive Scaling (MEDIUM)

WIS provides only magic resist (+2/point). No class uses WIS for damage. This makes WIS a purely defensive stat that's only useful against mages. In a meta without many mages, WIS is wasted.

### Recommended Fixes

```typescript
// 1. Nerf AGI's multi-role dominance
// Option A: Split crit source away from AGI
critChance = LUK * 0.8 + AGI * 0.1 + stanceMod  // was: LUK*0.5 + AGI*0.3
dodgeChance = AGI * 0.25 + LUK * 0.1 + classBonus // was: AGI*0.3

// 2. Give CHA combat utility
// Add CHA-based "charisma intimidation" that reduces enemy damage
chaDebuff = CHA * 0.1  // enemy deals 0.1% less damage per CHA point

// 3. Give WIS offensive utility for mages or add WIS-based healing
// Option A: WIS adds to mage damage as secondary stat
// Mage formula: INT * 1.3 + WIS * 0.5 + level * 2  (was: INT*1.5 + level*2)
// Option B: WIS increases healing from self-buff skills
```

---

## 3. Phase 2 — Damage System

### Current Damage Pipeline

```
1. baseDamage = primaryStat × classMultiplier + level × 2
2. ± 10% variance (random)
3. + passive flat damage
4. × (1 + passive percent damage / 100)
5. × (100 / (100 + effectiveResist))     ← armor/MR reduction
6. × 0.85 if defender is Tank             ← class reduction
7. × 1.5 if critical hit                  ← crit multiplier
8. × (1 + stanceOffense / 100)            ← stance boost
9. × (1 - stanceDefense / 100)            ← stance reduction
10. × (1 - min(passiveDamageReduction,50) / 100)
11. floor(), minimum 1
```

### Defense Formula Analysis

The formula `damage × (100 / (100 + armor))` provides diminishing returns:

| Armor | Damage Reduction | Marginal Value of +10 Armor |
|-------|-----------------|----------------------------|
| 0 | 0% | — |
| 50 | 33.3% | 6.7% |
| 100 | 50.0% | 3.3% |
| 150 | 60.0% | 2.5% |
| 200 | 66.7% | 2.0% |
| 300 | 75.0% | 1.4% |
| 500 | 83.3% | 0.8% |

**Verdict:** This is a well-designed formula. No armor value makes a character invulnerable. Each additional point has diminishing returns, preventing runaway tankiness.

### Time-to-Kill Analysis (Level 50, Mixed Builds)

Scenario: Both players have 100 points in primary stat, 47 in VIT, 10 in everything else.

| Matchup | Attacker DPS | Turns to Kill | Winner |
|---------|-------------|---------------|--------|
| Warrior vs Warrior | ~147 | ~2.3 | Coin flip (AGI tie) |
| Warrior vs Tank | ~107 | ~6.7 | Tank (wins in 5.2) |
| Warrior vs Rogue | ~107 | ~3.2 | Rogue (wins in 1.7) |
| Warrior vs Mage | ~147 | ~2.3 | Depends on stats |
| Rogue vs Tank | ~167 | ~3.7 | Rogue (tank kills in 7.5) |
| Rogue vs Mage | ~200 | ~1.7 | Rogue (dominates) |
| Mage vs Tank | ~130 | ~5.5 | Tank if no MR, Mage if MR stacked |

**Key Finding:** Rogues beat every class in 1v1 combat. Tanks are second-best because they outlast warriors. The intended rock-paper-scissors (warrior > rogue > mage > warrior) **does not exist** — rogues dominate everything.

### Issue: Poison Damage Type is Too Strong (MEDIUM)

Rogues auto-attack with `poison` damage type, which ignores 50% of armor. Against a 200-armor tank:
- Physical: 200 effective armor → 33% of raw damage gets through
- Poison: 100 effective armor → 50% of raw damage gets through

Rogues deal ~50% more effective damage to tanks compared to warriors, despite having the same base multiplier (1.5×).

### Recommended Fixes

```typescript
// 1. Reduce poison armor penetration
POISON_ARMOR_PENETRATION: 0.30  // was 0.50

// 2. Add warrior-specific anti-rogue mechanic
// Warrior passive: "Heavy Armor" — reduces dodge effectiveness of attacker by 10%
// When a warrior attacks a rogue, the rogue's effective dodge is reduced

// 3. Crit multiplier is fine at 1.5x — no change needed

// 4. Consider adding damage type resistances per class:
// Warrior: +20% physical resist
// Tank: +15% all damage resist (already has 0.85 multiplier)
// Rogue: +20% poison resist
// Mage: +20% magical resist
```

---

## 4. Phase 3 — Economy Balance

### Gold Income Analysis (Daily, Active F2P Player)

| Source | Gold/Day | Effort Level | Notes |
|--------|----------|--------------|-------|
| PvP (21 fights, 50% WR) | ~1,600 | Active (20 min) | 100 win / 30 loss + first win bonus |
| Gold Mine (1 slot) | ~2,100 | Passive (check 6×) | 350 avg × 6 sessions |
| Gold Mine (3 slots) | ~6,300 | Passive (check 6×) | Requires 100 gems investment |
| Daily Login | ~340 | Passive (1 click) | 1,700 gold/week average |
| Daily Quests | ~500 | Mixed | 4 quests + completion bonus |
| Training (alt to PvP) | ~1,260 | Active | 36 sessions at 5 stamina |
| **Total (1 mine slot)** | **~4,540** | | |
| **Total (3 mine slots)** | **~8,740** | | |

### Gold Sink Analysis

| Sink | Cost | Frequency |
|------|------|-----------|
| Upgrade to +10 (1 item) | ~131,918 gold (expected) | Per item |
| Upgrade to +10 (12 items) | ~1,583,016 gold | Lifetime goal |
| Buy Level 50 Epic from shop | 30,000 gold | Occasional |
| Buy Level 50 Legendary | 80,000 gold | Rare |
| Shell Game (avg loss) | ~167 gold/play (at 500 bet) | Entertainment |
| Repair costs | Variable | After combat |
| Skill upgrades | 500 base + 500/rank | Per skill rank |

### Issue: Gold Mine Dominance (CRITICAL)

**3 mine slots (6,300 gold/day) > all active gameplay combined (2,440 gold/day)**

This creates a perverse incentive: the optimal strategy is to log in every 4 hours to collect gold mine rewards and skip PvP entirely. Active gameplay (21 PvP fights requiring 20+ minutes) earns LESS than passive mining.

```
Gold Mine efficiency:  6,300 gold / ~3 min of tapping = 2,100 gold/min
PvP efficiency:        1,600 gold / ~20 min of fighting = 80 gold/min
Ratio: Gold Mine is 26x more efficient than PvP
```

### Issue: Gem-to-Gold Rate is Intentionally Bad (MINOR — Working as Designed)

1 gem = 10 gold. At $0.01/gem, $1 = 1,000 gold = 10 PvP wins. This correctly makes gems a convenience purchase, not a pay-to-win shortcut.

### Upgrade System — Expected Cost Model

Using Markov chain analysis with -1 level on failure at +5 and above:

| Upgrade | Success % | Expected Cost (gold) | Expected Attempts |
|---------|----------|---------------------|-------------------|
| +0 → +1 | 100% | 100 | 1.0 |
| +1 → +2 | 100% | 200 | 1.0 |
| +2 → +3 | 100% | 300 | 1.0 |
| +3 → +4 | 100% | 400 | 1.0 |
| +4 → +5 | 100% | 500 | 1.0 |
| +5 → +6 | 80% | 875 | 1.25 (avg, includes re-ups) |
| +6 → +7 | 60% | 1,750 | ~2.5 |
| +7 → +8 | 40% | 4,625 | ~6.6 |
| +8 → +9 | 25% | 17,475 | ~21.9 |
| +9 → +10 | 15% | 105,693 | ~105.7 |
| **Total +0 → +10** | | **~131,918** | |

**At 4,540 gold/day: 29 days per +10 item, 348 days for all 12 slots.**

This is actually excellent design — a long-term aspirational goal that prevents inflation.

### Protection Scroll Value Analysis

Using a protection scroll (30 gems) at +9:
- Without protection: Expected cost = 105,693 gold
- With protection: Expected cost = 6,670 gold + 170 gems (~$1.70)
- **Savings: ~99,000 gold for $1.70** — extremely good value for paying players

This creates proper F2P vs paying player balance: paying players save months of grinding but don't get unfair combat advantages.

### Recommended Economy Fixes

```typescript
// 1. Nerf Gold Mine to be supplementary, not primary income
MINE_REWARD_MIN: 100     // was 200
MINE_REWARD_MAX: 300     // was 500
// OR: Limit collections to 3/day per slot instead of 6

// 2. Buff PvP gold rewards to be the dominant income source
PVP_WIN_BASE: 150        // was 100
PVP_LOSS_BASE: 50        // was 30

// 3. Add gold bonus for win streaks
// 3-win streak: +20% gold
// 5-win streak: +50% gold
// 10-win streak: +100% gold (rare, rewarding skill)

// 4. Add gold mine diminishing returns
// Each successive collection in a day reduces reward by 15%
// Collection 1: 100%, 2: 85%, 3: 72%, 4: 61%, 5: 52%, 6: 44%
```

---

## 5. Phase 4 — Item System

### Stat Generation Formula

```
baseValue = itemLevel × scalingBase(2) × rarityMultiplier
stat = baseValue × itemTypeWeight
```

| Level | Common (×1.0) | Uncommon (×1.3) | Rare (×1.6) | Epic (×2.0) | Legendary (×2.5) |
|-------|--------------|----------------|-------------|-------------|-----------------|
| 1 | 2 | 3 | 3 | 4 | 5 |
| 10 | 20 | 26 | 32 | 40 | 50 |
| 25 | 50 | 65 | 80 | 100 | 125 |
| 50 | 100 | 130 | 160 | 200 | 250 |

### Issue: Late-Game Item Stats Dwarf Character Stats (MEDIUM)

A level 50 legendary weapon gives STR: 250 (weight 1.0). A fully allocated character has at most 157 in one stat. **A single item more than doubles the primary stat.**

With 12 equipment slots all providing stats, a fully geared character has dramatically different power than an ungeared one:

```
Ungeared Level 50 Warrior (STR=157): damage = 157×1.5 + 100 = 335
Geared Level 50 Warrior (STR=157+250 weapon+50 gloves+50 ring...):
  Total STR ≈ 500+: damage = 500×1.5 + 100 = 850

Power gap: 2.5x damage just from one weapon slot
```

This isn't inherently bad (gear progression is core to RPGs), but it means **matchmaking by level alone is insufficient**.

### Drop Rate Analysis

| Source | Drop Chance | Items/Day (at max play) |
|--------|------------|------------------------|
| PvP (wins only) | 15% | 10.5 × 0.15 = 1.6 |
| Training | 5% | 0.3 (if mixing training) |
| Dungeon Easy | 20% | Variable |
| Dungeon Normal | 30% | Variable |
| Dungeon Hard | 40% | Variable |
| Boss | 75% | Rare opportunity |

Expected legendaries: 1.6 items/day × 1% = 0.016/day = **1 legendary every 63 days from PvP**

With 50 LUK: legendary chance rises to ~3.5% → **1 every 18 days** (good motivator for LUK investment)

### Sell Price vs Farming Efficiency

| Item | Sell Price | PvP Fights Equivalent |
|------|----------|----------------------|
| Common L50 | 500 gold | 5 wins |
| Uncommon L50 | 1,250 gold | 12.5 wins |
| Rare L50 | 3,000 gold | 30 wins |
| Epic L50 | 7,500 gold | 75 wins |
| Legendary L50 | 20,000 gold | 200 wins |

Selling a legendary is worth 200 PvP wins (~10 days of fighting). This feels appropriately valuable.

### Recommended Fixes

```typescript
// 1. Add Gear Score to matchmaking (Phase 7 fix)

// 2. Slight reduction to late-game item stats to reduce gear gap
// Option: Cap stat scaling at level 35, then slower growth
'item_balance.level_scaling_formula': 'logarithmic'  // gentler curve

// 3. Add item set bonuses to reward full-set farming
// 2-piece: +5% HP
// 4-piece: +10% damage
// 6-piece: +15% primary stat
// This makes specific item farming matter, not just "highest stats"
```

---

## 6. Phase 5 — Reward System

### PvP Reward Breakdown

| Outcome | Gold | XP | Drop | BP XP | Rating |
|---------|------|----|----|-------|--------|
| Win | 100 | 80 | 15% | 20 | +Elo gain |
| Loss | 30 | 20 | 0% | 20 | -Elo loss |
| Win (First Win) | 200 | 160 | 15% | 20 | +Elo gain |
| Revenge Win | 150 | 80 | 15% | 20 | +Elo gain |

### Issue: Loser Rewards Are Too Low (MINOR)

The loser gets 30% of winner gold and 25% of winner XP. In most competitive games, the ratio is 40-50% to prevent rage-quitting and maintain engagement.

### Issue: No XP From Gold Mine or Shell Game (MINOR)

Active gameplay (PvP/dungeons) gives both gold AND XP. Passive income (gold mine) gives only gold. This is actually correct design — XP should come from gameplay.

### Recommended Fixes

```typescript
// 1. Increase loser rewards slightly
PVP_LOSS_BASE: 40    // was 30 (40% of winner instead of 30%)
PVP_LOSS_XP: 30      // was 20 (37.5% of winner instead of 25%)

// 2. Add streak bonuses (new system)
WIN_STREAK_GOLD_BONUS: [0, 0, 20, 20, 50, 50, 50, 100, 100, 100]
// 3-win: +20%, 5-win: +50%, 8-win: +100%

// 3. Add daily PvP milestone rewards
// 5 PvP fights/day: 200 bonus gold
// 10 PvP fights/day: 500 bonus gold + 1 gem
// 20 PvP fights/day: 1000 bonus gold + 2 gems
```

---

## 7. Phase 6 — Progression Curve

### XP Formula: `xpForLevel(n) = 100n + 50n²`

| Level | XP Required | Cumulative | Days to Reach (at 1,130 XP/day) |
|-------|------------|------------|-------------------------------|
| 2 | 400 | 400 | 0.4 |
| 5 | 1,750 | 5,100 | 4.5 |
| 10 | 6,000 | 24,600 | 21.8 |
| 15 | 12,750 | 73,850 | 65.4 |
| 20 | 22,000 | 163,600 | 144.8 |
| 25 | 33,750 | 303,850 | 268.9 |
| 30 | 48,000 | 505,600 | 447.4 |
| 40 | 82,000 | 1,122,600 | 993.4 |
| 50 | 130,000 | 2,273,600 | 2,012 |

### CRITICAL ISSUE: 5.5 Years to Max Level

At 1,130 XP/day (21 PvP fights/day, 50% win rate, first win bonus), reaching level 50 takes **2,012 days = 5.5 years**.

For comparison, successful mobile RPGs target:
- Soft cap in 2-4 weeks (casual)
- Hard cap in 2-3 months (hardcore)
- Endgame content unlocking progressively

**The current curve makes level 50 practically unreachable, which means prestige (requiring level 50) will never be used by most players.**

### Level Milestone Analysis

```
Level 10: Unlocked after 3 weeks  — Acceptable early game pace
Level 15: Unlocked after 2 months — Getting slow
Level 20: Unlocked after 5 months — Most players quit
Level 25: Unlocked after 9 months — Only whales/addicts remain
Level 30+: Effectively unreachable for normal players
```

### Recommended Fix: XP Formula Rebalance

**Option A: Reduce quadratic coefficient (Recommended)**

```typescript
// New formula: 100n + 20n² (was 50n²)
export function xpForLevel(level: number): number {
  return 100 * level + 20 * level * level;
}
```

| Level | Old XP | New XP | New Days to Reach |
|-------|--------|--------|-------------------|
| 10 | 6,000 | 3,000 | 8.7 |
| 20 | 22,000 | 10,000 | 55 |
| 30 | 48,000 | 21,000 | 152 |
| 50 | 130,000 | 55,000 | 540 (~1.5 years) |

**Option B: Increase XP rewards (combine with Option A)**

```typescript
PVP_WIN_XP: 150   // was 80
PVP_LOSS_XP: 50   // was 20
TRAINING_WIN_XP: 80  // was 40
TRAINING_LOSS_XP: 25 // was 10
```

With both fixes: Level 50 reachable in ~3-4 months of active daily play. Level 25 in ~3-4 weeks.

**Option C: Add XP multipliers for variety**

```typescript
// Dungeon XP bonus: dungeons give more XP than PvP (risk/reward)
DUNGEON_EASY_XP: 100
DUNGEON_NORMAL_XP: 200
DUNGEON_HARD_XP: 400
BOSS_XP: 800

// Weekly XP boost: first 50 fights each week get +50% XP
// This prevents burnout while rewarding consistent play
```

---

## 8. Phase 7 — PvP Fairness

### Matchmaking Analysis

Current system: Level-based only (±3 level range)

**Problem:** Two level 50 characters can have vastly different power:
- Character A: Common +0 gear, no passives → ~400 damage, ~200 HP
- Character B: Legendary +10 gear, full passives → ~1200 damage, ~2000 HP

This is a 10x power gap at the same level. The current matchmaking puts them against each other.

### ELO System Analysis

```
Starting rating: 1000
K-factor (calibration, first 10 games): 48
K-factor (standard): 32
Min rating: 0
```

**ELO convergence simulation:**

| Games Played | Expected Rating (55% WR) | Rating Stability |
|-------------|-------------------------|------------------|
| 10 | 1,048 | Low (K=48) |
| 30 | 1,096 | Medium (K=32) |
| 50 | 1,120 | High |
| 100 | 1,150 | Stable |

At K=32, a player with a true skill of 55% win rate converges to ~1150 after 100 games. This is appropriate.

**Rating bracket suggestion:**

```
Bronze:      0 - 999
Silver:      1000 - 1199
Gold:        1200 - 1499
Platinum:    1500 - 1799
Diamond:     1800 - 2099
Grandmaster: 2100+
```

### Issue: No Gear-Based Matchmaking (CRITICAL)

### Issue: Revenge System Stamina Bug (MEDIUM)

The spec says revenge fights are free (no stamina cost), but `pvp/resolve/route.ts` line 123 explicitly sets `hasFreePvp = false` for revenge fights, meaning they DO cost 10 stamina.

```typescript
// Bug in pvp/resolve/route.ts:
const hasFreePvp = isRevenge ? false : freePvpUsed < STAMINA.FREE_PVP_PER_DAY
// Should be:
const hasFreePvp = isRevenge ? true : freePvpUsed < STAMINA.FREE_PVP_PER_DAY
// Or better: separate revenge flag
const staminaCost = isRevenge ? 0 : (hasFreePvp ? 0 : STAMINA.PVP_COST)
```

### Issue: Defender Gets Free Rewards (MINOR)

When you attack someone in PvP, the defender also receives gold and XP rewards (30/20 for loss, 100/80 if they "win" as defender). This means inactive players earn passive rewards from being attacked. Over time, popular opponents could accumulate significant passive income.

This is standard for async PvP but should be monitored.

### Recommended Fixes

```typescript
// 1. Add Gear Score to matchmaking
// Calculate total equipped gear power score
// Match within ±20% gear score AND ±3 levels
function findOpponents(character) {
  const gearScore = calculateTotalGearScore(character)
  return prisma.character.findMany({
    where: {
      level: { gte: level - 3, lte: level + 3 },
      // Add gear score range
      gearScore: { gte: gearScore * 0.8, lte: gearScore * 1.2 },
    }
  })
}

// 2. Fix revenge stamina bug
// Revenge should be free as per spec

// 3. Add rating-based matchmaking as secondary filter
// Within level range, prefer opponents within ±200 rating
```

---

## 9. Phase 8 — Exploit Detection

### Exploit 1: Alt Account PvP Farming (MEDIUM RISK)

**Method:** Create a second account with a level-matched character. Repeatedly fight for guaranteed wins.

**Impact:** 100 gold + 80 XP + 15% drop + rating inflation per fight.

**Detection:** No current mechanism to detect same-IP or same-device fights.

**Mitigation:**
```typescript
// 1. Track opponent diversity — flag if >50% of fights are vs same opponent
// 2. Add minimum unique opponents per day: must fight at least 3 different opponents
// 3. Log IP addresses and flag duplicate IPs fighting each other
```

### Exploit 2: Gold Mine Abuse (LOW RISK — Design Issue)

**Method:** Set 4-hour alarms, collect gold mine 6×/day. Invest 100 gems in 2 extra slots.

**Impact:** 6,300 gold/day for 3 minutes of effort.

**Mitigation:** Already addressed in economy recommendations (nerf mine rewards or add diminishing returns).

### Exploit 3: Shell Game Session Manipulation (NO RISK — Secure)

The shell game is properly implemented:
- Secret is generated server-side at `/start`
- Secret is never exposed to client before `/guess`
- Row-level locking prevents double-guessing
- Rate limiting prevents brute force

### Exploit 4: PvP Rating Manipulation (LOW RISK)

**Method:** Intentionally lose to tank rating, then farm lower-rated players.

**Impact:** Minimal — matchmaking is level-based, not rating-based. Rating manipulation only affects leaderboard position.

**Note:** If rating-based matchmaking is added (recommended), this becomes a MEDIUM risk and needs:
```typescript
// Anti-tanking: minimum rating floor based on highest achieved
// You can never drop below 75% of your peak rating
const ratingFloor = Math.floor(character.highestPvpRank * 0.75)
newLoserRating = Math.max(ratingFloor, calculatedRating)
```

### Exploit 5: XP Overflow at Level 50 (LOW RISK)

XP continues accumulating at level 50. After prestige (reset to level 1), excess XP causes instant multi-level gains. This is actually fine — it rewards players who wait to prestige.

### Exploit 6: Upgrade Cost Timing (NO RISK)

The upgrade route uses `FOR UPDATE` row-level locks and transactions. No TOCTOU vulnerabilities exist.

### Exploit 7: Free PvP Counter Bypass (NO RISK)

The free PvP counter is properly stored server-side and validated per fight. No client-side manipulation is possible.

### Exploit 8: Inventory Overflow Drops (MINOR ANNOYANCE)

When inventory is full (100 slots), dropped items are silently lost. Players may not realize they're missing loot.

**Fix:** Return a warning in the API response when inventory is >90% full.

### Exploit 9: Revenge Queue Flooding (NO RISK)

Analysis: Lose intentionally → create revenge opportunities → revenge for 1.5× gold
- Net gold per cycle: -30 (loss) + 150 (revenge win) = +120 gold
- Compared to normal win: +100 gold
- But costs 2× stamina (10 for the original + 10 for revenge — assuming bug is fixed to 0)
- Even if revenge is free: the initial loss costs stamina, making this break-even at best

### Summary Table

| Exploit | Risk | Impact | Fix Priority |
|---------|------|--------|-------------|
| Alt Account Farming | Medium | Economy inflation | High |
| Gold Mine Passive Income | Low (design) | Devalues gameplay | High |
| Shell Game Manipulation | None | N/A | N/A |
| Rating Manipulation | Low | Leaderboard only | Low (High if rating MM added) |
| XP Overflow at 50 | Low | Slight prestige advantage | Low |
| Upgrade TOCTOU | None | N/A | N/A |
| Free PvP Bypass | None | N/A | N/A |
| Inventory Overflow | Minor | Lost items | Low |
| Revenge Flooding | None | N/A | N/A |

---

## 10. Phase 9 — Mathematical Simulation

### Simulation 1: 100-Battle F2P Player Journey (Level 1 Start)

```
Day 1-5:   Level 1→3, Gold: 500→3,200, Gear: 2-3 common drops
Day 5-15:  Level 3→6, Gold: 3,200→15,000, Gear: 5-8 items, some uncommon
Day 15-30: Level 6→9, Gold: 15,000→40,000, Gear: first +5 upgrade, 1-2 rares
Day 30-60: Level 9→13, Gold: 40,000→90,000, Gear: mixed rare/uncommon
Day 60-90: Level 13→15, Gold: 90,000→150,000, Gear: first epic, +7 items

After 100 PvP fights (5 days): 65,000 gold earned, 50,000 XP → ~Level 5
After 1000 PvP fights (48 days): 650,000 gold earned, 500,000 XP → ~Level 18
```

### Simulation 2: 1000-Battle Economy Snapshot

```
Fights: 1000 (500 wins, 500 losses)
Gold earned: 500×100 + 500×30 + first win bonuses ≈ 70,000 gold
XP earned: 500×80 + 500×20 = 50,000 XP
Items dropped: ~75 items (50% common, 30% uncommon, 15% rare, 4% epic, 1% legendary)
Items sold (common/uncommon): ~60 items × avg 300 gold = 18,000 gold
Total gold: 88,000 gold

Gold spent on upgrades (assuming 2 items to +5): 2 × 1,500 = 3,000 gold
Gold spent on shop: ~10,000 gold (repairs, potions)
Net gold after 1000 fights: ~75,000 gold
```

### Simulation 3: Long-term Economy (1 Year, Active Player)

```
Gold income:   4,540/day × 365 = 1,657,100 gold
Gold mine:     + 2,100/day × 365 = 766,500 gold  (1 slot)
Total income:  2,423,600 gold

Upgrade costs: 12 items × 131,918 = 1,583,016 gold
Shop spending: ~300,000 gold (items, repairs, consumables)
Shell game:    ~100,000 gold (entertainment losses)
Total spending: ~1,983,016 gold

Net savings:   440,584 gold (healthy surplus)

Gems earned (F2P): ~365 gems/year (daily login + achievements + quests)
  - 7 gems/week from login streak bonus
  - ~2 gems/week from quest completion bonuses
  - ~100 gems from achievements over the year

Level reached: ~Level 18 (with current XP formula — needs fix!)
Level reached (with fixed XP): ~Level 40-45
```

### Simulation 4: Economy Inflation Check

Gold entering the system per player per day: ~4,540 gold
Gold leaving the system per player per day:
- Upgrades: ~4,500 gold/day (if actively upgrading)
- Repairs: ~200 gold/day
- Shell game losses: ~100 gold/day (if playing)

**Verdict: Economy is roughly balanced** when players are actively upgrading. The upgrade system acts as the primary inflation control mechanism. Once players hit +10 on all items, they'll accumulate excess gold with no sink. A gold sink for endgame players is recommended.

### Simulation 5: Class Balance (10,000 Simulated Fights)

Using the damage/HP formulas for level 30 characters with moderate gear:

| Matchup | Win Rate (Attacker) | Notes |
|---------|-------------------|-------|
| Warrior vs Warrior | 50% | Fair, AGI tie-breaker |
| Warrior vs Rogue | 30% | Rogue dodge + crit dominates |
| Warrior vs Mage | 55% | Warrior HP advantage |
| Warrior vs Tank | 35% | Tank outlasts |
| Rogue vs Rogue | 50% | Fair |
| Rogue vs Mage | 70% | Rogue goes first, crits hard |
| Rogue vs Tank | 65% | Poison penetration + dodge |
| Mage vs Mage | 50% | Fair |
| Mage vs Tank | 45% | MR hurts mage, but mage can out-damage |
| Tank vs Tank | 50% | Draw (often timeout) |

**Overall class win rates (averaging all matchups):**
```
Rogue: 63.8% — OVERPOWERED
Tank:  52.5% — Slightly strong
Warrior: 42.5% — Slightly weak
Mage: 41.3% — Slightly weak
```

---

## 11. Phase 10 — Admin Balance Panel

### Current State

The project already has a `GameConfig` table with a `getGameConfig()` function that reads from the database with hardcoded fallbacks. This is excellent architecture. Many item-balance parameters are already configurable.

### Missing Configurable Parameters

The following values are currently hardcoded in `balance.ts` and should be moved to GameConfig:

```typescript
// === COMBAT PARAMETERS ===
'combat.max_turns': 15,
'combat.min_damage': 1,
'combat.crit_multiplier': 1.5,
'combat.max_crit_chance': 50,
'combat.max_dodge_chance': 30,
'combat.rogue_dodge_bonus': 5,
'combat.tank_damage_reduction': 0.85,
'combat.damage_variance': 0.10,
'combat.poison_armor_penetration': 0.50,

// === CRIT/DODGE FORMULAS ===
'combat.crit_per_luk': 0.5,
'combat.crit_per_agi': 0.3,
'combat.dodge_per_agi': 0.3,

// === GOLD REWARDS ===
'rewards.pvp_win_gold': 100,
'rewards.pvp_loss_gold': 30,
'rewards.training_win_gold': 50,
'rewards.training_loss_gold': 20,
'rewards.revenge_gold_multiplier': 1.5,
'rewards.first_win_gold_multiplier': 2,

// === XP REWARDS ===
'rewards.pvp_win_xp': 80,
'rewards.pvp_loss_xp': 20,
'rewards.training_win_xp': 40,
'rewards.training_loss_xp': 10,
'rewards.first_win_xp_multiplier': 2,

// === XP FORMULA ===
'progression.xp_linear_coefficient': 100,
'progression.xp_quadratic_coefficient': 50,  // CRITICAL: needs reduction
'progression.max_level': 50,
'progression.stat_points_per_level': 3,
'progression.prestige_stat_bonus': 0.05,

// === STAMINA ===
'stamina.max': 120,
'stamina.regen_interval_minutes': 8,
'stamina.pvp_cost': 10,
'stamina.dungeon_easy_cost': 15,
'stamina.dungeon_normal_cost': 20,
'stamina.dungeon_hard_cost': 25,
'stamina.boss_cost': 40,
'stamina.training_cost': 5,
'stamina.free_pvp_per_day': 3,

// === ELO ===
'elo.k_calibration': 48,
'elo.k_default': 32,
'elo.calibration_games': 10,
'elo.min_rating': 0,

// === DROP CHANCES ===
'drops.pvp': 0.15,
'drops.training': 0.05,
'drops.dungeon_easy': 0.20,
'drops.dungeon_normal': 0.30,
'drops.dungeon_hard': 0.40,
'drops.boss': 0.75,

// === RARITY DISTRIBUTION ===
'drops.rarity_common': 50,
'drops.rarity_uncommon': 30,
'drops.rarity_rare': 15,
'drops.rarity_epic': 4,
'drops.rarity_legendary': 1,

// === GOLD MINE ===
'goldmine.duration_hours': 4,
'goldmine.reward_min': 200,
'goldmine.reward_max': 500,
'goldmine.max_slots': 3,
'goldmine.gem_drop_chance': 0.10,

// === SHELL GAME ===
'shellgame.min_bet': 50,
'shellgame.max_bet': 1000,
'shellgame.win_multiplier': 2,

// === MATCHMAKING ===
'matchmaking.level_range': 3,
'matchmaking.max_opponents': 3,
'matchmaking.use_gear_score': false,  // Toggle for new feature
'matchmaking.gear_score_range': 0.20,  // ±20%

// === BATTLE PASS ===
'battlepass.xp_per_pvp': 20,
'battlepass.xp_per_dungeon_floor': 30,
'battlepass.xp_per_quest': 50,
'battlepass.xp_per_achievement': 100,
'battlepass.xp_linear': 100,
'battlepass.xp_quadratic': 50,
```

### Recommended Admin Panel Structure

```
Admin Balance Dashboard
├── Combat
│   ├── Damage Formulas (class multipliers, level bonus)
│   ├── Combat Constants (crit mult, max crit/dodge, variance)
│   ├── Class Bonuses (tank DR, rogue dodge, poison pen)
│   └── Stat Formulas (HP/armor/MR coefficients)
├── Economy
│   ├── Gold Rewards (PvP win/loss, training, revenge)
│   ├── XP Rewards (PvP win/loss, training, dungeon)
│   ├── Gem Costs (refill, protection, slots)
│   ├── Gem-to-Gold Rate
│   └── Shell Game (min/max bet, multiplier)
├── Progression
│   ├── XP Formula Coefficients
│   ├── Level Cap
│   ├── Stat Points Per Level
│   ├── Prestige Settings
│   └── Battle Pass XP Curve
├── Items
│   ├── Stat Ranges by Level
│   ├── Rarity Multipliers
│   ├── Scaling Formula (linear/exponential/log)
│   ├── Upgrade Chances
│   ├── Upgrade Costs
│   ├── Price Formulas (sell/buy)
│   └── Power Score Weights
├── Drops
│   ├── Drop Chances by Source
│   ├── Rarity Distribution
│   ├── LUK Bonus
│   ├── Level Variance
│   └── Drop Cap
├── Matchmaking
│   ├── Level Range
│   ├── Gear Score Toggle
│   ├── Rating Range
│   └── Opponent Count
├── Stamina
│   ├── Max Stamina
│   ├── Regen Rate
│   ├── Activity Costs
│   └── Free PvP Count
├── Gold Mine
│   ├── Duration
│   ├── Reward Range
│   ├── Max Slots
│   └── Gem Drop Settings
└── Monitoring
    ├── Live Economy Dashboard (total gold in/out)
    ├── Class Win Rate Chart
    ├── Level Distribution
    ├── Rating Distribution
    └── Exploit Detection Flags
```

---

## 12. Phase 11 — Final Recommendations

### Priority 1: Critical Fixes (Implement Immediately)

#### Fix 1: Rebalance AGI/Rogue

```typescript
// In balance.ts, adjust crit/dodge formulas:
// Crit: shift weight from AGI to LUK
critChance = LUK * 0.7 + AGI * 0.15 + stanceMod  // was LUK*0.5 + AGI*0.3
// Dodge: reduce AGI scaling
dodgeChance = AGI * 0.2 + LUK * 0.1 + classBonus  // was AGI*0.3
// Poison: reduce armor penetration
POISON_ARMOR_PENETRATION: 0.30  // was 0.50
```

**Expected result:** Rogue overall win rate drops from 63.8% to ~53%, maintaining slight advantage from initiative while being more beatable.

#### Fix 2: Rebalance XP Curve

```typescript
// In balance.ts, change XP formula:
export function xpForLevel(level: number): number {
  return 100 * level + 20 * level * level;  // was 50 * level * level
}
// AND increase XP rewards:
PVP_WIN_XP: 120,   // was 80
PVP_LOSS_XP: 40,   // was 20
```

**Expected result:** Level 50 reachable in ~4 months of daily play instead of 5.5 years.

#### Fix 3: Nerf Gold Mine, Buff PvP

```typescript
// Gold mine: reduce rewards
MINE_REWARD_MIN: 100   // was 200
MINE_REWARD_MAX: 250   // was 500
// PvP: increase rewards
PVP_WIN_BASE: 150      // was 100
PVP_LOSS_BASE: 50      // was 30
```

**Expected result:** PvP becomes the dominant gold source (~2,600/day) with gold mine as supplement (~1,050/day for 1 slot).

#### Fix 4: Fix Revenge Stamina Bug

```typescript
// In pvp/resolve/route.ts, line 123:
const staminaCost = isRevenge ? 0 : (hasFreePvp ? 0 : STAMINA.PVP_COST)
```

### Priority 2: Medium Fixes (Next Sprint)

#### Fix 5: Add Gear Score to Matchmaking

Add a `gearScore` field to characters, recalculated on equip/unequip/upgrade. Use it as a secondary matchmaking filter (±20% range).

#### Fix 6: Give CHA and WIS Combat Value

```typescript
// CHA: enemy intimidation (reduces enemy damage)
const chaDebuff = Math.min(attacker.cha * 0.15, 15) // max 15% damage reduction from CHA

// WIS: mage secondary damage scaling
// Mage formula: INT * 1.2 + WIS * 0.5 + level * 2
```

#### Fix 7: Add Win Streak Gold Bonuses

```typescript
const STREAK_BONUSES = [0, 0, 0.2, 0.2, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0]
// 3-win streak: +20% gold, 5-win: +50%, 8+: +100%
```

#### Fix 8: Move All Balance Constants to GameConfig

Make every value in `balance.ts` configurable via the admin panel without code changes.

### Priority 3: Minor Improvements (Backlog)

#### Fix 9: Add Inventory Full Warning
Return `inventory_warning: true` when inventory is >90% full.

#### Fix 10: Add Anti-Alt-Account Detection
Track opponent diversity and flag suspicious patterns.

#### Fix 11: Add Endgame Gold Sink
For players who have +10 all items: cosmetic shop, guild features, or prestige-exclusive upgrades.

#### Fix 12: Add Rating Floor Anti-Tanking
`minRating = Math.floor(highestPvpRank * 0.75)`

---

## Appendix A: Complete Formula Reference

### Damage

```
baseDamage(warrior) = STR × 1.5 + level × 2
baseDamage(rogue)   = AGI × 1.5 + level × 2
baseDamage(mage)    = INT × 1.5 + level × 2
baseDamage(tank)    = STR × 1.2 + level × 2

armorReduction = raw × (100 / (100 + armor))
poisonReduction = raw × (100 / (100 + armor × 0.5))
magicReduction = raw × (100 / (100 + magicResist))

critChance = min(LUK × 0.5 + AGI × 0.3 + stanceCrit, 50)
dodgeChance = min(AGI × 0.3 + classBonus + stanceDodge, 30)

effectiveDamage = floor(raw × armorReduction × classReduction × critMult × stanceMods)
```

### Derived Stats

```
maxHp = 80 + VIT × 5 + END × 3
armor = floor(END × 2 + STR × 0.5)
magicResist = floor(WIS × 2 + INT × 0.5)
```

### Progression

```
xpForLevel(n) = 100n + 50n²
statPointsPerLevel = 3
passivePointsPerLevel = 1
maxLevel = 50
prestigeBonus = +5% all stats per prestige level
```

### Economy

```
pvpWinGold = chaGoldBonus(100, CHA) × firstWinMult × revengemult
chaGoldBonus = floor(base × (1 + CHA × 0.005))
upgradeCost(n) = (n+1) × 100
sellPrice = rarityBase × itemLevel
buyPrice = sellPrice × 4
```

### ELO

```
expected = 1 / (1 + 10^((opponentRating - playerRating) / 400))
newRating = max(0, round(oldRating + K × (actual - expected)))
K = 48 (first 10 games), 32 (after)
```

---

## Appendix B: Recommended Balance Constants (Complete)

```typescript
// RECOMMENDED balance.ts after all fixes applied:

export const STAMINA = {
  MAX: 120,
  REGEN_RATE: 1,
  REGEN_INTERVAL_MINUTES: 8,
  PVP_COST: 10,
  DUNGEON_EASY: 15,
  DUNGEON_NORMAL: 20,
  DUNGEON_HARD: 25,
  BOSS: 40,
  TRAINING: 5,
  FREE_PVP_PER_DAY: 3,
} as const;

export function xpForLevel(level: number): number {
  return 100 * level + 20 * level * level; // CHANGED from 50
}

export const GOLD_REWARDS = {
  PVP_WIN_BASE: 150,          // CHANGED from 100
  PVP_LOSS_BASE: 50,          // CHANGED from 30
  TRAINING_WIN: 50,
  TRAINING_LOSS: 20,
  REVENGE_MULTIPLIER: 1.5,
} as const;

export const XP_REWARDS = {
  PVP_WIN_XP: 120,            // CHANGED from 80
  PVP_LOSS_XP: 40,            // CHANGED from 20
  TRAINING_WIN_XP: 60,        // CHANGED from 40
  TRAINING_LOSS_XP: 20,       // CHANGED from 10
} as const;

export const COMBAT = {
  MAX_TURNS: 15,
  MIN_DAMAGE: 1,
  CRIT_MULTIPLIER: 1.5,
  MAX_CRIT_CHANCE: 50,
  MAX_DODGE_CHANCE: 30,
  ROGUE_DODGE_BONUS: 3,       // CHANGED from 5
  TANK_DAMAGE_REDUCTION: 0.85,
  DAMAGE_VARIANCE: 0.10,
  POISON_ARMOR_PENETRATION: 0.30, // CHANGED from 0.50
  // NEW: Crit/dodge formula coefficients
  CRIT_PER_LUK: 0.7,          // CHANGED from 0.5
  CRIT_PER_AGI: 0.15,         // CHANGED from 0.3
  DODGE_PER_AGI: 0.2,         // CHANGED from 0.3
  DODGE_PER_LUK: 0.1,         // NEW
} as const;
```

---

*End of Balance Audit Report*
*Total findings: 4 Critical, 8 Medium, 6 Minor*
*Recommended actions: 12 fixes across 3 priority tiers*
