---
title: Audit Block 249 — Schema Reference Count Parity
category: audit
tags: [audit, docs, database, prisma, metadata]
sources:
  - docs/04_database/SCHEMA_REFERENCE.md
  - backend/prisma/schema.prisma
updated: 2026-04-20
status: Fixed
---

# Audit Block 249 — Schema Reference Count Parity

## Scope

- `docs/04_database/SCHEMA_REFERENCE.md`
- `backend/prisma/schema.prisma`

## Why this block

`SCHEMA_REFERENCE.md` is meant to be derived from the live Prisma schema, but its header summary had drifted:

- models: correct
- enums: correct
- field count: stale (`830`)

The current schema now contains `839` model fields.

## Fix applied

- updated the schema-reference header to the live verified counts:
  - `65 models`
  - `19 enums`
  - `839 fields`
- refreshed the verification date to `2026-04-20`

## Result

The schema reference header once again matches the actual Prisma schema instead of undercounting the live field surface.

## Verification

- direct count pass over `backend/prisma/schema.prisma`
- `git diff --check`
