---
title: Block 129 — archive legacy doc boundaries
category: audit
tags: [audit, docs, archive, legacy, historical-boundary]
sources:
  - docs/11_archive/ADMIN_PANEL_AUDIT_REPORT_2026-03-16.md
  - docs/11_archive/ART_STYLE_GUIDE_DUPLICATE.md
  - docs/11_archive/BALANCE_AUDIT_REPORT_2026-03-09.md
  - docs/11_archive/CLAUDE_2_LEGACY.md
  - docs/11_archive/HEXBOUND_UI_UX_AUDIT_GUIDE_v1.md
  - docs/11_archive/PROJECT_KNOWLEDGE_v2_LEGACY.md
  - docs/11_archive/UI_DESIGN_DOCUMENT_LEGACY.md
  - docs/11_archive/mine-card-prompts_DUPLICATE.md
updated: 2026-04-16
status: Fixed
---

# Block 129 — archive legacy doc boundaries

## Scope

- `docs/11_archive/ADMIN_PANEL_AUDIT_REPORT_2026-03-16.md`
- `docs/11_archive/ART_STYLE_GUIDE_DUPLICATE.md`
- `docs/11_archive/BALANCE_AUDIT_REPORT_2026-03-09.md`
- `docs/11_archive/CLAUDE_2_LEGACY.md`
- `docs/11_archive/HEXBOUND_UI_UX_AUDIT_GUIDE_v1.md`
- `docs/11_archive/PROJECT_KNOWLEDGE_v2_LEGACY.md`
- `docs/11_archive/UI_DESIGN_DOCUMENT_LEGACY.md`
- `docs/11_archive/mine-card-prompts_DUPLICATE.md`

## Why this block

The archive folder already signaled intent at the directory level, but several individual files still opened as if they were self-contained living references. That is fine for raw preservation, but not for a repo that now depends on a strict source-of-truth discipline.

This block tightens that boundary without deleting any historical material.

## Related pages

- [[block-127-dated-product-economy-and-architecture-doc-boundaries]]
- [[block-128-retro-log-historical-boundaries]]
- [[design-principles]]
- [[bug-patterns]]

## File notes

### `docs/11_archive/ADMIN_PANEL_AUDIT_REPORT_2026-03-16.md`

- **Zone:** archived admin audit
- **Purpose:** preserves an early admin/liveops capability review
- **Problem found:** opened like a standalone current assessment
- **Fix:** added a historical admin-audit boundary
- **Status:** Fixed

### `docs/11_archive/BALANCE_AUDIT_REPORT_2026-03-09.md`

- **Zone:** archived balance audit
- **Purpose:** preserves an early balance/economy review
- **Problem found:** detailed recommendations still looked authoritative without a date-boundary reminder
- **Fix:** added a historical balance-audit boundary
- **Status:** Fixed

### `docs/11_archive/ART_STYLE_GUIDE_DUPLICATE.md`

- **Zone:** archived duplicate
- **Purpose:** duplicate copy of art prompting guidance
- **Problem found:** duplicate status was only implied by filename
- **Fix:** added an explicit archived-duplicate boundary
- **Status:** Fixed

### `docs/11_archive/CLAUDE_2_LEGACY.md`

- **Zone:** legacy workflow/rules snapshot
- **Purpose:** preserves an older assistant/project-rules document
- **Problem found:** still read like a direct rules source on open
- **Fix:** added a legacy-rulebook boundary pointing away from live rules
- **Status:** Fixed

### `docs/11_archive/HEXBOUND_UI_UX_AUDIT_GUIDE_v1.md`

- **Zone:** archived UI audit guide
- **Purpose:** preserves an earlier UI/UX audit framework and standards pass
- **Problem found:** “canonical standards” language was too strong without an archive boundary
- **Fix:** added a historical UI-audit-guide boundary
- **Status:** Fixed

### `docs/11_archive/PROJECT_KNOWLEDGE_v2_LEGACY.md`

- **Zone:** legacy project knowledge snapshot
- **Purpose:** preserves an earlier architecture/product knowledge base from the web+Godot phase
- **Problem found:** still claimed to be a single source of truth
- **Fix:** added a strong legacy-knowledge boundary redirecting readers to current sources
- **Status:** Fixed

### `docs/11_archive/UI_DESIGN_DOCUMENT_LEGACY.md`

- **Zone:** legacy design document
- **Purpose:** preserves an older large UI design spec
- **Problem found:** still read like a broad current UI contract
- **Fix:** added a legacy design-document boundary
- **Status:** Fixed

### `docs/11_archive/mine-card-prompts_DUPLICATE.md`

- **Zone:** archived duplicate prompt file
- **Purpose:** preserves a duplicate copy of Gold Mine art prompts
- **Problem found:** duplicate/archive status was not explicit inside the file
- **Fix:** added an archived-duplicate boundary
- **Status:** Fixed

## Problems found

1. **Archive folder intent was not enough by itself**
   - Risk: direct-open files can still be mistaken for current guidance if they do not self-identify.
   - Fix: added explicit historical/legacy/duplicate boundaries inside the files themselves.

2. **Legacy documents still made strong source-of-truth claims**
   - Risk: old rules and old project-knowledge docs can silently compete with current repo truth.
   - Fix: redirected those claims back toward live rules, code, and audited wiki surfaces.

3. **Duplicate prompt/style files needed clearer self-labeling**
   - Risk: duplicate docs get edited or cited instead of the current canonical prompt catalogs.
   - Fix: marked them explicitly as archived duplicates.

## Verification

- inspected the opening sections of all eight archive files
- confirmed each now self-identifies as historical, legacy, or duplicate
- `git diff --check`

## Follow-up

- Continue through the remaining top-level legacy/old-process docs outside `docs/11_archive/` until every historical surface self-identifies on open.
