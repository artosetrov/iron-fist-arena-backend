# Cross-System Integration Review

> Trigger: "cross-system check", "проверь интеграцию", "integration review", or when feature touches 3+ systems.

## Purpose
Ensure a feature works correctly across all project systems without breaking adjacent functionality.

## Systems Map
1. **iOS Frontend** — Views, ViewModels, Models, Services, Navigation
2. **Backend API** — Routes, Game Logic, Prisma, Auth, Middleware
3. **Admin Panel** — Pages, Config, Moderation, Analytics
4. **Database** — Schema, Migrations, Indexes, Constraints
5. **Game Systems** — Combat, Economy, Progression, Rewards, Balance
6. **Documentation** — CLAUDE.md, docs/, skills/
7. **Deploy** — Vercel (backend + admin), Xcode/TestFlight (iOS)

## Workflow

### Step 1 — Impact Map
For the feature, mark affected systems:
```
[ ] iOS Frontend — [specific views/models]
[ ] Backend API — [specific routes/services]
[ ] Admin Panel — [specific pages/config]
[ ] Database — [schema changes]
[ ] Game Systems — [balance/economy/combat]
[ ] Documentation — [which docs]
[ ] Deploy — [migration/config changes]
```

### Step 2 — Contract Verification
For each system boundary crossed:
- Frontend ↔ Backend: API contract matches
- Backend ↔ Database: Prisma schema matches DB
- Backend ↔ Admin: Schema synced, config params accessible
- Game logic ↔ Client: Server-authoritative, client display-only

### Step 3 — Regression Check
List adjacent features that COULD break:
- Does changing this model affect other screens using it?
- Does this migration require data backfill?
- Does this config change affect live users?

### Step 4 — Dependency Order
Define correct execution order:
1. Database migration first
2. Backend deploy
3. Admin deploy (if schema changed)
4. iOS update (client-side)

## Output
```
FEATURE: [name]
SYSTEMS AFFECTED: [list]
CONTRACTS: [all match / mismatches found]
REGRESSION RISKS: [list]
DEPLOY ORDER: [sequence]
BLOCKERS: [if any]
```
