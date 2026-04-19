---
title: Audit Block 213 — Backend Analytics Scaffold Boundary Sync
category: audit
tags: [audit, backend, analytics, docs, boundary]
sources:
  - backend/src/lib/analytics.ts
  - docs/retro/RETRO_2026-04-18.md
  - backend/src/lib/game/tutorial-analytics.ts
updated: 2026-04-19
status: Fixed
---

# Audit Block 213 — Backend Analytics Scaffold Boundary Sync

## Scope

- `backend/src/lib/analytics.ts`
- `docs/retro/RETRO_2026-04-18.md`
- `backend/src/lib/game/tutorial-analytics.ts`

## Why this block

One more analytics truth gap remained after the recent cleanup:

- `backend/src/lib/analytics.ts` defines a typed provider-agnostic event contract
- but the repo currently has no live `track(...)` call-sites outside that file itself

That means the active instrumentation story today is narrower:

- tutorial structured JSON funnel logs are live
- the generic backend analytics contract is still scaffold/foundation, not an actively emitting runtime surface yet

## Fix applied

### `backend/src/lib/analytics.ts`

- clarified in the header comment that the generic analytics layer is currently a dormant scaffold with no live emitters wired yet

### `docs/retro/RETRO_2026-04-18.md`

- tightened the retrospective wording so “7 critical-funnel events instrumented” no longer overstates the current repo reality
- now distinguishes the generic typed scaffold from the live tutorial log path

## Result

The backend analytics story is now honest across code and docs:

- `tutorial-analytics.ts` is the live event path today
- `analytics.ts` is the typed scaffold for future generic instrumentation

## Verification

- `rg -n "\\btrack\\(" backend/src -g '*.ts'`
- `git diff --check`

The search shows no live backend `track(...)` call-sites outside `analytics.ts`, and the docs now say so explicitly.
