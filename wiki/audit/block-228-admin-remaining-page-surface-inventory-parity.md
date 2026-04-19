---
title: Audit Block 228 — Admin Remaining Page Surface Inventory Parity
category: audit
tags: [audit, docs, admin, surfaces, inventory]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/components/layout/nav-items.ts
  - admin/src/app/(dashboard)/battle-pass/page.tsx
  - admin/src/app/(dashboard)/battle-pass/battle-pass-client.tsx
  - admin/src/app/(dashboard)/daily-login/page.tsx
  - admin/src/app/(dashboard)/daily-login/daily-login-client.tsx
  - admin/src/app/(dashboard)/iap-products/page.tsx
  - admin/src/app/(dashboard)/iap-products/iap-products-client.tsx
  - admin/src/app/(dashboard)/matchmaking/page.tsx
  - admin/src/app/(dashboard)/minigame-sessions/page.tsx
  - admin/src/app/(dashboard)/minigame-sessions/minigame-sessions-client.tsx
  - admin/src/app/(dashboard)/referrals/page.tsx
  - admin/src/app/(dashboard)/social/page.tsx
  - admin/src/app/(dashboard)/dungeon-map/page.tsx
  - admin/src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx
  - admin/src/app/(dashboard)/design-system/page.tsx
  - admin/src/app/(dashboard)/design-system/design-system-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 228 — Admin Remaining Page Surface Inventory Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/components/layout/nav-items.ts`
- `admin/src/app/(dashboard)/battle-pass/page.tsx`
- `admin/src/app/(dashboard)/battle-pass/battle-pass-client.tsx`
- `admin/src/app/(dashboard)/daily-login/page.tsx`
- `admin/src/app/(dashboard)/daily-login/daily-login-client.tsx`
- `admin/src/app/(dashboard)/iap-products/page.tsx`
- `admin/src/app/(dashboard)/iap-products/iap-products-client.tsx`
- `admin/src/app/(dashboard)/matchmaking/page.tsx`
- `admin/src/app/(dashboard)/minigame-sessions/page.tsx`
- `admin/src/app/(dashboard)/minigame-sessions/minigame-sessions-client.tsx`
- `admin/src/app/(dashboard)/referrals/page.tsx`
- `admin/src/app/(dashboard)/social/page.tsx`
- `admin/src/app/(dashboard)/dungeon-map/page.tsx`
- `admin/src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx`
- `admin/src/app/(dashboard)/design-system/page.tsx`
- `admin/src/app/(dashboard)/design-system/design-system-client.tsx`

## Why this block

The remaining drift in `ADMIN_CAPABILITIES.md` was no longer about individual forms that overstated their power. It had become a map problem:

- several live dashboard routes already existed in `nav-items.ts`, but still had no first-class capability sections in the document
- the bottom `Page Surface Inventory` list still hid or misplaced real routes like `Matchmaking`, `Referrals`, `IAP Products`, and `Minigame Sessions`
- `Social`, `Dungeon Map`, and `Design System` were only partially represented even though they are real sidebar surfaces with specific roles

## Fix applied

### Added the missing live route sections

Added dedicated capability sections for:

- `Matchmaking`
- `Referrals`
- `Dungeon Map`
- `Battle Pass Rewards`
- `Daily Login Rewards`
- `IAP Products`
- `Minigame Sessions`
- `Social Hub`
- `Design System`

Each section now describes the actual current surface instead of leaving those routes implied by the nav only.

### Narrowed wording to the real live behavior

The new sections explicitly frame these routes as what they really are today:

- `Matchmaking` is a read-only rating-distribution review page
- `Referrals` is a read-only qualification-claims audit page
- `Battle Pass` is a reward-authoring page, not a sales/pass-management suite
- `Daily Login` is a 7-day reward-cycle editor, not a calendar/rules engine
- `IAP Products` is a read-only SKU review page backed by code/config
- `Minigame Sessions` is a read-only audit page
- `Social` is a review surface for friendships/messages/challenges, not a moderation console
- `Dungeon Map` is a manual layout editor, not a route-generation tool
- `Design System` is a team reference surface, not a full Storybook/export pipeline

### Fixed the page inventory

Rewrote the `Page Surface Inventory` section so it now matches the live grouped dashboard surface much more closely:

- added `Matchmaking`
- added `Referrals`
- added `IAP Products`
- added `Minigame Sessions`
- moved `Social` into the overview/review cluster where it actually behaves as a read-side audit surface
- updated the current-repo note so analytics-adjacent pages are described as a small collection of review screens, not a unified telemetry dashboard

## Result

`ADMIN_CAPABILITIES.md` now treats the remaining sidebar routes as real first-class surfaces instead of half-hidden nav entries, and the bottom inventory finally lines up with what the dashboard actually ships.

## Verification

- compared the capability doc against the live sidebar route map in `admin/src/components/layout/nav-items.ts`
- compared each new section against the current page/component code for battle pass, daily login, IAP products, matchmaking, minigame sessions, referrals, social, dungeon map, and design system
- `git diff --check`

This closes the remaining page-surface inventory drift inside the admin capability map.
