---
title: Audit Block 172 — Audio and Asset Doc Boundary Parity
category: audit
tags: [audit, docs, audio, assets, source-of-truth]
sources:
  - docs/08_prompts/SOUND_CATALOG.md
  - docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md
  - Hexbound/Hexbound/Persistence/SFXCatalog.swift
  - scripts/sync-assets.sh
  - wiki/audit/block-006-project-scripts.md
updated: 2026-04-17
---

# Audit Block 172 — Audio and Asset Doc Boundary Parity

## Why this block exists

`block-006` had already identified two lingering documentation drifts around project scripts:

1. `docs/08_prompts/SOUND_CATALOG.md` still read like a live runtime audio catalog even though the app now owns real cue naming and file-extension truth in `SFXCatalog.swift`
2. `docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md` was already marked historical, but several sections still spoke as if the old `512px` `sync-assets.sh` cap were the current script behavior

Neither document needed deletion. They just needed honest boundaries.

## What changed

### `docs/08_prompts/SOUND_CATALOG.md`

- added an explicit status-boundary note at the top
- clarified that the `.mp3` file column reflects the original acquisition/prompt plan
- clarified that live runtime naming and extension truth now belong to:
  - `Hexbound/Hexbound/Persistence/SFXCatalog.swift`
  - the current bundled audio assets

### `docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md`

- kept the `2026-04-03` audit findings intact
- rewrote the old `512px` sections so they read as **historical findings at audit time**
- explicitly noted that the later script floor was raised to `1024px`
- preserved the design rule itself without pretending the old exact number is still current code

## Result

These docs now behave correctly:

- `SOUND_CATALOG.md` = historical prompt/acquisition planning artifact
- `ASSET_CONSISTENCY_AUDIT.md` = historical forensic asset audit
- runtime truth = current code, bundle contents, and live script implementations

That means `block-006` no longer has to carry these as silent “still stale” docs; the remaining open tails are narrower policy questions, not mislabeled source-of-truth surfaces.
