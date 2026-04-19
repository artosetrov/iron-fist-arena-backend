---
title: Audit Block 206 — iOS Analytics Auth Provider Enum Parity
category: audit
tags: [audit, ios, analytics, auth, typing]
sources:
  - Hexbound/Hexbound/Services/AnalyticsService.swift
  - backend/src/lib/analytics.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 206 — iOS Analytics Auth Provider Enum Parity

## Scope

- `Hexbound/Hexbound/Services/AnalyticsService.swift`
- `backend/src/lib/analytics.ts`

## Why this block

The backend analytics contract already narrows `authProvider` to a fixed set:

- `email`
- `guest`
- `google`
- `apple`

But the iOS mirror still modeled the same field as a raw `String`.

That left a quiet type seam where the client-side analytics bridge could drift away from the backend contract without Swift noticing.

## Fix applied

### `Hexbound/Hexbound/Services/AnalyticsService.swift`

- added a dedicated `AnalyticsAuthProvider` enum
- changed `AnalyticsEvent.signup` from `authProvider: String` to `authProvider: AnalyticsAuthProvider`
- serialized the event back out through `authProvider.rawValue`

## Result

The iOS analytics mirror now matches the backend contract more closely:

- allowed auth providers are explicit in Swift
- typo-driven drift is blocked at compile time
- the wire payload stays unchanged because the enum still serializes to the same lowercase strings

## Verification

- compared the live Swift contract against `backend/src/lib/analytics.ts`
- `git diff --check`

The change narrows typing only; payload shape remains the same.
