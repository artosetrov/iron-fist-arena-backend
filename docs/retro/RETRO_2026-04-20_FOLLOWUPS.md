# Retro 2026-04-20 — Follow-up Audit

Выполнение двух задач из раздела «На следующий ретро» файла
`docs/retro/RETRO_2026-04-20.md`. Этот документ — только аудит, без
кодовых изменений.

---

## Task 1: FK-safe split audit по combat-routes (oracle §11d)

**Пул:** все `.ts` под `backend/src/app/api` с упоминанием
`winnerId|loserId|winner_id|loser_id` (17 файлов).

### Prisma writes на `pvp_matches` — проверены все 5 сайтов

| Файл / строки | Поведение | Вердикт |
|---|---|---|
| `pvp/match/complete/route.ts:457-458` | Сегодняшний fix: `winnerId: winnerCharacterId` + `loserId: loserCharacterId` со split на FK-safe пару. | ✅ safe |
| `pvp/match/start/route.ts:401-402` | На создании матча пишет `winnerId: null, loserId: null`. | ✅ safe |
| `pvp/revenge/[id]/route.ts:232-233` | `attacker` и `defender` оба загружаются через `prisma.character.findUnique` с 404-guard (линия 97-99). Revenge физически не может быть против бота. | ✅ safe |
| `characters/[id]/route.ts:113-114` | Cascade на удалении персонажа: `updateMany({ where: { winnerId: id }, data: { winnerId: null } })`. | ✅ safe |
| `pvp/resolve/route.ts:747-763` | Legacy bot-fight создаёт `pvp_matches` c `player2Id: attacker.id`, `winnerId: attacker.id`, `loserId: attacker.id` — self-reference hack. | ⚠️ **legacy-bug** |

### ⚠️ Legacy finding: `pvp/resolve/route.ts:747-763`

```ts
const pvpMatch = await tx.pvpMatch.create({
  data: {
    player1Id: attacker.id,
    player2Id: attacker.id,        // self-reference hack
    ...
    winnerId: attacker.id,          // attacker записан И как winner
    loserId:  attacker.id,          // И как loser одновременно
    ...
    matchType: 'bot',
  },
})
```

**Контекст:**
- `/api/pvp/resolve` всё ещё активно вызывается из `BattlePreloader.resolve()` в iOS (`Hexbound/Services/BattlePreloader.swift:438`) — это классический (non-interactive) combat-путь.
- Self-reference был написан ДО миграции 2026-04-19 (`ed3001d`), которая сделала `player2Id` / `winnerId` / `loserId` nullable.
- FK не нарушается (везде реальный `attacker.id`), поэтому это не падающий прод. Но:
  - Любой запрос, который агрегирует W/L по `winnerId` / `loserId` без фильтра по `matchType`, получит бот-бои, где attacker засчитан И в winners И в losers.
  - Admin `/matches` и leaderboard-агрегации → вероятный источник расхождений.

**Рекомендация (follow-up, не менять в рамках ретро):** привести к современному паттерну
```ts
player2Id: null,
winnerId: attackerWon ? attacker.id : null,
loserId:  attackerWon ? null : attacker.id,
```
Плюс перед правкой — grep админ-запросов и аналитических агрегаций на то, переживут ли они NULL-winnerId и одностороннюю запись.

### Read-only / response-only сайты (угрозы для DB нет)

12 других файлов (`strike`, `fight`, `history`, `dungeons/fight`,
`dungeon-rush/fight`, `tutorial/scripted-fight/resolve`, `social/*`,
`session-summary`, `dev/tests`, `admin/matches`) содержат `winnerId` /
`loserId` либо в JSON-ответе iOS, либо в `select` для чтения. Ни одного
write-сайта на `pvp_matches` среди них нет.

---

## Task 2: Аудит идемпотентных сидов для static-catalog таблиц

**Критерий §6c gatekeeper:** static-catalog должен иметь ПАРУ —
`.sql` миграция с `ON CONFLICT ... DO NOTHING` (для prod/staging) +
`seed-*.ts` с `upsert` (для local / CI).

| Таблица | `seed-*.ts` | `.sql` миграция | Статус |
|---|---|---|---|
| `appearance_skins` | ✅ `seed-appearances.ts` | ✅ `20260420_seed_appearance_skins` | **complete** (сегодня) |
| `consumable_items` | — | ✅ `20260320_seed_consumable_items` | half — нужен `seed-consumable-items.ts` для dev |
| `game_config` (balance constants) | ✅ `seed-balance.ts` | ❌ отсутствует | **GAP** |
| `battle_pass_rewards` + `seasons` | ✅ `seed-battle-pass.ts` | ❌ отсутствует | **GAP** |
| `dungeon_drops` | ✅ `seed-dungeon-drops.ts` | ❌ отсутствует | **GAP** |
| `dungeons` | ✅ `seed-dungeons.ts` | ❌ отсутствует | **GAP** |
| `users.role='admin'` | — | — | не catalog; нужна отдельная re-apply script (Degon 2026-04-19) |

### Шкала риска

| Таблица | Что ломается при пустой таблице | Priority |
|---|---|---|
| `game_config` | Combat-формулы читают конфиги через `getStaminaConfig() / getGoldRewardsConfig() / ...`; при отсутствии — дефолты из кода, но balance расходится с админкой; admin-панель показывает пустой list. | P0 |
| `battle_pass_rewards` / `seasons` | Battle Pass-экран пустой, `claim` возвращает 400; live-season freeze. | P0 |
| `dungeon_drops` | Dungeon-win даёт XP/gold, но loot — пусто; тихая регрессия. | P1 |
| `dungeons` | Hub / Dungeon-select список пустой; блокирует весь PvE-путь. | P0 |

### Отдельно: admin-role re-apply (Degon 2026-04-19)

`users.role='admin'` — не catalog, а per-user стейт. Снапшот-рестор
откатывает одного-двух админов в `player`. Нужен **НЕ** seed, а
post-restore script:

```sql
-- scripts/restore-admin-roles.sql (proposed)
UPDATE users SET role='admin' WHERE email IN (
  'osetrov.artem@gmail.com',
  -- добавлять админов сюда, в git
);
```

Этот файл не должен лежать в `migrations/` (не идемпотентен по схеме), а
быть runbook-артефактом под `scripts/` и упомянут в post-restore checklist
§6c gatekeeper.

---

## Рекомендованные follow-up (не выполнять в рамках этой сессии)

1. **P0** Создать `20260421_seed_balance_constants/migration.sql` + обновить `seed-balance.ts` ссылкой на миграцию как source-of-truth-mirror. Объём: ~10-20 `INSERT ... ON CONFLICT`-строк (каждая — одна `key` из `BALANCE_CONFIGS`).
2. **P0** Создать `20260421_seed_battle_pass_season/migration.sql` + обновить `seed-battle-pass.ts`. Объём: большой (~90 reward rows), нужно аккуратно сохранить `BATTLE_PASS_MILESTONE_CATALOG_IDS` маппинг.
3. **P0** Создать `20260421_seed_dungeons/migration.sql` — 7 GDD-dungeons + abilities catalog. Блокирующий для PvE, если случится ещё один snapshot-restore.
4. **P1** Создать `20260421_seed_dungeon_drops/migration.sql` — drop-tables per dungeon.
5. **Добавить** `scripts/restore-admin-roles.sql` — known-admins re-apply list + reference в gatekeeper §6c.
6. **Долг (Task 1):** модернизировать `pvp/resolve/route.ts` self-reference hack — убрать двойной счёт winner/loser в bot-fight статистике. Перед правкой grep agg-запросов в `admin/` и `analytics/`.

---

## Итог двух задач

- **Task 1:** combat-routes проверены, один legacy-bug найден (`pvp/resolve` self-reference). FK-нарушений больше нет. Oracle §11d grep-шаблон работает и сигналит, что нужно дальше смотреть семантику bot-matches.
- **Task 2:** 4 static-catalog таблицы без идемпотентной `.sql` миграции. Это пятый возможный repeat того же incident class, если случится ещё один snapshot-restore. Полный план follow-up выше — готов начать с §1 (balance_constants), если дашь добро.
