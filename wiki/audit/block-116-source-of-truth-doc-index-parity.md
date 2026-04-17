---
title: Block 116 — Source-of-truth doc index parity
category: audit
tags: [audit, docs, source-of-truth, index]
sources:
  - docs/01_source_of_truth/DOCUMENTATION_INDEX.md
  - docs/01_source_of_truth/CLEANUP_REPORT.md
updated: 2026-04-16
status: Fixed
---

# Block 116 — Source-of-truth doc index parity

## Scope

- `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`
- `docs/01_source_of_truth/CLEANUP_REPORT.md`

## Why this block

After the operations/wiki cleanup, the repo still had one awkward mismatch:

- the "master reference" documentation index was still speaking in old March counts and old role descriptions
- the cleanup report was still easy to read as live documentation truth instead of archived restructuring evidence

That is exactly the kind of thing that trips people up during onboarding: the doc named "source of truth" quietly drifts away from the actual source of truth.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-115-operations-figma-and-historical-doc-boundaries]]

## File notes

### `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`

- **Zone:** docs / top-level navigation
- **Purpose:** master index for active project documentation
- **Problems found:**
  - still advertised old March freshness
  - repeated stale numeric descriptions like `40+ models`, `20+ screens`, `38 admin pages`, `45+ docs`
  - described `PROGRESS_LOG.md` as a normal changelog even after we explicitly reframed it as historical notebook material
- **What was fixed:**
  - updated the freshness banner to 2026-04-16
  - linked the index back to `wiki/` for live file-by-file audit state
  - replaced stale numeric blurbs with role-accurate descriptions
  - updated metadata rows to stop pretending the old totals were authoritative
- **Status:** Fixed

### `docs/01_source_of_truth/CLEANUP_REPORT.md`

- **Zone:** docs / historical audit evidence
- **Purpose:** preserved report from the 2026-03-19 documentation restructuring pass
- **Problems found:**
  - read like an active documentation map rather than a historical cleanup report
- **What was fixed:**
  - added an explicit historical-snapshot banner directing readers to the current documentation index and wiki audit surfaces
- **Status:** Fixed

## Problems found

1. **Master documentation index was still carrying stale March-era quantitative framing**
   - Risk: new contributors trust outdated counts and role descriptions instead of the current repo map.
   - Fix: refreshed descriptions and explicitly linked the index to the live wiki audit layer.

2. **Historical cleanup report was not clearly bounded as historical**
   - Risk: people treat a restructuring report as current operating documentation.
   - Fix: added a historical banner and pointed current readers to the active source-of-truth docs.

## Verification

- inspected both docs against the current repo/wiki state
- `git diff --check`

## Follow-up

- The next source-of-truth docs pass should probably hit `PROJECT_OVERVIEW.md`, because that file still carries several old count-based descriptions that are now lagging behind the live repo.
