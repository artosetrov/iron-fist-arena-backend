---
title: Audit Block 239 — Feature Maps Auth, Character, Tutorial, and Progression Boundary Sync
category: audit
tags: [audit, wiki, features, auth, tutorial, characters, stamina, prestige]
sources:
  - wiki/features/auth.md
  - wiki/features/tutorial.md
  - wiki/features/characters.md
  - wiki/features/stamina.md
  - wiki/features/prestige.md
  - backend/tests/api/auth-guest.test.ts
  - backend/tests/api/auth-guest-login.test.ts
  - backend/tests/api/auth-register.test.ts
  - backend/tests/api/auth-login.test.ts
  - backend/tests/api/auth-forgot-password.test.ts
  - backend/tests/api/auth-google-apple.test.ts
  - backend/tests/api/auth-upgrade-guest.test.ts
  - backend/tests/api/auth-upgrade-guest-oauth.test.ts
  - backend/tests/api/auth-link-account.test.ts
  - backend/tests/api/auth-sync-user.test.ts
  - backend/tests/api/tutorial-quest.test.ts
  - backend/tests/api/tutorial-scripted-fight-contracts.test.ts
  - backend/tests/api/tutorial-referral.test.ts
  - backend/tests/lib/tutorial-referral-rewards.test.ts
  - backend/tests/api/characters-list.test.ts
  - backend/tests/api/character-progression-derived-stats.test.ts
  - backend/tests/api/stamina-refill.test.ts
  - backend/tests/lib/stamina.test.ts
  - backend/tests/lib/stamina-refill-dr.test.ts
  - admin/src/app/(dashboard)/players/page.tsx
  - admin/src/app/(dashboard)/players/[id]/page.tsx
  - admin/src/app/(dashboard)/config/page.tsx
  - admin/src/app/(dashboard)/balance/page.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 239 — Feature Maps Auth, Character, Tutorial, and Progression Boundary Sync

## Scope

- `wiki/features/auth.md`
- `wiki/features/tutorial.md`
- `wiki/features/characters.md`
- `wiki/features/stamina.md`
- `wiki/features/prestige.md`
- adjacent backend test coverage
- adjacent live admin surfaces for players / config / balance

## Why this block

The next feature-map slice still carried two older kinds of drift:

- `backend/src/__tests__/* (if present)` placeholders even though these features now have real focused tests under `backend/tests/`
- phantom or over-claimed admin notes like `admin/src/app/(dashboard)/characters/` or tutorial/stamina/prestige tools that are not actually checked in today

That made the feature maps sound broader and blurrier than the current repo.

## Fix applied

- replaced the auth placeholder test note with the real checked-in auth route test surface
- replaced the tutorial placeholder test note with the real tutorial quest / scripted-fight / referral coverage
- replaced the character placeholder test note with the real character list and progression-derived-stats coverage
- replaced the stamina placeholder test note with the real refill / stamina-lib / DR coverage
- replaced the prestige placeholder with an explicit note that no dedicated prestige backend test file is checked in today
- removed the phantom `admin/src/app/(dashboard)/characters/` references
- narrowed tutorial admin wording to adjacent player-review surfaces only
- narrowed stamina admin wording to live config/balance tuning, not per-character direct stamina edits
- narrowed prestige admin wording to adjacent review/tuning surfaces, not a manual prestige editor

## Result

These feature maps now point at the real checked-in tests and the real adjacent admin surfaces, instead of preserving older placeholder language and non-existent admin trees.

## Verification

- file existence checks for the listed backend tests
- file existence checks for the referenced admin pages
- `git diff --check`
