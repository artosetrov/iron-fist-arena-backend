# Hexbound — Database Migrations

*Source of truth: this file + `backend/prisma/`. Updated: 2026-03-19*

---

## Overview

- **ORM**: Prisma
- **DB**: Supabase PostgreSQL
- **Schema source of truth**: `backend/prisma/schema.prisma`
- **Migrations**: `backend/prisma/migrations/`
- **Admin schema**: must be identical copy of backend schema

## Current Migrations

| Migration | Date | Purpose |
|-----------|------|---------|
| `20260306_baseline` | 2026-03-06 | Initial schema (40+ models) |
| `20260312_add_pvp_battle_tickets` | 2026-03-12 | PvP battle authorization tickets |
| `20260316_add_daily_gem_card` | 2026-03-16 | Daily gem card subscription |

## Creating a New Migration

```bash
# 1. Edit backend/prisma/schema.prisma

# 2. Generate migration
cd backend
npm run db:migrate:dev -- --name add_feature_name

# 3. Sync admin schema (CRITICAL — do not skip)
cp backend/prisma/schema.prisma admin/prisma/schema.prisma

# 4. Test locally
npm run dev  # verify backend works
cd ../admin && npm run dev  # verify admin works

# 5. Commit all three files
git add backend/prisma/schema.prisma backend/prisma/migrations/ admin/prisma/schema.prisma
git commit -m "db: add feature_name migration"
```

## Applying Migrations to Production

```bash
# Option A: Automatic (via Vercel build)
# If using `prisma migrate deploy` in build command, migrations apply on deploy.
# Currently NOT configured — see "Recommended Setup" below.

# Option B: Manual
cd backend
DATABASE_URL="production_connection_string" npm run db:migrate:deploy
```

## Recommended Setup

Add migration deploy to Vercel build command for backend:

**Current** (in backend/package.json):
```
"build": "prisma generate && next build"
```

**Recommended**:
```
"build": "prisma generate && prisma migrate deploy && next build"
```

⚠️ This is safe because `prisma migrate deploy` only applies pending migrations, never creates new ones, and never resets data.

## Commands Reference

| Command | Purpose | Safe for production? |
|---------|---------|---------------------|
| `npm run db:migrate:dev` | Create new migration | ❌ Local only |
| `npm run db:migrate:deploy` | Apply pending migrations | ✅ Yes |
| `npm run db:push` | Push schema without migration | ❌ Local only |
| `npm run db:generate` | Regenerate Prisma client | ✅ Yes |
| `npm run db:studio` | Open Prisma Studio GUI | ❌ Local only |
| `npm run db:seed` | Seed initial data | ❌ Local only |

## Schema Sync Rule

**Backend schema is the single source of truth.**

After ANY schema change:
1. Edit `backend/prisma/schema.prisma`
2. Run migration in backend
3. Copy schema to `admin/prisma/schema.prisma`
4. Commit both

CI check (`prisma-schema-sync` job) will fail if schemas are different.

## Common Mistakes

| Mistake | Impact | Fix |
|---------|--------|-----|
| Edit admin schema directly | Schemas diverge, admin crashes | Always edit backend first, copy to admin |
| `db push` on production | Schema changes without migration history | Never use `db push` on production |
| Forget to copy schema to admin | Admin build fails on deploy | `cp backend/prisma/schema.prisma admin/prisma/schema.prisma` |
| Migration not applied before deploy | New code references missing columns | Add `prisma migrate deploy` to build |

## Rollback

Prisma migrations are **forward-only**. To undo:

1. Write a new migration that reverts the change
2. `npm run db:migrate:dev -- --name revert_feature_name`
3. Apply to production: `npm run db:migrate:deploy`

Never use `prisma migrate reset` on production — it drops all data.
