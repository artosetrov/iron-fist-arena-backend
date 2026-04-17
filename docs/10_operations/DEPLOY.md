# Hexbound — Deploy Guide

*Source of truth: this file + Vercel dashboard + live repo config (`.github/workflows/ci.yml`, `backend/next.config.ts`, `admin/vercel.json`). Updated: 2026-04-16*

---

## Overview

| Service | Platform | Trigger | URL |
|---------|----------|---------|-----|
| Backend API | Vercel | Push to `origin/main` | `api.hexboundapp.com` |
| Admin Panel | Vercel | Manual `git subtree push --prefix=admin admin-deploy main` | Vercel project URL |
| Landing Site | Vercel (manual) | Push to `artosetrov/hexbound-landing` `main` | `hexboundapp.com` |
| iOS App | TestFlight | `fastlane beta` (manual) | TestFlight |

## Backend Deploy

**Automatic on push to `origin/main`.**

```
git push origin main
  → Vercel detects push
  → Runs: npm install → prisma generate → next build
  → Deploys to production
```

**Vercel project**: `hexbound-backend` (`prj_XbOGDTioVSx9uCibkGq3JI92sVJS`)

**Build command** (from `backend/package.json`):
```
prisma generate && next build
```

**Environment variables** (set in Vercel Dashboard):
- `DATABASE_URL` — Supabase Postgres (pooled, port 6543)
- `DIRECT_URL` — Supabase Postgres (direct, port 5432)
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_JWT_SECRET`
- `CORS_ORIGINS`
- `NEXT_PUBLIC_APP_URL`

### Preview Deploys

Every push to any branch creates a Vercel preview URL. Use for testing before merge to main.

### Validation Gates

GitHub Actions now runs `.github/workflows/ci.yml` on `push` and `pull_request` for `main`-relevant changes:

- `Backend Build & Test` — `npm ci`, `prisma generate`, `vitest`, `docs:balance:check`, `next build`
- `Admin Build` — `npm ci`, `prisma generate`, `next build`
- `Prisma Schema & Migration Drift Check` — backend/admin schema diff + `scripts/check_schema_drift.py`

This does **not** replace Vercel deploys, but it does catch build/test/schema regressions before or alongside production pushes.

## Admin Deploy

**NOT automatic.** Requires manual subtree push.

```bash
# Step 1: Push monorepo
git push origin main

# Step 2: Push admin subtree (REQUIRED for admin to update)
git subtree push --prefix=admin admin-deploy main
```

**Vercel project**: `admin` (`prj_BiMipu3CdZ5topnENQxd9H2svcOc`)

**Build command** (from `admin/vercel.json`):
```
prisma generate && next build
```

**Environment variables** (set in Vercel Dashboard):
- `DATABASE_URL`, `DIRECT_URL` — same Supabase DB as backend
- `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `NEXT_PUBLIC_API_URL` — backend API URL

### Preview Deploys

Admin preview deploys are tied to the `admin-deploy` repo, not to monorepo pushes on `origin`. If you only push `origin/main`, backend updates but admin does not.

## Database Migrations

See `docs/10_operations/DATABASE_MIGRATIONS.md` for full guide.

**Quick version:**
```bash
# Create migration locally
cd backend && npm run db:migrate:dev -- --name add_feature_x

# Copy schema to admin
cp backend/prisma/schema.prisma admin/prisma/schema.prisma

# Deploy migration to production explicitly:
cd backend && npm run db:migrate:deploy
```

`next build` does **not** run `prisma migrate deploy` automatically. Treat migration apply as a separate production step.

## iOS Deploy

See `docs/10_operations/RELEASE_IOS.md` for full guide.

## Rollback

### Backend/Admin (Vercel)
1. Go to Vercel Dashboard → Deployments
2. Find last working deployment
3. Click "..." → "Promote to Production"

### Database
- Prisma migrations are forward-only
- For emergency rollback: write a new migration that reverts the change
- Never use `prisma migrate reset` on production

### iOS
- TestFlight: remove build from testing group
- App Store: use Vercel-style rollback (submit previous version)

## Common Mistakes

| Mistake | Impact | Fix |
|---------|--------|-----|
| Forgot admin subtree push | Admin panel stays on old version | `git subtree push --prefix=admin admin-deploy main` |
| Forgot backend/admin schema sync | CI drift check fails; admin Prisma can lag behind backend | Copy backend → admin schema before commit |
| Pushed without testing | Broken production | Vercel instant rollback |
| Assumed Vercel build applies migrations | New code references missing columns | Run `cd backend && npm run db:migrate:deploy` explicitly |
