---
title: Audit Block 280 — Screen Inventory Guild Hall Runtime Parity
category: audit
tags: [audit, ios, social, docs]
sources:
  - docs/07_ui_ux/SCREEN_INVENTORY.md
  - wiki/features/social.md
  - Hexbound/Hexbound/Views/Social/GuildHallDetailView.swift
  - Hexbound/Hexbound/Views/Social/GuildHallScrollsTab.swift
updated: 2026-04-30
status: Fixed
---

# Audit Block 280 — Screen Inventory Guild Hall Runtime Parity

## Scope

This block aligns the live iOS screen inventory with the shipped Guild Hall runtime.

## Why this block

`SCREEN_INVENTORY.md` is still an active source-of-truth doc, not a purely historical
snapshot. Its Guild Hall row still described the screen as "Guild management &
social", which overstated the shipped feature set after the broader guild-system
docs had already been narrowed to a historical draft.

## Changes shipped

- Rewrote the Guild Hall purpose in `SCREEN_INVENTORY.md`.
- The row now reflects the shipped runtime truth: a social hub for allies,
  scrolls, and duels.

## Result

The live screen map no longer describes Guild Hall as if full guild-management
systems already exist in the iOS runtime.
