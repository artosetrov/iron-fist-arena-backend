# Economy System (Source of Truth)
*Derived from backend implementation*

## Currencies

### Gold (Soft Currency)

**Purpose**: Primary in-game currency, earned through gameplay, spent on progression and cosmetics.

#### Earnings
| Source | Base Amount | Modifiers |
|--------|-------------|-----------|
| PvP Win | 150 | Level ×10%, CHA bonus up to 50%, Win streak 10-25%, First Win 2×, Revenge 1.5× |
| PvP Loss | 50 | — |
| Training | 50 | — |
| Training Loss | 20 | — |
| Dungeons | Difficulty-scaled | Boss bonus, floor count multiplier |
| Daily Quests | 25-100 | Level-scaled |
| Gold Mine | 100-250 | Per 4hr session, chest drops |
| Shell Game | 2× bet | Win payout (fair RNG, no house edge) |

#### Spending
| Destination | Cost | Purpose |
|-------------|------|---------|
| Item Purchase (Shop) | 500-5000 | Gear acquisition |
| Equipment Upgrades | Scaling | +1 → +10 enhancement |
| Equipment Repairs | 10% of purchase | Durability restoration |
| Shell Game Bets | 50-1000 | Gambling mechanic |
| Cosmetics | 200-1000 | Non-power cosmetics |

#### Scaling Mechanics
- **Level Scaling**: Earnings increase 10% per level (level 10 = 1.1×, level 20 = 1.2×, etc.)
- **Charisma Bonus**: Adds up to 50% to gold earnings (10% per CHA point)
- **Win Streak**: 10% bonus per consecutive win, up to 25% at 5+ wins
- **First Win Bonus**: 2× gold for first battle each day
- **Revenge Bonus**: 1.5× gold if fighting opponent who beat you previously
- **Prestige Scaling**: Earnings scale with prestige level

### Gems (Premium Currency)

**Purpose**: Acceleration currency, obtained through gameplay or IAP, spent on convenience and cosmetics.

#### Earnings
| Source | Amount |
|--------|--------|
| Daily Login Day 7 | 5 |
| Achievements | 1-10 per achievement |
| Battle Pass (free) | 50 total across 50 levels |
| Battle Pass (premium) | 100 total across 50 levels |
| Gold Mine (10% drop chance) | 1-3 per session |
| In-App Purchase | 100-6500 per pack |

#### Spending
| Destination | Cost | Purpose |
|-------------|------|---------|
| Stamina Refill | 10 | Time-gating acceleration |
| Inventory Expansion | 20 per slot | Soft cap increase (capped at 28 total) |
| Stat Respec | 50 | Build flexibility (stat point reallocation) |
| Passive Respec | 100 | Build flexibility (passive tree reset) |
| Battle Pass Premium | 500 | Premium cosmetic/reward track |
| Gold Mine Slot Unlock | 30 | 4th/5th mining slot (if applicable) |
| Gold Mine Boost | 10 | Instant 4hr session completion |

#### Economy Rules
- **No gem → gold conversion** (prevents pay-to-win)
- **No gem refunds** once spent
- **Gem drops are rare** but meaningful (Gold Mine only, 10% chance)
- **Balanced acquisition**: F2P players earn 5 gems/week from login + 50+ from Battle Pass/achievements

### Arena Tokens (Planned)

**Purpose**: Future exclusive cosmetics and limited-edition items.

**Current Implementation**: Minimal — reserved for exclusive cosmetics system in later season.

---

## In-App Purchase (IAP) Products

### Gem Packs

Standard gem packages with tiered pricing. Larger packs offer better value ($/gem).

| Pack | Gems | Price | Rate (Gems/$) | Best For |
|------|------|-------|---------------|----------|
| Small | 100 | $0.99 | 101 | First-time buyer |
| Medium | 550 | $4.99 | 110 | ⭐ Recommended tier |
| Large | 1200 | $9.99 | 120 | Regular player |
| Huge | 2500 | $19.99 | 125 | Committed player |
| Mega | 6500 | $49.99 | 130 | Whale tier |

**Pricing Strategy**:
- Small pack: Entry point for hesitant buyers
- Medium pack (⭐): Sweet spot — best value per dollar, highest conversion
- Large+ packs: Diminishing returns, targets engaged players

### Gold Packs

Direct gold purchase (primarily for new players who need starting capital).

| Pack | Gold | Price | Use Case |
|------|------|-------|----------|
| Starter | 500 | $0.99 | New player gear |
| Standard | 1200 | $1.99 | Quick shop purchases |
| Premium | 3500 | $4.99 | Equipment upgrades |
| Deluxe | 8000 | $9.99 | Full build refresh |
| Ultimate | 20000 | $19.99 | Major progression |

**Note**: Gold packs are secondary monetization — gems are primary. Gold purchase encourages spending but doesn't lock power.

### Subscription Products

Recurring revenue with steady value delivery.

#### Monthly Gem Card
- **Instant**: 50 gems on purchase
- **Daily**: 10 gems/day for 30 days
- **Total**: 350 gems for $4.99
- **Value**: Equivalent to ~$17 in gem packs (341% value)
- **ROI**: Encourages continued play (daily reminder)

#### Premium Forever
- **One-time**: $9.99
- **Permanent**: Unlocks permanent cosmetic/account benefit
- **Use**: Status symbol, account-wide cosmetic effect
- **Future use**: Could unlock exclusive shop filters, faster animations, etc.

---

## Monetization Points (Friction & Acceleration)

### 1. Stamina Refill (10 Gems)
- **Friction**: 5-10 stamina per battle, regens 1/5min, gates PvP sessions
- **Acceleration**: Pay gems to continue playing immediately
- **Fair play**: Energy fully regenerates (no hard paywall)
- **Whaling resistance**: Players will refill once/day max

### 2. Inventory Expansion (20 Gems per slot)
- **Friction**: Soft cap at 8 base slots, caps at 28 total
- **Acceleration**: Expand to farm more efficiently
- **Fair play**: All power is equippable, expansion is convenience
- **Whaling resistance**: Rare use case (90% players never buy)

### 3. Stat/Passive Respec (50/100 Gems)
- **Friction**: Respec locked, encourages commitment to builds
- **Acceleration**: Pivot strategies without re-leveling
- **Fair play**: All builds equally viable, respec unlocks flexibility
- **Whaling resistance**: Used 1-2× per month by engaged players

### 4. Battle Pass Premium (500 Gems)
- **Friction**: Two-track system (free = slow, premium = faster)
- **Acceleration**: Unlock cosmetic rewards and tier skips
- **Fair play**: Free track has full progression (cosmetics only)
- **Whaling resistance**: Cosmetic-only, no power advantage

### 5. Gold Mine Slot Expansion (30 Gems)
- **Friction**: Passive income, base 1 slot (→ 4-5 available)
- **Acceleration**: Multiple simultaneous passive sessions
- **Fair play**: Purely passive, no grinding required
- **Whaling resistance**: Marginal benefit (steady 100-250 gold/4hr)

### 6. Gold Mine Boost (10 Gems)
- **Friction**: 4hr wait timer on completion
- **Acceleration**: Instant completion, collect rewards now
- **Fair play**: Not required for progression
- **Whaling resistance**: Low-cost convenience

---

## Economy Health Principles

### Fair Play Guarantee
✓ **All power is earnable through play** — no gear or stat advantage locked behind paywall
✓ **Gems accelerate, never restrict** — free players can reach endgame (slower)
✓ **PvP is skill + build, not wallet** — card-based matchmaking, ELO rating
✓ **Cosmetics only for premium** — visual differentiation, not competitive edge

### Anti-Exploit Rules
✗ **No gem → gold conversion** — prevents pay-to-win farming
✗ **Stamina gate on PvP** — prevents whale dominance via session length
✗ **Equipment gold sinks** — repair costs drain gold, prevent soft currency hoarding
✗ **Level-based matchmaking** — prevents smurfing with bought gear

### Economy Levers (Live Ops)
- **Daily bonus boost** (2× gold, 3× XP) — combat dead periods
- **Flash sales** (30-50% off cosmetics) — FOMO retention
- **Battle pass speedup** (XP bonuses) — season closing push
- **Event currency** (seasonal special drops) — limited-time engagement
- **Prestige bonus scaling** — long-term player reward

---

## Economy Flow Diagram

```
                    ┌─────────────────┐
                    │   FREE PLAYERS  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         Daily Quests    PvP (150g)    Dungeons
              │              │              │
              └──────────────┼──────────────┘
                             │
                         (150-250g/day)
                             ▼
                    ┌─────────────────┐
                    │   SPEND: GOLD   │ ← Equipment, Upgrades, Repairs
                    └─────────────────┘


                    ┌─────────────────┐
                    │  PAID PLAYERS   │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
             IAP        + Free Earnings  Gold Mine Boost
              │              │              │
              └──────────────┼──────────────┘
                             │
                    (Gems + Extra Gold)
                             ▼
          ┌─────────────────────────────────┐
          │  Convenience + Cosmetics Only   │
          │  (Stamina, Respec, Battle Pass) │
          └─────────────────────────────────┘
```

---

## Economy Metrics to Track

### Health Indicators
- **Average Session Value (ASV)**: Total gem spend / total players
- **Gem Sink Rate**: Gems spent / gems earned (target: 0.8-1.2)
- **Gold Sink Rate**: Gold spent / gold earned (target: 0.5-0.8)
- **Battle Pass Conversion**: Premium buyers / total players (target: 5-15%)
- **Gem Pack Conversion**: Buyers / daily active users (target: 2-5%)
- **Prestige Participation**: L50 resets / total players (target: 20-40%)

### Risk Indicators
⚠️ **Gem inflation** (earn > spend) → free gems devalue, reduce login gems
⚠️ **Gold hoarding** (spend < earn) → add gold sinks (cosmetics, upgrades)
⚠️ **Whale dominance** (top 1% control 30%+ power) → skill-based matchmaking
⚠️ **Prestige deflation** (low participation) → increase prestige bonus scaling
⚠️ **IAP conversion drop** → A/B test gem pack pricing, add limited-time offers

---

## Seasonal Adjustments

### Battle Pass Cadence
- 8-week seasons
- 50-100 XP levels per season
- Free track: cosmetics + 50 gems
- Premium track: cosmetics + 100 gems (cost: 500 gems)

### Event Economy
- Limited-time event currency (e.g., "Dungeon Tokens")
- Event shops with exclusive cosmetics
- Prevents core economy inflation
- Drives seasonal engagement

### Prestige Scaling
- Every prestige level = +5% to gold/XP earnings
- Prestige 1 = 1.05×, Prestige 5 = 1.25×
- Infinite scaling encourages endgame play
- Prevents late-game economy stagnation
