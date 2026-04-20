---
title: Audit Block 240 — Feature Maps Runtime Test and Admin Surface Sync
category: audit
tags: [audit, wiki, features, tests, admin]
sources:
  - wiki/features/interactive-combat.md
  - wiki/features/passive-tree.md
  - wiki/features/session-summary.md
  - wiki/features/gold-mine.md
  - wiki/features/stash.md
  - wiki/features/inventory.md
  - wiki/features/shop.md
  - wiki/features/dungeons.md
  - wiki/features/leaderboard.md
  - wiki/features/dungeon-rush.md
  - wiki/features/battle-pass.md
  - wiki/features/events.md
  - wiki/features/quests.md
  - wiki/features/mail.md
  - backend/tests/api/pvp-resolve.test.ts
  - backend/tests/api/pvp-prepare-bot-ticket.test.ts
  - backend/tests/api/pvp-history.test.ts
  - backend/tests/api/inventory-equip.test.ts
  - backend/tests/api/inventory-unequip.test.ts
  - backend/tests/api/inventory-sell.test.ts
  - backend/tests/api/shop-buy.test.ts
  - backend/tests/api/dungeon-rush-resolve.test.ts
  - admin/src/app/(dashboard)/skills/page.tsx
  - admin/src/app/(dashboard)/passives/page.tsx
  - admin/src/app/(dashboard)/battle-pass/page.tsx
  - admin/src/app/(dashboard)/events/page.tsx
  - admin/src/app/(dashboard)/quests/page.tsx
  - admin/src/app/(dashboard)/mail/page.tsx
  - admin/src/app/(dashboard)/items/page.tsx
  - admin/src/app/(dashboard)/dungeons/page.tsx
  - admin/src/app/(dashboard)/matches/page.tsx
  - admin/src/app/(dashboard)/economy/page.tsx
  - admin/src/app/(dashboard)/config/page.tsx
  - admin/src/app/(dashboard)/minigame-sessions/page.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 240 — Feature Maps Runtime Test and Admin Surface Sync

## Scope

- runtime-heavy feature maps that still carried placeholder test notes
- feature maps that still pointed at broad admin directories instead of the live page/client files

## Why this block

After the previous feature-map cleanup, one wider cluster still had older drift:

- `backend/src/__tests__/*` placeholders with no relation to the current `backend/tests/` tree
- broad admin references like `admin/src/app/(dashboard)/dungeons/` or even `admin/src/app/` instead of the real live page/client surfaces

That made several runtime maps look fuzzier than the repo actually is.

## Fix applied

- replaced remaining placeholder test notes with:
  - real checked-in tests where they exist today
  - explicit “no dedicated backend test file is checked in today” notes where coverage is still adjacent rather than feature-owned
- rewrote broad admin directory notes to the actual live surfaces for:
  - battle pass
  - events
  - quests
  - mail
  - inventory
  - dungeons
  - interactive combat
  - passive tree
  - shop
  - gold mine
- narrowed several “admin console” claims into honest adjacent review/tuning wording

## Result

The runtime feature-map layer now points at the real admin entry points and the real current test surface, instead of preserving leftover placeholders and broad directory shorthand.

## Verification

- live file existence checks for referenced admin page/client files
- live file existence checks for referenced backend tests
- `git diff --check`
