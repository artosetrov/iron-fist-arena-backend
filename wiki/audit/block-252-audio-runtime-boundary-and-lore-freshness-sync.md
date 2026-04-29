---
title: Audit Block 252 — Audio Runtime Boundary and Lore Freshness Sync
category: audit
tags: [audit, docs, audio, lore, metadata]
sources:
  - docs/02_product_and_features/AUDIO_DESIGN.md
  - docs/02_product_and_features/WORLD_AND_LORE.md
  - Hexbound/Hexbound/Persistence/AudioManager.swift
  - Hexbound/Hexbound/Persistence/AmbientManager.swift
  - Hexbound/Hexbound/Persistence/SFXCatalog.swift
  - Hexbound/Hexbound/Views/Settings/SettingsDetailView.swift
  - Hexbound/Hexbound/Views/Settings/SettingsViewModel.swift
  - sounds/
updated: 2026-04-29
status: Fixed
---

# Audit Block 252 — Audio Runtime Boundary and Lore Freshness Sync

## Scope

- `docs/02_product_and_features/AUDIO_DESIGN.md`
- `docs/02_product_and_features/WORLD_AND_LORE.md`

## Why this block

The active product docs had a small but real narrative drift:

- `AUDIO_DESIGN.md` still said “Planning / pre-production. No audio assets exist yet,” even though the repo already ships:
  - bundled `sounds/`
  - `AudioManager`
  - `AmbientManager`
  - `SFXCatalog`
  - live Settings audio controls
- the same doc still described the Settings audio surface like a future plan instead of the current toggles/sliders
- `WORLD_AND_LORE.md` was simply stale on freshness metadata and still talked about guild lore as something to think about “when guilds are added,” even though Guild Hall / social surfaces already exist

## Fix applied

- rewrote the `AUDIO_DESIGN.md` status line into a truthful hybrid-runtime boundary
- added a `Current Runtime Snapshot` section covering the live audio managers, bundled assets, settings controls, and current haptics limitation
- rewrote the Settings controls matrix in `AUDIO_DESIGN.md` to match the live iOS surface
- reframed the asset sourcing section as a historical/planning appendix instead of current runtime truth
- updated `WORLD_AND_LORE.md` freshness metadata to `2026-04-29`
- rewrote the future guild-lore hook so it now builds on the already-live Guild Hall/social foundation instead of pretending that guild surfaces do not exist yet

## Result

The audio design doc now stops pretending the project has no audio runtime, and the world/lore doc no longer carries an obviously outdated guild-future sentence. Both files are back in sync with the current repo state.

## Verification

- checked `sounds/`
- checked `AudioManager.swift`, `AmbientManager.swift`, and `SFXCatalog.swift`
- checked live Settings audio controls in `SettingsDetailView.swift` and `SettingsViewModel.swift`
- `git diff --check`
