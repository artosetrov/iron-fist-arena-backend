# Инспектор (Full Game QA Audit)

Полный QA-аудит всех систем Hexbound: backend, iOS client, экономика, база данных, безопасность.
Генерирует .docx отчёт с 8 секциями.

## Триггеры

- "full QA", "полный аудит", "QA audit", "инспектор", "game audit"
- "готов ли к релизу?", "release readiness", "проверь всё"
- Перед каждым мажорным релизом или TestFlight билдом

## Протокол работы

### Phase 0 — Подготовка
1. Прочитай `CLAUDE.md` полностью (правила проекта)
2. Прочитай `docs/06_game_systems/BALANCE_CONSTANTS.md` (баланс)
3. Прочитай `docs/03_backend_and_api/API_REFERENCE.md` (API)
4. Прочитай `docs/04_database/SCHEMA_REFERENCE.md` (БД)

### Phase 1 — System Map
Составь полную карту систем:
- Подсчитай: API routes (`find backend/src/app/api -name "route.ts" | wc -l`)
- Подсчитай: Swift views (`find Hexbound/Hexbound/Views -name "*.swift" | wc -l`)
- Подсчитай: ViewModels (`find Hexbound/Hexbound/ViewModels -name "*.swift" | wc -l`)
- Подсчитай: Models (`find Hexbound/Hexbound/Models -name "*.swift" | wc -l`)
- Подсчитай: Prisma models (`grep "^model " backend/prisma/schema.prisma | wc -l`)
- Подсчитай: Test files (`find backend/src -name "*.test.*" -o -name "*.spec.*" | wc -l`)
- Составь таблицу по системам: PvP, Dungeons, Shop, Inventory, BattlePass, DailyQuests, Achievements, GoldMine, ShellGame, Social, Auth, Leaderboards, DailyLogin

### Phase 2 — Запусти 4 параллельных агента

**Agent 1: Backend Audit**
- Для каждого route handler: проверь try/catch, auth guard, input validation, rate limiting
- Проверь transaction safety на economy routes (Serializable + FOR UPDATE)
- Проверь combat: серверный PRNG, детерминизм, no client influence
- Проверь await на async functions (getConfig, runCombat, calculateCurrentStamina)
- Проверь PII в логах

**Agent 2: iOS Client Audit**
- Для каждого ViewModel: @MainActor, @Observable, error handling
- Force unwraps: `grep -rn '!' Hexbound/Hexbound/ --include="*.swift"` — фильтруй осмысленные
- Design system compliance: нет hardcoded Color(), используются DarkFantasyTheme tokens
- Cache TTL: все GameDataCache entries имеют TTL
- Optimistic UI: все mutating actions обновляют UI до ответа API

**Agent 3: Economy Audit**
- Посчитай daily gold income (все источники) vs daily gold sinks
- Проверь passive vs active income ratio (Gold Mine vs PvP/Dungeons)
- Проверь exploit vectors: daily login timing, concurrent claims, TOCTOU
- Проверь IAP validation (client-side vs server-side)
- Проверь shell game RTP и server-authoritative

**Agent 4: Database Audit**
- Schema sync: `diff backend/prisma/schema.prisma admin/prisma/schema.prisma`
- Missing indexes: check frequently queried fields
- Missing timestamps: models without createdAt/updatedAt
- Migration integrity: `prisma migrate status`
- Merge conflict markers: grep across all files

### Phase 3 — Собери результаты и оцени

Для каждой системы выставь score 0-100:
- Backend API: error handling (30%), security (30%), transaction safety (20%), code quality (20%)
- iOS Client: @MainActor compliance (20%), design system (20%), error handling (20%), cache (20%), UX (20%)
- Economy: exploit resistance (30%), balance (30%), monetization fairness (20%), sink/source ratio (20%)
- Database: schema sync (25%), indexes (25%), timestamps (25%), migration health (25%)

### Phase 4 — Сгенерируй .docx отчёт

Используй docx skill. Отчёт включает 8 секций:
1. Executive Summary (scores, verdict)
2. System Map (полная карта)
3. Bug Report (таблица: ID, Severity, System, Title, Description, Fix)
4. Exploit Report (найденные + уже закрытые vectors)
5. Balance Report (currency flow, known issues)
6. Master Test Matrix (key scenarios + PASS/FAIL)
7. Recommendations (prioritized: Before Release / Before Scale / Ongoing)
8. Appendix (methodology, tools, files audited)

### Phase 5 — Release Readiness Verdict

Один из:
- **GO** — готов к публичному релизу
- **CONDITIONAL GO** — готов к бете с N critical fixes
- **NO GO** — не готов, список блокеров

## Baseline Scores (March 25, 2026)

Для сравнения с предыдущим аудитом:
| System | Score | Key Issues |
|--------|-------|------------|
| Backend API | 87/100 | Auth rate limiting missing, 0% test coverage |
| iOS Client | 82/100 | 5 force unwraps, StoreKit errors not surfaced |
| Economy | 76/100 | Daily login exploit, gold mine dominance |
| Database | 84/100 | PvpMatch missing createdAt, 14 models no timestamps |
| **OVERALL** | **82/100** | **CONDITIONAL GO** |

## Known Issues Registry

Track these across audits:
- BUG-001: Daily login calendar-day exploit (CRITICAL) — FIXED 2026-03-25 (switched to 20h cooldown)
- BUG-002: 6 force unwraps in animation views (CRITICAL) — FIXED 2026-03-25 (replaced with ?? fallback)
- BUG-003: Auth routes missing rate limiting (CRITICAL) — FIXED 2026-03-25 (added to google/apple OAuth routes)
- BUG-004: GoogleSignInHelper missing error handling (HIGH)
- BUG-005: StoreKit purchase error not surfaced (HIGH)
- BUG-006: PvpMatch missing createdAt index (HIGH)
- BUG-007: 14 models missing timestamp fields (HIGH)
- BUG-008: 0% automated test coverage (HIGH)
- BUG-009: Some caches missing TTL (HIGH)
- BUG-010: Dungeon tables missing indexes (MEDIUM)
- BAL-001: Gold mine passive income 4.4x stronger than active PvP (HIGH)
- BAL-002: Repair costs at 16% of daily income (HIGH)
- EXP-002: Client-side IAP validation only (MEDIUM)

When running a new audit, check each item above — mark FIXED or still open.
