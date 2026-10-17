# Hexbound — Full Balance Audit (2026-10-16)

Scope: combat formulas (both engines), gear/passives/dice, PvE scaling, XP and gold curves, gems, PvP ladder. Sources: `backend/src/lib/game/*`, `prisma/seed-*`, `docs/06_game_systems/*`, `tests/`. Numbers below were produced by running the repo's own code (`runCombat`, `dice.ts`, `sim:economy`, `find-tutorial-seed`) — not estimated from docs.

**Fixed in `bcf6048`** (7 defects, see §8).

**Applied 2026-10-17** (six commits, all tests green — 617 passed):
- `b92f5a3` PvE: `calcBossHp` 120 → 70, multiplier cap 1.5, hard = HP ×1.2 / stats ×1.4, `levelReq` 55/60/65 → 42/46/50, hardcoded + iOS tables on the same curve. **Prod migration `20261017_boss_hp_curve` NOT applied yet** (80 bosses by name) — apply before deploying.
- `834b65c` Gems: daily bonus 10 → 3, large potion 500 → 2,000 and cap 4 → 2/day, gem packs 500 / 3,000 / 7,500. Catalog migration `20261017_gem_economy_prices` (display only; the shop charges from code).
- `cbbb33f` Dice: `diceHitProfile` is now the expected classic strike — crit (LUK/AGI + passives), dodge, CHA miss all count in live PvP; tank class reduction + passive DR share one cap (`DICE_DAMAGE_REDUCTION_CAP` 35); rogue Cunning → +3%/rank life steal. Migration `20261017_rogue_cunning_lifesteal`.
- `341415c` Runes: 13 parameters retuned and re-measured on the live engine; greats +5–10 pp, paths +3–9, lessers +2–5. Text in `runes.ts` and `DICE_RUNES_DESIGN.md §10` updated.
- `f40e68a` Items: validator and generator share `generatorBaseValue`; brackets 1.2·L .. 2.8·L.
- `2fbe5ba` Docs: PROGRESSION / ECONOMY_RULES / SKILL_TREE_V2 say what the code does; BALANCE_CONSTANTS_AUTO regenerated.

Still open (decisions): `item-sets.ts` wire-or-delete; defender-share daily cap and per-account daily faucets (routes); `cooldownReduction` has no dice analogue; Evasion rune wants a mechanic, not a number; 49 vs 59 SP; sink-ratio test floors + simulator coverage.

---

## 1. Headline

| # | Finding | Severity | Status |
|---|---|---|---|
| 1 | **Gear is the win button.** 12 slots × linear `2·L·rarity` budget: at equal level, one rarity tier up ≈ >95% win; L50 legendary+10 kills 6.5× faster than L50 common. Level itself is 3 stat points/level (147 total) — ~10× less than gear. | High | proposal §3 |
| 2 | **Late PvE is unkillable, not hard.** On the real engine, seeded bosses at L35+ time out at turn 15 for every tested loadout (L50 mid-gear: 10% "wins", 100% timeouts; BiS: 93% wins, still 100% timeouts). Outcome is the HP% tiebreak, not a kill. | High | proposal §5 (validated) |
| 3 | **Three dungeons are unreachable**: `levelReq` 55/60/65 > `MAX_LEVEL` 50 — 30 bosses nobody can see. | High | proposal §5 (needs a migration) |
| 4 | **36 of a rogue's 109 passive SP do nothing in live PvP.** Dice combat snapshots `diceHitProfile`, which reads only flat/percent damage, DR and lifesteal; `flat_crit_chance`, `flat_dodge_chance`, `cooldown_reduction` are ignored. Mage loses 32 SP the same way. | High | proposal §2 |
| 5 | **Tank tree stacks to ~×7.3 EHP·dmg** vs ×3.3 rogue: 50% DR (11 SP) × class 0.85 × 50% lifesteal, all multiplicative. | Med | proposal §2 |
| 6 | **Free gems ≈ 2,000–4,000/month** vs the R9.2 target of 250–320. Daily-quest bonus alone is 300/mo; gold→gem packs add up to 100/day. | High | proposal §6 |
| 7 | **Stamina potions undercut the gem refill 5–10×**: a 500-gold large potion = 180 stamina ≈ 4,800 gold of fights at L40; the same refill costs 50–240 gems. | High | proposal §6 |
| 8 | **Referral farm** — `maxReferrals` never enforced. | High | **fixed** |
| 9 | **Rune EV spread 2–4× the design targets**: Meteor +14.7 pp win-rate (target +6–10), Dagger (1 SP, "lesser") +8.6 (target +2–4). Warrior kit weakest (43–45% vs every other class at full runes). | Med | proposal §4 |
| 10 | **Sink-ratio test floors were lowered to 48/45/50** (R4 says 50/60/65) and the simulator omits the gold mine, daily bonus, potions, gem packs and defender share — its 63.5% is optimistic; a fuller model lands at ~45–60%. | Med | proposal §6 |
| 11 | `item-sets.ts` (set bonuses, boss-exclusive drops) is imported by nothing — a whole feature is dead code. | Med | decision needed |
| 12 | 19 doc/code drifts in ECONOMY_RULES / PROGRESSION / SKILL_TREE_DESIGN_V2 (§7). | Low | regenerate |

---

## 2. Combat formulas and class parity

### Classic engine (`combat.ts`, used by dungeons, revenge, social challenges, `/pvp/resolve`)

- Damage: warrior `str×1.5 + 2L`; tank `str×1.3 + vit×0.3 + 2L`; rogue `agi×1.5 + 2L`; mage `int×1.4 + wis×0.25 + 2L` (`combat.ts:208-230`, DB-tunable).
- Mitigation `100/(100+resist)` floored at `1 − MAX_RESIST_REDUCTION` = 0.4 (`combat.ts:325`), tank ×0.85 (`:346`), passive DR capped 50 (`:439`). Crit `0.6·LUK + 0.2·AGI` ≤ 50, dodge `0.2·AGI + 0.1·LUK (+4 rogue)` ≤ 30, CHA miss `0.2/pt` ≤ 20.
- Fatigue +10%/turn after 10; `MAX_TURNS 15`; timeout → HP% compare.
- Verified sane: no div-by-zero, all caps present, mirror TTK pinned by `combat-ttk.test.ts`.

### Dice engine (`dice.ts`, **the live PvP mode since 2026-10-14**)

`diceHitProfile` (`combat.ts:424-441`) snapshots one plain strike and the dice decide crit/dodge. Consequence: every passive node that grants `flatCritChance`, `flatDodgeChance` or `cooldownReduction` is silent in PvP.

| class | %dmg at full tree | DR | lifesteal | %HP | SP void in dice |
|---|---|---|---|---|---|
| warrior | 113 | 34 | 48 | 54 | 18 / 127 |
| rogue | 179 | 25 | 0 | 0 | **36 / 109** |
| mage | 148 | 45 | 0 | 9 | 32 / 109 |
| tank | 105 | **99 (cap 50)** | 69 (cap 50) | 40 | 6 / 109 |

Greedy best-49-SP build, dmg × EHP vs scattered: tank ×7.3, warrior ×4.5, mage ×4.3, rogue ×3.3. Rank cost 1/2/3 with linear magnitude makes rank 1 always the best SP spend (breadth beats depth). Unleash's stated "+10% damage taken" drawback is not implemented (free +25%).

**Proposals**
- [BUG-DESIGN] `combat.ts:424` fold crit/dodge into the dice profile: `hit × (1 + flatCritChance/100 × (HEAD_MULT−1))` and `missChance += flatDodgeChance/100 × 0.5` — or reseed the 11 affected nodes as %dmg/DR. Pick one before the next passive-tree pass; today those nodes are a trap for anyone who reads the tooltip.
- [TUNE] `combat.ts:436` passive DR cap 50 → 35 **and** include the tank class 0.85 inside the cap (`min(DR + 15, 35)`), or halve `passives-tank-v2.sql` DR nodes (immovable 10 → 5, aegis_wall/unstoppable 15 → 8).
- [TUNE] `passives-rogue-v2.sql`: one sustain node (Cunning → lifesteal 3/rank). Rogue is the only class with zero sustain and zero %HP.
- [DOC] `SKILL_TREE_DESIGN_V2.md §1` says 59 SP at L50; code gives 49 (`progression.ts:184`, `balance.ts:712`). Decide which.

## 3. Gear budget

Generator (`item-balance.ts:327`): primary stat = `2·L·rarityMult` (1 / 1.3 / 1.6 / 2.0 / 2.5), +1 flat per upgrade level per stat (`item-stats.ts:76`), rolls +0–25%. Validator (`item-balance.ts:109-115`) uses bracket midpoints (L36–50 = 51.5), so it flags the generator's own L46–50 output as "overpowered" and gives Tier-6 items no growth. Two models, one file, ~2× apart.

| L | common +0 → +10 | legendary +0 → +10 |
|---|---|---|
| 1 | 32 → 272 (×8.5) | 85 → 325 (×3.8) |
| 10 | 316 → 556 (×1.76) | 790 → 1,030 (×1.30) |
| 20 | 632 → 872 | 1,580 → 1,820 |
| 40 | 1,264 → 1,504 | 3,160 → 3,400 |
| 50 | 1,580 → 1,820 (×1.15) | 3,950 → 4,190 (×1.06) |

- L20 full legendary beats L40 full common (hit 202 vs 183; kills in 10.3 vs 15.9 rounds).
- +10 is ×8.5 at L1 and ×1.06 at L50 — upgrades matter only where gold is scarcest.
- `item-sets.ts` is never imported. Set bonuses, `rollBossExclusiveDrop`, Wanderer's Charm, rush-miniboss drops: all unreachable.
- Tier-6 items (L41–50) appear in no `seed-dungeon-drops.ts` table.

**Proposals**
- [BUG] `item-balance.ts:109-115` replace brackets with `minStat = 1.2·L, maxStat = 2.8·L` so validator == generator.
- [TUNE] `item-stats.ts:76` upgrade bonus `+1` flat → `ceil(base × 0.03)` per level: +10 = ×1.3 at every level.
- [DECISION] wire or delete `item-sets.ts`.
- [TUNE] `PRESTIGE.STAT_POINTS_PER_LEVEL` 3 → 5 if level should be felt against gear at all.

## 4. Dice and runes

Measured on `dice.ts` (4,000 seeded mirror duels per cell, smart AI both sides). Bare mirror 50.6%, 6.5 rounds. Single rune on best face, win-rate delta vs bare (design targets: lesser +2–4, path +4–7, great +6–10):

Meteor **+14.7**, Reaper +12.8, Shadowstrike (path) **+11.7**, Beast +10.6, Vanish +10.2, Bastion +9.7, Frenzy +9.3, **Dagger (lesser, 1 SP) +8.6**, Flow +8.6 … Evasion +1.8, Mail +2.5, Unbreakable +2.9.

Full 6-rune vs bare: mage 80%, tank 78%, rogue 76%, warrior 73% (doc target ≤ 75%). Best-vs-best cross-class: warrior loses to all three (43–45%); the others ≈ 50%. Bots (`dice-loadout.ts:91`, full Great at L25) beat a bare player 72–79%.

Missing caps: DoT stacking (bleed+poison+burn) unlimited; Riposte 140% counter scales with fatigue.

**Fixed:** blocked Dagger ignored Mail/Barrier/Stone/Unbreakable `take` (`dice.ts:307`) — blocking a Dagger was worse than not blocking.

**Proposals** — `RUNE_PARAMS`: meteor.mult 1.4 → 1.2; reaper.mult 1.75 → 1.5; shadowstrike.mult 1.6 → 1.3; beast.mult 1.8 → 1.5; vanish.missChance 0.45 → 0.35; dagger.pierce 0.8 → 0.5; evasion.focus 2 → 3; mail.take 0.65 → 0.55 (lifts the warrior kit). Cap DoT stacks at 3. Timeout tie `>=` (`dice.ts:625`) always hands ties to the initiator — acceptable as a rule, but say so in the design doc.

## 5. PvE — measured time-to-kill (real `runCombat`, 60 seeded fights per cell)

Hero = warrior, "mid" gear = the audit's gear model (the L25/L50 rows in `combat-ttk.test.ts`). Boss built exactly as `dungeon.ts` / `seed-dungeons.ts` build it, mapped as `dungeons/fight/route.ts` maps it.

| boss (as seeded) | vs L25 mid | vs L40 mid | vs L50 mid | vs L50 BiS |
|---|---|---|---|---|
| Overgrowth L17 ×1.35 (lvlReq 30) | 100% / 12% timeout | 100% / 0% | 100% / 0% | 100% / 0% |
| Pyrax L22 ×1.45 (lvlReq 35) normal | 58% / **100%** | 100% / 17% | 100% / 3% | 100% / 0% |
| Pyrax hard (×1.4) | 0% / 55% | 70% / **100%** | 98% / 85% | 100% / 12% |
| Frost L27 ×1.55 (lvlReq 40) | 0% / 60% | 90% / **98%** | 98% / 55% | 100% / 7% |
| L35 ×1.8 (lvlReq 50 dungeon) | 0% / 7% | 0% / 90% | **10% / 100%** | 93% / **100%** |
| Malachar L45 ×2.1 (lvlReq 65) | 0% | 0% / 15% | 0% / 52% | 10% / 100% |

Read: "win% / timeout%". A win with a high timeout share is not a kill — it is the turn-15 HP% comparison going the hero's way. From `levelReq 40` on, a level-appropriate mid-gear hero never kills the boss.

**Same matrix with `calcBossHp` 120·L·mult → 70·L·mult** (everything else unchanged):

| boss | vs L25 mid | vs L40 mid | vs L50 mid | vs L50 BiS |
|---|---|---|---|---|
| Pyrax normal | 97% / 10% | 100% / 0%, 8.1 rounds | 100% / 0% | 100% / 0% |
| Pyrax hard | 8% / 55% | 98% / 22% | 100% / 5% | 100% / 2% |
| Frost | 18% / 60% | 98% / 8%, 12 rounds | 100% / 2% | 100% / 0% |
| L35 ×1.8 | 0% | 23% / 90% | 75% / 83% | 100% / 17% |
| Malachar | 0% | 0% | 0% / 52% | 72% / 95% |

70 fixes the L30–40 band outright (level-appropriate hero wins by a kill in 8–12 rounds, hard mode is a real step up). The L50 dungeon still needs the multiplier capped: ×1.8 and ×2.1 compound on HP, damage **and** defense.

Other PvE findings:
- `seed-dungeons.ts:367/390/413` `levelReq` 55/60/65 > `PRESTIGE.MAX_LEVEL` 50 — 3 dungeons, 30 bosses, unreachable. Fixing the seed is not enough; prod rows need `UPDATE dungeons SET level_req = … WHERE slug IN (…)`.
- `dungeon.ts:146-151` variety rooms sit on floors 3/5/7/9 and skip boss indices 2/4/6/8, so `BOSS_ABILITIES[*][4]` etc. never spawn; `BOSS_ABILITIES` has zero callers anyway.
- `dungeon.ts:339` DB bosses get `level × diffMult` (L30 → L42 on hard); the hardcoded path (`:220`) does not scale level. One of the two is wrong.
- Dungeon Rush (`dungeon-rush.ts:155`) ignores player level: room-5 miniboss (1,020 HP) is unkillable below ~L12 and free at L50, where it pays 1,700–2,500 gold + two 75% loot rolls at gear-capped item level — the best gold/stamina in the game.
- Straw Dummy (forced passive, 120 HP) is a zero-risk clear whose gold and BP-XP sit outside `TRAINING_XP_DR`.

**Proposals**
- [TUNE, validated] `seed-dungeons.ts:229` `calcBossHp` 120 → 70; cap `statMultiplier` at 1.5; `dungeon.ts:64` hard: HP ×1.2, damage ×1.4 (not ×1.4 on everything).
- [BUG] `levelReq` 55/60/65 → 42/46/50 + migration.
- [TUNE] `dungeon-rush.ts:155` `effectiveLevel = max((room+1)·1.5, playerLevel·0.8)`; drop the ×1.5 Goldweave on rush gold.
- [BUG] pick one boss-level scaling rule; key `BOSS_ABILITIES` by boss name or move variety rooms off ability floors.

## 6. Economy

### XP (`balance.ts:152-175`)
`xpToNext(L) = (120 + 40L) × 3`; linear, no dead zones (max consecutive ratio 1.25). 164,640 XP to L50 ≈ 741 PvP fights ≈ 33 days on free stamina. Prestige resets `level` to 1 while `levelScaledReward` uses raw level and repair uses `effectiveGearLevel` — income drops to ⅓, L50 repair bills stay.

### Gold — sources (per fight, `balance.ts:178-190, 650`)
| L | PvP win / loss | peak legal stack (first win × streak × CHA × premium × event) |
|---|---|---|
| 1 | 150 / 50 | ~1,800 |
| 20 | 264 / 88 | ~3,100 |
| 40 | 384 / 128 | ~4,600 |
| 50 | 444 / 148 | **~7,900** |

Plus: defender 34% of base per incoming attack (no stamina, no daily cap), gold mine ~100/cart, daily-quest bonus 500 + 10💎, login 950/wk, milestones 47,500 lifetime.

### Gold — sinks
Repair (L50 legendary 5,600/item), upgrade +1..+10 Σ 17,623 (E ≈ 46k with +9/+10 downgrades), respec 5,000, skills 500+500·rank, inventory 5,000×3, potions flat 100/250/500, gem packs 500/1,750/3,000 (1/day).

### Sink ratio
`sim:economy`: casual 68.0%, active 68.5%, whale 61.6%, overall 63.5%. The simulator does **not** model: gold mine, daily bonus, defender share, milestones, large potions, gem packs, events, premium, level progression, downgrade-on-fail, real repair frequency. Re-estimated with those: casual ≈ 56%, active ≈ 42%, whale ≈ 47% (≈ 57/62 if the daily gem-pack buy counts as a sink). `tests/economy/sink-ratio.test.ts:50-60` floors were lowered to 48/45/50 against ECONOMY_RULES R4's 50/60/65 — the test passes because the bar moved.

### Gems
Free: daily 3/3 bonus **10/day**, login day-7 25, milestones 705 lifetime, achievements 98, mine ~1.6/cart (+1 per ≥75% minigame, +2 per expedition) ≈ 14–29/day, guild 30–60/wk, referral 10/invitee, premium 25/day, gem card 50/day. **Total F2P ≈ 2,000–4,000/month vs target 250–320 (R9.2).**
Gold→gem loop: 1,750 gold → 50 gems → 50-gem refill → 180 stamina → ~4,800 gold at L40. Bounded by the 1/day cap but 10× the designed floor.

### Exploits / loopholes
1. Large stamina potion 500 gold = full bar (`consumable-pricing.ts:23`, cap 4/day) — gold → potion → gold ≈ ×5–10.
2. ~~Referral farm~~ **fixed**.
3. Per-character faucets into an account wallet (5 chars): daily-quest bonus, tutorial 500 + 150 + 1,300 gold, mine sessions — all per `characterId` (`daily-quests.ts:41`, `tutorial.ts:20-26`). Milestones already fixed this for themselves (`milestones.ts:199`).
4. Defender share with no cap (`balance.ts:189`): bot accounts attacking a main and losing mint ~130 gold/attack at L40.
5. `gold-mine-expedition.ts:78` honours a stored legacy `shaftTotal` over the constant (chest 1.67× faster). *Left alone — the gold mine is mid-rewrite in the other session.*
6. Stat points for gems (`balance.ts:737`) and the 100-gem 4th active slot sell combat power — against R17.

**Proposals**
- [TUNE] `stamina_potion_large` 500 → 2,000 gold; `STAMINA_POTION_DR.DAILY_CAP` 4 → 2, or restore 60 not 180.
- [TUNE] `DAILY_BONUS_REWARD.gems` 10 → 3; `MINIGAME_GEM_CAP` 1 → gem only on a perfect run.
- [TUNE] `GEM_PACKS` → 10/500, 50/3,000, 100/7,500 (≥ 60 gold/gem) or small-only.
- [BUG] cap defender share at 5 paid defenses/day; skip when attacker < L5.
- [BUG] make daily-quest bonus and tutorial faucets per account (route).
- [TUNE] `levelScaledReward` on `effectiveGearLevel` for prestiged characters.
- [TUNE] delete `EXTRA_PVP_COMBAT` (50 gems / 5 stamina) and the `STAT_PURCHASE` gem ladder, or price them in gold.
- [TEST] restore sink floors to 50/60/65 and extend the simulator with mine, daily bonus, potions, gem packs before quoting its number again.
- [DESIGN] gem-pack seed prices in `prisma/seed-consumable-items.ts:51-53` (150/750/1,500) disagree with `GEM_PACKS` — which table does the shop read?

## 7. PvP ladder

ELO standard (`elo.ts`): K 48 for 10 calibration games, then 32; floor 0. Ladder 8 tiers × 750, Master 3,750, GM 4,250, start 1,000 (Silver II). With K 32 and equal opponents a 55% player nets +1.6/game: Diamond (3,000) ≈ 1,250 games ≈ 60 days of free stamina; a 70% player ≈ 15 days. Grandmaster is effectively bot-farmed or unreachable. April audit #4 ("ladder gaps") still open. Not touched here: how bot fights move rating.

Bots mirror the player ×0.65/0.80/0.90 (`npc-bots.ts:30`) but the opponent card shows a fake 10-base stat block (`:96-116`) — card ≠ fight.

## 8. Fixed in `bcf6048`

| file | defect |
|---|---|
| `tutorial.ts:293` | `maxReferrals` never checked — unlimited 500 gold + 10 gems per fresh account |
| `tutorial-opponents.ts:107` | `0xDEADBEEF` DO-NOT-SHIP seed → 26 (all classes win in 5 turns) |
| `dice.ts:307` | blocked Dagger skipped the guard rune's `take` — blocking was worse than not blocking |
| `daily-login.ts:72` | `rewards[(0−1) % 7]` = undefined |
| `item-balance.ts:415` | `chances[-1]` → NaN roll |
| `live-config.ts:408` | streak fallbacks still carried the pre-cap ×2 table |
| `gem-packs.ts:32` | medium pack cheaper per gem than large (24 < 30) → 1,750 (35/gem) |

Tests: `vitest tests/lib` 401 passed; new `referral cap` test.

## 9. Doc / code drift (regenerate or decide)

| constant | doc | code |
|---|---|---|
| XP to L50 | 55,000 (PROGRESSION) | 164,640 (`XP_CURVE_SCALE 3`) |
| PvP XP | 120/40 | 150/50 level-scaled |
| Login gold / day-7 gems | 200/500/1000, 5 | 150/300/500, 25 |
| Login claim window | 24 h | 20 h |
| BP premium / season | 500 gems, 8 wk | 700 gems, 90 d |
| Upgrade cost | 150×1.4^N (R7.2) | 150×N^1.4 |
| Consumable prices | level-scaled (R7.4) | flat 100/250/500 |
| Sell price | flat 10..400 (R14.3) | base × itemLevel (L50 legendary 20,000) |
| Mine boost | 10 gems, skip wait (R13) | 15 gems, ×2 haul |
| Premium pass | $9.99, +20💎/d (R11) | $4.99, 300/renewal, +25/d |
| SP at L50 | 59 (SKILL_TREE_V2 §1) | 49 |
| Rune EV tables | §3 | stale; §10 matches `RUNE_PARAMS` |
| First refill 15💎, BP skips, Warlord's Chest, Sovereign | specified | absent |

## 10. Suggested order

1. PvE: `calcBossHp` 120 → 70 + multiplier cap 1.5 + `levelReq` migration (one afternoon, validated above).
2. Dice profile: decide crit/dodge mapping; then the `RUNE_PARAMS` retune in one pass with the mirror harness.
3. Gems: daily bonus 10 → 3, potion 500 → 2,000, gem-pack ladder — then re-run `sim:economy` with the missing faucets added and restore the R4 floors.
4. Tank DR cap + rogue sustain node.
5. Decide `item-sets.ts`; align validator and generator.
6. Regenerate the three stale docs from code.

*Note for the next session: `git stash` on the mounted repo SIGBUSed mid-`pop` and truncated a file to 0 bytes; recovered from `stash@{0}` (kept). Do not stash on this mount — use index juggling or a worktree.*
