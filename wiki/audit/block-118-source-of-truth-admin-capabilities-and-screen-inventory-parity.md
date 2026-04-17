---
title: Block 118 — Source-of-truth admin capabilities and screen inventory parity
category: audit
tags: [audit, docs, source-of-truth, admin, ios, screens]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - docs/07_ui_ux/SCREEN_INVENTORY.md
  - admin/package.json
  - Hexbound/Hexbound/App/AppRouter.swift
  - Hexbound/Hexbound/Views/Dev/ScreenCatalogView.swift
updated: 2026-04-16
status: Fixed
---

# Block 118 — Source-of-truth admin capabilities and screen inventory parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `docs/07_ui_ux/SCREEN_INVENTORY.md`
- `admin/package.json`
- `Hexbound/Hexbound/App/AppRouter.swift`
- `Hexbound/Hexbound/Views/Dev/ScreenCatalogView.swift`

## Why this block

These two docs still looked like source-of-truth files, but both had the same failure mode:

- stale freshness banners
- count-heavy wording that had already drifted
- summary claims that were stronger than the code could safely back up

That is exactly the kind of documentation bug that wastes review time. Nothing crashes, but the next person quietly starts from the wrong map.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-117-source-of-truth-project-overview-parity]]

## File notes

### `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

- **Zone:** docs / admin source-of-truth
- **Purpose:** high-level capability map of the admin panel by responsibility area
- **Problems found:**
  - still read as last updated `2026-03-19`
  - opened with “complete reference of all `37+` pages”, even though count-based wording had already gone stale
  - claimed `Next.js 14`, while the live admin package is on Next 15
  - used absolute wording about admin access that is too strong for a high-level doc
  - section/page headings still embedded brittle page counts
- **What was fixed:**
  - refreshed the banner and reframed the doc as a capability map, not a perfect security matrix
  - corrected the stack wording to `Next.js 15`
  - removed stale page/config count language from key headings and summary copy
  - clarified that route/action permissions must be treated as code-enforced, per-surface behavior
- **Status:** Fixed

### `docs/07_ui_ux/SCREEN_INVENTORY.md`

- **Zone:** docs / iOS UI source-of-truth
- **Purpose:** coded screen map of the iOS app and a Figma coverage snapshot
- **Problems found:**
  - still read as last updated `2026-04-04`
  - summary line used stale totals (`70+`, `46`, `15`) as if they were live facts
  - multiple section headers embedded screen counts that had already drifted from the tables beneath them
  - Figma coverage section read too much like release truth instead of a snapshot gap-analysis
- **What was fixed:**
  - refreshed the banner and explicitly tied the doc to live router/screen files for revalidation
  - replaced brittle total-count wording with area-based coverage wording
  - removed section-level screen counts from headers
  - reframed the Figma block as a snapshot that must be revalidated against the current file and navigation map
- **Status:** Fixed

### `admin/package.json`

- **Zone:** runtime evidence
- **Purpose:** source for current admin framework version wording
- **Review outcome:**
  - confirms the admin surface is on `next: ^15.2.0` and `typescript: ^5.7.0`
- **Status:** OK

### `Hexbound/Hexbound/App/AppRouter.swift` and `Hexbound/Hexbound/Views/Dev/ScreenCatalogView.swift`

- **Zone:** runtime evidence
- **Purpose:** support the claim that screen inventory should be validated against live routing and screen catalog, not only against historical counts
- **Review outcome:**
  - both remain the better live evidence sources than hardcoded count language in the doc
- **Status:** OK

## Problems found

1. **Count-heavy source-of-truth docs had already drifted**
   - Risk: people trust stale totals and outdated headings as if they were current system facts.
   - Fix: removed brittle count framing where the role of the surface matters more than the exact number.

2. **Admin capabilities doc overstated permission certainty**
   - Risk: readers mistake a capabilities summary for a formal auth matrix.
   - Fix: clarified that permission boundaries are enforced in code per route/action and that this doc is not the final security authority.

3. **Screen inventory mixed live navigation truth with snapshot design-gap truth**
   - Risk: people treat a point-in-time Figma gap list as if it were guaranteed current coverage.
   - Fix: explicitly labeled the Figma section as snapshot gap analysis and pointed readers back to live routing/screens.

4. **Admin stack wording lagged behind the actual package version**
   - Risk: onboarding and review start from a wrong framework baseline.
   - Fix: corrected the stack wording to the live Next 15 package reality.

## Verification

- inspected `ADMIN_CAPABILITIES.md`
- inspected `SCREEN_INVENTORY.md`
- checked `admin/package.json`
- checked `Hexbound/Hexbound/App/AppRouter.swift`
- checked `Hexbound/Hexbound/Views/Dev/ScreenCatalogView.swift`
- `git diff --check`

## Follow-up

- The next adjacent source-of-truth pass should keep moving through the remaining count-heavy or snapshot-heavy docs under `docs/05_admin_panel/`, `docs/07_ui_ux/`, and any other historical inventories that still read like current guaranteed truth.
