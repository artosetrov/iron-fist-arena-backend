---
title: Block 070 — admin events API auth gap
category: audit
tags: [audit, admin, api, auth, security, events]
sources:
  - admin/src/app/api/events/route.ts
updated: 2026-04-15
status: Fixed
---

# Block 070 — admin events API auth gap

## Scope

- `admin/src/app/api/events/route.ts`

## Why this block

This was not a polish issue. During the admin API boundary review, the events route stood out because it exposed list/create/update/delete handlers without the `getAdminUser()` gate that the rest of the admin API surface already used.

That made it a real security bug, not just a consistency issue.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-054-admin-settings-role-guards-and-feature-flag-contracts]]
- [[block-067-admin-generic-table-shell-mutation-hardening]]

## File notes

### `admin/src/app/api/events/route.ts`

- **Zone:** admin / API / events
- **Purpose:** list, create, update, and soft-delete live events
- **Problems found:**
  - `GET`, `POST`, `PATCH`, and `DELETE` were all reachable without an admin auth check
  - this route was inconsistent with the surrounding admin API surface, which already enforced `getAdminUser()`
- **What was fixed:**
  - added `getAdminUser()` checks to all handlers
  - unauthenticated requests now return `401 Unauthorized`
- **Status:** Fixed

## Problems found

1. **Admin event mutations were not protected by admin auth**
   - Risk: unauthorized callers could read or mutate live event configuration through the admin app API route.
   - Fix: added explicit admin authentication guards to every handler in the route.

2. **Security posture was inconsistent across adjacent admin API routes**
   - Risk: reviewers could assume parity from neighboring files and miss the exception.
   - Fix: aligned `events` with the existing admin API contract used by `items`, `seasons`, `dungeons`, `upload`, and the `admin/*` routes.

## Verification

- targeted admin `eslint`:
  - `src/app/api/events/route.ts`
- `npx next build` in `admin/`
- `git diff --check`
- compared admin API route auth coverage with `rg -n "getAdminUser|Unauthorized"` across `admin/src/app/api`

## Follow-up

- the next security pass should stay alert for route-parity gaps like this whenever a new admin API file appears
- this block materially improves the admin surface; it was one of the clearer “fix now” findings from the recent residual pass
