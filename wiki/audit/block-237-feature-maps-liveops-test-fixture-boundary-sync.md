---
title: Audit Block 237 — Feature Maps Liveops Test Fixture Boundary Sync
category: audit
tags: [audit, wiki, feature-map, tests, quests, battle-pass, mail, events]
sources:
  - wiki/features/quests.md
  - wiki/features/battle-pass.md
  - wiki/features/mail.md
  - wiki/features/events.md
  - backend/tests/api/tutorial-quest.test.ts
  - backend/tests/api/battle-pass-claim.test.ts
  - backend/tests/prisma/battle-pass-reward-repair.test.ts
  - backend/tests/api/mail-list.test.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 237 — Feature Maps Liveops Test Fixture Boundary Sync

## Scope

- `wiki/features/quests.md`
- `wiki/features/battle-pass.md`
- `wiki/features/mail.md`
- `wiki/features/events.md`
- focused backend test files for adjacent liveops/runtime coverage

## Why this block

Several feature maps still ended with older `backend/src/__tests__/* (if present)` placeholders even though the repo has already moved to `backend/tests/...` and the actual coverage is more selective than those old blanket notes implied.

## Fix applied

- `quests.md`
  - replaced the old blanket placeholder with the live `tutorial-quest` test and an explicit note that there is no broad dedicated quest suite today
- `battle-pass.md`
  - replaced the old placeholder with the current focused claim/repair test files
- `mail.md`
  - replaced the old placeholder with the existing inbox-list route test and an explicit note about the narrower current coverage
- `events.md`
  - replaced the old placeholder with the current truth: no dedicated backend events test file is checked in today

## Result

These liveops feature maps now describe the actual checked-in test surface instead of older `__tests__/*` placeholders.

## Verification

- verified the referenced backend test files exist
- verified there is no broad `backend/src/__tests__/quests|battle-pass|mail|events` tree in the current repo
- `git diff --check`

This closes the next test-fixture boundary tail in the feature-map layer.
