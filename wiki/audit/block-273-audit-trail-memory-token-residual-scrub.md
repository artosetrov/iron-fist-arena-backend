---
title: Audit Block 273 — Audit Trail Memory Token Residual Scrub
category: audit
tags: [audit, wiki, docs, cleanup]
sources:
  - wiki/log.md
  - wiki/audit/block-263-combat-historical-doc-memory-boundary-sync.md
  - wiki/audit/block-264-active-skill-picker-memory-boundary-sync.md
  - wiki/audit/block-271-retro-2026-04-10-and-11-memory-boundary-sync.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 273 — Audit Trail Memory Token Residual Scrub

## Scope

This block removes the last literal external memory-token strings from the
audit trail itself.

## Why this block

The runtime docs had already been cleaned, but a few audit and log pages still
quoted the old shorthand literally while describing that cleanup work. That was
harmless, but it meant repo-wide searches still surfaced token names that were
supposed to be retired from the checked-in source-of-truth layer.

## Changes shipped

### `wiki/log.md`

- Rephrased the block-264 summary so it now says "off-repo breadcrumbs"
  instead of spelling the old shorthand literally.

### `wiki/audit/block-263-combat-historical-doc-memory-boundary-sync.md`

- Replaced the old top-level heading token with neutral "external-note
  references" wording.

### `wiki/audit/block-264-active-skill-picker-memory-boundary-sync.md`

- Replaced the literal rollout-token wording with neutral "off-repo rollout
  references" wording.

### `wiki/audit/block-271-retro-2026-04-10-and-11-memory-boundary-sync.md`

- Replaced the last literal shorthand wording with neutral "external-note" /
  "off-repo shorthand" language.

## Result

Repo-wide searches for the old memory-token patterns are now quiet inside the
checked-in docs/wiki layer as well, not just inside the runtime docs they were
describing.
