---
title: Audit Block 223 — Admin Arena Dungeons Assets Surface Parity
category: audit
tags: [audit, docs, admin, pvp, dungeons, assets]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/app/(dashboard)/matches/page.tsx
  - admin/src/app/(dashboard)/dungeons/dungeons-client.tsx
  - admin/src/app/(dashboard)/dungeons/[id]/dungeon-editor.tsx
  - admin/src/app/(dashboard)/assets/assets-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 223 — Admin Arena Dungeons Assets Surface Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/app/(dashboard)/matches/page.tsx`
- `admin/src/app/(dashboard)/dungeons/dungeons-client.tsx`
- `admin/src/app/(dashboard)/dungeons/[id]/dungeon-editor.tsx`
- `admin/src/app/(dashboard)/assets/assets-client.tsx`

## Why this block

The next stale capability cluster in `ADMIN_CAPABILITIES.md` was still describing a broader GM/content toolkit than the live admin actually ships:

- Arena still sounded like a fraud-ops browser with filters, anomaly detection, and invalidation
- Dungeons still sounded like a template-based balancing planner with completion forecasts
- Assets still sounded like a richer DAM pipeline with tags, usage tracking, and guarded deletes

## Fix applied

### Arena Matches

- rewrote the section around the live `/matches` page:
  - total matches
  - matches today
  - revenge matches
  - last-100 history table
  - player links
  - type/result/rating delta/reward/turn/date columns
- removed:
  - advanced filters
  - battle-log expansion
  - anomaly detection
  - invalidate/refund flow

### Dungeons

- rewrote the section around the actual list + editor split:
  - search/create/delete on the dungeon list
  - summary columns on the list
  - full editor fields for general config, images, bosses, waves, and drops
- removed:
  - completion-rate forecasting
  - recommended stats
  - clear-time estimates
  - template saving

### Assets

- rewrote the asset section around the live bucket/path browser:
  - browse
  - upload
  - preview image files
  - resolve/copy public URL
  - delete file
- removed:
  - sprite generation
  - tag/search metadata
  - usage tracking
  - delete-only-if-unused enforcement

## Result

The next PvP/content-ops/media slice in `ADMIN_CAPABILITIES.md` now matches the real admin dashboard much more closely instead of promising a broader liveops toolkit than the repo currently ships.

## Verification

- compared the docs against the live matches page, dungeons list/editor, and asset browser
- `git diff --check`

This closes the next stale capability block inside `ADMIN_CAPABILITIES.md`.
