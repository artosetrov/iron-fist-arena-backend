---
title: Block 109 — Operations deploy docs reality sync
category: audit
tags: [audit, docs, deploy, ci, operations]
sources:
  - docs/10_operations/DEPLOY.md
  - docs/10_operations/GIT_AND_DEPLOY_AUDIT.md
  - .github/workflows/ci.yml
  - backend/next.config.ts
  - admin/next.config.ts
  - backend/package.json
  - admin/vercel.json
  - Hexbound/fastlane/Appfile
  - Hexbound/Hexbound/App/AppConstants.swift
  - .claude/agent-bus/herald.md
updated: 2026-04-16
status: Fixed
---

# Block 109 — Operations deploy docs reality sync

## Scope

- `docs/10_operations/DEPLOY.md`
- `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`
- `.github/workflows/ci.yml`
- `backend/next.config.ts`
- `admin/next.config.ts`
- `backend/package.json`
- `admin/vercel.json`
- `Hexbound/fastlane/Appfile`
- `Hexbound/Hexbound/App/AppConstants.swift`
- `.claude/agent-bus/herald.md`

## Why this block

During Herald deploy verification, the repo itself was healthier than the operations docs claimed:

- CI exists and is active
- backend/admin schemas are synced and checked
- `ignoreBuildErrors` is gone
- backend/admin real `next build` gates are green

But the live docs still described a much older repo state. That is risky because deploy docs are not passive reference material here; they are part of the operator runbook.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-030-backend-ci-contract-hardening-and-actions-upgrade]]
- [[block-053-admin-snapshots-restore-runtime-hardening]]

## File notes

### `docs/10_operations/DEPLOY.md`

- **Zone:** operations / deploy runbook
- **Purpose:** practical deploy instructions for backend, admin, DB, and iOS
- **Problems found:**
  - still claimed a backend `ignoreBuildErrors: true` known issue that no longer exists
  - implied migration deploy could happen “on next Vercel build”, which is false with the current `build` scripts
  - did not mention the now-live GitHub Actions validation gates
- **What was fixed:**
  - removed stale `ignoreBuildErrors` warning
  - added CI validation-gates section
  - clarified that `prisma migrate deploy` is an explicit production step
  - tightened “common mistakes” around schema sync and migration assumptions
- **Status:** Fixed

### `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`

- **Zone:** operations / audit snapshot
- **Purpose:** repo-level git/deploy reality audit
- **Problems found:**
  - claimed there was no CI/CD at all
  - claimed backend/admin Prisma schema drift as a standing fact
  - claimed 136 uncommitted files as if that were still current repo state
  - claimed build errors were ignored through `ignoreBuildErrors`
  - treated the landing/static deploy surface as “not found” without clearly separating unknowns from verified facts
- **What was fixed:**
  - rewrote the audit to the real 2026-04-16 state
  - documented live CI jobs and what they do not cover
  - documented explicit admin subtree deploy and explicit migration-apply behavior
  - preserved the still-open iOS/Appfile and environment-targeting risks instead of flattening everything into “all good now”
- **Status:** Fixed

### `.github/workflows/ci.yml`

- **Zone:** CI source of truth
- **Purpose:** build/test/schema guardrail workflow
- **Review outcome:**
  - the workflow is real and materially contradicts the older audit claim of “no CI/CD”
  - it now serves as a canonical evidence source for deploy docs
- **Action:** no code change; used as evidence source
- **Status:** OK

### `backend/next.config.ts` and `admin/next.config.ts`

- **Zone:** build/runtime config
- **Purpose:** Next.js build behavior
- **Review outcome:**
  - neither file contains `ignoreBuildErrors`
  - this directly invalidated a stale operations warning
- **Action:** no code change; used as evidence source
- **Status:** OK

### `backend/package.json` and `admin/vercel.json`

- **Zone:** deploy/build config
- **Purpose:** authoritative build commands
- **Review outcome:**
  - current backend/admin build commands do not include `prisma migrate deploy`
  - that means “build green” and “DB migrated” are different operational steps
- **Action:** no code change; clarified docs accordingly
- **Status:** OK

### `Hexbound/fastlane/Appfile`

- **Zone:** iOS release config
- **Purpose:** Fastlane identity/team setup
- **Review outcome:**
  - placeholder Apple ID/team setup is still real
  - the old audit was right to flag this, so that warning was kept
- **Action:** no code change; preserved as an open operational risk
- **Status:** Needs review

### `Hexbound/Hexbound/App/AppConstants.swift`

- **Zone:** iOS environment targeting
- **Purpose:** app-side API environment selection
- **Review outcome:**
  - `DEBUG` defaults to staging, but staging still points at the production API URL
  - this is still a runtime environment-split caveat, but later release docs explicitly documented the behavior instead of leaving it as a docs-status unknown
- **Action:** no code change in this block; later truth-sync in [[block-185-stale-operations-tail-env-and-landing-sync]] closed the stale documentation warning while keeping the runtime caveat explicit
- **Status:** Fixed

### `.claude/agent-bus/herald.md`

- **Zone:** deploy protocol bus
- **Purpose:** run result for the last Herald verification
- **Review outcome:**
  - confirmed that the repo was deployable and synchronized at the time of verification
  - also confirmed that the blocker was “no new delta to release”, not build failure
- **Action:** no code change; used to anchor the rewritten audit snapshot
- **Status:** OK

## Problems found

1. **Deploy docs still described an older, riskier repo than the one we actually have**
   - Risk: operators follow defensive rituals for problems that are already closed, while missing the smaller risks that are still real.
   - Fix: rewrote the operations audit and deploy guide around current build, CI, schema, and migration facts.

2. **Migration semantics were documented too loosely**
   - Risk: someone assumes Vercel build will apply DB migrations because build is green.
   - Fix: docs now say explicitly that `prisma migrate deploy` is a separate production step.

3. **Stale risk inventory obscured the true remaining release risks**
   - Risk: “no CI, broken schemas, ignored builds” noise hides the actual current weak points: admin subtree push, iOS release setup, and environment targeting.
   - Fix: narrowed the risk section to current unresolved issues.

4. **Two documentation-risk labels later became stale**
   - Risk: the deploy audit itself would start lagging behind `DEPLOY.md` and `RELEASE_IOS.md`.
   - Later fix: [[block-185-stale-operations-tail-env-and-landing-sync]] reclassified landing/static deploy as manual-but-defined and iOS environment targeting as documented-with-caveat.

## Verification

- `git ls-files | wc -l`
- `git ls-files --others --exclude-standard | wc -l`
- `find wiki -name '*.md' | wc -l`
- inspected `.github/workflows/ci.yml`
- inspected `backend/next.config.ts`
- inspected `admin/next.config.ts`
- inspected `backend/package.json`
- inspected `admin/vercel.json`
- inspected `Hexbound/fastlane/Appfile`
- inspected `Hexbound/Hexbound/App/AppConstants.swift`
- inspected `.claude/agent-bus/herald.md`

## Follow-up

- The deploy/operations docs are now aligned with live repo behavior.
- The remaining operations debt is narrower and explicit:
  - admin subtree deploy is still manual
  - production migration apply is still explicit
  - iOS Fastlane/Appfile setup is still incomplete
  - iOS staging still shares the production API URL
  - later truth-sync in [[block-185-stale-operations-tail-env-and-landing-sync]] closed the stale landing/env documentation warnings without pretending the runtime caveats vanished
