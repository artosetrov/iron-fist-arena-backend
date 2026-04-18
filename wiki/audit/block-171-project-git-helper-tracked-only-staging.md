---
title: Audit Block 171 — Project Git Helper Tracked-Only Staging
category: audit
tags: [audit, scripts, git, tooling, safety]
sources:
  - scripts/git-commit-push.sh
  - scripts/git-watcher.sh
  - wiki/audit/block-006-project-scripts.md
updated: 2026-04-17
---

# Audit Block 171 — Project Git Helper Tracked-Only Staging

## Why this block exists

`block-006` had already removed the workstation-specific path assumptions and stale lock behavior from the repo Git helpers.

But one sharp edge still remained:

- both helpers staged the **entire working tree** by default via `git add -A`

In a repo that regularly carries:

- in-progress audit pages
- local scratch artifacts
- retained prototype references
- partial follow-up work

that meant the helpers were still too willing to sweep in extra files an operator did not explicitly mean to ship.

## What changed

### `scripts/git-commit-push.sh`

- now stages **tracked changes only** by default via `git add -u`
- warns when untracked files remain outside the staged set
- supports explicit full staging via:
  - `--all`
  - `HEXBOUND_GIT_HELPER_STAGE_ALL=1`

### `scripts/git-watcher.sh`

- now also stages **tracked changes only** by default
- warns when untracked files remain outside the staged set
- supports explicit full staging via:
  - `HEXBOUND_GIT_HELPER_STAGE_ALL=1`

## Why this is better

The helpers still preserve their intended local operator role:

- fast commit/push convenience
- current-branch safety
- optional `admin` subtree push

But they now act more like careful repo tools and less like a blanket vacuum over the whole filesystem state.

That shifts the boundary from:

- "every untracked file might come along for the ride"

to:

- "tracked work goes through by default; untracked work requires explicit intent"

## Remaining boundary

These scripts are still **local workflow helpers**, not canonical shared deployment automation.

That is now mostly a policy/workflow question, not an accidental staging bug.
