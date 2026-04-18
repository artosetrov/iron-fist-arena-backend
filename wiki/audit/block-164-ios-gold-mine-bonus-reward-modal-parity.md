---
title: Audit Block 164 — iOS Gold Mine Bonus Reward Modal Parity
category: audit
tags: [audit, ios, gold-mine, rewards, modal, toast]
sources:
  - Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift
  - Hexbound/Hexbound/Views/Minigames/MineClaimRewardView.swift
  - wiki/features/gold-mine.md
  - wiki/decisions/why-reward-modal-over-toast.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 164 — iOS Gold Mine Bonus Reward Modal Parity

## Scope

- `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`
- `Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift`
- `Hexbound/Hexbound/Views/Minigames/MineClaimRewardView.swift`
- `wiki/features/gold-mine.md`
- `wiki/decisions/why-reward-modal-over-toast.md`

## Why this block

The Gold Mine feature already had a dedicated reward modal for `collect-all`, but two bonus payout paths still used a `.reward` toast:

- `applySlotMinigameResult(_:)`
- `applyBonusResult(_:)`

That left one feature speaking two reward languages for the same kind of gold / gem payout.

## Fix applied

### `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`

- replaced the bonus payout toast path with `claimReward = ClaimRewardData(...)`
- kept non-currency toasts intact (`slot unlocked`, `boosted`, errors, shaft prompts)
- clarified the comment on `claimReward` so it explicitly covers both collect and bonus-round rewards

### `Hexbound/Hexbound/Views/Minigames/MineClaimRewardView.swift`

- updated the file header comment so the modal is described as the shared Gold Mine reward ceremony, not as a collect-only surface

### Wiki truth-sync

- `wiki/features/gold-mine.md` now documents `MineClaimRewardView` as the reward surface for both collect-all and slot-bonus payouts
- `wiki/decisions/why-reward-modal-over-toast.md` now explicitly includes Gold Mine collect-all and slot-bonus rewards inside the modal-only rule

## Result

Gold Mine now uses one consistent reward ceremony for currency payouts:

- `collect-all` delta => modal
- slot-bonus minigame payout => modal
- non-currency structure / utility events => toast

That removes the last obvious reward-surface contradiction inside the Gold Mine flow itself.

## File records

| Path | Role | Status |
|------|------|--------|
| `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift` | Gold Mine collect / bonus payout orchestration | Fixed |
| `Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift` | Gold Mine reward modal presenter | OK |
| `Hexbound/Hexbound/Views/Minigames/MineClaimRewardView.swift` | Shared Gold Mine payout ceremony | Fixed |
| `wiki/features/gold-mine.md` | Gold Mine feature map and reward-surface truth | Fixed |
| `wiki/decisions/why-reward-modal-over-toast.md` | Product rule for reward surfaces | Fixed |

## Verification

- `xcodebuild -project /Users/artosetrov/Documents/Cursor\\ AI/PVP\\ RPG/Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

Both passed after the change.
