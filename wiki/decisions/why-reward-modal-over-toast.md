---
title: "Decision: Gold/XP Rewards Surface as Modals, Not Toasts"
category: decisions
tags: [ui, ux, rewards, modals, toasts, claim]
sources: [Hexbound/Hexbound/Views/Components/ClaimRewardModalView.swift, Hexbound/Hexbound/App/AppState.swift, Hexbound/Hexbound/App/HexboundApp.swift, Hexbound/Hexbound/Views/Hub/HubView.swift, Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift, Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift]
updated: 2026-04-17
---

# Why Reward Modals Over Toasts

## Decision

Any user-facing surface that awards **gold, gems, or XP** presents the reward via `ClaimRewardModalView` (the CLAIMED ceremony) — never via `showToast(type: .quest|.reward)` with the amounts baked into the subtitle.

Toasts remain valid for non-reward feedback (equipped, repaired, sold, stamina restored, errors).

## Rationale

Rewards are the game's payoff moments. Toasts are too ambient — they slide in at screen-edge, auto-dismiss in ~3s, and compete with whatever the player is currently doing. A player can easily miss "+150g +80 XP" if the toast fires mid-scroll or while tapping another element.

The CLAIMED modal centers the screen, dims the background, runs a tick-up counter, and requires an explicit CONTINUE tap. The player *has* to acknowledge the reward, and the ceremony feels commensurate with the effort that earned it.

## Tradeoffs

**Pros:**
- Consistent reward ceremony across every earn-point (quest, achievement, battle pass, daily login, shop contraband, bonus).
- Reward visibility is 100% — no missed earnings.
- Tick-up counters + haptics create a dopamine beat toast can't match.

**Cons:**
- Modals interrupt flow — one more tap to continue.
- Cannot stack: only one CLAIMED ceremony at a time (already handled by the single `appState.claimRewardConfig` slot).

## Scope

**Must use modal** (receive gold/gems/XP):
- Daily quest claim (both `DailyQuestsDetailView` and inline `ActiveQuestBanner` / hub quest card)
- Tutorial quest claim from the Hub NPC banner
- Referral code apply bonus from Settings
- Mail attachment claim from Inbox
- Daily quest all-complete bonus
- Achievement claim
- Battle pass tier claim
- Daily login claim
- Shop contraband / special offer claim
- Gold Mine collect-all payout and slot-bonus minigame payout
- PvP / dungeon victory rewards (use the full battle-result screen, which is already ceremonial)

**Must stay toast** (no gold/gems/XP awarded):
- "Equipped X" / "Sold for N gold" (transaction, player chose it)
- "Healed!" / "Repaired!" / "+N Stamina restored!" (utility action)
- "Unlocked mining slot" (milestone, no reward counter)
- All errors + retry prompts

## Implementation Notes

- `AppState.claimRewardConfig: ClaimRewardConfig?` is the **root-level slot** for surfaces with no own VM (inline banners).
- `HexboundApp.swift` mounts `ClaimRewardModalView` as an overlay driven by that slot (zIndex 180 — above Daily Login 150, below Hero Forge 200).
- Views with their own VM (DailyQuests, BattlePass, Achievements, DailyLogin, Shop) keep their VM-local `claimRewardConfig` + `.claimRewardModal(config:)` modifier — they were the original pattern.
- Title convention across all call sites: `"CLAIMED!"`. Subtitle = the item/quest/achievement title.
- Do NOT call `SFXManager.shared.play(.uiRewardClaim)` before setting the config — the modal ceremony plays it internally at 0.25s.

## See Also

- [[quests]] — quest claim uses this pattern
- [[achievements]] — achievement claim uses this pattern
- [[battle-pass]] — tier claim uses this pattern
- [[daily-login]] — day claim uses this pattern
- [[shop]] — contraband claim uses this pattern
- [[design-principles]] — 3-second rule, no dead ends, one goal per screen
