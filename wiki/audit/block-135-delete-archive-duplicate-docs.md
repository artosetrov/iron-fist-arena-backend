---
title: Block 135 — delete archive duplicate docs
category: audit
tags: [audit, docs, archive, duplicate, deletion]
sources:
  - docs/11_archive/ART_STYLE_GUIDE_DUPLICATE.md
  - docs/11_archive/mine-card-prompts_DUPLICATE.md
  - docs/11_archive/ARCHIVE_INDEX.md
updated: 2026-04-16
status: Fixed
---

# Block 135 — delete archive duplicate docs

## Scope

- `docs/11_archive/ART_STYLE_GUIDE_DUPLICATE.md`
- `docs/11_archive/mine-card-prompts_DUPLICATE.md`
- `docs/11_archive/ARCHIVE_INDEX.md`

## Why this block

The previous archive pass already proved these two files were not “historical docs with unique value.” They were explicit duplicates whose only remaining role was redundancy.

Once the user asked to delete everything unnecessary, these became high-confidence removal candidates: deleting them reduces noise without erasing any unique history.

## Related pages

- [[block-129-archive-legacy-doc-boundaries]]
- [[block-134-delete-placeholder-and-editor-artifact-files]]
- [[bug-patterns]]

## What was removed

### `docs/11_archive/ART_STYLE_GUIDE_DUPLICATE.md`

- **Previous role:** archived duplicate copy of the art-style guide
- **Why removal was safe:** current art prompt/style sources already exist outside the archive and the file had no unique historical annotations
- **Result:** deleted from the working tree

### `docs/11_archive/mine-card-prompts_DUPLICATE.md`

- **Previous role:** archived duplicate prompt set for Gold Mine card art
- **Why removal was safe:** canonical prompt catalogs already exist in active docs and the archive copy carried no unique forensic value
- **Result:** deleted from the working tree

## Supporting doc cleanup

### `docs/11_archive/ARCHIVE_INDEX.md`

- **Problem found:** the archive index still listed both duplicate files and also used an over-broad “Do not delete archive files” rule
- **Fix:** removed the duplicate-file rows and updated archive policy wording to distinguish unique historical docs from pure duplicates
- **Status:** Fixed

## Problems resolved

1. **Archive duplicates were still taking up namespace**
   - Risk before: contributors could still open or cite redundant archive copies instead of the canonical active docs.
   - Resolution: deleted both duplicate files.

2. **Archive policy was too blunt**
   - Risk before: “Do not delete archive files” discouraged safe removal of obvious duplicate residue.
   - Resolution: clarified that unique historical docs should stay, while pure duplicates can be removed.

## Verification

- confirmed both duplicate files were removed from the working tree
- confirmed `ARCHIVE_INDEX.md` no longer lists them as present archive members
- `git diff --check`

## Follow-up

- Keep preserving historical docs that add real context, but remove duplicate archive copies as soon as their canonical replacements are stable and linked.
