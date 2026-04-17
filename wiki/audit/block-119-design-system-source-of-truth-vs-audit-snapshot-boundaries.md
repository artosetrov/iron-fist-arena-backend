---
title: Block 119 — Design system source-of-truth vs audit snapshot boundaries
category: audit
tags: [audit, docs, design-system, source-of-truth, ui]
sources:
  - docs/07_ui_ux/DESIGN_SYSTEM.md
  - docs/07_ui_ux/DESIGN_SYSTEM_AUDIT.md
  - Hexbound/Hexbound/Theme/DarkFantasyTheme.swift
updated: 2026-04-16
status: Fixed
---

# Block 119 — Design system source-of-truth vs audit snapshot boundaries

## Scope

- `docs/07_ui_ux/DESIGN_SYSTEM.md`
- `docs/07_ui_ux/DESIGN_SYSTEM_AUDIT.md`
- `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`

## Why this block

These two files were both valuable, but they were speaking in different modes without saying so clearly enough:

- `DESIGN_SYSTEM.md` is supposed to be the living ruleset
- `DESIGN_SYSTEM_AUDIT.md` is a forensic point-in-time audit snapshot

When those roles blur, readers start trusting stale counts and old milestone claims as if they were current guarantees.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-118-source-of-truth-admin-capabilities-and-screen-inventory-parity]]

## File notes

### `docs/07_ui_ux/DESIGN_SYSTEM.md`

- **Zone:** docs / live design-system reference
- **Purpose:** canonical ruleset for tokens, component conventions, interaction patterns, and implementation rules
- **Problems found:**
  - opened with count-heavy metadata (`46`, `70+`, `30+`, `370+`) that is brittle by nature
  - included an ambiguous “iOS players 16+” audience line that could be read as platform/version guidance
  - still carried a “100% COMPLETE” milestone sentence from March as if it were current state truth
  - several section headers still embedded screen counts
- **What was fixed:**
  - refreshed the date and reframed the doc as a living design-system reference
  - replaced brittle count metadata with role-based coverage wording
  - clarified that exact inventories belong in `wiki/`, `SCREEN_INVENTORY.md`, code, and Figma export
  - converted the March “100% COMPLETE” line into an explicit historical milestone note
  - removed section-level screen counts from screen-alignment headings
- **Status:** Fixed

### `docs/07_ui_ux/DESIGN_SYSTEM_AUDIT.md`

- **Zone:** docs / historical audit artifact
- **Purpose:** deep forensic audit snapshot of code ↔ token ↔ component ↔ Figma parity from `2026-04-01`
- **Problems found:**
  - did not clearly warn readers that it is a historical snapshot rather than live guaranteed truth
  - `Success Metrics` could be misread as current-state guarantees instead of audit target metrics
- **What was fixed:**
  - added an explicit status-boundary note at the top
  - clarified that success metrics are audit targets from that historical pass and must be revalidated before reuse
- **Status:** Fixed

### `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`

- **Zone:** runtime evidence
- **Purpose:** live token source supporting the claim that exact token inventories should be validated in code rather than frozen in prose
- **Review outcome:**
  - remains the stronger authority for current token surface than count-based doc summaries
- **Status:** OK

## Problems found

1. **Living design doc and historical audit were not clearly separated**
   - Risk: readers use the wrong file as the authority for current-state decisions.
   - Fix: explicitly separated “canonical ruleset” from “historical forensic snapshot.”

2. **Count-heavy metadata had become fragile**
   - Risk: screen/component/token numbers silently drift and weaken trust in the document.
   - Fix: replaced top-level counts with coverage wording and redirected exact inventory questions to live sources.

3. **Historical milestone language read like present-tense truth**
   - Risk: “100% COMPLETE” messaging makes current design debt easy to underestimate.
   - Fix: reframed the statement as a dated milestone, not a permanent guarantee.

## Verification

- inspected `DESIGN_SYSTEM.md`
- inspected `DESIGN_SYSTEM_AUDIT.md`
- checked `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- `git diff --check`

## Follow-up

- The next adjacent pass should likely cover the remaining `docs/07_ui_ux/` audit-style artifacts that still contain strong snapshot counts or milestone language without explicit historical boundaries.
