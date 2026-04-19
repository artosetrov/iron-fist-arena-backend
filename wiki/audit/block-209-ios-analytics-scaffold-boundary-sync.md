---
title: Audit Block 209 — iOS Analytics Scaffold Boundary Sync
category: audit
tags: [audit, ios, analytics, docs, boundary]
sources:
  - Hexbound/Hexbound/Services/AnalyticsService.swift
  - docs/retro/RETRO_2026-04-18.md
updated: 2026-04-19
status: Fixed
---

# Audit Block 209 — iOS Analytics Scaffold Boundary Sync

## Scope

- `Hexbound/Hexbound/Services/AnalyticsService.swift`
- `docs/retro/RETRO_2026-04-18.md`

## Why this block

The repo had one more analytics truth gap:

- `AnalyticsService.swift` exists as a provider-agnostic iOS mirror
- but there are currently no live call-sites using it

That meant some wording still read as if client analytics were already wired end to end, when in practice the live project still relies on:

- server-side provider-agnostic analytics events
- tutorial structured JSON funnel logs

## Fix applied

### `Hexbound/Hexbound/Services/AnalyticsService.swift`

- clarified in the header comment that the service is currently a dormant scaffold
- noted that it is ready for future client-side emitters but not yet wired into live flows

### `docs/retro/RETRO_2026-04-18.md`

- tightened the analytics note so it no longer implies that iOS analytics hooks are already active everywhere
- now describes the Swift layer as a mirrored scaffold rather than a fully wired runtime surface

## Result

The analytics story is now honest across code and docs:

- backend/tutorial analytics are the live source today
- iOS has a typed scaffold ready for future use
- the repo no longer overstates current client-side instrumentation

## Verification

- `rg -n "AnalyticsService\\.shared|setBackend\\(|track\\(" Hexbound/Hexbound -g '*.swift'`
- `git diff --check`

The search confirms the service is currently unwired outside its own file, and the docs now say so explicitly.
