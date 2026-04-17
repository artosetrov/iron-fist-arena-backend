---
title: Block 142 — delete wiki Obsidian editor residue
category: audit
tags: [audit, wiki, obsidian, deletion, cleanup]
sources:
  - wiki/.obsidian/app.json
  - wiki/.obsidian/appearance.json
  - wiki/.obsidian/core-plugins.json
  - wiki/.obsidian/graph.json
  - wiki/.obsidian/workspace.json
updated: 2026-04-17
status: Fixed
---

# Block 142 — delete wiki Obsidian editor residue

## Scope

- `wiki/.obsidian/app.json`
- `wiki/.obsidian/appearance.json`
- `wiki/.obsidian/core-plugins.json`
- `wiki/.obsidian/graph.json`
- `wiki/.obsidian/workspace.json`

## Why this block

The wiki inventory still had a silent count gap because five editor-specific Obsidian files existed in `wiki/.obsidian/` but were not part of the maintained wiki file map.

These were local editor state, not project source of truth:

- no runtime consumer
- no docs consumer
- no audit value outside local workstation preferences

So they were safe to remove instead of normalizing them into the repository map.

## What was removed

- local Obsidian app settings
- appearance/theme state
- enabled core-plugin state
- graph-view state
- workspace/window state

## Problems resolved

1. **Wiki count drift**
   - Risk before: actual files under `wiki/` were higher than the maintained inventory count.
   - Resolution: removed the five non-source editor artifacts and restored count parity.

2. **Hidden editor-specific state**
   - Risk before: local workstation preferences sat next to source-of-truth wiki content.
   - Resolution: only intentional wiki content remains in the repo-owned wiki tree.

## Verification

- confirmed the five `wiki/.obsidian/*` files no longer exist
- confirmed wiki file counts and inventory headings now line up again
- `git diff --check`

## Follow-up

- Keep deleting editor-state residue instead of teaching the inventory to treat it as meaningful project content.

