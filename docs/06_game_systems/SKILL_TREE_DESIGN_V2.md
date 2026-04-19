# Skill Tree Design — v2

Status: **ACTIVE** (2026-04-19)
Supersedes: `SKILL_TREE_DESIGN.md` (v1 draft, 2026-04-13 — archived for reference only)
Prototype: `prototypes/talents-horizontal.html`

## 0. Phase 0 Decisions (LOCKED)

| # | Decision | Value | Rationale |
|---|----------|-------|-----------|
| 1 | SP scaling | `1/level` + milestone bonus `+2 @ 10/20/30/40/50` + `+5` per prestige | Flat curve feels stale; milestones = craving loops (psyche), prestige bonus rewards long-horizon |
| 2 | Rank cost ramp | `1 → 2 → 3` SP per rank (`6` SP to max) | Ensures the `20 × 6 = 120` SP ceiling is unreachable even at L50 P5 (`84` SP) — choice stays meaningful |
| 3 | Class backgrounds | 4 unique `21:9` PNG at `2800×1200` @2x | Ember ruling: atmosphere differentiation > bandwidth; lazy-load mitigates memory |
| 4 | Phase 2 expansion | Launch with `20` nodes, `+10` per season (target `30` by S3) | Seasonal cadence per Calendar; preserves runway for build diversity |
| 5 | Weekly free respec | `1` free/week + `50` gems after | Vault rule: low friction for experimentation; gem sink for compulsive re-spec |

## 1. SP Economy

Formula (final):
```
SP_available(level, prestige) =
    (level - 1)
  + 2 × count_of(milestones ≤ level in {10, 20, 30, 40, 50})
  + 5 × prestige
```

Reference totals:

| Level | Prestige | Base | Milestones | Prestige | **Total SP** |
|-------|----------|------|------------|----------|--------------|
| 10 | 0 | 9 | 2 | 0 | **11** |
| 25 | 0 | 24 | 4 | 0 | **28** |
| 50 | 0 | 49 | 10 | 0 | **59** |
| 50 | 1 | 49 | 10 | 5 | **64** |
| 50 | 5 | 49 | 10 | 25 | **84** |
| 50 | 10 | 49 | 10 | 50 | **109** |

Budget: 20 nodes × 6 SP = **120 SP max spend**. Players at L50 P10 still can't max everything — build identity persists into endgame.

Respec: `50` gems per reset OR `1` free per ISO week (Mon 00:00 UTC reset).

## 2. Node Schema

Visible node (single row in Talents tab):
```
{
  id: string                  // "warrior.foundation.vitality"
  class: "warrior"|"rogue"|"mage"|"tank"
  tier: 1|2|3|4               // Foundation | Specialization | Keystone | Ultimate
  lane: "offense"|"balance"|"defense"|null  // null for Foundation + Ultimate
  position: { x: 0..1400, y: 0..600 }
  maxRank: 3
  rankCosts: [1, 2, 3]        // SP per rank
  ranks: [                    // 1 entry per rank, contains effect magnitudes
    { magnitude: number, description: string }
  ]
  prereqs: string[]           // node ids that must have ≥1 rank
  flavor: string              // 1–2 sentence lore line
  isKeystone?: true
  isUltimate?: true
  activeSkill?: {             // only for Ultimates — goes into Active Slot 04
    actionType: string
    cooldown: number          // seconds
    magnitude: number
  }
}
```

Rank storage (backend contract): existing `PassiveNode.cost` stores **total** SP for that node (`6`), and a new field `CharacterPassive.currentRank Int @default(0)` tracks per-character progress. Migration required — see §6.

## 3. Tree Structure (all classes share this topology)

```
                 [ULTIMATE A]  [ULTIMATE B]        ← tier 4 (2 nodes, each locked by 1 keystone)
                      │             │
        ┌─────────────┼─────────────┤
     [KEY-O]       [KEY-M]       [KEY-D]           ← tier 3 (3 keystones, one per lane)
        │             │             │
     [S-O3]        [S-M3]        [S-D3]            ← tier 2 row 3
        │             │             │
     [S-O2]─────[S-M2]──[S-M2′]─[S-D2]             ← tier 2 row 2 (cross-lane weak links allowed)
        │          │       │       │
     [S-O1]     [S-M1]  [S-M1′]  [S-D1]            ← tier 2 row 1
        │          │       │       │
     [F1]──[F2]──[F3]──[F4]──[F5]──[F6]            ← tier 1 Foundation (6 nodes, single row)
```

- **Foundation (6):** always accessible, no prereqs. Entry points.
- **Specialization (9):** 3 per lane. Row-1 needs any adjacent Foundation; row-2 needs row-1 in same lane OR weak cross-lane link; row-3 needs row-2 in same lane.
- **Keystone (3):** one per lane. Requires row-3 of same lane.
- **Ultimate (2):** each requires 1 specific Keystone. Grants an **active skill** usable in Active Slot 04 (the premium-gated slot is now also earnable via Ultimate).

Positions (all classes use the same `(x, y)` grid so the canvas layout is uniform):

| Role | x | y |
|------|---|---|
| F1..F6 | 120, 300, 480, 680, 880, 1080 | 520 |
| S-O1/M1/M1′/D1 | 220, 430, 600, 830 | 400 |
| S-O2/M2/M2′/D2 | 220, 430, 600, 830 | 290 |
| S-O3/M3/D3 | 300, 600, 800 | 180 |
| KEY-O/KEY-M/KEY-D | 300, 600, 800 | 80 |
| ULT A / ULT B | 450, 750 | 20 |

Canvas viewport `390×260` (iPhone 14 Pro logical), world `1400×600`, zoom range `0.5×–1.5×`.

## 4. Warrior — full specification

**Theme:** frontline bruiser. Lanes: **Berserker** (offense, rage/crit) · **Crusader** (balance, sustain/armor) · **Executioner** (defense inverted — actually brutal finishers; "defense" lane on grid, but theme = low-HP power).

### 4.1 Foundation (6 nodes)

| id | name | magnitudes (r1/r2/r3) | effect |
|----|------|-----------------------|--------|
| `warrior.found.vitality` | Vitality | +3% / +6% / +10% | Max HP |
| `warrior.found.iron_skin` | Iron Skin | +2 / +4 / +7 | Armor |
| `warrior.found.wards` | Wards | +2 / +4 / +7 | Magic Resist |
| `warrior.found.critical_eye` | Critical Eye | +1% / +2% / +4% | Crit chance |
| `warrior.found.swift_resolve` | Swift Resolve | +3% / +6% / +10% | Attack speed |
| `warrior.found.lifesteal` | Lifesteal | +2% / +4% / +7% | Life steal |

### 4.2 Specialization — Berserker lane (offense)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `warrior.berserk.rage` | Rage | `found.swift_resolve` OR `found.critical_eye` | +4% / +8% / +14% | Damage |
| `warrior.berserk.momentum` | Momentum | `berserk.rage` | +3% / +6% / +10% | Crit chance after kill (30s) |
| `warrior.berserk.bloodlust` | Bloodlust | `berserk.momentum` | +4% / +8% / +14% | Lifesteal below 50% HP |

### 4.3 Specialization — Crusader lane (balance)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `warrior.crus.iron_will` | Iron Will | `found.iron_skin` OR `found.wards` (weak link: `berserk.rage`) | +3% / +6% / +10% | All resists |
| `warrior.crus.retribution` | Retribution | `crus.iron_will` | +3% / +6% / +10% | Reflect melee damage |
| `warrior.crus.sanctified` | Sanctified | `crus.retribution` | +10% / +20% / +35% | Heal on block |

Parallel mirror nodes (`M′`) in this lane:

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `warrior.crus.fortitude` | Fortitude | `found.vitality` | +5% / +10% / +15% | Max HP (stacks with Vitality) |
| `warrior.crus.second_wind` | Second Wind | `crus.fortitude` | 10% / 18% / 25% | HP restored at 25% threshold (once/match) |
| `warrior.crus.aegis` | Aegis | `crus.second_wind` | 5% / 10% / 15% | Damage reduction below 30% HP |

### 4.4 Specialization — Executioner lane (defense grid / theme = finishers)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `warrior.exec.ruthless` | Ruthless | `found.lifesteal` OR `found.critical_eye` (weak link: `crus.iron_will`) | +5% / +10% / +18% | Crit damage |
| `warrior.exec.execute` | Execute | `exec.ruthless` | +10% / +20% / +35% | Damage vs. enemies < 30% HP |
| `warrior.exec.decapitate` | Decapitate | `exec.execute` | +5% / +10% / +18% | Skip enemy turn on kill |

### 4.5 Keystones (3, single rank, cost `3` SP each)

| id | name | prereq | effect |
|----|------|--------|--------|
| `warrior.key.frenzy` | Frenzy | `berserk.bloodlust` | Attacks have `15%` chance to proc an extra strike at `50%` damage |
| `warrior.key.bulwark` | Bulwark | `crus.sanctified` + `crus.aegis` (needs both lanes r3) | Reduces all damage by `10%` while HP `> 80%` |
| `warrior.key.headsman` | Headsman | `exec.decapitate` | Critical hits on enemies `< 40%` HP deal `1.8×` crit damage |

### 4.6 Ultimates (2, single rank, cost `5` SP each, grant Active Skill)

| id | name | prereq | passive | active skill (slot 04) |
|----|------|--------|---------|------------------------|
| `warrior.ult.unleash` | Unleash the Beast | `key.frenzy` | +`10%` damage taken, +`25%` damage dealt | **Rampage** — `burst_damage` magnitude `60%`, cooldown `90s` |
| `warrior.ult.champion` | Champion's Resolve | `key.bulwark` | +`20%` armor, +`20%` magic resist | **Guardian Oath** — `damage_reduction` magnitude `50%` for `4s`, cooldown `75s` |

Warrior SP totals:
- Foundation maxed: `6 × 6 = 36`
- One lane + Keystone maxed: `3 × 6 + 3 = 21`
- Two lanes maxed + 2 Keystones: `6 × 6 + 6 = 42`
- Everything maxed: `20 × 6 - 2 × 6 + 2 × 3 + 2 × 5 = 120` (impossible at L50 P5)

Realistic L50 P0 build (59 SP): maxed Foundation (36) + one lane r3 (18) + 1 Keystone (3) + partial 2 Foundation upgrades — forces clear identity.

## 5. Rogue — full specification

**Theme:** burst + attrition. Lanes: **Assassin** (offense — first strike, bleed) · **Duelist** (balance — parry, counter) · **Saboteur** (defense — poison, debilitation).

### 5.1 Foundation (6)

| id | name | r1/r2/r3 | effect |
|----|------|----------|--------|
| `rogue.found.agility` | Agility | +1% / +2% / +4% | Dodge |
| `rogue.found.precision` | Precision | +1% / +2% / +4% | Crit chance |
| `rogue.found.shadows` | Shadows | -2% / -4% / -7% | Active skill cooldowns |
| `rogue.found.venom` | Venom | +3% / +6% / +10% | Poison damage |
| `rogue.found.swiftness` | Swiftness | +3% / +6% / +10% | Attack speed |
| `rogue.found.cunning` | Cunning | +3% / +6% / +10% | Initiative (first-turn chance) |

### 5.2 Assassin lane (offense)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `rogue.asn.backstab` | Backstab | `found.precision` OR `found.cunning` | +5% / +10% / +18% | First-strike damage |
| `rogue.asn.bleed` | Bleed | `asn.backstab` | +4% / +8% / +14% | Bleed DoT chance on crit |
| `rogue.asn.deep_cut` | Deep Cut | `asn.bleed` | +4% / +8% / +14% | Crit chance vs bleeding targets |

### 5.3 Duelist lane (balance)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `rogue.duel.parry` | Parry | `found.agility` OR `found.swiftness` (weak link: `asn.backstab`) | +3% / +6% / +10% | Parry chance |
| `rogue.duel.riposte` | Riposte | `duel.parry` | +5% / +10% / +18% | Counter damage on parry |
| `rogue.duel.finesse` | Finesse | `duel.riposte` | +5% / +10% / +18% | Crit damage vs single target |

### 5.4 Saboteur lane (defense grid / theme = attrition)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `rogue.sab.toxin` | Toxin | `found.venom` OR `found.shadows` (weak link: `duel.parry`) | +5% / +10% / +18% | Poison damage |
| `rogue.sab.paralyze` | Paralyze | `sab.toxin` | +3% / +6% / +10% | Stun chance on crit |
| `rogue.sab.weaken` | Weaken | `sab.paralyze` | -5% / -10% / -18% | Enemy damage for 2 turns (debuff) |

### 5.5 Keystones (single rank, 3 SP each)

| id | name | prereq | effect |
|----|------|--------|--------|
| `rogue.key.shadowstrike` | Shadowstrike | `asn.deep_cut` | Every 5th attack deals `2×` damage |
| `rogue.key.riposte_master` | Riposte Master | `duel.finesse` | `20%` chance to counter any melee attack |
| `rogue.key.envenom` | Envenom | `sab.weaken` | Poisons apply `1s` stun on tick |

### 5.6 Ultimates (single rank, 5 SP each)

| id | name | prereq | passive | active skill (slot 04) |
|----|------|--------|---------|------------------------|
| `rogue.ult.vanish` | Vanish | `key.shadowstrike` | +`15%` damage after using stealth | **Fade** — `stealth` `4s` (next attack = auto-crit), cooldown `60s` |
| `rogue.ult.shadow_reaper` | Shadow Reaper | `key.envenom` | +`30%` damage vs poisoned targets | **Reap** — `burst_damage` `80%` if target `< 30%` HP, cooldown `75s` |

---

## 6. Mage — full specification

**Theme:** elemental control. Lanes: **Pyromancer** (offense — burn, AoE) · **Arcanist** (balance — mana, cooldowns) · **Cryomancer** (defense — slow, freeze, shields).

### 6.1 Foundation (6)

| id | name | r1/r2/r3 | effect |
|----|------|----------|--------|
| `mage.found.intellect` | Intellect | +3% / +6% / +10% | Spell power |
| `mage.found.mana_pool` | Mana Pool | +3% / +6% / +10% | Max mana |
| `mage.found.focus` | Focus | +3% / +6% / +10% | Cast speed |
| `mage.found.resonance` | Resonance | -2% / -4% / -7% | Cooldowns |
| `mage.found.arcane_armor` | Arcane Armor | +2 / +4 / +7 | Magic resist |
| `mage.found.ward` | Ward | +5% / +10% / +18% | Shield strength |

### 6.2 Pyromancer lane (offense)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `mage.pyro.kindle` | Kindle | `found.focus` OR `found.intellect` | +5% / +10% / +18% | Burn DoT damage |
| `mage.pyro.conflagration` | Conflagration | `pyro.kindle` | +5% / +10% / +18% | AoE spell damage |
| `mage.pyro.inferno` | Inferno | `pyro.conflagration` | +4% / +8% / +14% | Burn crit chance |

### 6.3 Arcanist lane (balance)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `mage.arc.focus_flow` | Focus Flow | `found.mana_pool` OR `found.resonance` (weak link: `pyro.kindle`) | +5% / +10% / +18% | Mana regen |
| `mage.arc.arcane_might` | Arcane Might | `arc.focus_flow` | +5% / +10% / +18% | Direct spell damage |
| `mage.arc.chronomancy` | Chronomancy | `arc.arcane_might` | -3% / -6% / -10% | All cooldowns (additive with Resonance) |

### 6.4 Cryomancer lane (defense)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `mage.cryo.frost` | Frost | `found.ward` OR `found.arcane_armor` (weak link: `arc.focus_flow`) | +5% / +10% / +18% | Slow magnitude |
| `mage.cryo.freeze` | Freeze | `cryo.frost` | +3% / +6% / +10% | Freeze chance on crit |
| `mage.cryo.glacial` | Glacial | `cryo.freeze` | +10% / +20% / +35% | Shield granted when enemy freezes |

### 6.5 Keystones

| id | name | prereq | effect |
|----|------|--------|--------|
| `mage.key.ignite` | Ignite | `pyro.inferno` | Burns spread to nearest enemy on target death |
| `mage.key.manaflow` | Manaflow | `arc.chronomancy` | Every 3rd spell costs `0` mana |
| `mage.key.frostbite` | Frostbite | `cryo.glacial` | Frozen targets take `+50%` damage |

### 6.6 Ultimates

| id | name | prereq | passive | active skill (slot 04) |
|----|------|--------|---------|------------------------|
| `mage.ult.meteor` | Meteor | `key.ignite` | +`15%` spell crit damage | **Cataclysm** — `aoe_damage` `70%`, cooldown `90s` |
| `mage.ult.timewarp` | Timewarp | `key.manaflow` | -`10%` all cooldowns | **Rewind** — `cooldown_reset` (all actives), cooldown `180s` |

---

## 7. Tank — full specification

**Theme:** frontline anchor. Lanes: **Protector** (offense — threat, cleave) · **Warden** (balance — shields, reflect) · **Juggernaut** (defense — HP, CC immunity).

### 7.1 Foundation (6)

| id | name | r1/r2/r3 | effect |
|----|------|----------|--------|
| `tank.found.stoneform` | Stoneform | +5% / +10% / +18% | Max HP |
| `tank.found.plate` | Plate | +3 / +6 / +10 | Armor |
| `tank.found.resilience` | Resilience | +2% / +4% / +7% | Damage reduction |
| `tank.found.rebuke` | Rebuke | +5% / +10% / +18% | Threat generation |
| `tank.found.stability` | Stability | +5% / +10% / +18% | CC resistance |
| `tank.found.vigor` | Vigor | +3% / +6% / +10% | HP regen (per turn) |

### 7.2 Protector lane (offense)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `tank.prot.cleave` | Cleave | `found.rebuke` OR `found.stability` | +5% / +10% / +18% | Cleave damage (hits 2nd enemy) |
| `tank.prot.challenge` | Challenge | `prot.cleave` | +3% / +6% / +10% | Crit chance vs highest-HP enemy |
| `tank.prot.retaliation` | Retaliation | `prot.challenge` | +5% / +10% / +18% | Damage on next attack after being hit |

### 7.3 Warden lane (balance)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `tank.ward.shield` | Shield | `found.plate` OR `found.stoneform` (weak link: `prot.cleave`) | +5% / +10% / +18% | Shield-bash damage |
| `tank.ward.reflect` | Reflect | `ward.shield` | +3% / +6% / +10% | Damage reflected to attacker |
| `tank.ward.absolution` | Absolution | `ward.reflect` | +10% / +20% / +35% | Heal when blocking |

### 7.4 Juggernaut lane (defense)

| id | name | prereq | r1/r2/r3 | effect |
|----|------|--------|----------|--------|
| `tank.jug.fortify` | Fortify | `found.resilience` OR `found.vigor` (weak link: `ward.shield`) | +3% / +6% / +10% | Damage reduction (additive) |
| `tank.jug.immovable` | Immovable | `jug.fortify` | -10% / -20% / -35% | CC duration on self |
| `tank.jug.unbreakable` | Unbreakable | `jug.immovable` | +10% / +20% / +35% | HP regen below `30%` HP |

### 7.5 Keystones

| id | name | prereq | effect |
|----|------|--------|--------|
| `tank.key.taunt` | Taunt | `prot.retaliation` | Every `10s`, AoE taunt for `2s` |
| `tank.key.aegis_wall` | Aegis Wall | `ward.absolution` | Active shield absorbs `+15%` of all incoming damage |
| `tank.key.unstoppable` | Unstoppable | `jug.unbreakable` | Immune to CC below `50%` HP |

### 7.6 Ultimates

| id | name | prereq | passive | active skill (slot 04) |
|----|------|--------|---------|------------------------|
| `tank.ult.fortress` | Fortress | `key.aegis_wall` | +`25%` max HP | **Bastion** — `damage_reduction` `70%` for `4s` + taunt `3s`, cooldown `90s` |
| `tank.ult.earthshatter` | Earthshatter | `key.taunt` | +`30%` cleave damage | **Quake** — `aoe_stun` `2s`, cooldown `120s` |

---

## 8. Active Skill Types Reference

Existing `actionType` strings (per `feedback_migration_mcp_apply_to_prod` — verify in `backend/src/lib/game/active-skills.ts` before seed):

- `burst_damage` — used by `warrior.ult.unleash`, `rogue.ult.shadow_reaper` ✓ (exists per Phase 3.B memory)
- `damage_reduction` — used by `warrior.ult.champion`, `tank.ult.fortress` ✓ (exists per Phase 3.B)
- `stealth` — used by `rogue.ult.vanish` ⚠ **new** (engineering needed)
- `aoe_damage` — used by `mage.ult.meteor` ⚠ **new**
- `cooldown_reset` — used by `mage.ult.timewarp` ⚠ **new**
- `aoe_stun` — used by `tank.ult.earthshatter` ⚠ **new**

4 new `actionType` handlers needed in the strike-resolver before Ultimates can ship. Track as a sub-issue in task #7.

## 9. Backend Contract Changes

Required Prisma schema delta (write migration, do not hand-edit):

```prisma
model CharacterPassive {
  // ...existing fields
  currentRank Int @default(0)   // NEW — 0 means unlocked but no ranks, 1..3 = rank level
  // unlock row now persists from first rank purchase
}
```

`PassiveNode.cost` semantics unchanged (stays as total-SP-to-max, `6` for standard, `3` for keystone, `5` for ultimate).

API changes:
- `POST /api/passives/unlock` — accepts `{ character_id, node_id, rank: 1|2|3 }`. Validates `currentRank + 1 === rank`. Deducts `rankCosts[rank-1]`.
- `POST /api/passives/respec` — unchanged externally; internally the `reduce` that computes refund must sum `rankCosts.slice(0, currentRank)` per row, not `node.cost` flat.
- `recalculateFullDerivedStats` — iterates `CharacterPassive` rows, looks up `ranks[currentRank-1].magnitude` instead of a binary unlock.

Live config:
- `passivesConfig.POINTS_PER_LEVEL = 1` (unchanged)
- `passivesConfig.MILESTONE_BONUSES = { 10: 2, 20: 2, 30: 2, 40: 2, 50: 2 }` (NEW)
- `prestigeConfig.SP_BONUS_PER_PRESTIGE = 5` (NEW)
- `passivesConfig.RESPEC_GEM_COST = 50` (unchanged)
- `passivesConfig.FREE_RESPEC_PER_WEEK = 1` (NEW) — stored on `Character.lastFreeRespecAt DateTime?`

## 10. iOS Integration Checklist

- [ ] `TalentsScreenView` → horizontal `ScrollView` + pinch zoom (`MagnificationGesture`)
- [ ] `TalentNodeView` — ring progress `currentRank / maxRank`, keystone glow, ultimate frame
- [ ] `TalentDetailSheet` — `.presentationDetents([.fraction(0.4), .large])`
- [ ] `TalentMinimap` — viewport-indicator overlay
- [ ] `Assets.xcassets/Talents/bg_warrior.png` (+ rogue/mage/tank) — `2800×1200` @2x
- [ ] `ActiveSlotCellView` — extend to surface Ultimate's granted active skill
- [ ] `pbxproj` — register all new files with random unique IDs (per `feedback_pbxproj_unique_ids.md`)

## 11. QA Gates (before `talents_v2_enabled` flag flips to 100%)

- `ledger`: simulate L50 P0 → verify no legal build exceeds `59` SP spend
- `scales`: 4 classes × 3 canonical builds — no dominant strategy (> `55%` win rate)
- `gauntlet`: 50-match playtest for each class
- `shield`: respec regression — `CharacterActiveSlot` rows cleared, derived stats recomputed
- `gate`: soft-launch `10%` cohort for 48h → monitor crash rate + respec gem sink velocity

## 12. References

- Prototype: `prototypes/talents-horizontal.html`
- Existing backend schema: `backend/prisma/schema.prisma` (models `PassiveNode`, `PassiveConnection`, `CharacterPassive`, `CharacterActiveSlot`)
- Progression: `backend/src/lib/game/progression.ts`
- Respec: `backend/src/app/api/passives/respec/route.ts`
- iOS canvas seed: `Hexbound/Hexbound/Views/Hero/Talents/TalentTreeCanvas.swift`
- v1 draft (superseded): `docs/06_game_systems/SKILL_TREE_DESIGN.md`
- Balance source of truth: `docs/06_game_systems/BALANCE_CONSTANTS.md`
