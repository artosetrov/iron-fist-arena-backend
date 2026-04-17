---
title: Block 130 — top-level source-of-truth and orchestration boundaries
category: audit
tags: [audit, docs, source-of-truth, orchestration, historical-boundary]
sources:
  - docs/PROJECT_INDEX.md
  - docs/SOURCE_OF_TRUTH.md
  - docs/AGENT_LOADING_GUIDE.md
  - docs/ORCHESTRATOR.md
  - docs/00_studio/STUDIO_COMMAND_CENTER.md
  - docs/01_source_of_truth/DOCUMENTATION_INDEX.md
updated: 2026-04-16
status: Fixed
---

# Block 130 — top-level source-of-truth and orchestration boundaries

## Scope

- `docs/PROJECT_INDEX.md`
- `docs/SOURCE_OF_TRUTH.md`
- `docs/AGENT_LOADING_GUIDE.md`
- `docs/ORCHESTRATOR.md`
- `docs/00_studio/STUDIO_COMMAND_CENTER.md`
- `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`

## Why this block

By this point the repo already had a much stronger live source-of-truth layer in `wiki/` plus a deeply audited code/documentation core. The remaining problem was the very top of `docs/`: several entry-point documents still described a March snapshot of the project or read like live operating constitutions.

That is a real navigation risk. These are exactly the files a new contributor or agent opens first.

## Related pages

- [[block-109-operations-deploy-docs-reality-sync]]
- [[block-116-source-of-truth-doc-index-parity]]
- [[block-117-source-of-truth-project-overview-parity]]
- [[design-principles]]

## File notes

### `docs/PROJECT_INDEX.md`

- **Zone:** top-level docs navigator
- **Purpose:** high-level entry point into the documentation tree
- **Problem found:** still carried stale March freshness plus count-heavy stack claims (`iOS 16.4+`, `38+ screens`, `40+ Prisma models`) and did not clearly redirect to `wiki/` for current audit reality
- **Fix:** updated freshness, removed fragile count-based claims, corrected iOS target to 17.0, and added explicit `wiki/` pointers for current audit/ownership state
- **Status:** Fixed

### `docs/SOURCE_OF_TRUTH.md`

- **Zone:** top-level source-of-truth routing matrix
- **Purpose:** clarifies which surface wins when docs disagree
- **Problem found:** lacked the now-central `wiki/` audit layer and still read as if `docs/` alone defined current truth
- **Fix:** added `wiki/` as the current audit/ownership layer and tightened conflict rules around code, fresh audited docs, and historical snapshots
- **Status:** Fixed

### `docs/AGENT_LOADING_GUIDE.md`

- **Zone:** agent documentation loading guide
- **Purpose:** tells agents which docs to open for common task types
- **Problem found:** still routed broad tasks through March-era top-level docs without enough warning about historical review/prototype documents
- **Fix:** added `wiki/` as the first stop for repo-wide tasks, clarified historical-boundary checks, and aligned documentation-update guidance with the audited wiki flow
- **Status:** Fixed

### `docs/ORCHESTRATOR.md`

- **Zone:** agent/studio orchestration framework
- **Purpose:** preserves an earlier agent-role operating model
- **Problem found:** opened like a current required operating contract for the repo
- **Fix:** added an explicit historical operating-framework boundary and redirected readers to live repo execution sources
- **Status:** Fixed

### `docs/00_studio/STUDIO_COMMAND_CENTER.md`

- **Zone:** studio operations framework
- **Purpose:** preserves a broad studio-role/command-center model
- **Problem found:** said `Active Operating Framework`, which overstated its current role and could compete with the live repo process
- **Fix:** reframed it as a historical operating-framework snapshot and linked to live current references
- **Status:** Fixed

### `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`

- **Zone:** documentation catalog
- **Purpose:** index of the doc tree and its entry points
- **Problem found:** descriptions for `PROJECT_INDEX`, `SOURCE_OF_TRUTH`, and `AGENT_LOADING_GUIDE` did not reflect the new audited `wiki/` layer
- **Fix:** updated their descriptions so the doc index now points readers toward `wiki/` for current repo reality
- **Status:** Fixed

## Problems found

1. **Top-level docs still described a March snapshot as if it were present-day fact**
   - Risk: new readers can trust stale counts and outdated platform/version language before they ever reach live code or audited wiki notes.
   - Fix: removed fragile count-heavy claims and updated freshness/boundary wording.

2. **The audited `wiki/` layer was not reflected in the top-level source-of-truth docs**
   - Risk: readers miss the strongest current file-by-file audit surface and keep treating narrative docs as the freshest truth.
   - Fix: explicitly routed `PROJECT_INDEX`, `SOURCE_OF_TRUTH`, `AGENT_LOADING_GUIDE`, and `DOCUMENTATION_INDEX` through `wiki/`.

3. **Studio/orchestrator documents overstated their current authority**
   - Risk: they can be read as mandatory live process documents, even though they now function as historical operating models.
   - Fix: added strong historical boundaries and redirected to live repo references.

## Verification

- reviewed the edited headers and top sections of all six files
- confirmed stale `2026-03-26` freshness banners were removed from the three top-level routing docs
- confirmed `ORCHESTRATOR.md` and `STUDIO_COMMAND_CENTER.md` now self-identify as historical framework snapshots
- `git diff --check`

## Follow-up

- Continue through the remaining residual top-level governance and archive-adjacent docs so every root `docs/` entry point clearly distinguishes live repo truth from historical process narrative.
