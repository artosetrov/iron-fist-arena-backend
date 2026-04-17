---
title: Block 113 — Wiki generation tooling and generated indexes
category: audit
tags: [audit, wiki, tooling, generated, scripts]
sources:
  - scripts/wiki/check-drift.sh
  - scripts/wiki/generate-all.sh
  - scripts/wiki/generate-api-routes.mjs
  - scripts/wiki/generate-prisma-models.mjs
  - scripts/wiki/generate-tokens.mjs
  - wiki/_generated/README.md
  - wiki/_generated/api-routes.json
  - wiki/_generated/prisma-models.json
  - wiki/_generated/tokens.json
  - wiki/features/_template.md
  - .skills/skills/gatekeeper/scripts/preflight_check.sh
  - .claude/skills/gatekeeper/scripts/preflight_check.sh
updated: 2026-04-16
status: Fixed
---

# Block 113 — Wiki generation tooling and generated indexes

## Scope

- `scripts/wiki/check-drift.sh`
- `scripts/wiki/generate-all.sh`
- `scripts/wiki/generate-api-routes.mjs`
- `scripts/wiki/generate-prisma-models.mjs`
- `scripts/wiki/generate-tokens.mjs`
- `wiki/_generated/README.md`
- `wiki/_generated/api-routes.json`
- `wiki/_generated/prisma-models.json`
- `wiki/_generated/tokens.json`
- `wiki/features/_template.md`
- `.skills/skills/gatekeeper/scripts/preflight_check.sh`
- `.claude/skills/gatekeeper/scripts/preflight_check.sh`

## Why this block

New wiki-generation tooling appeared in the repo:

- machine-readable indexes under `wiki/_generated/`
- generator scripts under `scripts/wiki/`
- a feature page template under `wiki/features/`

That was good news, but there was one important gap:

- the generated README claimed preflight would warn about stale generated files
- the actual preflight scripts did not do that yet

So this was already more than “new tooling exists”; it needed a real contract check.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-109-operations-deploy-docs-reality-sync]]

## File notes

### `scripts/wiki/generate-all.sh`

- **Zone:** wiki tooling
- **Purpose:** one-shot regeneration of all generated JSON indexes
- **Review outcome:**
  - simple and correct orchestration wrapper for the three generators
- **Action:** no code change
- **Status:** OK

### `scripts/wiki/generate-tokens.mjs`

- **Zone:** wiki tooling / design tokens
- **Purpose:** extracts token data from `DarkFantasyTheme.swift` and `LayoutConstants.swift`
- **Review outcome:**
  - useful machine-facing fast lookup layer for design/token questions
- **Action:** no code change
- **Status:** OK

### `scripts/wiki/generate-api-routes.mjs`

- **Zone:** wiki tooling / backend API surface
- **Purpose:** builds a route inventory from `backend/src/app/api/**/route.ts`
- **Review outcome:**
  - good best-effort static inventory; especially useful for fast route/auth/rate-limit lookup
- **Action:** no code change
- **Status:** OK

### `scripts/wiki/generate-prisma-models.mjs`

- **Zone:** wiki tooling / Prisma schema surface
- **Purpose:** machine-readable export of models, fields, enums, indexes, uniques
- **Review outcome:**
  - useful for fast model lookup without reparsing the Prisma schema every time
- **Action:** no code change
- **Status:** OK

### `scripts/wiki/check-drift.sh`

- **Zone:** wiki tooling / drift guard
- **Purpose:** checks whether generated indexes are older than their sources
- **Problems found:**
  - the script existed, but nothing in preflight actually invoked it
- **What was fixed:**
  - wired it into both gatekeeper preflight scripts as a warning-stage check when relevant source/generated files change
- **Status:** Fixed

### `wiki/_generated/*`

- **Zone:** wiki generated machine indexes
- **Purpose:** fast JSON lookup for tokens, routes, and Prisma models
- **Review outcome:**
  - regenerated successfully
  - now matches the actual source files after generator run
- **Action:** regenerated and documented in inventory
- **Status:** Fixed

### `wiki/features/_template.md`

- **Zone:** wiki authoring support
- **Purpose:** future per-feature flat map template
- **Review outcome:**
  - useful and consistent with the audit direction
  - should be treated as a real repo artifact, not ignored local scratch
- **Action:** added to inventory/accounting
- **Status:** OK

### `.skills/skills/gatekeeper/scripts/preflight_check.sh` and `.claude/skills/gatekeeper/scripts/preflight_check.sh`

- **Zone:** local preflight tooling
- **Purpose:** repo-local commit/push readiness checks
- **Problems found:**
  - drift warning promised by generated-index docs was not actually enforced
- **What was fixed:**
  - added a wiki generated-drift warning section gated to relevant source/generated changes
- **Status:** Fixed

## Problems found

1. **Wiki generated-drift guard existed only on paper**
   - Risk: generated JSON indexes silently drift while docs claim preflight is watching them.
   - Fix: integrated `scripts/wiki/check-drift.sh` into both preflight scripts.

2. **New wiki tooling artifacts were not yet reflected in the file inventory**
   - Risk: inventory and audit counts drift immediately after adding the tooling meant to support the wiki.
   - Fix: refreshed inventory counts and listed the new scripts/generated/template files explicitly.

## Verification

- `bash scripts/wiki/generate-all.sh`
- `bash scripts/wiki/check-drift.sh`
- `bash .skills/skills/gatekeeper/scripts/preflight_check.sh "$(pwd)"`
- `git diff --check`
- refreshed `git ls-files`, `git ls-files --others --exclude-standard`, and `find wiki -name '*.md'`

## Follow-up

- The remaining decision here is operational, not structural:
  - whether `scripts/wiki/*` and `wiki/_generated/*` stay intentionally untracked local tooling/indexes
  - or get promoted to tracked repo artifacts later
