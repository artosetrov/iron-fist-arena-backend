---
title: Audit Block 297 — iOS Enemy Portrait Resolver MainActor Parity
category: audit
tags: [audit, ios, combat, concurrency]
sources:
  - Hexbound/Hexbound/Views/Combat/EnemyPortraitResolver.swift
  - Hexbound/Hexbound/Views/Combat/CombatDetailView.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift
updated: 2026-05-01
status: Fixed
---

# Audit Block 297 — iOS Enemy Portrait Resolver MainActor Parity

## Scope

This block fixes the new combat portrait resolver so it matches the actor
isolation of the cache and its UI call sites.

## Why this block

After the shared `EnemyPortraitResolver` landed, `xcodebuild` still failed in
the combat compile batch even after a full clean build.

The root issue was not stale DerivedData this time. The resolver was introduced
as a plain synchronous helper, but it reads from `GameDataCache`, which is
`@MainActor`, and it is used from UI rendering code that already lives on the
main thread.

That left the new helper outside the actor boundary of the cache it depended on.

## Changes shipped

- Marked `EnemyPortraitResolver` itself as `@MainActor`.
- Marked the adjacent portrait helper methods in
  `CombatDetailView.swift` as `@MainActor`.
- Marked `InteractiveBattleView.avatarContent(for:)` as `@MainActor` so its
  portrait resolution path matches the shared resolver's isolation.

## Result

The shared enemy portrait lookup now matches the actor model of the cache and
combat UI. The resolver remains centralized, but it no longer breaks the iOS
combat build on actor-isolation rules.
