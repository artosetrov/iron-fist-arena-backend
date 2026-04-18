---
title: Audit Block 166 — iOS Referral Apply Reward Modal Parity
category: audit
tags: [audit, ios, referral, rewards, modal, settings]
sources:
  - Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift
  - Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift
  - Hexbound/Hexbound/App/AppState.swift
  - wiki/features/referral.md
  - wiki/decisions/why-reward-modal-over-toast.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 166 — iOS Referral Apply Reward Modal Parity

## Scope

- `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`
- `Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift`
- `Hexbound/Hexbound/App/AppState.swift`
- `wiki/features/referral.md`
- `wiki/decisions/why-reward-modal-over-toast.md`

## Why this block

The reward-surface cleanup had already moved several currency payout flows off transient toasts and onto the shared CLAIMED ceremony:

- daily login
- tutorial quest claim
- Gold Mine collect and bonus payout

Referral apply was still a stray exception. The Settings referral screen showed:

- inline success state
- plus a `showToast("+X gold from referral!")`

That toast still carried a real currency reward and therefore violated the reward-surface rule already documented in [[why-reward-modal-over-toast]].

## What changed

### `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`

- replaced the referral apply success toast with `appState.claimRewardConfig`
- added a small `buildReferralRewardConfig(...)` helper
- kept the inline success row and typed error handling intact
- aligned modal copy with the shared convention:
  - title: `CLAIMED!`
  - subtitle: `Referral bonus`

### `wiki/features/referral.md`

- documented that entering a valid friend code now uses the shared CLAIMED modal for the invitee-side gold payout

### `wiki/decisions/why-reward-modal-over-toast.md`

- expanded the scope list so referral code apply is explicitly inside the modal-only reward rule

## Problems resolved

1. **Referral apply still surfaced currency payout via toast**
   - Resolution: the happy-path reward now uses the shared CLAIMED modal.

2. **Reward-surface rules had one more undocumented exception**
   - Resolution: feature and decision docs now include referral apply in the same reward-ceremony language as other currency claims.

## Verification

- `xcodebuild -project /Users/artosetrov/Documents/Cursor\ AI/PVP\ RPG/Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check -- Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift wiki/features/referral.md wiki/decisions/why-reward-modal-over-toast.md`

All passed after the change.

## Follow-up

- The invitee-side apply reward now matches the rest of the currency-ceremony system.
- The remaining referral work is no longer about reward surfacing; it is about broader product/runtime decisions like milestone breadth and any future referrer-side UI ceremony.
