---
title: Audit Block 286 — Social Message Action and TODO Inventory Parity
category: audit
tags: [audit, ios, social, operations, docs]
sources:
  - Hexbound/Hexbound/Views/Social/GuildHallAlliesTab.swift
  - docs/10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md
  - admin/src/actions/dashboard.ts
  - Hexbound/Hexbound/Models/CombatLogEvent.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift
updated: 2026-04-30
status: Fixed
---

# Audit Block 286 — Social Message Action and TODO Inventory Parity

## Scope

This block closes a stale social TODO in the shipped UI and syncs the old release audit's TODO inventory.

## Why this block

Two separate drifts had piled up:

- `GuildHallAlliesTab` still showed `Send Scroll` with a dead `TODO: Message — Phase 2`
  action, even though Guild Hall message threads have long been live.
- `HEXBOUND_PRE_RELEASE_AUDIT.md` still talked about a 6-file product-flow TODO
  surface that no longer matches the current checked-in repo.

## Changes shipped

- Wired `Send Scroll` in `GuildHallAlliesTab` to the existing
  `AppRoute.guildHallMessage(...)` deep-link.
- Removed the stale social "Phase 2" TODO from the shipped UI.
- Updated the historical pre-release audit so its TODO-related rows now describe
  the current smaller, bounded TODO set instead of the stale 6-file list.

## Result

The Allies action menu no longer contains a fake follow-up stub, and the
historical release audit no longer overstates the current production TODO
surface.
