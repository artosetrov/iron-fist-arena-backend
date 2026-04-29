---
title: Audit Block 255 — Guild System Spec Historical Boundary Sync
category: audit
tags: [audit, docs, social, guild, historical-boundary]
sources:
  - docs/02_product_and_features/GUILD_SYSTEM_SPEC.md
  - wiki/features/social.md
  - backend/src/lib/game/guild-challenge.ts
  - Hexbound/Hexbound/Views/Social/GuildHallDetailView.swift
  - admin/src/app/(dashboard)/social/page.tsx
updated: 2026-04-29
status: Fixed
---

# Audit Block 255 — Guild System Spec Historical Boundary Sync

## Scope

- `docs/02_product_and_features/GUILD_SYSTEM_SPEC.md`
- `wiki/features/social.md`
- adjacent live social/guild surfaces

## Why this block

The repo had a real checked-in guild design draft, but the boundary around it
was fuzzy:

- `GUILD_SYSTEM_SPEC.md` still read like a live MVP spec
- `wiki/features/social.md` pointed at an old memory note instead of the actual
  draft file
- shipped social runtime is much narrower than the draft:
  friends, direct messages, PvP challenges, Guild Hall host UI, and server-wide
  guild-challenge helpers

That made it too easy to mistake the broader raid / guild-currency / hierarchy
plan for current product reality.

## Fix applied

- reframed `GUILD_SYSTEM_SPEC.md` as a **historical design draft**
- added an explicit top-level boundary note describing what the live repo
  actually ships today versus what remains draft-only
- pointed readers at the real live social source-of-truth surfaces:
  - `wiki/features/social.md`
  - `backend/src/lib/game/social.ts`
  - `backend/src/lib/game/challenges.ts`
  - `backend/src/lib/game/guild-challenge.ts`
  - `Hexbound/Hexbound/Views/Social/*`
  - `admin/src/app/(dashboard)/social/page.tsx`
- updated `wiki/features/social.md` so it now references the checked-in guild
  spec file directly instead of the old memory note

## Result

The guild draft remains available as useful planning history, but it no longer
masquerades as the live social runtime. The social feature map now also points
to the actual draft document instead of an off-repo memory reference.

## Verification

- live file review of:
  - `wiki/features/social.md`
  - `backend/src/lib/game/guild-challenge.ts`
  - `Hexbound/Hexbound/Views/Social/GuildHallDetailView.swift`
  - `admin/src/app/(dashboard)/social/page.tsx`
- `git diff --check`
