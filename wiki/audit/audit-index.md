---
title: File-By-File Project Audit
category: audit
tags: [audit, architecture, file-catalog, qa]
sources: [wiki/audit/project-file-inventory.md]
updated: 2026-04-14
---

# File-By-File Project Audit

This audit tracks every project-owned file in small logical blocks. Scope is Git-tracked files plus untracked project files. Vendor/build/cache artifacts are excluded unless committed to the repository.

## Inventory

- [[project-file-inventory]] — complete file list by top-level block
- In-scope files: 4756
- Excluded: `node_modules/`, `.next/`, `.git/`, generated local caches, ignored dev artifacts

## Audit Blocks

| Block | Scope | Status |
|-------|-------|--------|
| 001 | [[block-001-root-files]] — Root files: repository policy, root reports, root prototypes/legal HTML | Fixed; cleanup decisions pending |
| 002 | [[block-002-repo-automation]] — GitHub CI, Cursor rules, local skills and scanner scripts | Fixed; follow-up consolidation pending |
| 003 | [[block-003-claude-operational-safety]] — `.claude` settings, duplicated operational skills, and runnable safety scripts | Fixed; de-tracking/credential rotation pending |

## Status Legend

- **OK** — file has a clear role and no immediate action.
- **Fixed** — safe issue found and corrected.
- **Needs review** — issue or uncertainty needs product/architecture decision.
- **Deprecated** — candidate to remove after confirming it is not referenced.

## Rules

- Record role, dependencies, inbound usage, business rules, issues, fixes, unresolved decisions, and status for every audited file.
- Prefer safe mechanical fixes during audit.
- Do not delete prototypes/reports/assets without explicit confirmation; mark candidates first.
