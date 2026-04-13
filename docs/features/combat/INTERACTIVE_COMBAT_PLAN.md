# Interactive Combat — Full Feature Plan

**Status:** planning — **REVISED 2026-04-13 (v2)** after balance/economy review.
**Created:** 2026-04-13
**Owner:** Artem
**Scope:** Phase 1 (active talent slots) + Phase 2 (per-strike stance choice) — shipped together

> **v2 revision headline:** the v1 "Attack / Defend / Counter" RPS model has been **replaced** with an interactive version of the existing **head / chest / legs zone stance system** (already in `combat.ts`). RPS was inventing a parallel layer that contradicted the shipped combat pipeline and `SKILL_TREE_DESIGN.md`. See **§13 Balance & Economy Alignment** for the full rationale.

---

## 1. Vision

Battles become tactical: the player
1. **Earmarks 3 active talents** in the passive tree (tree UI gains an "Equip as Active" slot mechanic).
2. **Picks a stance** (Attack / Defend / Counter, RPS) before every strike during battle.
3. Sees the opponent's stance revealed simultaneously; RPS resolves damage multiplier; active talents trigger via cooldown and slot buttons.

Async-PvP stays async — opponent is a snapshot. The server resolves each strike, the opponent's stance is chosen by a deterministic AI from the snapshot (seed = battle_id + strike_index, so replays are stable).

---

## 2. Data Model

### 2.1 New enums

```prisma
enum CombatStance {
  attack
  defend
  counter
}

enum TalentSlotAction {
  // Non-exhaustive starter set; each active-eligible node maps to one
  burst_damage       // +X% damage on next strike
  heal_self          // restore Y% max HP
  shield_self        // absorb Z damage next strike
  stun_enemy         // enemy skips next strike
  execute            // +big damage if enemy HP < threshold
}
```

### 2.2 `PassiveNode` additions

```prisma
model PassiveNode {
  // ... existing fields
  activeActionType   TalentSlotAction?   @map("active_action_type")
  activeCooldown     Int?                @map("active_cooldown")        // strikes between uses
  activeMagnitude    Float?              @map("active_magnitude")       // coefficient (e.g. 0.5 = +50%)
  isActivatable      Boolean             @default(false) @map("is_activatable")
}
```

Not every node is activatable. Seed decision: all tier-5 ultimates + one tier-3 keystone per branch = **8 activatable nodes in MVP**. Expand later.

### 2.3 `CharacterActiveSlots` (new table)

```prisma
model CharacterActiveSlot {
  id           String       @id @default(uuid())
  characterId  String       @map("character_id")
  nodeId       String       @map("node_id")
  slotIndex    Int          @map("slot_index") // 0, 1, 2

  character    Character    @relation(fields: [characterId], references: [id])
  node         PassiveNode  @relation(fields: [nodeId], references: [id])

  @@unique([characterId, slotIndex])
  @@unique([characterId, nodeId])   // a node can't occupy two slots
  @@map("character_active_slots")
}
```

Constraint: the node must be both unlocked (`CharacterPassive` row exists) AND `isActivatable = true`. Server-enforced.

### 2.4 `CombatSession` (new table — per-strike state)

```prisma
model CombatSession {
  id                   String       @id @default(uuid())
  battleId             String       @unique @map("battle_id")
  attackerId           String       @map("attacker_id")
  defenderId           String       @map("defender_id")
  strikeIndex          Int          @default(0) @map("strike_index")
  attackerHp           Int          @map("attacker_hp")
  defenderHp           Int          @map("defender_hp")
  slot0Cooldown        Int          @default(0) @map("slot0_cooldown")
  slot1Cooldown        Int          @default(0) @map("slot1_cooldown")
  slot2Cooldown        Int          @default(0) @map("slot2_cooldown")
  // ... opponent slot cooldowns too
  rngSeed              String       @map("rng_seed")
  status               String       // "active" | "finished" | "expired"
  resultJson           Json?        @map("result_json")  // full replay once finished
  createdAt            DateTime     @default(now())
  updatedAt            DateTime     @updatedAt
  @@map("combat_sessions")
}
```

Session lives ~60s (TTL sweep). If player ragequits, session resumes on next open; if stale > 60s, forfeit = defender wins.

---

## 3. RPS Rules (Stances)

| Attacker \ Defender | Attack        | Defend           | Counter          |
|---|---|---|---|
| **Attack**  | normal damage  | –50% damage       | attacker takes 50% of own damage back |
| **Defend**  | –50% damage    | stalemate, no damage | small chip damage |
| **Counter** | +50% damage   | small chip damage | stalemate         |

Notes:
- **Counter vs Attack** = the signature PvP moment. Announce it hard (VFX + haptic).
- Crit/dodge/armor still apply on top of the RPS multiplier.
- Active talents trigger **before** RPS resolution and can change the stance's multiplier (e.g. `execute` converts defensive stances to attacker's favor).

---

## 4. Backend (TypeScript / Prisma)

### 4.1 New endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/passives/active-slots` | Set slot: `{ slotIndex, nodeId }`. Validates unlock + activatable. |
| `DELETE` | `/api/passives/active-slots/:slotIndex` | Clear slot. |
| `GET` | `/api/passives/active-slots?characterId=…` | Return all 3 slots for UI. |
| `POST` | `/api/pvp/combat/start` | Replaces current `/pvp/fight`. Creates `CombatSession`, returns `session_id`, `strike_total`, initial state. |
| `POST` | `/api/pvp/combat/strike` | Body: `{ sessionId, stance, activeSlotIndex? }`. Server resolves one strike, decrements cooldowns, returns `{ heroStance, enemyStance, damageDealt, damageTaken, activeUsed, newHp, nextStrikeIndex, isFinished, finalResult? }`. |
| `POST` | `/api/pvp/combat/forfeit` | Player leaves mid-fight → session marked finished = loss. |

### 4.2 Strike resolution (server)

Pseudocode in `backend/src/lib/game/combat-interactive.ts`:

```ts
async function resolveStrike(sessionId: string, heroStance: Stance, activeSlot?: 0|1|2) {
  const session = await loadSession(sessionId);
  const enemyStance = deriveEnemyStance(session.rngSeed, session.strikeIndex);

  // 1. Active talent (if any + cooldown OK)
  const activeEffect = activeSlot !== undefined
    ? applyActiveTalent(session, activeSlot)
    : null;

  // 2. RPS multiplier
  const rpsMult = resolveRPS(heroStance, enemyStance);

  // 3. Standard combat math (crit / dodge / armor) with stance mods
  const strike = computeStrike(session, rpsMult, activeEffect);

  // 4. Commit: update HP, cooldowns, advance strike index
  session.attackerHp -= strike.damageTaken;
  session.defenderHp -= strike.damageDealt;
  session.strikeIndex += 1;
  decrementCooldowns(session);
  await saveSession(session);

  // 5. Finish check
  if (session.attackerHp <= 0 || session.defenderHp <= 0 || session.strikeIndex >= MAX_STRIKES) {
    return finalizeCombat(session);
  }
  return strike;
}
```

### 4.3 Enemy AI stance selection

```ts
function deriveEnemyStance(seed: string, strikeIndex: number): Stance {
  const h = hash(seed + ':' + strikeIndex);
  const roll = h % 100;
  // Snapshot personality (from opponent's build): aggressive vs defensive
  // but deterministic per seed for replay.
  if (roll < 40) return 'attack';
  if (roll < 70) return 'defend';
  return 'counter';
}
```

Deterministic → replay works. Personality weights come from the opponent's class/build (warrior leans attack, tank leans defend, etc.).

### 4.4 Server-authoritative invariants

- Client never sees the enemy stance until the strike response returns.
- Client cannot submit two strikes at the same `strikeIndex` (idempotency key).
- Active talent use validated against session cooldown table.
- Session expires after 60s of inactivity → forfeit.

---

## 5. iOS Client

### 5.1 Passive Tree — "Equip as Active"

- `TalentNodeView` adds a new state: **equipped-as-active** (visual: gold glow ring + number badge 1/2/3).
- Node detail sheet adds a "Equip as Active" button for activatable unlocked nodes.
- New screen `ActiveSlotsBarView` appears at top of tree: 3 slots, tap → opens node picker filtered to activatable unlocked nodes.
- ViewModel: `PassiveTreeViewModel.equipActive(nodeId, slotIndex)` → calls `POST /passives/active-slots`.

Reuses existing DS components: `ItemCardView` slot rendering, `TalentNodeView` glow ring, existing modals.

### 5.2 Combat Screen — Stance Picker

- New component `StanceSelectorView` at bottom of `CombatDetailView`.
- 3 buttons: Attack / Defend / Counter — use `ButtonStyles.combat` variants.
- Selection → disable buttons, send `POST /pvp/combat/strike`, play animation on response.
- Stance reveal: hero stance flies up, opponent stance flips in, RPS resolution icon (crossed swords / shield / counter-swirl) pulses, then damage numbers.
- Active talent slots: 3 icons above stance row, tap before picking stance. Icon shows cooldown overlay.

### 5.3 Visual feedback per outcome

| Outcome | VFX |
|---|---|
| Attack beats Defend | Shield crack, reduced damage number (yellow) |
| Attack beats Attack | Clash, both numbers (normal) |
| Defend beats Counter | Shield pulse, chip damage |
| Counter beats Attack | Gold flash + "COUNTER!" banner + full damage |
| Stalemate | Gray 0 + small particle |

Reuses existing `CombatVFXOverlay` + a few new assets (stance icons, counter banner).

### 5.4 State flow

```
BattleVM.startCombat()
  → POST /pvp/combat/start → session_id
  → enter stance phase
  → user taps stance (+ optional active)
  → POST /pvp/combat/strike
  → animate (hero stance, enemy stance, damage, HP update)
  → if not finished → back to stance phase
  → else → transition to BattleResultCardView (already built)
```

### 5.5 Optimistic UI (per project rule)

Stance tap → button highlight + haptic fires **immediately**. Network call starts in background. If response arrives before animation window ends → seamless. If late → show "…" spinner briefly, NEVER block user.

---

## 6. Design System (Figma + Swift)

### New components (both places)

| Component | Variants | Swift file | Figma page |
|---|---|---|---|
| StanceButton | Default, Selected, Disabled, Locked × (Attack / Defend / Counter) — 12 | `Hexbound/Views/Combat/StanceButton.swift` | Buttons |
| ActiveSlotButton | Empty, Ready, Cooldown(N), Firing — 4 | `Hexbound/Views/Combat/ActiveSlotButton.swift` | Buttons |
| StanceBadge | Attack/Defend/Counter icon badge — 3 | `Hexbound/Views/Combat/StanceBadge.swift` | Badges & Pills |
| RPSResultBanner | Hero wins / Enemy wins / Stalemate — 3 | `Hexbound/Views/Combat/RPSResultBanner.swift` | Toast & Banners |
| ActiveSlotsBar | 3-slot picker, empty vs populated — 2 | `Hexbound/Views/Hero/Talents/ActiveSlotsBar.swift` | Hero & Character |

All use existing tokens (DarkFantasyTheme + LayoutConstants + existing Button/Card instances). No new colors. No new spacing.

### New tokens (minimal)

- `DarkFantasyTheme.stanceAttack` = alias → existing `.danger` (red)
- `DarkFantasyTheme.stanceDefend` = alias → existing `.gold`
- `DarkFantasyTheme.stanceCounter` = alias → existing `.xpRing` (purple)

Sync to Figma primitives + Color collection.

---

## 7. Balance

### 7.1 RPS multipliers (initial)

- Win: ×1.5 damage
- Loss: ×0.5 damage
- Tie: ×1.0
- Chip damage on asymmetric ties: 20% of base

### 7.2 Active talent cooldowns (initial)

- Offensive actives: 3 strikes cooldown
- Defensive actives: 4 strikes cooldown
- Ultimates: 6 strikes cooldown (may not fire more than once per battle in practice)

Tune via admin panel after first playtest.

### 7.3 Backwards compatibility

- Existing fights without `CombatSession` (legacy) resolve via old path (1-shot `/pvp/fight`) — keep the endpoint behind a feature flag for rollback.
- Feature flag `interactive_combat_enabled` (admin panel) — gradual rollout: internal → TestFlight → 10% → 100%.

---

## 8. Rollout Phases

### Phase 1 — Active Slot infrastructure (4-6 days)
- DB: `active_action_type`, `active_cooldown`, `active_magnitude`, `is_activatable` on PassiveNode; `character_active_slots` table.
- Seed: mark 8 nodes as activatable.
- Backend: `/passives/active-slots` CRUD.
- iOS: `ActiveSlotsBarView` + tree node "Equip" button.
- Figma: `ActiveSlotButton`, `ActiveSlotsBar`.
- **Ship standalone** — talents now feel ownable even without combat changes.

### Phase 2 — Combat Session & RPS (6-8 days)
- DB: `combat_sessions` table + `CombatStance` enum.
- Backend: `/pvp/combat/start`, `/pvp/combat/strike`, `/pvp/combat/forfeit`, strike resolver, enemy AI.
- iOS: CombatViewModel refactor from 1-shot to session-based; `StanceSelectorView`, `RPSResultBanner`.
- Figma: `StanceButton`, `StanceBadge`, `RPSResultBanner`.
- Feature flag gated.

### Phase 3 — Active Talents firing in combat (2-3 days)
- Server hooks actives into strike resolver.
- iOS: actives icons in combat, cooldown overlay, firing animation.
- Playtest + balance pass.

### Phase 4 — Polish & live (1-2 days)
- SFX (3 new stance picks, RPS outcome stings).
- Tutorial updates.
- Analytics (`stance_picked`, `rps_outcome`, `active_used`).
- Gradual rollout.

**Total:** ~13-19 days. Parallel work possible (backend + Figma in parallel in Phase 2).

---

## 9. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| 10-20 HTTP/fight → lag feels bad | HTTP/2 keep-alive, server p99 < 80ms, animation window 800ms hides it, optimistic haptic on tap |
| Session orphans (player force-kills app) | 60s TTL sweep cron; resume on reopen |
| Existing active combat for old clients | Keep `/pvp/fight` endpoint alive behind flag; old clients get non-interactive resolution |
| Balance breaks PvP ratings | Feature flag → internal → 10% → 100%; monitor win-rate / rating delta; freeze rating impact for first 72h of each rollout tier |
| Tree UX: "wasted" unlock because node isn't activatable | Clear badge on tree nodes that ARE activatable (gold star); filter in active-slot picker |
| Active talent dominance (one meta build) | Admin panel tuning live; cap magnitude + cooldown per tier |

---

## 10. Open Questions

1. **Class personality for enemy AI**: warrior 50/30/20 attack/defend/counter? tank 20/60/20? Needs balance pass with Scales agent.
2. **Should actives cost mana/energy**, or pure cooldown? (Current plan: pure cooldown.)
3. **Stance for dungeon PvE**: extend or keep auto? (Current plan: PvE stays auto for Phase 1-3; revisit later.)
4. **Respec cost** for active slots: free vs gold cost?

---

## 11. File Touch List (for reference during implementation)

### Backend
- `backend/prisma/schema.prisma` — new enum, model additions, new model
- `backend/prisma/migrations/<timestamp>_interactive_combat/migration.sql`
- `backend/prisma/seeds/passive-tree-activatable.sql` — mark 8 nodes + seed active_action_type
- `backend/src/lib/game/combat-interactive.ts` (new)
- `backend/src/lib/game/active-talents.ts` (new)
- `backend/src/app/api/passives/active-slots/route.ts` (new)
- `backend/src/app/api/passives/active-slots/[slotIndex]/route.ts` (new)
- `backend/src/app/api/pvp/combat/start/route.ts` (new)
- `backend/src/app/api/pvp/combat/strike/route.ts` (new)
- `backend/src/app/api/pvp/combat/forfeit/route.ts` (new)
- `admin/prisma/schema.prisma` (copy)

### iOS
- `Hexbound/Models/ActiveSlot.swift` (new)
- `Hexbound/Models/CombatStance.swift` (new)
- `Hexbound/Models/CombatSession.swift` (new)
- `Hexbound/Views/Hero/Talents/ActiveSlotsBar.swift` (new)
- `Hexbound/Views/Hero/Talents/ActiveSlotPickerSheet.swift` (new)
- `Hexbound/Views/Hero/Talents/TalentNodeView.swift` (edit — equipped-as-active visual)
- `Hexbound/Views/Hero/Talents/PassiveTreeViewModel.swift` (edit — equipActive)
- `Hexbound/Views/Combat/StanceButton.swift` (new)
- `Hexbound/Views/Combat/StanceSelectorView.swift` (new)
- `Hexbound/Views/Combat/ActiveSlotButton.swift` (new)
- `Hexbound/Views/Combat/RPSResultBanner.swift` (new)
- `Hexbound/Views/Combat/StanceBadge.swift` (new)
- `Hexbound/Views/Combat/CombatDetailView.swift` (edit — integrate selector)
- `Hexbound/Views/Combat/CombatViewModel.swift` (major refactor — session-based)
- `Hexbound/Network/APIEndpoints.swift` (edit — new endpoints)
- `Hexbound/Theme/DarkFantasyTheme.swift` (edit — stance color aliases)
- `Hexbound/Hexbound.xcodeproj/project.pbxproj` (add ~11 new files, 4 sections each)

### Figma
- DS file (uDjXIz7CdJxcEOI5jCBcjY): StanceButton (12v), ActiveSlotButton (4v), StanceBadge (3v), RPSResultBanner (3v), ActiveSlotsBar (2v)
- Color tokens: stanceAttack / stanceDefend / stanceCounter aliases

### Docs
- `docs/06_game_systems/COMBAT.md` — update with interactive model
- `docs/04_database/SCHEMA_REFERENCE.md` — new tables/columns
- `docs/03_backend_and_api/API_REFERENCE.md` — new endpoints
- `docs/07_ui_ux/SCREEN_INVENTORY.md` — stance selector, active slots bar

---

## 12. First Concrete Step

Start with **Phase 1 DB migration** because it unblocks everything else and is low-risk (pure additive). Specifically:

1. Edit `schema.prisma` → add 4 columns to `PassiveNode` + new `CharacterActiveSlot` model.
2. `npm run db:migrate:dev -- --name active_slot_infrastructure`
3. `cp backend/prisma/schema.prisma admin/prisma/schema.prisma`
4. Write `passive-tree-activatable.sql` to mark 8 nodes.
5. Run drift checker.
6. Commit via `.git-trigger`.

Then build the Active Slots UI before touching combat at all.

---

## 13. Balance & Economy Alignment (v2 — added 2026-04-13)

This section reconciles the plan with the three source-of-truth docs: `COMBAT.md`, `BALANCE_CONSTANTS.md` (+ `ECONOMY_RULES.md`), and `SKILL_TREE_DESIGN.md`. Where the v1 plan conflicted with shipped systems, v2 supersedes it.

### 13.1 Conflicts found in v1

| # | v1 claim | Shipped system | Verdict |
|---|---|---|---|
| C1 | New "Attack / Defend / Counter" RPS stances | `combat.ts` already has **head / chest / legs** attack zones + defense zones with match/mismatch bonuses | **Replace RPS with interactive zone choice.** No new stance enum needed. |
| C2 | "Battle = 3–5 strikes, session ends when HP ≤ 0 OR strikes exhausted" | Existing combat = **15 turns**, each turn both sides attack, 30 actions total | **Keep 15-turn ceiling.** Interactive input occurs on the **hero's attacking turn only** (~7–8 choices per fight). Defender zone is still used, but chosen as a prediction **before** the strike. |
| C3 | Active talents = new `TalentSlotAction` enum with new magnitudes | `SKILL_TREE_DESIGN.md` §4.3 already spells out ~12 active skills per class, cooldown-based, scaling per rank, integrated with turn engine. Backend has `Skill` + `CharacterSkill` + `EquippedSkill` | **Reuse the existing Skill system.** Active slots = the existing **4 equipped skill slots** (or 3 per new design if we reduce). No new enum, no new `active_action_type` column. The "Equip as Active" UX becomes **"Equip from tree unlock list"** — tree unlocks skills; equipped slots pick from unlocked. |
| C4 | "Respec active slots — free vs gold?" | `SKILL_TREE_DESIGN.md` §3.4: "Loadout change is **free** pre-fight. No cooldown, no cost." | **Resolved: free pre-fight.** Mid-fight locked. No new SKU. |
| C5 | "Win ×1.5, Loss ×0.5, Tie ×1.0" as reward multiplier | `balance.ts` rewards = `150 / 50 gold`, scaled by `level × 0.04`, plus CHA tier, streaks, revenge, first-win-of-day | **Reframed:** ×1.5 / ×0.5 / ×1.0 were intended as **per-strike damage multipliers** on the zone-match outcome, NOT reward multipliers. Rewards stay exactly as-is — interactive combat should not change the payout surface, per R1 pillar #3 ("monetization never buys combat power"). A faster-moving, more skillful win still pays 150 gold base. |
| C6 | New `combat_sessions` table | Existing `Battle` + `BattleLog` tables already persist combat state | **Merge:** add per-strike interaction log to `BattleLog`, add `status = 'awaiting_input'` + `interactiveStrikeIndex` + `interactiveTimeoutAt` columns to existing `Battle`. No new table — just new columns. Expired sessions fall back to the existing 1-shot resolver automatically. |
| C7 | "Chip damage 20% of base" on asymmetric ties | Existing pipeline has no "tie" concept — zones always resolve | **Drop.** The existing zone-match / mismatch bonuses (±15% def, ±5% off) already handle the "tie-ish" case elegantly. |
| C8 | "Ultimates CD = 6 strikes" | `SKILL_TREE_DESIGN.md` §4.5: ultimates are **Ultimate Meter gated** (fills from damage dealt/taken), not cooldown | **Align:** defer ultimate wiring to a follow-up feature that adds the Ultimate Meter bar. Phase 1–3 of this plan only touches the 3-slot active loadout (existing cooldown skills). |

### 13.2 Revised combat loop (replacing §3 RPS Rules)

Combat remains **15 turns max** (`BATTLE_FATIGUE_START = 11`, existing constants untouched). Per turn where the **hero attacks**:

1. **Predict phase (hero):** hero picks an **attack zone** (head/chest/legs) AND a **defense zone** (head/chest/legs) for the opponent's next swing. 2 taps. Timer: 8s, auto-pick = last-used zones.
2. **Active phase (optional):** hero may tap 1 of 3 equipped skill slots if cooldown is 0. Skill fires on this turn's swing.
3. **Resolve (server):** existing `resolveAttack()` pipeline runs. Opponent's attack zone = deterministic from `seed + turnIndex` using class personality weights (see §13.4). Opponent's defense zone same. Apply all existing rolls (CHA miss, dodge, crit, armor, stance, passive DR, rogue execute).
4. **Reveal:** opponent zones flip in, damage number resolves, HP bars tween.
5. **Riposte (hero defends):** opponent's predicted attack zone + hero's chosen defense zone from step 1 are now used for the return swing. No second input window on the same turn — the choice was made upfront.

**Input density:** ~7 interactive turns per 15-turn fight × 2 taps (zones) + occasional skill tap = ~15–20 user actions per battle. Matches the "tactical but not exhausting" target.

### 13.3 Zone-match math (unchanged from shipped)

Already in `COMBAT.md` §Stance System — quoted here for the prototype:

- Attacker picks head = +10% offense / +5% crit
- Attacker picks chest = +5% offense / 0 crit
- Attacker picks legs = +2% offense / 0 crit *(W3.D4 fix — no dominated option)*
- Defender picks head = 0% def / +8% dodge
- Defender picks chest = +10% def / 0 dodge
- Defender picks legs = +5% def / +3% dodge
- **Correct prediction** (defender zone == attacker zone) = **+15% defense** to defender
- **Mismatch** (defender zone != attacker zone) = **+5% offense** to attacker

These are real numbers already in `balance.ts`. No new constants.

### 13.4 Opponent AI zone selection (deterministic)

```ts
function deriveEnemyZones(seed: string, turnIndex: number, enemyClass: CharacterClass): { atk: Zone, def: Zone } {
  const h = mulberry32(hashSeed(seed + ':' + turnIndex));
  const weights = ZONE_WEIGHTS_BY_CLASS[enemyClass]; // warrior leans head-attack, tank leans chest-def, etc.
  return { atk: pickWeighted(weights.attack, h()), def: pickWeighted(weights.defense, h()) };
}
```

Personality table (initial — Scales agent will tune):

| Class | Attack head / chest / legs | Defense head / chest / legs |
|---|---|---|
| Warrior | 50 / 30 / 20 | 20 / 50 / 30 |
| Rogue | 45 / 25 / 30 | 40 / 25 / 35 |
| Mage | 40 / 40 / 20 | 30 / 40 / 30 |
| Tank | 30 / 40 / 30 | 20 / 60 / 20 |

Deterministic — same `battleId` replays identically, which is required for async PvP replay parity.

### 13.5 Economy impact — none

Every rule in `ECONOMY_RULES.md` passes:

| Rule | Passes? | Note |
|---|---|---|
| R1 — Retention > Monetization > Fairness | ✅ | Interactive combat is pure engagement; no paywall. |
| R2 — Two currencies, no exceptions | ✅ | No new currency introduced. Respec stays 50 gems. |
| R3 — Reward scaling matches cost scaling | ✅ | Rewards unchanged (`150/50 × level mult`). |
| R4 — 60–80% sink ratio | ✅ | Sinks unchanged. |
| R5 — Achievement ranks use real ELO ceilings | ✅ | No achievement changes. |
| R7 — Upgrade curve | ✅ | Untouched. |
| R8 — Stamina cap + refill | ✅ | Untouched (PvP still costs 10 stamina per match). |
| R11 — Premium Pass | ✅ | Untouched. |
| R15 — No P2W | ✅ | Actives are earned via tree unlock (level-gated skill points, not gems). |

**Respec cost sanity:** existing passive respec = 50 gems. Active slot loadout = free pre-fight. Single-point refund (tree) per `SKILL_TREE_DESIGN.md` §6.1 = 10 gems. All three tiers already exist — no new SKU, no new paywall.

**Stamina sanity:** a session-based fight no longer refunds stamina on forfeit (intentional — prevents farm-forfeit cheese). PvP cost stays 10 stamina; free PvP 3/day stays free. Forfeit = loss, normal ELO loss, no extra penalty.

**Match pacing sanity:** v1 worried interactive combat would take "3 min per fight" and starve the economy (fewer matches/session → less gold). Target fight length = **~60s** (15 turns × ~4s per turn with animations, optimistic input). Within one stamina bar (120 stamina = 12 matches), total play time is ~12 min — same ballpark as current. No change to `LEVEL_REWARD_SCALE`.

### 13.6 Balance veto — what would break it

The plan fails rebalance review if any of the following ships:

1. **Per-strike reward multipliers** (the original "×1.5 win, ×0.5 loss"). Rewards stay whole-match, whole-number. Per-strike multipliers are **damage only**, and damage is already capped by the 15-turn fight length.
2. **Stance choice inflating win rate > 55% for the choosing player** in mirror matchups. Interactive combat must not dominate passive — in mixed queues, both populations must be within 5pp of 50% win rate on equal ELO. Tracked via analytics event `interactive_combat_outcome`.
3. **Active slot meta collapse** (one slot config wins > 40% of all fights). Admin-panel tunable cooldowns, feature flag rollback if observed.
4. **Session TTL abuse** (player force-quits when losing, re-enters at full HP). Solution: session resume uses stored HP, not fresh HP. Encoded in the revised `Battle` columns.

---

## 14. Combat Prototype — Detailed Spec

A clickable prototype lives at `docs/features/combat/interactive-combat-prototype.html` (single-file, no build step — open in any browser). It implements:

### 14.1 Scene structure (3 phases per turn)

```
[ INPUT PHASE ]              [ RESOLVE PHASE ]             [ REVEAL PHASE ]
  - 8s timer                   - no input, 1200ms total      - damage numbers rise
  - 3 attack-zone buttons      - hero swing animation        - HP bars tween 400ms
  - 3 defense-zone buttons       (400ms windup, 200ms hit)    - "correct!" banner if
  - 3 active-slot buttons      - opponent swing (if alive)     prediction matched
    (only if CD == 0)          - both swings share the RNG   - cooldown ticks -1
  - "Attack" CTA (commits)       seed segment                 - → next turn (or end)
```

### 14.2 State machine (client)

```
idle
  └─ startFight → INPUT_ATK_ZONE
INPUT_ATK_ZONE
  ├─ tap zone → INPUT_DEF_ZONE (keep atk choice highlighted)
  └─ timer 0 → auto-pick last-used → INPUT_DEF_ZONE
INPUT_DEF_ZONE
  ├─ tap zone → INPUT_READY
  ├─ tap active slot → toggle active (optional)
  └─ timer 0 → auto-pick last-used → SUBMIT
INPUT_READY
  ├─ tap "Strike" → SUBMIT (optimistic haptic)
  └─ tap any zone → update + stay
SUBMIT
  └─ POST /pvp/combat/strike → RESOLVE
RESOLVE
  └─ animation queue plays → REVEAL
REVEAL
  ├─ onFinish (animations done) → if isFinished → END else INPUT_ATK_ZONE
END
  └─ show BattleResultCardView (existing component)
```

### 14.3 Animation timings (ms)

| Frame | Start | End | Element |
|---|---|---|---|
| Input in | 0 | 200 | Stance buttons fade/slide up |
| Input hold | 200 | 8200 | Timer ring drains |
| Commit | 8200 | 8400 | Buttons gold pulse, haptic `.medium` |
| Windup | 8400 | 8800 | Hero sprite raises weapon |
| Zones reveal | 8500 | 8700 | Both zone icons pop (scale disallowed → opacity 0→1 + y -8→0) |
| Impact | 8800 | 9000 | Screen shake 4px if crit, damage number spawn |
| HP tween | 9000 | 9400 | HP bar decrement |
| Return swing | 9400 | 10200 | Opponent sprite swing, mirrored timings (compressed) |
| HP tween (hero) | 10200 | 10600 | Hero HP decrement |
| Outcome banner | 10600 | 11400 | "CORRECT PREDICTION" or "MISS" or miss text |
| Reset | 11400 | 11600 | Buttons back to default state |

**Budget:** ~3.2s per turn with all animation. 15 turns × 3.2s = 48s worst-case. Skill-fire adds ~400ms for the cast VFX. Target median: 60s total, matching §13.5.

### 14.4 Optimistic UI rules

- **Haptic + button selection state fire on tap, before network round-trip.** `.medium` haptic for zone, `.heavy` for skill-fire tap.
- Network call starts on second tap (defense zone). Response typically arrives during the 600ms windup animation → seamless.
- If p95 response > 800ms → show dim overlay + spinner over hero sprite (never block input panel, which is already committed).
- If network fails → session persists server-side (already committed); client auto-retries on reconnect.

### 14.5 Prototype coverage checklist

The HTML prototype must demonstrate:

- [x] 15-turn turn counter with fatigue indicator starting turn 11
- [x] 3 attack zones + 3 defense zones, real bonus math applied
- [x] 3 skill slots with cooldown counters
- [x] Deterministic opponent zone selection (seeded PRNG, class personality weights)
- [x] HP bars, damage numbers, miss/dodge/crit labels
- [x] Prediction-match banner (+15% def visualised)
- [x] Timeout auto-pick using last-used zones
- [x] End screen with gold/XP/ELO delta preview
- [x] No scale animations (per memory rule `feedback_no_scale_animations`)
- [x] All colors from `DarkFantasyTheme` hex values (no ad-hoc palette)

### 14.6 Sequence diagram (strike)

```
Hero (iOS)          Server                         Opponent (snapshot)
   │                   │                                   │
   │ tap atk-zone      │                                   │
   │ tap def-zone      │                                   │
   │ tap "Strike" ─────► POST /pvp/combat/strike          │
   │                   │ loadBattle(sessionId)             │
   │                   │ if turn expired → forfeit        │
   │                   │ deriveOpponentZones(seed, t) ◄────│ (deterministic)
   │                   │ resolveAttack(hero → opp) [existing pipeline]
   │                   │ resolveAttack(opp → hero) [existing pipeline]
   │                   │ persist BattleLog row             │
   │                   │ persist Battle.turn = t+1         │
   │                   │ if HP≤0 || t≥15 → finalize, award rewards via existing path
   │ ◄────────────────── 200 { heroSwing, oppSwing, newHpA, newHpB, cdTick, isFinished, final? }
   │ play animation queue                                  │
   │ if isFinished → route to BattleResultCardView        │
```

### 14.7 Failure modes covered in prototype

| Mode | Prototype behaviour |
|---|---|
| Player closes app mid-fight | Session persists server-side with `awaitingInput` + `timeoutAt`; re-opening re-hydrates from last `Battle.turn` |
| Timeout (60s no input) | Server auto-picks last-used zones and advances — no forfeit (less punishing than v1) |
| Forfeit button | Explicit — defender wins, ELO loss applied |
| Network flap during strike | Client retries 3× with backoff; server idempotent on `(battleId, turnIndex)` |
| Replay from share link | Deterministic seed replays identically — used for async PvP and spectator |

---

## 15. Revised file touch list delta (v2 vs v1)

**Removed from v1:**
- ~~`TalentSlotAction` enum~~ — replaced by reusing existing `Skill.effectType`
- ~~`PassiveNode.activeActionType / activeCooldown / activeMagnitude / isActivatable` columns~~ — activatable-ness is derived from "is this node a Skill-unlock node?" flag already in seed
- ~~`CombatSession` table~~ — replaced by new columns on `Battle`: `interactiveStrikeIndex`, `interactiveTimeoutAt`, `status` (enum add: `awaiting_input`)
- ~~`CombatStance` enum (attack/defend/counter)~~ — existing `Zone` enum (head/chest/legs) is sufficient
- ~~New tokens `stanceAttack/stanceDefend/stanceCounter`~~ — use existing `bodyHead/bodyChest/bodyLegs` semantic mapping or introduce one `zoneAccent` alias

**New columns on existing `Battle`:**

```prisma
model Battle {
  // ... existing fields
  interactiveStrikeIndex Int?       @map("interactive_strike_index")
  interactiveTimeoutAt   DateTime?  @map("interactive_timeout_at")
  interactiveHeroChoices Json?      @map("interactive_hero_choices")   // per-turn zones + skill uses
  status                 BattleStatus @default(completed)
}

enum BattleStatus {
  completed
  awaiting_input
  forfeit
  expired
}
```

**Net change:** -1 enum, -1 table, -4 columns vs v1. Simpler migration, lower risk, aligns with shipped model.
