---
title: Block 126 — design system roadmap and screen inventory live parity
category: audit
tags: [audit, docs, ui, ux, design-system, screen-inventory, historical-boundary]
sources:
  - docs/07_ui_ux/UI_AUDIT_DASHBOARD.html
  - docs/07_ui_ux/DESIGN_SYSTEM.md
  - docs/07_ui_ux/SCREEN_INVENTORY.md
updated: 2026-04-16
status: Fixed
---

# Block 126 — design system roadmap and screen inventory live parity

## Scope

- `docs/07_ui_ux/UI_AUDIT_DASHBOARD.html`
- `docs/07_ui_ux/DESIGN_SYSTEM.md`
- `docs/07_ui_ux/SCREEN_INVENTORY.md`

## Why this block

After the prototype-boundary cleanup, one small but important split remained:

- `UI_AUDIT_DASHBOARD.html` was clearly historical in subtitle text, but still opened like a generic current dashboard
- `DESIGN_SYSTEM.md` is intentionally a live ruleset, yet its old migration roadmap still read like an active delivery queue
- `SCREEN_INVENTORY.md` is a live source-of-truth page, but it still contained at least one stale component reference and one missing-screen entry for a view that no longer exists

That combination is exactly the kind of “mostly right, slightly dangerous” documentation drift that causes quiet confusion later.

## Related pages

- [[block-118-source-of-truth-admin-capabilities-and-screen-inventory-parity]]
- [[block-119-design-system-source-of-truth-vs-audit-snapshot-boundaries]]
- [[block-125-ui-prototype-and-figma-workflow-boundaries]]
- [[design-principles]]

## File notes

### `docs/07_ui_ux/UI_AUDIT_DASHBOARD.html`

- **Zone:** historical forensic dashboard
- **Purpose:** direct-open HTML summary of one full UI audit pass
- **Problems found:**
  - subtitle already admitted historical scope, but the file title and top heading still looked like a generic current dashboard
- **What was fixed:**
  - added archival comment plus historical framing in the page title and top heading
- **Status:** Fixed

### `docs/07_ui_ux/DESIGN_SYSTEM.md`

- **Zone:** live design-system ruleset
- **Purpose:** current rules, tokens, and component conventions for UI work
- **Problems found:**
  - the document is intentionally live, but section 16 still presented an old migration rollout as if it were the active implementation plan
- **What was fixed:**
  - reframed the migration roadmap as a historical archival appendix while preserving the live status of the rest of the document
- **Status:** Fixed

### `docs/07_ui_ux/SCREEN_INVENTORY.md`

- **Zone:** live screen/source map
- **Purpose:** current coded screen inventory and Figma-gap snapshot for the iOS app
- **Problems found:**
  - Hero Detail still referenced `HeroIntegratedCard` even though the code now uses `IntegratedCharacterCard`
  - embedded-components table still listed `HeroIntegratedCard` and `OpponentIntegratedCard` instead of the shared component that replaced them
  - Figma-gap snapshot still mentioned `LoreIntroView.swift`, which no longer exists in the live codebase
- **What was fixed:**
  - updated the Hero Detail description and component table to the shared `IntegratedCharacterCard`
  - removed the stale `LoreIntroView.swift` line from the Figma-gap snapshot
- **Status:** Fixed

## Problems found

1. **Historical dashboards can still look current from the browser tab alone**
   - Risk: a reader opens the file directly and trusts the title before reading the subtitle caveat.
   - Fix: added explicit historical framing to the HTML title/header.

2. **Live source-of-truth docs can hide stale rollout plans inside otherwise correct content**
   - Risk: engineers treat an archival migration schedule as the current delivery plan.
   - Fix: narrowed only the migration roadmap section in `DESIGN_SYSTEM.md` to archival status.

3. **Live inventory docs had begun to drift from shipped component names**
   - Risk: downstream audits and design mapping start from deleted component names.
   - Fix: rewired `SCREEN_INVENTORY.md` to the current shared `IntegratedCharacterCard` and removed the nonexistent `LoreIntroView.swift` entry.

## Verification

- rechecked current code paths for `IntegratedCharacterCard`
- confirmed `HeroIntegratedCard` / `OpponentIntegratedCard` no longer exist as live files
- confirmed `LoreIntroView.swift` is absent from the current iOS tree
- `git diff --check`

## Follow-up

- Continue the same pass through the remaining source-of-truth docs where live rules and historical rollout notes still share one file.
- Keep `SCREEN_INVENTORY.md` aligned to live component names whenever shared UI refactors land.
