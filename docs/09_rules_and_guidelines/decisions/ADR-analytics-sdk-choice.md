---
title: ADR — Analytics SDK choice
status: Proposed
date: 2026-04-19
owner: Audit 2026-04-17 (P4.16)
supersedes: —
---

# ADR — Analytics SDK choice

## Context

Audit 2026-04-17 flagged **zero analytics instrumentation** as the single
🔴-priority gap. Phase 4.17 + 4.18 shipped a provider-agnostic event schema
and 7 server-side call-sites:

| Event | Emitter |
|---|---|
| `signup` | `POST /api/auth/register` |
| `first_pvp` | `POST /api/pvp/match/complete` (first match) |
| `iap_purchase` | `POST /api/iap/verify-receipt` |
| `bp_claim` | `POST /api/battle-pass/claim/[level]` |
| `daily_login` | `POST /api/daily-login/claim` |
| `level_up` | `lib/game/progression.ts#applyLevelUp` |
| `shop_upgrade` | `POST /api/shop/upgrade` |

Current backend is `NoopBackend` (stdout when `ANALYTICS_DEBUG=true`, silent
otherwise). Instrumentation is ready; only the sink decision is outstanding.

## Decision

**Firebase Analytics** as the primary sink, with **BigQuery export** enabled
for ad-hoc funnel / cohort queries.

## Why Firebase (over Mixpanel / Amplitude / Segment)

| Criterion | Firebase | Mixpanel | Amplitude | Segment |
|---|---|---|---|---|
| Cost at our scale (<10k DAU) | **Free tier sufficient** | $28/mo+ free tier | Free for 10M events | Free tier w/ cap |
| Mobile-first SDK | **iOS / Android native** | Good, less optimised | Good | Router only — needs sink |
| Cohort + funnel UI | Good (GA4 interface) | **Best-in-class** | Best-in-class | — |
| Raw-event export | **BigQuery (free daily)** | CSV (paid) | S3 (paid) | Via sink (paid) |
| GDPR tooling | Consent mode v2 native | Manual | Manual | Via sink |
| Remote-config piggyback | **Yes, built-in** | No | No | No |
| Crashlytics piggyback | **Yes, same SDK** | No | No | No |
| Push piggyback | **FCM, same project** | No | No | No |
| Team learning curve | Low (common baseline) | Medium | Medium | High |

**Tie-breakers:**
1. **BigQuery export** is the unlock: Mixpanel/Amplitude funnels are polished,
   but when a designer asks "what's the retention curve for players who
   buy adventurer bundle II vs III?" we need raw SQL. Firebase → BigQuery
   on free tier gives us that.
2. **Single SDK for Analytics + Crashlytics + Remote Config + FCM.** We
   already plan to need all four; adopting Firebase now avoids 4 SDKs fighting
   over app startup time and privacy manifests.
3. **Cost**. Firebase stays free indefinitely at our scale. Mixpanel's free
   tier tops out at 1k MTUs; we'd cross it in a soft-launch week.

## What we give up

- **Mixpanel's funnel UI** is unmatched for non-technical designers. We
  mitigate by publishing Looker Studio dashboards backed by the BigQuery
  export (free, already integrated with Firebase).
- **Event-property cardinality** — Firebase caps custom properties at 500
  per event registration. We're well under that (7 events × ~5 props each).
  Worth revisiting at 100k+ DAU.

## Integration plan

Wiring is ~30 minutes of work once the SDK choice is locked:

### Backend

1. `npm i @google-cloud/firestore` — no, wrong package. Backend sink uses
   Firebase Admin SDK (`firebase-admin`) or Google Analytics Measurement
   Protocol (`fetch`-based, zero deps, recommended).
2. Create `backend/src/lib/analytics-firebase.ts` implementing
   `AnalyticsBackend`:
   ```ts
   import { AnalyticsBackend, AnalyticsEvent } from './analytics'
   export class FirebaseAnalyticsBackend implements AnalyticsBackend {
     constructor(private measurementId: string, private apiSecret: string) {}
     async track(event: AnalyticsEvent) {
       await fetch(
         `https://www.google-analytics.com/mp/collect?measurement_id=${this.measurementId}&api_secret=${this.apiSecret}`,
         {
           method: 'POST',
           body: JSON.stringify({
             client_id: (event as { userId?: string }).userId ?? 'server',
             events: [{ name: event.name, params: event }],
           }),
         },
       )
     }
   }
   ```
3. Wire in `instrumentation.ts` (Next.js bootstrap):
   ```ts
   import { setAnalyticsBackend } from '@/lib/analytics'
   import { FirebaseAnalyticsBackend } from '@/lib/analytics-firebase'
   if (process.env.FIREBASE_MEASUREMENT_ID && process.env.FIREBASE_API_SECRET) {
     setAnalyticsBackend(new FirebaseAnalyticsBackend(
       process.env.FIREBASE_MEASUREMENT_ID,
       process.env.FIREBASE_API_SECRET,
     ))
   }
   ```
4. Add env vars to Vercel: `FIREBASE_MEASUREMENT_ID`, `FIREBASE_API_SECRET`.

### iOS

1. Add `firebase-ios-sdk` via SPM: `FirebaseCore` + `FirebaseAnalytics`.
2. `HexboundApp.swift`:
   ```swift
   import FirebaseCore
   import FirebaseAnalytics

   @main
   struct HexboundApp: App {
     init() { FirebaseApp.configure() }
     // ...
   }
   ```
3. `Services/AnalyticsService.swift`: add `FirebaseAnalyticsBackend`
   conforming to `AnalyticsBackend`, wire via
   `AnalyticsService.shared.setBackend(FirebaseAnalyticsBackend())` at boot.
4. Add `GoogleService-Info.plist` (gitignored; fetched from Firebase console).

### Dashboards (P4.19)

1. Enable BigQuery export in Firebase console (1 click, free).
2. Publish Looker Studio templates backed by `project.analytics_XYZ.events_*`
   tables:
   - **Acquisition funnel**: install → first_open → signup → first_pvp
   - **Monetization funnel**: first_open → first_pvp → first IAP
   - **Retention cohorts**: by signup week, W1/W4/W12 return
   - **Economy health**: gems earned vs spent, per-cohort
3. Pin to `/dashboard` in admin panel via iframe (auth gated by
   `requireAdmin()`).

## Rollback

If Firebase proves insufficient, the `setAnalyticsBackend()` indirection
lets us swap to Mixpanel / Segment / Amplitude by replacing one file. All
call-sites stay untouched. Cost of migration: ~2 hours of backend work.

## References

- `backend/src/lib/analytics.ts` — event contract (single source)
- `Hexbound/Hexbound/Services/AnalyticsService.swift` — iOS mirror
- Audit 2026-04-17, Zone 10 (Analytics + LiveOps) 🔴
