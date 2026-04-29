---
title: Audit Block 258 — Feature-Map Game-Systems Doc Reference Parity
category: audit
tags: [audit, wiki, docs, feature-maps, source-of-truth]
sources:
  - wiki/features/tutorial.md
  - wiki/features/quests.md
  - wiki/features/events.md
  - wiki/features/minigames.md
  - wiki/features/dungeons.md
  - wiki/features/achievements.md
  - wiki/features/daily-login.md
  - docs/02_product_and_features/GAME_SYSTEMS.md
  - docs/02_product_and_features/ONBOARDING_SPEC.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 258 — Feature-Map Game-Systems Doc Reference Parity

## Scope

- feature-map docs sections that still pointed at the deleted
  `docs/06_game_systems/GAME_SYSTEMS.md`

## Why this block

Several live feature maps still referenced a product/system overview file that
no longer exists:

- `docs/06_game_systems/GAME_SYSTEMS.md`

That created an awkward footgun:

- the feature maps looked maintained
- but one of their "source" doc pointers was dead
- and the correct modern overview file had already moved to
  `docs/02_product_and_features/GAME_SYSTEMS.md`

## Fix applied

- replaced the dead `docs/06_game_systems/GAME_SYSTEMS.md` pointer with the
  live `docs/02_product_and_features/GAME_SYSTEMS.md` overview in:
  - `wiki/features/quests.md`
  - `wiki/features/events.md`
  - `wiki/features/minigames.md`
  - `wiki/features/dungeons.md`
  - `wiki/features/achievements.md`
  - `wiki/features/daily-login.md`
- updated `wiki/features/tutorial.md` to use more specific, still-present docs:
  - `docs/02_product_and_features/GAME_SYSTEMS.md`
  - `docs/02_product_and_features/ONBOARDING_SPEC.md` as historical plan
  - `docs/07_ui_ux/W2_D4_BUILDING_GATING_DESIGN.md` as historical hub-gating rationale

## Result

The feature-map layer no longer sends readers into a deleted path when they
follow its docs pointers. The broad systems overview now resolves to the live
`GAME_SYSTEMS.md`, while tutorial gets the narrower historical references that
actually explain its rollout history.

## Verification

- repo search for `docs/06_game_systems/GAME_SYSTEMS.md` in the touched feature
  maps
- live file existence checks for the replacement docs
- `git diff --check`
