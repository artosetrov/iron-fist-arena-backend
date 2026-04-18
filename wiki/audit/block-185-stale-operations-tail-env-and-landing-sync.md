---
title: Block 185 — stale operations tail env and landing sync
category: audit
tags: [audit, operations, ios, deploy, docs]
sources:
  - docs/10_operations/GIT_AND_DEPLOY_AUDIT.md
  - docs/10_operations/DEPLOY.md
  - docs/10_operations/RELEASE_IOS.md
  - Hexbound/Hexbound/App/AppConstants.swift
  - wiki/audit/block-109-operations-deploy-docs-reality-sync.md
updated: 2026-04-17
status: Fixed
---

# Block 185 — stale operations tail env and landing sync

## Scope

- `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`
- `docs/10_operations/DEPLOY.md`
- `docs/10_operations/RELEASE_IOS.md`
- `Hexbound/Hexbound/App/AppConstants.swift`
- `wiki/audit/block-109-operations-deploy-docs-reality-sync.md`

## Why this block

[[block-109-operations-deploy-docs-reality-sync]] correctly narrowed the old operations chaos, but two tails stayed marked like unresolved fog:

- landing/static deploy was still described as “not fully codified”
- iOS environment targeting was still left at `Needs review`

By now both of those are actually documented. The runtime caveat still exists for iOS staging, but the documentation state no longer deserves an open-warning badge. This block closes that stale mismatch between the docs and the audit about the docs.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-109-operations-deploy-docs-reality-sync]]

## File notes

### `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`

- **Zone:** operations / deploy audit snapshot
- **Purpose:** human-readable deploy/release risk map
- **Problems found:**
  - still said landing/static deploy was not codified
  - still surfaced iOS environment targeting as a doc-status unknown instead of a documented caveat
- **What was fixed:**
  - executive summary now points at the hosted landing/legal deploy contract as documented
  - risk snapshot no longer treats landing/static deploy as undocumented
  - source-of-truth table now reflects:
    - landing/static deploy is manual but defined
    - iOS environment targeting is documented, with staging currently aliasing production
- **Status:** Fixed

### `docs/10_operations/DEPLOY.md`

- **Zone:** operations / deploy guide
- **Purpose:** current deploy runbook
- **Why it mattered here:** this file already codified the hosted landing-site deploy path (`artosetrov/hexbound-landing` → `hexboundapp.com`), which meant the older audit warning had become stale
- **Status:** OK

### `docs/10_operations/RELEASE_IOS.md`

- **Zone:** operations / iOS release guide
- **Purpose:** current iOS release/source-of-truth doc
- **Why it mattered here:** it already states that `staging` exists as an app environment mode but currently resolves to the production API host, so the remaining issue is runtime topology, not missing documentation
- **Status:** OK

### `Hexbound/Hexbound/App/AppConstants.swift`

- **Zone:** iOS environment config
- **Purpose:** app-side API environment selection
- **What was clarified:** the code still routes `.staging` to the production API host, but this is now documented as the current state rather than left as an unexplained audit warning
- **Status:** Fixed

### `wiki/audit/block-109-operations-deploy-docs-reality-sync.md`

- **Zone:** wiki / audit trail
- **Purpose:** original deploy-doc reality-sync block
- **What was fixed:** its old `Needs review` wording now points at this follow-up as a stale-doc-status tail rather than an unresolved documentation gap
- **Status:** Fixed

## Problems found

1. **The operations audit still advertised two documentation gaps that had already been documented elsewhere**
   - Risk: operators reading the audit would assume deploy semantics were less defined than they really are.
   - Fix: aligned the audit snapshot to the current deploy/release docs.

2. **The iOS staging caveat was being framed as missing-doc uncertainty**
   - Risk: the team could conflate “documented but still sharing prod host” with “nobody knows how this works.”
   - Fix: rewrote it as a documented runtime caveat rather than a docs-status hole.

## Verification

- re-read `DEPLOY.md`, `RELEASE_IOS.md`, and `AppConstants.swift` against `GIT_AND_DEPLOY_AUDIT.md`
- `git diff --check`

## Follow-up

- the real remaining operations risks here are still narrower:
  - admin deploy is manual
  - DB migration apply is explicit
  - iOS staging still lacks a distinct backend host if a true split is needed later
