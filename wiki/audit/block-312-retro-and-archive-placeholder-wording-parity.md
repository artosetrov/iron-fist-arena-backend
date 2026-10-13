---
title: Audit Block 312 — Retro and Archive Placeholder Wording Parity
category: audit
tags: [audit, retro, archive, docs, wording]
sources:
  - docs/retro/RETRO_2026-03-25.md
  - docs/11_archive/HEXBOUND_UI_UX_AUDIT_GUIDE_v1.md
  - wiki/audit/project-file-inventory.md
  - git ls-files
  - git ls-files --others --exclude-standard
updated: 2026-05-06
status: Fixed
---

# Audit Block 312 — Retro and Archive Placeholder Wording Parity

## Scope

This block closes the next small historical-language seam after the broader
route-less cleanup: one retro note and one archive guide still used older
placeholder phrasing more literally than the rest of the repo now does.

## Why this block

The project has already standardized around clearer repo-owned wording:

- `route-less placeholder` when a surface has no live route yet
- `historical / design-only / superseded` when an older proposal no longer
  matches runtime

Two checked-in docs still lagged behind that cleanup:

- `RETRO_2026-03-25.md` still quoted the older placeholder/future-stub wording
  more literally than necessary while describing the messaging-doc fix
- `HEXBOUND_UI_UX_AUDIT_GUIDE_v1.md` still labeled the old bottom-navigation
  section as `NOT IMPLEMENTED IN CODE` instead of the more precise archived
  truth that the design was superseded by the CityMapView runtime model

## Changes shipped

- Reworded the messaging-system retro note so it now describes the old Guild
  Hall doc drift as placeholder/future-stub language instead of repeating the
  older literal phrasing.
- Renamed the archive-guide bottom-navigation subsection to
  `Design-Only; Superseded in Runtime`, which matches the explanatory text
  already present immediately below it.
- Rolled the inventory forward again so it now includes block `312` and the
  current tracked/untracked totals.

## Result

The retro/archive layer now matches the wording cleanup standard used in the
rest of the repo: older placeholder language is preserved as history when
needed, but the checked-in docs no longer reintroduce that phrasing as their
own present-tense voice.
