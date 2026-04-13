# Interactive Combat — Mechanic Spec

**Version:** v2.1 (reuse-first)
**Status:** Design (not implemented)
**Depends on:** `COMBAT.md`, `BALANCE_CONSTANTS.md`, `SKILL_TREE_DESIGN.md`, `INTERACTIVE_COMBAT_PLAN.md` v2
**Principle:** Zero new mechanics. Every system is either already-shipped or a UI layer over an already-shipped system.

---

## 1. Design goal

Make the existing 15-turn auto-combat **playable** — the player makes one meaningful choice per strike, sees what that choice did, and learns to read the opponent. Nothing else about the sim changes: the same `resolveAttack()` pipeline runs, the same payouts pay out, the same ELO updates update.

**What "playable" means here:**

1. Player makes a decision inside a 6-second window.
2. The result of that decision is visible within 2 seconds of resolution.
3. The next decision is informed by the last (reads, anti-reads).
4. The whole fight ends in 45–75 seconds of wall-clock time.

---

## 2. Fight lifecycle (7 phases)

```
[Pre-fight] → [Intro] → [Turn loop] → [Climax] → [Reveal] → [Rewards] → [Exit]
    loadout    zoom-in    N strikes     last-hit   numbers    gold+ELO    back
    (free)     +banners   (2-8 typical)            tally      payout      to Arena
```

### 2.1 Pre-fight (Arena lobby, before tap "FIGHT")

**Player sees:** own hero card + opponent card + "FIGHT" CTA.

**Player can:**
- Swap equipped skills (up to 3 slots, free, `SKILL_TREE_DESIGN.md` §3.4)
- Swap equipment (existing Inventory flow)
- Change stance defaults (reused from current stance screen)
- Back out (no penalty)

**What's new:** an **Opponent Read** strip above the CTA showing opponent's stance history from their last 5 public fights — e.g. "Head 60% · Chest 20% · Legs 20%". This is read-only data pulled from existing `Battle.heroStance` / `Battle.enemyStance` columns. No new table, no new endpoint — just a new query on existing data.

**Why it matters:** gives pre-fight decisions weight (pick skills and stance defaults based on tendencies) without inventing any mechanic.

### 2.2 Intro (2.5 s, uninterruptable)

- Arena background fades in.
- Both heroes slide from off-screen to their mark (opacity + translate, no scale — memory feedback rule).
- Name banners flip in with ELO + tier badge.
- Class icon pulses once (opacity pulse, 200 ms).
- Turn-order indicator reveals: "⚡ You strike first" or "⚡ Opponent strikes first" (AGI-based, existing rule).

**Skippable:** tap anywhere after 1.0 s → cuts to turn 1.

### 2.3 Turn loop — the core

See §3.

### 2.4 Climax (the lethal strike)

Triggered when a strike would reduce HP to ≤ 0 **OR** is strike #30 (turn 15 × 2 actions) and opponent has less HP %.

- Global time-dilation: everything slows to 0.4× for 600 ms.
- Screen desaturates.
- Damage number for the killing strike draws 2× larger and gold-tinted.
- On hit: victim collapses (opacity fade + tilt rotation, no scale).
- On timeout draw: both fighters kneel, HP% badges flash.

### 2.5 Reveal (numbers tally)

Fullscreen panel, uses the existing Battle Result Card component from the DS (9 rarity variants already shipped, we pick one by outcome):

- Victory / Defeat / Timeout label
- Final HP bars (animated drain)
- Strike count · crit count · dodge count
- Gold reward, XP reward, ELO delta (all coming from existing server payload)

### 2.6 Rewards (existing Celebration Banner stack)

Drops in order using existing shipped components:
1. **XP bar** fills (XPBarView) → if level up, show Level Up Modal.
2. **Gold** pill counts up (WidgetPill.gold, animated flag).
3. **ELO** delta badge slides in (green ↑ or red ↓).
4. **Achievement** toast if any progress updated (ToastOverlayView).
5. **Quest** progress toast if applicable.

Each beat = 350 ms. Total = ≤ 2 s.

### 2.7 Exit

- "REMATCH" (if opponent online, existing challenge flow)
- "BACK TO ARENA" (default)
- "SHARE" (screenshot the reveal panel)

---

## 3. Turn structure — the core loop

Each strike is a **single round** with two halves: **Predict** (you choose), **Resolve** (server reveals). The server already runs this exactly — we're only surfacing the choice and the result.

```
┌────────────────────────────────────────────────────────┐
│ STRIKE N of up-to-15×2                                 │
├────────────────────────────────────────────────────────┤
│ ① Predict window  (6 s, player input)                  │
│    ├─ Attack zone  (head / chest / legs)               │
│    ├─ Defense zone (head / chest / legs)               │
│    └─ Optional skill (if attacker this strike)         │
│                                                         │
│ ② Submit         (tap FIGHT or auto-submit on timer)   │
│                                                         │
│ ③ Lock-in        (300 ms, no-take-back, optimistic UI) │
│                                                         │
│ ④ Server resolve (200–500 ms, authoritative)           │
│                                                         │
│ ⑤ Reveal         (1.4 s scripted animation)            │
│    ├─ Zone-match flash                                 │
│    ├─ Crit / dodge / miss beats                        │
│    ├─ Damage number                                    │
│    └─ HP bar drain                                     │
│                                                         │
│ ⑥ Outcome badge  (500 ms, stays until next strike)     │
│                                                         │
│ → next strike, or Climax if HP ≤ 0                     │
└────────────────────────────────────────────────────────┘
```

Total strike length: **~8.5 s** best case (instant tap), **~12 s** worst case (auto-submit on timeout).

### 3.1 Player choice surface (Predict window)

The screen during Predict is the most important UI in the game. It must be readable on a 6" device in 2 s, editable in 4 s, confirmable in 6 s.

**Layout (top → bottom):**

| Region | Content | Source |
|---|---|---|
| Header | Strike `N/30`, 6 s countdown ring | New, thin layer |
| Opponent band | HP bar, class tag, last 3 actions strip | Reuse HPBarView, ClassTagView |
| Prediction zone | **Defense picker** — 3 large tiles: head / chest / legs. Icons = existing stance icons. | Reuse stance icons |
| Middle banner | Turn label: "You defend" / "You strike" | New thin layer |
| Attack zone | **Attack picker** — 3 large tiles + hero pose preview | Reuse stance icons |
| Skill rail | 3 slots with cooldown overlays, tap to arm | Reuse existing Skill + CharacterSkill |
| Hero band | HP, Ultimate meter (see §5), last 3 actions | Reuse HPBarView |
| Footer | FIGHT button (gold CTA, full-width) | Reuse ButtonStyles `.primary` |

**Tile states:**
- Idle: DS card with gold bracket corners.
- Hovered/Pending: inner border brightens (opacity 1.0 → opacity 1.0 with +8% inner white, per Figma spec).
- Selected: gold fill bloom (fill = `#D4A537`, text → `textOnGold`).
- Locked (after FIGHT): grayscale + 85% opacity.

**Interaction rules:**
- Tap a tile → arms it.
- Tap another tile in the same row → replaces.
- Tap same tile again → deselects (unless timer < 2 s).
- Both rows must have a selection → only then FIGHT button enables.
- If timer hits 0 → auto-pick: defense = opponent's most common attack zone (from pre-fight read strip), attack = opponent's least-used defense zone. Skill = none.

### 3.2 What the server receives per strike

One compact payload. Nothing new — it's a superset of the existing battle-initiation payload.

```
POST /pvp/strike
{
  battleId,
  strikeIndex,
  heroAttackZone:  "head" | "chest" | "legs",
  heroDefenseZone: "head" | "chest" | "legs",
  skillSlotIndex:  0 | 1 | 2 | null,
  clientTs
}
```

Server responds with the full strike result (same shape as existing `resolveAttack` output, plus opponent's zone picks for reveal).

### 3.2a Three-layer influence model — talents × skills × stances

The interactive layer does **not** introduce new math. It exposes three already-shipped systems at three different timescales, all of which converge into the same `resolveAttack()` pipeline.

| Layer | When fixed | Where it lives | What it does per strike |
|---|---|---|---|
| **Passive talents** | Out-of-combat, when player spends tree points | Already baked into `hero.stats` and flags on `Character` | Changes stats and permanent modifiers BEFORE the strike starts |
| **Active skills (3 slots)** | Pre-fight loadout (free, `SKILL_TREE_DESIGN.md` §3.4) + per-strike slot arm in Predict | `CharacterSkill` rows with `isEquipped + slotIndex` | Multiplies base damage + triggers effects (stun/heal/DoT) at strike time |
| **Stance zones** | In the Predict window of every strike (6 s) | New `interactive_hero_choices` JSON column on `Battle` | Changes final damage via match/mismatch math |

#### Where each layer slots into `resolveAttack`

Exact existing pipeline, annotated with which layer touches which step:

```
① hit check (CHA)                        ← passive (CHA from talents)
② dodge check (AGI/LUK)                  ← passive
③ base damage (class formula)            ← passive (STR/AGI/INT/VIT/LUK)
④ variance ±10%
⑤ × skill multiplier                     ← ACTIVE SKILL
⑥ × attack-zone bonus                    ← STANCE (attack pick)
⑦ × (defense match ? 0.85 : 1.0)         ← STANCE (defense pick)
⑧ × (defense mismatch ? 1.05 : 1.0)      ← STANCE (defense miss)
⑨ ÷ armor/resist mitigation              ← passive (armor gear)
⑩ × (tank ? 0.85 : 1.0)                  ← passive (class)
⑪ × (crit ? 1.5 : 1.0)                   ← passive (LUK/AGI formula)
⑫ × (rogue execute ? 2.0 : 1.0)          ← passive (rogue flag)
⑬ × (turn≥11 ? fatigue mult : 1.0)       ← passive (global rule)
⑭ + skill side-effects (stun/heal/DoT)   ← ACTIVE SKILL
```

Passive touches ①②③⑨⑩⑪⑫⑬. Active touches ⑤ and ⑭. Stance touches ⑥⑦⑧. Single pass, single transaction, unchanged from shipped resolver.

#### What the player controls in the 6 s Predict window

Exactly three inputs, each bound to a subset of pipeline steps:

1. **Attack zone** (head / chest / legs) → drives ⑥ and tilts ⑪ (`head` = +5% crit).
2. **Defense zone** (head / chest / legs) → drives ⑦ and ⑧ on the opponent's return strike.
3. **Skill slot** (0 / 1 / 2 / none) → drives ⑤ and ⑭.

Passive is never chosen in combat — it's already in `hero.stats` at strike #1.

#### Numerical envelope (same fighter, different choices)

Lvl-20 Warrior, STR 50, target armor 50, auto-attack baseline = ~66 damage:

| Scenario | Final damage | Δ vs. base |
|---|---|---|
| Base (no skill, no match/mismatch) | ~66 | — |
| + passive: +10 STR from tree | ~72 | +9 % |
| + active skill ×1.5 (Rage Strike) | ~108 | +63 % |
| + stance mismatch (defender guessed wrong) | ~113 | +71 % |
| + crit (LUK roll succeeded) | ~170 | +157 % |
| All four compounding | ~186 | +181 % |
| Defender **matched** instead of mismatch | ~96 (vs. 113) | defender saved ~15 % |

Best-vs-worst strike spread for identical `hero.stats` ≈ **×3**. That spread is the entire skill-expression surface of interactive combat.

#### Talent-tree ↔ interactive combat channels (no duplication)

The tree is not reworked. It feeds the interactive layer through exactly three channels:

| Channel | Mechanism |
|---|---|
| **A. Stat passives** | Node "+5 STR" → lifts step ③. Player feel: "my strikes hit harder in every stance." |
| **B. Conditional passives** | Node "+10 % damage in Head stance" → conditional multiplier at ⑥ (already supported by skill/passive flag). Player feel: "zone choice just got more important." |
| **C. Active skills** | Active nodes go into the equippable pool → player slots 3 → they appear in the Predict skill rail. |

**No new nodes required.** The current 40-node-per-class trees in `SKILL_TREE_DESIGN.md` already cover all three channels.

#### Stance ↔ interactive combat

Stance already lives in pipeline steps ⑥⑦⑧. Old UX: one stance set per fight. New UX: both zones re-picked every strike. **Coefficients and formulas unchanged** (attack head = +5 % crit, chest = +5 % dmg, legs = +5 % hit, defense match −15 %, mismatch +5 % for attacker). The only mechanical delta is decision frequency (1 per fight → 2 per strike).

#### What the Reveal must surface to keep choices legible

Per-strike animation must attribute damage to the right layer, or player decisions lose felt weight:

| Signal | Visual | Source layer |
|---|---|---|
| Zone match / mismatch | Gold / red ring around attack zone at t=220 ms | Stance |
| Skill fired | Skill icon flash above hero at t=360 ms | Active |
| Crit / Execute | Shockwave ring at t=500 ms | Passive + LUK roll |
| Final damage | Gold/red number + HP bar drain | Sum |
| Side effect (stun/DoT/heal) | Badge above target after t=1200 ms | Active skill effect |

Within 1.4 s the player reads: "zone mismatched + skill fired + crit → that's why 170." On a base strike they read: "no match, no skill → 66, expected." That contrast is the teaching loop.

---

### 3.3 Outcome taxonomy (what can happen on a strike)

Every strike resolves into **exactly one** of these 9 outcome states. This is what the Reveal animation branches on:

| # | Outcome | Condition | Visual | Damage % of base |
|---|---|---|---|---|
| 1 | **MISS** | Attacker CHA check failed (`combat.ts`) | "MISS" stamp, opacity wobble | 0 |
| 2 | **DODGE** | Defender passed dodge roll (AGI/LUK) | Ghost trail on defender | 0 |
| 3 | **GLANCING** | Defender predicted correctly (zone match) | Sparks at defender's zone | ~55–65% |
| 4 | **HIT** | Standard resolution, no match, no crit | Clean flash | 90–110% |
| 5 | **ANTI-READ** | Attacker hit opposite of defender's guess (mismatch) | Yellow edge flash | 105–116% |
| 6 | **CRIT** | Crit roll succeeded | Red shockwave ring | 150% |
| 7 | **EXECUTE** | Rogue passive, victim < 15% HP | Gold chain-flash, kill if lethal | ~200% or lethal |
| 8 | **BLOCKED** | Tank 15% reduction + match (stacks) | Shield arc glyph | ~45–55% |
| 9 | **FATIGUE** | Turn ≥ 11 bonus triggered | Orange heat haze on fatigued side | base × (1 + 0.1 × (turn−10)) |

**All 9 are read directly from the existing `resolveAttack` return value** — we just map outcome flags to animations. No new flags, no new calculations.

### 3.4 Reveal animation (1.4 s, scripted)

Frame-accurate timeline (hero is attacker this strike):

| t (ms) | Event |
|---|---|
| 0 | Zone tiles dim, lock badges appear |
| 80 | Opponent's picks flip in (reveal their guess) |
| 220 | Match/mismatch flash: gold ring if attack ≠ opponent's defense zone, red ring if attack == opponent's defense zone |
| 360 | Hero strike pose (opacity cross-fade between idle and strike frames) |
| 500 | Impact: outcome-specific beat (crit shockwave, dodge trail, etc.) |
| 650 | Damage number draws (gold for normal, red for crit, gray for glancing, strikethrough-red for miss/dodge) |
| 800 | Opponent HP bar drains (duration 400 ms, ease-out) |
| 1200 | Outcome badge settles above opponent |
| 1400 | Ready for next predict window |

Opponent-attacker rounds mirror this (hero defends). Both halves of a turn always play in full — no skipping.

### 3.5 Last-3 actions strip (memory aid)

Above each HP bar, a small strip shows the last 3 zone picks as icons (defense on own side, attack on opponent side). This is the only thing resembling "new" data — but it's generated client-side from the already-sent strike responses. No storage change.

---

## 4. Skill activation (reusing Skill system)

### 4.1 What's reused

- The existing 3-slot loadout (`CharacterSkill` rows, `isEquipped` + `slotIndex`).
- Existing cooldown counter on each skill (`currentCooldown` in resolver).
- Existing damage multipliers and effect flags on `Skill` rows.
- Existing `SKILL_TREE_DESIGN.md` §4 catalog — all 48 skills remain untouched.

### 4.2 What's new (UI only)

- 3 skill cards on the Predict screen, each showing:
  - Icon (existing)
  - Cooldown pill (reuse WidgetPill)
  - Tap target
- Tap = arm for this strike. Taps while already armed = disarm.
- If armed skill has CD > 0 → card is locked with a CD overlay (existing pattern from other cooldown displays).
- On strike resolve, armed skill's CD sets to `skill.cooldown` (turns), decrements 1 per turn until ready.

### 4.3 Skill + zone interaction

Skill multiplier **stacks** with zone mismatch bonus:

```
final = base × skillMult × zoneOffenseBonus × zoneDefenseReduction × variance × ...
```

No new formula — this is exactly how `resolveAttack` already multiplies these.

### 4.4 Heroic Recovery, Shield Bash, non-damage skills

These already exist as skill flags (heal, stun, etc.). UI difference: if skill is non-damage, the Attack zone tile is **required anyway** (basic attack always fires unless skill fully replaces it, per existing resolver). Stuns suppress the opponent's next Predict window — opponent sees a "STUNNED" overlay and auto-submits random picks.

---

## 5. Ultimate Meter (follow-up phase, not v1)

**Deferred** — spec only, not in v1 implementation.

- Fills from damage dealt (0.5 per point) and taken (0.3 per point), exactly as in `SKILL_TREE_DESIGN.md` §4.5.
- Full bar unlocks a 4th skill slot button during Predict.
- Same resolver path as skills — multiplier + flags.
- UI: a gold bar between skill rail and HP bar. Pulses when full.
- **Excluded from v1** to avoid shipping two new systems at once. Ships after v1 stabilizes.

---

## 6. Failure & edge cases

| Case | Handling |
|---|---|
| Client timeout (no submit) | Auto-pick fires at t=6000. Payload sent with `auto=true` flag so telemetry can track auto-submit rate. |
| Disconnect mid-strike | Server holds state for 30 s. On reconnect, client reloads strike index and resumes. After 30 s: forfeit, opponent awarded by HP% rule. |
| App backgrounded | Predict pauses (strike timer freezes). On foreground, predict resumes with remaining time. Backend TTL = 60 s total per strike. |
| Opponent disconnect | Hero sees "Opponent connecting..." overlay. 30 s grace. After that: hero wins by forfeit. |
| Reconcile conflict (double-submit) | Server takes first payload, 409 on second. Client rolls back optimistic UI if 409. |
| Server rejects choice (e.g. skill on CD) | Client shows toast "Skill not ready", reopens predict window with remaining timer. |

---

## 7. Economy touch (unchanged)

Full reuse. Same payouts, same ELO, same quests. Interactive is **just** a presentation layer.

| Lever | Before | After |
|---|---|---|
| Gold per win | `150 × (1 + 0.04×(lvl−1))` | identical |
| XP per win | `50 × (1 + 0.04×(lvl−1))` | identical |
| ELO delta | Existing K-factor | identical |
| Quest triggers | `pvp/resolve` event | identical |
| Achievement hooks | pvp category | identical |
| Gem cost | 0 (only skill respec, unchanged) | 0 |

**R1–R15 economy rules pass list:** all 15 unchanged, because nothing about the reward pipeline changes.

---

## 8. Balance veto conditions

Ship gates (must hold in telemetry before promoting from beta):

1. **Average fight length:** 45–75 s. If > 90 s → cut timeout from 6 s to 5 s.
2. **Auto-submit rate:** < 20 % of strikes. If > 30 % → indicates UI/timer too harsh.
3. **Skill usage rate:** > 40 % of strikes with CD ready. If lower → skills aren't readable.
4. **Zone-match rate:** 28–40 % (baseline is 33 % random). If < 25 % or > 50 % → meta is too swingy.
5. **Win rate at ≥ ±200 ELO gap:** 70–85 % for higher-rated side. If < 60 % → interactive layer makes outcome too random (skill ceiling collapse).
6. **Forfeit rate:** < 5 %. If > 10 % → disconnect/timeout handling is broken.

---

## 9. Player-facing content per strike (what the player actually sees)

This is the "show, don't tell" layer. A strike must communicate these 6 facts **without reading text**:

1. **Whose turn** — who's glowing / whose pose is forward.
2. **What I picked** — gold-filled tile on my side.
3. **What they picked** — gold-filled tile on their side (revealed at t=80 ms).
4. **Was it a match** — gold or red ring flash.
5. **What the damage was** — the big number.
6. **Am I winning** — HP % delta visible on both bars.

All 6 must be delivered in ≤ 1.4 s. Anything extra (crit text, skill name, etc.) is bonus.

---

## 10. Telemetry events (reuse existing analytics table)

Add six event types to the existing `pvp/*` namespace:

| Event | Payload | Why |
|---|---|---|
| `pvp/strike/predict_shown` | battleId, strikeIndex, remainingMs=6000 | Attribution window open |
| `pvp/strike/choice_submit` | battleId, strikeIndex, auto:bool, msToSubmit | UI responsiveness |
| `pvp/strike/resolve_shown` | battleId, strikeIndex, outcome | Outcome distribution |
| `pvp/strike/skill_used` | battleId, strikeIndex, skillId | Skill popularity |
| `pvp/strike/disconnect` | battleId, strikeIndex, reason | Reliability |
| `pvp/fight/interactive_end` | battleId, totalStrikes, autoSubmits, winnerId | Session health |

---

## 11. Implementation order (when approved)

1. Backend: add 3 columns + 1 enum to `Battle` (`interactive_strike_index`, `interactive_timeout_at`, `interactive_hero_choices`, `status`). Migration + Prisma sync (both `backend/` and `admin/`).
2. Backend: `POST /pvp/strike` endpoint. Wraps the existing single-strike resolver (not a rewrite).
3. Backend: forfeit/timeout cron (re-uses existing scheduler).
4. iOS: `InteractiveBattleViewModel` (parallel to existing `BattleViewModel`, reuses all of its reward/ELO plumbing).
5. iOS: `PredictView` composed of existing stance-tile + skill-card components.
6. iOS: `RevealView` composed of existing HPBarView + damage popup + class pose assets.
7. iOS: feature-flag `interactive_combat_v1` (server-controlled) — rollout to 10 % → 50 % → 100 %.
8. Figma: screens go into `PalemJ36B97ZdC0cd8jzv4` (Screens file), components already exist in DS — no new DS work.

**File touch delta vs. status-quo codebase:** +3 columns, +1 enum, +1 endpoint, +2 iOS views, 0 new DS components, 0 new balance constants, 0 new economy SKUs.

---

## 12. Open questions (need Artem decision before implementation)

1. **Predict window duration:** 6 s default. Is that OK for a first-time player? (Tutorial flag could bump to 10 s for first fight.)
2. **Skill slot count:** 3 in predict UI. Do we want to show the 4th Ultimate slot grayed-out from day 1 (to seed the feature), or hide entirely until shipped?
3. **Auto-submit AI heuristic:** use opponent read strip (most-common attack zone) vs. pure random? Leaning toward the read strip — it's deterministic and teachable.
4. **Opponent is human or bot:** does the UI distinguish? Current thinking: no — bot is matched via ELO exactly like a human, and the Predict/Reveal flow is identical.
5. **Rematch ladder:** does REMATCH trigger a fresh matchmaking call or force the same opponent? Existing flow forces same opponent with ELO delta recomputed — we'd inherit that.

---

*End of spec. No code written. Review, mark questions, then we implement.*
