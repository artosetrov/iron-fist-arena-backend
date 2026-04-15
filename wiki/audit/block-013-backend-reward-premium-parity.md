---
title: Audit Block 013 — Backend Reward Premium Parity
category: audit
tags: [audit, backend, premium, rewards, pvp, dungeons, auth]
sources:
  - backend/src/lib/game/premium.ts
  - backend/src/app/api/pvp/
  - backend/src/app/api/dungeons/
  - backend/src/app/api/dungeon-rush/
  - backend/src/app/api/social/
  - backend/src/app/api/me/
  - backend/src/app/api/game/init/
  - backend/src/app/api/auth/upgrade-guest-oauth/
updated: 2026-04-15
---

# Audit Block 013 — Backend Reward Premium Parity

## Scope

This block audits the remaining premium-entitlement runtime after the subscription rollout: PvP and dungeon reward routes, duel/challenge rewards, user/profile surfaces that serialize premium state, and guest-to-OAuth account upgrade flow.

- **Files audited in this block:** 13
- **Primary file types:** Next.js route handlers, TypeScript entitlement helper
- **Status:** Gold-bonus parity is now consistent across reward routes, but `social/challenges` still carries typing debt and guest-account merge rules remain under-specified beyond premium entitlement
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-012-backend-stash-contraband-premium-runtime]], [[economy]], [[pvp-rating]], [[dungeons]]

## Summary

- The main systemic bug was real: many reward routes still selected only `user.premiumUntil`, while `premium.ts` already knew how to honor active `premiumSubscription` rows. In practice, Premium Pass users could miss the +10% gold bonus across PvP, dungeons, Dungeon Rush, and social challenges.
- The same rollout gap existed on client-facing read surfaces. `/me` and `/game/init` exposed only raw `premiumUntil`, so a subscriber with no legacy forever entitlement could look non-premium to the app even while some backend helpers already knew better.
- The most serious hidden defect in this block was `auth/upgrade-guest-oauth`: it transferred `premiumUntil`, cosmetics, IAP transactions, and daily gem card, but it did not transfer the unique `premiumSubscription` row. Upgrading a guest account after buying Premium Pass could silently orphan the subscription and then delete the owning user row.
- I also used this pass to shave off a little dead code in touched files so the next backend audit round has less noise.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | PvP, dungeon, rush, and challenge reward routes selected only `premiumUntil` before calling `goldBonusMultiplier()`. | Active Premium Pass users could miss paid gold-bonus entitlement across major reward loops. | Added a canonical entitlement select in `premium.ts` and updated every audited reward route to fetch both `premiumUntil` and `premiumSubscription`. |
| P1 | `auth/upgrade-guest-oauth` did not transfer `premiumSubscription` when migrating a guest account to OAuth. | A player could buy Premium Pass on a guest account, upgrade to Google/Apple, and lose the subscription row when the guest user was deleted. | Added in-transaction transfer/merge handling for `premiumSubscription`, preserving the longer-lived entitlement when both guest and OAuth rows exist. |
| P2 | `/me` and `/game/init` serialized only raw `premiumUntil`. | Subscribed users could look non-premium to clients that still read `premiumUntil` as the compatibility field. | Added `getPremiumExpiresAt()` helper and now serialize effective premium expiry back into the existing `premiumUntil` response field. |
| P3 | Premium entitlement shape was duplicated route by route. | Future rollout work could drift again, recreating partial premium support. | Centralized the common Prisma select shape in `PREMIUM_ENTITLEMENT_USER_SELECT` and made `premium.ts` able to derive entitlement directly from the nested subscription relation. |

## Cross-File Safe Fixes Applied

- `backend/src/lib/game/premium.ts` now exposes `PREMIUM_ENTITLEMENT_USER_SELECT` and `getPremiumExpiresAt()`, so callers can reuse one select shape and one compatibility serializer.
- Reward routes in PvP, dungeons, Dungeon Rush, and social challenges now all fetch the same entitlement shape before applying gold bonus.
- `backend/src/app/api/me/route.ts` and `backend/src/app/api/game/init/route.ts` now keep their existing API shape while surfacing the effective premium expiry for active subscribers.
- `backend/src/app/api/auth/upgrade-guest-oauth/route.ts` now preserves premium entitlement during guest-account upgrade by merging `premiumUntil` conservatively and transferring/merging the `premiumSubscription` row.
- Removed a handful of dead imports/unused locals in `social/challenges`, `dungeon-rush/*`, `dungeons/fight`, `pvp/resolve`, and `pvp/revenge`.

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `backend/src/lib/game/premium.ts` | Premium entitlement helper | Central source for premium gold bonus, daily gems, entitlement shape, and premium-expiry compatibility logic. | Used by reward routes, daily-login, `/me`, `/game/init`. | Premium is active if either forever entitlement or active/grace subscription expiry is in the future. | Fixed drift by exporting the canonical select shape and reusable effective-expiry helper. | Fixed |
| `backend/src/app/api/me/route.ts` | User profile read API | Returns the authenticated user's account profile. | Depends on auth + Prisma; used by client profile/settings surfaces. | Response must stay backward compatible for clients that still look at `premiumUntil`. | Fixed premium-status serialization so subscribers now surface as premium through the existing field. | Fixed |
| `backend/src/app/api/game/init/route.ts` | Session bootstrap API | Returns user, character, economy/config, quest, event, and feature-flag state for app boot. | Depends on many gameplay/config helpers; used by app startup. | This route is the main compatibility surface for runtime account state. | Fixed premium-status serialization so boot payload now reflects active subscriptions too. | Fixed |
| `backend/src/app/api/auth/upgrade-guest-oauth/route.ts` | Guest → OAuth account migration | Links a guest account to Google/Apple and transfers owned data to the OAuth user. | Depends on auth, Supabase admin client, Prisma, rate limit. | Must preserve paid entitlements when reparenting user-owned rows. | Fixed missing subscription-row transfer and preserved the longer `premiumUntil` when the OAuth user already exists. Broader merge semantics for gems/other user-owned state still deserve a product/architecture decision. | Needs review |
| `backend/src/app/api/pvp/fight/route.ts` | Classic PvP fight runtime | Runs one immediate PvP battle and awards rating, XP, gold, achievements, loot, and side effects. | Depends on combat loader, ELO, stamina, events, progression, achievements, mail/cache helpers. | Gold bonus must apply last, after CHA/streak/event modifiers. | Fixed premium entitlement select drift. Reward formula duplication with other PvP routes remains. | Fixed |
| `backend/src/app/api/pvp/match/complete/route.ts` | Interactive PvP finalizer | Finalizes in-progress interactive matches and awards the same side effects as classic PvP. | Depends on match state, ELO, progression, events, loot, cache helpers. | Must stay formula-compatible with `pvp/fight`. | Fixed premium entitlement select drift. Still duplicates reward formula logic with other PvP routes. | Fixed |
| `backend/src/app/api/pvp/revenge/[id]/route.ts` | Revenge fight runtime | Resolves revenge battles with revenge multiplier and normal PvP side effects. | Depends on revenge queue, combat, ELO, progression, achievements. | Revenge applies special gold multiplier but still uses the same premium-last rule. | Fixed premium entitlement select drift and removed one dead local after level-up. Route still over-fetches the attacker via `include`, which is inefficiency rather than a correctness bug. | Fixed |
| `backend/src/app/api/pvp/resolve/route.ts` | Authoritative PvP resolve + bot resolve | Re-runs combat, validates client outcome, awards rewards, and persists both human and bot PvP results. | Depends on combat engine, ELO, progression, events, bot helpers, battle mail. | Both human and bot resolve paths must use the same entitlement logic. | Fixed premium entitlement select drift in both resolve paths and removed one dead local in bot resolve. | Fixed |
| `backend/src/app/api/dungeons/fight/route.ts` | Boss dungeon fight runtime | Resolves structured dungeon boss fights, grants rewards, advances/deletes run, and applies side effects. | Depends on dungeon generation, progression, loot, durability, BP, guild challenge helpers. | Gold reward applies CHA first, premium last. | Fixed premium entitlement select drift and removed dead dungeon imports while touching the file. | Fixed |
| `backend/src/app/api/dungeons/run/[id]/fight/route.ts` | Standard dungeon floor runtime | Resolves normal dungeon floor fights and advances run state. | Depends on dungeon generation, training-XP DR, progression, loot, durability. | Dungeon training uses daily DR for XP and premium applies only to gold. | Fixed premium entitlement select drift. | Fixed |
| `backend/src/app/api/dungeon-rush/fight/route.ts` | Rush combat-room runtime | Resolves Dungeon Rush combat rooms with artifact buffs, HP persistence, and per-room rewards. | Depends on rush helper rules, progression, loot, durability, guild challenges. | Gold uses CHA + artifact multiplier first, premium last. | Fixed premium entitlement select drift and removed dead Battle Pass config load. | Fixed |
| `backend/src/app/api/dungeon-rush/resolve/route.ts` | Rush non-combat-room runtime | Resolves treasure/event/shop rooms and applies rewards/buffs. | Depends on rush helper rules, room lock helper, guild challenge increment. | Premium applies only when the resolved room grants gold. | Fixed premium entitlement select drift and removed dead artifact/config imports. | Fixed |
| `backend/src/app/api/social/challenges/route.ts` | Duel/challenge runtime | Lists challenges, sends them, accepts/declines them, runs duel combat, and awards challenge rewards. | Depends on combat engine, stamina, ELO, progression, mail, cache helpers. | Winner and loser both receive gold/XP, and premium applies independently to each side. | Fixed premium entitlement drift for both winner and loser and removed some dead code. Remaining `any` usage is still high, so this route stays a typing/maintainability follow-up candidate. | Needs review |

## Duplicate / Split Logic Found

- PvP reward math is still repeated across `pvp/fight`, `pvp/match/complete`, `pvp/resolve`, `pvp/revenge`, and `social/challenges`. The formulas are intentionally similar, but that makes future balance changes easy to miss in one path.
- Premium-aware user selection had already started to drift before this block. The new shared select fixes the immediate problem, but a broader “entitlement surface checklist” still does not exist.
- `social/challenges` still relies on a lot of explicit `any` and manual DTO shaping. It works, but it is harder to evolve safely than the other reward routes.
- `auth/upgrade-guest-oauth` still has broader unresolved merge-policy questions for non-premium fields when both guest and OAuth user rows already contain state.

## Files Without Clear Current Role

- None in this block. Every file has a live runtime role.

## Candidates For Refactor

- Extract a shared PvP reward service so classic PvP, interactive PvP, revenge, bot resolve, and social duels stop reimplementing the same gold/xp/ELO award sequence.
- Add a small account-entitlement serializer/helper for read surfaces so `/me`, `/game/init`, and future session/profile routes cannot drift from each other.
- Define explicit account-merge policy for guest→OAuth upgrades: which fields should overwrite, merge, max, sum, or fail when both accounts already contain data.
- Replace `social/challenges` ad hoc `any` payload shaping with typed query/result helpers.

## Documentation Missing Or Stale

- No current page lists every backend route that must honor premium entitlement and whether it uses reward-time logic, read-time serialization, or account-migration handling.
- No current account-merge doc specifies how entitlements, gems, consumables, or cards should merge during guest→OAuth upgrade when both sides already have state.
- No current backend doc names `PREMIUM_ENTITLEMENT_USER_SELECT` as the canonical select for premium-aware routes.

## Verification

- `bash -lc 'cd backend && npx eslint src/lib/game/premium.ts src/app/api/daily-login/claim/route.ts src/app/api/me/route.ts src/app/api/game/init/route.ts src/app/api/auth/upgrade-guest-oauth/route.ts src/app/api/pvp/fight/route.ts src/app/api/pvp/match/complete/route.ts "src/app/api/pvp/revenge/[id]/route.ts" src/app/api/pvp/resolve/route.ts src/app/api/dungeons/fight/route.ts "src/app/api/dungeons/run/[id]/fight/route.ts" src/app/api/dungeon-rush/fight/route.ts src/app/api/dungeon-rush/resolve/route.ts src/app/api/social/challenges/route.ts'` reports **0 errors** and **12 warnings**, all remaining in `social/challenges/route.ts` (`no-explicit-any` debt).
- `python3 scripts/check_schema_drift.py --verbose` passes.
- `git diff --check` passes.
