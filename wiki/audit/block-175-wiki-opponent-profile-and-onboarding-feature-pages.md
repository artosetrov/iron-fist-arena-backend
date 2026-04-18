---
title: Audit Block 175 — Wiki Opponent Profile And Onboarding Feature Pages
category: audit
tags: [audit, wiki, features, navigation, source-of-truth]
sources:
  - wiki/audit/block-122-wiki-feature-map-visibility-and-related-link-gaps.md
  - wiki/features/characters.md
  - wiki/features/leaderboard.md
  - wiki/features/social.md
  - wiki/features/tutorial.md
  - Hexbound/Hexbound/Views/Leaderboard/LeaderboardPlayerDetailSheet.swift
  - Hexbound/Hexbound/Views/Profile/CharacterProfileView.swift
  - Hexbound/Hexbound/Models/OpponentProfile.swift
  - Hexbound/Hexbound/Services/GameDataCache.swift
  - Hexbound/Hexbound/Services/SocialService.swift
  - backend/src/app/api/social/relationship/route.ts
  - Hexbound/Hexbound/Views/Auth/OnboardingDetailView.swift
  - Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift
  - backend/src/app/api/characters/route.ts
updated: 2026-04-17
---

# Audit Block 175 — Wiki Opponent Profile And Onboarding Feature Pages

## Why this block exists

`block-122` had already narrowed the feature-map gap to two real missing pages:

- `[[opponent-profile]]`
- `[[onboarding]]`

That meant the feature atlas was no longer broadly incomplete, but it still had a couple of visible dead-end links inside otherwise strong pages.

## What changed

- created `wiki/features/opponent-profile.md`
- created `wiki/features/onboarding.md`
- updated the main feature atlas in `wiki/index.md` so both pages are discoverable
- updated `wiki/features/social.md` to stop claiming opponent profile exists only as project memory
- updated `block-122` so its remaining `Needs review` records now point to this follow-up and close as `Fixed`

## Result

The feature-map layer now has explicit pages for:

- the shared opponent-profile drill-down surface behind leaderboard/social actions
- the first-time onboarding / hero-forging flow that bridges auth, character creation, and tutorial handoff

That closes the old dead-end tail from `block-122` and makes the current atlas match the real product surfaces more closely.
