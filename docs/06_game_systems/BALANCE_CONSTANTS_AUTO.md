<!-- AUTO-GENERATED from backend/src/lib/game/balance.ts — DO NOT EDIT MANUALLY -->
<!-- Regenerate with: cd backend && npm run docs:balance -->

# Balance Constants — Auto-Generated Reference

> **Source of truth:** `backend/src/lib/game/balance.ts`
> **Curated narrative:** `docs/06_game_systems/BALANCE_CONSTANTS.md`
>
> This document is the mechanical mirror of `balance.ts`. Every number below
> is read from code at generation time. If you edit this file by hand, the
> pre-commit drift check will fail.

## Table of contents

- [Stamina](#stamina)
- [HP regen](#hp-regen)
- [XP & leveling](#xp--leveling)
- [Gold rewards](#gold-rewards)
- [First-win bonus](#first-win-bonus)
- [Equipment upgrade](#equipment-upgrade)
- [Daily login rewards](#daily-login-rewards)
- [IAP products](#iap-products)
- [Battle pass](#battle-pass)
- [ELO & PvP ranks](#elo--pvp-ranks)
- [Combat](#combat)
- [Battle fatigue](#battle-fatigue)
- [Stance zones](#stance-zones)
- [Prestige](#prestige)
- [Drop chances](#drop-chances)
- [Streak bonuses](#streak-bonuses)
- [Repair & upgrade costs](#repair--upgrade-costs)
- [Skills & passives](#skills--passives)
- [Gem costs](#gem-costs)
- [Stat purchase](#stat-purchase)
- [Inventory](#inventory)
- [Extra PvP](#extra-pvp)
- [Rarity distribution](#rarity-distribution)

## Stamina


### STAMINA

| Key | Value |
|-----|-------|
| `MAX` | `180` |
| `REGEN_RATE` | `1` |
| `REGEN_INTERVAL_MINUTES` | `8` |
| `PVP_COST` | `10` |
| `DUNGEON_EASY` | `15` |
| `DUNGEON_NORMAL` | `20` |
| `DUNGEON_HARD` | `25` |
| `BOSS` | `40` |
| `TRAINING` | `5` |
| `FREE_PVP_PER_DAY` | `3` |

### Refill diminishing returns (W3.D4)

| Refill # | Cost multiplier |
|----------|-----------------|
| 1 | ×1 |
| 2 | ×1.6 |
| 3 | ×2.8 |
| 4 | ×4.8 |

**Daily cap:** 4 refills per UTC day (hard gate). Pattern: Clash Royale chest slots + Genshin Fragile Resin.

### Training XP diminishing returns (W3.D4)

- First **6** dungeon clears/day: **100% XP**  
- Next **6** clears: **50% XP**  
- Every clear after: **10% XP** (floor, never zero)

Counter resets at UTC midnight via lazy refresh. Pattern: LoL First Win of the Day + RAID XP brew farming.

**Derived:** full 0→180 stamina takes 1440 minutes (24.0 hours).

## HP regen


### HP_REGEN

| Key | Value |
|-----|-------|
| `REGEN_RATE` | `1` |
| `REGEN_INTERVAL_MINUTES` | `5` |

**Derived:** out-of-combat regen is 1% of maxHp per 5 minutes → full heal in 500 minutes.

## XP & leveling

Formula: `xpForLevel(level) = 100 * level + 20 * level²`

| Level | XP required | Cumulative delta |
|-------|-------------|-------------------|
| 1 | 120 | +120 |
| 2 | 280 | +160 |
| 5 | 1,000 | +720 |
| 10 | 3,000 | +2,000 |
| 20 | 10,000 | +7,000 |
| 30 | 21,000 | +11,000 |
| 40 | 36,000 | +15,000 |
| 50 | 55,000 | +19,000 |
| 60 | 78,000 | +23,000 |
| 75 | 120,000 | +42,000 |
| 100 | 210,000 | +90,000 |

## Gold rewards


### GOLD_REWARDS

| Key | Value |
|-----|-------|
| `PVP_WIN_BASE` | `150` |
| `PVP_LOSS_BASE` | `50` |
| `TRAINING_WIN` | `30` |
| `TRAINING_LOSS` | `10` |
| `REVENGE_MULTIPLIER` | `1.5` |


### XP_REWARDS

| Key | Value |
|-----|-------|
| `PVP_WIN_XP` | `150` |
| `PVP_LOSS_XP` | `50` |
| `TRAINING_WIN_XP` | `60` |
| `TRAINING_LOSS_XP` | `20` |

## First-win bonus


### FIRST_WIN_BONUS

| Key | Value |
|-----|-------|
| `GOLD_MULT` | `2` |
| `XP_MULT` | `2` |

## Equipment upgrade

### UPGRADE_CHANCES (success % per +N level)

| +Level | Success % |
|--------|-----------|
| +1 | 100% |
| +2 | 100% |
| +3 | 100% |
| +4 | 100% |
| +5 | 100% |
| +6 | 80% |
| +7 | 60% |
| +8 | 40% |
| +9 | 30% |
| +10 | 20% |

### UPGRADE_COSTS


### UPGRADE_COSTS

| Key | Value |
|-----|-------|
| `BASE` | `150` |
| `EXPONENT` | `1.4` |

**Derived cost table:**

| +Level | Gold cost |
|--------|-----------|
| +1 | 210 |
| +2 | 293 |
| +3 | 411 |
| +4 | 576 |
| +5 | 806 |
| +6 | 1,129 |
| +7 | 1,581 |
| +8 | 2,213 |
| +9 | 3,099 |
| +10 | 4,338 |

## Daily login rewards

7-day cycle, ships to clients via `/api/game/init` → `config.dailyLoginRewards`.

| Day | Type | Amount | Display name | Display icon | Item ID |
|-----|------|--------|--------------|--------------|---------|
| 1 | gold | 150 | 150 Gold | `icon-gold` | — |
| 2 | consumable | 1 | 1 S. Potion | `icon-stamina-small` | stamina_potion_small |
| 3 | gold | 300 | 300 Gold | `icon-gold` | — |
| 4 | consumable | 2 | 2 S. Potions | `icon-stamina-small` | stamina_potion_small |
| 5 | gold | 500 | 500 Gold | `icon-gold` | — |
| 6 | consumable | 1 | 1 L. Potion | `icon-stamina-large` | stamina_potion_large |
| 7 | gems | 25 | 25 Gems | `icon-gems` | — |

## IAP products

| Product ID | Gems | Gold | Premium | Monthly gem card | Price USD |
|------------|------|------|---------|------------------|-----------|
| `gems_small` | 100 | 0 | — | — | $0.99 |
| `gems_medium` | 550 | 0 | — | — | $4.99 |
| `gems_large` | 1200 | 0 | — | — | $9.99 |
| `gems_huge` | 2500 | 0 | — | — | $19.99 |
| `gems_mega` | 6500 | 0 | — | — | $49.99 |
| `gold_500` | 0 | 500 | — | — | $0.99 |
| `gold_1200` | 0 | 1200 | — | — | $1.99 |
| `gold_3500` | 0 | 3500 | — | — | $4.99 |
| `gold_8000` | 0 | 8000 | — | — | $9.99 |
| `gold_20000` | 0 | 20000 | — | — | $19.99 |
| `adventurer_bundle_I` | 600 | 3000 | — | — | $4.99 |
| `adventurer_bundle_II` | 1400 | 10000 | — | — | $9.99 |
| `adventurer_bundle_III` | 3200 | 20000 | — | — | $19.99 |
| `monthly_gem_card` | 50 | 0 | — | yes | $4.99 |
| `starter_bundle` | 200 | 3000 | — | — | $2.99 |
| `premium_forever` | 0 | 0 | yes | — | $9.99 |
| `premium_pass_monthly` | 0 | 0 | — | — | $4.99 |

## Battle pass


### BATTLE_PASS

| Key | Value |
|-----|-------|
| `BP_XP_PER_PVP` | `20` |
| `BP_XP_PER_DUNGEON_FLOOR` | `30` |
| `BP_XP_PER_QUEST` | `50` |
| `BP_XP_PER_ACHIEVEMENT` | `100` |

**Formula:** `bpXpForLevel(level) = 100 + level * 50`

| BP Level | XP required |
|----------|-------------|
| 1 | 150 |
| 5 | 350 |
| 10 | 600 |
| 25 | 1,350 |
| 50 | 2,600 |
| 100 | 5,100 |

## ELO & PvP ranks


### ELO

| Key | Value |
|-----|-------|
| `K_CALIBRATION` | `48` |
| `K_DEFAULT` | `32` |
| `CALIBRATION_GAMES` | `10` |
| `MIN_RATING` | `0` |


### PVP_RANKS (rating thresholds)

| Key | Value |
|-----|-------|
| `BRONZE` | `0` |
| `SILVER` | `750` |
| `GOLD` | `1500` |
| `PLATINUM` | `2250` |
| `DIAMOND` | `3000` |
| `MASTER` | `3750` |
| `GRANDMASTER` | `4250` |

## Combat


### COMBAT

| Key | Value |
|-----|-------|
| `MAX_TURNS` | `15` |
| `MIN_DAMAGE` | `1` |
| `CRIT_MULTIPLIER` | `1.5` |
| `MAX_CRIT_CHANCE` | `50` |
| `MAX_DODGE_CHANCE` | `30` |
| `ROGUE_DODGE_BONUS` | `4` |
| `TANK_DAMAGE_REDUCTION` | `0.85` |
| `DAMAGE_VARIANCE` | `0.1` |
| `POISON_ARMOR_PENETRATION` | `0.3` |
| `CRIT_PER_LUK` | `0.6` |
| `CRIT_PER_AGI` | `0.2` |
| `DODGE_PER_AGI` | `0.2` |
| `DODGE_PER_LUK` | `0.1` |
| `ROGUE_EXECUTE_HP_THRESHOLD` | `0.35` |
| `ROGUE_EXECUTE_DAMAGE_BONUS` | `0.15` |
| `CHA_MISS_PER_POINT` | `0.2` |
| `CHA_MISS_CAP` | `20` |

## Battle fatigue


### BATTLE_FATIGUE

| Key | Value |
|-----|-------|
| `FATIGUE_START_TURN` | `10` |
| `FATIGUE_PERCENT_PER_TURN` | `10` |

**Mechanic:** after turn 10, both fighters deal +10% more damage per additional turn.

## Stance zones

Valid zones: `head`, `chest`, `legs`

### Attack zone bonuses

| Zone | Offense | Crit |
|------|---------|------|
| head | 10 | 5 |
| chest | 5 | 0 |
| legs | 2 | 0 |

### Defense zone bonuses

| Zone | Defense | Dodge |
|------|---------|-------|
| head | 0 | 8 |
| chest | 10 | 0 |
| legs | 5 | 3 |

**Mismatch offense bonus:** +5 (attacker)  
**Match defense bonus:** +15 (defender)

## Prestige


### PRESTIGE

| Key | Value |
|-----|-------|
| `MAX_LEVEL` | `50` |
| `STAT_BONUS_PER_PRESTIGE` | `0.05` |
| `STAT_POINTS_PER_LEVEL` | `3` |

## Drop chances

| Source | Drop chance |
|--------|-------------|
| pvp | 15% |
| training | 5% |
| dungeon_easy | 20% |
| dungeon_normal | 30% |
| dungeon_hard | 40% |
| boss | 75% |

## Streak bonuses

### Win streak gold bonus

| Streak length | Bonus |
|---------------|-------|
| 0 | +0% |
| 3 | +15% |
| 4 | +15% |
| 5 | +30% |
| 6 | +30% |
| 7 | +30% |
| 8 | +50% |
| 9 | +50% |
| 10 | +50% |

### Loss streak gold recovery (applied on next win)

| Loss streak | Bonus on next win |
|-------------|-------------------|
| 0 | +0% |
| 3 | +20% |
| 4 | +20% |
| 5 | +35% |
| 6 | +35% |
| 7 | +50% |
| 8 | +50% |
| 9 | +50% |
| 10 | +50% |

## Repair & upgrade costs

### REPAIR_COSTS

- **Base cost:** 120 gold  
- **Per level:** +20 gold  

**Rarity multipliers:**

| Rarity | Multiplier |
|--------|------------|
| common | ×1 |
| uncommon | ×1.5 |
| rare | ×2 |
| epic | ×3 |
| legendary | ×5 |

## Skills & passives


### SKILLS

| Key | Value |
|-----|-------|
| `MAX_EQUIPPED_SLOTS` | `4` |
| `UPGRADE_GOLD_BASE` | `500` |
| `UPGRADE_GOLD_PER_RANK` | `500` |
| `LEARN_GOLD_COST` | `200` |


### PASSIVES

| Key | Value |
|-----|-------|
| `POINTS_PER_LEVEL` | `1` |
| `MAX_PASSIVE_POINTS` | `50` |
| `RESPEC_GEM_COST` | `50` |
| `RESPEC_GOLD_COST` | `5000` |
| `BASE_ACTIVE_SLOTS` | `3` |
| `MAX_ACTIVE_SLOTS` | `4` |
| `PREMIUM_ACTIVE_SLOT_GEM_COST` | `100` |

## Gem costs


### GEM_COSTS

| Key | Value |
|-----|-------|
| `STAMINA_REFILL` | `50` |
| `EXTRA_PVP_COMBAT` | `50` |
| `BATTLE_PASS_PREMIUM` | `700` |
| `GOLD_MINE_BUY_SLOT` | `50` |
| `GOLD_MINE_BOOST` | `15` |
| `UPGRADE_PROTECTION` | `40` |

## Stat purchase

- **Daily limit:** 5  
- **Global cap:** 50  

**Escalating daily cost (gems):**

| Purchase # | Gem cost |
|------------|----------|
| 1 | 15 |
| 2 | 20 |
| 3 | 30 |
| 4 | 45 |
| 5 | 65 |

## Inventory


### INVENTORY

| Key | Value |
|-----|-------|
| `BASE_SLOTS` | `28` |
| `EXPAND_AMOUNT` | `10` |
| `EXPAND_COST_GOLD` | `5000` |
| `MAX_EXPANSIONS` | `3` |
| `MAX_SLOTS` | `58` |

**Derived:** max slots a character can ever reach = 28 + 3 × 10 = 58.

## Extra PvP


### EXTRA_PVP

| Key | Value |
|-----|-------|
| `STAMINA_GRANTED` | `5` |

## Rarity distribution

| Rarity | Weight (%) |
|--------|------------|
| common | 50 |
| uncommon | 30 |
| rare | 15 |
| epic | 4 |
| legendary | 1 |

**Sum check:** 100 (must equal 100)

---

*Generated by `backend/scripts/generate-balance-docs.ts`. Do not edit this file directly — edit `backend/src/lib/game/balance.ts` and rerun `npm run docs:balance`.*
