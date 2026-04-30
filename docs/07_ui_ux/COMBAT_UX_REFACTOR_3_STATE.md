# Combat UX Refactor — 3-State Flow (CHOOSE / RESOLVE / END)

**Status:** Proposal — review + prototype, not yet implemented.
**Owner:** Artem
**Date:** 2026-04-19
**Related:**
- `COMBAT_SCREEN_REDESIGN.md` (Variant B visual direction, shipped in prototype form)
- `STRIKE_REVEAL_SHAPE_B_PLAN.md` (round-reveal card shape)
- `prototypes/combat-3-state-flow.html` (this refactor's interactive prototype)
- Checked-in runtime context: `wiki/features/interactive-combat.md`, `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md`

---

## 0. Why this refactor

The combat screen today packs five decision contexts onto one frame:
round label, player pickers, opponent intent hint, previous round log card,
damage popups, active skill HUD, consumable banners, micro ticker,
timer-ring strike button, "your choice" badge, and the victory/summary view —
all mounted in the same `ZStack` with overlapping lifetimes.

The player's eye has to re-parse the screen every ~1.5s because *what the screen means* changes (choose → resolve → next choose) faster than the UI fades.

**Goal:** one screen = one job. State-driven, not layer-driven.

---

## 1. Current flow (abbreviated)

`InteractiveBattleView` is live. `CombatDetailView` is the legacy fallback.

**Existing `Phase` enum in `InteractiveBattleViewModel`:**

```
.intro → .predict → .resolving → .reveal → .summary → .completing → .finished(winnerId)
```

Plus `.unavailable` / `.error(message)` terminals.

Server is authoritative. Client ticks a 6s predict timer and auto-submits
`/pvp/strike` on expiry.

---

## 2. State-mixing problems (the real audit)

Eleven confirmed overlap spots, grouped by severity:

### Critical (break decision clarity)

**M1 — Pickers + Round Log Card co-mount.**
`InteractiveBattleView.swift:556–576`. When `currentExchange != nil` the round card slides in while the zone pickers are still in the tree. For ~250 ms both layers fight for the same vertical band.

**M2 — TimerRingStrikeButton ↔ YourChoiceButton swap.**
`InteractivePredictView.swift:592–610`. Driven by `currentExchange?.id`; `.easeInOut(0.25)` blend means both buttons briefly occupy the CTA slot.

**M3 — Opponent intent chip flip.**
`InteractiveCombatComponents.swift:295–298`. During predict the opponent ATK chip shows `.predicted("? CHEST")` based on a heuristic. After reveal it flips to `.confirmed("CHEST")` — on the same chip, same card, without remount. The player reads two different values at two different instants, thinking the system lied.

**M4 — Round strip persists through CHOOSE → RESOLVE.**
`InteractiveBattleView.swift:104–136`. "ROUND 3 — CHOOSE YOUR STRIKE" stays mounted during `.resolving` and `.reveal`. The label says "choose" while the picker has already submitted.

### High (noise, not confusion)

**M5 — Micro log ticker lifetime spans multiple phases.**
Entries have a 2.4s TTL (`InteractiveBattleView.swift:49`). Often the previous round's "YOU HIT CHEST 24" appears over the next round's picker.

**M6 — Active / Consumable fire banners persist into next round start.**
`InteractiveBattleView.swift:182–233`. Banner cleared only on `revealCompleted()`. Any layout delay stretches visibility.

**M7 — Damage popups float over the round log card.**
Separate lifecycle, 1s auto-clear, independent of the card's 2.4s timer. Two numbers-based UIs compete for the same attention budget at the same moment.

### Medium (hierarchy drift)

**M8 — Portrait outcome styling leaks into summary.**
`outcomeRole` (winner/loser glow) computed from `currentExchange?.verdict` persists while `BattleSummaryView` is scrolling. Portraits are still "OUTPLAYED" during the final recap.

**M9 — Stance chips always dual.**
Player chips show both ATK + DEF from the moment both are picked. On RESOLVE the same chip shape is reused to show what actually happened. No visual state change = no signal that the round is over.

**M10 — Round-log card tap-to-skip vs Skip vs Auto-dismiss.**
Three ways to advance + a countdown. Player doesn't know which action they just took.

**M11 — `predictPanel` slot is a polymorphic container.**
One `ZStack` hosts pickers, round card, summary view, and finished banner. Polymorphic by phase switch. Easy to break on a refactor; hard to reason about lifetime.

---

## 3. New architecture — 3 states

```
    CHOOSE  →  RESOLVE  →  (loop)  →  RESOLVE (finishing blow) →  END
    interactive   read-only                 freeze + crit                 summary + rewards
```

### Phase-enum mapping

| Current VM phase      | New UX state | Notes |
| --------------------- | ------------ | ----- |
| `.intro`              | Pre-CHOOSE splash / loading | Keep, unchanged. |
| `.predict`            | **CHOOSE**   | The only interactive combat decision state. |
| `.resolving`          | **RESOLVE** (server-waiting sub-substate) | Same view, zones locked, "RESOLVING…" copy. |
| `.reveal`             | **RESOLVE** (animating sub-substate) | HP animation, damage, crit/dodge/block. |
| (finishing blow flag) | **RESOLVE → finishing blow** | Freeze frame (opacity dim), verdict stamp, then auto-advance to END. |
| `.summary`            | **END**      | Victory / Defeat root view. |
| `.completing`         | **END** (awaiting server final snapshot) | Rewards placeholder → real values on resolve. |
| `.finished`           | **END** (final)  | Full rewards + Continue CTA. |
| `.unavailable` / `.error` | **END.error** | Already terminal. Unchanged. |

The VM's `Phase` enum does NOT need renaming. Add one derived property:

```swift
@MainActor
var uxState: CombatUXState {
    switch phase {
    case .intro:                    return .intro
    case .predict:                  return .choose
    case .resolving, .reveal:       return .resolve
    case .summary, .completing:     return .end(.awaiting)
    case .finished:                 return .end(.final)
    case .unavailable, .error:      return .end(.terminal)
    }
}
```

That keeps the network contract intact (zero risk on the backend/server side) while the view layer consumes one clean enum.

---

## 4. Per-state specs

### 4.1 CHOOSE

> One and only interactive combat frame. All decision-making lives here.

**Hierarchy, top to bottom:**

1. **Duel header** — both portraits, HP bars, name / level / class chip.
   - Player portrait: full saturation.
   - Enemy portrait: full saturation. *No* outcomeRole tinting in CHOOSE (there is no outcome yet).
   - HP bar is the strongest non-text element. Numbers read first.

2. **Round strip** — one line: `ROUND 3 · BO7` (or `ROUND 3 · FIRST BLOOD` for ranked). No verb. No CTA copy here.

3. **Stance summary strip** — compact single line:
   `You: ATK — · DEF — · Enemy: ATK 🔒 · DEF 🔒`
   Replaces "? CHEST" predicted heuristic. Shows lock icon while unknown. Flips to confirmed in RESOLVE only, never mid-CHOOSE.

4. **Attack picker** — three buttons Head / Chest / Legs in one row. Active card: gold border + full opacity + title color primary. Inactive: outline only + 60% opacity title.

5. **Defense picker** — same, below attack. Label "DEFEND".

6. **Active skills HUD** — below pickers. Unchanged component (`ActiveSkillsHUD`), but now always in CHOOSE (never in RESOLVE).

7. **Action bar (sticky bottom):**
   - Left: `SKIP` (secondary, tertiary emphasis).
   - Right: `STRIKE` with radial timer ring.
   - STRIKE disabled until both ATK and DEF selected. Disabled state = 40% opacity + tappable-but-shake-opacity feedback (no scale).

**Hidden in CHOOSE:**
- Round log card.
- Damage popups (there can't be any — no round has resolved yet).
- "YOUR CHOICE" badge. (Redundant with the picker's own active state.)
- Micro log ticker. (Belongs to RESOLVE context.)
- Fire banners. (RESOLVE only.)
- Enemy heuristic prediction chip. Replaced with lock icon.

**Timer rules:**
- 6.0s default, visible on STRIKE ring.
- When timer expires, VM still auto-submits (current behavior preserved). UX transitions to RESOLVE within the same frame.

**Selection state colors:**
- Selected attack: `DarkFantasyTheme.rarityLegendary` border (gold, already in use).
- Selected defense: `DarkFantasyTheme.bronze` border (differentiates ATK vs DEF at a glance).
- Both selected → STRIKE ring opacity 100% + timer colored gold.

### 4.2 RESOLVE

> Non-interactive. Shows what just happened. Only transient until next CHOOSE.

Two sub-substates: **awaiting** (server in-flight, <200 ms usually) and **animating** (HP tween + damage floats).

**Hierarchy:**

1. **Duel header** — same portraits, but:
   - HP bar animates from previous → new value over 700 ms (width tween, no scale).
   - Damage popups float up from the hit portrait. Max 2 concurrent (player + enemy). `translateY(-40) + opacity 1 → 0` over 900 ms. No scale grow.
   - Crit: 160 ms opacity pulse on duel frame border, gold tint.
   - Dodge/Miss: portrait opacity dim → restore over 220 ms, no movement.

2. **Result header (verdict chip)** — single compact chip, one of:
   - `BOTH HIT`
   - `YOU DODGED`
   - `ENEMY DODGED`
   - `CRITICAL`
   - `BLOCKED`
   - `OUTPLAYED` / `OUTREAD`

3. **Two result rows — exactly two lines, no more:**
   ```
   YOU    HEAD → CHEST   24 DMG
   ENEMY  LEGS → CHEST   10 DMG
   ```
   Typography: zone labels as uppercase spaced letters, numbers as large tabular figures. Number font weight heavier than label weight. This is the eye's anchor — it should read numbers in under 300 ms.

4. **Compact progress row:**
   - Left: `NEXT ROUND IN 2.4s` (non-ticking until count starts).
   - Right: small `SKIP` pill (secondary emphasis).

**Hidden in RESOLVE:**
- Zone pickers (removed from tree, not just hidden).
- STRIKE button.
- Active skills HUD row. (Replaced by the result block; HUD can return in CHOOSE.)
- Round strip "CHOOSE YOUR STRIKE" label.

**Transitions:**
- CHOOSE → RESOLVE: pickers fade out (160 ms opacity 0) in parallel with result card fade in (200 ms opacity 0→1, Y offset 12→0). No concurrent mount of pickers + result.
- RESOLVE → CHOOSE (next round): result card fade out (180 ms) finishes BEFORE pickers mount. Guarantees one focal area at all times.

**Active skill fire banner:**
- Shown ONLY during RESOLVE, in a dedicated slot below the result rows. Not floating over portraits.
- Auto-dismiss with the RESOLVE card.

### 4.3 END — Finishing blow + Victory/Defeat

**Finishing blow moment (pre-END):**

When the server response has `finishingBlow == true`, the RESOLVE state runs its normal animation, then:

1. 250 ms freeze frame (all HP/popup/banner opacity 0.4, except the loser portrait which stays 1.0 for two beats).
2. Verdict stamp appears (opacity fade, no scale): `ENEMY DEFEATED` or `YOU WERE DEFEATED`.
3. 600 ms hold.
4. Fade into END.

No scale pulse anywhere. Opacity + optional 6pt Y offset only.

**END — Victory hierarchy:**

```
┌─────────────────────────────┐
│        VICTORY              │  ← title, gold, large, opacity fade-in
├─────────────────────────────┤
│   REWARDS                   │  ← H2, count-up animation
│   +120 Gold                 │
│   +240 XP                   │
│   +24 Rank Points           │
│   Loot: Iron Blade (Common) │
├─────────────────────────────┤
│   OBJECTIVES                │  ← H3
│   ✓ Win in under 7 rounds   │
│   ✓ Land a critical         │
│   ☐ No damage taken         │
├─────────────────────────────┤
│   BATTLE STATS              │  ← H3, secondary text
│   Rounds: 5                 │
│   Crits landed: 2           │
│   Damage dealt: 412         │
│   Damage taken: 187         │
├─────────────────────────────┤
│         CONTINUE            │  ← sticky primary CTA
└─────────────────────────────┘
```

**Rules:**
- Rewards always above stats. Stats are secondary, muted text.
- One primary CTA. No "Rematch" / "Share" / "Claim" button competition. Those can live inside the next screen.
- XP bar fills with a 1.2 s count-up (opacity + width tween). No particle burst, no scale.
- Numbers count-up (not instant). This is the reward signal.

**END — Defeat hierarchy:**

Same structure, but:
- Title `DEFEAT` in muted red.
- Rewards section still shown — rank loss (negative), consolation XP. Honesty > hiding.
- Objectives still shown (some may be checked).
- Stats section identical.
- CTA: `CONTINUE` (same label; the next screen handles rematch / back / ranked flow).

**END — Error / Unavailable:**
Reuse error state already implemented. Not in scope of this refactor.

---

## 5. Component tree per state

### CHOOSE

```
CombatScreen(.choose)
└─ CombatRoot
   ├─ CombatBackgroundLayer (existing)
   │  ├─ CombatVFXOverlay
   │  ├─ CombatFXImageOverlay
   │  └─ CombatVerdictFlash (dormant in CHOOSE)
   ├─ DuelHeader
   │  ├─ DuelFighterCard(side: .player, outcomeRole: .neutral)
   │  └─ DuelFighterCard(side: .opponent, outcomeRole: .neutral)
   ├─ RoundStrip (label only, no verb)
   ├─ StanceSummaryStrip  ← NEW, replaces stance chips inside cards
   ├─ ChoosePhaseView  ← NEW view
   │  ├─ ZonePickerRow(.attack)
   │  ├─ ZonePickerRow(.defend)
   │  └─ ActiveSkillsHUD
   └─ ActionBar(.choose)
      ├─ SkipButton (secondary)
      └─ TimerRingStrikeButton (primary, disabled until both picked)
```

### RESOLVE

```
CombatScreen(.resolve)
└─ CombatRoot
   ├─ CombatBackgroundLayer (same)
   ├─ DuelHeader (HP animating)
   ├─ RoundStrip (label only)
   ├─ ResolvePhaseView  ← NEW view
   │  ├─ VerdictChip
   │  ├─ ResultRow(side: .player)
   │  ├─ ResultRow(side: .opponent)
   │  ├─ ActiveFireSlot (dedicated, not floating)
   │  └─ NextRoundCountdown
   └─ ActionBar(.resolve)
      └─ SkipSmallPill
```

### END

```
CombatScreen(.end)
└─ CombatRoot
   ├─ CombatBackgroundLayer (same)
   ├─ EndHeader  ← VICTORY / DEFEAT title
   ├─ DuelHeader (compact, muted, informational only)
   ├─ EndPhaseView  ← NEW view
   │  ├─ RewardsBlock
   │  │  ├─ GoldRow
   │  │  ├─ XPRow (count-up)
   │  │  ├─ RankPointsRow
   │  │  └─ LootRow (if any)
   │  ├─ ObjectivesBlock
   │  └─ BattleStatsBlock (secondary)
   └─ ActionBar(.end)
      └─ ContinuePrimaryButton
```

*`BattleSummaryView` is either retired or wrapped by `EndPhaseView`. See §7.*

---

## 6. Data contracts

What each state reads from `InteractiveBattleViewModel`. Nothing else.

### CHOOSE reads

- `phase == .predict`
- `currentRoundNumber`
- `state.playerProfile`, `state.opponentProfile`
- `state.playerHp`, `state.opponentHp` (raw, no tween)
- `selectedAttackZone`, `selectedDefendZone`
- `actives` (for HUD)
- `predictTimeRemaining` (for STRIKE ring)
- `canSubmit` (computed: both zones set && phase == .predict)

Writes: `selectedAttackZone`, `selectedDefendZone`, `submitStrike()`, `skipRound()`, `tapActiveSlot(index:)`.

### RESOLVE reads

- `phase in [.resolving, .reveal]`
- `currentExchange` (the `RoundExchange` struct the VM already builds)
- `lastTurn`, `lastOpponentTurn` (damage + zones)
- `lastOutcome` (verdict)
- `lastActiveFiredLabel`, `lastOpponentActiveFiredLabel`
- HP old → new values for tween (`previousPlayerHp`, `previousOpponentHp` need to be added to VM; trivial)

Writes: `skipResolve()` (alias for existing `dismissCurrentExchange()`).

### END reads

- `phase in [.summary, .completing, .finished, .unavailable, .error]`
- `matchOutcome` (won / lost / draw)
- `rewards` (from final `CombatData`: gold, xp, rankPoints, loot)
- `objectives` (from match meta)
- `stats` (round count, crits, damage totals — already in `battleLog`)

Writes: `continue()` (routes to result screen via existing router).

---

## 7. Files — keep / modify / add / retire

### Keep as-is (purely presentational)

- `YourChoiceButton.swift` — but stop using it in the new flow. Candidate for removal in a later sweep.
- `InteractiveCombatComponents.swift` — keep `TimerRingStrikeButton`, `ZoneChip`, `LogDivider`. Deprecate `StanceBonusChip.Mode.predicted` (no longer needed).
- `ActiveSkillsHUD.swift` — unchanged component, new mount point.
- `InteractiveRoundLogCard.swift` — superseded by `ResolvePhaseView`. Keep file during migration for visual comparison; delete after cut-over.
- `CombatVFXOverlay.swift`, `CombatFXImageOverlay.swift`, `CombatVerdictFlash.swift` — unchanged; mounted in `CombatBackgroundLayer`.
- `CombatDetailView.swift` — legacy fallback, untouched.
- `CombatResultDetailView.swift`, `LootDetailView.swift` — post-combat routes, untouched.

### Modify

- `InteractiveBattleView.swift` — root view becomes a thin `switch uxState { }` on three child views. Extracts `DuelHeader` + `CombatBackgroundLayer` as outside-the-switch stable mounts.
- `InteractiveBattleViewModel.swift` — add:
  - `uxState: CombatUXState` computed property
  - `canSubmit: Bool` computed
  - `previousPlayerHp`, `previousOpponentHp: Int` for RESOLVE HP tween
  - `currentRoundNumber: Int` already exists; just expose to root.
  - No rename of `Phase` cases. No breaking change to persistence or network contracts.
- `BattleSummaryView.swift` — either:
  - Option A: retire, replaced by `EndPhaseView` + `RewardsBlock` + `BattleStatsBlock`.
  - Option B: rename to `EndBattleStatsBlock` and mount inside `EndPhaseView` as the secondary stats section. **Recommended: Option B** — preserves the already-shipped full-battle-log collapsible component as a nested block.

### Add (new files)

- `Views/Combat/State/CombatUXState.swift` — enum + computed property.
- `Views/Combat/State/ChoosePhaseView.swift`
- `Views/Combat/State/ResolvePhaseView.swift`
- `Views/Combat/State/EndPhaseView.swift`
- `Views/Combat/Shared/DuelHeader.swift` — extract from `InteractiveBattleView`.
- `Views/Combat/Shared/StanceSummaryStrip.swift`
- `Views/Combat/Shared/ActionBar.swift`
- `Views/Combat/Shared/VerdictChip.swift`
- `Views/Combat/Shared/ResultRow.swift`
- `Views/Combat/End/RewardsBlock.swift`
- `Views/Combat/End/ObjectivesBlock.swift`
- `Views/Combat/End/BattleStatsBlock.swift`  (renamed from `BattleSummaryView` internals)
- `Views/Combat/End/EndHeader.swift`

All new files must be added to `project.pbxproj` in four places (`PBXBuildFile`, `PBXFileReference`, `PBXGroup.children`, `PBXSourcesBuildPhase.files`) with unique random hex IDs.

### Retire (after cut-over)

- `InteractiveRoundLogCard.swift` — fully replaced by `ResolvePhaseView`.
- `YourChoiceButton.swift` — no longer used.
- `CombatLogRow.swift` — replaced by `ResultRow`. *(Verify no other caller via repo-wide grep before delete.)*

---

## 8. Transitions — explicit frame budget

| From       | To         | Duration | Type                         | Concurrency |
| ---------- | ---------- | -------- | ---------------------------- | ----------- |
| CHOOSE     | RESOLVE    | 160 ms   | opacity 1→0 (pickers), 200 ms opacity 0→1 + y +12 (resolve) | Serial: pickers must reach 0 before resolve starts (overlap of 40 ms only) |
| RESOLVE    | CHOOSE     | 180 ms   | opacity 1→0 (resolve), 160 ms opacity 0→1 (pickers) | Serial |
| RESOLVE    | END        | 250 ms freeze + 600 ms hold + 320 ms cross-fade | opacity only + verdict stamp fade | One-way, cannot interrupt |
| ANY        | ERROR      | 120 ms   | opacity 0→1 error card        | Replaces body only; background stays |

**No scale transforms anywhere.** Opacity and position-only motion.

---

## 9. Edge cases

1. **Server slow on `/strike`** — RESOLVE sub-substate `.awaiting`. Shows verdict chip as "RESOLVING…" spinner row. After 800 ms, show a subtle "Connection slow" hint. Never show pickers during wait.

2. **Finishing blow on first round (one-shot)** — Still play RESOLVE with damage numbers, then freeze, then END. Don't skip RESOLVE even if HP reaches 0 from full.

3. **Both HP = 0 (simultaneous KO)** — Verdict chip: `MUTUAL DEFEAT`. END uses draw layout: no VICTORY/DEFEAT title; "DRAW" title, rewards split per server rules.

4. **Skip during RESOLVE** — Fast-forwards remaining animation to end values. Transitions to next CHOOSE immediately. Does not re-fire VFX.

5. **Skip during CHOOSE (user intent: forfeit round)** — Confirms via short confirmation micro-sheet "Skip this round? Enemy strikes freely.". Yes → submit with zero zones. Matches current server contract if it accepts null zones; otherwise call existing `skipRound()`.

6. **Active skill fires during RESOLVE** — Dedicated slot (not floating). Opacity fade only. Auto-dismiss with RESOLVE card.

7. **Enemy disconnects** — Server returns `.unavailable`. END.terminal state. CTA: `CONTINUE` routes to lobby.

8. **VFX anchor positions shift** — `DuelHeader` is mounted outside the state switch, so anchor preferences report stable coordinates. VFX manager continues to work without changes.

9. **Haptics already wired** — Keep `HapticManager` hooks in `applyStrikeResponse()`. No UI-layer changes needed.

10. **Reduced motion accessibility** — If `UIAccessibility.isReduceMotionEnabled`, collapse all transition durations to 0 ms and show instantly. No parallax, no Y offset, no count-up.

---

## 10. QA checklist (pre-merge)

- [ ] STRIKE disabled state visible (40% opacity title + lock feel).
- [ ] STRIKE enabled only when both zones picked.
- [ ] No scale grow/shrink on any element (grep `.scaleEffect`, `.scale`).
- [ ] No prev-round info visible during CHOOSE of the next round.
- [ ] No pickers visible during any RESOLVE frame.
- [ ] HP bar tween uses width, not transform.
- [ ] Damage popup uses translateY + opacity only.
- [ ] Verdict stamp uses opacity fade only.
- [ ] Rewards block appears above stats block in END.
- [ ] One primary CTA in END.
- [ ] `uxState` computed from `phase` only; no duplicate state.
- [ ] `DuelHeader` mounted outside state switch (VFX anchors stable).
- [ ] `project.pbxproj` updated for every new Swift file (4 sections × random hex IDs).
- [ ] `ReduceMotion` honored.
- [ ] Classic combat (`CombatDetailView`) fallback still works — `InteractiveBattleRouteView` unchanged.
- [ ] Server contract unchanged — verified by running `python3 scripts/check_schema_drift.py` (no-op here; ensures no accidental schema touch).

---

## 11. Rollout plan

1. **Behind feature flag** — `CombatUXV2` (default off). Kept in remote config + local toggle in DevSettings. Flag checked at `InteractiveBattleRouteView` level: when on, mount new screen; when off, mount current `InteractiveBattleView`. Gives a 1-tap instant rollback.
2. **Dogfood on internal build** — Artem solo matches, 30+ rounds. Watch for state-mixing regressions and VFX anchor drift.
3. **Staged rollout** — 5% → 25% → 100% over a week.
4. **Cleanup PR** — after 100% soak, delete retired files, flip flag default on, remove flag branch.

See `docs/10_operations/DEPLOY.md` for deploy path and `backend/CLAUDE.md` for schema-sync note (not applicable here — no schema change).

---

## 12. Success criteria

- Visual noise: measured by count of simultaneously-opacity>0 top-level sub-views on the combat screen. Current peak: 9. Target: ≤5 at any frame.
- Time-to-decide (internal metric): median time from CHOOSE enter to STRIKE tap. Target: reduce by 15% vs. current baseline.
- Round log re-parse: zero. The player never has to match "which round is this result from?".
- No new crash reports within one week of 100% rollout.

---

## 13. Non-goals

- Redesigning individual attack zone icons (kept from current DS).
- Changing server tick rate or round duration.
- Replacing VFX particles / crit effects.
- Adding new combat mechanics (no gameplay change).
- Redoing `CombatResultDetailView` (post-combat route, separate scope).

---

## Appendix A — Wire prototype

See `prototypes/combat-3-state-flow.html`. Open in browser, resize to ~390×844 (iPhone viewport). Controls on the prototype let you step through CHOOSE → RESOLVE → Finishing blow → END, and between Victory / Defeat.

## Appendix B — Decision log

- **Why merge `.resolving` and `.reveal` into one RESOLVE state** — From the player's mental model they're one event ("I pressed strike, now I see what happened"). Splitting them into separate screen behaviors causes mount/unmount thrash.
- **Why keep the `Phase` enum intact** — Backend contract alignment. Also, `uxState` is cheaper to introduce as a derived property than to rename cases across the VM.
- **Why retire `InteractiveRoundLogCard` instead of evolving it** — Its component contract embeds auto-dismiss + skip + countdown + allyEvents/enemyEvents. New RESOLVE wants different layout (2 lines max, verdict chip, dedicated fire slot). A rewrite is cleaner than a refactor.
- **Why Option B for `BattleSummaryView`** — The collapsible full-round-by-round recap shipped in Phase 3 is worth keeping as an optional "view full log" affordance inside END. Nesting avoids losing it.
