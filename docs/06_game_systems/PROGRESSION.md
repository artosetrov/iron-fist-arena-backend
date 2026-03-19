# Progression System (Source of Truth)

*Derived from backend: `src/lib/game/progression.ts`, `balance.ts`, `daily-login.ts`, `daily-quests.ts`, `achievement-catalog.ts`, `battle-pass.ts`, `passives.ts`, `skills.ts`*

---

## Leveling System

### XP Formula

Experience required to reach each level (cumulative threshold):

```
XP for Level N = 100 × N + 20 × N²
```

### XP Curve Examples

| Level | Total XP Required | XP from Previous Level |
|-------|------------------|----------------------|
| 1 | 0 | — |
| 2 | 280 | 280 |
| 5 | 1200 | 420 |
| 10 | 3000 | 800 |
| 20 | 9200 | 2000 |
| 30 | 19800 | 3800 |
| 40 | 35200 | 6000 |
| 50 | 55000 | 8800 |

**Note:** Progression is quadratic; later levels take exponentially more XP.

### Level Cap

- **Maximum Level:** 50
- **After Reaching Level 50:** Can prestige to reset to level 1 and gain prestige bonuses
- **At Max Level:** XP no longer increases level but is retained for prestige

### Stat Points

- **Per Level:** 3 stat points
- **Total to Level 50:** 147 stat points (levels 1–50 each grant 3)
- **Allocatable to:** STR, AGI, VIT, END, INT, WIS, LUK, CHA

### Passive Points

- **Per Level:** 1 point
- **Total to Level 50:** 49 points
- **Max Passive Points:** 50 (can earn 1 extra from prestige resets)
- **Cost to Respec:** 50 gems

---

## Prestige System

### Requirements & Mechanics

| Property | Value | Details |
|----------|-------|---------|
| Prestige Requirement | Level 50 | Must reach max level first |
| Level Reset | Yes | Back to level 1 |
| Equipment Retained | Yes | All items stay in inventory |
| Gold Retained | Yes | Currency stays |
| Passive Points Retained | Yes | All unlocked passives remain |
| Stat Points Retained | No | Stat allocations reset with level |

### Prestige Bonuses

Each prestige level grants a multiplicative bonus to all stats:

```
Stat Multiplier = 1 + (Prestige Level × 0.05)
```

### Prestige Scaling Examples

| Prestige Level | Stat Multiplier | Example (Base STR: 50) |
|----------------|-----------------|----------------------|
| 0 | 1.00× | 50 STR |
| 1 | 1.05× | 52.5 STR |
| 5 | 1.25× | 62.5 STR |
| 10 | 1.50× | 75 STR |
| 20 | 2.00× | 100 STR |
| 50 | 3.50× | 175 STR |

**Impact:** Prestige 50 is equivalent to 3.5× base power, heavily incentivizing multiple prestiges.

---

## Skill System

### Active Skills

Skills are learned by class and can be equipped for combat use.

#### Equipped Slots

| Property | Value |
|----------|-------|
| Max Equipped Slots | 4 (0–3 = slots 1–4) |
| Selection Priority | First ready skill in slot order |
| Fallback | Auto-attack if all on cooldown |

#### Skill Learning

| Action | Cost |
|--------|------|
| Learn Skill | 200 gold |
| Rank 1 → 2 | 500 + (500 × 1) = 1000 gold |
| Rank 2 → 3 | 500 + (500 × 2) = 1500 gold |
| Rank N → N+1 | 500 + (500 × N) gold |

#### Skill Damage Formula

```
Raw Damage = Base Damage + sum(character_stat × scaling_coefficient)
Multiplied by: 1 + (rank - 1) × rank_scaling

Example:
Skill: "Fireball"
- Base Damage: 30
- Scaling: { int: 1.5, wis: 0.5 }
- Rank Scaling: 0.1 per rank
- Character: INT 100, WIS 50
- At Rank 1: (30 + 100×1.5 + 50×0.5) × 1.0 = 195 damage
- At Rank 3: (30 + 150 + 25) × (1 + 2×0.1) = 205 × 1.2 = 246 damage
```

#### Cooldown Management

Cooldowns are tracked per skill:

```
Initial Cooldown = skill.cooldown (turns)
After Use: max(1, ceil(cooldown × (1 - cooldown_reduction / 100)))
Minimum: 1 turn (even with 100% CDR)
```

**Example:** Skill with 4-turn cooldown, 20% CDR:
- Effective cooldown = ceil(4 × 0.8) = 4 turns (CDR not enough to reduce below ceil)

### Skill Damage Types

| Type | Mitigation | Auto-Attack by Class |
|------|-----------|----------------------|
| Physical | Reduced by Armor | Warrior, Tank |
| Magical | Reduced by Magic Resist | Mage |
| Poison | Penetrates 30% armor | Rogue |
| True Damage | No mitigation | (Rare) |

### Self-Buff Skills

Special skills that target `'self_buff'`:
- Deal 0 damage
- Apply effects to caster (heal, buff, etc.)
- Consume a turn but don't attack

---

## Passive Tree System

### Tree Structure

- **Start Nodes:** Can always unlock (no prerequisites)
- **Connected Nodes:** Must be adjacent to an unlocked node (undirected graph)
- **Unlocking:** Spend 1 passive point per node
- **Max Points:** 50 passive points total

### Passive Bonus Types

| Type | Behavior | Examples |
|------|----------|----------|
| **flat_stat** | Add fixed points to a stat | +5 STR, +3 INT |
| **percent_stat** | Add percentage bonus to stat | +10% AGI |
| **flat_damage** | Add fixed damage | +15 damage |
| **percent_damage** | Add damage multiplier | +20% damage |
| **flat_crit_chance** | Add % crit | +5% crit |
| **flat_dodge_chance** | Add % dodge | +3% dodge |
| **flat_hp** | Add fixed HP | +100 HP |
| **percent_hp** | Add HP multiplier | +10% HP |
| **flat_armor** | Add armor value | +25 armor |
| **flat_magic_resist** | Add magic resist | +20 resist |
| **percent_armor** | Armor multiplier | +5% armor |
| **percent_magic_resist** | Magic resist multiplier | +5% resist |
| **lifesteal** | Percent heal on damage | +5% lifesteal |
| **cooldown_reduction** | CDR percentage | +10% CDR |
| **damage_reduction** | Damage mitigation (capped 50%) | +5% DR |

### Passive Point Allocation

Passive points accumulate at 1 per level:

| Level | Passive Points Available | Notes |
|-------|--------------------------|-------|
| 1 | 0 | Unlocked at level 2 |
| 2 | 1 | |
| 10 | 9 | |
| 25 | 24 | Mid-game |
| 50 | 49 | Near cap |

After prestige:
- Passive points reset to 0
- Player can re-allocate 1 point per new level gained
- Same 50-point cap applies

### Passive Bonus Aggregation

Multiple bonuses stack:

```
Final STR = Base STR
  + flat_stat bonuses
  × (1 + sum(percent_stat bonuses))
```

**Example:**
- Base STR: 50
- Flat bonuses: +5 (from 2 nodes × 2.5 each)
- Percent bonuses: +20% (from 2 nodes × 10% each)
- Final STR = (50 + 5) × 1.20 = 66 STR

---

## Battle Pass System

### XP Sources

| Activity | BP XP | Notes |
|----------|-------|-------|
| PvP Combat (Win or Loss) | 20 XP | Per match |
| Dungeon Floor Clear | 30 XP | Per floor completed |
| Story/Daily Quest | 50 XP | Per quest |
| Achievement Unlock | 100 XP | One-time bonus |

**Fastest progression:** Achievements (100 XP) → Quests (50 XP) → Dungeons (30 XP) → PvP (20 XP)

### Level Formula

```
BP XP Required for Level N = 100 + N × 50

Examples:
- Level 1: 100 XP
- Level 10: 100 + 10×50 = 600 XP cumulative
- Level 100: 100 + 100×50 = 5100 XP cumulative
```

### Battle Pass Tracks

| Track | Details |
|-------|---------|
| **Free** | 50 levels included with game |
| **Premium** | +100 additional levels (500 gems) |
| **Total** | 150 levels per season |

**Free Track Rewards:**
- Experience fragments, common items, cosmetics, 5 gems

**Premium Track Rewards:**
- All free rewards +
- Rare/epic items, 100+ gems, exclusive cosmetics

---

## Daily Quests

### Quest Generation

- **3 quests per day** generated automatically
- **Reset time:** UTC midnight
- **Quest types:** PvP, Dungeon, Training, Minigames, Collectibles, etc.

### Quest Structure

| Property | Value | Notes |
|----------|-------|-------|
| Quests per Day | 3 | Random selection |
| Reset Time | UTC midnight | Consistent for all players |
| Target Scaling | By character level | Higher level = harder targets |
| Completion Reward | (TBD by quest) | Typically gold/XP |

### Quest Progression Tracking

Daily quest progress is tracked via `updateDailyQuestProgress()`:
- Progress increments by 1 (or custom amount) per relevant action
- Auto-completes when progress ≥ target
- Cannot exceed target value
- Persisted to database on each update

### Quest Types (Examples)

| Type | Example Target | Reward |
|------|----------------|--------|
| **PvP** | Win 2 PvP matches | 100 gold + 25 XP |
| **Dungeon** | Complete Dungeon Normal | 150 gold + 40 XP |
| **Training** | Win 3 training matches | 50 gold + 20 XP |
| **Damage** | Deal 5000 damage | 75 gold + 30 XP |
| **Collection** | Upgrade 1 item | 50 gold + 15 XP |

---

## Daily Login Rewards

### 7-Day Cycle

Repeats weekly; streak resets on 2-day gap:

| Day | Reward | Amount | Equivalent Value |
|-----|--------|--------|------------------|
| 1 | Gold | 200 | |
| 2 | Stamina Potion (Small) | 1 | +50 stamina |
| 3 | Gold | 500 | |
| 4 | Stamina Potions (Small) | 2 | +100 stamina |
| 5 | Gold | 1000 | |
| 6 | Stamina Potion (Large) | 1 | +100 stamina |
| 7 | Gems | 5 | Premium currency |

**Total per week:** 1700 gold + 250 stamina + 5 gems

### Streak Mechanics

```
Claimable: 24+ hours since last claim (same UTC calendar day)
Streak Reset: 2+ days (48 hours) since last claim
```

**Timeline Example:**
- Day 1: Claim reward → Day 1 claimed
- Day 2 (18 hrs later): Can claim → Day 2 progress
- Day 3 (missing): —
- Day 4 (48+ hrs later): Can claim, but streak resets → Day 1 progress restarts

### Repeat Cycle

After Day 7 completion:
- Automatically cycles back to Day 1
- Streak counter continues if daily login maintained
- No XP/level caps on login rewards

---

## Achievements

### Achievement System

Achievements track permanent milestones:

| Category | Examples |
|----------|----------|
| Combat | 100 PvP wins, 500 total damage dealt |
| Progression | Reach level 25, Prestige 5 times |
| Skill | Equip 4 skills, Land 50 critical hits |
| Collection | Own 20 legendary items, Forge 100 items |
| Exploration | Clear all dungeons, Defeat all bosses |

### Reward Types

| Reward Type | Value |
|------------|-------|
| Gold | 100–1000 gold per achievement |
| Gems | 5–50 gems (rare) |
| XP | 200–500 XP boost |
| Cosmetics | Skins, titles, emotes |
| Battle Pass XP | +100 BP XP |

### Achievement Discovery

- Tracked in real-time as players perform actions
- Unlock notifications sent on completion
- Rewards claimed automatically or via menu
- Progress visible in Achievement catalog

---

## Progression Tracking Endpoints

### Level-Up Flow

1. Character gains XP (from PvP, training, quests, etc.)
2. System calls `checkLevelUp(character)`
3. Returns: `{ leveledUp, newLevel, remainingXp, statPointsAwarded, passivePointsAwarded }`
4. If level-up occurred:
   - Level increases by 1
   - Stat points added (3 per level)
   - Passive points added (1 per level)
   - Excess XP carries to next level
   - Triggers achievement check if applicable

### Multiple Level-Ups in One Pass

The `checkLevelUp()` function handles bulk XP gains:

```typescript
// If character gains 10000 XP at once:
// Level 10 (needs 3000 total) → Level 12 (needs 4600 total)
// Returns: leveledUp=true, newLevel=12, statPointsAwarded=6, etc.
```

### Prestige Flow

1. Character reaches level 50
2. System calls `checkPrestige(currentLevel, currentPrestige)`
3. Returns: `{ canPrestige, newPrestigeLevel, statBonusPercent }`
4. If prestige available:
   - Prestige level increments by 1
   - Level resets to 1
   - XP resets to 0
   - Equipment, gold, passive tree preserved
   - Stat bonuses re-calculated with new prestige multiplier
   - Player receives notification

### Passive Bonus Application

1. Player unlocks passive node (costs 1 point)
2. Node bonus added to aggregated passive bonuses
3. Called via `aggregatePassiveBonuses(unlockedNodes)`
4. Bonuses apply immediately in next combat
5. Combat calculates final damage/defense with bonuses

---

## Progression Milestones

### Early Game (Levels 1–15)

- Learn core mechanics
- Equip first 1–2 skills
- Unlock first passive nodes
- Reach Silver rank (1200 ELO)

**Expected Time:** 2–4 hours

**Goals:**
- Complete first 3 daily login cycles
- Earn 5–10 equipment drops
- Understand stamina/gold economy

### Mid Game (Levels 16–35)

- Unlock all 4 skill slots
- Build out passive tree (15–20 points)
- Farm better equipment
- Reach Gold/Platinum rank (1500–1800 ELO)

**Expected Time:** 10–20 hours

**Goals:**
- Upgrade equipment to +4 or +5
- Complete first battle pass
- Start first prestige prep

### Late Game (Levels 36–50)

- Optimize equipment loadout (+6 to +8 upgrades)
- Specialize passive tree (30–49 points)
- High ELO competition (Diamond+)
- Prepare for first prestige

**Expected Time:** 30–50 hours

**Goals:**
- Equipment to +8 or higher
- Max out battle pass (150 levels)
- Prestige to level 1 with multiplier

### Post-Max (Prestige 1+)

- Prestige multiple times for 2–3.5× stat scaling
- Push ELO ladder with exponentially stronger builds
- Collection and cosmetic grind
- Seasonal battle pass completion

**Scaling:** Each prestige adds another 50–100 hours of playtime

---

## Progression Speeds by Mode

### Fastest XP (PvP)

```
Win rate 60% (typical skilled player):
- 6 wins (120 XP each) = 720 XP per hour
- 4 losses (40 XP each) = 160 XP per hour
- Avg ~880 XP/hour
- Level 50: 55,000 XP ÷ 880 = 62.5 hours
```

### Moderate (Training)

```
Win rate 70%:
- 7 wins (60 XP each) = 420 XP per hour
- 3 losses (20 XP each) = 60 XP per hour
- Avg ~480 XP/hour
- Level 50: 55,000 XP ÷ 480 = 114 hours
```

### Battle Pass Speed (Mixed)

```
PvP (20 BP XP) → 200 BP XP per 10 matches
Quests (50 BP XP) → 150 BP XP per 3 quests
Mix: ~50 BP XP per 30 min active play
150 levels: ~90 hours to complete (free) + time for premium
```

---

## Economy Loop

### Gold Flow

| Source | Gold/hr | Notes |
|--------|---------|-------|
| PvP Wins | 150–300 | Level and CHA scaling |
| Training Wins | 50–100 | Lower tier, guaranteed income |
| Gold Mine | 50 | Passive, per 4-hour slot |
| Daily Login | 243 | ~35 gold/day (1700/7) |

### Gem Sustainability

**Free gems per week:** 5 (daily login) = ~20/month

**Typical monthly spenders (optional):**
- Premium pass: 500 gems (one-time per month)
- Stamina refills: 30 gems (optional, 1–2×/week)
- Total: 560–620 gems optional spending

**F2P sustenance:**
- 20 gems/month (login only)
- Enough for ~1 Stamina refill every 1.5 months
- Must earn gold for equipment upgrades

---

## Summary: Progression Arc

```
Level 1
  ↓ (3 XP per level, 3 stat points, 1 passive point)
Level 50 (55,000 total XP)
  ↓ (can prestige, resets to level 1)
Prestige 1 (+5% all stats)
  ↓ (reach level 50 again)
Prestige 2 (+10% all stats)
  ↓ ... (infinite scaling)
Prestige ∞ (builds become extremely powerful)
```

This creates a "soft loop" where players can repeatedly cycle through the level 1–50 progression, gaining permanent power increases via prestige.

---

## Retention Features

### Daily Engagement Loop

1. **Daily Login** (1 min) → claim reward
2. **Daily Quests** (30 min) → 3 random quests
3. **Stamina Usage** (30–60 min) → PvP, training, dungeons
4. **Gold Mine Collection** (as it completes) → passive income
5. **Battle Pass XP** → progress toward rewards

### Weekly Goals

1. Complete 7-day login cycle (1700 gold + 5 gems)
2. Finish all battle pass levels for season
3. Reach next ELO milestone
4. Upgrade equipment to next tier (+1 to +2)
5. Unlock 5–7 passive tree nodes

### Long-Term Goals

1. Reach level 50
2. First prestige (reset to level 1)
3. Multi-prestige scaling (5×, 10×, 20× power)
4. Legendary item collection (rarest drops)
5. Grandmaster rank (2400+ ELO)

</content>
</invoke>