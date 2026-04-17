---
title: Block 132 — Obsidian base artifacts
category: audit
tags: [audit, docs, editor-artifact, deprecated]
sources:
  - docs/Untitled.base
  - docs/Untitled 1.base
  - docs/Untitled 2.base
updated: 2026-04-16
status: Fixed
---

# Block 132 — Obsidian base artifacts

## Scope

- `docs/Untitled.base`
- `docs/Untitled 1.base`
- `docs/Untitled 2.base`

## Why this block

These files sit in the root `docs/` surface with generic names and editor-state-style content. They do not behave like project documentation, but they are still visible enough to confuse a repo-wide audit or a new contributor scanning the tree.

The main job here is not to over-edit them. It is to name the risk clearly and mark them as likely editor residue instead of pretending they are meaningful docs.

## Related pages

- [[block-131-empty-doc-placeholders-and-deprecation-markers]]
- [[block-128-retro-log-historical-boundaries]]
- [[bug-patterns]]

## File notes

### `docs/Untitled.base`

- **Zone:** root docs editor artifact
- **Purpose:** likely Obsidian/base-view residue, not product or engineering documentation
- **What it does:** stores a trivial table-view stanza
- **Problem found:** generic filename plus non-doc content makes it look accidental and non-canonical
- **What to keep:** nothing as source-of-truth
- **What to fix:** decide whether any local tooling still expects `.base` artifacts
- **What to delete:** likely candidate for removal once editor dependency is ruled out
- **Status:** Deprecated candidate

### `docs/Untitled 1.base`

- **Zone:** root docs editor artifact
- **Purpose:** likely duplicate Obsidian/base-view residue
- **What it does:** same trivial table-view stanza as `Untitled.base`
- **Problem found:** duplicate unnamed artifact with no repo-facing meaning
- **What to keep:** nothing as source-of-truth
- **What to fix:** confirm no editor workflow still uses it
- **What to delete:** likely candidate for removal
- **Status:** Deprecated candidate

### `docs/Untitled 2.base`

- **Zone:** root docs editor artifact
- **Purpose:** same family of residue, already boundary-marked in block 131
- **What it does:** no live doc behavior; currently only carries a placeholder warning
- **Problem found:** root-level artifact remains visible and non-canonical
- **What to keep:** only if a local editor still needs it
- **What to fix:** same dependency check as the other `.base` files
- **What to delete:** likely candidate for removal after confirmation
- **Status:** Deprecated candidate

## Problems found

1. **Editor-state residue is mixed into the live docs surface**
   - Risk: generic root filenames pollute the file-by-file map and create noise during repo navigation.
   - Proposed fix: confirm whether `.base` artifacts are used by any real local workflow; if not, remove them.

2. **Two artifacts are still almost content-free and unnamed**
   - Risk: contributors may treat them as accidental corruption or undocumented required files.
   - Proposed fix: final cleanup should either delete them or move them to an editor-specific ignored area.

3. **`docs/Untitled 2.base` is now self-labeled, but the trio still belongs to the same residue class**
   - Risk: the repo remains inconsistent if only one of the three is visibly explained.
   - Proposed fix: resolve the whole `.base` group together.

## Verification

- confirmed the repo only contains three `.base` files
- confirmed `Untitled.base` and `Untitled 1.base` share the same trivial table-view content
- confirmed `Untitled 2.base` was already flagged in the previous placeholder cleanup
- `git diff --check`

## Follow-up

- Resolved in [[block-134-delete-placeholder-and-editor-artifact-files]] by deleting the entire `.base` group from the working tree.
