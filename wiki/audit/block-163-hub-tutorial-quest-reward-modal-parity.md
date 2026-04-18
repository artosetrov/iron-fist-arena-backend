---
title: Audit Block 163 — Hub Tutorial Quest Reward Modal Parity
category: audit
tags: [audit, ios, tutorial, hub, rewards, modal, toast]
sources:
  - Hexbound/Hexbound/Views/Hub/HubView.swift
  - Hexbound/Hexbound/Tutorial/TutorialManager.swift
  - Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift
  - Hexbound/Hexbound/App/AppState.swift
  - wiki/decisions/why-reward-modal-over-toast.md
  - wiki/audit/block-078-ios-tutorial-manager-typed-contract-cleanup.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 163 — Hub Tutorial Quest Reward Modal Parity

## Scope

- `Hexbound/Hexbound/Views/Hub/HubView.swift`
- `Hexbound/Hexbound/Tutorial/TutorialManager.swift`
- `Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift`
- `Hexbound/Hexbound/App/AppState.swift`
- `wiki/decisions/why-reward-modal-over-toast.md`
- `wiki/audit/block-078-ios-tutorial-manager-typed-contract-cleanup.md`

## Why this block

[[block-078-ios-tutorial-manager-typed-contract-cleanup]] fixed the field-name drift in tutorial quest claim handling, but the success surface still lagged behind the current product rule:

- tutorial quest claim from the Hub NPC banner still used a success toast
- the rest of the reward-claim surfaces had already moved to the shared CLAIMED ceremony

That left tutorial quest rewards feeling cheaper and less visible than the rest of the reward system.

## Fix applied

### `Hexbound/Hexbound/Views/Hub/HubView.swift`

- replaced the success toast path in `claimQuestReward(_:)`
- now builds a root-level `ClaimRewardConfig` for tutorial quest rewards
- supports the live reward shapes currently returned by the tutorial quest route:
  - `goldDelta`
  - consumable reward payload
- keeps the error toast path for failed claims

### `wiki/decisions/why-reward-modal-over-toast.md`

- added tutorial quest claim from the Hub NPC banner to the explicit “must use modal” scope
- replaced the old broad `Hexbound/CLAUDE.md` source pointer with live code surfaces

## Result

Tutorial quest rewards in the Hub now follow the same player-facing rule as the rest of the reward system:

- success => CLAIMED modal
- failure => toast

This also closes the last obvious contradiction between the reward-modal decision page and the live Hub tutorial quest flow.

## File records

| Path | Role | Status |
|------|------|--------|
| `Hexbound/Hexbound/Views/Hub/HubView.swift` | Hub tutorial quest claim entrypoint and reward presentation handoff | Fixed |
| `Hexbound/Hexbound/Tutorial/TutorialManager.swift` | Typed tutorial quest claim transport | OK |
| `Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift` | Shared reward ceremony surface | OK |
| `Hexbound/Hexbound/App/AppState.swift` | Root reward-modal slot owner | OK |
| `wiki/decisions/why-reward-modal-over-toast.md` | Product rule for reward surfaces | Fixed |
| `wiki/audit/block-078-ios-tutorial-manager-typed-contract-cleanup.md` | Earlier tutorial claim contract sync context | OK |

## Verification

- `xcodebuild -project /Users/artosetrov/Documents/Cursor\\ AI/PVP\\ RPG/Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

Both passed after the change.
