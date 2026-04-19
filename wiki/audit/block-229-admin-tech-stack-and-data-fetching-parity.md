---
title: Audit Block 229 — Admin Tech Stack And Data Fetching Parity
category: audit
tags: [audit, docs, admin, tech-stack, data-fetching]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/package.json
  - admin/src/lib/backend-api.ts
  - admin/src/lib/backend-admin.ts
  - admin/src/components/forms/dynamic-form.tsx
  - admin/src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 229 — Admin Tech Stack And Data Fetching Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/package.json`
- `admin/src/lib/backend-api.ts`
- `admin/src/lib/backend-admin.ts`
- `admin/src/components/forms/dynamic-form.tsx`
- `admin/src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx`

## Why this block

After the page-surface cleanup, the next stale cluster in `ADMIN_CAPABILITIES.md` was the bottom implementation summary:

- it still claimed `Chart.js or Recharts` even though the live repo standard here is `Recharts`
- it implied a repo-wide `React Query` live-data layer and optional websocket metrics surface, but those do not exist in the current admin codebase
- it still described a general `Debounced auto-save (5s)` behavior, which is no longer true as a global admin pattern
- the performance note still sounded like every search surface was explicitly debounced and every flag/config page had a shared caching layer

## Fix applied

### Tech Stack

- updated the frontend stack wording to the actual live setup:
  - `Next.js 15 (React 19)`
  - `TailwindCSS + shadcn/ui + Radix primitives`
  - `Recharts`
  - `Zod` plus typed helpers
  - `react-hook-form` on the dynamic-form surface and selected admin forms

### Backend Integration

- replaced the old simplified description with the live mixed model:
  - server actions
  - same-origin admin API routes
  - backend proxy/helper fetches
- clarified that save behavior is page-specific and there is no repo-wide debounced auto-save contract
- clarified that many edit flows now refresh from the server after mutation instead of leaning on a broad optimistic-update story

### Data Fetching

- rewrote the section around the real current model:
  - SSR for initial load where used
  - server actions and direct `fetch(...)` calls to local/admin/backend proxy routes
  - `no-store` fetches on selected review pages
- explicitly removed the false claims about:
  - repo-wide React Query
  - websocket-driven real-time metrics

### Notes / Performance wording

- narrowed the performance note so it no longer promises universal debounced search or shared feature-flag caching behavior across the dashboard

## Result

The bottom implementation summary in `ADMIN_CAPABILITIES.md` now describes the admin app’s real runtime model instead of an imagined React Query + websocket + debounced-autosave stack that the current repo does not ship.

## Verification

- compared the tech-stack wording against `admin/package.json`
- searched the admin repo for `React Query`, websocket usage, and debounced autosave claims
- verified the live data flow through server actions, local route fetches, and backend proxy helpers
- `git diff --check`

This closes the next stale implementation-summary block in the admin capability doc.
