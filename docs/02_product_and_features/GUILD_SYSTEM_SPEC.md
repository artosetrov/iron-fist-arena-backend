# Guild System — MVP Spec (v1)

> **Статус**: DRAFT — обсуждение перед реализацией
> **Автор**: Claude + Artem
> **Дата**: 2026-04-01

---

## Проблема

Текущий Guild Hall — это контакт-лист (Allies) + личные сообщения (Scrolls) + 1v1 вызовы (Duels). По сути это Скайп, а не гильдия. Нет причины возвращаться каждый день, нет коллективной цели, нет социальной стикости.

Во всех успешных PvP RPG (Raid Shadow Legends, Summoners War, Clash Royale, AFK Arena) гильдия — это **боевая организация** с совместным контентом, еженедельным ритмом и уникальными наградами, которые нельзя получить в одиночку.

---

## Цели MVP

1. **Гильдия как сущность** — создание, вступление, иерархия, профиль
2. **Guild Raid Boss** — еженедельный кооперативный босс (главный retention hook)
3. **Гильдейская валюта + магазин** — уникальные награды за участие
4. **Пассивные баффы** — ощутимая выгода от членства
5. **Guild Chat** — общий чат (эволюция текущих Scrolls)

**НЕ входит в MVP**: Guild Wars (PvP гильдия vs гильдия), территории, донаты, лидерборд гильдий.

---

## 1. Гильдия как сущность

### Создание гильдии

| Параметр | Значение |
|----------|----------|
| Стоимость создания | 5000 gold |
| Минимальный уровень создателя | 10 |
| Максимум членов | 20 (MVP), позже до 50 |
| Название | 3–20 символов, уникальное, без спецсимволов |
| Описание | До 100 символов |
| Эмблема | Выбор из 12 preset иконок (MVP) |

### Иерархия

| Роль | Права |
|------|-------|
| **Leader** (1) | Всё: kick, promote, demote, disband, настройки |
| **Officer** (до 3) | Invite, kick рядовых, управление Guild Raid |
| **Member** | Участие в рейдах, чат, магазин |

- Leader может передать лидерство другому члену
- Если Leader неактивен 14 дней → автоматическая передача старшему Officer
- Если нет Officers → старшему по дате вступления Member

### Вступление

- **Open** — любой может вступить (до лимита)
- **Request** — заявка, Leader/Officer одобряют
- **Invite Only** — только по приглашению

### Выход и кик

- Игрок может покинуть гильдию в любой момент
- Кулдаун 24ч перед вступлением в другую гильдию (anti-hopping)
- Кикнутый — кулдаун 48ч
- При выходе: теряет гильдейские баффы мгновенно, гильдейская валюта сохраняется

### Расформирование

- Только Leader, если в гильдии ≤1 человек
- Или через голосование (будущая фича)

---

## 2. Guild Raid Boss (Главный контент)

### Концепция

Еженедельный босс с огромным HP. Каждый член гильдии может атаковать 2 раза в день. Суммарный урон определяет награды. Это **асинхронный PvE** — каждый бьёт в своё время, результат общий.

### Механика

| Параметр | Значение |
|----------|----------|
| Появление | Понедельник 00:00 UTC |
| Длительность | 7 дней (до воскресенья 23:59 UTC) |
| Атаки в день | 2 на члена |
| Стоимость атаки | 15 stamina |
| HP босса | Масштабируется по размеру гильдии |
| Тип боя | Используется существующий combat engine |

### Scaling HP босса

```
Boss HP = BASE_HP × (1 + (member_count - 1) × 0.6)

BASE_HP = 50,000
```

| Членов | HP босса | Примечание |
|--------|----------|-----------|
| 1 | 50,000 | Соло (тяжело, но возможно) |
| 5 | 170,000 | Маленькая гильдия |
| 10 | 320,000 | Средняя |
| 20 | 620,000 | Полная гильдия |

### Боевая механика

- Используется **существующий combat engine** (runCombat)
- Босс = специальный NPC-персонаж с уникальными абилками
- Бой длится фиксированные **10 раундов** (не до смерти босса)
- Урон за бой записывается и вычитается из HP босса
- Игрок видит свой урон + общий урон гильдии
- Босс **НЕ убивает** игрока (нет штрафа за проигрыш — только меньше урона)

### Еженедельные боссы (ротация)

| Босс | Тип | Особенность |
|------|-----|-------------|
| **Gorath the Unyielding** | Tank | Высокий DEF, низкий урон. Требует магический урон |
| **Vexara the Venomous** | Poison | DOT-урон, требует sustain-билды |
| **Ironclad Sentinel** | Physical | Отражает 20% физ. урона. Маги в приоритете |
| **Shadowmaw** | Agility | Высокий dodge. Точность (hit chance) важна |
| **Pyraxis** | Fire | AOE-урон каждые 3 раунда. Нужен HP/VIT |

### Награды

Награды зависят от **% HP снятого гильдией**:

| Порог | Название | Guild Marks | Gold | Gem |
|-------|----------|-------------|------|-----|
| 25% HP | Bronze | 50 | 500 | 0 |
| 50% HP | Silver | 100 | 1000 | 5 |
| 75% HP | Gold | 200 | 2000 | 10 |
| 100% HP | Legendary | 350 | 3500 | 25 |

**Бонус за топ-урон в гильдии:**

| Место | Бонус Guild Marks |
|-------|-------------------|
| 1st | +100 |
| 2nd | +60 |
| 3rd | +30 |

Награды раздаются **всем активным членам** (сделавшим ≥1 атаку за неделю). Неактивные не получают ничего.

---

## 3. Гильдейская валюта и магазин

### Guild Marks (Знаки Гильдии)

Новая валюта. Получается **только** через гильдейскую активность.

| Источник | Marks |
|----------|-------|
| Guild Raid Boss (награды порога) | 50–350/неделя |
| Guild Raid Boss (топ бонус) | 30–100/неделя |
| Guild Challenge (текущая система) | 25–75/неделя |
| Ежедневный логин в гильдии | 5/день |

**Примерный доход**: 100–500 Marks/неделя (зависит от активности).

### Guild Shop (Магазин гильдии)

Уникальные предметы, **недоступные** в обычном магазине:

| Предмет | Цена (Marks) | Описание |
|---------|-------------|----------|
| Guild Stamina Potion | 50 | +30 stamina (лимит 2/неделя) |
| Guild Repair Kit | 75 | Полный ремонт всего экипа |
| Guild XP Scroll | 100 | +25% XP на 1 час |
| Random Rare Item Box | 300 | Гарантированный rare+ предмет |
| Random Epic Item Box | 800 | Гарантированный epic+ предмет |
| Guild Emblem (cosmetic) | 500 | Уникальная рамка аватара |
| Legendary Shard (×1) | 200 | Собери 5 → случайный legendary |

**Правила:**
- Ассортимент обновляется каждый понедельник (вместе с новым боссом)
- Лимиты на покупку: расходники 2/неделя, боксы 1/неделя, cosmetics без лимита
- При выходе из гильдии — накопленные Marks **сохраняются**
- При расформировании гильдии — Marks сохраняются

---

## 4. Пассивные баффы гильдии

Гильдия получает **Guild XP** от активности членов. Каждый уровень разблокирует пассивный бафф для **всех** членов.

### Guild XP

| Действие | XP |
|----------|-----|
| Атака Guild Boss | +20 |
| PvP победа (любым членом) | +5 |
| Dungeon clear (любым членом) | +10 |
| Guild Challenge completion | +100 |

### Уровни и баффы

| Уровень | XP нужно | Бафф | Доп. слотов |
|---------|----------|------|-------------|
| 1 | 0 | — (создание) | 20 членов |
| 2 | 500 | +2% Gold всем | — |
| 3 | 1500 | +3% XP всем | +2 (22) |
| 4 | 3500 | +5% Gold всем | — |
| 5 | 7000 | +5% XP всем, Guild Shop Tier 2 | +3 (25) |
| 6 | 12000 | +2% Crit Chance всем | — |
| 7 | 20000 | +8% Gold всем | +5 (30) |
| 8 | 35000 | +8% XP всем | — |
| 9 | 55000 | +3% Defense всем | +5 (35) |
| 10 | 80000 | +10% Gold, +10% XP, Guild Shop Tier 3 | +15 (50) |

**Баффы стэкаются** (уровень 10 = +10% Gold + 10% XP + 2% Crit + 3% Defense).

**Баффы применяются на сервере** — клиент только отображает. Формула:

```
finalGold = baseGold × (1 + guildGoldBonus)
finalXP = baseXP × (1 + guildXPBonus)
```

---

## 5. Guild Chat

### Эволюция текущей системы

Сейчас Scrolls = DM между двумя игроками. Guild Chat = общий канал для всех членов.

| Параметр | Значение |
|----------|----------|
| Формат | Один общий канал |
| Лимит сообщений | 200 char, 30 в день |
| Хранение | 7 дней (auto-expire) |
| Модерация | Leader/Officer могут мьютить на 24ч |
| Системные сообщения | Вступление, выход, рейд-результаты, level up |

### Quick Messages (переиспользование)

Те же `QuickMessage` что в DM: gg, rematch, thanks, nice_fight, well_played, haha, wow, oops.

---

## 6. Реструктуризация UI

### Было (текущий Guild Hall)

```
Guild Hall
├── ALLIES (друзья)
├── SCROLLS (DM)
└── DUELS (1v1 вызовы)
```

### Стало (новый Guild Hall)

```
Guild Hall
├── OVERVIEW (профиль гильдии, баффы, уровень, текущий босс)
├── ROSTER (список членов, онлайн-статус, роли)
├── RAID (Guild Boss: HP bar, твой урон, лидерборд, атаковать)
├── SHOP (Guild Shop за Marks)
└── CHAT (Guild Chat)

Social Hub (отдельный экран, бывший Guild Hall)
├── FRIENDS (бывшие Allies)
├── MESSAGES (бывшие Scrolls / Messages — консолидация!)
└── DUELS (без изменений)
```

**Ключевое изменение**: разделяем **Guild** (коллективная организация) и **Social** (личные связи). Это убирает путаницу "гильдия = друзья" и устраняет дублирование Messages/Scrolls.

---

## 7. Интеграция с существующими системами

### Stamina

- Guild Raid атака стоит **15 stamina** (между dungeon easy и normal)
- Не влияет на PvP/dungeon лимиты

### Economy

- Guild Marks — **новая валюта**, отдельная от Gold/Gems/Arena Tokens
- Guild баффы увеличивают Gold/XP earnings → sink нужен (Guild Shop)
- Баланс: гильдейский бонус Gold (+10% max) компенсируется дополнительным spend (Guild Shop)

### Combat Engine

- Guild Boss использует **тот же runCombat()**, но с фиксированным числом раундов
- Босс = Character с предзаданными статами (не из БД пользователей)
- После боя: **нет ELO изменения**, нет loot drops, нет durability loss
- Только: запись урона + начисление Guild XP

### Achievements

- Новая категория: `"guild"` (4й таб в AchievementsView)
- Примеры: "Join a Guild", "Deal 100k damage to Guild Boss", "Reach Guild Level 5"

### Quest System

- Новый тип квеста: `guild_raid_attack` — "Attack the Guild Boss"
- Интегрируется в существующий `QuestType` enum

---

## 8. Database Schema (новые модели)

### Guild

```prisma
model Guild {
  id          String   @id @default(cuid())
  name        String   @unique
  description String   @default("")
  emblemId    Int      @default(0)
  leaderId    String
  level       Int      @default(1)
  xp          Int      @default(0)
  maxMembers  Int      @default(20)
  joinPolicy  String   @default("request") // open, request, invite
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  leader      Character      @relation("GuildLeader", fields: [leaderId], references: [id])
  members     GuildMember[]
  raidBosses  GuildRaidBoss[]
  chatMessages GuildChatMessage[]

  @@index([name])
}
```

### GuildMember

```prisma
model GuildMember {
  id          String   @id @default(cuid())
  guildId     String
  characterId String   @unique  // один персонаж = одна гильдия
  role        String   @default("member") // leader, officer, member
  joinedAt    DateTime @default(now())
  guildMarks  Int      @default(0)
  weeklyDamage Int     @default(0) // сброс каждый понедельник
  lastRaidAttack DateTime?

  guild     Guild     @relation(fields: [guildId], references: [id])
  character Character @relation(fields: [characterId], references: [id])

  @@index([guildId])
  @@index([characterId])
}
```

### GuildRaidBoss

```prisma
model GuildRaidBoss {
  id          String   @id @default(cuid())
  guildId     String
  bossType    String   // gorath, vexara, ironclad, shadowmaw, pyraxis
  maxHp       Int
  currentHp   Int
  totalDamage Int      @default(0)
  startAt     DateTime
  endAt       DateTime
  completed   Boolean  @default(false)
  rewardTier  String?  // bronze, silver, gold, legendary
  createdAt   DateTime @default(now())

  guild   Guild              @relation(fields: [guildId], references: [id])
  attacks GuildRaidAttack[]

  @@index([guildId, startAt])
}
```

### GuildRaidAttack

```prisma
model GuildRaidAttack {
  id          String   @id @default(cuid())
  raidBossId  String
  characterId String
  damage      Int
  rounds      Int      @default(10)
  createdAt   DateTime @default(now())

  raidBoss  GuildRaidBoss @relation(fields: [raidBossId], references: [id])
  character Character     @relation(fields: [characterId], references: [id])

  @@index([raidBossId])
  @@index([characterId, createdAt])
}
```

### GuildChatMessage

```prisma
model GuildChatMessage {
  id          String   @id @default(cuid())
  guildId     String
  senderId    String
  content     String
  isSystem    Boolean  @default(false)
  isQuick     Boolean  @default(false)
  quickId     String?
  createdAt   DateTime @default(now())
  expiresAt   DateTime // +7 дней

  guild   Guild     @relation(fields: [guildId], references: [id])
  sender  Character @relation(fields: [senderId], references: [id])

  @@index([guildId, createdAt])
  @@index([expiresAt])
}
```

### Изменение Character

```prisma
// Добавить в Character:
guildMember   GuildMember?
guildRaidAttacks GuildRaidAttack[]
guildChatMessages GuildChatMessage[]
```

---

## 9. API Endpoints (новые)

| Method | Route | Описание |
|--------|-------|----------|
| GET | `/api/guild` | Получить гильдию игрока (или null) |
| POST | `/api/guild/create` | Создать гильдию |
| POST | `/api/guild/join` | Вступить / подать заявку |
| POST | `/api/guild/leave` | Покинуть гильдию |
| POST | `/api/guild/manage` | Kick, promote, demote, transfer, settings |
| GET | `/api/guild/search` | Поиск гильдий по имени |
| GET | `/api/guild/raid` | Текущий рейд-босс, HP, урон |
| POST | `/api/guild/raid/attack` | Атаковать босса |
| GET | `/api/guild/shop` | Ассортимент магазина |
| POST | `/api/guild/shop/buy` | Купить предмет |
| GET | `/api/guild/chat` | Получить сообщения чата |
| POST | `/api/guild/chat/send` | Отправить сообщение в чат |

---

## 10. Фазы реализации

### Фаза 1 — Структура (3–4 дня)

- [ ] Prisma schema: Guild, GuildMember, GuildRaidBoss, GuildRaidAttack, GuildChatMessage
- [ ] API: create, join, leave, manage, search
- [ ] iOS: GuildViewModel, GuildService
- [ ] iOS: Overview таб, Roster таб
- [ ] Рефактор: Guild Hall → разделение на Guild + Social Hub

### Фаза 2 — Guild Raid Boss (3–4 дня)

- [ ] Backend: Boss templates, HP scaling, attack endpoint
- [ ] Backend: Интеграция с combat engine (10-round mode)
- [ ] Backend: Reward calculation + distribution
- [ ] iOS: Raid таб (boss HP bar, attack button, damage leaderboard)
- [ ] iOS: Raid result screen (урон, награды)
- [ ] Cron: Weekly boss rotation

### Фаза 3 — Currency & Shop (2–3 дня)

- [ ] Backend: Guild Marks tracking
- [ ] Backend: Shop catalog + buy endpoint
- [ ] iOS: Shop таб
- [ ] iOS: Guild Marks в CurrencyDisplay
- [ ] Интеграция Marks в гильдейские активности

### Фаза 4 — Баффы & Chat (2–3 дня)

- [ ] Backend: Guild level + XP tracking
- [ ] Backend: Apply buffs to Gold/XP calculations
- [ ] Backend: Chat endpoints
- [ ] iOS: Overview с баффами и уровнем
- [ ] iOS: Chat таб
- [ ] Системные сообщения (join, leave, raid result)

### Фаза 5 — Багфиксы текущего кода (параллельно)

- [ ] Fix: Failed to load allies — error handling в SocialService
- [ ] Fix: Гонка данных в полинге сообщений
- [ ] Fix: Проверка дружбы при отправке сообщений (backend)
- [ ] Fix: Гонка в cancelOutgoingChallenge
- [ ] Fix: Обработка сетевых ошибок в полинге
- [ ] Fix: Проверка expiry челленджей на клиенте

---

## 11. Риски и открытые вопросы

### Риски

1. **Маленькая база игроков** → гильдии из 2–3 человек не осилят босса
   - *Митигация*: HP скейлится по размеру; соло возможно, но тяжело
2. **Сложность combat engine для босса** → босс не использует стандартный PvP
   - *Митигация*: Босс = Character с preset stats, используем тот же runCombat()
3. **Инфляция Guild Marks** → слишком легко/тяжело копить
   - *Митигация*: Лимиты покупок + еженедельный сброс магазина

### Открытые вопросы

1. **Guild vs Guild Wars** — добавлять в MVP или в Фазе 2?
   - Рекомендация: НЕ в MVP. Сначала убедиться что Guild Boss работает как retention hook
2. **Лидерборд гильдий** — нужен?
   - Рекомендация: Да, но post-MVP (когда будет ≥10 гильдий)
3. **Названия в лоре** — "Guild" или "Order" / "Clan" / "Warband"?
   - Предложение: **Warband** (подходит к dark fantasy тематике Hexbound)
4. **Миграция Guild Challenge** — текущий server-wide челлендж → per-guild?
   - Рекомендация: Оставить server-wide КАК ЕСТЬ + добавить per-guild рейд отдельно

---

## Конкурентный контекст

| Фича Hexbound | Аналог в Raid SL | Аналог в Clash Royale | Аналог в AFK Arena |
|---------------|-------------------|----------------------|-------------------|
| Guild Raid Boss | Clan Boss | — | Guild Hunt (Wrizz/Soren) |
| Guild Marks + Shop | Clan Gold + Shop | War Medals + Shop | Guild Coins + Shop |
| Passive Buffs | Clan Perks | — | — |
| Guild Chat | Clan Chat | Clan Chat | Guild Chat |
| Guild Level | Clan Level | Clan Level | Guild Level |
| Weekly rotation | Weekly boss | Weekly River Race | Daily boss availability |

---

*Этот документ — точка обсуждения. После утверждения структуры — начинаем реализацию по фазам.*
