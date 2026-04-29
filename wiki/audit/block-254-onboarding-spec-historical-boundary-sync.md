---
title: Audit Block 254 — Onboarding Spec Historical Boundary Sync
category: audit
tags: [audit, docs, onboarding, tutorial, historical-boundary]
sources:
  - docs/02_product_and_features/ONBOARDING_SPEC.md
  - wiki/features/onboarding.md
  - wiki/features/tutorial.md
  - backend/src/lib/game/tutorial.ts
  - backend/src/app/api/tutorial/route.ts
  - Hexbound/Hexbound/Views/Auth/OnboardingCinematicView.swift
  - Hexbound/Hexbound/Tutorial/TutorialManager.swift
updated: 2026-04-29
status: Fixed
---

# Audit Block 254 — Onboarding Spec Historical Boundary Sync

## Scope

- `docs/02_product_and_features/ONBOARDING_SPEC.md`
- verification against the live onboarding/tutorial runtime maps and helpers

## Why this block

`ONBOARDING_SPEC.md` still read like an active shipped spec, but large parts of
it had become historical planning material:

- old building unlock schedule
- old tutorial-quest unlock levels
- old first-session economy walkthrough
- old MVP / Phase rollout checklist
- blended onboarding + tutorial language that no longer matched the current
  runtime split

Meanwhile the live repo already has narrower, more accurate source-of-truth
surfaces:

- `wiki/features/onboarding.md`
- `wiki/features/tutorial.md`
- `backend/src/lib/game/tutorial.ts`
- `backend/src/app/api/tutorial/route.ts`

## Fix applied

- re-framed `ONBOARDING_SPEC.md` as a **historical planning snapshot**
- added an explicit boundary banner at the top pointing readers to the live
  source-of-truth files
- clarified that exact welcome-gift values, unlock schedules, tutorial quest
  progression, and rollout phases are no longer canonical in this document
- added local reminders near the rollout and analytics sections so they are not
  mistaken for the active runtime tracker

## Result

The onboarding spec no longer competes with the shipped runtime for authority.
It remains useful as design history and UX intent, while the live repo now has a
clearer path to the current onboarding/tutorial truth.

## Verification

- live file review of:
  - `wiki/features/onboarding.md`
  - `wiki/features/tutorial.md`
  - `backend/src/lib/game/tutorial.ts`
  - `backend/src/app/api/tutorial/route.ts`
  - `Hexbound/Hexbound/Views/Auth/OnboardingCinematicView.swift`
  - `Hexbound/Hexbound/Tutorial/TutorialManager.swift`
- `git diff --check`
