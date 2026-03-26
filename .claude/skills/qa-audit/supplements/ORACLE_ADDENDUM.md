# Oracle Agent — QA Audit Addendum (2026-03-25)

These findings should be checked by the Oracle agent during backend reviews, in addition to its standard checklist.

## New Check: Security & Rate Limiting

- **Auth routes MUST have rate limiting.** Login and registration endpoints need 5 attempts/min per IP+email. Flag any auth route without rate limiting middleware.
- **Every API route MUST have try/catch.** Unhandled errors return raw 500 with stack traces. 95%+ routes have this, but check new routes.
- **No PII in logs.** Grep for `console.log.*email`, `console.log.*password`, `console.log.*token`. Flag any match.
- **Daily login timing check.** If reviewing daily-login route: verify it uses 24h cooldown (lastClaimAt + 86400s), NOT calendar-day check. Calendar-day check = CRITICAL exploit (BUG-001).
- **IAP validation.** If reviewing StoreKit/purchase routes: flag if validation is client-side only. Server-side receipt validation with Apple SSAPI v2 is required before public release.

## New Check: N+1 Query Prevention

- **Never call DB queries or config lookups inside loops.** Load all config into a Map before the loop.
- **Pattern:** `findMany({ where: { id: { in: ids } } })` + Map lookup, NOT `Promise.all(map(id => findUnique(id)))`.
- **Known past incidents:** `shop/items/route.ts` (160ms overhead), `social/messages/route.ts` (N+1 on character lookups).

## Known Open Issues (track status)

| ID | Severity | Issue | Status |
|---|---|---|---|
| BUG-003 | CRITICAL | Auth routes missing rate limiting | OPEN |
| BUG-008 | HIGH | 0% automated test coverage | OPEN |
| BUG-006 | HIGH | PvpMatch missing createdAt | OPEN |
| BUG-007 | HIGH | 14 models missing timestamps | OPEN |
| BUG-013 | MEDIUM | IAP receipt validation client-side only | OPEN |
