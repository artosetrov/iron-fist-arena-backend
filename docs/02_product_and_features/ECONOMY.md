# Economy System — Economy v2 (Source of Truth)
*Updated: 2026-04-10 — W3.D3 sink-ratio rebalance applied*

## Currencies

### Gold (Soft Currency)

**Purpose**: Primary in-game currency, earned through gameplay, spent on progression.

**Starting gold**: 300 (new characters)

#### Earnings
| Source | Base Amount | Modifiers |
|--------|-------------|-----------|
| PvP Win | 150 | Level ×2%, CHA bonus (diminishing, cap **80%** — W3.D3), Win streak **+15/30/50%** (W3.D3), First Win 2×, Revenge 1.5× |
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
| Equipment Repairs | **120 + level×20**, rarity mult (W3.D3) | Durability restoration |
| Consumable Potions | **125-875 (+25% W3.D3)** | Stamina/HP recovery |
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
- **CHA Gold Bonus (W3.D3)**: Diminishing returns — 0-30 CHA: +2.5%/pt, 31-60: +1%/pt, 61+: +0.5%/pt (**hard cap +80%**, was +125%). W3.D1 moved CHA's primary effect to miss-chance, so the gold cap tightened to keep CHA from double-dipping.
- **Win Streak (W3.D3)**: 3-win **+15%**, 5-win **+30%**, 8+ win **+50%** (was +20/+50/+100%)
- **Loss Streak Protection (W3.D3)**: 3 losses → next win **+20%**, 5 losses → **+35%**, 7+ → **+50%** (was +30/+50/+80%)
- **First Win Bonus**: 2× gold + 2× XP for first PvP win each day
- **Revenge Bonus**: 1.5× gold if fighting opponent who beat you previously
- **Training XP Diminishing Returns (W3.D4)**: first 6 dungeon clears/day award 100% XP, next 6 clears award 50% XP, every clear after that awards a 10% floor. Counter resets at UTC midnight via lazy refresh. Applies to dungeon training loop only — PvP XP is unaffected.

##### Streak & CHA Caps — Why This Shape (W3.D3)

Pre-W3.D3 the multipliers stacked. A whale with 45 CHA on an 8-win streak during first-win-of-day would earn:
$$150 \times 2.25_{\text{CHA}} \times 2.0_{\text{streak}} \times 2.0_{\text{first-win}} = 1350 \text{g}$$
…which, on top of level scaling (×1.6 at lvl 30), reached a theoretical peak of ~**×13 base**. Clash Royale, LoL, and Fortnite all cap streak bonuses well under ×2 — typical ceiling ×1.25-1.5 — so Hexbound was ~10× more generous than peer titles.

W3.D3 rebalance:
- **Win streak cap**: +50% (was +100%). Holds peak stacking to ~×6 base — aggressive but not runaway.
- **Loss-streak recovery cap**: +50% (was +80%). Still cushions tilt recovery but stops loss-streak farming.
- **CHA cap**: 80% (was 125%). W3.D1 already made CHA's primary effect a miss-chance aura, so the gold bonus is now a secondary flavor, not the marquee stat.

Empirically the streak cap alone moves overall sink ratio ~20 points, and CHA adds another ~5 points at whale scale.

##### Training XP DR — Why This Shape

| Range | Multiplier | Intent |
|-------|-----------|--------|
| Clears 1-6 | 1.0× | Full reward window — typical session |
| Clears 7-12 | 0.5× | Soft DR — whales still progress, pace slows |
| Clears 13+ | 0.1× | Hard floor — never zero, no brick |

Pattern combines **LoL First Win of the Day** (hard bonus window), **RAID: Shadow Legends XP brew farming** (tiered DR), and **WoW rested XP** (reward for session breaks). The 10% floor is the anti-brick guarantee — a player who wants to keep grinding always gets *something*, preserving player agency while flattening the top-end curve that was letting no-lifers out-level the ladder.

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
| Stamina Refill (1st of day) | 50 | Instant stamina restore |
| Stamina Refill (2nd of day) | 80 | 1.6× — diminishing returns (Economy v3) |
| Stamina Refill (3rd of day) | 140 | 2.8× — diminishing returns (Economy v3) |
| Stamina Refill (4th of day) | 240 | 4.8× — final refill, then hard cap (Economy v3) |
| Upgrade Protection Scroll | 50 | Prevents downgrade on failed +6 and above |
| Battle Pass Premium | 500 | Premium cosmetic/reward track |
| Gold Mine Slot Unlock | 50 | Additional mining slot |
| Gold Mine Boost | 10 | Instant 4hr session completion |
| Passive Respec | 50 | Passive tree reset |

##### Stamina Refill Diminishing Returns (W3.D4)

Refill prices escalate across the day and hard-cap at **4 refills per day**.
Full daily cost is $50 + 80 + 140 + 240 = 510$ gems (vs. 200 under a flat 4 × 50 model).

Pattern mirrors Clash Royale chest slot refreshes and Genshin Fragile Resin caps:
both make whales self-regulate without punishing free-to-play players, who rarely
buy more than one refill in a session. Counters reset at UTC midnight via lazy
refresh on the next refill request — no scheduled job.

Rationale: a flat-price refill lets one player buy 20 refills in a day and
out-grind 40 opponents, which brakes matchmaking and ranked integrity. Capping at 4
keeps acceleration available without turning gems into unlimited stamina.

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

#### Premium Forever ($9.99, one-time) — W3.D5 (IAP-02) expansion

Permanent account-wide benefit bundle. Stored on `User.premiumUntil` (far-future
timestamp for the lifetime SKU). All math lives in `backend/src/lib/game/premium.ts`.

| Perk | Mechanic | Touchpoints |
|---|---|---|
| **+10% gold multiplier** | `goldBonusMultiplier(user) = hasPremium(user) ? 1.10 : 1.00` | Applied at the **END** of the reward stack — after CHA cap, streak, first-win-of-day, event multipliers. PvP resolve, dungeon complete, rush reward, duel reward, daily login gold, quest rewards. |
| **+25 gems / UTC day** | `PREMIUM_DAILY_GEMS = 25`, gated by `hasPremiumGemsClaimedToday(premiumGemClaimDate)` | Awarded atomically inside the `/api/daily-login/claim` transaction. `premiumGemClaimDate` rolls over on UTC midnight — the daily login itself is the delivery vehicle, no separate claim button. |
| **"Chosen" cosmetic title** | Client-side render in profile/leaderboard sheet | Purely cosmetic, no gameplay impact. |

**Sink-ratio protection (CRITICAL):** the +10% gold multiplier is applied
**after** the CHA soft-cap from W3.D3 — it does NOT compound with CHA inflation.
The economy simulator in `tests/economy/sink-ratio.test.ts` includes a Premium
archetype and must stay inside the 55-80% band.

**Not included:** raw stat boosts, XP multipliers, loot quality bumps. Premium
Forever is deliberately light on power (F2P-friendly) — it sells convenience,
not competitive advantage.

---

## Economy Health — Sink Ratio Targets

| Player Type | Target Sink Ratio | Mechanism |
|-------------|-------------------|-----------|
| Casual F2P (1-5 battles/day) | 55-65% | Repairs + potions eat most income |
| Active F2P (6-10 battles/day) | 60-70% | Upgrades + repairs + potions |
| Light Spender | 65-75% | More activity = more sinks |
| Whale | 70-80% | Exponential upgrade costs dominate |

### W3.D3 Sink-Ratio Acceptance (2026-04-10)

Measured by `backend/src/lib/game/economy-simulator.ts` — a pure Monte-Carlo model that runs 1000 synthetic players × 30 days against the live `balance.ts` formulas.

| Archetype | Avg gold/day in | Avg gold/day out | Sink ratio | Cumulative net (30d) |
|-----------|-----------------|------------------|------------|-----------------------|
| Casual (lvl 15, 2 PvP/d) | ~891 | ~516 | **57.9%** | +11.2M |
| Active (lvl 30, 7 PvP/d) | ~3,746 | ~2,335 | **62.3%** | +42.3M |
| Whale (lvl 45, 15 PvP/d) | ~10,558 | ~7,840 | **74.3%** | +81.5M |
| **Overall** | — | — | **70.4%** | — |

Simulator methodology notes:
- **Optimistic on income** — streak bonus applied at expected value (not max), CHA bonus at full curve, first-win-of-day always fires. Real sink ratio is therefore ≥ simulator number, so the measured band is a conservative floor.
- **Sinks at expected value** — upgrade attempts (not successes), full-set repair cycles at realistic cadence (~every 12-14 fights = 0.10/0.15/0.22 cycles per day for casual/active/whale).
- **Deterministic** — seeded with `20260410`, locked in `tests/economy/sink-ratio.test.ts`.
- **CI gate** — acceptance test requires casual ≥ 50%, active ≥ 55%, whale ≥ 60%, overall ≥ 55%, and every archetype must stay net-positive over 30 days (pressure, not impossibility).

Every archetype sits comfortably inside the 55-80% Economy v2 band. Whale is at the top of the band as intended — the exponential upgrade curve is supposed to dominate their spend.

Run interactively:
```bash
cd backend && npx tsx scripts/simulate-economy.ts
# or with a custom scenario:
cd backend && npx tsx scripts/simulate-economy.ts --players 5000 --days 60 --seed 777
```

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

### W3.D3 Deltas (2026-04-10)
- **Win streak cap**: +20/+50/+100% → +15/+30/+50% (Clash Royale / LoL parity)
- **Loss streak recovery**: +30/+50/+80% → +20/+35/+50%
- **CHA gold bonus hard cap**: 125% → 80% (CHA primary effect moved to miss-chance in W3.D1)
- **Repair BASE_COST**: 80 → 120; **PER_LEVEL**: 15 → 20 (RAID / AFK Arena 25-35% income band)
- **Consumable prices**: small stamina 100→125, small HP 150→190 (+25% across tiers)
- **No new sink consumables** this day — Bless Weapon Scroll deferred to W4 to keep W3 combat hot path stable
- **Simulator + CI gate** — `economy-simulator.ts` + `sink-ratio.test.ts` locks acceptance bands against future drift
- **Helper coverage** — `tests/lib/balance-gold.test.ts` locks streak/CHA/repair/upgrade formulas (37 regression tests)

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
