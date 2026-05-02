---
title: Audit Block 300 — Push Surface APNS-Only Boundary Sync
category: audit
tags: [audit, push, backend, admin, docs]
sources:
  - backend/src/lib/push/send.ts
  - admin/src/actions/push.ts
  - admin/src/app/(dashboard)/push/push-client.tsx
  - docs/03_backend_and_api/API_REFERENCE.md
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - docs/01_source_of_truth/PROJECT_OVERVIEW.md
updated: 2026-05-01
status: Fixed
---

# Audit Block 300 — Push Surface APNS-Only Boundary Sync

## Scope

This block aligns the backend/admin/docs push surface with the actual live
delivery transport that ships in the repo today.

## Why this block

The checked-in push stack was already narrower than some of the surrounding
wording implied.

- the backend sender has a real APNS path for iOS
- Android tokens can be stored
- but there is no shipped FCM delivery transport yet

That meant parts of the source-of-truth layer still read like the repo had a
fully symmetrical APNS/FCM sender when the current production truth is more
bounded.

## Changes shipped

- Clarified `backend/src/lib/push/send.ts` so its top-level contract now says
  what it really does: live APNS sends, Android held inert until a real FCM
  sender exists.
- Updated `API_REFERENCE.md` so the push routes are described as device-token
  registration plus an APNS-backed iOS campaign path.
- Updated `ADMIN_CAPABILITIES.md` so the live admin push surface is explicitly
  documented as an iOS/APNS-first campaign sender rather than a platform-neutral
  delivery console.
- Updated `PROJECT_OVERVIEW.md` so `PushToken` no longer implies full current
  APNS/FCM parity.

## Result

The repo now tells the same truth in code, admin docs, and source-of-truth
overview: iOS push delivery is live, Android token storage exists, and Android
delivery itself remains future work rather than a silently implied capability.
