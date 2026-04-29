---
title: Audit Block 261 — Feature-Map Memory Note Repo Truth Sync
category: audit
tags: [audit, wiki, feature-maps, gold-mine, stash, shop, inventory, characters, passive-tree]
sources:
  - wiki/features/gold-mine.md
  - wiki/features/stash.md
  - wiki/features/shop.md
  - wiki/features/inventory.md
  - wiki/features/characters.md
  - wiki/features/passive-tree.md
  - wiki/audit/block-010-prisma-migrations-hotfixes-stash-interactive-premium.md
  - wiki/audit/block-012-backend-stash-contraband-premium-runtime.md
  - wiki/audit/block-089-ios-stash-transfer-typed-contracts.md
updated: 2026-04-29
status: Fixed
---

# Audit Block 261 — Feature-Map Memory Note Repo Truth Sync

## Scope

- remaining non-combat feature maps that still leaned on memory-note wording

## Why this block

Several feature maps still mixed real repo truth with external-memory shorthands:

- Gold Mine incident notes
- stash incident history
- shop/inventory flat-response and optimistic-UI notes
- character appearance fallback note
- passive-tree migration note

Most of these did not need an external note anymore. Either:

- the checked-in audit blocks already preserve the incident history, or
- the rule is now simple enough to state directly in the feature map

## Fix applied

- `gold-mine.md`: kept the 2026-04-11 migration incident, but removed the
  external memory-note dependency and framed it as part of the now-established
  manual-first migration rule
- `stash.md`:
  - replaced the old memory reference with checked-in audit blocks `010`, `012`,
    and `089`
  - removed the trailing “see memory” wording from the prod-table gotcha
- `shop.md` and `inventory.md`:
  - removed external-memory tags from flat-response and optimistic-UI gotchas
  - kept the rules themselves intact
- `characters.md`: turned the avatar fallback note into plain repo truth
- `passive-tree.md`: removed the external-memory tail from the
  migration-before-deploy note

## Result

These feature maps still preserve the important operational lessons, but they
no longer depend on external memory-note names to make sense. The checked-in
repo once again carries the authority.

## Verification

- repo search over `wiki/features/*` for the removed memory-note patterns
- checked-in audit block existence checks for the stash replacements
- `git diff --check`
