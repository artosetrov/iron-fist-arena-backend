---
title: Audit Block 208 — Project Overview Analytics Surface Parity
category: audit
tags: [audit, docs, analytics, source-of-truth]
sources:
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - backend/src/app/api/admin/stats/route.ts
  - backend/src/app/api/admin/economy/route.ts
  - backend/src/app/api/admin/iap/route.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 208 — Project Overview Analytics Surface Parity

## Scope

- `docs/01_source_of_truth/PROJECT_OVERVIEW.md`
- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `backend/src/app/api/admin/stats/route.ts`
- `backend/src/app/api/admin/economy/route.ts`
- `backend/src/app/api/admin/iap/route.ts`

## Why this block

After the admin analytics cleanup, `PROJECT_OVERVIEW.md` was still speaking in a broader analytics dialect than the live repo:

- implied live PvP/class/rating analytics views
- implied live retention/session dashboards
- kept “Advanced analytics dashboard” phrasing in the roadmap without clarifying that the current surface is still much narrower

## Fix applied

### `docs/01_source_of_truth/PROJECT_OVERVIEW.md`

- rewrote the current analytics section to describe the live review surface:
  - aggregate admin stats
  - economy review
  - IAP transaction review
  - tutorial funnel / provider-agnostic instrumentation groundwork
- moved retention/session-style analytics back into future-facing wording
- renamed the roadmap item to a clearer future target rather than something that sounds already half-live

## Result

The source-of-truth overview now matches the current project reality:

- analytics today = narrow review + instrumentation foundation
- deeper retention/session/behavior dashboards = future work

## Later follow-up

This block was tightened further by `block-214-delete-orphan-admin-review-routes`:

- the review surface described here no longer depends on dedicated backend `stats/economy/iap` routes
- aggregate review now lives through the admin app's own read-side/server-action layer
- the dedicated backend admin catalog surface left in this area is `/api/admin/iap-products`

## Verification

- compared `PROJECT_OVERVIEW.md` against the live admin docs and backend admin routes
- `git diff --check`

The overview now speaks the same language as the current admin/runtime surface.
