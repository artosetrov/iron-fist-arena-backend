# Hexbound — Deploy Guide

*Source of truth: this file + Vercel dashboard + vercel.json configs. Updated: 2026-03-19*

---

## Overview

| Service | Platform | Trigger | URL |
|---------|----------|---------|-----|
| Backend API | Vercel | Push to `origin/main` | `api.hexboundapp.com` |
| Admin Panel | Vercel | Push to `admin-deploy/main` | Vercel project URL |
| Landing Site | Vercel (manual) | Manual deploy | TBD |
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

**⚠️ Known issue**: `ignoreBuildErrors: true` in `backend/next.config.ts`. TypeScript errors are not caught at build time. Track in tech debt.

### Preview Deploys

Every push to any branch creates a Vercel preview URL. Use for testing before merge to main.

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

## Database Migrations

See `docs/10_operations/DATABASE_MIGRATIONS.md` for full guide.

**Quick version:**
```bash
# Create migration locally
cd backend && npm run db:migrate:dev -- --name add_feature_x

# Copy schema to admin
cp backend/prisma/schema.prisma admin/prisma/schema.prisma

# Deploy migration to production (runs on next Vercel build, or manually):
cd backend && npm run db:migrate:deploy
```

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
| Prisma schema drift | Admin crashes on missing fields | Copy backend → admin schema |
| Pushed without testing | Broken production | Vercel instant rollback |
| Migration not applied | New code references missing columns | `npm run db:migrate:deploy` |
