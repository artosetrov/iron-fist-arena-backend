---
title: Audit Block 222 — Admin Player Appearance Mail And Footer Surface Parity
category: audit
tags: [audit, docs, admin, players, appearances, mail]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/app/(dashboard)/players/players-client.tsx
  - admin/src/app/(dashboard)/players/[id]/player-client.tsx
  - admin/src/app/(dashboard)/appearances/appearances-client.tsx
  - admin/src/app/(dashboard)/mail/mail-client.tsx
  - admin/src/actions/mail.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 222 — Admin Player Appearance Mail And Footer Surface Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/app/(dashboard)/players/players-client.tsx`
- `admin/src/app/(dashboard)/players/[id]/player-client.tsx`
- `admin/src/app/(dashboard)/appearances/appearances-client.tsx`
- `admin/src/app/(dashboard)/mail/mail-client.tsx`
- `admin/src/actions/mail.ts`

## Why this block

The next stale capability cluster in `ADMIN_CAPABILITIES.md` was still overstating several live admin surfaces:

- Players still sounded like a broad account-ops console with soft delete, grant-items, and direct email flows
- Appearances still claimed a 3D model preview and a broader cosmetics catalog than the live skin editor provides
- Mail still described scheduled sends, richer attachments, resend flows, and extra targeting filters that the current screen does not ship
- The global security/UX footer still implied generic undo and CSV bulk flows across the dashboard

## Fix applied

### Players

- narrowed the list-page language to the live search/list surface:
  - username/email search
  - basic account columns
  - row navigation into player detail
  - ban/unban
- moved advanced actions to the player detail view where they actually exist:
  - grant gold
  - grant gems
  - reset inventory
  - inspect characters, equipment, match history, purchases
- removed soft delete, grant-items, and direct email claims

### Appearances

- rewrote the section around the live appearance-skin editor:
  - `skinKey`
  - origin / gender
  - rarity
  - gold/gem prices
  - image URL / key
  - default toggle
  - sort order
- removed the 3D preview claim
- added a note that the live page is a 2D appearance-skin surface, not a full cosmetics catalog for effects/emotes/titles

### Mail

- rewrote the targeting model to the actual live choices:
  - broadcast
  - segment by min/max level and class
  - single character target
- rewrote attachments to the actual live payload:
  - gold
  - gems
  - xp
- removed:
  - markdown body claim
  - future scheduling
  - online-only send
  - repeat cadence
  - resend flow
  - item / consumable / cosmetic attachments
- documented the live tracking surface:
  - message totals
  - recipient totals
  - read / claimed rates
  - per-message read/claim counts
  - delete sent mail

### Footer notes

- narrowed the security note so it no longer reads like a formal controls matrix
- removed the generic “undo on most destructive actions” claim
- removed the generic “CSV import/export bulk actions” claim
- softened tooltips/help-text language to match the real dashboard more closely

## Result

The remaining player/content-ops/liveops overstatements in `ADMIN_CAPABILITIES.md` now line up with the real admin surfaces much more closely instead of promising a broader GM toolset than the repo currently ships.

## Verification

- compared the docs against the live players list/detail, appearances screen, mail screen, and mail action payload
- `git diff --check`

This closes the next stale capability cluster inside `ADMIN_CAPABILITIES.md`.
