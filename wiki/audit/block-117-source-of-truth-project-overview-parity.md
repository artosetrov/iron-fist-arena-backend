---
title: Block 117 — Source-of-truth project overview parity
category: audit
tags: [audit, docs, source-of-truth, overview]
sources:
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
  - backend/package.json
  - admin/package.json
  - Hexbound/Hexbound.xcodeproj/project.pbxproj
updated: 2026-04-16
status: Fixed
---

# Block 117 — Source-of-truth project overview parity

## Scope

- `docs/01_source_of_truth/PROJECT_OVERVIEW.md`
- `backend/package.json`
- `admin/package.json`
- `Hexbound/Hexbound.xcodeproj/project.pbxproj`

## Why this block

`PROJECT_OVERVIEW.md` is one of the first files a new engineer or reviewer will open. That means it cannot quietly lag behind the codebase.

Before this pass, it still carried a March-era shape:

- stale freshness banner
- count-heavy descriptions that were already drifting
- outdated iOS minimum version
- overly simplified deploy wording that no longer matched the real backend/admin/iOS release flow

None of that would crash production, but it absolutely would mislead onboarding and review work.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-116-source-of-truth-doc-index-parity]]

## File notes

### `docs/01_source_of_truth/PROJECT_OVERVIEW.md`

- **Zone:** docs / high-level architecture overview
- **Purpose:** one-file summary of stack, systems, schema surface, app areas, admin areas, and operational model
- **Problems found:**
  - still read as “last verified 2026-03-19”
  - used many brittle count-based descriptions (`40+ models`, `38+ screens`, `38 Pages`, `80+ skills`, `150+ nodes`, `80+ config keys`)
  - claimed iOS minimum `16.4+`, while the live Xcode project target is `17.0`
  - described backend/admin deploy flow too loosely compared to the now-updated operations docs
- **What was fixed:**
  - updated freshness banner and pointed readers to `wiki/` for live audit state
  - normalized framework/version wording to the current package reality (`Next.js 15.x`, `TypeScript 5.7.x`, `Prisma 6.x`)
  - corrected iOS minimum to `17.0`
  - replaced brittle count-based descriptions with role-accurate, lower-maintenance descriptions
  - clarified backend/admin deploy and migration semantics to match the audited operations docs
- **Status:** Fixed

### `backend/package.json` and `admin/package.json`

- **Zone:** runtime evidence
- **Purpose:** live version source for framework/tooling statements in the overview doc
- **Review outcome:**
  - still use semver ranges rooted at Next 15.2 / TS 5.7 / Prisma 6.4
  - better reflected in docs as `15.x / 5.7.x / 6.x` than as falsely precise locked versions
- **Status:** OK

### `Hexbound/Hexbound.xcodeproj/project.pbxproj`

- **Zone:** runtime evidence
- **Purpose:** authoritative iOS deployment target
- **Review outcome:**
  - confirms `IPHONEOS_DEPLOYMENT_TARGET = 17.0`
- **Status:** OK

## Problems found

1. **Overview doc still carried stale quantitative framing**
   - Risk: people trust old counts as if they are current architecture facts.
   - Fix: replaced brittle counts with role-based descriptions wherever the exact number is not the point.

2. **iOS deployment target was wrong in the overview**
   - Risk: onboarding and release assumptions drift from the actual Xcode project.
   - Fix: corrected the minimum iOS version to `17.0`.

3. **Overview deploy language lagged behind current ops docs**
   - Risk: readers think admin deploy and migration apply are more automatic than they really are.
   - Fix: aligned the wording with the audited operations runbooks.

## Verification

- inspected `PROJECT_OVERVIEW.md`
- checked live package versions in `backend/package.json` and `admin/package.json`
- checked iOS deployment target in `Hexbound/Hexbound.xcodeproj/project.pbxproj`
- `git diff --check`

## Follow-up

- The next adjacent source-of-truth pass should probably hit `docs/05_admin_panel/ADMIN_CAPABILITIES.md` and `docs/07_ui_ux/SCREEN_INVENTORY.md`, because they still carry some older count-heavy wording and March/April freshness banners.
