---
title: block-167-ios-mail-claim-reward-modal-parity
category: audit
tags: [audit, ios, mail, rewards, modal]
sources:
  - Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift
  - Hexbound/Hexbound/Models/MailMessage.swift
  - Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift
  - Hexbound/Hexbound/App/AppState.swift
  - wiki/features/mail.md
  - wiki/decisions/why-reward-modal-over-toast.md
updated: 2026-04-17
---

# Block 167 - iOS mail claim reward modal parity

## Why this block exists

We had already moved the main reward-heavy earn surfaces onto the shared `CLAIMED!` ceremony: daily login, daily quests, battle pass, tutorial quest, Gold Mine bonus payout, and referral apply.

Mail claim was one of the last obvious holdouts. `InboxViewModel.claimAttachments(...)` already applied authoritative reward state, invalidated inventory cache for item attachments, and marked the mail claimed optimistically, but the happy path still ended with no reward ceremony at all. The reward sound even fired on tap before the server confirmed the claim.

That left Inbox out of step with the rule recorded in [[why-reward-modal-over-toast]]: if a surface awards gold, gems, XP, or loot, it should use `ClaimRewardModalView`, not a toast-or-silence hybrid.

## What changed

### `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift`

- removed the premature `HapticManager.success()` / `uiRewardClaim` sound from the optimistic pre-request path
- after a successful `/api/mail/[id]/claim`, now builds a `ClaimRewardConfig` from:
  - authoritative `gold/gems/xp` values in `MailClaimResponse`
  - claimed `item` / `consumable` attachments as `ClaimLootItem`
  - the mail subject as the ceremony subtitle
- writes that config into the root-level `appState.claimRewardConfig`
- keeps the existing authoritative reward-state sync and inventory-cache invalidation intact

### `wiki/features/mail.md`

- added an explicit reward-surface section documenting that mail attachment claim now uses the shared reward modal

### `wiki/decisions/why-reward-modal-over-toast.md`

- expanded the rule scope so mail attachment claim is explicitly inside the modal-only reward policy

## Result

Inbox reward claim now speaks the same ceremonial language as the rest of the important earn surfaces:

- success reward sound happens inside the modal ceremony, not before server confirmation
- currency and loot are centered and acknowledged explicitly
- error paths remain toasts

## Verification

- `rg -n "uiRewardClaim|claimRewardConfig|Failed to claim rewards" Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift`
- `xcodebuild -project Hexbound/Hexbound.xcodeproj -scheme Hexbound -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
- `git diff --check`

All passed after this change.
