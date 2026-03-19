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
| Mage | INT × 1.2 + WIS × 0.5 + Level × 2 | Spell scaling |

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
  LUK × 0.7 + AGI × 0.15 + stance_crit_bonus,
  50% max
)
```

| Stat | Contribution | Notes |
|------|--------------|-------|
| LUK | 0.7× per point | Primary crit source |
| AGI | 0.15× per point | Secondary, halved from old |
| Stance Bonus | 0–5% | Attack zone modifiers |

**Example (LUK 50, AGI 40, no stance bonus):**
- Crit = min(50 × 0.7 + 40 × 0.15 + 0, 50) = min(35 + 6, 50) = 41%

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
| AGI | 0.2× per point | Primary dodge stat |
| LUK | 0.1× per point | Secondary dodge |
| Rogue Class Bonus | +3% flat | Rogues naturally evasive |
| Stance Bonus | 0–8% | Defense zone modifiers |

**Example (AGI 50, LUK 20, Rogue class, legs stance):**
- Dodge = min(50 × 0.2 + 20 × 0.1 + 3 + 3, 30) = min(16 + 2 + 3 + 3, 30) = 24%

### Rogue Class Passive

All rogues gain +3% dodge as innate bonus.

---

## Stance System

### Body Zones

Three defensive/offensive zones available:

```
Attack Zone → Defense Zone (what you're protecting)
```

Available zones: **head**, **chest**, **legs**

### Attack Zone Bonuses

| Zone | Offense | Crit | Playstyle |
|------|---------|------|-----------|
| **head** | +10% | +5% | Aggressive, high-risk |
| **chest** | +5% | 0% | Balanced |
| **legs** | 0% | -3% | Conservative |

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

## Charisma Intimidation

### Intimidation Effect

Attacker's CHA reduces defender's outgoing damage:

```
Intimidation Reduction = min(
  (Attacker CHA × 0.15) / 100,
  15% max
)

Defender Damage = Base Damage × (1 - intimidation_reduction)
```

| CHA Value | Damage Reduction | Notes |
|-----------|-----------------|-------|
| 0 | 0% | No reduction |
| 50 | 7.5% | Mid-game |
| 100 | 15% | Cap reached |

**Example:**
- Attacker CHA 60 → Defender takes min(60 × 0.15, 15) = 9% less damage
- Attacker CHA 100+ → Defender takes 15% less damage (capped)

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
| Mage | Base damage formula | Magical | INT × 1.2 + WIS × 0.5 |

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

### PvP Rank Tiers

ELO-based rank system:

| Rank | Threshold | Color | Perks |
|------|-----------|-------|-------|
| Bronze | 0 | — | Starter rank |
| Silver | 1200 | Blue | Milestone |
| Gold | 1500 | Yellow | Mid-tier |
| Platinum | 1800 | Silver | High tier |
| Diamond | 2100 | Blue | Very high |
| Grandmaster | 2400+ | Purple | Elite only |

**Minimum Rating:** 0 (cannot go negative)

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

### Complete Damage Pipeline

```
1. Base Damage Calculation
   └─ Class formula: STR×1.5, AGI×1.5, INT×1.2+WIS×0.5, STR×1.3+VIT×0.3

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

9. Intimidation (Defender CHA)
   └─ × (1 - min(def_cha × 0.15, 15%) / 100)

10. Passive Damage Reduction (Defender)
    └─ × (1 - min(damageReduction, 50%) / 100)

11. Floor to Minimum
    └─ max(floor(damage), 1)

12. Crit Check (before step 6)
    └─ if crit: × 1.5
```

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
- Crit Check: min(20 × 0.7 + 30 × 0.15, 50) = 19.5% → 20% (no crit this turn)
- **Final: 100 damage**

**Mage Auto-Attack (Magical):**
- Base: 60 × 1.2 + 40 × 0.5 + 20 × 2 = 72 + 20 + 40 = 132 dmg
- Variance: 132 × 0.97 = 128 dmg
- Warrior Magic Resist 10: 128 × 100 / 110 = 116.4 → 116 dmg
- Crit Check: min(20 × 0.7 + 35 × 0.15, 50) = 19.25% → 19% (no crit)
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