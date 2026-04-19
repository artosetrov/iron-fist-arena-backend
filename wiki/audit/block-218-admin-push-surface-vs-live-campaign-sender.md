---
title: Audit Block 218 — Admin Push Surface Vs Live Campaign Sender
category: audit
tags: [audit, docs, admin, push]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/app/(dashboard)/push/page.tsx
  - admin/src/app/(dashboard)/push/push-client.tsx
  - admin/src/actions/push.ts
  - admin/src/lib/push-campaigns.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 218 — Admin Push Surface Vs Live Campaign Sender

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/app/(dashboard)/push/page.tsx`
- `admin/src/app/(dashboard)/push/push-client.tsx`
- `admin/src/actions/push.ts`
- `admin/src/lib/push-campaigns.ts`

## Why this block

The push section in `ADMIN_CAPABILITIES.md` was still describing a much richer system than the repo actually ships:

- VIP / inactive / new-player cohorts
- timezone scheduling
- recurring campaigns
- A/B push tests
- delivered/open/click analytics

But the live admin screen is much narrower:

- create a campaign
- target broadcast / segment / explicit user IDs
- segment by min/max level and class
- optionally attach a route
- send it
- review sent/failed/token counters

## Fix applied

### `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

- rewrote the Push Notifications section to match the live UI and action layer
- documented the actual supported target types:
  - broadcast
  - segment
  - user IDs
- documented the actual supported segment filters:
  - min level
  - max level
  - class
- kept optional route/deep-link support
- reduced analytics wording to the counters that really exist today:
  - sent count
  - failed count
  - active token count
- added an explicit note that the current repo does **not** expose:
  - timezone scheduling
  - recurring campaigns
  - A/B messaging
  - rich media
  - delivered/open/click analytics
  - VIP / inactive / region / beta-tester cohort targeting

## Result

The admin push docs now describe the actual live campaign sender instead of a speculative lifecycle-marketing suite.

## Verification

- compared `ADMIN_CAPABILITIES.md` against `push/page.tsx`, `push-client.tsx`, `actions/push.ts`, and `lib/push-campaigns.ts`
- `git diff --check`

This closes the remaining push-surface overstatement in the admin docs corridor.
