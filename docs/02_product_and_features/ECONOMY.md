# Economy System — Economy v2 (Source of Truth)
*Updated: 2026-04-09 — Economy v2 rebalance applied*

## Currencies

### Gold (Soft Currency)

**Purpose**: Primary in-game currency, earned through gameplay, spent on progression.

**Starting gold**: 300 (new characters)

#### Earnings
| Source | Base Amount | Modifiers |
|--------|-------------|-----------|
| PvP Win | 150 | Level ×2%, CHA bonus (diminishing, cap 125%), Win streak +20/50/100%, First Win 2×, Revenge 1.5× |
| PvP Loss | 50 | Level ×2% |
| Training Win | 30 | — |
| Training Loss | 10 | — |
| Dungeons | Difficulty-scaled | Boss bonus, floor count multiplier |
| Daily Quests | 25-100 | Level-scaled |
| Gold Mine | 40-100 per 4hr session | 10% gem drop (1-3 gems) |
| Shell Game | 2× bet | Fair RNG, no house edge |
| Daily Login | Day 1: 150g, Day 3: 300g, Day 5: 500g | Weekly cycle |
| Tutorial NPC Quests | ~1300g total | One-time |

#### Spending (Sinks)
| Destination | Cost | Purpose |
|-------------|------|---------|
| Equipment Purchase (Shop) | 100-8000+ | Rarity/level scaled |
| Equipment Upgrades | 150 × 1.4^N (exponential) | +1→+10 enhancement |
| Equipment Repairs | 80 + level×15, rarity mult | Durability restoration |
| Consumable Potions | 150-800 | Stamina/HP recovery |
| Gem Packs (gold) | 500-3000 | In-shop gem pack purchases |
| Inventory Expansion | 5000 per 10 slots | Max 3 expansions |
| Skill Learning | 200 | Per new skill |
| Skill Upgrade | 500 + 500×rank | Per rank |
| Passive Respec | 5000 | Alternative to gem respec |
| Shell Game Bets | 50-1000 | Gambling mechanic |

#### Upgrade Cost Table (Exponential: $150 \times 1.4^N$)
| Level | Gold Cost |
|-------|-----------|
| +1 | 210 |
| +2 | 294 |
| +3 | 412 |
| +4 | 576 |
| +5 | 807 |
| +6 | 1,130 |
| +7 | 1,582 |
| +8 | 2,214 |
| +9 | 3,100 |
| +10 | 4,340 |

#### Scaling Mechanics
- **Level Scaling**: +2% per level above 1 (level 50 = ~2× rewards)
- **CHA Gold Bonus**: Diminishing returns — 0-30 CHA: +2.5%/pt, 31-60: +1%/pt, 61+: +0.5%/pt (hard cap +125%)
- **Win Streak**: 3-win +20%, 5-win +50%, 8+ win +100%
- **Loss Streak Protection**: 3 losses → next win +30%, 5 losses → +50%, 7+ → +80%
- **First Win Bonus**: 2× gold + 2× XP for first PvP win each day
- **Revenge Bonus**: 1.5× gold if fighting opponent who beat you previously

### Gems (Premium Currency)

**Purpose**: Acceleration currency, obtained through gameplay or IAP.

#### Earnings (F2P)
| Source | Amount |
|--------|--------|
| Daily Login Day 7 | 25 |
| Achievements | Variable |
| Battle Pass (free) | ~50 total across 50 levels |
| Battle Pass (premium) | ~100 total across 50 levels |
| Gold Mine (10% drop chance) | 1-3 per session |

#### Spending
| Destination | Cost | Purpose |
|-------------|------|---------|
| Stamina Refill | 30 | Instant stamina restore |
| Upgrade Protection Scroll | 50 | Prevents downgrade on failed +6 and above |
| Battle Pass Premium | 500 | Premium cosmetic/reward track |
| Gold Mine Slot Unlock | 50 | Additional mining slot |
| Gold Mine Boost | 10 | Instant 4hr session completion |
| Passive Respec | 50 | Passive tree reset |

---

## In-App Purchase (IAP) Products

### Gem Packs

| Pack | Gems | Price | Rate (Gems/$) |
|------|------|-------|---------------|
| Small | 100 | $0.99 | 101 |
| Medium | 550 | $4.99 | 110 |
| Large | 1200 | $9.99 | 120 |
| Huge | 2500 | $19.99 | 125 |
| Mega | 6500 | $49.99 | 130 |

### Gold Packs

| Pack | Gold | Price |
|------|------|-------|
| 500g | 500 | $0.99 |
| 1200g | 1200 | $1.99 |
| 3500g | 3500 | $4.99 |
| 8000g | 8000 | $9.99 |
| 20000g | 20000 | $19.99 |

### Subscription Products

#### Monthly Gem Card ($4.99)
- 50 gems instant + 10 gems/day × 30 days = 350 gems total (~341% value vs packs)

#### Starter Bundle ($2.99, one-time)
- 200 gems + 3000 gold — best $/value in the game, creates habit

#### Premium Forever ($9.99, one-time)
- Permanent account-wide cosmetic benefit

---

## Economy Health — Sink Ratio Targets

| Player Type | Target Sink Ratio | Mechanism |
|-------------|-------------------|-----------|
| Casual F2P (1-5 battles/day) | 55-65% | Repairs + potions eat most income |
| Active F2P (6-10 battles/day) | 60-70% | Upgrades + repairs + potions |
| Light Spender | 65-75% | More activity = more sinks |
| Whale | 70-80% | Exponential upgrade costs dominate |

### Key Economy v2 Changes (2026-04-09)
- Gold rewards reduced: PvP win 200→150, loss 70→50, training 50→30
- Starting gold: 500→300
- Free PvP per day: 5→3 (stamina-gated after)
- Repair costs: base 50→80, per-level 10→15
- Upgrade formula: linear (level×100) → exponential (150×1.4^N)
- Consumable prices: +25-35% across all potions
- Gold mine rewards: 60-150 → 40-100
- Daily login gold: Day 1 200→150, Day 3 500→300, Day 5 1000→500
- Upgrade protection: 30→50 gems

---

## Stamina System

| Parameter | Value |
|-----------|-------|
| Max Stamina | 120 |
| Regen Rate | 1 per 8 minutes |
| Full Regen Time | 16 hours |
| PvP Cost | 10 |
| Training Cost | 5 |
| Dungeon Easy/Normal/Hard | 15/20/25 |
| Boss | 40 |
| Free PvP Per Day | 3 (no stamina cost) |

---

## Economy Rules
- **No gem → gold conversion** — prevents pay-to-win
- **Server-authoritative** — all economy calculations on backend
- **Live-tunable** — all constants readable from GameConfig DB table
- **Exponential upgrade costs** — endgame gold sink preventing hoarding
- **Repair costs scale with rarity** — legendary items cost 5× common to repair
