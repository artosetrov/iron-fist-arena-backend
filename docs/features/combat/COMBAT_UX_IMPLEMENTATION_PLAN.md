# Combat Screen v2 — Implementation Plan

> **Status:** Superseded by `COMBAT_V3_IMPLEMENTATION_PLAN.md`. Keep as v2 decision history.
> **Historical note:** the exploratory `combat-proto-B2.html` was removed during later repository cleanup; this plan remains as the retained record of that direction.
> **Audit:** `COMBAT_UX_AUDIT.md`
> **Date:** 2026-04-14

---

## 1. TL;DR

The redesign is **90% re-layout, 10% new data**. All the hard pieces — opponent-actives data flow, fire banner, cooldown ticking, HP sync, VFX anchors — already exist from Phase 3.B. We're re-composing the same VM surface into a cleaner view.

**Big wins** the redesign unlocks without touching the backend:
- Kills the duplicate stance readout (`zoneBadgesRow` goes away).
- Moves opponent actives into the enemy fighter card (already rendered, just relocated).
- Slams the fire banner over the enemy portrait for kinetic feedback.
- Replaces the disconnected `PredictTimerBar` with a radial ring fused to STRIKE.

**One new data input** required: an **enemy-intent hint** (e.g. "Likely Chest"). Backend either derives from opponent's last round or exposes a class-tendency hint; see Open Q1.

## 2. What already exists (reuse, don't rebuild)

| Existing component / VM field | Current job | In v2 |
|---|---|---|
| `InteractiveBattleViewModel` | Phase machine, timer, actives, fire labels, HP | **Unchanged.** Same surface powers v2. |
| `DuelFighterCard` (inside `InteractiveBattleView.swift`) | Portrait + name + HP + flash + popups | **Extract to own file**, add params for stance overlay, intent hint, actives strip, fire banner slot. |
| `ActiveSkillsHUD` | 5-slot player active bar with cooldowns | **Reuse as-is** in the new "Talents" row under the stance picker. |
| `OpponentActivesPreview` | 3-icon mini opponent actives strip | **Reuse**, relocate into enemy `DuelFighterCard`. |
| `ActiveFireBanner` | "BURST DAMAGE" banner for fires | **Reuse**, relocate to overlay enemy portrait (player fires overlay player portrait). |
| `HPBarView` | Compact HP bar | **Unchanged.** |
| `PrimaryButtonStyle` / `SecondaryButtonStyle` | Gold CTA / outline ghost | **Reuse**, plus new `TimerRingButtonStyle` on top of `PrimaryButtonStyle`. |
| `CombatVFXOverlay`, `CombatFXImageOverlay` | Slash / crit / shield | **Unchanged.** Anchors already wired via `FighterAnchorKey`. |

Net: we are deleting more code than we are writing.

## 3. What's new

| New artifact | Where | Why |
|---|---|---|
| `StanceOverlay` | `Views/Combat/` | Attack gold-glow + Defend blue-ring pinned to body zones on portrait |
| `TimerRingButtonStyle` (+ wrapper `TimerRingStrikeButton`) | `Theme/ButtonStyles.swift` (or sibling) | Radial timer arc around a gold primary button, danger state when <1.5s |
| `FighterStatusChip` (streak / gear score) | `Views/Combat/` | Small row between picker and CTA |
| `EnemyIntentPill` | `Views/Combat/` | Telegraph pill inside enemy portrait |
| `InteractiveBattleView+Layout` | Split of current file | Cleanup — host file > 680 lines |

All new components must land in **both** Swift and Figma DS per the sync rule.

## 4. Delta — what changes structurally

```
BEFORE (current layout)                 AFTER (Variant B2)
──────────────────────────────────────  ──────────────────────────────────────
[ YOU | ENEMY ]  portraits side-by-side [ YOU | ENEMY ] portraits side-by-side
                                          + stance glow overlays on portraits
                                          + enemy intent pill
                                          + enemy actives strip (3 mini)
                                          + fire banner slot
[ YOU  Attack box  Defend box ]         (deleted — duplicate, ownership unclear)
[ FOE  Attack box  Defend box ]         (deleted)
[ fire banner inline row ]              (moved to overlay enemy/player portrait)

[ CHOOSE YOUR STANCE · ───── · 3.4s ]   (deleted — timer fuses to STRIKE)

[ ACTIVE SKILLS ]  player HUD           [ TALENTS ] player HUD row
                                        (same component, moved just under picker)

[ ATTACK  Head Chest Legs ]             [ ATTACK  Head Chest Legs ]  (unchanged)
[ DEFEND  Head Chest Legs ]             [ DEFEND  Head Chest Legs ]  (unchanged)

                                        [ Streak ×3      Gear Score 1240 ]  NEW
[ STRIKE (left) · SKIP (right) ]        [ SKIP (left) · STRIKE + timer ring (right) ]
```

## 5. Phased delivery

Phases are designed so each one **ships independently** — if we stop after any phase, main is shippable and better than today.

### Phase 0 — Figma DS prep · ~1h
- Add new components to `Hexbound-DS`:
  - `Timer Ring Button` (Default / Pressed / Disabled / Danger variants)
  - `Stance Overlay` (Head / Chest / Legs × Attack / Defend = 6 variants)
  - `Enemy Intent Pill` (Head / Chest / Legs × probability hi/med/lo)
  - `Fighter Status Chip` (Streak / Gear Score variants)
- All bound to `Color`/`Spacing` variables, text tied to `Heading/*` + `Body/*` styles, `Shadow/Card` on root. Run the audit script from `FIGMA_SCREEN_RULES.md` Rule 7.
- **Skill to invoke:** `cc-figma-component` (requires `cc-figma-tokens` already run — it is).

### Phase 1 — Figma screen in `Hexbound-Design` · ~1-2h
- Build **`Combat / Interactive / v2`** frame using only DS components above + existing `Duel Fighter Card` instance.
- Produce 3 states of the same frame: *Predict · Resolving · Final ≤1.5s (danger)*.
- No hardcoded values. Audit must pass.
- **Skill to invoke:** `figma-generate-design` + `figma-use`.

### Phase 2 — Swift component extraction · ~2h
Extract into `Views/Combat/Cards/`:
- `DuelFighterCard.swift` — lift from `InteractiveBattleView.swift`, expand API:
  ```swift
  DuelFighterCard(
    side: .player | .enemy,
    profile: FighterProfile?,
    hp: (current: Int, max: Int),
    stancePicks: StanceOverlayData?,     // NEW
    intent: EnemyIntentHint?,            // NEW (enemy only)
    opponentActives: [ActiveSlotView]?,  // NEW (enemy only)
    fireBanner: ActiveFireLabel?,        // NEW
    slideX: CGFloat, flash: Bool, popups: [DamagePopup]
  )
  ```
- `StanceOverlay.swift` — zone glow + shield ring.
- `TimerRingStrikeButton.swift` + `TimerRingButtonStyle` — radial arc around `PrimaryButtonStyle`.
- `FighterStatusChip.swift` — streak/gear pill.

Register every file in `project.pbxproj` (4 sections each, unique random 24-char hex IDs).

### Phase 3 — Recompose `InteractiveBattleView` · ~1.5h
- Delete `zoneBadgesRow`, `stanceSideLabel`, `ZoneBadge`, `PredictTimerBar` structs (moved or obsolete).
- `InteractivePredictView` slims to: *Talents row → Attack picker → Defend picker → Status chip → SKIP + Strike(timer)* .
- `InteractiveBattleView.body` becomes: *Duel header → Spacer → PredictPanel*.
- Fire-banner routing: VM's `lastOpponentActiveFiredLabel` → enemy `DuelFighterCard`; `lastActiveFiredLabel` → player `DuelFighterCard`.
- `prefers-reduced-motion` honoured: timer ring uses CA, not explicit scale; pulse on critical uses opacity only.

### Phase 4 — Enemy intent hint · ~1-2h (backend + client)
- **Backend:** add `opponentIntentHint` to the `/pvp/match/start` or `/tick` response. V1 heuristic: last-round stance, or null if first round. V2 could factor class tendency. Feature-flag it.
- **Client:** read into VM; render via `EnemyIntentPill`. If null, hide pill (no empty frame).
- Server-authoritative — no client-side prediction.
- Migration: none. New optional field.

### Phase 5 — QA + polish · ~1h
- Run the VM's **TutorialFight** through the new view (`TutorialFightView` shares the VM) — confirms tutorial still works.
- Playtest matrix: 5 rounds × {player fires / opponent fires / both fire / neither} × {critical timer / strike before timer}.
- Screenshots of all 3 phase states on iPhone 15 Pro + iPhone SE (smallest safe size).
- Run `scripts/check_design_system.sh`, the CDO verification block, and `hexbound-studio:mirror` (UX audit of final screen).

### Phase 6 — Ship · ~30m
- `hexbound-studio:gatekeeper` preflight
- `hexbound-studio:herald` deploy
- Watch `/pvp/match/*` metrics for 24h (strike submit rate, skip rate, avg decision time). Artem pings if anything moves.

## 6. Risks + mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Timer ring performance on older devices | Med | Med | Use `Canvas` once/60 or `TimelineView` at 30 Hz; skip redraw when frac delta <1% |
| Fire banner overlaps damage popups | Med | Low | Z-stack banner above popups but below VFX; 1.4s timeout, 0.3s fade |
| Extracting `DuelFighterCard` breaks VFX anchors | Med | High | Keep `FighterAnchorKey` preference emission inside the extracted card; add UI test covering anchor publish |
| Enemy intent shipped before backend ready | Low | Med | Phase 4 is optional — ship Phases 0-3 without intent, add as a follow-up |
| Tutorial flow regression | Med | High | `TutorialFightView` reuses `InteractiveBattleViewModel` + view — always smoke-test tutorial as part of Phase 5 |
| Opponent-actives layout in enemy card squeezes HP bar | Med | Low | Lock card min-height via `LayoutConstants`; cap mini-slots at 3 |
| Figma screens file drifts from Swift | High if sloppy | Med | Keep Swift and the retained design artifacts synchronized whenever the visual branch changes |

## 7. Agents I'll route through

| Phase | Agent / Skill | Why |
|---|---|---|
| 0 | `cc-figma-tokens`, `cc-figma-component` | Figma DS additions |
| 1 | `figma-generate-design`, `figma-use`, `hexbound-studio:blueprint` | Screen build + DS compliance |
| 2 | `hexbound-studio:screen` (SwiftUI reviewer) | Extraction quality |
| 3 | `hexbound-studio:flow`, `hexbound-studio:bladework` | UX clarity + combat-design sign-off |
| 3 | `hexbound-studio:pulse` | Motion/feedback review (timer ring, fire banner) |
| 4 | `hexbound-studio:engine`, `hexbound-studio:server` | Intent hint implementation |
| 5 | `hexbound-studio:mirror`, `hexbound-studio:gauntlet` | Final UX audit + playtest |
| 5 | `accessibility-audit` | WCAG pass on final screen |
| 6 | `hexbound-studio:gatekeeper`, `hexbound-studio:herald` | Preflight + ship |

## 8. Open questions — need Artem's call before Phase 0

1. **Enemy intent source.** Options:
   a. *Last-round heuristic* — show "Likely Chest" if opponent attacked Chest last round (server pass-through). Cheap, ships this week.
   b. *Class-tendency + last-round* — weighted hint per class archetype. ~3 days work.
   c. *Hide intent v1*, revisit post-launch. Safest.
   **My recommendation: a.** Ship the UI with the hint visible, backend returns null for first round. Upgrade to b later.

2. **Opponent active loadout: revealed or fog-of-war?**
   a. *Revealed from round 1* (current prototype). Mindgame depth, counter-play obvious.
   b. *Fog-of-war* — `?` until they fire. Surprise, but less readable.
   **My recommendation: a.** Matches "Raid" pattern, supports the telegraph loop.

3. **SKIP semantics.** Keep as "no strike this round, opponent strikes free" — or add a small benefit (stamina regen, partial parry)?
   **My recommendation:** keep current semantics for now; separate balance pass with `hexbound-studio:bladework` after ship.

4. **Round counter / best-of-N indicator.** The prototype shows "Round 3 · Best of 5". Actual match model has no round cap today — strikes continue until someone's HP = 0. Do we want a soft round counter for information, or is it misleading?
   **My recommendation:** replace with "Strike #N" or `vm.state.strikes.count` — honest and already in the VM.

5. **Streak · Gear Score chip.** Is streak "wins in a row in this match" or "across matches"? Gear Score — display both or just player's?
   **My recommendation:** streak = current win run across matches (retention hook), gear score = player's only (clutter otherwise).

## 9. Effort estimate

| Phase | Hours | Can parallelize? |
|---|---|---|
| 0 — Figma DS | 1 | No (blocks screen) |
| 1 — Figma screen | 1-2 | No |
| 2 — Swift components | 2 | Partial (4 files in parallel) |
| 3 — Recompose view | 1.5 | No |
| 4 — Intent hint | 1-2 | Yes (backend + client in parallel) |
| 5 — QA + polish | 1 | No |
| 6 — Ship | 0.5 | No |
| **Total** | **8-10h** | |

Roughly a 1.5-day push. Phases 0-3 alone (~6h) already deliver 80% of the value without touching backend.

## 10. Files

- Historical Prototype B2 — later removed during repository cleanup; this plan remains as the retained record of that approved direction
- [UX Audit](COMBAT_UX_AUDIT.md)
- Original A/B/C comparison — historical launcher removed during later repository cleanup
- Current code: `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift`, `ActiveSkillsHUD.swift`, `InteractiveBattleViewModel.swift`
