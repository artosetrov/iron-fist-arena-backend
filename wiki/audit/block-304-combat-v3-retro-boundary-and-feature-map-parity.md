---
title: Audit Block 304 — Combat v3 Retro Boundary and Feature-Map Parity
category: audit
tags: [audit, combat, retro, wiki, ios]
sources:
  - docs/retro/RETRO_2026-05-04.md
  - wiki/features/interactive-combat.md
  - wiki/features/pvp-combat.md
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift
  - Hexbound/Hexbound/Views/Combat/BattleSummaryView.swift
  - Hexbound/Hexbound/Models/CombatData.swift
updated: 2026-05-04
status: Fixed
---

# Audit Block 304 — Combat v3 Retro Boundary and Feature-Map Parity

## Scope

This block aligns the fresh 2026-05-04 combat retro with the live combat
feature maps after the latest v3.1 UI wave.

## Why this block

Two truth drifts had opened at once:

1. `RETRO_2026-05-04.md` had already started leaning on external
   `feedback_*` and `project_*.md` shorthand again, even though the repo now
   has enough checked-in code/docs to preserve those lessons directly.
2. The live combat feature maps were behind the runtime:
   - `interactive-combat.md` still presented `2026-04-29` as the last major
     change and barely acknowledged the v3.1 readability wave.
   - `pvp-combat.md` still sounded as if the interactive END summary already
     rendered `delta + new total`, while `BattleSummaryView.swift` explicitly
     documents that rating numbers are still a follow-up there.

## Changes shipped

- Rewrote `RETRO_2026-05-04.md` so its lessons now stand on checked-in repo
  truth instead of external feedback/project note names.
- Updated `wiki/features/interactive-combat.md` to reflect the live v3.1
  surface:
  - optimistic cold-start shell
  - compact duel header
  - collapsed one-channel reveal feedback
  - `BattleSummaryView` as the live end-of-battle summary surface
  - rating tile still pending there
- Updated `wiki/features/pvp-combat.md` so it no longer overclaims the current
  interactive summary. The backend/iOS payload plumbing for
  `rating_before` / `rating_after` is real, but the summary tile itself is
  still a bounded follow-up.

## Result

The fresh combat retro now keeps its reasoning inside the checked-in repo, and
the two combat feature maps once again match the actual shipped v3.1 runtime
instead of a slightly older or more optimistic story.
