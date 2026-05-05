# W3.D5 — Review-Before-Code Plan
*Drafted: 2026-04-10 · historical review-before-code plan preserved for scope/rationale*

> **Status boundary:** historical review-before-code plan for one late W3 slice. Treat it as a dated planning artifact, not as the current active implementation plan.

---

## Что просит QA-план

Три независимых куска в одном дне:

1. **BAL-05** — ELO tier expansion (добавить divisions I/II/III + Master + Challenger)
2. **BAL-06** — Battle Pass weekly challenges (rotating) вместо one-shot achievements
3. **IAP-02** — Premium Forever expansion (+7 новых бенефитов)

QA-план даёт на это "2 дня (D5 + overflow to W4.D1)". Моё мнение: в один день влезает не всё — придётся резать scope. Ниже — рекомендация.

---

## Что я нашёл в коде (факты, не домыслы)

### ELO система

- `backend/src/lib/game/balance.ts` → `PVP_RANKS`: `BRONZE: 0, SILVER: 1200, GOLD: 1500, PLATINUM: 1800, DIAMOND: 2100, GRANDMASTER: 2400` — это **orphan константы**: нигде в gameplay-коде не потребляются. Только в `live-config.ts` зарегистрированы как GameConfig keys.
- `backend/src/lib/game/elo.ts` — расчёт рейтинга есть (calculateElo + K-factor), tier-маппинга нет совсем.
- `Hexbound/Hexbound/Views/Leaderboard/LeaderboardRowView.swift` — рендерит только top-3 цветные позиции (`rankGold/rankSilver/rankBronze`), никаких tier badges, никаких названий "Bronze/Silver". iOS вообще не знает о PVP_RANKS.
- **Стартовый рейтинг**: `prisma/schema.prisma:290` → `pvpRating Int @default(1000)`.
- В QA-плане предложенные ranges (Bronze 0-399, Silver 400-799, Gold 800-1199...) **несовместимы со стартом 1000** — новый игрок сразу оказался бы в Gold III. Это нужно исправить.

### Battle Pass infrastructure

- `backend/src/lib/game/battle-pass.ts` — **28 строк всего**. Одна функция `awardBattlePassXp()`. Никакой инфраструктуры challenges/weekly нет.
- `schema.prisma`: есть `BattlePass`, `BattlePassReward` (с `isPremium` флагом для track), `Season`. Таблицы под weekly challenges нет.
- `balance.ts` имеет `BATTLE_PASS.XP_PER_ACHIEVEMENT: 100` (по комментарию в QA) — one-shot.
- `QuestType` enum: `pvp_wins, dungeons_complete, gold_spent, item_upgrade, consumable_use, shell_game_play, gold_mine_collect` — 7 вариантов, ровно тот набор, что нужен для weekly challenges.

### Premium Forever

- `schema.prisma`:
  - `User.premiumUntil: DateTime?` — есть (для подписочного Monthly Gem Card)
  - `BattlePassReward.premium: Boolean` — track flag
  - `BattlePassReward.isPremium: Boolean` — то же самое (дубль?)
- QA-план хочет **7 новых бенефитов**:
  1. +20 stamina cap (max 140 вместо 120)
  2. +10 inventory slots (max 68)
  3. +25 gems/day (auto-claim)
  4. +50 gold daily login (уже есть?)
  5. +10% gold bonus на все fights
  6. Exclusive cosmetic title «Chosen»
  7. Priority queue в matchmaking (-2s match)

Анализ рисков каждого бенефита:
- (1) stamina cap — нужен новый getter `maxStamina(hasPremium)` + миграция расчёта regen. **Средне**.
- (2) inventory — нужен override константы + проверка в auth/onboarding. **Легко**.
- (3) +25 gems/day — hook в daily login handler + поле `premium_gem_claim_date`. **Легко**.
- (4) +50 gold daily login — "keep existing" значит уже есть, проверить. **Тривиально**.
- (5) +10% gold bonus — **инжектится в PvP resolve hot path** + dungeon rewards + quests. Множитель после CHA но до level scaling? Нужно решать формулу. **Средне, сейчас критический путь.**
- (6) cosmetic title — нужна новая таблица или enum + UI в профиле. **Средне**.
- (7) priority queue — матчмейкинг только что "widened" до ±10 lvl / 3-phase cascade (W3.D3, память). Добавление priority queue требует переделки matchmaker'а под two-lane flow. **Высокий риск, 1 день точно мало.**

---

## Market-leader research — ELO tiers

Что делают лидеры для "климба лестницы":

| Игра | Tiers | Divisions | Top rank | Стартовый tier |
|---|---|---|---|---|
| **League of Legends** | 10 (Iron→Challenger) | 4 (IV→I) в tier, кроме Master+ | Challenger (top ~300 серверу) | Iron/Bronze после placement |
| **Valorant** | 9 (Iron→Radiant) | 3 (I→III) кроме Radiant | Radiant (top 500 региону) | Iron после placement |
| **Apex Legends** | 8 (Rookie→Predator) | 4 | Apex Predator (top 750 global) | Rookie calibration |
| **Dota 2** | 8 (Herald→Immortal) | 5 stars в tier | Immortal (без divisions) | Herald после calibration |
| **Clash Royale** Path of Legends | 10 leagues | ★1-★10 внутри | Ultimate Champion | League 1 |
| **Hexbound текущий** | 6 (без Master/Challenger) | нет | Grandmaster 2400+ | — (не рендерится) |

**Ключевые инварианты у всех лидеров:**

1. **3-5 divisions внутри tier** создают дофаминовую микро-progression (каждые ~200 ELO = промо).
2. **Top tier — всегда top-N по absolute rank**, НЕ по рейтингу. Это гарантирует эксклюзивность.
3. **Новый игрок стартует в самом низу** (Iron/Herald/Rookie) и продвигается через placement games.
4. **Декейт/демоушн** есть в диапазоне Diamond+ (LoL, Valorant) — иначе tier инфлейтится.
5. **Promotion visuals** (promo series, rank-up animation) — отдельный UX-момент, не просто смена числа.

---

## Моя рекомендация по ELO (Variant A)

### Tier structure — 8 tiers, 3 divisions, top-N Challenger

Стартовый рейтинг 1000 = **Silver III** (калибровка будущая, пока placement по факту первых 10 боёв через K_CALIBRATION=48).

| Tier | Divisions | ELO range | Start включён? |
|---|---|---|---|
| **Bronze** | III, II, I | 0-749 (каждая ~250) | нет — ниже стартового |
| **Silver** | III, II, I | 750-1499 | **Silver III: 750-999, Silver II: 1000-1249** ← старт |
| **Gold** | III, II, I | 1500-2249 | нет |
| **Platinum** | III, II, I | 2250-2999 | нет |
| **Diamond** | III, II, I | 3000-3749 | нет |
| **Master** | (без div) | 3750-4249 | нет |
| **Grandmaster** | (без div) | 4250-4749 | нет |
| **Challenger** | top 100 only | **>=4250 AND rank <= 100** | только серверный cutoff |

Почему так:
- **250 пойнтов на дивижен** → промоушен каждые ~7-10 побед для среднего K=32 игрока. Это ритм, которым LoL и Valorant живут.
- **Silver II старт** — новый игрок чувствует, что немного выше дна, но есть куда падать и расти. Чистый 0-старт был бы слишком жёстким (Hexbound не соревновательный киберспорт).
- **Challenger по абсолютному ранку** — максимум 100 игроков на всю игру. Это single leaderboard slot, вычисляется на лету при чтении leaderboard, НЕ поле в БД (иначе нужны крон-джобы).
- **Нет demotion** в W3.D5 — добавим в W4 если dev-плейтест покажет tier inflation.

### Variant B (минимальное касание)

Если хочешь **НЕ трогать existing PVP_RANKS ranges** (0/1200/1500/1800/2100/2400) и просто добавить divisions+Challenger поверх:

- Bronze (0-1199): делим на B-III 0-399, B-II 400-799, B-I 800-1199. Старт 1000 = Bronze I.
- Silver (1200-1499): S-III 1200-1299, S-II 1300-1399, S-I 1400-1499 (тонкие, по 100)
- Gold (1500-1799): аналогично по 100
- Platinum (1800-2099): по 100
- Diamond (2100-2399): по 100
- Master: 2400-2699 (новый tier, выделен из старого GM)
- Grandmaster: 2700-2999
- Challenger: >= 3000 AND top 100

**Плюсы B:** zero migration, старые рейтинги не меняются визуально.
**Минусы B:** division widths непоследовательные (400/100/100/100/100 потом 300/300), это плохой UX ("почему из B-III в B-II надо 400 ELO, а из S-III в S-II — 100?").

**Моя рекомендация: Variant A.** Чище, мэппит на индустриальные стандарты, предсказуемый ритм промоушенов. Стоимость миграции — **нулевая**: PVP_RANKS нигде не консюмится, мы просто пишем новую функцию `tierFromRating(rating, leaderboardRank?)` и всё.

---

## Weekly BP Challenges — дизайн

### Основная механика

5 челленджей ротируются **каждый ISO-понедельник UTC**. Каждый даёт 150 BP XP. Total 750/week. За сезон ~50 дней = ~7 недель = **5250 BP XP из challenges**. Это ~10-15% от полного BP (зависит от curve), остальное — из боёв и achievements.

### 5 slot shapes (каждая неделя — рандом из pool с guaranteed diversity)

| # | Slot type | Примеры goal | Почему |
|---|---|---|---|
| 1 | **PvP grind** | Win 15 PvP matches / Do 25 PvP matches | Ядро гейма |
| 2 | **PvE progression** | Clear 20 dungeons / Defeat 5 dungeon bosses | Альт-луп для anti-burnout |
| 3 | **Economy sink** | Spend 5000g on upgrades / Repair 10 items | Подкрепляет W3.D3 sink ratio |
| 4 | **Social/variety** | Use 10 consumables / Play 3 shell game rounds / Collect 5 gold mine sessions | Лёгкий, туториальный |
| 5 | **Wildcard** | Win 3 PvP with <50% HP / Clear a dungeon in <90s / Upgrade an item to +5 | "Skill check", нечастый |

Pool подборки определяется **seeded RNG по ISO-неделе** — детерминированно, без cron'а, без DB-миграций на каждую ротацию.

### Схема БД

Новая таблица:
```prisma
model WeeklyChallengeProgress {
  id           String   @id @default(uuid())
  characterId  String   @map("character_id")
  isoWeek      String   @map("iso_week")   // "2026-W15"
  slotIndex    Int      @map("slot_index") // 0..4
  goalType     QuestType @map("goal_type")
  goalTarget   Int      @map("goal_target")
  progress     Int      @default(0)
  bpXpAward    Int      @map("bp_xp_award")
  claimed      Boolean  @default(false)
  completedAt  DateTime? @map("completed_at")

  character Character @relation(fields: [characterId], references: [id], onDelete: Cascade)

  @@unique([characterId, isoWeek, slotIndex])
  @@map("weekly_challenge_progress")
}
```

Lazy-init при первом вызове `GET /api/battle-pass/weekly-challenges` — если на эту неделю нет строк для персонажа, вставляем 5 (seeded random). Прогресс обновляется в существующих hook'ах: PvP resolve, dungeon resolve, shop-buy (upgrade), consumable use — тех же, что уже пишут в daily quests.

### Acceptance

- `GET /api/battle-pass/weekly-challenges` возвращает 5 ровных слотов с progress
- `POST /api/battle-pass/weekly-challenges/claim` → выдаёт 150 BP XP, ставит `claimed=true`
- Ротация детерминирована на `isoWeek` (seed)
- Unit test: 100 недель подряд — pool diversity покрывает все 7 QuestType'ов
- Не дублируется с daily quests (daily остаются независимыми)

---

## Premium Forever — scope cut

**Всё за один день не влезет.** Рекомендация: режем на 2 части.

### W3.D5 (сегодня) — минимальный жизнеспособный пакет

| Бенефит | Почему сейчас |
|---|---|
| **+25 gems/day** (auto-claim при daily login) | Чистый гейтинг по `user.premiumUntil`/`account.premiumForever`, 1 поле + 1 hook, визуальная монетка |
| **+10% gold bonus** на PvP/dungeon/quest rewards | Простой множитель в reward calculator ПЕРЕД CHA cap и level scaling (ставим в конец стека). 1 функция, 4 callsite'а |
| **Exclusive «Chosen» title** | Нужен `Character.activeTitle: String?` + enum set. UI в профиле уже будет работать через существующий text slot |

Суммарно: 1 миграция (`chosen_title` enum value + `gem_daily_claim_date`), 4 hook-сайта, 3 теста.

### Deferred to W4.D1

| Бенефит | Почему отложить |
|---|---|
| +20 stamina cap | Требует изменения regen формулы + миграция полей `max_stamina` → либо recalc на лету, либо денормализация. Риск bricking существующих state-машин стамины. |
| +10 inventory slots | Нужен gate в shop/expansion purchase flow + проверка max. Низкий риск, но не критично для W3 retention goal. |
| +50 gold daily login | Возможно уже есть — надо проверить. Если нет — копеечный 1-line fix. |
| **Priority queue matchmaking** | Матчмейкинг только что расширили до cascade (W3.D3 memory). Добавление priority lane ломает инварианты cascade. **Отказываемся от этой фичи до post-launch** — замерим retention эффект от базового premium, решим потом, нужен ли queue boost. |

---

## Итог — что я собираюсь сделать в W3.D5 (если одобришь)

| # | Блок | Файлы | Acceptance |
|---|---|---|---|
| 1 | ELO tiers+divisions (**Variant A**) | `balance.ts` (новый PVP_RANKS shape), новый `tier.ts` (pure `tierFromRating(rating, rank?)` + `divisionFromRating`), `tests/lib/tier.test.ts` (~20 тестов) | Pure function, 8 tiers × {I,II,III} + Master/GM/Challenger; Challenger фильтруется top-100 leaderboard |
| 2 | Weekly BP challenges backend | Migration: `WeeklyChallengeProgress` table; `backend/src/lib/game/weekly-challenges.ts` (pool + seeded pick + progress update); `GET/POST /api/battle-pass/weekly-challenges{,/claim}`; tests: pool diversity, determinism, claim idempotency | 5 slots per week, 150 BP XP каждый, ротация на ISO-неделю, claimable once |
| 3 | Premium — minimum pack | Migration: `Character.activeTitle: String?`, `User.premiumGemClaimDate: DateTime?`; `premium.ts` helper (hasPremium, goldBonusMultiplier); hook в PvP resolve + dungeon resolve + daily login | +10% gold на fights/dungeons, +25 gems/day, «Chosen» title |
| 4 | iOS — tier badge | `LeaderboardRowView.swift` + новый `TierBadge.swift` компонент (SwiftUI), рендерит roman numerals division + tier name через DarkFantasyTheme токены | Виден в leaderboard + профиле; ZERO hardcoded colors |
| 5 | Docs | ECONOMY.md (premium multiplier), GAME_SYSTEMS.md (weekly BP challenges), новый раздел в PVP.md (tier ladder) | Всё через auto-generator где возможно |

**НЕ делаю в W3.D5:**
- Stamina cap expansion
- Inventory slot expansion
- Priority matchmaking queue (отказ)
- Demotion protection в ELO
- Weekly challenge UI на iOS (оставляю эндпоинты готовыми, UI в W4)

**Оценка:** 6-8 часов работы при чистых тестах. ELO tier — ~1.5ч, Weekly BP — ~3ч (миграция + логика + тесты), Premium — ~2ч, iOS badge — ~1.5ч.

---

## Вопросы для тебя

1. **Variant A или B для ELO tiers?** (я рекомендую A: 250-пойнтовые divisions, старт в Silver II)
2. **+10% gold premium multiplier — куда в стеке?** Предлагаю **в самый конец**, после CHA и streak и level scaling, чтобы не взрывать sink-ratio через мультипликативный boost. Альтернативно — перед level scaling (слабее, ~+8% чистыми). 
3. **«Chosen» title** — добавлять как enum value или как free-form string? Предлагаю **hardcoded enum** `Title.chosen` чтобы нельзя было spoof'нуть через API.
4. **Миграция рейтингов существующих игроков?** Мне кажется — НЕ нужна (Variant A сохраняет рейтинги числами, меняется только интерпретация tier). Confirm?
5. **Weekly BP challenges unlock** — с 1-го дня сезона или с недели 2? Предлагаю **с 1-го дня** (текущая ISO-неделя, даже если неполная — прогресс pro-rata не режем).

После твоих ответов — сразу к коду.
