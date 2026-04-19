---
title: Audit Block 235 — Feature Maps Minigames and Social Runtime Boundary Sync
category: audit
tags: [audit, wiki, feature-map, minigames, social, runtime]
sources:
  - wiki/features/minigames.md
  - wiki/features/social.md
  - admin/src/app/(dashboard)/social/page.tsx
  - Hexbound/Hexbound/Views/Minigames/ShellGameViewModel.swift
  - Hexbound/Hexbound/Views/Minigames/FortuneWheelViewModel.swift
  - backend/src/lib/game/guild-challenge.ts
  - backend/tests/api/shell-game-start.test.ts
  - backend/tests/api/shell-game-guess.test.ts
  - backend/tests/api/shell-game-play-deprecated.test.ts
  - backend/tests/api/social-challenges.test.ts
  - backend/tests/api/social-messages.test.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 235 — Feature Maps Minigames and Social Runtime Boundary Sync

## Scope

- `wiki/features/minigames.md`
- `wiki/features/social.md`
- `admin/src/app/(dashboard)/social/page.tsx`
- `Hexbound/Hexbound/Views/Minigames/ShellGameViewModel.swift`
- `Hexbound/Hexbound/Views/Minigames/FortuneWheelViewModel.swift`
- `backend/src/lib/game/guild-challenge.ts`
- route-level backend tests for shell game and social flows

## Why this block

Two feature maps still carried older speculative boundary language:

- `minigames.md` still mentioned a shared `backend/src/lib/game/minigames.ts` helper and a possible `MinigameService.swift`
- `social.md` still pointed at a richer moderation-style admin surface and a possible `guild.ts`

That wording was now behind the actual runtime:

- shell and wheel calls live directly in their view models
- guild-scoped logic is represented by `guild-challenge.ts`, not a broader live guild backend
- the admin social page is a review dashboard, not a full moderation console

## Fix applied

- `minigames.md`
  - removed the speculative shared backend helper
  - replaced the speculative service note with the real `ShellGameViewModel` and `FortuneWheelViewModel` API ownership
  - replaced the vague minigames test note with the current route-level shell-game tests
- `social.md`
  - replaced the speculative `guild.ts` note with the real `guild-challenge.ts` helper
  - rewrote the admin note to the real read-only social review page
  - added an explicit note that the admin surface is not a live moderation console
  - replaced the vague social test note with the current route-level social challenge/message tests

## Result

The minigames and social feature maps now describe the live runtime and admin boundaries instead of older “maybe-present” helper layers.

## Verification

- verified the referenced view models, admin page, helper, and test files exist
- confirmed there is no shared `MinigameService.swift`
- confirmed there is no `backend/src/lib/game/guild.ts`
- `git diff --check`

This closes the next runtime-boundary tail in the feature-map layer.
