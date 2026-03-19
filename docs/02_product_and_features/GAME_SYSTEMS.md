# Game Systems Overview (Source of Truth)

Complete reference for all game systems in Hexbound. Each system is server-authoritative — client displays what the server returns.

---

## PvP Combat

**The core gameplay loop.** Turn-based 1v1 battles with class-based strategies, stance system, and ELO-based ranking.

### Core Mechanics
- **Format**: Turn-based 1v1 (attack → counterattack → repeat)
- **Duration**: Typical 3-8 turns per battle
- **Pacing**: Minimal animations, 2-5 min per session

### RNG & Seeding
- **Server-seeded RNG**: All randomness (hit chance, crit, damage variance) calculated server-side
- **Player cannot cheat**: Damage rolls, ability procs, critical hits are authoritative
- **Reproducible results**: Battle replay uses same seed for consistency

### Stance System
Four character stances, each affecting:
- Damage output/defense ratio
- Ability access and cooldowns
- Stat modifiers (±10-20% per stat)

Stance switching is tactical mid-battle strategy.

### Classes & Balance
| Class | Primary Stat | Role | Example Abilities |
|-------|--------------|------|-------------------|
| Warrior | STR | High damage, moderate defense | Slash, Power Attack, Provoke |
| Rogue | AGI | High crit, high dodge, lower durability | Backstab, Evade, Poison |
| Mage | INT | Crowd control, area damage, low durability | Fireball, Slow, Teleport |
| Tank | VIT | High durability, crowd control, lower damage | Shield Bash, Taunt, Fortify |

All classes equally viable — balance tuned for equal ELO distribution.

### ELO Rating
- **Rating Range**: 800 (Bronze) → 3000+ (Grandmaster)
- **Win Gain**: +20-40 ELO (varies by opponent rating)
- **Loss Penalty**: -10-40 ELO (lower penalty for stronger opponents)
- **Matchmaking**: Soft match on ±300 rating, hard cap at ±800
- **Decay**: Inactive 30+ days = -5 ELO/day (prevents stale leaderboard)

### Revenge Mechanic
- Player who lost to opponent gets +1.5× gold bonus on revenge win
- Encourages rematches, adds narrative tension
- No ELO bonus, only gold (prevents rating inflation)

### Battle States
- **Pending**: Waiting for opponent turn
- **Victory**: Won battle, showing rewards
- **Defeat**: Lost battle, showing opponent team
- **Fled**: Player abandoned (counts as loss, -20 ELO penalty)

---

## Dungeons

**Progression challenge mode.** Climb 10 floors, defeat monsters and bosses, collect loot.

### Progression System
- **10 Floors**: Difficulty scales per floor
- **4 Difficulties**: Normal, Hard, Heroic, Mythic
- **Scaling**: Each difficulty increases enemy stats 10-25%, reward multiplier 1× → 2.5×

### Floor Mechanics
- **Standard Floor**: 1-3 random monsters, gold/XP reward
- **Boss Floor** (Floors 5, 10): Unique boss encounter, guaranteed item drop
- **Loot Chance**: 30-60% per floor (increases per difficulty)

### Rewards
| Floor | Normal | Hard | Heroic | Mythic |
|-------|--------|------|--------|--------|
| 1 | 50g, 20 XP | 75g, 30 XP | 100g, 40 XP | 150g, 60 XP |
| 5 | 150g, 60 XP + item | 225g, 90 XP + item | 300g, 120 XP + item | 450g, 180 XP + item |
| 10 | 300g, 150 XP + boss item | 450g, 225 XP + boss item | 600g, 300 XP + boss item | 900g, 450 XP + boss item |

### Boss Encounters
- **Unique stats**: +50% HP, +30% damage vs. normal mobs
- **Special abilities**: Boss-exclusive skills (summons, AOE, debuffs)
- **Guaranteed drop**: Floor 5 = common/uncommon, Floor 10 = rare/epic
- **Difficulty scaling**: Mythic bosses have unique mechanics

### Session Structure
- Complete dungeon in single session or return to last floor
- Save progress between floors
- Can abandon dungeon (no penalty, just lose progress)

---

## Dungeon Rush

**Endless dungeon mode.** Continuous floors with exponential scaling, shop between fights, maximize rewards.

### Progression
- **Infinite floors**: Scaling indefinitely
- **Exponential difficulty**: +15% stats per floor
- **Exponential rewards**: Gold/XP multiplier increases per floor (1× → 3× → 10×)

### Shop Mechanics
- **Between every floor**: Player stops at shop, buys consumables/equipment
- **Limited inventory**: Must manage slots between floors
- **Shop stock**: 4-6 random items, refreshes per floor

### Reward Scaling
| Floor | Gold | XP | Multiplier |
|-------|------|-----|-----------|
| 1 | 50g | 20 | 1× |
| 5 | 75g | 30 | 1.5× |
| 10 | 150g | 60 | 2.5× |
| 15 | 225g | 100 | 4× |
| 20 | 375g | 150 | 6× |

### Session End
- Player loses when defeated (no revives)
- Total gold/XP split between current and offline storage
- Rewards deposited on server, delivered on next login

---

## Skills (Abilities)

**Offensive and utility actions in combat.** Each class has 4 equippable skills with cooldowns and resource requirements.

### Skill System
- **4 Equip Slots**: Active slots for battle
- **Class Restrictions**: Each skill locked to specific class(es)
- **Cooldowns**: 1-5 turn recharge between uses
- **Resource Cost**: Stamina/mana cost per cast (typically 10-25)

### Skill Progression
- **Upgradeable ranks**: Skill 1 → Skill 5 (max)
- **Scaling**: Damage +10% per rank, cooldown -0.5 turns per 2 ranks
- **Upgrade cost**: 50-500 gold per rank (scales with level)

### Skill Types
| Type | Effect | Example |
|------|--------|---------|
| Attack | Direct damage, single target | Slash, Fireball, Backstab |
| AOE | Damage multiple enemies | Power Attack, Inferno, Shrapnel |
| Control | Disable/slow enemies | Stun, Root, Silence |
| Support | Heal/buff self | Heal, Fortify, Evasion Buff |
| Stance | Switch stance, gain bonuses | Defensive Stance, Berserk, Evasion |

### Cooldown Mechanics
- Cooldowns tracked per turn (shared across stances)
- Cooldown reduction stacks (passive bonuses, stat scaling)
- Instant-cast skills have 0 cooldown

---

## Passives (Talent Tree)

**Permanent bonuses through node-based progression tree.** Connect nodes to unlock higher-tier passives.

### Node System
- **15+ node types**: +STR, +AGI, +Crit, +Defense, +HP Regen, +Cooldown Reduction, etc.
- **Connections graph**: Each node has prerequisites (parent nodes)
- **Respec available**: Reset entire tree for 100 gems (not gold)

### Progression Mechanics
- **Node unlocking**: Spend points earned from leveling (1 point per level after L10)
- **Path branching**: Multiple paths through tree enable different builds
- **Synergy bonuses**: Connecting 3+ nodes of same type triggers combo bonus (+5-10% to all)

### Passive Types
| Category | Bonuses | Effect |
|----------|---------|--------|
| Stat Nodes | STR, AGI, VIT, END, INT, WIS, LUK, CHA | +1-5 per stat point |
| Combat | Crit Chance, Crit Damage, Dodge, Defense | +1-3% per node |
| Cooldown | Cooldown Reduction (CDR) | -10-20% cooldowns |
| Sustain | HP Regen, Mana Regen, Stamina Regen | +2-5 per 5s |
| Damage | Elemental Damage, Status Effect Chance | +5-10% per type |

### Tree Structure
- **Early nodes**: Easy to access, modest bonuses (all players unlock these)
- **Mid nodes**: Require 10-20 points investment, better scaling
- **Capstone nodes**: End-of-branch powerful bonuses (choose 1-2 as endgame)

---

## Equipment & Inventory

**Gear progression system with rarity tiers, stat rolling, and upgrade mechanics.**

### Item Types (8 Categories)
| Type | Slot | Quantity | Effect |
|------|------|----------|--------|
| Weapon | Main hand | 1 | +Damage, weapon ability |
| Off-hand | Off hand | 1 | +Defense or secondary ability |
| Helmet | Head | 1 | +VIT, +Defense |
| Chest | Torso | 1 | +HP, +Defense (highest defense) |
| Legs | Legs | 1 | +AGI, +Defense |
| Gloves | Hands | 1 | +STR or AGI |
| Boots | Feet | 1 | +AGI or SPEED |
| Accessory | Finger/neck | 2 | Variable bonuses |

### Rarity Tiers
| Rarity | Color | Stat Range | Upgrade Limit | Drop Chance |
|--------|-------|------------|---------------|-------------|
| Common | Gray | 1 stat | +3 | 40% |
| Uncommon | Green | 2 stats | +5 | 35% |
| Rare | Blue | 3 stats | +7 | 15% |
| Epic | Purple | 4 stats | +9 | 8% |
| Legendary | Orange | 5 stats + special | +10 | 2% |

### Stat Rolling
- **Random rolls on drop**: Each item drops with randomized stat values
- **Stat roll range**: Varies per rarity (common = ±10%, legendary = ±5%)
- **Reroll mechanic**: Pay 50-200 gold to reroll stats (future feature)

### Durability System
- **Durability loss**: Equipment loses 1 durability per battle
- **Durability cap**: 100-500 depending on rarity
- **Repair cost**: 10% of item's purchase price to restore to max
- **Broken state**: Durability 0 = equipment disabled (can't equip)
- **Purpose**: Gold sink to prevent economy hoarding

### Upgrade System (+1 to +10)
| Upgrade Level | Cost | Stat Bonus | Durability Penalty |
|--------|------|------------|--------|
| +0 | — | 0% | — |
| +1 | 100g | +5% | -10 max |
| +3 | 300g | +15% | -20 max |
| +5 | 1000g | +25% | -30 max |
| +7 | 3000g | +35% | -40 max |
| +10 | 10000g | +50% | -50 max |

- **Breakable on high upgrade**: +9/+10 can fail (10% lose upgrade)
- **Repair required**: Upgraded gear costs more to repair

### Inventory Management
- **Base slots**: 8 (one item per type except accessories)
- **Expandable to**: 28 total (20 gem investment)
- **Overflow handling**: Excess items go to mail/storage
- **Equipment swapping**: Can switch gear outside battle (in Hub/Armory)

---

## Shop

**Equipment and consumable vendor.** Browse catalog, limited-time offers drive engagement.

### Shop Inventory
- **50+ items**: Mix of weapons, armor, consumables
- **Rarity distribution**: Common (40%) → Uncommon (35%) → Rare (15%) → Epic (8%) → Legendary (2%)
- **Price range**: 500g (common) → 5000g (legendary)

### Consumables
| Consumable | Effect | Price | Use |
|------------|--------|-------|-----|
| Health Potion | +50% HP | 50g | Heal between battles |
| Stamina Potion | Full stamina restore | 100g | Mid-session recovery |
| Stat Scroll | +10% STR for 1 battle | 75g | Temporary boost |
| Revive Token | Revive in dungeon | 200g | Dungeon-only safety |

### Limited-Time Offers
- **Daily Deal**: 1-2 items at 30% off, refreshes daily
- **Flash Sale**: 4-6 items at 20% off, 6-hour window
- **Bundle Offers**: 3-5 items bundled at 25% discount (themed: warrior gear, mage gear, etc.)
- **Purpose**: Drive impulse purchases, create daily login reason

### Shop Mechanics
- **Sell equipment**: Players can sell equipped/unequipped gear (50% buy-back value)
- **Unlimited stock**: No item scarcity (not gacha-based)
- **Price transparency**: All prices visible, no RNG cost

---

## Gold Mine (Passive Income)

**Off-game passive gold generation.** Players set 4hr sessions while offline, return to collect.

### Session Mechanics
- **Base duration**: 4 hours per session
- **Base yield**: 100-250 gold per session (randomized)
- **Slots available**: 1 base, expandable to 4-5 (30 gems per slot)

### Gem Boost (10 gems)
- **Effect**: Instantly complete 4hr session
- **Yield**: Same as normal session (no bonus for gems)
- **Purpose**: Convenience, not pay-to-win

### Chest Drop (10% chance)
- **Triggers**: During any 4hr session
- **Chest types**:
  - Gold chest: +50 gold bonus
  - Gem chest: 1-3 gems (rare engagement reward)
  - Item chest: Guaranteed equipment drop

### Session Queue
- **Multiple concurrent sessions**: Can start sessions on different slots
- **Stacking**: Sessions don't block each other
- **Offline collection**: Returns online to full rewards

### Stamina Economics
- Gold Mine doesn't cost stamina (true passive)
- Encourages players to engage daily (rewards offline play)
- Revenue driver (encourages slot expansion)

---

## Shell Game (Gambling Mechanic)

**Simple RNG gambling minigame.** Cup-shell game with fair payouts.

### Mechanics
- **3 cups**: Hide gold under one cup, shuffle, player picks
- **50/50 odds**: Fair 2/3 win chance if random (no house edge)
- **Bet range**: 50-1000 gold
- **Payout**: 2× bet on win (100g bet = 200g return)

### Loss Prevention
- **Daily limit**: 5 plays/day (prevents gambling addiction)
- **Minimum bet**: 50 gold (prevents micro-losses)
- **Transparency**: Animation shows which cup has gold (player chooses, not dealer)

### RNG Implementation
- **Server-seeded**: Result determined before reveal animation
- **Player cannot cheat**: Selecting "wrong" cup always has wrong placement
- **Fair distribution**: Long-term 50% win rate across all players

### Risk/Reward
- **Risk**: Lose bet amount
- **Reward**: +100% on win (doubles money)
- **Psychology**: Quick gambles create engagement hooks (good/bad luck streaks)

---

## Daily Quests

**3 repeating quests per day.** Level-scaling, varied objectives, gold/XP/gem rewards.

### Quest System
- **3 per day**: Refreshes at 00:00 UTC
- **Level-scaling**: Difficulty adjusts to player level (L5 vs L50 same quest type)
- **Auto-complete**: Server tracks progress, quest completes automatically

### Quest Types (7 Categories)
| Type | Objective | Reward |
|------|-----------|--------|
| Defeat Enemies | Win 3 PvP battles | 50g + 20 XP + 1 gem |
| Defeat Bosses | Complete Dungeon L5 on any difficulty | 100g + 50 XP + 2 gems |
| Win Streak | Achieve 3+ consecutive PvP wins | 75g + 30 XP |
| Stat Check | Reach 100 total STR (example) | 100g + 40 XP |
| Equip Check | Equip rare+ item in 3 slots | 80g + 30 XP |
| Skill Quest | Use ability 5 times in battle | 50g + 15 XP |
| Daily Login | Log in (daily reminder) | 10g + 5 XP |

### Rewards
- **Gold**: 50-100 per quest (varies by difficulty)
- **XP**: 15-50 per quest (scales with level)
- **Gems**: 1-2 per quest (only from harder quests)

### Completion
- **Auto-track**: Server logs all progress
- **Claim on login**: Rewards show in inbox (not auto-claimed)
- **Refusal allowed**: Skip quests without penalty

---

## Daily Login

**7-day reward cycle with streak tracking.** Encourages daily engagement.

### Streak System
- **7-day cycle**: Repeats after Day 7
- **Streak tracking**: Consecutive days logging in
- **Streak breaks**: Miss 1 day = reset to 0 (except prestige carries streak)
- **Prestige preserve**: Prestige resets don't break login streak

### Rewards by Day
| Day | Reward | Value |
|-----|--------|-------|
| 1 | 50g | Common |
| 2 | 75g | Common |
| 3 | Equipment box (common) | Commons |
| 4 | 100g | Common |
| 5 | 150g + consumables | Good |
| 6 | 200g + rare item box | Good |
| 7 | 5 gems | Premium |

### Payout Strategy
- **Day 7 gem payoff**: Encourages 7-day habit (gem login tax prevents churn)
- **Day 3/5/6 equipment**: Gear drops support new players
- **Escalating gold**: Increasing amounts encourage daily habit

### Bonus Streaks
- **7-day streak bonus**: +25g + 1 gem when completing full cycle
- **Prestige streak bonus**: +50% to all Day 7 rewards (5 gems → 7.5 gems)

---

## Battle Pass

**Seasonal progression track with cosmetic/reward progression.**

### Structure
- **Seasonal cadence**: 8-week seasons
- **Level range**: 50-100 levels per season
- **Dual tracks**: Free (all players) + Premium (500 gems)
- **Crossover**: Some rewards share both tracks, others exclusive

### Leveling
- **XP source**: All activities grant battle pass XP (PvP, Dungeons, Daily Quests)
- **Level requirements**: 500 XP per level (scales to playtime)
- **Typical playtime**: Casual 5-10 min/day = ~1 level/week, serious player = 1-2 levels/day

### Reward Tracks
| Track | Reward Pool | Cosmetics |
|-------|------------|-----------|
| Free | 50 gems + cosmetics | 5 skins, 3 frames |
| Premium | 100 gems + cosmetics + rare items | 8 skins, 5 frames, 3 titles |

### Premium Track (500 gems)
- **Instant access**: Unlock all cosmetics retroactively on purchase
- **Level skip**: Option to buy levels (future, likely 5 gems/level)
- **Cosmetic exclusivity**: Premium items only on premium track

### Cosmetics Progression
- **Skin unlocks**: L1, L15, L30, L50, L75, L100 (progressive unlock)
- **Frame unlocks**: L5, L25, L60 (cosmetic frames for avatar)
- **Titles**: L10, L40, L80 (profile titles)

---

## Achievements

**30+ lifetime objectives with progress tracking and rewards.**

### Categories (Examples)
| Category | Type | Count | Reward |
|----------|------|-------|--------|
| PvP | Combat achievements | 8 | 50g + 2 gems |
| Dungeon | Progression achievements | 6 | 75g + 3 gems |
| Progression | Leveling milestones | 5 | 100g + 1 gem |
| Cosmetics | Collection achievements | 4 | 25g |
| Economy | Spending milestones | 4 | 50g + 1 gem |
| Prestige | Endgame achievements | 3 | 200g + 5 gems |

### Achievement Types
- **One-time**: Win 100 battles (never repeats)
- **Milestone**: Reach level 50 (triggers once per prestige)
- **Tracker**: Collect 50 rare items (progress bar)

### Reward Structure
- **Individual reward**: 25-200 gold per achievement
- **Bonus**: 2-5 gems per achievement (rare/special only)
- **Prestige reset**: Achievements reset per prestige cycle, rewards re-claimable

---

## Prestige System

**High-level progression system: reset at L50, keep gear, gain stat bonuses.**

### Reset Mechanics
- **Trigger**: Reach level 50
- **Reset action**: Manual prestige button (player chooses timing)
- **Stat reset**: Levels → L1, XP → 0
- **Gear retention**: All equipment kept (can equip immediately)
- **Passive reset**: Tree reset to 0 points (100 gems to keep passives)

### Prestige Bonuses
- **Per prestige level**: +5% to gold earned, XP earned
- **Prestige 1**: 1.05×, Prestige 2 = 1.10×, Prestige 5 = 1.25×
- **Infinite scaling**: No prestige cap (encourages infinite progression)

### Prestige Rewards
- **1st prestige**: Title "Reborn" + 500g + 10 gems
- **5th prestige**: Title "Legend" + 1000g + 50 gems
- **10th prestige**: Title "Eternal" + 2000g + 100 gems (+ exclusive cosmetic)

### Economy Effect
- **Soft reset**: Players re-engage (new level grind)
- **Stat scaling**: Prestige bonuses keep endgame rewarding
- **Cosmetic milestone**: Titles show prestige to other players

---

## Leaderboard

**Global ranking by rating, level, or wealth.**

### Leaderboard Types
| Type | Metric | Audience | Decay |
|------|--------|----------|-------|
| Rating | ELO rating | Competitive | -5/day inactive 30+ days |
| Level | Current level (resets per prestige) | Grinders | None |
| Gold | Total gold earned lifetime | Economy | None |
| Prestige | Highest prestige level | Long-term | None |

### Display
- **Top 100**: Shows top 100 players per leaderboard
- **Your rank**: Shows player's position + nearby ranks (±5)
- **Season resets**: Rating leaderboard resets each season (8 weeks)
- **Other persist**: Level, gold, prestige persist across seasons

### Rewards (Seasonal)
| Rank | Reward |
|------|--------|
| #1 | 1000g + 100 gems + "Grandmaster" title |
| #2-3 | 750g + 75 gems |
| #4-10 | 500g + 50 gems |
| #11-50 | 250g + 25 gems |
| #51-100 | 100g + 10 gems |

---

## Mail & Inbox

**System messages, admin broadcasts, and reward attachment delivery.**

### Message Types
| Type | Sender | Content | TTL |
|------|--------|---------|-----|
| System | Server | Battle results, quest completion, level up | Auto-clear |
| Admin | Admin | Announcements, patch notes, compensation | 30 days |
| Rewards | Server | Achievements, daily login rewards, loot | 7 days |
| Attachments | Attachments system | Gold, gems, equipment (claim within 30 days) | 30 days |

### Attachment System
- **Claim attachments**: Players manually claim rewards from mail
- **Overflow**: Excess items go to mail if inventory full
- **Expiration**: Unclaimed attachments auto-delete after 30 days
- **Purpose**: Soft cap on free rewards, encourages daily login

### Broadcast Messages
- **Admin-only**: Patch notes, server maintenance, event announcements
- **Global**: Visible to all players
- **Dismissible**: Players can close (read notification)

---

## Cosmetics

**Non-power cosmetic items for visual differentiation.**

### Categories
| Type | Effect | Rarity | Cost |
|------|--------|--------|------|
| Skins | Avatar appearance | Common-Legendary | 200-1000g or Battle Pass |
| Frames | Profile frame (avatar border) | Common-Rare | 100-500g |
| Titles | Profile title text | Rare-Epic | 300-800g or Achievement |
| Effects | Battle effects (victory animation) | Epic-Legendary | 500-1000g |

### Origin-Based Skins
- **Male Origin**: Warrior, Knight, Ranger, Wizard
- **Female Origin**: Warrior, Knight, Ranger, Wizard
- **Mythical Origin**: Angel, Demon, Dragon, Phoenix (legend-only, 1000g)

### Cosmetic Acquisition
- **Shop**: Browse all cosmetics for purchase
- **Battle Pass**: Exclusive cosmetics, timed seasonal release
- **Achievements**: Special skins for hard achievements (e.g., "Rank 1" skin)
- **Events**: Limited-time cosmetics during events (exclusive pricing)

### Cosmetic Pricing Philosophy
- **Cosmetics = monetization gate** (gems preferred)
- **Gold alternative**: Some cosmetics available for 500-1000g (long-term earn path)
- **Premium exclusivity**: Premium-only cosmetics show whale status
- **Fair access**: All gameplay cosmetics available to free players (slower grind)

---

## Live Ops Integration Points

### Event Structure (Examples)
- **Boss event**: 2-week limited dungeon boss, exclusive loot
- **PvP tournament**: Bracket-based ranking, leaderboard prizes
- **Economy event**: 2× gold weekend, special shop offers
- **Cosmetic event**: Limited-time skins, 7-day availability

### Seasonal Calendar
- **Season 1-4**: Battle pass cycles (8 weeks each)
- **Boss events**: Every 2 weeks between seasons
- **Holiday events**: New Year, Halloween, Holiday season

### Engagement Hooks
- **Daily login**: Persistent 7-day streak incentive
- **Daily quests**: Auto-resets 3 varied quests
- **Limited offers**: Flash sales, bundles (6-hour windows)
- **FOMO cosmetics**: 7-day exclusive availability
- **Prestige milestone**: Encourages long-term play

---

## Server Authority Rules

✓ **Client CANNOT calculate**:
- Combat results (damage, crit, hit chance)
- Reward amounts (gold, XP, items)
- ELO rating changes
- Economy values (prices, costs)
- Balance formulas (stat scaling, upgrade multipliers)

✓ **Client MUST display**:
- Server-returned combat results
- Server-returned reward amounts
- Server-returned leaderboard rankings
- Server-returned achievement progress

✓ **Server responsibility**:
- All RNG seeding
- All balance calculations
- All economy transactions
- Anti-cheat detection
