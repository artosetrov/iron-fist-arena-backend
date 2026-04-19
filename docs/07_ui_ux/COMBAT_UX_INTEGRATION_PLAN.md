# Combat 3-State Refactor — Integration Plan

**Status:** Draft. Execute only after Artem approves `COMBAT_UX_REFACTOR_3_STATE.md` and the prototype `prototypes/combat-3-state-flow.html`.
**Date:** 2026-04-19
**Guiding rule (memory: `feedback_review_before_code.md`):** no implementation until design approved.

The idea of this doc is **"не что не слобать"** — safe landing for a refactor that touches the live interactive battle.

---

## 0. Invariants (do not break)

1. `InteractiveBattleViewModel.Phase` cases and their transitions stay identical. Network contracts with `/pvp/match/start`, `/pvp/strike`, `/pvp/match/complete` unchanged.
2. `InteractiveBattleRouteView` wrapper — unchanged (it wires VM → AppRouter terminals).
3. VFX anchor preferences — `DuelHeader` mounted outside the state switch, so anchor coordinates stay identical.
4. `CombatDetailView` legacy path — not touched.
5. `project.pbxproj` — every new `.swift` file added to 4 sections (`PBXBuildFile`, `PBXFileReference`, `PBXGroup.children`, `PBXSourcesBuildPhase.files`) with **random hex IDs** (memory: `feedback_pbxproj_unique_ids.md`).
6. No scale animations anywhere (memory: `feedback_no_scale_animations.md`). Opacity / width / Y-translate only.
7. DarkFantasyTheme tokens only — no raw `Color(hex:)` (memory: `reference_darkfantasytheme_color_tokens.md`).
8. Reusability first — never duplicate UI (memory: `feedback_reusability_first_rule.md`).
9. English-only copy in any artifact (memory: `feedback_english_only.md`).
10. Never git commit from sandbox — use `.git-trigger` for git-watcher on Mac (memory: `feedback_deploy_via_tmp_clone.md`).

---

## 1. Feature flag

**Name:** `combatUXV2`
**Default:** `false`
**Location:** `AppState` or `RemoteConfig`, same pattern used for prior combat flags (ref: `project_pvp_fight_routing_shipped.md` — the `locallyDisable` flag precedent).

**Gate point:** `InteractiveBattleRouteView.body`

```swift
Group {
    if appState.combatUXV2 {
        InteractiveBattleV2View(vm: vm)
    } else {
        InteractiveBattleView(vm: vm)   // current live
    }
}
```

**One-tap rollback** — flip the flag off in DevSettings. No deploy required.

---

## 2. PR sequence (7 PRs, strict order)

Each PR must be independently shippable (flag off → no behaviour change).

### PR-1 · Foundation types + shared layer

**Scope (minimal risk):**

- `Views/Combat/State/CombatUXState.swift` — enum + case carries `end(CombatEndPhase)`.
- `Views/Combat/Shared/DuelHeader.swift` — verbatim extraction of the current `DuelFighterCard` pair from `InteractiveBattleView` (lines 407–547). No logic change.
- `Views/Combat/Shared/ActionBar.swift` — pure layout container, Skip + CTA slot.
- Add `uxState`, `canSubmit`, `previousPlayerHp`, `previousOpponentHp` to VM (all derived / new properties only, no behavior change).

**Tests:**

- Unit: `CombatUXState` mapping from each `Phase` case.
- Snapshot: `DuelHeader` isolated preview matches current `InteractiveBattleView` visual.

**Ship condition:** build passes, snapshot diffs empty.

### PR-2 · Empty V2 view scaffold

- `Views/Combat/InteractiveBattleV2View.swift` — root view that mounts `DuelHeader` + a `switch uxState { }` with three empty placeholder views. Wires `DuelHeader` anchor preferences to existing VFX manager.
- `Views/Combat/State/ChoosePhaseView.swift` — placeholder "CHOOSE".
- `Views/Combat/State/ResolvePhaseView.swift` — placeholder "RESOLVE".
- `Views/Combat/State/EndPhaseView.swift` — placeholder "END".
- Feature flag hook in `InteractiveBattleRouteView`.
- Flag still default off.

**Tests:** Manual — flag on, scaffold loads, VFX anchors report same coords as V1. Verify via print-diff side by side.

### PR-3 · CHOOSE state

- Fill `ChoosePhaseView` with:
  - `StanceSummaryStrip` (new, replaces dual chip stacks inside fighter cards).
  - Zone picker rows (attack / defend) — reuse existing `ZoneChip` (from `InteractiveCombatComponents.swift`).
  - `ActiveSkillsHUD` mount (unchanged component).
- Action bar wires `SkipButton` + `TimerRingStrikeButton`.
- Strike disabled until `vm.canSubmit`.

**Risk:** timer auto-submit must still fire when `predictTimeRemaining <= 0`. Keep the VM side effect in place.

**Tests:**

- Manual: flag on, enter battle, pick ATK + DEF, Strike enables. Pick only ATK → Strike stays disabled.
- Manual: no pick at all, timer expires → auto-submit fires as expected.
- Manual: VFX anchors confirmed via debug overlay (temp print).

### PR-4 · RESOLVE state

- Fill `ResolvePhaseView`:
  - `VerdictChip` (new).
  - Two `ResultRow` rows (new, replaces `CombatLogRow` usage inside combat screen).
  - Dedicated fire slot (not floating over portraits).
  - Next-round countdown + small Skip pill.
- Use `currentExchange` fields directly: `allyEvents` / `enemyEvents` collapsed into one-line zone + damage summary each.
- HP tween from `previousPlayerHp` → `state.playerHp` (700 ms width-only transition).
- Damage popup overlay anchored to fighter cards: `translateY + opacity` only.
- Hook haptics on verdict chip mount (reuse existing `HapticManager` call site in `applyStrikeResponse`).

**Risk:** the VM's `animateReveal` currently owns the damage popup lifecycle. That can stay — the new `ResolvePhaseView` just reads `damagePopups` array from VM.

**Tests:**

- Manual: run 5 rounds. No pickers visible during RESOLVE. Numbers read before labels. Crit flash opacity-only. Skip pill advances.
- Instruments: verify no `scaleEffect` calls in Resolve subtree.

### PR-5 · END state

- Fill `EndPhaseView`:
  - `EndHeader` with `VICTORY` / `DEFEAT` title.
  - Compact `DuelHeader` variant (use `.compact = true` prop — already exists on `DuelFighterCard`).
  - `RewardsBlock` — gold / XP / rank / loot.
  - `ObjectivesBlock`.
  - `BattleStatsBlock` — rename of `BattleSummaryView` internals; keeps the collapsible full-round log as a secondary reveal.
- Count-up animation for gold / XP / rank (opacity-safe — width for XP bar, numeric setState for counters).
- One primary `CONTINUE` CTA.

**Data plumbing:** pull rewards from final `CombatData` via router wrapper (already available in `InteractiveBattleRouteView`). Keep the existing navigation sequence: finish → `appState.combatResult` → push `.combatResult` route.

**Risk:** the existing `BattleSummaryView` is currently mounted in the same `predictPanel` slot as pickers. In V2 this is a separate, top-level state view — no overlap with pickers possible.

**Tests:**

- Manual Victory: rewards > stats visual hierarchy. Count-up fires once. Continue routes correctly.
- Manual Defeat: negative rank shows. Same Continue path.
- Manual Draw (mutual KO): title `DRAW`. Rewards split per server.

### PR-6 · Finishing blow polish

- Insert freeze-frame overlay on `finishingBlow == true` response.
- Verdict stamp fade.
- Auto-advance to END after 1100 ms total.
- Match the prototype exactly — no pulsing, no scale.

**Tests:** manual — force finishing blow via cheat ability or test opponent; verify stamp + dim + auto-advance.

### PR-7 · Cleanup + flag flip

**Only after 1 week of soak at 100% rollout:**

- Flip `combatUXV2` default to `true`.
- Delete:
  - `Views/Combat/InteractiveBattleView.swift` (V1 root).
  - `Views/Combat/InteractivePredictView.swift`.
  - `Views/Combat/InteractiveRoundLogCard.swift` (replaced by ResolvePhase).
  - `Views/Combat/YourChoiceButton.swift` (no callers after V2).
- Rename `InteractiveBattleV2View` → `InteractiveBattleView`.
- Update `InteractiveBattleRouteView` to remove the flag branch.
- Remove feature flag from config.
- Run `python3 scripts/check_schema_drift.py` (no-op, safety net).

**Per memory `feedback_check_all_callers.md`:** before deleting each file, `grep -rn` for its type/file name across the whole repo (backend, admin, tests, Figma Code Connect maps). Confirm zero references outside the retired path.

---

## 3. Migration safety checklist (per PR)

| Check | Command / action |
| ----- | ---------------- |
| No scale animations | `grep -rn "scaleEffect\\|\\.scale(" Hexbound/Hexbound/Views/Combat` — must be empty in new files |
| DS tokens only | `grep -rn "Color(hex:" Hexbound/Hexbound/Views/Combat/State` — must be empty |
| pbxproj updated | open project, build — new files must compile. Use `ruby -e` or `openssl rand` for unique hex IDs |
| No state-mixing | inspect View tree in Xcode Previews — pickers must not co-exist with resolve card |
| VFX anchors | temp-print anchor coords in `DuelHeader.onPreferenceChange` — compare V1 vs V2, diff ≤ 1 pt |
| English copy | skim each new view file — no Russian/other strings |
| Reduce motion | UIAccessibility toggle → all transitions collapse to 0 ms |
| Haptics wired | verify haptic fires on verdict chip mount (RESOLVE) and on Continue (END) |
| Classic fallback | toggle `locallyDisableInteractive` flag → legacy `CombatDetailView` still works |

---

## 4. Risk log

| Risk | Likelihood | Mitigation |
| ---- | ---------- | ---------- |
| VFX positions drift after layout change | Medium | Keep `DuelHeader` mounted outside state switch; add anchor-coordinate parity test |
| Auto-submit timer breaks on pickers unmount | Medium | Timer lives on VM, not on view. ChoosePhaseView just displays `vm.predictTimeRemaining`. Unmount of view does not cancel VM's `Task` |
| Haptics misfire on extra mount/unmount cycles | Low | Use `.onAppear` with a guard flag `didFireVerdictHaptic` |
| pbxproj merge conflicts on 14 new files | High (if multiple people touch project) | Batch all PR-3/4/5 pbxproj additions into one group; randomize IDs via script `./scripts/xcode-new-files.sh` |
| Damage popup overflow outside portrait card | Low | Clip disabled on portrait container; verify with DebugView |
| Backend sends finishingBlow flag but HP > 0 | Low | Trust server flag over client HP comparison for EN transition |
| Player taps Continue twice, routes twice | Medium | Debounce via `isDismissing` flag on button; route call guarded |
| `animateReveal` single-flight guard conflicts with V2 view lifecycle | Medium | Add VM-level guard: ignore duplicate `onAppear` of ResolvePhaseView if already animating |
| `BattleSummaryView` rename breaks external code | Low | grep for all `BattleSummaryView(` call sites before rename |

---

## 5. Rollout timeline (suggested)

| Day | Step |
| --- | ---- |
| D0 | PR-1 merged (foundation types), flag off. |
| D1 | PR-2 merged (V2 scaffold), flag off. |
| D2-3 | PR-3, PR-4 (CHOOSE + RESOLVE) — internal dogfood with flag on locally. |
| D4 | PR-5 (END). |
| D5 | PR-6 (Finishing blow polish). |
| D6 | Internal matches 30+ rounds. Watch VFX parity + state-mix regressions. |
| D7 | Flag on 5% of users (remote config). |
| D10 | 25% rollout. |
| D14 | 100% rollout. |
| D21 | PR-7 (cleanup + flag removal). |

---

## 6. Files — touched summary

### New (14 files)

```
Views/Combat/State/CombatUXState.swift
Views/Combat/State/ChoosePhaseView.swift
Views/Combat/State/ResolvePhaseView.swift
Views/Combat/State/EndPhaseView.swift
Views/Combat/Shared/DuelHeader.swift
Views/Combat/Shared/StanceSummaryStrip.swift
Views/Combat/Shared/ActionBar.swift
Views/Combat/Shared/VerdictChip.swift
Views/Combat/Shared/ResultRow.swift
Views/Combat/End/RewardsBlock.swift
Views/Combat/End/ObjectivesBlock.swift
Views/Combat/End/BattleStatsBlock.swift
Views/Combat/End/EndHeader.swift
Views/Combat/InteractiveBattleV2View.swift
```

### Modified (2 files)

```
Views/Combat/InteractiveBattleViewModel.swift   (+4 derived properties)
Views/Combat/InteractiveBattleRouteView.swift   (feature-flag branch)
```

### Retired in PR-7 (4 files)

```
Views/Combat/InteractiveBattleView.swift
Views/Combat/InteractivePredictView.swift
Views/Combat/InteractiveRoundLogCard.swift
Views/Combat/YourChoiceButton.swift
```

### Untouched

```
Services/CombatEngine.swift
Models/InteractiveCombatModels.swift
Models/CombatData.swift
Models/CombatLogEvent.swift
Views/Combat/CombatDetailView.swift             (legacy fallback)
Views/Combat/CombatResultDetailView.swift        (post-combat)
Views/Combat/LootDetailView.swift                (post-combat)
Views/Combat/BattleSummaryView.swift             (renamed internals only in PR-5)
Views/Combat/VFX/*                                (all VFX files)
Views/Combat/ActiveSkillsHUD.swift                (reused)
Views/Combat/InteractiveCombatComponents.swift    (reused — ZoneChip, TimerRingStrikeButton)
```

---

## 7. Rollback playbook

If anything regresses:

1. Toggle `combatUXV2 = false` in remote config. All traffic back to V1 within seconds. No deploy.
2. If remote config is broken, push a hot-config update via backend (see `docs/10_operations/DEPLOY.md`).
3. If local crash loop on V2: TestFlight build rebuilt from the commit before PR-2 merge.

No database migration is involved — no need to touch Supabase. This refactor is pure client-side view layer.

---

## 8. Open questions for Artem

Flag these before starting PR-1:

1. Should ranked rewards show **numeric rank delta** (+24 / -18) or **new total rank**?
   → Prototype currently uses delta. Confirm preference.

2. Do we want to keep the **collapsible full round-by-round log** inside END (from `BattleSummaryView`) or drop it entirely for the cleaner "rewards > stats" hierarchy?
   → Plan assumes keep-as-secondary. Confirm.

3. Should the round strip in CHOOSE say `ROUND 3 · BEST OF 7` or just `ROUND 3`?
   → Prototype uses `ROUND 3 · BEST OF 7`. Confirm.

4. Should the objectives block surface at all in Defeat, or only on win?
   → Prototype shows objectives in both. Confirm.

5. For the `SKIP` button in CHOOSE: fire-and-forget submit with null zones, OR show a one-tap confirmation micro-sheet?
   → Prototype assumes confirmation. Confirm.
