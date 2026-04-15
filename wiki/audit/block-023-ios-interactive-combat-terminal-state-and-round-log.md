---
title: Audit Block 023 — iOS Interactive Combat Terminal State and Round Log
category: audit
tags: [audit, ios, combat, interactive-combat, pvp, accessibility]
sources:
  - Hexbound/Hexbound/Views/Combat/ActiveSkillsHUD.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift
  - Hexbound/Hexbound/Views/Combat/BattleSummaryView.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift
  - Hexbound/Hexbound/Models/InteractiveCombatModels.swift
  - Hexbound/Hexbound/Models/RoundExchange.swift
  - Hexbound/Hexbound/Models/CombatData.swift
  - backend/src/app/api/pvp/match/start/route.ts
  - backend/src/app/api/pvp/strike/route.ts
updated: 2026-04-15
---

# Audit Block 023 — iOS Interactive Combat Terminal State and Round Log

## Scope

This block continues the passive/active-slot audit into the live combat runtime. After block 022, the next question was whether the equipped active-slot contract still stayed coherent once the duel actually started.

That surfaced two separate problems:

1. the round log used the wrong round number on the second and later exchanges;
2. the interactive combat client still derived terminal state mostly from HP, even though the backend already returns `match_finished` and `winner_id` for max-round finishes where both fighters may still be alive.

- **Files audited in this block:** 10
- **Primary file types:** Swift combat UI/view-model/model files, backend interactive PvP routes
- **Status:** Round numbering is corrected, interactive combat now respects server-authoritative terminal state and winner identity, match-start resets stale combat UI state, and consumed potion slots expose a correct accessibility label
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[interactive-combat]], [[combat]], [[block-011-backend-passives-interactive-combat-runtime]], [[block-022-ios-active-skill-picker-passive-tree-contracts]]

## Summary

- `InteractiveBattleViewModel` created `RoundExchange` with `max(1, strikeIndex)` instead of `strikeIndex + 1`. That meant round 2 was still labeled as round 1 in the reveal card and battle summary.
- The client-side `InteractiveMatchState` only considered "someone hit 0 HP" as terminal. That breaks the backend rule where `MAX_ROUNDS` can end the duel on HP percentage and still produce a valid `winner_id`.
- Because of that HP-only terminal logic, summary/complete flow could fail to advance correctly on max-round wins, and `BattleSummaryView` could show the wrong victory/defeat label.
- `applyMatchStart()` did not fully clear prior transient combat state. If the VM instance survived longer than one duel, stale banners/logs/pending active state could bleed into the next match.
- `ActiveSkillsHUD` visually marked a consumed potion as `USED`, but VoiceOver still announced it as `ready`.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | Terminal state on iOS was derived only from HP. | Max-round wins by HP% could skip summary/complete flow or show the wrong winner. | Added server-authoritative terminal state (`serverFinished`, `serverWinnerId`) to `InteractiveMatchState` and populated it from `/pvp/strike` / `/pvp/match/complete`. |
| P1 | Round log numbering used `max(1, strikeIndex)` instead of `strikeIndex + 1`. | Round 2 and later could display the wrong round number in `InteractiveRoundLogCard` and `BattleSummaryView`. | Corrected `InteractiveBattleViewModel` to pass `response.strikeIndex + 1` into `RoundExchange.build(...)`. |
| P2 | Fresh match start did not fully clear prior-match transient combat UI state. | Reused VM instances could leak old banners, battle log entries, damage popups, or armed active slots into a new duel. | `applyMatchStart()` now resets active-fire banners, pending slot, log state, popup state, and server-finish metadata. |
| P3 | Consumed potion slots were announced as "ready" to VoiceOver. | Accessibility mismatch between visible HUD state and spoken state. | `ActiveSkillsHUD` accessibility label now reports `"used this battle"` for spent consumable slots. |

## Cross-File Safe Fixes Applied

- `InteractiveMatchState` now stores server-authoritative terminal state so client flow can honor backend `match_finished` / `winner_id` even when both fighters survive to the round cap.
- `InteractiveBattleViewModel` now resets stale combat UI state on `/match/start`, records server finish/winner data from `/strike`, and passes the final winner from `CombatData.result.winnerId` into `.finished(...)`.
- `BattleSummaryView` now bases victory/defeat on `vm.state.winnerId` instead of a KO-only HP heuristic.
- `RoundExchange` consumers remain unchanged; fixing the `roundNumber` passed by the view model repaired both the per-round card and the full battle summary.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `Hexbound/Hexbound/Views/Combat/ActiveSkillsHUD.swift` | iOS combat active-slot HUD | Renders the player's 3 combat actives plus cooldown/consumed state. | Used by interactive combat UI; depends on `InteractiveActiveSlotSnapshot`. | Empty slots are placeholders, talents are cooldown-gated, potions are one-shot and should remain distinguishable both visually and via accessibility. | Fixed VoiceOver label for consumed potion slots. | Fixed |
| `Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift` | iOS interactive combat runtime orchestration | Owns match start/strike/summary/complete flow, live actives, round log, and VFX timing. | Used by `InteractiveBattleView` and summary/log consumers. Depends on interactive combat DTOs and `APIClient`. | Must treat backend HP, finish state, and winner as authoritative. | Fixed stale match-start reset, round-number off-by-one, and HP-only terminal-state logic. | Fixed |
| `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift` | iOS interactive combat host screen | Hosts duel header, predict panel, reveal/summary surfaces, and final finished banner routing. | Used by PvP interactive flow. Depends on `InteractiveBattleViewModel`. | Finished banner should reflect the winner passed by the VM, not re-derive combat outcome locally. | Re-audited; no direct code change needed after VM winner fix. | OK |
| `Hexbound/Hexbound/Views/Combat/BattleSummaryView.swift` | iOS post-fight recap surface | Shows outcome label plus the full ordered battle log before `/match/complete` navigation finishes. | Used when `phase == .summary`. Depends on `RoundExchange` and VM state. | Must reflect server-authoritative winner, including max-round HP% decisions. | Fixed KO-only victory heuristic and now keys off `vm.state.winnerId`. | Fixed |
| `Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift` | iOS per-round reveal log card | Displays one round exchange with auto-dismiss countdown. | Used by `InteractiveBattleView`; depends on `RoundExchange`. | Round header assumes `roundNumber` is already 1-based and correct. | Re-audited; consumer was correct, producer was wrong. | OK |
| `Hexbound/Hexbound/Models/InteractiveCombatModels.swift` | iOS interactive combat DTOs and local state | Defines match start/strike DTOs plus client-owned `InteractiveMatchState`. | Used by VM, HUD, battle summary, and interactive screen. | DTOs mirror backend contract; local state must not invent different finish rules than the server. | Added `serverFinished` / `serverWinnerId` so max-round finishes no longer depend on HP heuristics. | Fixed |
| `Hexbound/Hexbound/Models/RoundExchange.swift` | iOS round-log model builder | Re-shapes one `/strike` response into ordered ally/enemy log rows. | Used by `InteractiveBattleViewModel`, `InteractiveRoundLogCard`, `BattleSummaryView`. | Expects a 1-based `roundNumber`; intentionally does not derive it itself. | Re-audited; builder contract was correct and documented, which helped isolate the caller bug quickly. | OK |
| `Hexbound/Hexbound/Models/CombatData.swift` | iOS final combat result DTO | Decodes `/pvp/match/complete` payload including result metadata and winner id. | Used by interactive combat completion and classic result surfaces. | `result.winnerId` is the best final source for finished-phase routing when present. | Re-audited because `InteractiveBattleViewModel` now uses `data.result.winnerId` first. | OK |
| `backend/src/app/api/pvp/match/start/route.ts` | Backend interactive match bootstrap | Starts an interactive duel, snapshots actives, and reserves stamina/free-PvP state. | Used by `InteractiveBattleViewModel.startMatch()`. Depends on combat loader, stamina rules, and actives snapshot build. | Active loadout is snapshotted at match start so mid-match loadout edits do not mutate the duel. | Re-audited as the source of fresh-match state; no direct code change in this block. | OK |
| `backend/src/app/api/pvp/strike/route.ts` | Backend interactive strike resolver | Resolves one round, updates actives, decrements consumables, and returns `match_finished` / `winner_id`. | Used by `InteractiveBattleViewModel.resolveStrike()`. Depends on combat resolver, match state, and actives state. | Server is authoritative for HP, cooldowns, end-of-match decision, and winner identity. | Re-audited as the contract source; still has one edge-case flow around out-of-combat consumable depletion that deserves a follow-up pass. | Needs review |

## Duplicate / Split Logic Found

- Terminal-state derivation was previously split between backend truth (`match_finished`, `winner_id`) and client HP heuristics. This block removes that drift on the iOS side.
- Round numbering responsibility is intentionally centralized in the view model / caller. `RoundExchange` already documented that correctly; the bug was in the caller's arithmetic, not in the model.

## Files Without Clear Current Role

- None. All files in this block are active production combat runtime or direct contract sources.

## Candidates For Refactor

- The `/strike` error path for `OUT_OF_CONSUMABLE` still deserves a graceful client/server reconciliation strategy instead of dropping into a generic error flow mid-match.
- Consider making `InteractiveMatchState` explicitly carry the latest `matchFinished`/`winnerId` from the response object in a dedicated nested struct, so future combat surfaces don't regress to HP-only heuristics.

## Documentation Missing Or Stale

- There is still no dedicated wiki page documenting interactive combat terminal-state rules end to end: KO finish, round-cap finish by HP%, timeout, and which layer owns the final winner.

## Requires Separate Decision

- Resolved in [[block-024-interactive-combat-consumable-recovery]]: the server now strips the impossible slot and the client recovers in place instead of treating the duel as terminal.

## Verification

- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` completed with `** BUILD SUCCEEDED **`.
- `rg -n "max\\(1, response\\.strikeIndex\\)|serverFinished|serverWinnerId|winnerId == vm.state.attackerId" Hexbound/Hexbound/Models/InteractiveCombatModels.swift Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift Hexbound/Hexbound/Views/Combat/BattleSummaryView.swift` confirms the old round-number bug is gone and the new server-authoritative terminal-state path is wired in.
- `git diff --check` passes after the combat-runtime and wiki updates.
