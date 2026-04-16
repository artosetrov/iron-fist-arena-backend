---
title: Block 055 — admin push and shop-offer contract hardening
category: audit
tags: [audit, admin, push, shop, offers, auth, contracts]
sources:
  - admin/src/lib/push-campaigns.ts
  - admin/src/actions/push.ts
  - admin/src/app/(dashboard)/push/push-client.tsx
  - admin/src/lib/shop-offers.ts
  - admin/src/actions/shop-offers.ts
  - admin/src/app/(dashboard)/offers/offers-client.tsx
updated: 2026-04-15
status: Fixed
---

# Block 055 — admin push and shop-offer contract hardening

## Scope

- `admin/src/lib/push-campaigns.ts`
- `admin/src/actions/push.ts`
- `admin/src/app/(dashboard)/push/push-client.tsx`
- `admin/src/lib/shop-offers.ts`
- `admin/src/actions/shop-offers.ts`
- `admin/src/app/(dashboard)/offers/offers-client.tsx`

## Why this block

The next admin warning-heavy slice turned out to contain two real runtime risks:

1. several `push` actions called `getAdminUser()` but never checked the result, which meant an unauthorized request could keep going instead of failing closed;
2. malformed user-targeted push campaigns fell through to the broadcast branch during send, so a bad `targetFilter` could accidentally target every active token.

The adjacent `shop-offers` surface had the same shape problem in a different costume: bundle contents, prices, windows, and offer metadata were accepted through weak `any` paths, so the admin UI could save offers the live shop runtime was never meant to consume.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[bug-patterns]]
- [[economy]]

## File notes

### `admin/src/lib/push-campaigns.ts`

- **Zone:** admin / shared push helpers
- **Purpose:** canonical contract for push target types, payload data, segment filters, and schedule parsing
- **What was added:**
  - typed `broadcast | segment | user` target union
  - normalized campaign payload parsing
  - strict segment/user filter validation
  - explicit schedule parsing
- **Status:** Fixed

### `admin/src/actions/push.ts`

- **Zone:** admin / push actions
- **Purpose:** list, create, send, delete, and summarize push campaigns
- **Problems found:**
  - several actions continued after `getAdminUser()` returned `null`
  - malformed `user` campaigns could fall through to broadcast on send
  - payload `data` and `targetFilter` were accepted through weak JSON typing
- **What was fixed:**
  - added a hard `requireAdminUser()` guard for every action
  - normalized create payloads through the shared helper contract
  - made `sendCampaign()` reject malformed `user` campaigns instead of broadcasting
  - replaced the old `any` segment query builder with typed Prisma where-shape construction
- **Status:** Fixed

### `admin/src/app/(dashboard)/push/push-client.tsx`

- **Zone:** admin / push UI
- **Purpose:** create, preview, send, and delete push campaigns
- **Problems found:**
  - weak `any` state for campaign payloads
  - unused imports
  - no readable summary of who a segment/user campaign actually targets
- **What was fixed:**
  - moved client-side target parsing onto the shared push helper contract
  - removed weak payload typing and dead imports
  - added a small target summary in the table so malformed campaigns are easier to spot before send
- **Status:** Fixed

### `admin/src/lib/shop-offers.ts`

- **Zone:** admin / shared shop-offer helpers
- **Purpose:** canonical typing and validation for offer types, currencies, schedule windows, tags, and bundle contents
- **What was added:**
  - typed offer/content unions
  - normalized key/tag parsing
  - bundle-content validation including required `id` for `item`/`consumable`
  - schedule/date parsing
- **Status:** Fixed

### `admin/src/actions/shop-offers.ts`

- **Zone:** admin / shop-offer actions
- **Purpose:** list, create, update, seed, toggle, and delete live shop offers
- **Problems found:**
  - `contents` and update payloads relied on `any`
  - prices, discounts, level windows, and schedule windows were not validated
  - malformed offer data could be persisted even though the live shop runtime expects stricter shapes
- **What was fixed:**
  - normalized create/update/seed flows through shared validation helpers
  - blocked malformed contents, invalid currencies/types, inverted level ranges, inverted time windows, and sale prices above original price
  - removed the weak `data: any` update builder
- **Status:** Fixed

### `admin/src/app/(dashboard)/offers/offers-client.tsx`

- **Zone:** admin / offers UI
- **Purpose:** manage shop bundles and promotional offers
- **Problems found:**
  - weak icon/content typing
  - mutable `any` content editor path
  - stale dead imports
- **What was fixed:**
  - moved the editor onto typed offer/content contracts
  - removed the `any` mutation path from the bundle contents editor
  - cleaned the touched import noise
- **Status:** Fixed

## Problems found

1. **Unauthorized push actions did not fail closed**
   - Risk: admin push reads/writes could continue when there was no authenticated admin context.
   - Fix: added a hard auth guard helper and applied it consistently to every push action.

2. **Malformed user-targeted push campaigns could broadcast to everyone**
   - Risk: a bad `targetFilter` on a `user` campaign could accidentally send to all active push tokens.
   - Fix: normalized campaign target filters on both create and send, and made malformed user campaigns throw instead of falling through to broadcast.

3. **Shop-offer admin writes were wider than the live runtime contract**
   - Risk: the admin UI could save offers with invalid content entries, broken schedules, or nonsensical price windows.
   - Fix: introduced one shared validation layer for offer types, currencies, bundle contents, levels, tags, and schedule windows.

4. **Push/offers UI carried weak local typing that hid real behavior**
   - Risk: duplicated client parsing makes it easier for the editor to drift away from the server actions.
   - Fix: moved touched client parsing/editing code onto the same shared helper contracts the actions now use.

## Verification

- targeted admin `eslint`:
  - `src/lib/push-campaigns.ts`
  - `src/actions/push.ts`
  - `src/app/(dashboard)/push/push-client.tsx`
  - `src/lib/shop-offers.ts`
  - `src/actions/shop-offers.ts`
  - `src/app/(dashboard)/offers/offers-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- there is still no dedicated admin route/action test harness, so this block is validated through typed helpers, targeted lint, and a full Next build
- broader admin warning-heavy surfaces remain in `quests`, `battle-pass`, `design-system`, and a few demo/media-heavy editor files
