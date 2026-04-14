# ADR: Premium Forever → Premium Pass (30-day subscription)

**Status:** Accepted (Economy v3, 2026-04-13)
**Owner:** Artem
**Scope:** Backend (`balance.ts`, `verify-receipt`), Apple StoreKit config, iOS storefront UI, docs.
**Related:** `ECONOMY_RULES.md` R11, `ECONOMY_AUDIT_2026-04-13.md` finding #1.

---

## Context

`premium_forever` is a **one-time $9.99** SKU that grants permanent premium (10% gold multiplier + 25 daily gems + "Chosen" title). At a conservative estimate, a single buyer who stays active for a year receives **~9,000 gems** for the $9.99 spend — far below the $0.015/gem floor the rest of the catalog enforces. This is the single biggest LTV leak in the current economy and was flagged as Critical-1 in the 2026-04-13 audit.

## Decision

1. **Disable `premium_forever` for new purchases** (set `enabled: false` in `IAP_PRODUCTS`). **Grandfather existing owners** — server continues to honor `premiumUntil = 2099-12-31` for anyone who already owns it. No refunds, no forced downgrades.
2. **Introduce `premium_pass_monthly`** — a **30-day auto-renewable subscription** at **$4.99/month** (Apple StoreKit Group 1). Benefits identical to Premium Forever *during* the active window: 10% gold multiplier, 25 daily gems, "Chosen" title, BP premium unlock discount (−100 gems).
3. **During overlap (subscription + legacy forever):** legacy forever always wins. No double-dipping.

## Why Subscription, Not Bigger One-Time

- **Predictable LTV.** $4.99 × avg 3–4 months retention = $15–20 per premium user vs. $9.99 flat forever. Matches industry benchmarks for mid-core RPG premium passes.
- **Retention lever.** Monthly renewal decision re-engages borderline churners. One-time purchases offer no such hook.
- **Platform-native.** Apple's auto-renewable subscription UX is expected by users for this price/benefit shape.

## What Changes (delivery plan)

### Phase 1 — shipped in Economy v3 PR (this release)

- [x] Add `enabled?: boolean` to `IapProduct`.
- [x] `premium_forever.enabled = false`.
- [x] `/api/iap/products` filters disabled SKUs.
- [x] `/api/iap/verify-receipt` returns 410 Gone for disabled SKUs.
- [x] Docs updated (`BALANCE_CONSTANTS.md`, `ECONOMY_RULES.md`).

**Observable outcome:** storefront hides Premium Forever. Existing owners unaffected. No new Premium entitlements created until Phase 2 ships.

### Phase 2 — backend shipped 2026-04-14 (batch 4)

- [x] Prisma migration: add `PremiumSubscription` table (`userId`, `startedAt`, `expiresAt`, `autoRenew`, `originalTransactionId`, `latestTransactionId`, `latestReceipt`, `status`). Applied to prod via Supabase MCP + on-disk migration `20260414_premium_subscription/`.
- [x] `IAP_PRODUCTS.premium_pass_monthly` entry (price $4.99, 30-day window, 300 gems/period).
- [x] `verify-receipt` branch for subscription: reads `appleResult.transactionInfo.expiresDate`, falls back to `purchaseDate + durationDays`, upserts `PremiumSubscription`, grants monthly gems on initial purchase.
- [x] `hasPremium()` in `premium.ts` reads **either** `premiumUntil` OR `activeSubscriptionExpiresAt` (both optional — backward-compatible for legacy callers).
- [x] Apple App Store Server Notifications v2 webhook handler (`/api/iap/apple-notifications`) — processes `DID_RENEW`, `SUBSCRIBED`, `OFFER_REDEEMED`, `DID_FAIL_TO_RENEW` (grace period), `EXPIRED`, `DID_CHANGE_RENEWAL_STATUS`, `REFUND`, `REVOKE`.
- [ ] Apple StoreKit: create subscription group + product (`com.hexbound.premiumpassmonthly`) in App Store Connect.
- [ ] Register webhook URL `https://api.hexboundapp.com/api/iap/apple-notifications` in App Store Connect.
- [ ] Wire caller sites (`pvp/*`, `dungeons/*`, `daily-login/claim`) to pass `activeSubscriptionExpiresAt` from `PremiumSubscription` — otherwise subscription benefits won't apply at runtime. Currently only the legacy `premiumUntil` path is wired. **Blocker for launch.**
- [ ] iOS storefront: new "Premium Pass" card with 7-day free trial introductory offer.
- [ ] Analytics: trial → paid conversion, renewal rate, refund rate.
- [ ] Phase 3 hardening: verify Apple's JWS signature against their cert chain (webhook currently decodes payload-only).

### Phase 3 — optional enhancements

- [ ] Annual tier ($39.99, ~33% discount vs. monthly × 12).
- [ ] Premium Pass-exclusive cosmetic rotation per month.
- [ ] Legacy forever owners get a small gratitude token each month (e.g., extra 100 gems) to reinforce they're still valued.

## Rejected Alternatives

- **Leave Premium Forever priced higher ($29.99+).** Still a one-time sale with no retention lever. Even at $29.99 the break-even is ~2 years of active play — still LTV-negative for engaged users.
- **Nerf Premium Forever benefits.** Bait-and-switch on a product people already bought. Destroys trust.
- **Remove the product entirely including for existing owners.** Refund nightmare, Apple policy risk, toxic to the most loyal ~5% of spenders.

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Backlash from legacy forever owners feeling devalued | Public note: your perk is permanent. Consider small monthly gratitude token in Phase 3. |
| Conversion drop during the gap (Phase 1 ships, Phase 2 not yet live) | Expected. Monitor gem pack sales — should absorb some demand. Ship Phase 2 within ~4 weeks. |
| Apple subscription review rejection | Follow their review checklist; include trial disclosure, restore-purchases, and subscription management link. |
| Server downtime → subscription entitlement gap | Cache last known `expiresAt` on User; 48-hour grace window before revoking benefits. |

## Rollout Checklist (Phase 2)

1. StoreKit configuration in App Store Connect, TestFlight sandbox subscription group.
2. Webhook endpoint deployed + tested with Apple's sandbox notifications.
3. iOS build with Premium Pass UI in internal TestFlight ≥ 72h.
4. Dashboard tracking: daily active subscriptions, trial starts, trial → paid conversion, refund rate.
5. Public announcement thread describing the change and reassuring Premium Forever owners.
