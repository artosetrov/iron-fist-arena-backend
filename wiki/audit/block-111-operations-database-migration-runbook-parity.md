---
title: Block 111 — Operations database migration runbook parity
category: audit
tags: [audit, docs, operations, prisma, migrations]
sources:
  - docs/10_operations/DATABASE_MIGRATIONS.md
  - docs/10_operations/DEPLOY.md
  - docs/10_operations/GIT_AND_DEPLOY_AUDIT.md
  - backend/package.json
  - admin/vercel.json
updated: 2026-04-16
status: Fixed
---

# Block 111 — Operations database migration runbook parity

## Scope

- `docs/10_operations/DATABASE_MIGRATIONS.md`
- `docs/10_operations/DEPLOY.md`
- `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`
- `backend/package.json`
- `admin/vercel.json`

## Why this block

After blocks `109–110`, one dangerous inconsistency still remained:

- `DEPLOY.md` and the rewritten deploy audit correctly said migration apply is explicit
- but `DATABASE_MIGRATIONS.md` still framed Vercel/build-based auto-apply as the nearby recommended path

That split is exactly how teams end up thinking “build green” means “DB safe”.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-109-operations-deploy-docs-reality-sync]]
- [[block-110-operations-git-workflow-and-ios-release-doc-parity]]

## File notes

### `docs/10_operations/DATABASE_MIGRATIONS.md`

- **Zone:** operations / DB migration runbook
- **Purpose:** migration creation, schema sync, and production apply instructions
- **Problems found:**
  - still described Vercel/build-based auto-apply as an active nearby option
  - “recommended setup” suggested changing build commands, which no longer matched the current deploy docs
  - common-mistake guidance still implied “fix by adding migrate deploy to build” instead of the actual current runbook
- **What was fixed:**
  - rewrote production apply around the explicit manual path
  - documented current build reality for backend/admin
  - moved future “embed migrations into deploy” into an explicit later decision, not a hidden assumption
  - aligned the common-mistake table with the actual current command
- **Status:** Fixed

### `backend/package.json` and `admin/vercel.json`

- **Zone:** deploy/build config
- **Purpose:** actual build behavior
- **Review outcome:**
  - confirmed neither build pipeline runs `prisma migrate deploy`
- **Action:** no code change; used as evidence source
- **Status:** OK

### `docs/10_operations/DEPLOY.md` and `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`

- **Zone:** related operations docs
- **Purpose:** neighboring source-of-truth pages
- **Review outcome:**
  - these files were already aligned after block `109`
  - they were used as the parity target for the migration runbook
- **Action:** no code change in this block
- **Status:** OK

## Problems found

1. **Migration docs still implied a semi-automatic deploy model that does not exist**
   - Risk: operator assumes production schema changes ride along with a normal backend deploy.
   - Fix: made the explicit `db:migrate:deploy` step the primary documented production path.

2. **One operations page was drifting away from the other two**
   - Risk: different docs tell different stories about the same release boundary.
   - Fix: aligned the migration doc with the deploy guide and the refreshed deploy audit.

## Verification

- inspected `docs/10_operations/DATABASE_MIGRATIONS.md`
- inspected `docs/10_operations/DEPLOY.md`
- inspected `docs/10_operations/GIT_AND_DEPLOY_AUDIT.md`
- inspected `backend/package.json`
- inspected `admin/vercel.json`

## Follow-up

- The remaining migration debt is now clearly operational, not documentary:
  - migration apply is still explicit
  - if the team wants deploy-time auto-apply later, that should be adopted as a deliberate cross-doc + build-config change
