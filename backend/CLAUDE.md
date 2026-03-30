# Hexbound Backend — TypeScript Rules

> Parent rules: see root `CLAUDE.md` for architecture, enums, tokens, deploy, git, Prisma sync.

## TypeScript & Next.js (CRITICAL)

- **`get*Config()` in `live-config.ts` are async.** Always `await`. Missing `await` = `Promise<number>` instead of `number`.
- **`runCombat()` is async.** Always `await runCombat(attacker, defender)`.
- **`calculateCurrentStamina()` takes 3 args:** `(currentStamina, maxStamina, lastUpdate)`. No 4th arg.
- **`StaminaResult`:** `{ stamina: number; updated: boolean }`. Use `.stamina`, NOT `.current`.
- **`CombatResult` fields:** `{ winnerId, loserId, turns, totalTurns, finalHp }`. No `.log`, `.duration`, `.player1FinalHp`.
- **`gems` on `User`, NOT `Character`.** Gold on Character, gems on User.
- **`Item` is a catalog model** — no `characterId`. Player items are in `EquipmentInventory`.
- **`DailyQuest`:** uses `day` (String "YYYY-MM-DD"), NOT `assignedDate`. Has `completed` but NO `claimed`.
- **`PvpMatch`:** `player1Id`/`player2Id`, NOT `attackerId`/`defenderId`. Field `playedAt`, not `createdAt`.
- **Next.js 15 `params` is `Promise`:** `const { id } = await params`. No direct destructuring.
- **Prisma `Json` double cast:** `as unknown as OfferContent[]`. For `InputJsonValue`: `(val ?? Prisma.JsonNull) as unknown as Prisma.InputJsonValue`.
- **`ignoreBuildErrors` is REMOVED.** TS errors block Vercel deploy. Fix properly.
- **`prisma generate` before `tsc`/`next build`.** Locally: `cd backend && npx prisma generate`.
- **No files with spaces or " 2" in name.** Delete macOS duplicates.
- **Game lib signatures:** `applyLevelUp(prisma, charId)`, `updateDailyQuestProgress(prisma, charId, questType, increment)`, `degradeEquipment(prisma, charId)`, `getKFactor(calibrationGames)` (async). When unsure, copy from `pvp/fight/route.ts`.
- **Character deletion:** PvpMatch FKs have no cascade. Nullify winnerId/loserId, deleteMany matches, THEN delete character.

## Admin Panel

- **Strict null checks:** Narrow `T | null` before use. `if (!x) throw` + assertion.
- **Build before push:** `npx next build` locally or check Vercel preview.

## Economy & Purchase Routes (CRITICAL — TOCTOU)

**All purchase routes MUST validate limits INSIDE a Prisma `$transaction` with `SELECT FOR UPDATE` row lock.**

Bad: check limit → start transaction → execute. Good: start transaction → lock row → check limit → execute.

Pattern: `$transaction(async (tx) => { ... })` with `Serializable` isolation.

Applies to: shop offers, consumables, PvP stamina, minigame bets, any resource limit check.

## Atomic Increments (CRITICAL)

**All counter increments MUST use atomic SQL**, not read-then-write.

Bad: `findFirst` → read progress → `update(progress + 1)` (concurrent calls read same value).
Good: `$executeRawUnsafe('UPDATE ... SET progress = LEAST(progress + $1, target) WHERE ...')`.

Reference: `backend/src/lib/game/daily-quests.ts`.

## N+1 Prevention (CRITICAL)

**Never call DB queries or config lookups inside loops.**

- Config: load all into Map BEFORE loop, use sync lookup inside.
- Records: `findMany({ where: { id: { in: ids } } })` + Map, NOT `Promise.all(ids.map(findUnique))`.

## Rate Limiting (CRITICAL)

**All unauthenticated GET routes MUST have IP-based rate limiting.**

Pattern: `const ip = req.headers.get('x-forwarded-for')?.split(',')[0] || 'unknown'; await rateLimit('route:' + ip, limit, windowMs);`

Limits: leaderboard 30/min, search 20/min, profile 60/min. Utility: `src/lib/rate-limit.ts`.

## Minigame Daily Limits (CRITICAL)

**All minigames MUST have server-enforced daily limits.** Client-only limits are bypassable.

Count via `prisma.minigameSession.count({ where: { characterId, gameType, createdAt: { gte: todayStart } } })`.

Shell Game 20/day, Fortune Wheel 10/day, Gold Mine per slot schedule.

## API Error Handling (CRITICAL)

**Every route handler MUST wrap body in try/catch.** Unhandled errors expose stack traces.

Pattern: `try { ... } catch (error) { console.error('context:', error); return NextResponse.json({message: 'Internal error'}, {status: 500}); }`

Log: error message, stacktrace, request context. **Never log:** email, password, tokens, API keys, PII.

## Prisma Migrate Resolve Gotcha

`prisma migrate resolve --applied` marks migration as done **WITHOUT executing SQL**. Only use when SQL was already applied manually.

After any migration, verify tables exist:
```sql
SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'characters';
```

## Dead Code Cleanup

After large refactors:
1. Grep for imports of old names across entire codebase
2. Delete files + remove references
3. Verify build succeeds
