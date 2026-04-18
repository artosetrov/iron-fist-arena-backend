---
title: Audit Block 157 — Stale Audit Tail Sync for Contraband and Social Challenges
category: audit
tags: [audit, backend, contraband, shop-offers, social-challenges, truth-sync]
sources:
  - backend/src/app/api/shop/contraband/route.ts
  - backend/src/app/api/shop/offers/route.ts
  - backend/src/app/api/social/challenges/route.ts
  - wiki/audit/block-012-backend-stash-contraband-premium-runtime.md
  - wiki/audit/block-013-backend-reward-premium-parity.md
updated: 2026-04-17
status: Fixed
---

# Audit Block 157 — Stale Audit Tail Sync for Contraband and Social Challenges

## Scope

- `backend/src/app/api/shop/contraband/route.ts`
- `backend/src/app/api/shop/offers/route.ts`
- `backend/src/app/api/social/challenges/route.ts`
- `wiki/audit/block-012-backend-stash-contraband-premium-runtime.md`
- `wiki/audit/block-013-backend-reward-premium-parity.md`

## Why this block

Two older audit warnings no longer matched the live backend:

1. `shop/contraband` was still described as directly incrementing XP without level-up handling.
2. `social/challenges` was still described as a warning-heavy `any`-heavy route.

Both concerns were true earlier in the sequence, but later code passes already changed the runtime:

- `contraband` and `shop/offers` now use shared reward grants and expose level-up fields
- `social/challenges` no longer carries the old `any` debt that the earlier audit snapshot referenced

## What changed

### `wiki/audit/block-012-backend-stash-contraband-premium-runtime.md`

- updated the `shop/contraband` file record from `Needs review` to `Fixed`
- removed the stale warning that contraband still incremented XP directly without level-up handling
- narrowed the remaining concern to broader shared reward-path consistency only where it still truly exists

### `wiki/audit/block-013-backend-reward-premium-parity.md`

- updated the `social/challenges` file record from `Needs review` to `Fixed`
- removed the stale `Remaining any usage is still high` warning
- narrowed the duplicate/split-logic note so it no longer claims that `social/challenges` is still blocked by ad hoc `any` shaping

## Problems resolved

1. **Contraband audit still warned about a reward path that was already replaced**
   - Resolution: audit now reflects the shared `grantRewardEntries(...)` runtime and level-up parity fields.

2. **Social challenges audit still warned about `any` debt that is no longer present**
   - Resolution: audit now reflects the current typed route surface and keeps only the still-real merge-policy/product follow-up.

## Verification

- `rg -n 'grantRewardEntries|leveled_up|passive_points_awarded' backend/src/app/api/shop/contraband/route.ts backend/src/app/api/shop/offers/route.ts`
- `rg -n '\\bany\\b' backend/src/app/api/social/challenges/route.ts`
- `npx eslint src/app/api/social/challenges/route.ts src/app/api/shop/contraband/route.ts src/app/api/shop/offers/route.ts`
- `git diff --check -- wiki/audit/block-012-backend-stash-contraband-premium-runtime.md wiki/audit/block-013-backend-reward-premium-parity.md wiki/audit/block-157-stale-audit-tail-contraband-and-social-challenges-sync.md wiki/audit/audit-index.md wiki/index.md wiki/log.md wiki/audit/project-file-inventory.md`

All passed for the touched files, and the route re-check confirmed the old audit warnings were stale.
