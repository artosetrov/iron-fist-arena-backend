---
title: Audit Block 243 — API Reference Runtime and Admin Surface Parity
category: audit
tags: [audit, docs, api, admin, gold-mine]
sources:
  - docs/03_backend_and_api/API_REFERENCE.md
  - backend/src/app/api/shop/buy-gold/route.ts
  - backend/src/app/api/session-summary/route.ts
  - backend/src/app/api/minigames/gold-mine/collect-all/route.ts
  - backend/src/app/api/minigames/gold-mine/minigame-bonus/route.ts
  - backend/src/app/api/minigames/gold-mine/slot-minigame/start/route.ts
  - backend/src/app/api/minigames/gold-mine/slot-minigame/submit/route.ts
  - backend/src/app/api/admin/config/route.ts
  - backend/src/app/api/admin/config/restore/route.ts
  - backend/src/app/api/admin/referrals/route.ts
  - backend/src/app/api/admin/matchmaking/route.ts
  - backend/src/app/api/admin/minigame-sessions/route.ts
  - admin/src/app/api/items/route.ts
  - admin/src/app/api/events/route.ts
  - admin/src/app/api/seasons/route.ts
  - admin/src/app/api/dungeons/[id]/route.ts
  - admin/src/app/api/settings/role/route.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 243 — API Reference Runtime and Admin Surface Parity

## Scope

- `docs/03_backend_and_api/API_REFERENCE.md`
- adjacent runtime routes that define the truth for Gold Mine, shop exchange, session summary, and admin route ownership

## Why this block

`API_REFERENCE.md` was still carrying a mixed snapshot:

- `shop/buy-gold` was described like an IAP route even though the live route is gem-to-gold exchange
- Gold Mine listed only the older core routes and missed the live aggregate/per-slot bonus session endpoints
- the admin sections still mixed real routes with stale method shapes
- the bottom `NOT IMPLEMENTED` block was now actively misleading, because several listed surfaces do exist in the live admin dashboard but are owned by admin-local APIs or server actions instead of standalone backend route families

## Fix applied

- corrected `/shop/buy-gold` to the real gem-to-gold exchange surface
- expanded Gold Mine coverage to include:
  - `/minigames/gold-mine/collect-all`
  - `/minigames/gold-mine/minigame-bonus`
  - `/minigames/gold-mine/slot-minigame/start`
  - `/minigames/gold-mine/slot-minigame/submit`
- tightened `/session-summary` wording to the actual recent-session snapshot behavior
- corrected backend admin route methods and added the live config/restore/referrals/matchmaking/minigame-sessions paths
- corrected admin-local route method shapes for items, events, seasons, dungeons, settings role, and the admin proxy routes
- replaced the stale `NOT IMPLEMENTED` graveyard with an explicit boundary note explaining that many live admin screens are owned by admin-local APIs or server actions rather than by dedicated backend route families

## Result

`API_REFERENCE.md` is back to being a usable runtime map instead of a half-current snapshot that made the admin surface look smaller than the shipped dashboard and made Gold Mine / shop semantics look older than the code.

## Verification

- live route existence and method checks against backend/admin route files
- `git diff --check`
