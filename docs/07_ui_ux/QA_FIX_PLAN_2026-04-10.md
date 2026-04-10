# Hexbound — QA Fix Plan (4-week roadmap)

**Date:** 2026-04-10
**Source:** `docs/07_ui_ux/QA_PLAYTHROUGH_2026-04-10.md`
**Scope:** полный roadmap по всем найденным багам (4 CRIT + 7 HIGH + 18 MED + 3 LOW)
**Execution mode:** один фикс за раз, review после каждого, commit после approve
**Target:** soft-launch ready build за 4 недели

---

## 0. Ground rules

### 0.1 Execution protocol (одна итерация = одна правка)

```
[1] Claude поднимает task из плана
[2] Claude делает фикс
[3] Claude запускает verification grep/test из acceptance criteria
[4] Claude показывает Артёму: diff + acceptance результат
[5] Артём даёт approve / ask changes
[6] Если approve → commit через git-watcher (.git-trigger)
[7] Переход к следующему task
```

**Нельзя:** батчить несколько багов в один commit, пропускать verification, двигаться дальше без approve.

### 0.2 Commit message convention

```
fix(CRIT-01): unify freePvpPerDay iOS<->backend
fix(HUB-01): add XP bar to hub

ONB fixes grouped where thematically linked:
feat(onboarding): compress class+origin+gender into 2 screens
```

Формат: `<type>(<BUG-ID>): <short>`. Типы: `fix` / `feat` / `refactor` / `docs` / `chore`.

### 0.3 Mandatory CDO verification per commit

Каждый commit проходит через `CLAUDE.md` CDO verification grep:

```bash
# Invented font tokens
grep -rn 'DarkFantasyTheme\.\(largeTitleFont\|titleFont\|bodyFont\|...\)' Hexbound/ --include="*.swift"
# Invented spacing tokens
grep -rn 'LayoutConstants\.\(spacing\|padding\|margin\)[A-Z]' Hexbound/ --include="*.swift"
# Hardcoded colors in Views
grep -rn 'Color(hex:' Hexbound/Hexbound/Views/ --include="*.swift"
# font(size:) violations
grep -rn '\.font(\.system(size:' Hexbound/Hexbound/Views/ --include="*.swift"
# Merge markers
grep -rn '^<<<<<<<\|^=======\$\|^>>>>>>>' . --include="*.swift" --include="*.ts" --include="*.prisma"
```

Все должны пройти чисто → "CDO: CLEAN" в commit comment.

### 0.4 Rollback strategy

- Каждый фикс в отдельном commit → `git revert <sha>` откатывает один фикс без поломки остальных.
- Balance fixes (Week 3) идут через feature flags в live-config где возможно, чтобы можно было отключить без деплоя.
- Economy рефакторинг (Week 3, BAL-01) — сначала на dev environment + 24ч playtesting, только потом prod.

### 0.5 Agent dispatch per fix type

| Fix type | Primary agent | Verification agent |
|---|---|---|
| iOS SwiftUI | `hexbound-studio:screen` | `hexbound-studio:guardian` |
| Backend TS | `hexbound-studio:server` | `hexbound-studio:oracle` |
| Balance formulas | `hexbound-studio:scales` | `hexbound-studio:ledger` |
| UX changes | `hexbound-studio:flow` | `hexbound-studio:mirror` |
| Combat | `hexbound-studio:bladework` | `hexbound-studio:engine` |
| Docs | `hexbound-studio:scroll` | — |
| Pre-commit | `hexbound-studio:gatekeeper` | — |
| Deploy | `hexbound-studio:herald` | `hexbound-studio:gate` |

---

## 1. WEEK 1 — Foundation fixes (5 days)

**Goal:** закрыть все critical drift bugs, сделать single source of truth, получить честный baseline для всех последующих изменений.

**Definition of done неделя 1:** ни один iOS хардкод не расходится с backend balance.ts; все 4 CRIT закрыты; CDO scan чистый.

### W1.D1 — CRIT-01: FREE_PVP_PER_DAY drift

**Bug:** `AppConstants.freePvpPerDay = 5` в iOS, `STAMINA.FREE_PVP_PER_DAY = 3` в backend → хаб показывает «FREE 5», но сервер резолвит по 3. Client/server distrust на 4-м бою.

**Evidence:**
- `Hexbound/Hexbound/App/AppConstants.swift:71`
- `backend/src/lib/game/balance.ts:16`
- `backend/src/app/api/game/init/route.ts:287` (backend уже отдаёт правильное значение)

**Files to change:**
1. `Hexbound/Hexbound/Services/GameDataCache.swift` — добавить поле `freePvpPerDay: Int` в `GameConfig`, парсить из `/api/game/init` response
2. `Hexbound/Hexbound/Views/Hub/CityMapView.swift:218–223` — заменить `AppConstants.freePvpPerDay` на `appState.gameConfig?.freePvpPerDay ?? 3`
3. `Hexbound/Hexbound/App/AppConstants.swift:71` — поменять fallback на 3 + комментарий `// fallback only — real value from /api/game/init`

**Estimate:** 2 часа

**Acceptance criteria:**
```bash
# iOS хардкоды с fallback = 3
grep -n "freePvpPerDay = " Hexbound/Hexbound/App/AppConstants.swift
# Expected: static let freePvpPerDay = 3

# Hub читает из gameConfig
grep -n "gameConfig?.freePvpPerDay" Hexbound/Hexbound/Views/Hub/CityMapView.swift
# Expected: 1+ matches
```

**Manual QA:** запустить симулятор, убедиться что бейдж над Arena показывает «FREE 3» а не «FREE 5». Сделать 3 боя — бейдж → «FREE 0». На 4-м — UI не показывает FREE и бой списывает stamina корректно.

**Risk:** низкий. Изолированный фикс.

---

### W1.D1 — CRIT-04 EXPANDED: INVENTORY.MAX_SLOTS runtime bug + dead constant

> **Scope upgrade (2026-04-10):** при recon'е обнаружен реальный runtime-баг, а не только косметическая константа. Что было в плане раньше (просто замена `100` на формулу `58` в `balance.ts`) недостаточно.

**Real bug:** инконсистентность между loot-path и shop/expand-path:

| Path | Проверка лимита | Фактический лимит |
|---|---|---|
| `shop/buy/route.ts:59` | `inventoryCount >= character.inventorySlots` | 28–58 (per-character) ✓ |
| `inventory/expand/route.ts:24` | `BASE_SLOTS + MAX_EXPANSIONS * EXPAND_AMOUNT` | 58 ✓ |
| **`loot.ts:312–318` (`persistLoot`)** | `inventoryCount >= MAX_SLOTS` | **100** ✗ |

**Последствие:** игрок с `character.inventorySlots=28` может получить дроп при 28 предметах. Лут попадает в «призрачные слоты» 29–100. Шоп/expand после этого валидны. Визуально инвентарь показывает больше, чем может вместить формально.

**Почему баг не обнаружен раньше:** проверка идёт в двух контурах (shop vs loot), кеш live-config скрывает рассинхрон, `MAX_SLOTS` читается из БД через `getInventoryConfig()` → fallback в `balance.ts` → 100.

**Evidence:**
- `backend/src/lib/game/loot.ts:76-79, 305-318` — `persistLoot` использует `MAX_SLOTS` вместо `character.inventorySlots`
- `backend/src/lib/game/balance.ts:335-341` — `INVENTORY.MAX_SLOTS: 100` как raw value
- `backend/src/lib/game/live-config.ts:254-269` — `getInventoryConfig()` возвращает `MAX_SLOTS` из live-config
- `admin/src/actions/config.ts:181` — админка **сидит** `inventory.max_slots=100` в БД при reset-defaults
- `admin/src/app/(dashboard)/balance/balance-client.tsx:293` — UI редактор с `defaultValue: 100`
- `backend/src/app/api/shop/buy/route.ts:59` — корректная per-character проверка
- `backend/src/app/api/inventory/expand/route.ts:24` — корректная формула BASE+MAX*EXPAND

**Root design error:** `MAX_SLOTS` — это **derived value** (формула от `BASE_SLOTS`, `MAX_EXPANSIONS`, `EXPAND_AMOUNT`), а не настраиваемая константа. Правильно вычисляемое значение = 58. Редактировать его отдельно в live-config = source of drift.

---

#### 8-шаговый sub-план

**Step 1 — `loot.ts` persistLoot refactor** (правильная per-character проверка):

```typescript
// loot.ts:305
export async function persistLoot(
  prisma: PrismaClient,
  characterId: string,
  drop: DroppedItem,
  playerLevel: number,
): Promise<LootResponseItem | null> {
  // Check inventory capacity — per-character, NOT global MAX_SLOTS
  const character = await prisma.character.findUnique({
    where: { id: characterId },
    select: { inventorySlots: true },
  });
  const maxSlots = character?.inventorySlots ?? INVENTORY.BASE_SLOTS;
  const inventoryCount = await prisma.equipmentInventory.count({
    where: { characterId },
  });
  if (inventoryCount >= maxSlots) {
    return null; // Inventory full — drop is lost
  }
  // ... rest unchanged
}
```

Удалить helper `getMaxInventorySlots()` (строки 76–79) — больше не нужен.
Импорт `getInventoryConfig` можно оставить — он всё ещё используется для других полей; а `getMaxInventorySlots()` — нет.

Также убрать импорт `INVENTORY.MAX_SLOTS` использование если оно там есть — полагаться только на `INVENTORY.BASE_SLOTS` как fallback.

**Step 2 — `balance.ts` INVENTORY cleanup:**

```typescript
// balance.ts:334-341
// --- Inventory ---
export const INVENTORY = {
  BASE_SLOTS: 28,
  EXPAND_AMOUNT: 10,
  EXPAND_COST_GOLD: 5000,
  MAX_EXPANSIONS: 3,
  /**
   * Derived hard cap: BASE_SLOTS + MAX_EXPANSIONS * EXPAND_AMOUNT = 58.
   * NOT a live-config value. NOT editable via admin.
   * Per-character actual limit lives in `Character.inventorySlots` (28-58).
   */
  get MAX_SLOTS() {
    return this.BASE_SLOTS + this.MAX_EXPANSIONS * this.EXPAND_AMOUNT;
  },
} as const;
```

**Риск getter:** TypeScript `as const` может конфликтовать с getter. Fallback — обычное поле:
```typescript
export const INVENTORY = {
  BASE_SLOTS: 28,
  EXPAND_AMOUNT: 10,
  EXPAND_COST_GOLD: 5000,
  MAX_EXPANSIONS: 3,
  MAX_SLOTS: 28 + 3 * 10, // DERIVED: BASE_SLOTS + MAX_EXPANSIONS * EXPAND_AMOUNT = 58
} as const;
```
+ комментарий про derived nature.

**Step 3 — `live-config.ts` remove `inventory.max_slots`:**

```typescript
// live-config.ts:253-269
export async function getInventoryConfig() {
  const configs = await getGameConfigs({
    // 'inventory.max_slots' REMOVED — derived value, not configurable.
    // Use INVENTORY.MAX_SLOTS from balance.ts directly if global cap needed.
    'inventory.base_slots': INVENTORY.BASE_SLOTS,
    'inventory.expand_amount': INVENTORY.EXPAND_AMOUNT,
    'inventory.expand_cost_gold': INVENTORY.EXPAND_COST_GOLD,
    'inventory.max_expansions': INVENTORY.MAX_EXPANSIONS,
  })
  return {
    MAX_SLOTS: INVENTORY.BASE_SLOTS + (configs['inventory.max_expansions'] as number) * (configs['inventory.expand_amount'] as number),
    BASE_SLOTS: configs['inventory.base_slots'] as number,
    EXPAND_AMOUNT: configs['inventory.expand_amount'] as number,
    EXPAND_COST_GOLD: configs['inventory.expand_cost_gold'] as number,
    MAX_EXPANSIONS: configs['inventory.max_expansions'] as number,
  }
}
```

`MAX_SLOTS` в return остаётся для back-compat (если где-то в коде читается), но вычисляется из derived-формулы, не из БД.

**Step 4 — admin cleanup:**

4a. `admin/src/actions/config.ts:181` — удалить строку:
```typescript
{ key: 'inventory.max_slots', value: 100, category: 'inventory', description: 'Absolute maximum inventory slots' },
```

4b. `admin/src/app/(dashboard)/balance/balance-client.tsx:293` — удалить UI элемент:
```typescript
{ key: 'inventory.max_slots', label: 'Max Slots (Hard Cap)', ... },
```

Убрать из UI окна балансного редактора, чтобы админ не мог случайно перезаписать.

**Step 5 — SQL migration для stale данных:**

Создать `backend/prisma/migrations/20260410_remove_inventory_max_slots/migration.sql`:
```sql
-- CRIT-04: MAX_SLOTS is now a derived constant, not a live-config value.
-- Remove stale entry from game_config table to prevent drift.
DELETE FROM game_config WHERE key = 'inventory.max_slots';
```

После миграции нужно **инвалидировать Redis кеш** — либо:
- `await cacheDel('gameconfig:inventory.max_slots')`
- или ждать 5 минут TTL
- или добавить в migration script `backend/scripts/migrate-crit04.ts` который и delete, и cache clear

**Рекомендую:** отдельный migration script `backend/scripts/migrate-crit04-inventory.ts` вместо SQL migration, чтобы он мог:
1. `DELETE FROM game_config WHERE key = 'inventory.max_slots'`
2. Инвалидировать кеш: `await cacheDel('gameconfig:inventory.max_slots')` + batch keys
3. Логировать результат

**Step 6 — Prod audit script для overflow detection:**

`backend/scripts/audit-inventory-overflow.ts`:
```typescript
// Detect characters where equipmentInventory count > inventorySlots
// (data left over from the old persistLoot bug using MAX_SLOTS=100)
import { prisma } from '../src/lib/prisma';

async function main() {
  const characters = await prisma.character.findMany({
    select: {
      id: true,
      name: true,
      inventorySlots: true,
      _count: { select: { equipmentInventory: true } },
    },
  });
  const overflowed = characters.filter(
    (c) => c._count.equipmentInventory > c.inventorySlots
  );
  console.log(`Found ${overflowed.length} characters with inventory overflow:`);
  for (const c of overflowed) {
    console.log(`  ${c.id} (${c.name}): ${c._count.equipmentInventory}/${c.inventorySlots}`);
  }
}
main().then(() => process.exit(0));
```

**Поведение после фикса:** overflowed персонажи просто перестанут получать дроп (persistLoot вернёт null для них до тех пор пока они не продадут/не выбросят лишние предметы, либо не расширят инвентарь). Это **нежелательно, но не критично** — игрок увидит «Inventory full» и поймёт что делать.

**Альтернатива** (если audit покажет много overflow случаев): cleanup-миграция которая либо (а) увеличивает inventorySlots до фактического count, (б) перемещает overflow-items в «дропбокс», (с) автоматически продаёт дешевые overflow-items. **Решение принимать ПОСЛЕ запуска audit скрипта.**

**Step 7 — CDO grep verification:**
```bash
# 1. persistLoot читает per-character, не MAX_SLOTS
grep -n "character.*inventorySlots\|inventoryCount >= maxSlots" backend/src/lib/game/loot.ts

# 2. getMaxInventorySlots() удалён
grep -n "getMaxInventorySlots" backend/src/lib/game/loot.ts
# Expected: no matches

# 3. balance.ts MAX_SLOTS derived
grep -n "MAX_SLOTS" backend/src/lib/game/balance.ts
# Expected: either `MAX_SLOTS: 28 + 3 * 10` or `get MAX_SLOTS()`

# 4. live-config не запрашивает inventory.max_slots из БД
grep -n "inventory.max_slots" backend/src/lib/game/live-config.ts
# Expected: no matches (or only in comment)

# 5. admin seeds не содержат inventory.max_slots
grep -rn "inventory.max_slots" admin/src/
# Expected: no matches

# 6. Нет merge conflicts
grep -rn "^<<<<<<<\|^=======$\|^>>>>>>>" backend/ admin/ --include="*.ts" --include="*.tsx" --include="*.sql"
# Expected: no matches

# 7. Prisma schema не трогали (должна остаться без изменений)
git diff --stat backend/prisma/schema.prisma admin/prisma/schema.prisma
# Expected: only new migration file, no schema changes
```

**Step 8 — Commit plan:**

Два коммита для чистоты (или один, если Артем предпочтёт):

**Commit A** (code refactor):
```
fix(CRIT-04): remove dead INVENTORY.MAX_SLOTS + fix loot per-character limit

persistLoot() now reads character.inventorySlots instead of global
MAX_SLOTS constant, matching the per-character limit used in shop/buy
and inventory/expand. Removes drift where loot could create ghost slots
beyond character.inventorySlots (up to MAX_SLOTS=100).

balance.ts INVENTORY.MAX_SLOTS is now a derived constant (58 = BASE +
MAX_EXPANSIONS * EXPAND_AMOUNT), not a configurable live-config value.
live-config.ts no longer reads inventory.max_slots from DB — value is
computed from other INVENTORY fields.

admin/config.ts and balance-client.tsx remove inventory.max_slots from
seeds and balance editor UI.

Part of W1.D1 of QA_FIX_PLAN_2026-04-10.md CRIT-04 EXPANDED
```

**Commit B** (migration + audit script):
```
chore(CRIT-04): migration script to remove stale inventory.max_slots

backend/scripts/migrate-crit04-inventory.ts deletes stale game_config
entry and invalidates Redis cache. Run once on dev → staging → prod
after deploying Commit A.

backend/scripts/audit-inventory-overflow.ts detects characters whose
equipmentInventory count exceeds inventorySlots (legacy data from the
old persistLoot bug). Run before migrate to decide cleanup strategy.

Part of W1.D1 of QA_FIX_PLAN_2026-04-10.md CRIT-04 EXPANDED
```

---

#### Files to change (total 6 code + 2 scripts + docs)

| # | File | Change |
|---|---|---|
| 1 | `backend/src/lib/game/loot.ts` | `persistLoot()` reads `character.inventorySlots`; remove `getMaxInventorySlots()` |
| 2 | `backend/src/lib/game/balance.ts` | `INVENTORY.MAX_SLOTS` derived value + doc comment |
| 3 | `backend/src/lib/game/live-config.ts` | Remove `inventory.max_slots` from `getInventoryConfig()` reads |
| 4 | `admin/src/actions/config.ts` | Remove line 181 (`inventory.max_slots` seed) |
| 5 | `admin/src/app/(dashboard)/balance/balance-client.tsx` | Remove line 293 (`inventory.max_slots` UI) |
| 6 | `backend/scripts/migrate-crit04-inventory.ts` | **NEW** — DELETE stale config key + cache invalidation |
| 7 | `backend/scripts/audit-inventory-overflow.ts` | **NEW** — audit script for legacy overflow |
| 8 | `docs/06_game_systems/BALANCE_CONSTANTS.md` | Update INVENTORY section if it exists |

**pbxproj:** не трогаем (backend only).
**Prisma schema:** не трогаем (инвентарь уже правильно моделируется).

---

#### Estimate

| Step | Time |
|---|---|
| Code refactor (Steps 1–4) | 1.5h |
| Migration + audit scripts (Steps 5–6) | 1h |
| Dry-run на dev + audit результаты | 30min |
| CDO + commits + doc update | 30min |
| **Total** | **~3.5h** |

---

#### Agent dispatch (по ходу)

- **После Step 1–4 (code changes):** `hexbound-studio:oracle` review loot.ts diff (async correctness, type safety, Prisma queries)
- **После Step 5 (migration):** `hexbound-studio:fortress` review SQL migration (safety, rollback)
- **После Step 6 (audit script):** `hexbound-studio:ledger` review (economy audit correctness — посчитал ли overflow правильно)
- **Перед commit:** `hexbound-studio:gatekeeper` preflight

---

#### Risk register (CRIT-04 EXPANDED)

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Prod имеет overflow случаи которые аудит покажет | Medium | Medium | Запустить audit скрипт ПЕРЕД кодом; если >5 случаев — отдельный cleanup план |
| Redis кеш не инвалидирован после migration | Low | Low | Script делает `cacheDel` напрямую, fallback — подождать 5 min TTL |
| `getter MAX_SLOTS()` ломает `as const` | Low | Low | Использовать literal expression вместо getter |
| Другой код (dungeon loot, BP claim) читает `MAX_SLOTS` как 100 | Medium | High | Step 7 grep verification проверяет ВСЕ usages |
| Battle Pass claim (`bp/claim/[level]/route.ts:386`) тоже имеет баг | High | High | **Проверить в рамках Step 1** — возможно расширение scope |

**Red flag к внимательной проверке:** `backend/src/app/api/battle-pass/claim/[level]/route.ts:386` уже использует `lockedCharacter.inventory_slots` (per-character) — значит там **не** баг. Но нужно grep'нуть все пути создания `equipmentInventory` чтобы найти все нерефакторенные места.

**Дополнительный grep на Step 0 (до старта):**
```bash
grep -rn "equipmentInventory.create\|equipmentInventory\.count" backend/src --include="*.ts"
```
Убедиться что все creators проверяют лимит корректно.

---

#### Acceptance criteria (final)

```bash
# Все grep'ы из Step 7 должны пройти
# + новые проверки:

# 1. persistLoot reads character.inventorySlots
grep -A 5 "persistLoot" backend/src/lib/game/loot.ts | grep "character?.inventorySlots\|character\.inventorySlots"
# Expected: 1 match

# 2. Нет других мест где MAX_SLOTS используется как hard cap
grep -rn "INVENTORY\.MAX_SLOTS\|config\.MAX_SLOTS" backend/src --include="*.ts"
# Expected: only in balance.ts declaration + safe usages

# 3. Audit script запускается без ошибок
cd backend && npx tsx scripts/audit-inventory-overflow.ts
# Expected: prints count (may be 0)

# 4. Migration script запускается без ошибок на dev
cd backend && npx tsx scripts/migrate-crit04-inventory.ts
# Expected: "Deleted 0 or 1 rows, cache invalidated"
```

**Уверенность в фиксе:** высокая (код); средняя (prod data) — зависит от результата audit скрипта. Если audit покажет >5 overflow персонажей, нужен отдельный cleanup план (Step 6 alternative).

---

### W1.D2 — CRIT-02: Daily Login Day 1 drift (150 vs 200)

**Bug:** Игра показывает 200 gold на Day 1, код `balance.ts` = 150. Значит live-config БД отстала.

**Evidence:**
- `backend/src/lib/game/balance.ts:77` — DAILY_LOGIN_REWARDS Day 1 = 150
- `backend/src/lib/game/live-config.ts` — runtime override из БД
- Симулятор показал 200

**Approach:**
1. Прочитать текущее состояние live-config в DB (через admin panel или `SELECT * FROM live_config WHERE key LIKE 'daily_login.%'`).
2. Написать одноразовый migration script `backend/scripts/sync-daily-login-rewards.ts` который пишет `DAILY_LOGIN_REWARDS` из `balance.ts` в live-config таблицу.
3. Запустить на dev → проверить → запустить на prod.

**Files to change:**
1. `backend/scripts/sync-daily-login-rewards.ts` — новый файл (migration script)
2. `backend/src/lib/game/live-config.ts` — убедиться что `getDailyLoginRewardsConfig()` читает из DB, но fallback = `balance.ts` DAILY_LOGIN_REWARDS (если null)

**Estimate:** 3 часа

**Acceptance criteria:**
```bash
# Скрипт создан
ls backend/scripts/sync-daily-login-rewards.ts

# Запуск в dev
cd backend && npm run script:sync-daily-login-rewards -- --env=dev --dry-run
# Expected: показывает diff — какие значения поменяются
```

**Manual QA:** После prod sync зайти в игру, смотреть Daily Login Day 1 — должно быть **150 gold**, не 200.

**Risk:** средний. Это production DB write. **Обязательно dry-run → manual review → apply.**

---

### W1.D2 — CRIT-03: Hub HP bar без подписи + XP bar отсутствует

**Bug:** Зелёная полоса 160/160 на хабе = HP, но читается как XP. Реального XP bar на хабе нет.

**Decision needed:** два подхода:
- (A) Подписать HP + добавить XP bar рядом — минимальное изменение
- (B) **(Recommended)** Убрать HP с хаба (показывать только когда <100%), поставить XP bar на основное место — сильный core loop fix

**План: вариант B.**

**Files to change:**
1. `Hexbound/Hexbound/Views/Hub/HubView.swift` — найти HP bar компонент
2. Создать новый `Hexbound/Hexbound/Views/Hub/HubXPBar.swift`:
   - Использует `XPBarView` из `Views/Components/` (уже есть, см. `CLAUDE.md` Progress Bars page)
   - Цвет: gold (не зелёный)
   - Показывает `appState.currentCharacter?.xp / xpForLevel(level+1)`
   - Подпись: `LEVEL {N} · {current}/{max} XP`
3. Условный рендер HP: `if hp < maxHp { HPBarView(compact) }` — показывается только когда ранен
4. Добавить файл в `Hexbound.xcodeproj/project.pbxproj` (4 секции — см. CLAUDE.md)

**Estimate:** 4 часа

**Acceptance criteria:**
```bash
# XP bar компонент существует
ls Hexbound/Hexbound/Views/Hub/HubXPBar.swift

# pbxproj содержит новый файл
grep "HubXPBar" Hexbound/Hexbound.xcodeproj/project.pbxproj
# Expected: 4 matches (PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase)

# Билд
cd Hexbound && xcodebuild -project Hexbound.xcodeproj -scheme Hexbound -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -5
```

**Manual QA:** хаб показывает LEVEL 1 · 0/280 XP, gold цвет, прогресс обновляется после боя. HP bar показывается только при <160 HP.

**Risk:** средний. Меняется primary hub element. Нужно аккуратно по дизайн-системе.

**Agent:** `hexbound-studio:screen` + `hexbound-studio:blueprint` (design system compliance)

---

### W1.D3 — Remove iOS hardcodes, introduce GameConfig from backend

**Meta-fix:** установить паттерн «iOS не хардкодит game constants». Это SSoT (single source of truth) protocol.

**Files to change:**
1. `Hexbound/Hexbound/App/AppConstants.swift` — оставить только UI константы (animation timings, cache limits). Game constants помечать `// DEPRECATED — use gameConfig from backend`.
2. `Hexbound/Hexbound/Models/GameConfig.swift` — новая модель, mirrors backend `/api/game/init` response:
   ```swift
   struct GameConfig: Codable {
       let freePvpPerDay: Int
       let pvpStaminaCost: Int
       let maxStamina: Int
       let xpFormulaConstants: XPFormula
       let inventoryBaseSlots: Int
       let inventoryMaxExpansions: Int
       let dailyLoginRewards: [DailyLoginReward]
       // ... etc
   }
   ```
3. `Hexbound/Hexbound/Services/GameDataCache.swift` — добавить `@Observable var gameConfig: GameConfig?`, загружать на старте через `/api/game/init`
4. `backend/src/app/api/game/init/route.ts` — расширить response чтобы содержал все game constants

**Estimate:** 1 день (8 часов)

**Acceptance criteria:**
```bash
# Нет хардкодов game констант в iOS
grep -rn "static let \(maxStamina\|pvpCost\|xp\)" Hexbound/Hexbound/App/AppConstants.swift
# Expected: all have DEPRECATED comment or removed

# GameConfig модель существует
ls Hexbound/Hexbound/Models/GameConfig.swift

# Backend отдаёт gameConfig
grep -n "gameConfig" backend/src/app/api/game/init/route.ts
```

**Risk:** средний. Касается загрузки при старте. Обязательно fallback в кэш если запрос падает.

---

### W1.D4 — Docs auto-generation from balance.ts

**Meta-fix:** запретить drift между `balance.ts` и `docs/06_game_systems/BALANCE_CONSTANTS.md`.

**Approach:**
1. Написать `backend/scripts/generate-balance-docs.ts` который читает `balance.ts` AST и генерирует markdown таблицы всех констант.
2. Обновить `docs/06_game_systems/BALANCE_CONSTANTS.md` с заголовком `<!-- AUTO-GENERATED from backend/src/lib/game/balance.ts — DO NOT EDIT MANUALLY -->`.
3. Добавить в `package.json`: `"docs:balance": "tsx scripts/generate-balance-docs.ts"`.
4. Pre-commit hook: если `balance.ts` изменён → перегенерировать `BALANCE_CONSTANTS.md` и добавить в stage.

**Files to change:**
1. `backend/scripts/generate-balance-docs.ts` — новый
2. `backend/package.json` — добавить script
3. `docs/06_game_systems/BALANCE_CONSTANTS.md` — перегенерирован
4. `.husky/pre-commit` или `scripts/preflight_check.sh` — добавить проверку

**Estimate:** 1 день

**Acceptance criteria:**
```bash
# Script работает
cd backend && npm run docs:balance
# Expected: no errors, BALANCE_CONSTANTS.md updated

# Doc содержит auto-gen marker
head -5 docs/06_game_systems/BALANCE_CONSTANTS.md
# Expected: includes "AUTO-GENERATED" comment
```

**Risk:** низкий.

---

### W1.D5 — CI guards: hardcode detection

**Meta-fix:** блокировать mergest на drift между iOS и backend.

**Files to change:**
1. `scripts/check_ios_backend_drift.sh` — новый скрипт:
   ```bash
   #!/bin/bash
   # Check that iOS AppConstants does not define game constants
   # Those should come from GameConfig response
   FORBIDDEN_CONSTANTS="freePvpPerDay|maxStamina|pvpStaminaCost|xpPerLevel"
   VIOLATIONS=$(grep -E "static let ($FORBIDDEN_CONSTANTS)" Hexbound/Hexbound/App/AppConstants.swift | grep -v "DEPRECATED")
   if [ -n "$VIOLATIONS" ]; then
       echo "DRIFT: iOS hardcodes game constants:"
       echo "$VIOLATIONS"
       exit 1
   fi
   ```
2. Добавить в `scripts/preflight_check.sh` → вызов этого скрипта.
3. Добавить в GitHub Actions если есть CI.

**Estimate:** 2 часа

**Acceptance criteria:**
```bash
bash scripts/check_ios_backend_drift.sh
# Expected: exit 0

# Тест отрицательного кейса
echo "static let freePvpPerDay = 99" >> Hexbound/Hexbound/App/AppConstants.swift
bash scripts/check_ios_backend_drift.sh
# Expected: exit 1, shows violation
git checkout Hexbound/Hexbound/App/AppConstants.swift
```

**Risk:** низкий.

---

### W1 checkpoint

В конце Week 1 запустить:
- [ ] Full `preflight_check.sh` — чисто
- [ ] CDO scan — чисто
- [ ] Manual QA: запустить симулятор, пройти онбординг, попасть в хаб, убедиться что: (а) XP bar на хабе, (б) FREE 3 над Arena, (в) Daily Login Day 1 = 150 gold
- [ ] Agent review: `hexbound-studio:guardian` по iOS изменениям + `hexbound-studio:oracle` по backend
- [ ] Commit tag: `v2026.04.17-w1-foundation`

**Выход Week 1:** все 4 CRIT закрыты, SSoT protocol применён, docs автогенерируются. Baseline для Week 2.

---

## 2. WEEK 2 — Onboarding hook (5 days)

**Goal:** превратить онбординг в эмоциональный hook. Цель: D1 retention +15–25%, первые 5 минут игры должны быть unforgettable.

**Definition of done Week 2:** от Sign Up до первой победы в туториальном бою — ≤ 7 экранов и ≤ 3 минуты. Daily Login — после первого боя.

### W2.D1 — ONB-02 part 1: compress gender + appearance into single screen

**Bug:** 5 отдельных экранов для создания персонажа — слишком длинный funnel.

**Approach:** объединить Gender picker и Appearance picker в один экран с табами «♂ Male / ♀ Female».

**Files to change:**
1. `Hexbound/Hexbound/Views/Auth/` или `Onboarding/` — найти `GenderPickerView.swift` и `AppearancePickerView.swift`
2. Создать `AppearanceWithGenderView.swift` — объединённый экран с:
   - Tab switcher (существующий `TabSwitcher.swift` из DS — 2-tab variant)
   - Body: grid портретов отфильтрованный по выбранному gender
3. Обновить navigation flow в `OnboardingCoordinator` или `AppRouter`
4. Добавить новый файл в pbxproj, удалить старые

**Estimate:** 1 день

**Acceptance criteria:**
```bash
# Старые экраны удалены или объединены
grep -rn "GenderPickerView\|AppearancePickerView" Hexbound/Hexbound/Views/

# Новый экран существует
ls Hexbound/Hexbound/Views/**/AppearanceWithGenderView.swift

# pbxproj обновлён
grep "AppearanceWithGenderView" Hexbound/Hexbound.xcodeproj/project.pbxproj
```

**Manual QA:** пройти онбординг, проверить что gender+appearance теперь один экран с табами, navigation работает корректно (back/next).

**Agent:** `hexbound-studio:flow`

---

### W2.D2 — ONB-04: Welcome lore — cinematic вместо wall-of-text

**Bug:** Длинный текст welcome/lore intro — никто не читает.

**Approach:**
1. Сократить текст до 15 слов (max 2 предложения).
2. Добавить full-screen background illustration (reuse from `Assets.xcassets/UI_Backgrounds` — например `bg-arena` или `logo`).
3. Вместо wall-of-text — одна мощная фраза типа:
   > «Веками клан сражался за эти земли. Сегодня твоя очередь.»
4. Full lore текст перенести в Codex / Archives экран (если такого нет, создать placeholder feature flag).

**Files to change:**
1. `Hexbound/Hexbound/Views/Auth/` или `Onboarding/` — `WelcomeView.swift` или `LoreIntroView.swift`
2. Текст в соответствующем ViewModel

**Estimate:** 3 часа

**Acceptance criteria:**
- Текст welcome экрана ≤ 15 слов
- Background illustration занимает full screen
- Text использует `DarkFantasyTheme.cinematicTitle` (40pt)
- Есть одна CTA кнопка «НАЧАТЬ» (`.primary` style)

**Manual QA:** welcome screen выглядит cinematic, читается за 2 секунды.

---

### W2.D2 — ONB-06: Guest option prominence

**Bug:** «Play as Guest» не в первой фокус-зоне, новички не видят.

**Files to change:**
1. `Hexbound/Hexbound/Views/Auth/AuthView.swift` или аналог
2. Swap hierarchy: большая primary CTA «PLAY AS GUEST», ниже secondary «Sign up / Sign In for Cloud Save»

**Estimate:** 1 час

**Acceptance criteria:** visual hierarchy перестроена, guest — primary CTA.

---

### W2.D3 — ONB-01: Tutorial fight (biggest win)

**Bug:** После онбординга игрок не получает guided первого боя.

**Approach:**
1. После хаба reveal анимации → автоматически триггерить tutorial fight
2. Tutorial = против слабого scripted противника (Lv 1 Orc Grunt, 100 HP, basic attack only)
3. Показывать подсказки (toast banners из DS) на ключевых моментах:
   - «Выбери stance для атаки» — подсветка stance selector
   - «Выбери zone защиты» — подсветка defense zones
   - «Нажми FIGHT»
4. Гарантированная победа (scripted outcome)
5. Epic reward screen: +50 gold, +150 XP, +1 common item drop
6. Только после этого → Daily Login popup (ONB-05)

**Files to change:**
1. `Hexbound/Hexbound/Views/Tutorial/TutorialFightView.swift` — новый
2. `Hexbound/Hexbound/Views/Tutorial/TutorialFightViewModel.swift` — scripted fight logic
3. `Hexbound/Hexbound/Views/Tutorial/TutorialHintOverlay.swift` — подсветка UI элементов
4. `backend/src/app/api/tutorial/fight/route.ts` — endpoint для scripted fight (либо offline на клиенте)
5. `AppRouter.swift` — добавить tutorial state в flow
6. `backend/src/lib/game/tutorial.ts` — state machine (started / completed)
7. Prisma schema — добавить `tutorialCompleted: Boolean @default(false)` на Character или User
8. Миграция: `npx prisma migrate dev --name add_tutorial_state`
9. `cp backend/prisma/schema.prisma admin/prisma/schema.prisma`

**Estimate:** 2 дня (самый большой фикс недели)

**Acceptance criteria:**
```bash
# Tutorial компоненты созданы
ls Hexbound/Hexbound/Views/Tutorial/

# Backend endpoint
ls backend/src/app/api/tutorial/

# Prisma sync
diff backend/prisma/schema.prisma admin/prisma/schema.prisma
# Expected: no diff
```

**Manual QA:** от начала новой игры до конца туториального боя ≤ 3 минут. Guided hints показываются. Победа гарантирована. Reward screen emotionally satisfying.

**Risk:** высокий. Это новая feature, не просто фикс. Нужен tight scope — scripted, не dynamic.

**Agent:** `hexbound-studio:flow` + `hexbound-studio:bladework` + `hexbound-studio:server`

---

### W2.D4 — HUB-02: Building gating by level

**Bug:** 10 зданий сразу на Lv 1 = choice overload.

**Approach:**
1. В `CityBuildingConfig.swift` добавить поле `unlockLevel: Int`
2. Gating design:
   | Building | Unlock Level |
   |---|---|
   | Arena | 1 (always) |
   | Inbox | 1 |
   | Daily Login | 1 |
   | Training | 2 |
   | Quests | 2 |
   | Dungeon | 3 |
   | Shop | 4 |
   | Battle Pass | 5 |
   | Achievements | 5 |
   | Gold Mine | 7 |
   | Future buildings | 8+ |
3. Visual lock state: здание затемнено (opacity 0.4), ornamental lock overlay, подпись `LVL {N}`
4. Unlock ceremony: при первом достижении уровня → cinematic popup «BUILDING UNLOCKED: Training Grounds»

**Files to change:**
1. `Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift` — добавить `unlockLevel`
2. `Hexbound/Hexbound/Views/Hub/CityBuildingView.swift` — условный рендер lock state
3. `Hexbound/Hexbound/Views/Hub/BuildingUnlockCeremony.swift` — новый файл
4. `CityMapView.swift` — триггер ceremony на level up
5. Добавить в pbxproj

**Estimate:** 1 день

**Acceptance criteria:**
```bash
# unlockLevel определён
grep -n "unlockLevel" Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift
# Expected: 10 buildings with levels

# Ceremony компонент существует
ls Hexbound/Hexbound/Views/Hub/BuildingUnlockCeremony.swift
```

**Manual QA:** на Lv 1 видно только 3 здания (Arena + Inbox + Daily Login). Остальные залочены с подписью уровня. На Lv 2 — Training unlock ceremony.

**Agent:** `hexbound-studio:ascent` (progression design) + `hexbound-studio:flow`

---

### W2.D5 — HUB-04: Today's goals panel + HUB-03 badge hierarchy + ONB-05 daily login timing

**Bug:** нет panel «что делать сегодня», бейджи шумные, daily login слишком рано.

**HUB-04 — Today's goals panel:**
1. Создать `Hexbound/Hexbound/Views/Hub/TodayGoalsPanel.swift`
2. Compact horizontal strip под currency bar
3. Содержимое:
   - `3 wins` прогресс bar (0/3)
   - `1 dungeon` (0/1)
   - `Claim BP` (claimable count)
   - `Daily login` (claimable flag)
4. Tap на goal → navigate к соответствующему зданию

**HUB-03 — Badge hierarchy:**
1. В `CityBuildingConfig.swift` добавить `badgePriority: .critical / .info / .none`
2. Critical: красный pulse (attention required) — например Daily Login неклеймлен
3. Info: приглушённый gold — например «FREE 3»
4. None: не показывать

**ONB-05 — Daily login timing:**
1. В `DailyLoginService.swift` — не показывать popup если `tutorialCompleted == false`
2. После завершения tutorial fight → trigger daily login popup
3. Это эмоционально правильно: «Молодец, первая победа! Держи бонус за день 1.»

**Files to change:**
1. `Hexbound/Hexbound/Views/Hub/TodayGoalsPanel.swift` — новый
2. `Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift` — badgePriority field
3. `Hexbound/Hexbound/Views/Hub/CityBuildingView.swift` — conditional badge styling
4. `Hexbound/Hexbound/Services/DailyLoginService.swift` — gate на tutorial completion
5. Add files to pbxproj

**Estimate:** 1 день

**Acceptance criteria:**
- Today's goals panel виден на хабе
- На Lv 1 после tutorial: показаны 3 wins, daily login claimable
- Badge на Daily Login пульсирует красным
- Badge «FREE 3» на Arena — gold, без анимации

---

### W2 checkpoint

- [ ] Full onboarding replay: Sign Up → 1st fight → Daily Login → hub. Должно быть ≤ 7 экранов до tutorial fight, ≤ 3 минут total.
- [ ] D1 retention hypothesis: хаб первых 5 минут эмоционально насыщенный
- [ ] Agent review: `hexbound-studio:psyche` (emotional hooks) + `hexbound-studio:heartbeat` (core loop)
- [ ] Commit tag: `v2026.04.24-w2-onboarding`

**Выход Week 2:** онбординг сжат, туториальный бой добавлен, хаб gating + today's goals. D1 hypothesis: +15% retention. Проверим на playtest.

---

## 3. WEEK 3 — Balance adjustments (5 days)

**Goal:** применить Economy v2 полностью, закрыть trap stats, исправить combat asymmetry. **Вся неделя — на dev environment, prod deploy только в конце.**

**Definition of done Week 3:** sink ratio в симуляциях близко к target 55–65%; CHA имеет смысловой выбор; AGI/Rogue восстановлены; stance zones симметричны.

### W3.D1 — STAT-02: Charisma redesign

**Bug:** CHA — trap stat, two mixed effects, false choice.

**Decision needed:** два подхода:
- (A) Убрать как allocatable — только race bonus
- (B) **(Recommended)** Сделать boss-stat с реальной mechanic

**План: вариант B — CHA gets «Intimidation miss chance».**

**Design:**

$$
P_\text{enemy miss} = \min(0.005 \cdot \text{CHA}, 0.10)
$$

То есть 0.5% enemy miss chance per CHA point, cap 10%. Это 20 CHA для cap, что соответствует roughly 1/3 stat budget на mid-game.

Плюс существующие эффекты остаются:
- Gold bonus (unchanged formula)
- Intimidation damage reduction (unchanged)

Новое: **Taunt active skill**. Charge: 1 skill slot. Cost: 20 stamina (in-fight). Effect: forces enemy to attack you instead of ally (для PvE dungeons). В PvP: снижает enemy next attack damage на 30%.

**Files to change:**
1. `backend/src/lib/game/balance.ts` — добавить `CHA_ENEMY_MISS_PER_POINT: 0.005`, `CHA_ENEMY_MISS_CAP: 0.10`
2. `backend/src/lib/game/combat.ts` — в resolve функции добавить miss roll на CHA
3. `backend/src/lib/game/skills.ts` — добавить `taunt` skill definition
4. `Hexbound/Hexbound/Views/Profile/StatusView.swift` — tooltip CHA обновить с новой формулой
5. `backend/tests/combat/cha-miss.test.ts` — новые тесты

**Estimate:** 1 день

**Acceptance criteria:**
```bash
# Formula в balance.ts
grep -n "CHA_ENEMY_MISS" backend/src/lib/game/balance.ts

# Тесты
cd backend && npm test -- cha-miss
# Expected: all pass
```

**Agent:** `hexbound-studio:scales` + `hexbound-studio:bladework`

---

### W3.D2 — STAT-03: AGI partial restoration

**Bug:** AGI triple-nerf класс-дискриминирует Rogue.

**Approach:** частично откатить один из трёх nerfs + добавить новую механику.

**Changes to `balance.ts`:**
```typescript
// BEFORE (current)
CRIT_PER_LUK: 0.7,
CRIT_PER_AGI: 0.15,
DODGE_PER_AGI: 0.2,
ROGUE_DODGE_BONUS: 3,

// AFTER
CRIT_PER_LUK: 0.6,       // -0.1
CRIT_PER_AGI: 0.2,       // +0.05 (partial restore)
DODGE_PER_AGI: 0.2,      // same
ROGUE_DODGE_BONUS: 4,    // +1 (partial restore)
```

Плюс новый Rogue pasiv: **«Execute»** — Rogue attacks have +15% damage vs enemies below 35% HP. Это execute bonus который тематически правильный и возвращает мощность без breaking мета.

**Files to change:**
1. `backend/src/lib/game/balance.ts`
2. `backend/src/lib/game/combat.ts` — execute bonus в damage calc
3. `backend/tests/combat/rogue-execute.test.ts`
4. Docs: `docs/06_game_systems/COMBAT.md` — обновить formulas

**Estimate:** 4 часа

**Acceptance criteria:**
```bash
# Values updated
grep -n "CRIT_PER_AGI\|ROGUE_DODGE_BONUS" backend/src/lib/game/balance.ts

# Execute logic
grep -n "execute" backend/src/lib/game/combat.ts

# Tests pass
cd backend && npm test -- rogue-execute
```

**Manual sim:** запустить 100 fights Rogue vs Warrior на dev → Rogue winrate должен быть 48–52% (близко к равному).

**Agent:** `hexbound-studio:scales` + `hexbound-studio:arena` (pvp fairness)

---

### W3.D3 — BAL-01: Sink ratio rebalance

**Bug:** Actual sink ratio ~20–30%, target 55–65%.

**Changes:**

1. **Cap streak multipliers:**
   ```typescript
   // BEFORE
   WIN_STREAK_3: 1.2, WIN_STREAK_5: 1.5, WIN_STREAK_8: 2.0,
   LOSS_STREAK_3: 1.3, LOSS_STREAK_5: 1.5, LOSS_STREAK_7: 1.8,

   // AFTER
   WIN_STREAK_3: 1.15, WIN_STREAK_5: 1.3, WIN_STREAK_8: 1.5,
   LOSS_STREAK_3: 1.2, LOSS_STREAK_5: 1.35, LOSS_STREAK_7: 1.5,
   ```

2. **Cap CHA gold bonus в 80% (вместо 125%):**
   ```typescript
   // BEFORE
   chaGoldBonus(CHA): max = 1.25
   // AFTER
   chaGoldBonus(CHA): max = 0.80
   ```

3. **Repair cost increase:**
   ```typescript
   // BEFORE
   BASE_COST: 80, LEVEL_MULT: 15
   // AFTER
   BASE_COST: 120, LEVEL_MULT: 20
   ```

4. **Introduce consumable sink — «Bless Weapon»:**
   - Item: `bless_weapon_scroll`
   - Cost: 500 gold (shop)
   - Effect: +10% damage для следующего боя
   - Daily limit: 3 use

**Files to change:**
1. `backend/src/lib/game/balance.ts` — все 4 правки
2. `backend/src/lib/game/items.ts` (или catalog) — добавить bless_weapon_scroll
3. `backend/src/app/api/shop/route.ts` — добавить в shop rotation
4. `backend/tests/economy/sink-ratio.test.ts` — simulation test: 1000 игроков, 30 дней, должен получиться sink ratio ≥ 50%

**Estimate:** 1.5 дня

**Acceptance criteria:**
```bash
# Simulation passes
cd backend && npm run test:economy-sim
# Expected: sink_ratio >= 0.50
```

**Risk:** **высокий.** Это ядро экономики. Обязательно:
1. Dev environment testing (24 часа)
2. Playtesting с несколькими тестерами
3. Compare pre/post metrics

**Agent:** `hexbound-studio:vault` + `hexbound-studio:ledger` + `hexbound-studio:scales`

---

### W3.D4 — BAL-02: Training XP nerf, BAL-03: Stance symmetry, BAL-04: Stamina refill DR

**BAL-02 — Training XP nerf:**
```typescript
// BEFORE
TRAINING_WIN_XP: 60
// AFTER
TRAINING_WIN_XP: 30, TRAINING_DAILY_XP_CAP: 200
```

**BAL-03 — Stance zones symmetry:**
```typescript
// BEFORE
MISMATCH_OFFENSE_BONUS: 5,
MATCH_DEFENSE_BONUS: 15,

// AFTER
MISMATCH_OFFENSE_BONUS: 12,
MATCH_DEFENSE_BONUS: 12,
```

Это даёт $\mathbb{E}[\text{net}]_\text{attacker} = \frac{2}{3} \cdot 12 + \frac{1}{3} \cdot (-12) = 4$ — атакующий теперь имеет чуть-чуть edge, что поощряет агрессию.

**BAL-04 — Stamina refill diminishing returns:**
```typescript
// BEFORE
STAMINA_REFILL: 30 // gems, flat

// AFTER
STAMINA_REFILL_COSTS: [30, 60, 120, 240] // 1st, 2nd, 3rd, 4th+ per day
```

**Files to change:**
1. `backend/src/lib/game/balance.ts` (3 места)
2. `backend/src/lib/game/xp.ts` или `progression.ts` — training daily cap logic
3. `backend/src/lib/game/combat.ts` — stance bonus values
4. `backend/src/app/api/stamina/refill/route.ts` — diminishing cost lookup
5. Prisma schema: add `staminaRefillsToday: Int @default(0)` на Character
6. Migration + sync to admin
7. Tests

**Estimate:** 1 день

**Acceptance criteria:**
```bash
# Training cap works
cd backend && npm test -- training-xp-cap

# Stance symmetry
cd backend && npm test -- stance-ev
# Expected: attacker EV positive

# Stamina DR
cd backend && npm test -- stamina-refill-dr
```

---

### W3.D5 — BAL-05: ELO tier expansion + BAL-06: BP achievement XP rework + IAP-02: Premium bundle

**BAL-05 — ELO tiers:**

| Tier | Current range | New range |
|---|---|---|
| Bronze | 0–399 | 0–399 (+ I/II/III divisions) |
| Silver | 400–799 | 400–799 (+ I/II/III) |
| Gold | 800–1199 | 800–1199 (+ I/II/III) |
| Platinum | 1200–1599 | 1200–1599 (+ I/II/III) |
| Diamond | 1600–1999 | 1600–2099 (+ I/II/III) |
| Master | 2000–2399 | 2100–2499 |
| Grandmaster | 2400+ | 2500–2899 |
| **Challenger** (NEW) | — | 2900+ (top 100 only) |

**Files:**
1. `backend/src/lib/game/balance.ts` PVP_RANKS update
2. `backend/src/lib/game/elo.ts` — tier/division calc
3. `Hexbound/Hexbound/Views/Leaderboard/LeaderboardRowView.swift` — render division badge

**BAL-06 — BP achievement XP rework:**
- Current: `BP_XP_PER_ACHIEVEMENT: 100` (one-shot lifetime)
- New: ввести **weekly rotating achievements** — 5 еженедельных челленджей, каждый даёт 150 BP XP, total 750/week, sustains BP pacing long-term.
- Files: `backend/src/lib/game/battle-pass.ts`, новый endpoint `/api/battle-pass/weekly-challenges`

**IAP-02 — Premium Forever bundle expansion:**

**New premium benefits:**
- +20 stamina cap (max 140)
- +10 inventory slots (max 68)
- +25 gems/day (auto-claimed with daily login)
- +50 gold daily login bonus (keep existing)
- +10% gold bonus on all fights
- Exclusive cosmetic title «Chosen»
- Priority queue in matchmaking (2s faster match)

**Files:**
1. `backend/src/lib/game/premium.ts` — новый или расширенный
2. `Hexbound/Hexbound/Views/Shop/PremiumPurchaseView.swift` — обновить description
3. Backend handlers для каждого benefit

**Estimate:** 2 дня (D5 + overflow to W4.D1 если нужно)

**Acceptance criteria:**
- ELO tier calculation tests pass
- Weekly BP challenges endpoint returns 5 challenges
- Premium benefits applied при premium=true

**Agent:** `hexbound-studio:arena` + `hexbound-studio:calendar` + `hexbound-studio:monetization-mirror`

---

### W3 checkpoint

- [ ] 24-hour dev playtest — 2–3 тестера, запись metrics
- [ ] Economy simulation — sink ratio ≥ 50%
- [ ] Class winrate sim — каждый класс в [45%, 55%]
- [ ] Rollback plan готов: каждая balance константа в live-config override-able
- [ ] Agent review: `hexbound-studio:strategist` + `hexbound-studio:scales` + `hexbound-studio:ledger`
- [ ] Prod deploy → Herald agent
- [ ] Commit tag: `v2026.05.01-w3-balance`

---

## 4. WEEK 4 — Polish, accessibility, verification (5 days)

**Goal:** закрыть оставшиеся medium/low, добавить accessibility, подготовить к soft launch.

### W4.D1 — DS-01: Token cleanup

Audit `DarkFantasyTheme.swift` и Figma Color collection. Найти unused semantic colors (grep по Views/ — если не упомянут → кандидат на удаление).

**Files to change:**
1. `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift` — удалить unused
2. Figma DS sync — удалить из Color collection (через `use_figma` skill)
3. Обновить `docs/07_ui_ux/DESIGN_SYSTEM.md`

**Estimate:** 4 часа

**Agent:** `hexbound-studio:blueprint` + `audit-design-system` skill

---

### W4.D1 — DS-03: CI guard против `font(size:)`

Уже есть в CDO scan, но нужно перевести в CI-blocking.

**Files:**
1. `scripts/check_font_tokens.sh` — новый или расширить существующий
2. Интеграция в `preflight_check.sh`

**Estimate:** 1 час

---

### W4.D2 — DS-02: Dynamic Type integration (WCAG 1.4.4)

**Bug:** Font tokens fixed sizes → accessibility violation.

**Approach:**
1. Обернуть каждый font token в scaling:
   ```swift
   static var title: Font {
       Font.custom("Oswald-Bold", size: 28, relativeTo: .title)
   }
   ```
2. Проверить все кастомные fonts через `UIFontMetrics.default.scaledValue(for:)`
3. Тест: iOS Accessibility > Text Size → maximum → все экраны должны оставаться читаемыми

**Files to change:**
1. `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift` — все font properties
2. Manual QA всех key screens

**Estimate:** 1 день

**Risk:** средний. Может поломать layout на экранах которые не предусматривают growth.

**Agent:** `accessibility-audit` skill + `hexbound-studio:flow`

---

### W4.D2 — BAL-07: Upgrade protection clarity

**Bug:** неясно что делает `UPGRADE_PROTECTION: 50 gems`.

**Fix:** добавить туториал popup при первой попытке upgrade с Protection toggle. Четко объяснить: «Protection: level не уменьшится при fail». Плюс визуально выделить в shop.

**Files:**
1. `Hexbound/Hexbound/Views/Inventory/UpgradeView.swift`
2. Добавить info icon с tooltip

**Estimate:** 3 часа

---

### W4.D3 — HUB-05: Hub scroll affordance

**Bug:** не очевидно что хаб скроллится.

**Fix:**
1. Edge gradient (darker на краях)
2. После 10 сек без движения → анимировать маленькую стрелку подсказку
3. Обнулять через UserDefaults после первого scroll (разовая подсказка)

**Files:**
1. `CityMapView.swift`

**Estimate:** 3 часа

---

### W4.D3 — INV-01: Inventory expansion tiers

**Bug:** 58 слотов мало.

**Fix:**
```typescript
// BEFORE
BASE_SLOTS: 28, EXPAND_AMOUNT: 10, EXPAND_COST_GOLD: 5000, MAX_EXPANSIONS: 3

// AFTER
BASE_SLOTS: 40, EXPAND_AMOUNT: 15, EXPAND_COST_GOLD: 3000, MAX_EXPANSIONS: 4
// Max: 40 + 4*15 = 100 slots
```

Плюс introduce Vault (long-term storage, 100 slots, unlock at Lv 15 via gems).

**Files:**
1. `backend/src/lib/game/balance.ts`
2. Prisma migration: add `vaultUnlocked`, `vaultItems` relation
3. New screen `VaultView.swift`
4. Sync schema

**Estimate:** 2 дня (overflow to W4.D4)

---

### W4.D4 — IAP-01: Whale curve optimization

**Fix:** увеличить discount на top packs:
```typescript
gems_small: 100, $0.99    // $0.0099/gem (0% discount — baseline)
gems_medium: 600, $4.99   // $0.0083/gem (16% discount) ← was 550
gems_large: 1400, $9.99   // $0.0071/gem (28% discount) ← was 1200
gems_huge: 3100, $19.99   // $0.0064/gem (35% discount) ← was 2500
gems_mega: 8500, $49.99   // $0.0059/gem (41% discount) ← was 6500
```

**Files:**
1. `backend/src/lib/game/balance.ts` IAP_PRODUCTS
2. iOS StoreKit product descriptions
3. App Store Connect — обновить product amounts (external action)

**Estimate:** 4 часа (backend/iOS) + external App Store work

---

### W4.D5 — Full re-playthrough + soft launch prep

1. Полный прогон всех fixes — повторить онбординг, хаб, Hero, 3 боя, Daily Login claim
2. Screenshot regression check: сравнить key screens с pre-fix baseline
3. Performance check: FPS > 55 на all screens
4. Crash-free session: 30 минут игры без crash
5. Final CDO scan — clean
6. Release notes drafted
7. Tag: `v2026.05.08-w4-polish`
8. Beta submission

**Agent:** `hexbound-studio:gauntlet` + `hexbound-studio:shield` + `hexbound-studio:gate`

---

## 5. Dependency graph (critical path)

```
W1.D1  CRIT-01 ─┐
W1.D1  CRIT-04 ─┤
W1.D2  CRIT-02 ─┼─→ W1.D3  GameConfig SSoT ─→ W1.D4  docs:balance ─→ W1.D5  CI guards
W1.D2  CRIT-03 ─┘         ↓
                          W2.D1  gender+appearance merge
                          W2.D2  welcome cinematic + guest
                          W2.D3  TUTORIAL FIGHT (critical path, 2 days) ←── longest
                                 ↓
                          W2.D4  hub gating
                          W2.D5  today's goals + badge hierarchy + daily login timing
                                 ↓
                          W3.D1  CHA redesign
                          W3.D2  AGI restore
                          W3.D3  SINK RATIO rebalance (high risk, 1.5 days)
                          W3.D4  training XP + stance + stamina DR
                          W3.D5  ELO + BP + premium
                                 ↓
                          W4.D1  DS cleanup + font CI
                          W4.D2  Dynamic Type + upgrade clarity
                          W4.D3  scroll affordance + inventory tiers
                          W4.D4  whale curve
                          W4.D5  FINAL VERIFY + release tag
```

**Critical path:** W2.D3 TUTORIAL FIGHT и W3.D3 SINK RATIO — самые рискованные и длинные tasks. Если slip — двигаем W4.D5 на неделю.

**Parallelizable:** W1.D4 docs autogen можно делать параллельно с W1.D5. W4.D1 и W4.D2 независимы.

---

## 6. Risk register

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Tutorial fight scope creep (Week 2) | High | High | Hard cut — scripted only, no dynamic. If overflow → cut hint overlay, keep fight + scripted win + reward. |
| Sink ratio rebalance breaks live economy | Medium | Critical | Dev environment 24h playtesting + rollback через live-config toggle. Deploy только после тестирования. |
| Prisma migration fails on prod DB | Low | High | Staging run перед prod. Backup DB dump перед migration. |
| GameConfig SSoT breaks iOS boot if API down | Medium | High | Aggressive caching: last known GameConfig saved в UserDefaults. Fallback на hardcoded defaults в AppConstants с «LAST RESORT» пометкой. |
| Dynamic Type breaks layouts на small screens | Medium | Medium | Per-screen manual QA. Constraints: `minimumScaleFactor` там где layout критичен. |
| Tester bandwidth — не успеем 24h playtest | High | Medium | Pre-schedule тестеров. Automated simulation покрывает 70% cases. |

---

## 7. Success metrics

### 7.1 Технические (must-pass)
- [ ] 0 хардкодов game constants в iOS AppConstants (только UI constants)
- [ ] `balance.ts` ↔ `BALANCE_CONSTANTS.md` auto-synced
- [ ] CI gates: hardcode detector, font(size:) detector, scale animation detector — all active
- [ ] Prisma schema: backend ↔ admin identical (diff empty)
- [ ] CDO scan clean на каждом commit
- [ ] Crash-free session ≥ 30 min

### 7.2 Gameplay balance (simulation)
- [ ] Sink ratio: 50–65% (target Economy v2 goal)
- [ ] Class winrates: все в [45%, 55%]
- [ ] Rogue PvP winrate: ≥ 48% (class не discriminated)
- [ ] Stance EV attacker: positive (≥ +2)

### 7.3 UX / retention (hypothesis)
- [ ] Onboarding screens к первому бою: ≤ 7
- [ ] Time to first fight: ≤ 3 мин
- [ ] D1 retention (hypothesis): +15% relative to baseline
- [ ] Buildings unlocked at Lv 1: ≤ 3 (no overload)

### 7.4 Documentation / maintainability
- [ ] Every new file has pbxproj entry (4 sections)
- [ ] Every Figma component change has Swift mirror
- [ ] CLAUDE.md updated with 8-stat list (STAT-01 fix)

---

## 8. TodoList sync

Этот план синхронизируется с in-conversation TodoList (один фикс = один todo). Claude обновляет todo status после каждой итерации.

Структура todo: `W{N}.D{N} — {BUG-ID}: {short title}` — позволяет видеть прогресс по неделям.

---

## 9. Post-launch monitoring

После release (W4.D5 tag):
1. Set up metrics dashboard: sink ratio, class winrate, D1 retention, crash-free rate
2. Daily check first 7 days — если metric drops → revert через live-config
3. Weekly: fetch data → `hexbound-studio:lens` agent review
4. Monthly: balance patch cycle → back to Week 3 protocol

---

**Подпись:** Claude, 2026-04-10
**Next action:** после approve этого плана — начать с **W1.D1 CRIT-01 (FREE_PVP_PER_DAY drift fix)**. Прочитаю точные файлы, покажу diff, дождусь approve, commit через git-trigger.
