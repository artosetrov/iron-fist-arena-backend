---
title: Block 114 — Wiki feature maps and index visibility
category: audit
tags: [audit, wiki, features, indexing, links]
sources:
  - wiki/features/_template.md
  - wiki/features/gold-mine.md
  - wiki/features/interactive-combat.md
  - wiki/features/pvp-combat.md
  - wiki/features/referral.md
  - wiki/features/shop.md
  - wiki/index.md
updated: 2026-04-16
status: Fixed
---

# Block 114 — Wiki feature maps and index visibility

## Scope

- `wiki/features/_template.md`
- `wiki/features/gold-mine.md`
- `wiki/features/interactive-combat.md`
- `wiki/features/pvp-combat.md`
- `wiki/features/referral.md`
- `wiki/features/shop.md`
- `wiki/index.md`

## Why this block

The new feature-map pages were already useful, but they still had two wiki-level problems:

- they were not surfaced from the main wiki index
- their cross-links still used ad hoc markdown links instead of the repo’s wiki-link style

That meant the content existed, but the wiki did not really “know” it existed.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-113-wiki-generation-tooling-and-generated-indexes]]

## File notes

### `wiki/features/_template.md`

- **Zone:** wiki authoring
- **Purpose:** flat feature-map template for future end-to-end pages
- **Review outcome:**
  - structure is useful and aligned with the file-by-file audit style
- **Action:** no content change
- **Status:** OK

### `wiki/features/gold-mine.md`

- **Zone:** wiki feature map
- **Purpose:** end-to-end feature map for Gold Mine
- **Problems found:**
  - related-feature links used plain markdown file links instead of wiki links
- **What was fixed:**
  - converted related links to `[[...]]`
- **Status:** Fixed

### `wiki/features/pvp-combat.md`

- **Zone:** wiki feature map
- **Purpose:** end-to-end feature map for PvP combat
- **Problems found:**
  - related-feature links used plain markdown file links instead of wiki links
- **What was fixed:**
  - converted related links to `[[...]]`
- **Status:** Fixed

### `wiki/features/interactive-combat.md`

- **Zone:** wiki feature map
- **Purpose:** end-to-end feature map for interactive PvP combat
- **Review outcome:**
  - already used the repo's native wiki-link style
  - was missing only from the top-level feature navigation
- **What was fixed:**
  - surfaced from `wiki/index.md`
- **Status:** Fixed

### `wiki/features/referral.md`

- **Zone:** wiki feature map
- **Purpose:** end-to-end feature map for referral code and milestone reward flow
- **Review outcome:**
  - already used the repo's native wiki-link style
  - was missing only from the top-level feature navigation
- **What was fixed:**
  - surfaced from `wiki/index.md`
- **Status:** Fixed

### `wiki/features/shop.md`

- **Zone:** wiki feature map
- **Purpose:** end-to-end feature map for Shop
- **Problems found:**
  - related-feature links used plain markdown file links instead of wiki links
- **What was fixed:**
  - converted related links to `[[...]]`
- **Status:** Fixed

### `wiki/index.md`

- **Zone:** wiki navigation
- **Purpose:** main entry point into wiki content
- **Problems found:**
  - feature maps were not represented in the index at all
- **What was fixed:**
  - added a dedicated `Features` section
  - surfaced all five live feature maps, not just the first three
  - refreshed footer counts so the wiki status reflects the new feature pages
- **Status:** Fixed

## Problems found

1. **Feature maps existed but were effectively hidden**
   - Risk: useful cross-system pages stay unused because the main index does not surface them.
   - Fix: added them to `wiki/index.md`.

2. **Feature pages were not using the repo’s native wiki-link style**
   - Risk: mixed linking styles make navigation and future refactoring noisier.
   - Fix: converted related feature references to `[[...]]`.

## Verification

- inspected `wiki/features/_template.md`
- inspected `wiki/features/gold-mine.md`
- inspected `wiki/features/pvp-combat.md`
- inspected `wiki/features/shop.md`
- inspected `wiki/index.md`
- `git diff --check`

## Follow-up

- The next wiki-level decision is whether feature maps should stay as a small curated set or expand into a broader feature atlas over time.
