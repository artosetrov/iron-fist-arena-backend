# Prisma migration workflow

## Why this exists

This project already had a live Supabase schema, but `_prisma_migrations` was never created.
That meant Prisma saw a large drift: the database already contained almost the full schema,
while the repository only had a few small delta migrations.

To fix that safely:

- `20260306_baseline` now captures the existing live schema
- `20260312_add_pvp_battle_tickets` stays as the first real post-baseline delta

## Fresh database

For a brand-new environment, use Prisma Migrate only:

```bash
npm run db:migrate:deploy
npm run db:seed
```

Do not use `db:push` for shared, staging, or production databases.

Important: `npm run db:seed` currently runs only `prisma/seed.ts`, which seeds
the core item catalog and PvP bot roster. Feature-specific bootstrap data still
requires explicit follow-up steps.

Common follow-up seeds after a fresh bootstrap:

```bash
npx tsx prisma/seed-balance.ts
npx tsx prisma/seed-dungeons.ts
npx tsx prisma/seed-dungeon-drops.ts
npx tsx prisma/seed-battle-pass.ts
```

Passive tree SQL is also separate on purpose because it is destructive reset
logic, not a casual idempotent seed:

```bash
psql "$DATABASE_URL" -f prisma/seeds/passive-tree.sql
psql "$DATABASE_URL" -f prisma/seeds/passive-tree-activatable.sql
```

Run only the feature seeds your environment actually needs.

## Existing database without `_prisma_migrations`

If the database already has the game tables but Prisma history is missing:

```bash
npm run db:migrate:status
npm run db:migrate:adopt
npm run db:migrate:deploy
```

What this does:

- `db:migrate:adopt` records `20260306_baseline` as already applied
- `db:migrate:deploy` then applies only migrations that are truly missing, starting with `20260312_add_pvp_battle_tickets`

## Rule going forward

- Create schema changes with `npm run db:migrate:dev`
- Deploy schema changes with `npm run db:migrate:deploy`
- Keep `schema.prisma` and `prisma/migrations` in sync at all times
- Reserve `db:push` for disposable local experiments only

## Shared cache and rate limits

For production-safe cache invalidation and cross-instance rate limiting, configure:

```bash
UPSTASH_REDIS_REST_URL=...
UPSTASH_REDIS_REST_TOKEN=...
```

Without these variables the backend falls back to per-instance memory and logs a production warning.

## Legacy battle pass reward repair

If an existing database still contains old premium milestone rows with broken battle pass reward config,
repair them with:

```bash
npm run db:fix:battle-pass-rewards
```
