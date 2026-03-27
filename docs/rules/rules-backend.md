# Rules: Backend / TypeScript / Next.js

> **Домен:** Весь код в `backend/`
> **Когда читать:** Работа с API endpoints, game logic, services
> **НЕ покрывает:** iOS UI, Admin panel UI, Deploy

---

## TypeScript Strict Mode

- **Strict null checks:** `T | null` → всегда narrow перед использованием
- **`ignoreBuildErrors` УДАЛЁН** — TS ошибки блокируют Vercel deploy
- **`prisma generate` перед `tsc`/`next build`** — без него TS не видит Prisma модели

## Async Functions (CRITICAL)

- **Все `get*Config()` в `live-config.ts` — async.** Всегда `await`.
- **`runCombat()` — async.** Всегда `await runCombat(attacker, defender)`.
- **`calculateCurrentStamina()` — 3 аргумента** (currentStamina, maxStamina, lastUpdate). НЕ 4.
- **`StaminaResult` = `{ stamina: number; updated: boolean }`** — `.stamina`, НЕ `.current`.
- **`CombatResult` fields:** `winnerId`, `loserId`, `turns`, `totalTurns`, `finalHp`. НЕТ `.log`, `.duration`.

**Перед использованием функции — ПРОВЕРЬ сигнатуру в исходнике.** Или копируй паттерн из `pvp/fight/route.ts`.

## Error Handling (CRITICAL)

- **Каждый API route handler ОБЯЗАН оборачивать body в try/catch**
- **Не логировать PII:** email, password, token, key, secret
- **Безопасно логировать:** userId, characterName, request path, error code

## Economy Routes — TOCTOU Prevention

- **Все purchase routes — validate limits ВНУТРИ `$transaction`**, не до
- **Используй `SELECT FOR UPDATE` row lock + `Serializable` isolation**
- Иначе: race condition → двойная покупка

## Atomic Increments

- **НЕ read-then-write.** Используй `$executeRawUnsafe('UPDATE ... SET progress = LEAST(progress + $1, target)')`
- Применяется к: daily quest progress, achievement counters, любые инкременты

## N+1 Prevention

- **Никогда не вызывай DB/config внутри циклов**
- Config lookups → загрузи в Map перед циклом
- Related records → `findMany({ where: { id: { in: ids } } })` + Map lookup

## Prisma Json Fields

- Приведение Json к конкретному типу: `as unknown as OfferContent[]` (double cast)
- Для InputJsonValue: `(value ?? Prisma.JsonNull) as unknown as Prisma.InputJsonValue`

## File Naming

- **Никогда не создавай файлы с пробелами или " 2" в имени** — это junk copies macOS

## Achievements

- Каталог: `backend/src/lib/game/achievement-catalog.ts`
- Tracking: `backend/src/lib/game/achievements.ts`
- `absolute: true` для streaks/ratings/levels (set, не increment)
- **Не добавляй achievement без tracking call** — будет 0/N навсегда

## Game Enums (VERIFY)

- CharacterClass: `warrior`, `rogue`, `mage`, `tank`
- CharacterOrigin: `human`, `orc`, `skeleton`, `demon`, `dogfolk`
- ItemRarity: `common`, `uncommon`, `rare`, `epic`, `legendary`
- QuestType: `pvp_wins`, `dungeons_complete`, `gold_spent`, `item_upgrade`, `consumable_use`, `shell_game_play`, `gold_mine_collect`
