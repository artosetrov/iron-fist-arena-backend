---
title: Audit Block 292 — Delete Dead Guild Hall Duels Placeholder Helper
category: audit
tags: [audit, ios, social, cleanup]
sources:
  - Hexbound/Hexbound/Views/Social/GuildHallDuelsTab.swift
updated: 2026-05-01
status: Fixed
---

# Audit Block 292 — Delete Dead Guild Hall Duels Placeholder Helper

## Scope

This block removes dead placeholder residue from the Guild Hall duels UI.

## Why this block

`GuildHallDuelsTab.swift` still carried a local duels placeholder helper even
though the file no longer used it anywhere.

That leftover made the screen read like it still depended on a generic placeholder
surface, when the live duels tab already has concrete incoming/outgoing/history
cards and the fake "Phase 2" style stubs were being retired elsewhere too.

## Changes shipped

- Deleted the orphan duels placeholder helper from `GuildHallDuelsTab.swift`.
- Verified that no call sites remained in the file, so this was pure dead-code
  removal rather than a behavior change.

## Result

The Guild Hall duels screen no longer carries unused placeholder residue, and
the checked-in social UI better matches the shipped bounded-surface model.
