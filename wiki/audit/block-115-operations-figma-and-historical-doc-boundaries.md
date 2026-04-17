---
title: Block 115 — Operations Figma and historical doc boundaries
category: audit
tags: [audit, docs, operations, figma, qa]
sources:
  - docs/10_operations/FIGMA_HANDOFF.md
  - docs/10_operations/FIGMA_SCREEN_INVENTORY.md
  - docs/10_operations/PROGRESS_LOG.md
  - docs/10_operations/SIMULATOR_PLAYTEST_BUGS_2026-04-09.md
  - docs/10_operations/UI_PR_CHECKLIST.md
updated: 2026-04-16
status: Fixed
---

# Block 115 — Operations Figma and historical doc boundaries

## Scope

- `docs/10_operations/FIGMA_HANDOFF.md`
- `docs/10_operations/FIGMA_SCREEN_INVENTORY.md`
- `docs/10_operations/PROGRESS_LOG.md`
- `docs/10_operations/SIMULATOR_PLAYTEST_BUGS_2026-04-09.md`
- `docs/10_operations/UI_PR_CHECKLIST.md`

## Why this block

This slice was not broken code, but it did contain a quieter kind of operational drift:

- handoff docs that still read like live source-of-truth specs
- historical bug and progress notes that were easy to misread as the current backlog
- one stale path reference inside the Figma handoff
- one ambiguous lint command in the UI review checklist

That kind of documentation debt does not crash the app, but it absolutely slows the team down and creates false confidence.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-109-operations-deploy-docs-reality-sync]]
- [[block-114-wiki-feature-maps-and-index-visibility]]

## File notes

### `docs/10_operations/FIGMA_HANDOFF.md`

- **Zone:** operations / design handoff
- **Purpose:** planning snapshot for transferring the product surface into Figma
- **Problems found:**
  - referenced the wrong inventory path: `docs/FIGMA_SCREEN_INVENTORY.md`
  - used a wildcard-like source path `admin/src/components/ui/*`, which is not a real file path
  - read too much like a live design source of truth without saying what newer references exist
- **What was fixed:**
  - corrected the inventory path to `docs/10_operations/FIGMA_SCREEN_INVENTORY.md`
  - normalized the admin UI source reference to `admin/src/components/ui/`
  - added a source-of-truth banner pointing readers to current wiki/entities/code surfaces
- **Status:** Fixed

### `docs/10_operations/FIGMA_SCREEN_INVENTORY.md`

- **Zone:** operations / design handoff
- **Purpose:** screen inventory snapshot for Figma transfer planning
- **Problems found:**
  - lacked an explicit boundary between “handoff snapshot” and “live navigation truth”
- **What was fixed:**
  - added a source-of-truth banner telling readers to revalidate against router/screen catalog/wiki before using it as implementation truth
- **Status:** Fixed

### `docs/10_operations/PROGRESS_LOG.md`

- **Zone:** operations / historical audit log
- **Purpose:** preserved working notebook from the earlier long-form repo audit
- **Problems found:**
  - began immediately with the original audit prompt, making it easy to read as a live status document
- **What was fixed:**
  - added a historical-notebook banner and redirected current-status usage to the wiki audit/index/log surfaces
- **Status:** Fixed

### `docs/10_operations/SIMULATOR_PLAYTEST_BUGS_2026-04-09.md`

- **Zone:** operations / historical QA evidence
- **Purpose:** point-in-time simulator bug report from 2026-04-09
- **Problems found:**
  - easy to misread as the current active bug backlog even though many issues have since moved
- **What was fixed:**
  - added a historical snapshot banner that points readers to the live audit/wiki trackers for current status
- **Status:** Fixed

### `docs/10_operations/UI_PR_CHECKLIST.md`

- **Zone:** operations / review checklist
- **Purpose:** repeatable UI review gate for Swift/iOS view work
- **Problems found:**
  - no source-of-truth framing
  - `swiftlint` command was too ambiguous about working directory/config
- **What was fixed:**
  - added a source-of-truth banner tied to the live theme/rules/wiki surfaces
  - replaced the vague SwiftLint line with the exact repo-safe invocation
- **Status:** Fixed

## Problems found

1. **Historical docs blurred into live operational truth**
   - Risk: teammates use old investigation logs or one-time bug reports as the current backlog/spec.
   - Fix: added explicit historical/source-of-truth boundaries.

2. **Figma handoff doc contained stale internal references**
   - Risk: the handoff points readers at the wrong file path and a not-quite-real source path.
   - Fix: corrected both references and linked the handoff back to current code/wiki truth.

3. **UI checklist had an ambiguous lint command**
   - Risk: people run SwiftLint from the wrong place and assume the checklist is satisfied.
   - Fix: documented the exact repo-safe command.

## Verification

- inspected all five docs against the current repo layout
- checked referenced paths against live files/folders
- `git diff --check`

## Follow-up

- The next docs-level cleanup should probably hit `docs/10_operations/DOCUMENTATION_INDEX` neighbors and remaining historical QA/retro documents that still read like live instructions instead of archived evidence.
