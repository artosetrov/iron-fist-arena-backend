---
title: Audit Block 241 — Feature Map PvP Combat Test and Admin Boundary Sync
category: audit
tags: [audit, wiki, features, pvp, tests, admin]
sources:
  - wiki/features/pvp-combat.md
  - backend/tests/api/pvp-resolve.test.ts
  - backend/tests/api/pvp-prepare-bot-ticket.test.ts
  - backend/tests/api/pvp-history.test.ts
  - backend/tests/api/social-challenges.test.ts
  - backend/tests/lib/bot-ticket.test.ts
  - admin/src/app/(dashboard)/matches/page.tsx
  - admin/src/app/(dashboard)/players/page.tsx
  - admin/src/app/(dashboard)/players/[id]/page.tsx
  - admin/src/app/(dashboard)/economy/page.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 241 — Feature Map PvP Combat Test and Admin Boundary Sync

## Scope

- `wiki/features/pvp-combat.md`
- adjacent backend PvP tests
- adjacent live admin PvP review surfaces

## Why this block

After the previous runtime feature-map pass, the only remaining live `backend/src/__tests__/` placeholder in `wiki/features` was `pvp-combat.md`.

It also still used a very broad `admin/src/app/` note instead of the concrete match / player / economy review pages that actually exist.

## Fix applied

- replaced the stale generic test placeholder with the real checked-in PvP/runtime tests
- rewrote the broad admin note to the actual live review surfaces:
  - matches
  - players list
  - player detail
  - economy review

## Result

The live feature-map layer no longer carries any leftover `backend/src/__tests__/` placeholders outside the template file.

## Verification

- live file existence checks for the referenced backend tests
- live file existence checks for the referenced admin pages
- `git diff --check`
