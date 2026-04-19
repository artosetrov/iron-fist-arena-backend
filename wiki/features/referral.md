# Feature: Referral

> Single-file map of every file that touches referral codes — invite-a-friend flow with staged rewards.

## One-liner

Players share a unique 8-character invite code; when an invitee signs up and hits progression milestones, both sides receive rewards.

## Status

- **Phase:** In production
- **Last major change:** Recent — `ReferralRewardClaim` model added to backend schema, synced to admin

## Entry points

- **iOS screen:** `Hexbound/Hexbound/Views/Settings/SettingsDetailView.swift` (section)
- **iOS component:** `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`
- **Player action:** Settings → Referral section → copy/share code OR enter friend's code

## Backend

### Routes

- `POST /api/tutorial/referral` — `backend/src/app/api/tutorial/referral/route.ts` — claim referral reward / register invitee-referrer link

### Business logic

- `backend/src/lib/game/tutorial.ts` — referral reward claim rules embedded in tutorial flow
- `backend/src/lib/game/tutorial-analytics.ts` — referral funnel events
- `backend/src/lib/game/progression.ts` — progression milestones that trigger referral reward claims

### Prisma models touched

- `ReferralRewardClaim` (line 148) — records a reward given to referrer or invitee at a specific milestone
  - `referrerCharacterId` / `inviteeCharacterId` — both indexed
  - `@@unique([referrerCharacterId, inviteeCharacterId])` — one relationship per pair
- `Character` (line 439-440):
  - `referralCode` — 8-char unique invite code, nullable
  - `referredBy` — character_id of referrer, nullable
  - Back-relations: `referralRewardsGiven`, `referralRewardsReceived`

### Schema fields

- `backend/prisma/schema.prisma` — `referral_code`, `referred_by` columns on `characters`
- Table: `referral_reward_claims`

## iOS

### Views

- `Hexbound/Hexbound/Views/Settings/SettingsDetailView.swift` — hosts referral section
- `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift` — copy code / enter code UI

### Reward surface

- invitee-side friend-code apply now presents the gold payout through the shared `ClaimRewardModalView` ceremony, not a toast
- inline status text remains for local confirmation/error context, but the actual currency reward moment is modal-backed

### Tutorial

- `Hexbound/Hexbound/Tutorial/TutorialManager.swift` — referral redeem is woven into tutorial progression events

## Admin

- `admin/src/app/(dashboard)/referrals/page.tsx` — read-only referral claims review page with total claims, last-7-days count, and recent qualification rows

## Docs

- `docs/04_database/SCHEMA_REFERENCE.md` — ReferralRewardClaim entry
- `docs/02_product_and_features/ECONOMY.md` — referral rewards are a currency source

## Notable gotchas

- **Prisma schema sync.** Adding `ReferralRewardClaim` required `cp backend/prisma/schema.prisma admin/prisma/schema.prisma`. Missing copy = admin CI fail + crash. See CLAUDE.md Prisma Schema Sync section.
- **Milestone-gated.** Rewards fire on tutorial/progression milestones, not on signup alone — check `tutorial.ts` for trigger points.
- **Unique invite code generation.** 8-character code must be globally unique on `characters.referral_code` — handle DB uniqueness collision with retry.
- **Admin surface is review-only today.** The referrals page is an audit/review table, not a full funnel analytics or manual-credit dashboard.

## Related features

- [[shop]] — referral rewards can include gems (shop currency)
