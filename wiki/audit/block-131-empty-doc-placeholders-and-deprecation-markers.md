---
title: Block 131 — empty doc placeholders and deprecation markers
category: audit
tags: [audit, docs, placeholder, deprecated, cleanup]
sources:
  - docs/06_game_systems/ECONOMY_MODEL_V2.md
  - docs/Untitled 2.base
  - docs/_COMMUNITY_Community 284.md
updated: 2026-04-16
status: Fixed
---

# Block 131 — empty doc placeholders and deprecation markers

## Scope

- `docs/06_game_systems/ECONOMY_MODEL_V2.md`
- `docs/Untitled 2.base`
- `docs/_COMMUNITY_Community 284.md`

## Why this block

These files were worse than ordinary stale docs because they were effectively silent holes in the repository: committed, visible, and named like they might matter, but empty. That creates a subtle audit problem. Readers cannot tell whether the file was intentionally reserved, accidentally committed, or silently supposed to contain live design material.

This block makes their status explicit without deleting anything prematurely.

## Related pages

- [[block-127-dated-product-economy-and-architecture-doc-boundaries]]
- [[block-129-archive-legacy-doc-boundaries]]
- [[bug-patterns]]

## File notes

### `docs/06_game_systems/ECONOMY_MODEL_V2.md`

- **Zone:** game-systems documentation
- **Purpose:** likely intended future/alternate economy modeling surface
- **Problem found:** committed as a completely empty markdown file under a live systems folder
- **Fix:** converted it into an explicit deprecated placeholder with redirects to current economy sources
- **Status:** Fixed

### `docs/Untitled 2.base`

- **Zone:** stray root docs artifact
- **Purpose:** unclear; filename suggests accidental/editor export residue
- **Problem found:** zero-byte, unnamed, and impossible to interpret safely
- **Fix:** added a plain-text boundary note marking it as a legacy placeholder and candidate for removal
- **Status:** Fixed

### `docs/_COMMUNITY_Community 284.md`

- **Zone:** stray root docs/community placeholder
- **Purpose:** likely intended community/system write-up that was never populated
- **Problem found:** zero-byte markdown file living in the root `docs/` surface
- **Fix:** converted it into an explicit deprecated placeholder with redirects to real social/community docs
- **Status:** Fixed

## Problems found

1. **Empty files can look more authoritative than they deserve**
   - Risk: contributors treat them as missing live docs that should be completed or cited, even though they have no verified scope.
   - Fix: added explicit boundary/deprecation markers and redirects to real current sources.

2. **Stray placeholder filenames create avoidable ambiguity**
   - Risk: `Untitled 2.base` especially reads like accidental residue, not intentional documentation.
   - Fix: marked it directly as a legacy placeholder candidate for removal.

3. **Live doc trees should not contain silent zero-byte surfaces**
   - Risk: they undermine confidence in the doc structure and blur the line between archival residue and maintained documentation.
   - Fix: kept the files non-destructively but made their status obvious on open.

## Verification

- confirmed all three files were previously zero-byte placeholders
- confirmed each now contains an explicit non-authoritative/deprecated status note
- `git diff --check`

## Follow-up

- Continue through remaining root/legacy-adjacent residuals and mark any accidental placeholders or abandoned doc surfaces before deciding on final deletion.
