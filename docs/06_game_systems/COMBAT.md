# Combat System (Source of Truth)

*Derived from backend: `src/lib/game/combat.ts`, `elo.ts`, `balance.ts`*

---

## Turn-Based Combat Engine

### Core Rules

| Property | Value | Details |
|----------|-------|---------|
| Combat Type | Turn-based | Alternating attacks |
| Max Turns | 15 | Each character attacks (30 total actions) |
| Turn Order | By AGI | Higher AGI attacks first |
| PRNG | Seeded Mulberry32 | Deterministic if seed provided |
| Draw Condition | Higher HP% wins | At 15-turn timeout |

### Combat Initialization

1. Load class damage formulas from config
2. Create seeded RNG (if seed provided, else random)
3. Determine turn order by AGI stat
4. Initialize skill cooldown states
5. Start turn 1

### Turn Flow

**Each round consists of 2 attacks:**

1. First character attacks second
2. (If second character alive) Second character attacks first
3. Tick cooldowns
4. Check for win/loss
5. Repeat until someone dies or 15 rounds expire

---

## Damage Formula

### Class-Based Scaling

Each class has unique base damage scaling:

| Class | Formula | Notes |
|-------|---------|-------|
| Warrior | STR × 1.5 + Level × 2 | Primary damage dealer |
| Tank | STR × 1.3 + VIT × 0.3 + Level × 2 | Balanced offense/defense |
| Rogue | AGI × 1.5 + Level × 2 | Speed-focused damage |
| Mage | INT × 1.4 + WIS × 0.25 + Level × 2 | Spell scaling (WIS nerfed from 0.5) |

**Example (Level 20 Warrior with STR 50):**
- Base Damage = 50 × 1.5 + 20 × 2 = 75 + 40 = 115

**Variance Applied:** ±10% random multiplier (0.9–1.1×)

### Damage Type Mitigation

After skill/auto-attack damage is calculated, apply resistances:

| Type | Mitigation Formula | Armor/Resist Applies | Special |
|------|-------------------|----------------------|---------|
| **Physical** | `dmg × 100/(100+armor)` | Full armor | Affected by tank 15% reduction |
| **Magical** | `dmg × 100/(100+magicResist)` | Full resist | Affected by tank 15% reduction |
| **Poison** | Armor penetration 30% | Effective armor reduced 30% | Affected by tank 15% reduction |
| **True Damage** | No mitigation | N/A | Bypasses all resistances |

**Example (100 damage physical vs. 50 armor):**
- Effective damage = 100 × 100 / (100 + 50) = 100 × 100 / 150 = 66.67 → 66 damage (after floor)

### Class-Specific Reductions

**Tank Passive:** Takes 15% less damage (0.85 multiplier)

```
Warrior vs Tank (100 physical damage):
- Without tank reduction: 100 × 100/(100+50) = 66 damage
- With tank reduction: 66 × 0.85 = 56 damage (15% less)
```

---

## Crit Strike System

### Crit Chance Calculation

```
Crit Chance = min(
  LUK × 0.6 + AGI × 0.2 + stance_crit_bonus,
  50% max
)
```

| Stat | Contribution | Notes |
|------|--------------|-------|
| LUK | 0.6× per point | Primary crit source (W3.D2 — was 0.7) |
| AGI | 0.2× per point | Secondary (W3.D2 — partial restore from 0.15) |
| Stance Bonus | 0–5% | Attack zone modifiers |

**Example (LUK 50, AGI 40, no stance bonus):**
- Crit = min(50 × 0.6 + 40 × 0.2 + 0, 50) = min(30 + 8, 50) = 38%

**W3.D2 rebalance rationale:** AGI/Rogue was over-nerfed in the prior pass. Partial restore (LUK 0.7→0.6, AGI 0.15→0.2) keeps LUK as primary crit stat while giving Rogue builds back some sting, paired with the Execute finisher below.

### Crit Damage Multiplier

Critical hits deal **1.5× damage** (before passive bonuses applied):

```
Crit Damage = Base Damage × 1.5
```

---

## Dodge System

### Dodge Chance Calculation

```
Dodge Chance = min(
  AGI × 0.2 + LUK × 0.1 + class_bonus + stance_dodge_bonus,
  30% max
)
```

| Factor | Contribution | Notes |
|--------|--------------|-------|
| AGI | 0.2× per point | Primary dodge stat (nerfed from 0.3) |
| LUK | 0.1× per point | New secondary dodge contributor |
| Rogue Class Bonus | +4% flat | Rogues naturally evasive (W3.D2 — was 3%) |
| Stance Bonus | 0–8% | Defense zone modifiers |

**Example (AGI 50, LUK 20, Rogue class, legs stance):**
- Dodge = min(50 × 0.2 + 20 × 0.1 + 4 + 3, 30) = min(10 + 2 + 4 + 3, 30) = 19%

### Rogue Class Passive

All rogues gain +4% dodge as innate bonus (W3.D2 partial restore — original 5%, was 3%).

### Rogue Execute (W3.D2)

Thematic finisher — Rogues deal **+15% final damage** when attacking a defender whose current HP is at or below **35% of max HP**.

```
if attacker.class == 'rogue' && defender.currentHp / defender.maxHp <= 0.35:
    final_damage *= 1.15
```

| Constant | Value | Purpose |
|---|---|---|
| `ROGUE_EXECUTE_HP_THRESHOLD` | 0.35 | Defender HP ratio that arms the bonus |
| `ROGUE_EXECUTE_DAMAGE_BONUS` | 0.15 | Multiplicative bonus to final damage |

Applied **after all mitigation** (resists, class reduction, crits, stance, passive DR) so the bonus scales with actual floor damage. Note: CHA now gates the hit itself via the pre-hit miss roll (see "CHA Miss Chance" below), not a damage reduction. Industry precedent: Diablo "Execute"-style finishers (PoE, Raid: Shadow Legends, Genshin Impact) — rewards Rogue for closing kills instead of kiting forever.

Unit-tested in `backend/tests/lib/rogue-execute.test.ts`.

---

## Stance System

### Body Zones

Three defensive/offensive zones available:

```
Attack Zone → Defense Zone (what you're protecting)
```

Available zones: **head**, **chest**, **legs**

### Attack Zone Bonuses (W3.D4 — symmetry pass)

| Zone | Offense | Crit | Playstyle |
|------|---------|------|-----------|
| **head** | +10% | +5% | Aggressive, high-risk |
| **chest** | +5% | 0% | Balanced |
| **legs** | +2% | 0% | Safe — small upside, no penalty |

> **W3.D4 change:** legs attack was `(0, -3)` — strictly dominated by chest. Now `(+2, 0)` — no dominated option, and the "safe" stance rewards mixups without a crit punishment.

### Defense Zone Bonuses

| Zone | Defense | Dodge | Playstyle |
|------|---------|-------|-----------|
| **head** | 0% | +8% | Evasive |
| **chest** | +10% | 0% | Tanky |
| **legs** | +5% | +3% | Balanced |

### Zone Matching Bonuses

**Attacker Bonus (Zone Mismatch):** +5% offense when attack zone ≠ defender's defense zone

**Defender Bonus (Zone Match):** +15% defense when correctly predicting attacker's zone

**Example (Head vs Head Prediction):**
- Attacker has no mismatch bonus
- Defender gets +15% damage reduction from correct prediction

**Example (Head vs Chest):**
- Attacker gets +5% mismatch bonus
- Defender gets no match bonus

---

## CHA Miss Chance (W3.D1)

### Pre-hit Whiff Effect

Defender's CHA represents an **intimidating presence** that unnerves the attacker, causing them to miss entirely. This replaces the legacy "CHA intimidation damage reduction" — we never stack two effects on one stat.

```
miss_chance = min(defender.cha × 0.2, 20%)
```

The miss roll happens **before** the dodge roll, so it's a pure pre-hit whiff, distinct from AGI/LUK evasion. Missing an attack deals **zero damage** and logs a `"miss"` action (see `Turn.isMiss` and `CombatLog.isMiss`).

| Constant | Value | Purpose |
|---|---|---|
| `CHA_MISS_PER_POINT` | 0.2 | Miss % per defender CHA point |
| `CHA_MISS_CAP` | 20 | Hard ceiling on CHA-induced miss chance |

| Defender CHA | Miss Chance | Notes |
|--------------|-------------|-------|
| 0 | 0% | No effect |
| 10 | 2% | Early game |
| 50 | 10% | Mid game |
| 100 | 20% | Break-even — cap reached |
| 200 | 20% | Still capped |

**Example:**
- Defender CHA 50 → 10% of attacks whiff completely, 90% proceed to dodge roll
- Defender CHA 100+ → 20% of attacks whiff (hard cap), 80% proceed to dodge roll

### Why a Miss Roll Instead of Damage Reduction

- **One stat → one mechanic.** Stacking damage reduction on top of armor/magic-resist diluted both.
- **Readable feedback.** A "MISS" log entry is distinct from "DODGE" and gives CHA a unique combat voice.
- **Industry precedent.** D&D charm/intimidate saves, MMO "blind" debuffs, and Raid: Shadow Legends' "decrease accuracy" all operate as pre-hit whiff rolls. Players understand the pattern.
- **Independent of AGI/LUK.** Two evasion stats (CHA + AGI) with independent rolls, rather than one stacked cap.

### Roll Order in `resolveAttack`

```
1. CHA miss roll      → if miss, return 0 damage
2. AGI/LUK dodge roll → if dodge, return 0 damage
3. Crit roll
4. Base damage + stance + passives + mitigation
5. Rogue Execute (if applicable)
```

Unit-tested in `backend/tests/lib/cha-miss.test.ts` via the pure `chaMissChance` helper exported from `backend/src/lib/game/combat.ts`.

---

## Passive Bonuses in Combat

Combat applies passive bonuses from passive tree:

| Bonus Type | Application |
|-----------|-------------|
| **Flat Damage** | Added to raw damage after base calculation |
| **Percent Damage** | Multiplied: `dmg × (1 + percentDamage / 100)` |
| **Flat Crit** | Added to crit chance calculation |
| **Flat Dodge** | Added to dodge chance calculation |
| **Lifesteal** | Heal: `ceil(dmg × lifesteal / 100)` |
| **Cooldown Reduction** | Applied when skill put on cooldown |
| **Damage Reduction** | Capped 50%, applied to final damage taken |

---

## Armor Formula (Defense)

### Armor Effectiveness

Armor reduces all non-true damage:

```
Effective Damage = Raw Damage × 100 / (100 + Armor)
```

**Armor Scaling:**

| Armor | Damage Reduction |
|-------|-----------------|
| 0 | 0% |
| 50 | 33% |
| 100 | 50% |
| 200 | 67% |
| 500 | 83% |

**Note:** Damage reduction % = Armor / (100 + Armor) × 100

---

## Auto-Attack Fallback

When no skills are available (all on cooldown), character uses auto-attack:

| Class | Damage | Type | Class Scaling |
|-------|--------|------|---------------|
| Warrior | Base damage formula | Physical | STR × 1.5 |
| Tank | Base damage formula | Physical | STR × 1.3 + VIT × 0.3 |
| Rogue | Base damage formula | Poison | AGI × 1.5 |
| Mage | Base damage formula | Magical | INT × 1.4 + WIS × 0.25 |

---

## Battle Fatigue (Anti-Stall)

After turn 10, both fighters deal escalating bonus damage to prevent stalemates:

```
Fatigue Start: Turn 11
Bonus Per Turn: +10% damage
Turn 11: +10%, Turn 12: +20%, Turn 13: +30%, Turn 14: +40%, Turn 15: +50%
```

Applied as final multiplier in the damage pipeline (after all other modifiers). This ensures tank-vs-tank and high-lifesteal matchups resolve before timeout.

---

## Combat Timeout & Victory

### 15-Turn Limit

If combat reaches turn 15 without a winner:

1. Calculate HP % for both combatants
2. Higher HP % character wins
3. If tied, defender (second character) wins

```
Winner = if (hpA% >= hpB%) then A else B
```

---

## ELO Rating System

### K-Factor Calibration

New players use a higher K-factor during calibration:

| Phase | K-Factor | Games | Notes |
|-------|----------|-------|-------|
| **Calibration** | 48 | 1–10 | Larger ELO swings |
| **Established** | 32 | 11+ | Normal progression |

**Transition:** After 10 wins or losses (whichever comes first), K switches to 32.

### ELO Formula

Standard ELO with K-factor:

```
Expected Score = 1 / (1 + 10^((opponent - player) / 400))
New Rating = Old + K × (actual - expected)
```

Where `actual = 1` for win, `0` for loss.

**Example (Winner 1600, Loser 1400, K=32):**
- Expected Winner = 1 / (1 + 10^((1400-1600)/400)) = 1 / (1 + 0.251) = 0.799
- New Winner = 1600 + 32 × (1 - 0.799) = 1600 + 6.4 = **1606.4 → 1606**
- Expected Loser = 1 / (1 + 10^((1600-1400)/400)) = 1 / (1 + 3.981) = 0.201
- New Loser = 1400 + 32 × (0 - 0.201) = 1400 - 6.4 = **1393.6 → 1394**

### PvP Rank Tiers (W3.D5 — BAL-05 ladder)

8-tier × 3-division ladder, resolved **server-side** in `backend/src/lib/game/tier.ts`
(`tierFromRating(rating, leaderboardRank?)`). iOS `TierBadge` is a pure display —
it never touches `pvpRating` numerically.

| Rank | Rating range | Divisions | Color token | Notes |
|------|--------------|-----------|-------------|-------|
| Bronze | 0 – 749 | III / II / I (width 250) | `rankBronze` | Starter rank, starting rating = 1000 (Silver II) |
| Silver | 750 – 1499 | III / II / I (width 250) | `rankSilver` | |
| Gold | 1500 – 2249 | III / II / I (width 250) | `rankGold` | |
| Platinum | 2250 – 2999 | III / II / I (width 250) | `rankPlatinum` | |
| Diamond | 3000 – 3749 | III / II / I (width 250) | `rankDiamond` | |
| Master | 3750 – 4249 | — | `rankMaster` | No divisions |
| Grandmaster | 4250+ | — | `rankGrandmaster` | No divisions |
| Challenger | 4250+ **and** leaderboard rank ≤ 100 | — | `rankChallenger` | Rank-based cutoff, rating-leaderboard only |

**Challenger semantics:** promotion requires BOTH a GM-range rating AND being
inside the top-100 of the rating leaderboard. The gold leaderboard intentionally
does NOT award Challenger (it would be misleading — a player could be "Challenger
on gold list" while sitting at Silver PvP rating).

**Starting rating:** new characters spawn at **1000** (Silver II), so the first
placement matches lean upward into Silver/Gold.

**Minimum Rating:** 0 (cannot go negative)

**API surface:** `/api/leaderboard` enriches every entry with `tierKey`,
`division`, and `tierLabel` — iOS consumes these fields and renders a `TierBadge`
in the leaderboard row and the opponent profile sheet.

---

## Combat Summary

```
COMBAT FLOW:
  1. Load class damage config
  2. Determine turn order (higher AGI first)
  3. Loop up to 15 turns:
     a. First attacks second (damage calculation → apply reduction → apply crits/dodges)
     b. Resolve lifesteal
     c. Check victory
     d. Second attacks first (if alive)
     e. Resolve lifesteal
     f. Check victory
     g. Tick cooldowns
  4. If turn 15 reached without winner, highest HP% wins
  5. Calculate ELO changes
  6. Award gold/XP/loot
```

---

## Damage Calculation Deep Dive

### Pre-Damage Rolls (W3.D1)

Before any damage is computed, two independent whiff rolls can abort the hit at zero damage:

```
0a. CHA Miss Roll (defender CHA)
    └─ if rand% < min(def_cha × 0.2, 20%) → MISS, return 0

0b. Dodge Roll (defender AGI/LUK)
    └─ if rand% < min(def_agi×0.2 + def_luk×0.1 + rogue_bonus, 30%) → DODGE, return 0
```

### Complete Damage Pipeline

```
1. Base Damage Calculation
   └─ Class formula: STR×1.5, AGI×1.5, INT×1.4+WIS×0.5, STR×1.3+VIT×0.3

2. Skill Damage (if skill available)
   └─ Base + stat scaling + rank multiplier
   └─ Replace auto-attack damage

3. Apply Variance
   └─ ×(0.9 to 1.1)

4. Apply Passive Flat Damage
   └─ + flatDamage bonus

5. Apply Passive Percent Damage
   └─ × (1 + percentDamage/100)

6. Resistance/Penetration
   └─ Armor formula for physical/magical
   └─ Poison penetration 30% of armor
   └─ True damage unchanged

7. Class Reduction (Tank only)
   └─ Tank × 0.85

8. Stance Modifiers
   └─ × (1 + attacker_stance_offense/100)
   └─ × (1 - defender_stance_defense/100)

9. Passive Damage Reduction (Defender)
   └─ × (1 - min(damageReduction, 50%) / 100)

10. Rogue Execute (W3.D2)
    └─ if attacker.class == 'rogue' && def_hp_ratio ≤ 0.35
    └─ × 1.15

11. Floor to Minimum
    └─ max(floor(damage), 1)

12. Crit Check (applied on base damage, before step 6)
    └─ if crit: × 1.5
```

**Note (W3.D1):** CHA intimidation damage reduction has been removed. CHA now gates the hit via the pre-damage miss roll (step 0a) rather than reducing damage after the fact.

---

## Common Combat Scenarios

### Scenario 1: Warrior vs Mage

**Setup:**
- Warrior (Level 20, STR 50, AGI 30, LUK 20)
- Mage (Level 20, INT 60, WIS 40, AGI 35)

**Warrior Auto-Attack:**
- Base: 50 × 1.5 + 20 × 2 = 115 dmg
- Variance: 115 × 1.05 = 120.75 → 120 (example variance roll)
- Mage Magic Resist 20: 120 × 100 / 120 = 100 physical/magical
- Crit Check: min(20 × 0.6 + 30 × 0.2, 50) = 18.0% (no crit this turn)
- **Final: 100 damage**

**Mage Auto-Attack (Magical):**
- Base: 60 × 1.4 + 40 × 0.25 + 20 × 2 = 84 + 10 + 40 = 134 dmg
- Variance: 134 × 0.97 = 130 dmg
- Warrior Magic Resist 10: 130 × 100 / 110 = 118.2 → 118 dmg
- Crit Check: min(20 × 0.6 + 35 × 0.2, 50) = 19.0% (no crit)
- **Final: 116 damage**

**Result:** Mage out-damages Warrior slightly due to INT/WIS scaling despite AGI advantage.

---

## Common Issues & Solutions

### Turn 15 Timeout

**Problem:** Combat reaches turn 15 without a winner.

**Solution:** Whichever combatant has higher HP percentage wins. Encouraging more aggressive play speeds combat.

### Dodge Spam

**Design:** Max dodge 30% means 70% of attacks always land, preventing infinite evasion.

### Infinite Cooldowns

**Design:** Minimum cooldown is 1 turn (even 99% CDR can't go lower), preventing infinite skill spam.

### Crit Overkill

**Cap:** Max 50% crit chance prevents guaranteed crits; relies on LUK investment.

</content>
</invoke>