---
title: Block 110 — Operations git workflow and iOS release doc parity
category: audit
tags: [audit, docs, operations, git, ios, release]
sources:
  - docs/10_operations/GIT_WORKFLOW.md
  - docs/10_operations/RELEASE_IOS.md
  - .github/workflows/ci.yml
  - Hexbound/fastlane/Appfile
  - Hexbound/fastlane/Fastfile
  - Hexbound/Hexbound/App/AppConstants.swift
updated: 2026-04-16
status: Fixed
---

# Block 110 — Operations git workflow and iOS release doc parity

## Scope

- `docs/10_operations/GIT_WORKFLOW.md`
- `docs/10_operations/RELEASE_IOS.md`
- `.github/workflows/ci.yml`
- `Hexbound/fastlane/Appfile`
- `Hexbound/fastlane/Fastfile`
- `Hexbound/Hexbound/App/AppConstants.swift`

## Why this block

After block `109`, the big deploy/docs contradictions were gone, but two neighboring runbooks still had softer drift:

- `GIT_WORKFLOW.md` still read like a mostly-March process note and did not clearly separate CI validation from actual deploy steps.
- `RELEASE_IOS.md` described the Fastlane flow a bit too optimistically relative to the current placeholder-backed `Appfile` and the still-shared staging/production API host.

Those are exactly the kinds of “almost true” docs that create late-night release mistakes.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-109-operations-deploy-docs-reality-sync]]

## File notes

### `docs/10_operations/GIT_WORKFLOW.md`

- **Zone:** operations / git workflow
- **Purpose:** working agreement for branch flow, main pushes, and admin subtree deploy
- **Problems found:**
  - implied preview/deploy sequencing without clearly separating backend preview, CI validation, and admin subtree reality
  - showed branch-protection checkboxes as if they were factual state rather than recommendation
  - did not explicitly say that CI validates builds but does not deploy admin or iOS
- **What was fixed:**
  - updated the source-of-truth header
  - clarified that feature-branch pushes give CI + backend preview value, not a magical admin deploy
  - reframed branch protection as recommendation, not claimed fact
  - added a small CI-reality section
  - added a common-mistake row for assuming CI deploys admin
- **Status:** Fixed

### `docs/10_operations/RELEASE_IOS.md`

- **Zone:** operations / iOS release runbook
- **Purpose:** TestFlight/App Store release path
- **Problems found:**
  - “Appfile configured” read like a current repo fact, while the repo still contains placeholder values
  - environment section could be misread as meaning staging already has its own backend host
  - local non-upload verification path was under-emphasized compared with Fastlane
- **What was fixed:**
  - clarified that Fastlane release is setup-required, not turnkey
  - documented that `staging` mode still points at the same production API host today
  - added the repo-local `xcodebuild` smoke gate as the cleanest no-upload verification path
  - tightened the common-mistake guidance around placeholders and staging assumptions
- **Status:** Fixed

### `.github/workflows/ci.yml`

- **Zone:** CI source of truth
- **Purpose:** validation boundary for backend/admin/schema checks
- **Review outcome:**
  - used as grounding evidence for the workflow doc updates
- **Action:** no code change
- **Status:** OK

### `Hexbound/fastlane/Appfile`

- **Zone:** iOS release config
- **Purpose:** Fastlane identity/team setup
- **Review outcome:**
  - placeholder values remain real and are still the honest release blocker at this layer
- **Action:** no code change; docs now describe this accurately
- **Status:** Needs review

### `Hexbound/fastlane/Fastfile`

- **Zone:** iOS release automation
- **Purpose:** release lanes
- **Review outcome:**
  - lane skeleton is real and usable, so the docs should not imply Fastlane itself is missing
- **Action:** no code change
- **Status:** OK

### `Hexbound/Hexbound/App/AppConstants.swift`

- **Zone:** iOS environment config
- **Purpose:** production/staging API targeting
- **Review outcome:**
  - app-side environment split exists, but staging still targets the production API host
- **Action:** no code change; docs now describe this exactly
- **Status:** Needs review

## Problems found

1. **Workflow docs still blurred “validated” and “deployed”**
   - Risk: someone sees green CI and assumes admin is live too.
   - Fix: made CI-vs-deploy separation explicit in the git workflow doc.

2. **iOS release doc still over-promised readiness**
   - Risk: someone expects `fastlane beta` to be turnkey from a fresh machine/repo checkout.
   - Fix: documented the current placeholder-backed setup honestly and called out the real local smoke gate.

3. **Staging wording was still too forgiving**
   - Risk: operators assume staging mode targets a separate backend when it does not.
   - Fix: docs now say directly that staging currently resolves to the production API host.

## Verification

- inspected `docs/10_operations/GIT_WORKFLOW.md`
- inspected `docs/10_operations/RELEASE_IOS.md`
- inspected `.github/workflows/ci.yml`
- inspected `Hexbound/fastlane/Appfile`
- inspected `Hexbound/fastlane/Fastfile`
- inspected `Hexbound/Hexbound/App/AppConstants.swift`

## Follow-up

- The operations/doc layer now says the quiet part out loud:
  - CI validates; it does not deploy admin or iOS
  - Fastlane exists; repo-level Apple identity/team setup is still incomplete
  - staging mode exists; staging host separation does not yet
