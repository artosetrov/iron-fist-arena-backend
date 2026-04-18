---
title: Block 152 — root bootstrap and ignore parity
category: audit
tags: [audit, root, docs, policy, cleanup]
sources:
  - .gitignore
  - CLAUDE.md
  - wiki/audit/block-001-root-files.md
  - wiki/audit/project-file-inventory.md
updated: 2026-04-17
status: Fixed
---

# Block 152 — root bootstrap and ignore parity

## Scope

- `.gitignore`
- `CLAUDE.md`
- `wiki/audit/block-001-root-files.md`

## Why this block

After the root doc relocations, two root review items were left:

- `.gitignore` still carried a warning from the old prototype-heavy root
- `CLAUDE.md` had grown into a mix of bootstrap, domain rules, stale counts, and legacy orchestrator process

At that point the safest next step was to make root honest again:

- ignore policy should describe the repo as it is now
- root `CLAUDE.md` should be a compact cross-domain entrypoint, not a second giant rules database

## What changed

### `.gitignore`

- no pattern changes were needed
- the audit status changed because the old contradiction is gone: root no longer carries the prototype clutter that originally made the ignore policy look inconsistent

### `CLAUDE.md`

- rewrote it into a compact bootstrap file
- kept only cross-domain invariants:
  - canonical doc pointers
  - repo-wide architecture truths
  - Xcode project file rule
  - schema sync
  - deploy/migration guidance
  - root hygiene
- removed stale count-heavy descriptions and legacy orchestrator/process noise that duplicated or conflicted with canonical docs

## Problems resolved

1. **Root policy doc duplicated too much domain detail**
   - Resolution: `CLAUDE.md` now points to canonical docs instead of trying to be all docs at once.

2. **Old `.gitignore` review note no longer matched the cleaned root**
   - Resolution: root ignore parity is now effectively restored by the prototype/doc relocation cleanup.

## Verification

- confirmed root now contains only `.gitignore`, `.mcp.json`, and `CLAUDE.md`
- confirmed `CLAUDE.md` still points at canonical docs and domain rule files
- confirmed `git diff --check`

## Follow-up

- future rule additions should prefer domain CLAUDE files or canonical docs first; root `CLAUDE.md` should stay as a bootstrap map, not regrow into a full duplicate ruleset.
