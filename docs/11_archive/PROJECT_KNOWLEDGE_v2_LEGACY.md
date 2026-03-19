# Hexbound — база знаний проекта (v2 — Mobile Edition)

Документ описывает реализованную и планируемую структуру, БД, переменные окружения, логику систем и API. Используется как единый источник истины для разработки и для AI.

**Последнее обновление:** 5 марта 2026  
**Версия:** 2.0 — включает новые системы для мобильного релиза

---

## 1. Описание проекта

- **Название:** Hexbound
- **Жанр:** браузерная + мобильная PvP RPG, пошаговый бой, асинхронный PvP
- **Платформы:** Web (текущая), iOS (в разработке — Godot 4.3+)
- **Стек (Web):** Next.js 14 (App Router), React 18, TypeScript, Tailwind CSS, Supabase (Auth + PostgreSQL), Prisma ORM
- **Стек (Mobile):** Godot 4.3+, GDScript, iOS export
- **Backend:** общий для Web и Mobile — Next.js API Routes + Supabase + PostgreSQL
- **Мониторинг:** Sentry (client + server + edge), Vercel Analytics, Speed Insights
- **Тестирование:** Vitest (25 unit/component test files, 322 теста), Playwright (E2E)
- **Геймдизайн:** полный GDD в `docs/hexbound_gdd.md`
- **Инструменты:** Cursor (IDE + AI-ассистент), Godot Editor 4.3+ (мобильный клиент и экспорт в iOS/App Store)

---

## 2. Архитектура: Web + Mobile

```
┌──────────────────┐     ┌──────────────────────┐
│   Web Client     │     │   Godot Client (iOS)  │
│   (Next.js/React)│     │   (GDScript)          │
└────────┬─────────┘     └──────────┬────────────┘
         │                          │
         │        HTTPS / JSON      │
         └────────────┬─────────────┘
                      │
         ┌────────────▼────────────┐
         │   Shared Backend        │
         │   Next.js API Routes    │
         │   Supabase Auth         │
         │   PostgreSQL (Prisma)   │
         └─────────────────────────┘
```

Принцип: **тонкий клиент, толстый сервер**. Вся игровая логика — на сервере. Клиенты (web и mobile) только отображают данные и отправляют действия. Это защищает от читов и позволяет кроссплатформенную игру.

### 2.1 Работа с Cursor и Godot

- **Cursor** — основная IDE: правки бэкенда (Next.js, Prisma, API), тестов, окружения. При запросах к AI указывать `@PROJECT_KNOWLEDGE_v2.md`, чтобы ответы опирались на актуальные API, схему БД и структуру Godot из этого документа.
- **Godot** — движок и редактор мобильного клиента: сцены, GDScript, экспорт под iOS, настройка проекта. Структура проекта — в §7.
- **Разделение ответственности:** сервер (Next.js) — вся игровая логика (бой, прогресс, награды, IAP, push); Godot — UI, вызовы API, кэш, воспроизведение боя по `combat_log`. Не дублировать логику боя/баланса в клиенте.
- **Единый источник истины:** при добавлении API, полей БД или сцен — сначала обновлять этот документ (§4, §6, §7), затем код/миграции. Имена эндпоинтов и полей должны совпадать с документом.

---

## 3. Переменные окружения

| Переменная | Назначение |
|------------|------------|
| `NEXT_PUBLIC_SUPABASE_URL` | URL проекта Supabase (публичный) |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Публичный anon-ключ Supabase |
| `DATABASE_URL` | PostgreSQL для Prisma (Supabase pooler) |
| `DIRECT_URL` | Прямое подключение PostgreSQL для миграций |
| `SUPABASE_SERVICE_ROLE_KEY` | Сервисный ключ Supabase для админ-операций |
| `NEXT_PUBLIC_SENTRY_DSN` | DSN Sentry |
| `SENTRY_ORG` | Организация Sentry |
| `SENTRY_PROJECT` | Проект Sentry |
| `APPLE_SHARED_SECRET` | **[NEW]** Shared secret для валидации Apple IAP receipts |
| `APNS_KEY_ID` | **[NEW]** Key ID для Apple Push Notifications |
| `APNS_TEAM_ID` | **[NEW]** Team ID для APNs |
| `APNS_AUTH_KEY` | **[NEW]** Путь к .p8 файлу для APNs |

---

## 4. База данных: таблицы и поля

Маппинг Prisma → БД: имена в БД в **snake_case** (см. `prisma/schema.prisma`, `@map()`).

### 4.1 Существующие таблицы (без изменений)

**users** — id (UUID, PK = auth.uid), email, username, password_hash, auth_provider, gems, premium_until, role, created_at, last_login, is_banned, ban_reason

**characters** — id, user_id (FK→users), character_name (UNIQUE), class (enum), origin (enum), level, current_xp, prestige_level, stat_points_available, 8 статов (str/agi/vit/end/int/wis/luk/cha, default 10), gold (500), arena_tokens, max_hp, current_hp, armor, magic_resist, combat_stance (JSONB), current_stamina, max_stamina, last_stamina_update, bonus_trainings/date/buys, pvp_rating (0), pvp_wins/losses/win_streak/loss_streak, highest_pvp_rank, gold_mine_slots, created_at, last_played

**items** — id, catalog_id (UNIQUE), item_name, item_type, rarity, item_level, base_stats (JSONB), special_effect, unique_passive, class_restriction, set_name, buy_price, sell_price, description, image_url, created_at

**equipment_inventory** — id, character_id (FK), item_id (FK), upgrade_level, durability, max_durability, is_equipped, equipped_slot (enum), rolled_stats (JSONB), acquired_at

**consumable_inventory** — id, character_id (FK), consumable_type (enum), quantity, acquired_at. UNIQUE(character_id, consumable_type)

**pvp_matches** — id, player1_id, player2_id (FK→characters), rating before/after для обоих, winner_id, loser_id, combat_log (JSONB), match_duration, turns_taken, gold/xp rewards, match_type, season_number, played_at

**dungeon_progress** — id, character_id, dungeon_id, boss_index, completed. UNIQUE(character_id, dungeon_id)

**dungeon_runs** — id, character_id, difficulty, current_floor, state (JSONB), seed, created_at

**legendary_shards** — id, character_id (UNIQUE FK), shard_count, updated_at

**training_sessions** — id, character_id, xp_awarded, won, turns, opponent_type, played_at

**gold_mine_sessions** — id, character_id, slot_index, started_at, ends_at, collected, reward, boosted, created_at

**minigame_sessions** — id, character_id, game_type, bet_amount, secret_data, status, result, created_at

**seasons** — id, number (UNIQUE), theme, start_at, end_at, created_at

**daily_quests** — id, character_id, quest_type, progress, target, reward_gold, reward_xp, reward_gems, completed, day, created_at. UNIQUE(character_id, quest_type, day)

**battle_pass** — id, character_id, season_id (FK→seasons), premium, bp_xp, created_at, updated_at

**cosmetics** — id, user_id (FK→users), type, ref_id, created_at

**design_tokens** — id ("global"), tokens (JSONB), updated_at, updated_by

### 4.2 Изменения в существующих таблицах

**characters — добавить поля:**
```
max_stamina            → увеличить default с 100 до 120
pvp_rating             → изменить default с 0 на 1000
pvp_calibration_games  Int      @default(0)     — счётчик калибровочных матчей (0–10)
first_win_today        Boolean  @default(false)  — бонус первой победы использован
first_win_date         DateTime?                 — дата последней первой победы
free_pvp_today         Int      @default(0)      — счётчик бесплатных PvP (макс 3)
free_pvp_date          DateTime?                 — дата сброса бесплатных PvP
```

**daily_quests — расширить quest_type enum:**
```
Было:    pvp_wins, dungeons_complete
Стало:   pvp_wins, dungeons_complete, gold_spent, item_upgrade,
         consumable_use, shell_game_play, gold_mine_collect
```

**pvp_matches — добавить поле:**
```
is_revenge  Boolean @default(false)  — это revenge-матч
```

### 4.3 Новые таблицы

**daily_login_rewards** — ежедневный логин-бонус
```
id              String   @id @default(uuid)
character_id    String   FK → characters, ON DELETE CASCADE
current_day     Int      @default(1)           — текущий день цикла (1–7)
last_claim_date DateTime?                      — дата последнего сбора
streak          Int      @default(0)           — подряд дней без пропуска
total_claims    Int      @default(0)           — всего собрано за всё время
created_at      DateTime @default(now())

UNIQUE(character_id)
```

Награды по дням (константы в `lib/game/balance.ts`):
```
Day 1: 200 gold
Day 2: 1 stamina_potion_small
Day 3: 500 gold
Day 4: 2 stamina_potion_small
Day 5: 1000 gold
Day 6: 1 stamina_potion_large
Day 7: 5 gems + 1 random rare item
→ Цикл сбрасывается на Day 1
```

**revenge_queue** — очередь для revenge-боёв
```
id              String   @id @default(uuid)
victim_id       String   FK → characters       — кого победили
attacker_id     String   FK → characters       — кто победил
match_id        String   FK → pvp_matches      — оригинальный матч
is_seen         Boolean  @default(false)        — игрок видел уведомление
is_used         Boolean  @default(false)        — revenge использован
created_at      DateTime @default(now())
expires_at      DateTime                        — 72 часа на revenge

INDEX(victim_id, is_used, expires_at)
INDEX(attacker_id)
```

**achievements** — система достижений
```
id              String   @id @default(uuid)
character_id    String   FK → characters, ON DELETE CASCADE
achievement_key String                          — уникальный ключ ("pvp_wins_100", "first_legendary")
progress        Int      @default(0)
target          Int                             — цель для выполнения
completed       Boolean  @default(false)
completed_at    DateTime?
reward_claimed  Boolean  @default(false)
created_at      DateTime @default(now())

UNIQUE(character_id, achievement_key)
INDEX(character_id, completed)
```

Каталог достижений (константы в `lib/game/achievement-catalog.ts`):
```
--- Боевые ---
pvp_first_blood     : Win first PvP match                    → 100 gold
pvp_wins_10         : Win 10 PvP matches                     → 500 gold
pvp_wins_50         : Win 50 PvP matches                     → 2 gems
pvp_wins_100        : Win 100 PvP matches                    → 5 gems + title "Gladiator"
pvp_wins_500        : Win 500 PvP matches                    → 10 gems + frame "Arena Legend"
pvp_streak_5        : Win 5 PvP in a row                     → 1000 gold
pvp_streak_10       : Win 10 PvP in a row                    → 3 gems
revenge_first       : Win first revenge match                 → 300 gold
revenge_wins_10     : Win 10 revenge matches                  → 2 gems

--- Прогрессия ---
reach_level_10      : Reach level 10                          → 500 gold
reach_level_25      : Reach level 25                          → 2 gems
reach_level_50      : Reach level 50                          → 5 gems + title "Veteran"
first_prestige      : Prestige for the first time             → 10 gems + frame "Reborn"
prestige_3          : Reach prestige 3                        → 20 gems

--- Коллекционирование ---
first_legendary     : Obtain first legendary item             → 1000 gold
full_set            : Equip a complete item set               → 3 gems
upgrade_10          : Upgrade item to +10                     → 5 gems + title "Mastersmith"
equip_all_slots     : Equip items in all 12 slots             → 500 gold

--- Подземелья ---
dungeon_first_clear : Clear first dungeon                     → 300 gold
dungeon_all_easy    : Clear all dungeons on Easy              → 2 gems
dungeon_all_hard    : Clear all dungeons on Hard              → 10 gems + frame "Dungeon Master"
boss_no_damage      : Defeat a boss without taking damage     → 5 gems

--- Экономика ---
earn_gold_10k       : Earn 10,000 total gold                  → 500 gold
earn_gold_100k      : Earn 100,000 total gold                 → 3 gems
spend_gold_50k      : Spend 50,000 total gold                 → 2 gems
shell_game_win_10   : Win Shell Game 10 times                 → 1000 gold

--- Ранги ---
rank_silver         : Reach Silver rank                       → 1 gem
rank_gold           : Reach Gold rank                         → 3 gems
rank_diamond        : Reach Diamond rank                      → 10 gems + effect "Diamond Aura"
rank_grandmaster    : Reach Grandmaster rank                  → 25 gems + title "Grandmaster"

--- Retention ---
login_7_days        : Log in 7 days in a row                  → 2 gems
login_30_days       : Log in 30 days in a row                 → 10 gems + frame "Dedicated"
daily_quest_100     : Complete 100 daily quests               → 5 gems
```

**battle_pass_rewards** — награды Battle Pass (дополнение к существующей таблице battle_pass)
```
id              String   @id @default(uuid)
season_id       String   FK → seasons
bp_level        Int                             — уровень BP (1–30)
is_premium      Boolean  @default(false)        — премиум-дорожка
reward_type     String                          — "gold", "gems", "item", "cosmetic", "consumable"
reward_id       String?                         — ID предмета/косметики (если применимо)
reward_amount   Int      @default(1)
created_at      DateTime @default(now())

UNIQUE(season_id, bp_level, is_premium)
```

**battle_pass_claims** — какие награды BP игрок уже забрал
```
id              String   @id @default(uuid)
character_id    String   FK → characters
battle_pass_id  String   FK → battle_pass
reward_id       String   FK → battle_pass_rewards
claimed_at      DateTime @default(now())

UNIQUE(character_id, reward_id)
```

**push_tokens** — токены для push-уведомлений
```
id              String   @id @default(uuid)
user_id         String   FK → users, ON DELETE CASCADE
platform        String                          — "ios", "web"
token           String
is_active       Boolean  @default(true)
created_at      DateTime @default(now())
updated_at      DateTime @updatedAt

UNIQUE(user_id, platform, token)
INDEX(user_id, is_active)
```

**iap_transactions** — валидация покупок App Store
```
id              String   @id @default(uuid)
user_id         String   FK → users
product_id      String                          — Apple product ID ("gems_small", "gems_large", etc.)
transaction_id  String   UNIQUE                 — Apple transaction ID
receipt_data    String                          — Base64 receipt для валидации
gems_awarded    Int
status          String   @default("pending")    — "pending", "verified", "failed", "refunded"
created_at      DateTime @default(now())
verified_at     DateTime?

INDEX(user_id, created_at DESC)
INDEX(transaction_id)
```

**events** — игровые события
```
id              String   @id @default(uuid)
event_key       String   UNIQUE                 — "weekend_boss_rush", "gold_rush_march"
title           String
description     String
event_type      String                          — "boss_rush", "gold_rush", "class_spotlight", "tournament"
config          Json                            — параметры ивента (множители, бонусы, etc.)
start_at        DateTime
end_at          DateTime
is_active       Boolean  @default(true)
created_at      DateTime @default(now())

INDEX(is_active, start_at, end_at)
```

### 4.4 Enum-типы (обновлённый список)

```
CharacterClass    : warrior, rogue, mage, tank
CharacterOrigin   : human, orc, skeleton, demon, dogfolk
ItemType          : weapon, helmet, chest, gloves, legs, boots, accessory, amulet, belt, relic, necklace, ring
Rarity            : common, uncommon, rare, epic, legendary
EquippedSlot      : weapon, weapon_offhand, helmet, chest, gloves, legs, boots, accessory, amulet, belt, relic, necklace, ring
ConsumableType    : stamina_potion_small, stamina_potion_medium, stamina_potion_large
QuestType         : pvp_wins, dungeons_complete, gold_spent, item_upgrade, consumable_use, shell_game_play, gold_mine_collect  [UPDATED]
CosmeticType      : frame, title, effect, skin  [NEW]
IAPProductId      : gems_small, gems_medium, gems_large, gems_mega, monthly_gem_card, battle_pass_premium  [NEW]
EventType         : boss_rush, gold_rush, class_spotlight, tournament  [NEW]
```

---

## 5. Логика систем

### 5.1 Существующие системы (краткая сводка, без изменений)

- **Auth:** Supabase Auth (email/password + OAuth). Middleware защищает игровые роуты.
- **Персонаж:** CRUD, расы с бонусами, стойки, зоны тела.
- **Бой:** `runCombat()`, AGI-порядок, урон, способности, статусы, 15 ходов макс, VFX.
- **Тренировка:** simulate + дневной лимит + покупка бонусных.
- **Подземелья:** 3 типа, генерация, боссы, прогресс.
- **Мини-игры:** Shell Game, Gold Mine, Dungeon Rush.
- **Инвентарь:** 12 слотов, экипировка/снятие, продажа.
- **Магазин:** предметы по уровню, ремонт, апгрейд, зелья.
- **Сезоны:** текущий сезон, лидерборд.
- **Админка:** Players, Matches, Economy, Characters, Balance, Design, Dev.

### 5.2 Обновлённые системы

#### Стамина (обновлённый баланс)
```
Max stamina:           120 (было 100)
Regen:                 1 / 8 мин (было 1/12 мин) = ~16ч полный рефилл
PvP cost:              10 (первые 3 боя в день — бесплатно)
Dungeon Easy/Normal/Hard: 15 / 20 / 25
Boss:                  40
Training:              5 (было неявно, теперь явно)
```

#### PvP (обновлённый баланс)
```
Стартовый рейтинг:    1000 (было 0)
Калибровка:            первые 10 матчей K=48 (потом K=32)
Free PvP:              3 боя/день без стамины
First Win bonus:       x2 gold + x2 XP за первую победу дня
Matchmaking range:     ±150 во время калибровки, ±100 после
```

#### Ежедневные квесты (расширены)
```
Типы: pvp_wins, dungeons_complete, gold_spent, item_upgrade,
      consumable_use, shell_game_play, gold_mine_collect
Выдаётся: 4 случайных квеста в день (было 2 типа)
Бонус за выполнение всех 4: дополнительная награда (500 gold + 1 gem)
```

#### Апгрейд предметов (уточнённые шансы)
```
+1 → +5:  100% успех
+6:       80%
+7:       60%
+8:       40%
+9:       25%
+10:      15%
При неудаче: -1 уровень (не ломается)
Protection scroll (30 gems): защита от -1 при неудаче
```

### 5.3 Новые системы

#### Daily Login Rewards
- При входе в игру — проверка: прошло ли 24+ часа с последнего claim.
- Если да — показать награду текущего дня, позволить забрать.
- Если пропуск >48 часов — streak сбрасывается, день НЕ сбрасывается (продолжает цикл).
- После Day 7 — возврат на Day 1, streak продолжается.
- Streak бонус: 7 дней подряд → дополнительные 2 гема.

#### First Win of the Day
- Первая PvP-победа за сутки (UTC) → gold × 2, XP × 2.
- Поле `first_win_today` на персонаже, сбрасывается `first_win_date < today`.
- Визуальный индикатор в UI: "First Win Bonus Available!"

#### Free PvP Fights
- 3 PvP-боя в день без затрат стамины.
- Поле `free_pvp_today` на персонаже, сбрасывается по `free_pvp_date`.
- После 3 бесплатных — обычная стоимость (10 стамины).

#### Revenge System
- После каждого PvP-поражения — запись в `revenge_queue`.
- Игрок видит список "кто меня победил" на экране арены.
- Revenge-бой: бесплатный (без стамины), x1.5 gold за победу.
- Срок действия: 72 часа. Одна попытка на каждый матч.
- Push-уведомление: "Игрок {name} победил тебя! Отомсти?"
- Revenge-победа прогрессит квест `pvp_wins` и achievement `revenge_wins_N`.

#### Achievement System
- При каждом значимом действии — вызов `updateAchievementProgress(characterId, key, increment)`.
- Проверяет: если progress >= target и not completed → completed = true.
- Награда НЕ выдаётся автоматически — игрок "забирает" в UI (кнопка claim).
- Незабранные награды — badge-счётчик на иконке Achievements.
- Hook-точки (где вызывать `updateAchievementProgress`):
  - PvP: после `find-match` → `pvp_wins_N`, `pvp_streak_N`, `rank_*`
  - Revenge: после revenge-боя → `revenge_wins_N`
  - Level up: в `applyLevelUp()` → `reach_level_N`
  - Prestige: → `first_prestige`, `prestige_N`
  - Equip: в `equip` → `equip_all_slots`
  - Upgrade: в `upgrade` → `upgrade_10`
  - Loot: в `rollDropChance()` → `first_legendary`
  - Set: в `equipment-stats.ts` → `full_set`
  - Dungeon: после clear → `dungeon_*`
  - Login: в login reward claim → `login_N_days`
  - Quest: в quest complete → `daily_quest_100`
  - Economy: в gold earn/spend → `earn_gold_*`, `spend_gold_*`

#### Battle Pass
- Привязан к сезону. Один BP на сезон на персонажа.
- 30 уровней. BP XP начисляется за: PvP (20 XP/бой), dungeons (30 XP/этаж), daily quests (50 XP/квест), achievements (100 XP/achievement).
- Требуется XP на уровень: `100 + (level × 50)`. Level 1 = 150 XP, Level 30 = 1600 XP.
- Бесплатная дорожка: gold, consumables, обычные предметы.
- Премиум дорожка (500 gems за сезон): exclusive cosmetics, gems, legendary items, rare consumables.
- При покупке premium — ретроактивно открываются все заработанные премиум-награды.
- UI: горизонтальный scrollable трек с двумя рядами наград.

#### In-App Purchases
```
Продукты (Apple App Store):
gems_small          : 100 gems   → $0.99
gems_medium         : 550 gems   → $4.99   (бонус +10%)
gems_large          : 1200 gems  → $9.99   (бонус +20%)
gems_mega           : 6500 gems  → $49.99  (бонус +30%)
monthly_gem_card    : 50 gems сразу + 10/день × 30 дней = 350 gems → $4.99
battle_pass_premium : 500 gems (покупка через gem store)
```

Валидация: клиент отправляет receipt → `POST /api/iap/verify` → сервер проверяет через Apple Verify Receipt API → начисляет гемы → записывает в `iap_transactions`.

#### Push Notifications (APNs)
```
Триггеры:
- stamina_full       : "Стамина полностью восстановлена!"           — когда stamina = max
- gold_mine_ready    : "Gold Mine готов к сбору!"                    — когда ends_at < now
- revenge_available  : "Игрок {name} победил тебя! Отомсти!"        — после PvP-поражения
- daily_reset        : "Новые ежедневные квесты доступны!"           — в 00:00 UTC
- bp_level_up        : "Battle Pass: новый уровень! Забери награду." — при повышении BP
- event_start        : "Новое событие: {title}!"                     — при старте ивента
```

Макс 3 уведомления в день. Приоритет: revenge > gold_mine > stamina > остальные.

#### Events System
- Админ создаёт ивент через `/api/admin/events`.
- Активные ивенты — `GET /api/events/active`.
- Типы:
  - `gold_rush`: множитель gold × 2 на все источники
  - `boss_rush`: усиленные боссы, x2 лут
  - `class_spotlight`: один класс получает +10% ко всем статам
  - `tournament`: отдельный bracket (будущее)
- Клиент проверяет активные ивенты при старте сессии и показывает баннер.

#### Onboarding (мобильный туториал)
```
Шаг 1: Splash → "Tap to Start" (нет логина)
Шаг 2: Выбор класса (4 карточки с анимацией)
Шаг 3: Мгновенный первый бой (предгенерированный, easy враг)
Шаг 4: Лут! (гарантированный rare item)
Шаг 5: "Создай аккаунт, чтобы сохранить прогресс" (или продолжить как гость)
Шаг 6: Хаб с подсказками
```
Гостевой аккаунт: Supabase anonymous auth → при регистрации привязка к email/OAuth.

---

## 6. API Endpoints (полный справочник)

### Auth
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| POST | /api/auth/sync-user | Синхронизация users с auth.uid | 10/мин |
| POST | /api/auth/guest | **[NEW]** Создать гостевой аккаунт | 5/мин |
| POST | /api/auth/link-account | **[NEW]** Привязать гостя к email/OAuth | 5/мин |

### User
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/me | Текущий пользователь | — |
| POST | /api/user/password | Изменение пароля | 5/мин |
| POST | /api/user/email | Изменение email | 3/мин |

### Characters
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/characters | Список персонажей | — |
| POST | /api/characters | Создать персонажа | 3/мин |
| GET | /api/characters/[id] | Персонаж по id | — |
| POST | /api/characters/[id]/allocate-stats | Распределить статы | + |
| POST | /api/characters/[id]/stance | Установить стойку | — |
| PATCH | /api/characters/[id]/origin | Сменить расу | 3/мин |
| GET | /api/characters/[id]/profile | **[NEW]** Публичный профиль | — |

### Combat
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| POST | /api/combat/simulate | Тренировочный бой | 5/10с |
| GET | /api/combat/status | Статус тренировок | — |
| POST | /api/combat/buy-extra | Купить бонусные тренировки | + |

### PvP
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| POST | /api/pvp/find-match | Найти и провести PvP бой | 3/10с |
| GET | /api/pvp/opponents | Список оппонентов | — |
| GET | /api/pvp/revenge | **[NEW]** Список revenge-возможностей | — |
| POST | /api/pvp/revenge/[id] | **[NEW]** Провести revenge-бой | 3/10с |
| GET | /api/pvp/history | **[NEW]** История матчей | — |

### Dungeons
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/dungeons | Список подземелий | — |
| POST | /api/dungeons/start | Начать подземелье | 3/10с |
| POST | /api/dungeons/run/[id]/fight | Бой в подземелье | + |

### Dungeon Rush
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| POST | /api/dungeon-rush/start | Начать Dungeon Rush | 3/10с |
| POST | /api/dungeon-rush/fight | Бой в Rush | + |
| GET | /api/dungeon-rush/status | Статус сессии | — |
| POST | /api/dungeon-rush/abandon | Отменить сессию | + |

### Inventory
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/inventory | Инвентарь персонажа | — |
| POST | /api/inventory/equip | Надеть предмет | 10/5с |
| POST | /api/inventory/unequip | Снять предмет | 10/5с |
| POST | /api/inventory/sell | Продать предмет | 10/5с |

### Consumables
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/consumables | Список расходников | — |
| POST | /api/consumables/use | Использовать расходник | + |

### Shop
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/shop/items | Товары по уровню | — |
| POST | /api/shop/buy | Купить предмет | 10/5с |
| POST | /api/shop/buy-potion | Купить зелье | + |
| POST | /api/shop/buy-consumable | Купить расходник | + |
| POST | /api/shop/buy-gold | Купить золото за гемы | + |
| POST | /api/shop/repair | Починить предмет | 10/10с |
| POST | /api/shop/upgrade | Улучшить предмет | 5/5с |

### Stamina
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| POST | /api/stamina/refill | Рефилл стамины за гемы | 5/10с |

### Minigames
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| POST | /api/minigames/shell-game | Shell Game | + |
| GET | /api/minigames/gold-mine | Статус Gold Mine | + |
| POST | /api/minigames/gold-mine/buy-slot | Купить слот | + |
| POST | /api/minigames/gold-mine/collect | Собрать награду | + |
| POST | /api/minigames/gold-mine/boost | Буст добычи | + |

### Quests
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/quests/daily | Ежедневные квесты | — |

### Daily Login **[NEW]**
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/daily-login | Статус логин-бонуса | — |
| POST | /api/daily-login/claim | Забрать награду | 3/мин |

### Achievements **[NEW]**
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/achievements | Все достижения персонажа | — |
| POST | /api/achievements/[key]/claim | Забрать награду | 5/мин |

### Battle Pass **[NEW]**
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/battle-pass | Текущий BP: уровень, XP, награды | — |
| POST | /api/battle-pass/claim/[level] | Забрать награду уровня | 5/мин |
| POST | /api/battle-pass/buy-premium | Купить Premium BP (500 gems) | 3/мин |

### Events **[NEW]**
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/events/active | Активные ивенты | — |

### Push Notifications **[NEW]**
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| POST | /api/push/register | Зарегистрировать push-токен | 5/мин |
| DELETE | /api/push/unregister | Удалить push-токен | 5/мин |

### IAP **[NEW]**
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| POST | /api/iap/verify | Валидация Apple receipt | 10/мин |
| POST | /api/iap/restore | Восстановление покупок | 5/мин |
| GET | /api/iap/products | Список IAP-продуктов и цен | — |

### Leaderboard
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET | /api/leaderboard | Топ по pvp_rating | — |

### Admin (расширен)
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET/POST | /api/admin/users | Управление пользователями | + |
| GET | /api/admin/matches | Матчи | + |
| GET | /api/admin/economy | Экономика | + |
| GET | /api/admin/characters | Персонажи | + |
| GET/POST | /api/admin/events | **[NEW]** Управление ивентами | + |
| GET | /api/admin/iap | **[NEW]** IAP транзакции | + |
| GET | /api/admin/achievements | **[NEW]** Статистика достижений | + |

### Dev
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET/POST | /api/dev/balance | Баланс тестирование | + |
| GET | /api/dev/tests | Тесты | + |
| GET | /api/dev/stats | Статистика | + |
| GET | /api/dev/health | Health check | + |

### Design Tokens
| Метод | Путь | Назначение | Rate Limit |
|-------|------|------------|------------|
| GET/POST | /api/design-tokens | Дизайн-токены | — |

---

## 7. Структура Godot-проекта (Mobile)

```
hexbound-mobile/
├── project.godot
├── export_presets.cfg
├── scenes/
│   ├── main/           — Main, Splash, Loading
│   ├── auth/           — Login, Register, Onboarding
│   ├── hub/            — Hub, CharacterPanel, NavBar
│   ├── combat/         — CombatScreen, Result, Loot, StanceSelector, vfx/
│   ├── arena/          — ArenaScreen, OpponentCard, RevengeList
│   ├── dungeon/        — DungeonSelect, DungeonRun, Boss
│   ├── inventory/      — InventoryScreen, ItemCard, EquipmentSlots
│   ├── shop/           — ShopScreen, IAPScreen
│   ├── minigames/      — ShellGame, GoldMine, DungeonRush
│   ├── battle_pass/    — BattlePassScreen, RewardTrack
│   ├── achievements/   — AchievementsScreen, AchievementCard
│   └── ui/             — компоненты (GameButton, GameCard, ProgressBar, Modal, Toast, HeroCard), themes/
├── scripts/
│   ├── autoload/       — GameManager, ApiClient, AuthManager, CacheManager, AudioManager, NotificationManager, AnalyticsManager
│   ├── api/            — CharacterApi, CombatApi, DungeonApi, InventoryApi, ShopApi, QuestApi, LeaderboardApi, AchievementApi, BattlePassApi, RevengeApi, IAPApi, EventApi, DailyLoginApi
│   ├── models/         — Character, Item, CombatLog, Quest, Achievement, BattlePassState
│   └── utils/          — SafeArea, HapticFeedback, Formatters
├── assets/
│   ├── sprites/        — персонажи, предметы
│   ├── ui/             — иконки, фоны, рамки
│   ├── vfx/            — эффекты частиц
│   ├── audio/music/    — фоновая музыка
│   ├── audio/sfx/      — звуковые эффекты
│   └── fonts/
├── addons/gut/         — тестирование
└── ios/                — Info.plist, export_options.plist, entitlements/
```

---

## 8. Безопасность

- Все API роуты проверяют auth через `supabase.auth.getUser()`
- In-memory rate limiting на критичных роутах (`lib/rate-limit.ts`)
- Security headers в `next.config.js`
- Prisma ORM — параметризованные запросы
- CORS: настроить для мобильных клиентов (Godot HTTPRequest)
- IAP: server-side receipt validation (никогда не доверять клиенту)
- Push tokens: валидация при регистрации
- Guest accounts: ограниченные действия до привязки email

---

## 9. Тестирование

- **Unit тесты** (Vitest): combat, damage, abilities, body-zones, elo, dungeon, loot, progression, stamina, stats, equipment, origins, weapon-affinity, stat-training, dungeon-rush, levelUp
- **Новые тесты:** achievements, daily-login, revenge, battle-pass, iap-verify, events, free-pvp, first-win
- **Component тесты**: GameButton, GameCard, GameBadge, ProgressBar
- **API тесты**: api-combat-simulate + все новые эндпоинты
- **E2E** (Playwright): Web-версия
- **Godot тесты** (GUT): ApiClient, AuthManager, CacheManager, модели
- Текущие 322 теста проходят ✓

---

*Документ актуален к 5 марта 2026. При изменении схемы или API — обновляй этот файл.*
