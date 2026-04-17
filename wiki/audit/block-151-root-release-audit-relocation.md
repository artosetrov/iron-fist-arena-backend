---
title: Block 151 — root release audit relocation
category: audit
tags: [audit, docs, operations, release, relocation]
sources:
  - docs/10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md
  - wiki/audit/block-001-root-files.md
  - wiki/audit/project-file-inventory.md
updated: 2026-04-17
status: Fixed
---

# Block 151 — root release audit relocation

## Scope

- `HEXBOUND_PRE_RELEASE_AUDIT.md` -> `docs/10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md`

## Why this block

This file was already clearly a historical release/operations artifact:

- App Store readiness snapshot
- release-risk table
- go/no-go framing

Keeping it in root blurred the line between active repo entrypoints and dated release history.

## What changed

- moved the historical pre-release audit into `docs/10_operations/`
- kept the file intact as a historical release snapshot rather than rewriting or deleting it
- updated root audit/inventory so the file is no longer counted as a root resident

## Problems resolved

1. **Root still held a dated release audit snapshot**
   - Resolution: release-audit history now lives in the operations doc family.

2. **`block-001` still implied root ownership of release-audit history**
   - Resolution: root audit now records this as a completed relocation.

## Verification

- confirmed `HEXBOUND_PRE_RELEASE_AUDIT.md` no longer exists in root
- confirmed `docs/10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md` exists
- updated root inventory/audit references
- `git diff --check`

## Follow-up

- future release-readiness snapshots should be created directly under operations or QA history rather than being staged in root.
