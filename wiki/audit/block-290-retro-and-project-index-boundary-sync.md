---
title: Audit Block 290 — Retro and Project Index Boundary Sync
category: audit
tags: [audit, docs, retro, source-of-truth]
sources:
  - docs/retro/RETRO_2026-04-30.md
  - docs/PROJECT_INDEX.md
updated: 2026-05-01
status: Fixed
---

# Audit Block 290 — Retro and Project Index Boundary Sync

## Scope

This block cleans the last off-repo shorthand from the newest retro journal and refreshes the top-level project index metadata.

## Why this block

Two small source-of-truth drifts remained nearby:

- `RETRO_2026-04-30.md` still named external memory files while describing the V2-combat scaffold retirement and the bundled-commit lesson
- `PROJECT_INDEX.md` still carried an old top-line freshness stamp even after the broader docs/wiki audit wave moved far beyond that date

## Changes shipped

- Rephrased the 2026-04-30 retro so the V2 scaffold note and the commit-structure observation stand on checked-in prose alone.
- Updated `PROJECT_INDEX.md` freshness metadata to reflect the current audit wave.

## Result

The latest retro now reads cleanly from repo-owned context, and the top-level docs index no longer looks older than the source-of-truth layer it points to.
