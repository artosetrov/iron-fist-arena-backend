---
title: Audit Block 293 — Enemy Portrait Resolver Memory Boundary Sync
category: audit
tags: [audit, ios, combat, comments]
sources:
  - Hexbound/Hexbound/Views/Combat/EnemyPortraitResolver.swift
updated: 2026-05-01
status: Fixed
---

# Audit Block 293 — Enemy Portrait Resolver Memory Boundary Sync

## Scope

This block removes an external memory-note breadcrumb from the new shared combat
enemy-portrait resolver.

## Why this block

`EnemyPortraitResolver.swift` is an active runtime helper, not a historical note.
Its header comment still justified the shared resolver by naming an external
memory file instead of stating the actual local rule directly.

That made a live combat utility depend on off-repo context for something simple:
keep enemy portrait lookup centralized so classic and interactive combat do not
drift apart.

## Changes shipped

- Rewrote the header comment in `EnemyPortraitResolver.swift` so it now states
  the real repo-owned rule directly: keep the lookup logic centralized here
  rather than duplicating slightly different heuristics across combat views.

## Result

The combat portrait resolver now stands on checked-in prose alone and no longer
needs an external memory-note name to explain why it exists.
