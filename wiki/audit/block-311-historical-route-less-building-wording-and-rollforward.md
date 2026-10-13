---
title: Audit Block 311 — Historical Route-Less Building Wording and Rollforward
category: audit
tags: [audit, docs, ios, hub, inventory]
sources:
  - docs/07_ui_ux/W2_D4_BUILDING_GATING_DESIGN.md
  - docs/07_ui_ux/W2_D1_REVIEW.md
  - docs/10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-05-06
status: Fixed
---

# Audit Block 311 — Historical Route-Less Building Wording and Rollforward

## Scope

This block closes the next narrow historical-language seam after the live hub
runtime already moved to the route-less placeholder model:

- older W2 building-gating docs still used generic player-facing placeholder
  wording for Black Market and adjacent hub questions
- the historical pre-release audit still carried the same label in section
  headers and summary rows
- `project-file-inventory.md` had drifted again after the late tracked
  rollforward, leaving stale `_untracked_` markers on blocks that are now
  tracked and missing the next audit block entry

## Why this block

The live repo truth is already clearer now:

- route-less buildings are a bounded editor/config placeholder model
- Guild Hall routes live
- Black Market is hidden from the normal hub path until a real route exists

The remaining historical docs were not wrong about the old snapshot moment, but
they were still using the older generic placeholder shorthand instead of the
cleaner route-less language the rest of the repo now uses.

## Changes shipped

- Reworded `W2_D4_BUILDING_GATING_DESIGN.md` so its Black Market examples,
  schedule row, and open questions now describe a route-less placeholder model
  rather than a generic player-facing placeholder surface.
- Added an explicit boundary note to that same historical design doc: the
  player-facing hub now hides the route-less Black Market, so the visible
  placeholder examples below belong to the proposal snapshot rather than the
  current shipped city map.
- Reworded the `W2_D1_REVIEW.md` building-gating row so it describes `route:
  AppRoute?` as the old route-less placeholder mechanism that still leaked into
  the hub at that snapshot, instead of treating it as a generic player-facing
  placeholder pattern.
- Renamed the residual placeholder section/header wording in
  `HEXBOUND_PRE_RELEASE_AUDIT.md` to the more accurate snapshot-time
  route-less dead-end language.
- Rolled `project-file-inventory.md` forward again so it no longer marks
  blocks `304–308` as untracked, and now includes block `311`.

## Result

The historical building-gating and release-audit layer now speaks the same
route-less placeholder language as the live runtime/docs cleanup wave, and the
inventory once again matches the current tracked/untracked repo state instead of
dragging stale markers behind it.
