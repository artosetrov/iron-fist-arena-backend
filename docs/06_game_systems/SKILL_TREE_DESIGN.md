# Skill Tree System — Full Design Spec

**Version:** 1.0 Draft
**Date:** 2026-04-13
**Owner:** Artem + Claude (combat/progression design)
**Status:** Historical design draft — preserved as early tree/progression direction
**Related docs:** `COMBAT.md`, `PROGRESSION.md`, `BALANCE_CONSTANTS.md`, `ECONOMY.md`, `ECONOMY_RULES.md`

> **Status boundary:** preserve this document as the earlier full tree-system
> direction, not as the live passive-tree/runtime contract. Current shipped or
> later-audited truth now lives in `docs/06_game_systems/SKILL_TREE_DESIGN_V2.md`
> and `wiki/features/passive-tree.md`; use this file for design rationale and
> superseded structure only.

---

## 1. Goals & Non-Goals

### Goals
1. Give the player **visible agency** over combat — every level up produces a meaningful choice.
2. Create **build diversity** — two Lv.30 Warriors should be able to play completely differently.
3. Turn the existing backend-only passive tree into a **player-facing identity system**.
4. Introduce **skill scrolls** as a new content/monetization vector without breaking economy balance (W3.D3 sink ratios).
5. Unify agency layers (stances, tactic cards, ultimate) under **one tree** that powers everything.

### Non-Goals
- Not breaking existing combat determinism (server-authoritative, seeded PRNG stays).
- Not replacing stats/gear — tree is additive, sits on top.
- Not PoE-scale complexity — target ~36 nodes per class, mobile-readable.
- Not pay-to-win — all tree content reachable F2P, scrolls only accelerate.

---

## 2. Current State (What Exists)

From `PROGRESSION.md`:

| System | Status | Notes |
|---|---|---|
| Passive tree | ✅ Backend exists | No UI. Generic (not class-specific). 1 point/level, max 50. Respec 50 gems. |
| Active skills | ✅ Backend exists | 4 equipped slots. Cooldown-based. Learn 200g / Rank+N = 500+500×N gold. |
| Prestige | ✅ Live | +5% stats per prestige level. Passive points retained. |
| Skill scrolls | ❌ Doesn't exist | — |
| Tree UI | ❌ Doesn't exist | — |
| Class-specific trees | ❌ All generic | — |

**Key finding:** ~80% of backend plumbing is already in place. Main work is (1) redesign tree content, (2) build UI, (3) add scrolls and monetization, (4) unify slots as "loadout".

---

## 3. High-Level Design

### 3.1 One Tree Per Class

4 separate trees — Warrior, Rogue, Mage, Tank. Each tree has:

- **1 root node** (free, auto-unlocked at Lv.1)
- **3 specialization branches** (~12 nodes each)
- **Cross-branch connectors** (3–4) allowing hybrid builds
- **1 ultimate node per branch** (3 ult variants per class, pick 1 equipped)

**Total per class:** 1 + 36 + 3 = ~40 nodes. 4 classes × 40 = 160 nodes total content budget.

### 3.2 Three Node Categories

| Category | % of Tree | Purpose |
|---|---|---|
| **Stat nodes** | 45% | Flat/percent stat boosts. Low-friction dopamine. |
| **Passive proc nodes** | 25% | Conditional bonuses ("on crit: …", "at HP <30%: …"). |
| **Skill nodes** | 20% | Unlock / rank up active skills. |
| **Ultimate nodes** | 5% | Terminal nodes in each branch. Unlock 1 ult variant. |
| **Keystone nodes** | 5% | Build-defining (e.g. "All skills deal True Damage but −30% base dmg"). |

### 3.3 Four Class Identities

Each class has a unique fantasy expressed through its 3 branches:

#### **Warrior — Tree of Iron**
- **Berserker** (offense) — raw damage, rage mechanics, crit
- **Crusader** (balanced) — mix of HP, armor, sustain
- **Executioner** (finisher) — low-HP damage, execute thresholds

#### **Rogue — Tree of Shadow**
- **Duelist** (speed) — AGI scaling, dodge, counter-attacks
- **Assassin** (crit) — LUK scaling, crit multiplier, poison
- **Trickster** (debuffs) — CHA scaling, miss chance, stance fakes

#### **Mage — Tree of Arcane**
- **Pyromancer** (burst) — single-target high-damage spells, fire DoT
- **Lichborn** (sustain) — lifesteal, mana, damage over time
- **Chronomancer** (control) — cooldown reduction, turn manipulation, slows

#### **Tank — Tree of Bulwark**
- **Guardian** (defense) — armor, DR, damage reflection
- **Warden** (crowd control) — taunts, interrupts, shield bashes
- **Titan** (power) — HP-scaling damage, earthquake AoE

### 3.4 Loadout (Pre-Fight Equipment)

Every fight, player equips:

- **Passive tree** — always on, applied automatically
- **3 Active skills** from the pool they've unlocked in the tree
- **1 Ultimate** from the 3 variants they've unlocked
- **3 saved presets** per character (PvP / Dungeon / Boss)

Loadout change is **free** pre-fight. No cooldown, no cost. Mid-fight loadouts are locked (anti-cheese).

---

## 4. Tree Structure — Detailed Spec

### 4.1 Shape (ASCII diagram — Warrior example)

```
                         [ROOT — Warrior Mastery +5% all stats]
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
               [BERSERKER]         [CRUSADER]       [EXECUTIONER]
                    │                  │                  │
              +8 STR             +100 HP              +5% crit
                    │                  │                  │
             Rage Skill          Taunt Skill        Execute Skill
                    │                  │                  │
            +10% crit dmg        +15 armor         +10% crit chance
                    │                  │                  │
           Bloodthirst         Shield Bash         Behead Skill
                    │                  │                  │
           +15 STR             +5% DR               +0.25× crit dmg
                    │                  │                  │
           ● KEY: Frenzy       ● KEY: Fortify      ● KEY: Last Rites
           +30% dmg <50% HP    −10% dmg taken      Execute armed at <40% HP
                    │                  │                  │
                    └──╲          ╱───┴───╲         ╱──┘
                        ╲        ╱         ╲       ╱
                 (cross-connector — e.g. "Battle Cry" unlocks if both
                  Berserker+5 and Executioner+5 nodes allocated)
                         │                 │
                    ULTIMATE:      ULTIMATE:      ULTIMATE:
                     Frenzy        Last Stand      Headsman
```

**Reading rules:**
- Start nodes (3 roots of each branch) — unlockable any time if adjacent to Root
- Deeper nodes require 1 prerequisite in-branch
- Keystones (● KEY) are gateway nodes — must allocate all preceding nodes in branch
- Ultimate nodes require 8+ points in that branch (hard gate)
- Cross-connectors require X nodes in branch A AND Y in branch B

### 4.2 Node Costs

| Node Tier | Cost | Effect Scale |
|---|---|---|
| Tier 1 (outer ring) | 1 point | Small stat (+3–5 STR or +2% crit) |
| Tier 2 (middle) | 1 point | Medium stat (+8–10) or skill unlock |
| Tier 3 (inner) | 1 point | Large passive proc or skill rank |
| Keystone | 1 point | Build-defining bonus |
| Ultimate | 1 point | Unlocks Ultimate variant |

All nodes cost **1 skill point**. Power comes from depth commitment, not cost inflation.

### 4.3 Active Skill Library (per class)

Each class has **~12 active skills** distributed across its 3 branches. 6 "unlock" nodes per tree (2 per branch) grant new skills.

#### Warrior actives (example — 12 total)

| Skill | Branch | Type | Base Effect | Scaling | Cooldown | Trigger |
|---|---|---|---|---|---|---|
| **Rage Strike** | Berserker | Physical | +40% dmg | +10% per rank | 3 | Cooldown |
| **Bloodthirst** | Berserker | Self-buff | +8% lifesteal 2 turns | +2%/rank | 4 | Cooldown |
| **Wild Swing** | Berserker | Physical | 2 hits, each 70% dmg | +5%/rank | 5 | Cooldown |
| **Taunt** | Crusader | Self-buff | Enemy must attack Chest | — | 4 | Cooldown |
| **Shield Bash** | Crusader | Physical | 60% dmg + stun 1 turn | +8%/rank | 4 | Cooldown |
| **Heroic Recovery** | Crusader | Self-buff | Heal 15% max HP | +3%/rank | 6 | HP <50% (once per fight) |
| **Guardian** | Crusader | Self-buff | +20% armor 3 turns | +4%/rank | 5 | On dodge |
| **Execute** | Executioner | Physical | +80% dmg if enemy <40% HP | +15%/rank | 3 | Cooldown |
| **Behead** | Executioner | Physical | 100% crit chance, 2.5× crit dmg, costs HP 15% | — | 6 | Cooldown |
| **Death Dance** | Executioner | Physical | +50% dmg, each turn loses 5% HP | +10%/rank | Passive (3 turns) | On killing blow |
| **Battle Cry** | Cross (Berserker+Crusader) | Self-buff | +20% dmg, +10% armor 2 turns | +5%/rank | 5 | Cooldown |
| **Counter Stance** | Cross (Crusader+Exec) | Self-buff | Next dodge auto-crits | — | 4 | On dodge |

(Full skill lists for all 4 classes in `SKILL_TREE_SKILLS.md` — to be generated Phase 1.)

### 4.4 Ultimates (3 per class = 12 total)

Ultimates are **resource-gated** (Ultimate Meter) and **manually targetable** on-device.

#### Warrior Ultimates

| Name | Branch | Effect |
|---|---|---|
| **Frenzy** | Berserker | 3 turns: every attack crits, but take 50% more damage |
| **Last Stand** | Crusader | Cannot drop below 1 HP for 2 turns, heal 30% on expire |
| **Headsman** | Executioner | Instant kill if target <30% HP, else deal 300% damage |

#### Rogue Ultimates (preview)

- **Shadow Dance** (Duelist) — 3 consecutive attacks in one turn
- **Death Mark** (Assassin) — next 2 hits auto-crit at 3× dmg
- **Mirage** (Trickster) — 80% dodge for next 3 turns

#### Mage Ultimates (preview)

- **Meteor** (Pyromancer) — 500% INT damage, burns target 3 turns
- **Soul Drain** (Lichborn) — heal for damage dealt, +50% dmg 3 turns
- **Time Stop** (Chronomancer) — enemy skips next 2 turns

#### Tank Ultimates (preview)

- **Earthquake** (Titan) — 250% HP damage to enemy, stun 2 turns
- **Iron Walls** (Guardian) — 100% damage reduction 2 turns
- **Warcry** (Warden) — enemy can't attack, must defend 3 turns

### 4.5 Ultimate Meter

- **Fills from:** damage dealt (0.5% per dmg) + damage taken (0.3% per dmg)
- **Caps at 100%** — stays full until fired
- **Average fill time:** ~turn 6–9 in typical 10-turn fight
- **Auto-fires** if player offline at first opportunity (per `auto-cast` rule set pre-fight)
- **Manual fire** if online — 2-sec reaction window when bar hits 100%, tap ult button + zone

**Balancing rule:** ultimates must feel **decisive** (clearly swing the fight) but **not auto-win** — a full-HP enemy should survive one ultimate hit 100% of the time.

### 4.6 Tactic Cards — Deprecated / Merged

The "Tactic Cards" concept from earlier brainstorm is **merged into the tree** as passive proc nodes. "Second Wind" becomes Crusader node "Heroic Recovery". "Rage Spike" becomes Berserker node "Bloodthirst". No separate card collection — all in the tree.

**Rationale:** avoids two overlapping systems. One tree, one loadout, less UI.

---

## 5. Progression & Point Economy

### 5.1 Point Sources

| Source | Points | Cadence |
|---|---|---|
| Level up | 1 | Per level 2–50 (= 49 points) |
| Milestone bonus | 3 | At levels 10, 20, 30, 40, 50 (= 15 points) |
| Prestige bonus | 5 | Per prestige level (permanent, stacks) |
| Achievement rewards | 1–2 | Specific achievements (Tree Master, Specialist) |
| Event rewards | 1–3 | Seasonal events (capped per season) |

**Lifetime baseline:** Lv.50, no prestige = **~65 points** (49 + 15 + 1 from tutorial).
**Post-prestige-1:** **~70 points**.
**Post-prestige-5:** **~90 points**.
**Long-term ceiling:** ~120 points at prestige 10+.

### 5.2 Tree Point Budget

Per class tree: 40 nodes.

| Lifetime tier | Points | Coverage | Playstyle |
|---|---|---|---|
| 65 (Lv.50 fresh) | 65 | 1 branch full (~12) + 1 branch 80% (~10) + keystones/ult | Moderate specialist |
| 90 (Prestige 5) | 90 | 2 branches full + 1 branch 40% | Strong hybrid |
| 120 (long-term) | 120 | 3 branches full + cross connectors | Near-complete |

**Design intent:** players at Lv.50 can **fully embody one spec + dip into another**. Completing the whole tree is a **long-term prestige goal** — no "level cap = done" dead zone.

### 5.3 Point Allocation Rules

- Points allocated one at a time (no bulk "allocate 5 now").
- Once allocated, point locked until respec.
- Must have unlocked prerequisite (graph adjacency).
- Allocating the Ultimate node **auto-equips** that ult (first-time UX).
- Tree save auto-persists to backend.

---

## 6. Respec Mechanics

### 6.1 Respec Costs

| Scope | Cost | Cooldown |
|---|---|---|
| Single point refund | 10 gems | None (repeated use allowed) |
| Full passive respec | 50 gems | None |
| Full tree + active loadout | 100 gems | None |
| **First respec (ever)** | Free | Per character |
| **First respec after prestige** | Free | Per prestige level |

**Rationale:** matches existing 50-gem passive respec cost from W3.D4 economy. Single-point refund at 10 gems enables tweaking without commit-to-nuke. Free first respec = onboarding safety.

### 6.2 Soft Reset on Prestige

On prestige, player gets **free full respec token** (expires in 7 days if unused). Encourages reinvention without punishing the first-fresh-prestige confusion.

### 6.3 Respec Scroll (Consumable)

- **Respec Scroll (Common):** Single-point refund — 1 scroll = 1 point
- **Respec Scroll (Master):** Full tree respec

Drops/sources: daily quests, BP rewards, lootboxes.

---

## 7. Skill Scrolls — New Item Type

### 7.1 Purpose

Scrolls let players **accelerate tree progression** without waiting for levels — monetization-compatible, F2P-accessible.

### 7.2 Scroll Types

| Scroll | Effect | Stack-friendly? |
|---|---|---|
| **Minor Skill Scroll** | +1 skill point (applies to any unallocated point available from level gap, or as bonus) | Yes, caps at +5 bonus points |
| **Major Skill Scroll** | +3 skill points + respec free | Yes, caps at +15 bonus |
| **Rank Scroll (Common)** | +1 rank to a chosen unlocked active skill (if not max rank) | Yes |
| **Rank Scroll (Epic)** | +1 rank, skips gold cost (normally 500+500×rank) | Yes |
| **Unlock Scroll (Rare)** | Unlock 1 random node of your class tree (excluding Ultimate/Keystone) | Yes |
| **Unlock Scroll (Epic)** | Unlock 1 chosen node of your class tree (excluding Ultimate/Keystone) | Yes |
| **Ultimate Scroll (Legendary)** | Unlock 1 chosen Ultimate variant without allocating 8 branch points | No — hard-gated |
| **Mastery Scroll (Mythic)** | +1 permanent max skill point cap (above prestige cap) | Max +10 lifetime |
| **Respec Scroll (Common)** | Refund 1 allocated point | Yes |
| **Respec Scroll (Master)** | Full tree respec free | Yes |

### 7.3 Scroll Sources

#### F2P sources
- **Daily quests:** 15% chance of Minor Skill Scroll on quest completion (cap 3/day)
- **Achievements:** Major Skill Scroll at specific milestones (Ranked Platinum, 1000 PvP wins, etc.)
- **Battle Pass (free track):** 1 Minor Skill Scroll at BP levels 10, 30, 50
- **Dungeon Rush boss drops:** 2–8% chance of Rank Scroll on Hard+ difficulty
- **Guild weekly rewards:** Rank Scroll or Unlock Scroll (Rare) based on tier
- **Event currency exchange:** seasonal events offer scrolls

#### Paid sources (gem / IAP)
- **Shop direct purchase** (see §7.5)
- **Battle Pass (Premium track):** 1 Major Skill Scroll + 1 Unlock Scroll (Epic) + 1 Ultimate Scroll (Legendary) across 50 levels
- **Adventurer's Bundle III (IAP):** 1 Unlock Scroll (Epic) + 3 Rank Scrolls
- **Lootboxes:** see §7.4

### 7.4 Lootbox Integration

We introduce a new lootbox line called **Arcanist's Chest** (separate from gear lootboxes so they don't drain each other).

| Chest | Cost | Contents |
|---|---|---|
| **Wooden Arcanist Chest** | 100 gems | 1 Minor Skill Scroll + RNG: 2% Rank Scroll Common |
| **Iron Arcanist Chest** | 400 gems | 2 Minor Skill Scrolls + 1 guaranteed Rank Scroll + 5% Unlock Scroll Rare |
| **Gold Arcanist Chest** | 1200 gems | 1 Major Skill Scroll + 2 Rank Scrolls + 15% Unlock Scroll Epic + 2% Ultimate Scroll Legendary |
| **Arcane Chest (Mythic)** | 3500 gems | 1 guaranteed Ultimate Scroll Legendary + 2 Unlock Scrolls Epic + 10% Mastery Scroll Mythic |

**Pity timer:** Every 10th Gold Chest guarantees an Ultimate Scroll Legendary. Every 5th Arcane Chest guarantees a Mastery Scroll Mythic. **No lootbox is strictly required to complete a class tree** — tree is 100% F2P-accessible, chests only accelerate.

**Rate transparency:** All drop rates displayed in-game (required by App Store / Play Store for gacha-adjacent mechanics).

### 7.5 Direct Shop Prices (gems)

| Scroll | Price | Notes |
|---|---|---|
| Minor Skill Scroll | 75 gems | Cheapest direct accelerator |
| Major Skill Scroll | 250 gems | |
| Rank Scroll (Common) | 120 gems | |
| Rank Scroll (Epic) | 350 gems | |
| Unlock Scroll (Rare) | 400 gems | |
| Unlock Scroll (Epic) | 900 gems | |
| Ultimate Scroll (Legendary) | 2400 gems | ~$15 equivalent |
| Mastery Scroll (Mythic) | 4500 gems | ~$30 equivalent, max stack 10/character lifetime |
| Respec Scroll (Common) | 50 gems | |
| Respec Scroll (Master) | 200 gems | |

### 7.6 Balance Guardrails

- **Max +15 bonus skill points** per character from all scroll sources (prevents whale infinity).
- **Mastery Scroll lifetime cap:** 10 per character (= +10 above prestige cap, ~120 → 130 points max).
- **Ultimate Scrolls** cannot exceed 3 owned variants per class (matches design — there are only 3 ults per class).
- Scrolls **cannot be gifted/traded** between players (prevents alt-account farming).

---

## 8. Economy Integration — Fit Into Existing Sink Ratios

### 8.1 Post-W3.D3 sink ratios we must preserve

From `ECONOMY.md`:
- Target sink-ratio ~65% (gold earned → gold spent within week)
- Gems weekly earn (F2P) ~25–30, weekly spend ~30–50 — slight deficit drives IAP

### 8.2 New spend surfaces introduced

| Surface | Scale | Impact |
|---|---|---|
| Tree respec (gems) | 10 gems/point, 50/tree, 100/tree+loadout | Neutral — replaces ad-hoc passive respec, same magnitudes |
| Active skill rank-up gold (existing system, untouched) | 500 + 500×rank | Kept — contributes to gold sink |
| Skill scrolls (gems direct) | 50–4500 gems | New gem sink — small-medium impact |
| Arcanist Chests | 100–3500 gems | New gem sink — medium-large impact on whales |
| Rank Scroll gold alternative | — | No gold-cost scrolls initially (keep gold for gear) |

### 8.3 Projected sink impact (model)

Assumption: average active player spends 20 gems/week on scrolls (F2P median) to 800 gems/week (whale).

| Cohort | New gem sink/week | Impact on IAP incentive |
|---|---|---|
| F2P | 20 | +5% gem earn pressure — healthy |
| Casual payer | 100 | +10% spend — neutral vs existing stamina refills |
| Whale | 800 | +30% spend — strong new surface without cannibalizing BP |

### 8.4 No ruleset conflicts

Checked against `ECONOMY_RULES.md`:
- **R3 (LEVEL_REWARD_SCALE):** unaffected
- **R8 (stamina refills):** unaffected
- **R10 (bundles):** extended — Adventurer's Bundle III gets scrolls
- **R11 (Premium Pass):** extended — adds 1 Ultimate Scroll Legendary
- **R12 (BP price):** unaffected
- **R13 (Gold Mine Boost):** unaffected

No existing rules contradicted. All new spend surfaces are additive.

---

## 9. Combat Integration

### 9.1 How tree affects combat resolver

Tree bonuses applied in this order during `resolveAttack`:

```
1. Base damage (class formula)
2. + Flat stat bonuses (tree stat nodes)
3. × Percent stat bonuses (tree stat nodes)
4. Crit roll (LUK×0.6 + AGI×0.2 + stance + tree crit nodes)
5. Dodge / CHA miss
6. Variance ±10%
7. Mitigation (armor / resist — tree mitigation nodes apply here)
8. Passive procs (tree conditional nodes fire here)
9. Active skill (if fired this turn)
10. Ultimate (if fired this turn)
11. Rogue Execute (existing)
12. Damage Reduction cap (50%)
```

### 9.2 Active skill slot resolution

Current system: 4 slots, first-ready fires.
New system: **3 slots + 1 Ultimate slot**, same priority rule.

Migration: existing 4-slot characters keep all 4 skills but slot 4 becomes Ultimate slot. If slot 4 wasn't an ult-tier skill, player gets a free respec token to rearrange.

### 9.3 Ultimate Meter — new mechanic

Added to combat state:

```ts
type CombatState = {
  // ... existing fields
  attackerUltMeter: number  // 0-100
  defenderUltMeter: number  // 0-100
  attackerUltFired: boolean
  defenderUltFired: boolean
}
```

Fill rule applied per turn:
- `ultMeter += dealtDmg * 0.5 + takenDmg * 0.3`, capped at 100

Fire rule:
- If meter >= 100 and player has ult equipped and `!ultFired`:
  - Auto-fires on next turn (server decides) unless online-override received

For async PvP (opponent is ghost): opponent's ult fires automatically per their pre-set `auto-cast` rule.

### 9.4 Determinism preserved

All tree effects, active skills, and ultimates are pre-resolved from the player's loadout + PRNG seed. Server stays authoritative. No new cheese vectors.

---

## 10. UI / UX Spec

### 10.1 Three new screens

1. **Skill Tree Screen** — full-screen, scrollable canvas with 3 branches visualized radially
2. **Loadout Screen** — pre-fight, shows passive tree summary + 3 active slots + 1 ult slot + preset selector
3. **Scroll Inventory Screen** — in Shop/Inventory, shows owned scrolls + apply UI

### 10.2 Skill Tree screen layout (detailed)

```
┌────────────────────────────────────┐
│ ◀  WARRIOR — Tree of Iron          │
│                          18/65 pts │
├────────────────────────────────────┤
│                                    │
│         [BERSERKER]                │
│            ● ── ●                  │
│           /      \                 │
│        ●          ● ── ●           │
│       / \          \    \          │
│     ●   ●            ●   [KEY]     │
│        ╲              ╲   ▲        │
│   [CRUSADER]         [EXECUTIONER] │
│         ●                ●         │
│       ╱   ╲            ╱   ╲       │
│     ●      ●         ●      ●      │
│                                    │
├────────────────────────────────────┤
│ Selected: Bloodthirst              │
│ +8% lifesteal 2 turns (Skill)      │
│ Rank 1 → Rank 2: 500 gold          │
│                                    │
│ [ALLOCATE 1 POINT]   [CANCEL]      │
└────────────────────────────────────┘
```

- **Pan/zoom** for branch exploration
- **Tap node:** show detail card at bottom
- **Long-press:** simulate (preview effect in combat log)
- **Filter toggle:** "Show only unlockable now"
- **Presets button** top-right: save/load 3 presets
- **Gem icon** top-right: quick access to scroll shop

### 10.3 Loadout screen layout

```
┌────────────────────────────────────┐
│ ◀  LOADOUT                         │
├────────────────────────────────────┤
│  Passive Tree (auto)               │
│  ╰─ 24 pts · +180 HP, +12% crit   │
│                                    │
│  Active Skills   [Edit]            │
│  ┌────┐ ┌────┐ ┌────┐              │
│  │Rage│ │Heal│ │Exec│              │
│  │CD 3│ │HP30│ │<40%│              │
│  └────┘ └────┘ └────┘              │
│                                    │
│  Ultimate        [Edit]            │
│  ┌────────────────┐                │
│  │ ⚡ FRENZY       │ auto-cast: HP<30│
│  └────────────────┘                │
│                                    │
│  Presets:  [Default] [PvP] [Dung]  │
│  [SAVE AS NEW PRESET]              │
└────────────────────────────────────┘
```

### 10.4 Combat screen changes

- Small **Ultimate Meter** indicator below HP bar (thin gold bar filling)
- When meter hits 100% and player is on device: pulsing ult button bottom-right
- Tap ult button → 2-sec reaction window, bullet-time animation, zone selection

---

## 11. Backend Data Model

### 11.1 New Prisma tables (additive — no migration conflicts)

```prisma
model SkillTreeNode {
  id              String   @id
  classKey        String   // warrior/rogue/mage/tank
  branchKey       String   // berserker/crusader/executioner/...
  tier            Int      // 1-3 + keystone/ultimate
  nodeType        String   // stat/proc/skill_unlock/skill_rank/keystone/ultimate
  effectPayload   Json     // { type: 'flat_stat', stat: 'str', value: 8 }
  requiresNodeIds String[] // graph prerequisites
  displayX        Float    // canvas x
  displayY        Float    // canvas y
}

model CharacterSkillTree {
  id             String   @id @default(cuid())
  characterId    String   @unique
  allocatedNodes String[] // array of SkillTreeNode.id
  bonusPoints    Int      @default(0) // from scrolls
  updatedAt      DateTime @updatedAt
  @@map("character_skill_tree")
}

model LoadoutPreset {
  id            String   @id @default(cuid())
  characterId   String
  slot          Int      // 0-2 (3 presets per char)
  name          String
  activeSkills  String[] // SkillId[]
  ultimateId    String?
  ultAutoRule   Json     // { type: 'hp_threshold', value: 30 }
  @@index([characterId])
  @@map("loadout_preset")
}

model ScrollInventory {
  id          String   @id @default(cuid())
  characterId String
  scrollType  String   // minor_skill/major_skill/rank_common/rank_epic/unlock_rare/unlock_epic/ultimate_legendary/mastery_mythic/respec_common/respec_master
  count       Int
  @@unique([characterId, scrollType])
  @@map("scroll_inventory")
}
```

### 11.2 New API endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/skill-tree/definition/:classKey` | GET | Returns full class tree structure (cached) |
| `/api/skill-tree/allocate` | POST | Allocate a point to a node |
| `/api/skill-tree/respec` | POST | Full/partial respec (gems charged) |
| `/api/loadout/presets` | GET | Get character's presets |
| `/api/loadout/save-preset` | POST | Save a preset |
| `/api/loadout/equip` | POST | Equip a preset |
| `/api/scrolls/inventory` | GET | Get owned scrolls |
| `/api/scrolls/use` | POST | Apply a scroll |
| `/api/scrolls/purchase` | POST | Buy from shop |
| `/api/lootbox/arcanist/open` | POST | Open an Arcanist Chest |

All require authentication, server-validated, rate-limited (10 req/sec per user).

### 11.3 Server-authoritative guarantees

- Combat resolver loads tree+loadout at fight start from DB snapshot, not client state
- Client cannot tamper with allocated nodes mid-fight
- Scroll application validates payload + cost server-side
- Loadout changes during active fight → rejected (409 Conflict)

---

## 12. Implementation Plan

### 12.1 Phases

#### **Phase 0 — Foundation** (sprint 1, 1 week)
- Finalize tree content for **Warrior only** (36 nodes + 3 ults)
- Write full skill descriptions for Warrior (12 actives × effect/scaling/cooldown)
- Agents: `hexbound-studio:bladework`, `hexbound-studio:scales`, `hexbound-studio:ascent`

#### **Phase 1 — Backend** (sprint 2, 2 weeks)
- Prisma schema + migration
- API endpoints (skill-tree, loadout, scrolls)
- Combat resolver integration (tree bonuses, ult meter)
- Unit tests for every new proc / ult
- Agents: `hexbound-studio:server`, `hexbound-studio:fortress`, `hexbound-studio:signal`

#### **Phase 2 — iOS UI (Warrior pilot)** (sprint 3, 2 weeks)
- Skill Tree screen (pan/zoom canvas, node detail, allocate UI)
- Loadout screen (pre-fight equipment)
- Scroll Inventory screen
- Ultimate Meter in Combat screen + reaction window
- Agents: `hexbound-studio:screen`, `hexbound-studio:canvas`, `hexbound-studio:flow`

#### **Phase 3 — Monetization & Lootbox** (sprint 4, 1 week)
- Arcanist Chest UI + drop logic
- BP Premium track extensions
- Adventurer's Bundle III scroll additions
- Shop UI for direct scroll purchase
- Agents: `hexbound-studio:vault`, `hexbound-studio:monetization-mirror`, `hexbound-studio:ledger`

#### **Phase 4 — Remaining 3 classes** (sprints 5–7, 3 weeks)
- Port tree design pattern to Rogue, Mage, Tank
- 36 nodes × 3 classes + 9 ultimates + 36 actives content
- Balance pass (`hexbound-studio:scales`)
- QA (`hexbound-studio:shield`, `hexbound-studio:gauntlet`)

#### **Phase 5 — Launch & Live Ops** (sprint 8, 1 week)
- Staged rollout: canary 5% → 25% → 100%
- LiveOps: first season's Mastery event
- Telemetry dashboards (`hexbound-studio:lens`)
- Agents: `hexbound-studio:gate`, `hexbound-studio:calendar`, `hexbound-studio:lens`

**Total: ~10 weeks end-to-end.** MVP (Warrior pilot) at end of Phase 3 (~6 weeks).

### 12.2 Agent assignments (per phase)

| Phase | Lead Agent | Supporting |
|---|---|---|
| 0 — Design | bladework | scales, ascent, architect |
| 1 — Backend | server | fortress, signal, oracle |
| 2 — iOS | screen | canvas, flow, guardian, mirror |
| 3 — Economy | vault | monetization-mirror, ledger |
| 4 — Content | scales | bladework, lore, ember |
| 5 — Launch | gate | calendar, lens, beacon |

### 12.3 Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Balance disaster with new actives × stance × items | High | Critical | Warrior pilot soft-launch, weekly balance telemetry, live-config kill switches |
| UI complexity overwhelms mobile | Medium | High | Auto-allocate recommendation first 5 levels, tutorial mandatory |
| Migration breaks existing 4-slot loadouts | Medium | Medium | Free respec token on first login post-release |
| Scrolls cannibalize BP sales | Low | Medium | Monetization-mirror monthly review, scroll prices tuned away from BP tier |
| Prestige scaling × tree points goes exponential | Medium | High | Hard cap 130 lifetime points + 50% DR on effects beyond tier 3 |
| Performance regression in combat resolver | Low | Medium | `hexbound-studio:tempo` benchmark suite pre-launch |

### 12.4 Success metrics

Launch KPIs (7 days post-release):
- **Tree engagement:** ≥ 80% of Lv.5+ characters have allocated ≥ 1 point (target: strong adoption)
- **Loadout swaps:** ≥ 40% of PvP fights use a non-default preset (target: real agency)
- **Ultimate usage:** ≥ 60% of online PvP fights end with at least one ult fired (target: meter paces well)
- **Respec rate:** 5–15% of players respec within week 1 (target: healthy experimentation without regret spiral)
- **Scroll revenue:** Arcanist Chests = ≥ 15% of gem revenue by week 2 (target: new surface traction)
- **Crash/error rate:** < 0.5% increase vs baseline (target: no regression)

30-day KPIs:
- **Retention D7:** +2 pp improvement for active cohort (target: tree provides meaningful retention)
- **Session length:** +10% increase among engaged users (target: loadout/tree exploration sticky)
- **PvP diversity:** Gini coefficient of loadout combinations < 0.4 (target: real build variety, not one meta)

---

## 13. Open Design Questions

Before kickoff, these need Artem's call:

1. **Cross-class trees?** Can a Warrior allocate Mage passive nodes? (recommendation: no, class-locked — preserves class fantasy)
2. **Node respec cost escalation?** Single-point refund stays 10 gems flat or scale with node tier?
3. **Preset limit — 3 or more?** Raid has 6 per character. We said 3 — bump to 5?
4. **Auto-cast rules for offline ults** — fixed list (e.g. "hp<30" / "turn5" / "always asap") or freeform if-then editor?
5. **Prestige skill point reset policy** — keep (no reset) or partial reset (reset allocation, keep total)?
6. **Launch season theme** — Season 1 Mastery event: free Mastery Scroll for top 500? Double points week?

---

## 14. Related Deliverables

This doc owns the design. Adjacent docs to be created/updated in Phase 0/1:

- [ ] `docs/06_game_systems/SKILL_TREE_SKILLS.md` — full 48-skill library (12 per class)
- [ ] `docs/06_game_systems/SKILL_TREE_NODES.md` — all 160 node specs per class
- [ ] `docs/06_game_systems/ULTIMATES.md` — 12 ultimate specs
- [ ] `docs/06_game_systems/BALANCE_CONSTANTS.md` — update with tree-related constants
- [ ] `docs/02_product_and_features/ECONOMY.md` — add Arcanist Chest + scroll section
- [ ] `docs/06_game_systems/ECONOMY_RULES.md` — add R14–R18 for scroll caps
- [ ] `docs/03_backend_and_api/API_REFERENCE.md` — add 10 new endpoints
- [ ] `docs/04_database/SCHEMA_REFERENCE.md` — add 4 new tables
- [ ] `docs/07_ui_ux/SCREEN_INVENTORY.md` — add 3 new screens
- [ ] `Hexbound/CLAUDE.md` — add skill-tree UI patterns
- [ ] `backend/CLAUDE.md` — add tree resolver patterns

---

## 15. TL;DR

A class-specific, 3-branch, ~40-node skill tree gives the player level-by-level agency, diverse builds, and a long-term prestige goal. Loadout (3 actives + 1 ultimate + passive tree) is swappable pre-fight. Skill scrolls — sourced from play + shop + new Arcanist Chest lootbox line — accelerate progression without breaking F2P access. All content additive to existing balance; no `ECONOMY_RULES.md` conflicts. Phased rollout: Warrior pilot in ~6 weeks, full system in ~10 weeks.

Waiting on Artem's answers to 6 open questions (§13) and green-light to kick off Phase 0.
