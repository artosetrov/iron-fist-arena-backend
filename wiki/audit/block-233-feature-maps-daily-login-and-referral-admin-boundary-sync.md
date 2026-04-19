---
title: Audit Block 233 — Feature Maps Daily Login and Referral Admin Boundary Sync
category: audit
tags: [audit, wiki, feature-map, daily-login, referral, admin]
sources:
  - wiki/features/daily-login.md
  - wiki/features/referral.md
  - admin/src/app/(dashboard)/daily-login/page.tsx
  - admin/src/app/(dashboard)/daily-login/daily-login-client.tsx
  - admin/src/app/(dashboard)/referrals/page.tsx
  - Hexbound/Hexbound/Services/DailyLoginService.swift
updated: 2026-04-19
status: Fixed
---

# Audit Block 233 — Feature Maps Daily Login and Referral Admin Boundary Sync

## Scope

- `wiki/features/daily-login.md`
- `wiki/features/referral.md`
- `admin/src/app/(dashboard)/daily-login/page.tsx`
- `admin/src/app/(dashboard)/daily-login/daily-login-client.tsx`
- `admin/src/app/(dashboard)/referrals/page.tsx`
- `Hexbound/Hexbound/Services/DailyLoginService.swift`

## Why this block

Two feature maps still sounded like older partial snapshots:

- `daily-login.md` still said the admin editor existed only “if present” and kept the older `7 or 30 days` wording
- `referral.md` still described a vague “referral funnel dashboard (if present)” instead of the actual read-only claims review page

Those pages were now behind the rest of the admin/doc cleanup and kept reintroducing uncertainty into otherwise cleaned source-of-truth surfaces.

## Fix applied

- `daily-login.md`
  - replaced the “if present” admin wording with the real daily-login page and client files
  - documented the existing `DailyLoginService.swift` instead of a speculative direct-API fallback note
  - narrowed the calendar-length note to the live 7-day reward-cycle editor
  - removed the vague “if present” test note and replaced it with the current truth: runtime is anchored in the live routes plus `daily-login.ts`
- `referral.md`
  - replaced the vague admin note with the real `referrals/page.tsx` read-only claims review surface
  - added an explicit note that the page is review-only today, not a full funnel analytics or manual-credit dashboard

## Result

The daily-login and referral feature maps now point at live admin surfaces and current runtime boundaries instead of old “maybe present” language.

## Verification

- verified the daily-login page/client and referrals page exist in the current admin app
- verified `DailyLoginService.swift` exists and is the current iOS service surface
- `git diff --check`

This closes the next feature-map admin-boundary tail after the broader admin capability cleanup.
