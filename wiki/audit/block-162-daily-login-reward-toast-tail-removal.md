---
title: Audit Block 162 — Daily Login Reward Toast Tail Removal
category: audit
tags: [audit, ios, daily-login, rewards, modal, toast]
sources:
  - Hexbound/Hexbound/Services/DailyLoginService.swift
  - Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupViewModel.swift
  - Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift
  - Hexbound/Hexbound/App/AppState.swift
  - wiki/decisions/why-reward-modal-over-toast.md
  - wiki/audit/block-016-backend-daily-login-battle-pass-reward-contracts.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 162 — Daily Login Reward Toast Tail Removal

## Scope

- `Hexbound/Hexbound/Services/DailyLoginService.swift`
- `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupViewModel.swift`
- `Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift`
- `Hexbound/Hexbound/App/AppState.swift`
- `wiki/decisions/why-reward-modal-over-toast.md`
- `wiki/audit/block-016-backend-daily-login-battle-pass-reward-contracts.md`

## Why this block

The daily-login reward flow had already been migrated onto the CLAIMED ceremony in [[block-016-backend-daily-login-battle-pass-reward-contracts]], but one small success-path tail remained:

- `DailyLoginService.claimReward()` still fired `showToast("Reward claimed!", type: .reward)`
- `DailyLoginPopupViewModel` then built and presented `ClaimRewardModalView`

So the player could get both a modal and a reward toast for the same claim. The modal was the intended surface; the toast was just leftover noise.

## Fix applied

### `Hexbound/Hexbound/Services/DailyLoginService.swift`

- removed the success toast from the happy path
- kept the error toast path intact for actual failure feedback

### Decision/docs sync

- recorded the tail removal in this audit block
- left the broader reward-modal decision page intact, because daily login is now back in compliance with it

## Result

Daily login claim now behaves the way the product rule already said it should:

- success => CLAIMED modal
- failure => toast

No duplicate “Reward claimed!” toast competes with the reward ceremony anymore.

## File records

| Path | Role | Status |
|------|------|--------|
| `Hexbound/Hexbound/Services/DailyLoginService.swift` | Daily-login claim transport and local reward-state sync | Fixed |
| `Hexbound/Hexbound/Views/DailyLogin/DailyLoginPopupViewModel.swift` | Builds the authoritative reward modal after claim | OK |
| `Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift` | Shared CLAIMED ceremony surface | OK |
| `Hexbound/Hexbound/App/AppState.swift` | Root reward modal slot and global state owner | OK |
| `wiki/decisions/why-reward-modal-over-toast.md` | Reward-surface product rule | OK |
| `wiki/audit/block-016-backend-daily-login-battle-pass-reward-contracts.md` | Earlier migration context for this path | OK |

## Verification

- `rg -n 'showToast\\("Reward claimed!"' Hexbound/Hexbound/Services/DailyLoginService.swift`
- `git diff --check`

Both passed after the change.
