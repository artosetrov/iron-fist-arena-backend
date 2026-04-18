---
title: Audit Block 176 — Stale Audit Tail Audio Bootstrap Boundary Sync
category: audit
tags: [audit, scripts, audio, truth-sync, docs]
sources:
  - wiki/audit/block-006-project-scripts.md
  - scripts/download_sounds.py
  - docs/08_prompts/SOUND_CATALOG.md
  - wiki/audit/block-172-audio-and-asset-doc-boundary-parity.md
updated: 2026-04-17
---

# Audit Block 176 — Stale Audit Tail Audio Bootstrap Boundary Sync

## Why this block exists

The `download_sounds.py` record in `block-006` was still left as `Needs review` because it used to be described as drifting from `SOUND_CATALOG.md`.

That warning was accurate before the later boundary cleanup:

- `scripts/download_sounds.py` now clearly says it is a bootstrap script for a curated Pixabay seed set, not the production audio source of truth
- `docs/08_prompts/SOUND_CATALOG.md` now explicitly says it is a historical prompt/acquisition snapshot, not the live runtime bundle contract

So the old “catalog drift” warning had become a stale audit tail rather than a live unresolved issue.

## What changed

- updated the `scripts/download_sounds.py` record in `block-006`
- replaced the old “still drifted from current audio catalog” wording with the newer boundary truth
- changed the file status from `Needs review` to `Fixed`

## Result

The remaining audio/script risk in `block-006` now stays focused on the surfaces that are still genuinely open, while `download_sounds.py` is documented honestly as:

- a manual bootstrap helper
- not a production audio source of truth
- no longer in silent conflict with the current audio docs
