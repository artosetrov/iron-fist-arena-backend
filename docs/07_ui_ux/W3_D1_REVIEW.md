# W3.D1 — Recon & Review (review BEFORE code)

**Автор:** Claude (orchestrator)
**Дата:** 2026-04-10
**Скоуп:** W3 Balance adjustments (5 дней) — pre-implementation recon
**Статус:** 🔍 Review — требуется выбор Артёма перед любой имплементацией

---

## Зачем этот документ

Правило `feedback_review_before_code.md`: сначала отчёт + варианты, потом код. Как и для W2, я снял реальный срез `backend/src/lib/game/balance.ts`, `combat.ts`, `skills.ts`, `elo.ts`, `premium.ts`, схемы Prisma и `backend/tests/` — и сверил с тем, что написано в `QA_FIX_PLAN_2026-04-10.md` (строки 896–1180).

В отличие от W2 (где половина задач уже была закрыта), W3 — это **настоящий баланс-спринт с нуля**. Большинство констант совпадает с тем, что план считает "BEFORE", то есть работа действительно есть. Но есть нюансы в формулировках и несколько опасных мест, которые я хочу обсудить до того, как тронем экономику.

---

## TL;DR

| Day | Задача | Reality | Verdict |
|---|---|---|---|
| **W3.D1** — STAT-02 CHA redesign | План: `Intimidation miss chance` + Taunt skill | `CHA_INTIMIDATION_PER_POINT = 0.25` — это **damage reduction**, а не miss chance. `chaGoldBonus` cap 125%. `skills.ts` — статическая система без active-skill runtime. Taunt потребует новый layer | 🟡 **Валидно, но "Taunt" — большая работа** (новая подсистема active skills). Miss chance сам по себе — 2 часа. |
| **W3.D2** — STAT-03 AGI restore + Execute | План: partial restore + Rogue execute bonus <35% HP | Все 4 константы совпадают с "BEFORE" плана. `DODGE_PER_LUK: 0.1` уже добавлен — план о нём не знает. Execute bonus в combat.ts отсутствует | ✅ **Валидно.** 4 часа как в плане. Нужен sim для winrate 48–52%. |
| **W3.D3** — BAL-01 Sink ratio | План: cap streaks, CHA gold 80%, repair 120/20, bless_weapon_scroll, sim test | `WIN_STREAK_BONUSES/LOSS_STREAK_BONUSES` — **таблицы lookup**, не плоские константы как в плане. `REPAIR_COSTS.PER_LEVEL` (не LEVEL_MULT). `chaGoldBonus` — piecewise функция, не константа. **Нет `backend/tests/economy/sink-ratio.test.ts`.** Нет `bless_weapon_scroll`. | 🟡 **Валидно, но план врёт об именах констант.** Симулятор экономики надо написать с нуля. Самый рискованный день. |
| **W3.D4** — BAL-02/03/04 training/stance/stamina | План: TRAINING_WIN_XP 30+cap, stance 12/12, stamina DR [30,60,120,240], `staminaRefillsToday` в Prisma | `TRAINING_WIN_XP: 60` ✓ (BEFORE). `MISMATCH_OFFENSE_BONUS: 5`, `MATCH_DEFENSE_BONUS: 15` ✓ (BEFORE). `STAMINA_REFILL: 30` ✓ (BEFORE, одна flat цена). **`staminaRefillsToday` отсутствует в Prisma** — нужна миграция | ✅ **Валидно.** Чистый 1 день. Единственная Prisma-миграция во всём W3. |
| **W3.D5** — BAL-05 ELO + BAL-06 BP + IAP-02 Premium | План: Challenger tier, weekly BP challenges, premium +20 stamina/+10 slots/+25 gems/day | `PVP_RANKS` уже другие (SILVER 1200 не 400) — план **использует устаревшие пороги**. `BP_XP_PER_ACHIEVEMENT: 100` ✓. Нет `premium.ts`, нет weekly-challenges endpoint | ⚠️ **Валидно, но план ELO-тиров не соответствует реальности.** Нужна сверка с Артёмом: раскатываем ли Challenger поверх текущих 1200/1500/1800/2100/2400, или переделываем всю сетку. |

**Bottom line:** из 5 дней W3 **0 уже сделано**, **3 валидны как есть** (D2, D4, D5 частично), **2 требуют пересмотра формулировок** (D1 Taunt, D3 имена констант + simulator). Никаких "уже сделано" — это настоящая неделя работы.

---

## Детальные находки

### 1. W3.D1 — STAT-02 CHA redesign

**Что говорит план:**
$$
P_\text{enemy miss} = \min(0.005 \cdot \text{CHA}, 0.10)
$$
+ Taunt active skill (20 stamina, forces enemy to attack).

**Что в коде** (`backend/src/lib/game/balance.ts:181–183`):

```typescript
// CHA intimidation: reduces enemy damage by 0.25% per CHA point (max 25%)
CHA_INTIMIDATION_PER_POINT: 0.25,
CHA_INTIMIDATION_CAP: 25,
```

И в `combat.ts:260–262`:

```typescript
/** CHA intimidation: attacker's CHA reduces defender's outgoing damage. */
function chaIntimidationReduction(attackerCha: number, config: CombatConfig): number {
  return Math.min(attackerCha * config.CHA_INTIMIDATION_PER_POINT, config.CHA_INTIMIDATION_CAP) / 100;
}
```

**Нюанс 1 — "Intimidation" уже существует, но это damage reduction, не miss.** План предлагает **добавить** miss chance *в дополнение* к текущей intimidation. Если так — CHA становится **двухслойной**: каждое очко даёт и -0.25% урона врага, и +0.5% его miss. Это может дать нежелательный стек (`E[damage] = (1-0.10) \cdot 0.75 = 0.675` — -32.5% total на cap). Нужно подтвердить: **add или replace**?

**Нюанс 2 — Taunt active skill.** В `skills.ts` (139 строк) сейчас только система **пассивных навыков по кулдауну**:

```typescript
export interface SkillDefinition {
  skillKey: string
  damageBase: number
  damageScaling: Record<string, number> | null
  targetType: 'single_enemy' | 'self_buff' | 'aoe'
  cooldown: number
  // ...
}
```

Это **damage skill system**, не active ability. "Forces enemy to attack you" и "снижает damage next attack на 30%" — это **новые типы эффектов**:
- `force_aggro` (PvE taunt)
- `debuff_next_attack` (PvP)

Ни того, ни другого в `targetType` enum нет. Добавление потребует новый layer — `effectJson` schema, combat loop reads, описание в UI. Это **не 4 часа, а ближе к 1.5 дня**.

**Нюанс 3 — UI.** `Hexbound/Hexbound/Views/Profile/StatusView.swift` уже показывает CHA tooltip с формулой intimidation. Надо будет обновить. Нет ничего сложного, но это +1 файл iOS в pbxproj если добавляем константу.

**Варианты:**

| Опция | Что делаем | Срок | Риск |
|---|---|---|---|
| **A — мини** | Только miss chance (заменяет intimidation) + обновить tooltip | 3 часа | Низкий |
| **B — дополняет** | Miss chance в **дополнение** к intimidation + tooltip | 4 часа | Средний (двойной buff) |
| **C — полный план** | Miss chance + Taunt active skill (новый effect layer) | 1.5 дня | Высокий (новая подсистема) |
| **D — split** | Miss chance сейчас, Taunt вынести в W4 или отдельный спринт | 3 часа сейчас | Низкий |

**Моя рекомендация: D.** Miss chance даёт CHA реальный выбор уже на D1, Taunt как новая подсистема заслуживает отдельного дизайн-документа (interaction с PvP matchmaking, AI priority, UI indication). Не мешать в один день.

---

### 2. W3.D2 — STAT-03 AGI partial restoration + Execute

**Что говорит план:**

```typescript
// BEFORE
CRIT_PER_LUK: 0.7, CRIT_PER_AGI: 0.15, DODGE_PER_AGI: 0.2, ROGUE_DODGE_BONUS: 3,
// AFTER
CRIT_PER_LUK: 0.6, CRIT_PER_AGI: 0.2, DODGE_PER_AGI: 0.2, ROGUE_DODGE_BONUS: 4,
```
+ Rogue Execute: +15% damage vs enemies <35% HP.

**Что в коде** (`balance.ts:172–180`):

```typescript
ROGUE_DODGE_BONUS: 3,         // rogues get +3% dodge (was 5)
// ...
CRIT_PER_LUK: 0.7,            // was 0.5 — LUK is now the primary crit stat
CRIT_PER_AGI: 0.15,           // was 0.3 — AGI crit contribution halved
DODGE_PER_AGI: 0.2,           // was 0.3 — dodge slightly nerfed
DODGE_PER_LUK: 0.1,           // NEW — LUK adds minor dodge
```

**Хорошая новость:** все 4 "BEFORE" константы совпадают с кодом. План корректен.

**Нюанс 1 — `DODGE_PER_LUK: 0.1` план не видел.** Это новая константа, добавленная после написания плана. Если мы делаем partial restore AGI, LUK всё ещё даёт `0.1` dodge — итоговая dodge formula становится `totalDodge = agi*0.2 + luk*0.1 + classBonus`. Надо решить: оставляем `DODGE_PER_LUK` или откатываем? Я бы оставил — это минорный вклад, не ломает тематику.

**Нюанс 2 — Execute bonus.** В `combat.ts` нет ничего похожего на execute. Это значит добавляем ~10 строк в damage calc + новый test. Чисто.

**Нюанс 3 — симуляция Rogue vs Warrior.** План требует winrate 48–52%. У меня нет инструмента для batch-симуляций (его надо написать или использовать существующие unit-тесты). Надо уточнить: **писать симулятор или проверяем аналитически?**

**Варианты:**

| Опция | Что делаем | Срок |
|---|---|---|
| **A — план как есть** | 4 константы + Execute + unit test + оставить `DODGE_PER_LUK` | 4 часа |
| **B — с симулятором** | То же + batch sim (1000 fights) для reporting | 6 часов |
| **C — откатить `DODGE_PER_LUK`** | Полное возвращение к "pure AGI dodge" парадигме | 5 часов |

**Моя рекомендация: A.** Симулятор нужен для W3.D3, не D2. Формулу Rogue можно проверить аналитически через EV. Сохраняем `DODGE_PER_LUK` как минор.

---

### 3. W3.D3 — BAL-01 Sink ratio rebalance (🔴 HIGH RISK)

**Это самый опасный день W3.** План говорит 1.5 дня. Я думаю — ближе к 2 дням из-за отсутствия инструментов.

**Что говорит план:**

1. Cap streak multipliers: `WIN_STREAK_3: 1.2 → 1.15`, etc (плоские константы).
2. CHA gold bonus cap: `1.25 → 0.80`.
3. Repair: `BASE_COST 80 → 120`, `LEVEL_MULT 15 → 20`.
4. New consumable `bless_weapon_scroll` (500g, +10% dmg, daily limit 3).

**Реальность — расхождения:**

**3.1 Streaks — это таблицы lookup, не плоские константы.**

```typescript
// balance.ts:258–263
export const LOSS_STREAK_BONUSES: readonly number[] = [
  0, 0, 0, 0.3, 0.3, 0.5, 0.5, 0.8, 0.8, 0.8, 0.8,
];
// balance.ts:272–275
export const WIN_STREAK_BONUSES: readonly number[] = [
  0, 0, 0, 0.2, 0.2, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0,
];
```

Соответствие плану:

| План | Код | Действие |
|---|---|---|
| `WIN_STREAK_3: 1.2` (1.20 = +20%) | `WIN_STREAK_BONUSES[3] = 0.2` (+20%) ✓ | Поменять на `0.15` |
| `WIN_STREAK_5: 1.5` | `WIN_STREAK_BONUSES[5] = 0.5` ✓ | `→ 0.3` |
| `WIN_STREAK_8: 2.0` | `WIN_STREAK_BONUSES[8] = 1.0` ✓ | `→ 0.5` |
| `LOSS_STREAK_3: 1.3` | `LOSS_STREAK_BONUSES[3] = 0.3` ✓ | `→ 0.2` |
| `LOSS_STREAK_5: 1.5` | `LOSS_STREAK_BONUSES[5] = 0.5` ✓ | `→ 0.35` |
| `LOSS_STREAK_7: 1.8` | `LOSS_STREAK_BONUSES[7] = 0.8` ✓ | `→ 0.5` |

План и код соответствуют через `multiplier = 1 + bonus`. ОК, просто правим индексы таблицы.

**3.2 CHA gold bonus — piecewise функция, не константа.**

```typescript
// balance.ts:242–254
export function chaGoldBonus(baseGold: number, cha: number): number {
  let bonus = 0;
  if (cha <= 30)       bonus = cha * 0.025;
  else if (cha <= 60)  bonus = 30 * 0.025 + (cha - 30) * 0.01;
  else                 bonus = 30 * 0.025 + 30 * 0.01 + (cha - 60) * 0.005;
  bonus = Math.min(bonus, 1.25);
  return Math.floor(baseGold * (1 + bonus));
}
```

План хочет cap 0.80 (80%). Правится одной строкой `Math.min(bonus, 0.80)`. Но:
- При текущей схеме 30 CHA даёт уже +75%, то есть cap 80% достигается на **32 CHA**. Это значит **bonus curve труба** — все 60+ CHA кучно у cap, нет смысла качать выше 32. Надо либо уменьшать tiers, либо просто ставить cap и принимать "CHA useful до 32".
- Я бы **пересмотрел всю piecewise функцию** под новый cap, не только Math.min.

**Предложение:**

```typescript
// Re-scaled with 80% cap, useful across all levels
if (cha <= 20)       bonus = cha * 0.02;                       // +2% per point, max +40%
else if (cha <= 40)  bonus = 0.40 + (cha - 20) * 0.015;        // +1.5% per point, max +70%
else                 bonus = 0.70 + (cha - 40) * 0.005;        // +0.5% per point, max +80% at 60
bonus = Math.min(bonus, 0.80);
```

Нужно согласие Артёма — это дизайн-решение, не механическое.

**3.3 Repair — имя константы неправильное в плане.**

```typescript
// balance.ts:289–299
export const REPAIR_COSTS = {
  BASE_COST: 80,
  PER_LEVEL: 15,   // не LEVEL_MULT, как в плане
  RARITY_MULTIPLIERS: { common: 1.0, uncommon: 1.5, rare: 2.0, epic: 3.0, legendary: 5.0 },
}
```

Изменения тривиальны: `BASE_COST: 80 → 120`, `PER_LEVEL: 15 → 20`. Проверить что нет drift-docs которые ссылаются на `LEVEL_MULT`.

**3.4 Bless Weapon Scroll — отсутствует полностью.**

Нужно:
1. Добавить в shop catalog (или ручное создание в `prisma/seed.ts`)
2. Effect logic: прокидывать `+0.10` damage multiplier в combat для next fight
3. Daily limit 3: нужно хранить `blessWeaponScrollsToday: Int` на Character? Или через отдельную таблицу `DailyUsage`?
4. UI: display в inventory, UI кнопка "использовать перед боем"

Это **мини-фича**, не просто константа. ~4-6 часов.

**3.5 Sink ratio simulator — НЕ СУЩЕСТВУЕТ.**

```bash
$ find backend/tests -name "*sink*" -o -name "*economy-sim*"
# empty
```

План требует `backend/tests/economy/sink-ratio.test.ts` — simulation test: 1000 игроков, 30 дней, sink ratio ≥ 50%. Это **отдельная работа на несколько часов** (модель игрока, распределение времени, гонка всех sources/sinks, агрегация).

**Варианты W3.D3:**

| Опция | Что делаем | Срок | Риск |
|---|---|---|---|
| **A — полный план** | Streaks + CHA + Repair + BlessScroll + Simulator + dev playtest | 2 дня | Высокий |
| **B — без scroll** | Streaks + CHA + Repair + Simulator (scroll в W4) | 1.5 дня | Средний |
| **C — без sim** | Streaks + CHA + Repair + BlessScroll, sim как отдельный checkpoint | 1 день + sim 0.5 дня | Средний |
| **D — минимум** | Только streaks + CHA + Repair. Без scroll, без sim. Analitycal check | 4 часа | Средний, но проверка слабее |

**Моя рекомендация: B.** Scroll — новая фича, она не про "rebalance". Но sim **обязателен** — это наш единственный способ убедиться что мы не переломали экономику. Playtest с Артёмом и 2 тестерами по 24 часа как в чеклисте — отдельный шаг.

---

### 4. W3.D4 — BAL-02/03/04 training, stance, stamina

**Что говорит план:**

- `TRAINING_WIN_XP: 60 → 30` + новый `TRAINING_DAILY_XP_CAP: 200`
- `MISMATCH_OFFENSE_BONUS: 5 → 12`, `MATCH_DEFENSE_BONUS: 15 → 12`
- `STAMINA_REFILL: 30 → STAMINA_REFILL_COSTS: [30, 60, 120, 240]`
- Prisma: `staminaRefillsToday: Int @default(0)` на Character

**Реальность:** все "BEFORE" совпадают.

```typescript
// balance.ts
TRAINING_WIN_XP: 60,               // line 44
MISMATCH_OFFENSE_BONUS: 5,         // line 214
MATCH_DEFENSE_BONUS: 15,           // line 215
STAMINA_REFILL: 30,                // line 337
```

**Нюанс 1 — `staminaRefillsToday` отсутствует в Prisma.**

```bash
$ grep "staminaRefills\|refillsToday" backend/prisma/schema.prisma
# empty
```

Нужна миграция:
```prisma
model Character {
  // ... existing
  staminaRefillsToday Int @default(0) @map("stamina_refills_today")
  staminaRefillsResetAt DateTime @default(now()) @map("stamina_refills_reset_at")
}
```

**+ reset logic** — когда именно обнуляется счётчик? Daily cron? Lazy reset при следующем refill запросе? Я бы делал lazy: `if now > resetAt + 24h → reset to 0`. Это избегает cron.

+ copy schema → `admin/prisma/schema.prisma` + migration + commit обоих.

**Нюанс 2 — training daily cap.** Нужна логика "сегодня уже получил 200 XP → даём 0". Это либо `trainingXpToday` field на Character (ещё одно поле Prisma), либо событийный лог. План говорит "training daily cap" но не уточняет хранилище. Предложение: поле на Character `trainingXpToday: Int @default(0)` + lazy reset как у stamina.

Итого Prisma: **2 новых поля + 2 reset timestamp**. Одна миграция, всё в одном дне.

**Варианты:**

| Опция | Что делаем | Срок |
|---|---|---|
| **A — план как есть** | 2 Prisma поля + 3 const правки + lazy reset + tests | 1 день |
| **B — с cron** | То же, но reset через cron (чище, но больше кода) | 1 день + 2 часа |

**Моя рекомендация: A.** Lazy reset проще, тестируемо, не требует инфраструктуры.

---

### 5. W3.D5 — BAL-05 ELO + BAL-06 BP + IAP-02 Premium

**Самый большой день** — 3 фичи, план оценивает 2 дня с overflow в W4.D1.

**5.1 BAL-05 ELO tiers — план использует устаревшие пороги.**

План:

| Tier | План "BEFORE" | План "AFTER" |
|---|---|---|
| Bronze | 0–399 | 0–399 (+ I/II/III) |
| Silver | 400–799 | 400–799 |
| Gold | 800–1199 | 800–1199 |
| Platinum | 1200–1599 | 1200–1599 |
| Diamond | 1600–1999 | 1600–2099 |
| Master | 2000–2399 | 2100–2499 |
| Grandmaster | 2400+ | 2500–2899 |
| **Challenger** (NEW) | — | 2900+ |

**Реальность** (`balance.ts:156–163`):

```typescript
export const PVP_RANKS = {
  BRONZE: 0,
  SILVER: 1200,
  GOLD: 1500,
  PLATINUM: 1800,
  DIAMOND: 2100,
  GRANDMASTER: 2400,
};
```

То есть:

| Rank | Реальный threshold |
|---|---|
| Bronze | 0–1199 |
| Silver | 1200–1499 |
| Gold | 1500–1799 |
| Platinum | 1800–2099 |
| Diamond | 2100–2399 |
| Grandmaster | 2400+ |

**6 уровней, не 7. Нет Master. Пороги совершенно другие.** План был написан на другой снимок или это архитектурная фантазия. Надо решать:

**Варианты 5.1:**

| Опция | Что делаем |
|---|---|
| **A — план как есть** | Полностью переделать `PVP_RANKS` под 8-tier сетку плана (Bronze/Silver/Gold/Platinum/Diamond/Master/Grandmaster/Challenger) с divisions I/II/III |
| **B — инкремент** | Оставить текущие 6 tiers, добавить **Challenger** выше Grandmaster (например `CHALLENGER: 2700`) и I/II/III divisions внутри |
| **C — только Challenger** | 6 текущих tiers + Challenger 2700+, без divisions |

**Моя рекомендация: B.** Разбивать каждый существующий tier на 3 divisions — понятный inкремент. "Challenger 2700+ top-N" — отдельная проверка (нужен server-side leaderboard rank). Полная перекройка (A) — слом всех текущих игроков, которые уже в своих tiers.

**Нужно согласие Артёма на A/B/C.**

**5.2 BAL-06 Weekly BP challenges.**

Текущий `BP_XP_PER_ACHIEVEMENT: 100` — one-shot. План предлагает **weekly rotating achievements** — 5 челленджей × 150 BP XP.

**Что нужно:**
- Новая таблица `WeeklyBpChallenge` в Prisma (id, seasonId, weekNumber, objective, target, rewardBpXp)
- Endpoint `/api/battle-pass/weekly-challenges` (GET + POST claim)
- Progress tracking (reuse existing quest tracking pattern)
- Weekly rotation logic (cron? manual season update?)
- iOS UI: новая секция в BP view

Это **мини-фича на ~1 день** сама по себе. План втискивает в W3.D5 — это нереально.

**5.3 IAP-02 Premium bundle expansion.**

Текущее состояние:

```bash
$ grep "isPremium" backend/prisma/schema.prisma
# line 628: isPremium Boolean @default(false)
# line 637: @@unique([seasonId, bpLevel, isPremium])
```

Нет `premium.ts` файла. `isPremium` используется только в **BattlePass** (premium track rewards). То есть premium как бенефит за deployment — **не существует**, это будет **новая система**.

**План хочет:**
- +20 stamina cap (140 вместо 120)
- +10 inventory slots (68 вместо 58)
- +25 gems/day
- +50 gold daily login bonus
- +10% gold bonus на все fights
- Title «Chosen»
- Priority queue matchmaking (-2s)

Это **7 разных хендлеров**, все надо соединить с `Character.isPremium` (которого тоже нет — только в BattlePass). Нужно:
1. Добавить `isPremium Boolean @default(false)` на User (или `premiumUntil DateTime?`)
2. Миграция + admin sync
3. Пропатчить каждую формулу/endpoint чтобы читать premium flag:
   - `stamina` max formula
   - `inventory` max slots
   - `dailyLogin` gems/gold bonus
   - `pvpResolve` gold bonus
   - `matchmaking` queue priority
   - `profile` title display
4. IAP флоу (если не готов)

Это **2-3 дня работы**, не 1.

**Варианты 5.2+5.3+5.1:**

| Опция | W3.D5 scope |
|---|---|
| **A — план как есть** | ELO tiers redo + weekly challenges + premium expansion → overflow в W4 неизбежен, ~3-4 дня |
| **B — разбить на D5+W4.D1** | D5: ELO (Opt B — Challenger + divisions) + Weekly BP skeleton. W4.D1: Premium expansion |
| **C — минимум** | D5: только ELO Challenger + divisions. Weekly BP и Premium — отдельный спринт |
| **D — split premium** | D5: ELO + Weekly BP. Premium expansion **вынести целиком в W4** или W5 |

**Моя рекомендация: D.** Premium expansion слишком жирный — смешивать его с ELO/BP в один день это гарантированный slip. Лучше честно зафиксировать: W3.D5 = ELO + BP weekly, premium = отдельная задача. W4.D5 у нас "full re-playthrough + soft launch prep" — туда premium не влезет, поэтому должен появиться W5 или partial W4.

---

## Общие риски W3

1. **Отсутствие симулятора экономики.** W3.D3 критически зависит от него. Варианты:
   - Написать простой TypeScript simulator (1000 characters, 30 days, все sinks/sources)
   - Использовать agent `hexbound-studio:ledger` для аналитической модели
   - Полагаться на dev playtest + post-launch telemetry (рискованно)

2. **Feature flags.** План `0.4 Rollback strategy` говорит "через feature flags в live-config". У нас есть `backend/src/lib/game/feature-flags.ts` с `prisma.featureFlag.findMany`. То есть инфраструктура **есть**. Надо решить: **каждая balance константа получает flag override, или только самые рискованные (sink ratio)?**

3. **Объём работы превышает план.** По моим оценкам:
   - D1: 0.5 дня (не 1, если C/D вариант) — Taunt в отдельный спринт
   - D2: 0.5 дня ✓
   - D3: 2 дня (не 1.5) — нужен simulator + 24h dev playtest
   - D4: 1 день ✓
   - D5: 1.5 дня (не 2) **без** premium, premium = +2 дня в W4

   Итого: 5.5 дней + premium 2 дня = **7.5 дней.** План говорит 5. **Slip ~50%.**

4. **Prod deploy в конце недели.** По плану — "Вся неделя на dev, prod deploy только в конце". Это требует:
   - Chistry dev environment (или feature flags на prod)
   - 2-3 тестеров для playtest
   - Rollback script готов

5. **Class winrate sim для W3 checkpoint** — ещё один simulator нужен ("каждый класс в [45%, 55%]"). Либо делаем один общий simulator, либо два раздельных.

---

## Вопросы к Артёму (нужен выбор перед кодом)

1. **W3.D1 CHA** — вариант A / B / C / D? (моя рекомендация: **D** — miss chance сейчас, Taunt отдельно)
2. **W3.D1 CHA miss** — **заменяет** intimidation damage reduction или **добавляет** сверху?
3. **W3.D2 DODGE_PER_LUK** — оставить `0.1` или откатить?
4. **W3.D3 CHA gold curve** — только cap 0.80 или пересмотр всей piecewise функции? (моя рекомендация: пересмотр, иначе 30 CHA = cap и дальше бесполезно)
5. **W3.D3 Bless Weapon Scroll** — оставляем в D3, выносим в W4, или вырезаем?
6. **W3.D3 Economy simulator** — пишем полноценный TS simulator или аналитическая модель ledger-агента?
7. **W3.D5 ELO** — вариант A (полная перекройка 8 tiers), B (6 текущих + Challenger + divisions), или C (только Challenger)?
8. **W3.D5 Premium expansion** — делаем в W3.D5, выносим в W4.D5, или откладываем в W5?
9. **Feature flags** — все balance константы override-able или только sink ratio?
10. **Playtest** — есть ли у тебя тестеры на 24h dev playtest W3.D3 и full checkpoint?

---

## Мои предложения (если хочешь быстрый путь)

**Scope minimum (5 дней, честные):**

- **D1** — CHA miss chance (replace intimidation) + tooltip update. Taunt в backlog. ~4 часа
- **D2** — AGI 4 const + Execute bonus + unit test. Оставить `DODGE_PER_LUK`. ~5 часов
- **D3** — Streaks + CHA cap 0.80 (с re-scale) + repair + **simulator**. Без scroll. 2 дня
- **D4** — Training + Stance + Stamina DR + Prisma миграция (2 поля + lazy reset). 1 день
- **D5** — ELO Challenger + divisions (вариант B) + Weekly BP challenges skeleton. ~1.5 дня

**Выносится в W4 или W5:**
- Taunt active skill (новая подсистема)
- Bless Weapon Scroll (новая мини-фича)
- Premium expansion (крупная монетизационная перестройка)
- Полная 8-tier ELO перекройка (если захотим вариант A)

**Checkpoint:**
- Economy simulator passes `sink_ratio ≥ 0.50`
- Class winrate sim: все классы в `[45%, 55%]`
- 24h dev playtest: 2–3 тестера
- `hexbound-studio:vault` + `ledger` + `scales` + `strategist` review
- Tag: `v2026.05.01-w3-balance`

---

## Следующий шаг

Жду твоего ответа на 10 вопросов выше — или хотя бы на первые три (D1 scope, CHA miss стек, ELO вариант). Как только выберем scope — я иду в W3.D2 (самый безопасный день) и оттуда по порядку, с reality-check'ами перед каждым днём.

Если хочешь ещё короче — скажи только один из трёх:
- **"план целиком"** → делаю всё как в `QA_FIX_PLAN`, принимаю slip
- **"мой minimum"** → мои 5 дней выше, остальное в backlog
- **"skip W3"** → сначала W4 polish, balance в отдельный спринт позже
