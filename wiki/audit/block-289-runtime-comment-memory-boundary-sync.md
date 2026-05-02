---
title: Audit Block 289 — Runtime Comment Memory Boundary Sync
category: audit
tags: [audit, ios, backend, prisma, comments]
sources:
  - Hexbound/Hexbound/Views/Combat/CombatLogRow.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift
  - Hexbound/Hexbound/Views/Combat/VFX/CombatVerdictFlash.swift
  - Hexbound/Hexbound/Views/Combat/BattleSummaryView.swift
  - Hexbound/Hexbound/Views/Hub/BuildingUnlockCeremony.swift
  - Hexbound/Hexbound/Views/Hub/CityBuildingLabel.swift
  - backend/src/app/api/pvp/resolve/route.ts
  - backend/prisma/migrations/20260414_active_slot_consumables/migration.sql
  - backend/prisma/migrations/20260419_talents_v2_current_rank/migration.sql
  - backend/prisma/migrations/20260429_talent_action_v2_ults/migration.sql
updated: 2026-05-01
status: Fixed
---

# Audit Block 289 — Runtime Comment Memory Boundary Sync

## Scope

This block removes off-repo memory-note references from active runtime code comments and migration notes.

## Why this block

By this point most external memory breadcrumbs were already gone from docs and wiki, but a small residue still lived directly inside checked-in code:

- combat and hub Swift comments still named the old no-scale animation note
- a PvP resolve comment still pointed at an external FK lesson filename
- three Prisma migrations still referenced an off-repo apply-order note

The underlying lessons were still useful; the external filenames were not.

## Changes shipped

- Rewrote the combat and hub animation comments so they describe the actual project motion rule directly: emphasize via opacity, glow, and translation rather than scale-grow.
- Rewrote the bot-match note in `pvp/resolve` so it explains the real invariant directly: bot rows keep `player2Id = null` and must preserve truthful `winnerId` / `loserId`.
- Rewrote the migration notes so they keep the real operational rule in checked-in prose: apply the DDL via Supabase MCP before deploying code that depends on it.

## Result

The active codebase now explains these runtime and deployment rules in repo-owned prose instead of depending on external memory-note names.
