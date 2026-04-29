# Hexbound — Onboarding & Tutorial Spec (Historical Planning Snapshot)

> **Статус:** Historical planning snapshot | **Updated:** 2026-04-29
> **Boundary:** this file is no longer the canonical source for exact welcome-gift
> values, building unlock levels, tutorial quest unlock schedule, or rollout
> phases.
>
> **Live source of truth now lives in:**
> - `wiki/features/onboarding.md`
> - `wiki/features/tutorial.md`
> - `backend/src/lib/game/tutorial.ts`
> - `backend/src/app/api/tutorial/route.ts`
> - `Hexbound/Hexbound/Views/Auth/*`
> - `Hexbound/Hexbound/Tutorial/TutorialManager.swift`
>
> **Why this matters:** onboarding and tutorial are both shipped, but the runtime
> has evolved since this design pass. Several concrete values below are now
> historical proposal material rather than live truth, including:
> - building unlock schedule
> - tutorial quest unlock levels
> - first-session economy table
> - MVP/Phase implementation checklists
>
> Read this document as the earlier design intent and UX framing, not as the
> authoritative runtime contract.

## Философия

Ниже сохранён исходный planning layer: narrative framing, tutorial beats, and
rollout intent. For the live repo, prefer the feature maps and backend tutorial
helpers listed above.

Три слоя, включающиеся последовательно:

1. **Hard Guided Tutorial** (Lv1, 3-4 минуты) — затемнение, spotlight, NPC ведёт за руку. Игрок не может уйти с пути. Цель: первое оружие + первая победа.
2. **NPC Quest Chain** (Lv1→15) — NPC на Hub даёт квесты привязанные к progressive unlock зданий. Игрок свободен, но квесты мягко направляют.
3. **First-Entry Micro-Tutorials** — каждое здание при первом входе показывает 2-3 spotlight шага. Лёгкие, пропускаемые.

Референсы: AFK Arena (короткий forced tutorial → свобода), Epic Seven (мини-туториалы при unlock), Raid (щедрый стартер).

---

## Часть 1: Hard Guided Tutorial

### Триггер

Сразу после `OnboardingDetailView` (создание персонажа: класс → внешность → имя). Игрок попадает на Hub впервые.

### Welcome Gift (выдаётся при создании персонажа)

| Предмет | Количество | Обоснование |
|---------|-----------|-------------|
| Золото | 500g | = 2.5 PvP победы. Хватит на 1 предмет в шопе |
| Оружие класса (Common) | 1 шт | Warrior→меч, Rogue→кинжал, Mage→посох, Tank→щит. Экипируется в туториале |
| Stamina бонус | +50 | Гарантия 5+ боёв в первой сессии |
| Зелье здоровья (Small) | 2 шт | Первое знакомство с consumables |

Оружие: Common Lv1, статы = стандартный Common из shop_items. НЕ уникальный предмет — то же самое можно купить в шопе. Это важно чтобы не создавать ощущение "у меня туториальный мусор".

### Шаг 1: Hub Intro (30 сек)

```
[Экран Hub загружается. Все здания видны но затемнены кроме Hero Widget]
[NPCGuideWidget появляется снизу, typewriter animation]

NPC: "Добро пожаловать в Hexbound, {characterName}! 
      Я — Каэль, смотритель этого города.
      Давай покажу тебе что к чему."

[Spotlight на Hero Widget]
NPC: "Это ты — {className} {level} уровня. 
      У тебя уже есть стартовое оружие. Давай его наденем."

[CTA кнопка: "Экипировать" → переход в инвентарь]
```

### Шаг 2: Экипировка (30 сек)

```
[Экран инвентаря. Spotlight на оружие в рюкзаке]
NPC: "Нажми на оружие чтобы экипировать."

[Игрок нажимает → оружие экипируется]
[Анимация power spike: статы мигают, числа растут]

NPC: "Отлично! Теперь ты вооружён. Время для боя."

[CTA: "На арену!" → возврат на Hub → spotlight на Arena]
```

### Шаг 3: Первый бой (2-3 мин)

```
[Hub. Только Arena кликабельна]
[Игрок нажимает Arena → экран арены]

[Spotlight на единственного противника — Tutorial Bot]
NPC: "Вот твой первый противник. Не бойся — 
      каждый великий воин начинал с первого боя."

[CTA: "Сражаться!"]
```

**Во время боя** (3 подсказки, показываются один раз):

```
[Раунд 1 — выбор атаки]
NPC: "Выбери зону атаки: голова — шанс на крит,
      тело — надёжный урон, ноги — шанс замедлить."

[Раунд 1 — выбор защиты]  
NPC: "Теперь защита. Угадай куда ударит враг —
      и получишь бонус к блоку."

[После первого нанесённого урона]
NPC: "Отличный удар! Продолжай в том же духе."
```

**Tutorial Bot** (бэкенд):
- `is_tutorial_opponent: true` в Character или отдельная таблица
- Статы = 60% от стартовых Lv1 (гарантированная победа за 3-5 раундов)
- Класс: Warrior (предсказуемый, без магии)
- НЕ влияет на ELO, НЕ попадает в лидерборд
- Имя: "Тренировочный голем" / "Training Golem"

### Шаг 4: Победа и награда (30 сек)

```
[Battle Result экран — ПОБЕДА]
[Показываем награды с анимацией]
+400g (200g × 2.0 First Win бонус)
+300 XP (150 × 2.0 First Win бонус)
[XP бар заполняется → если хватает, Level Up!]

NPC: "Победа! Ты уже на пути к величию.
      Город ждёт — исследуй его!"

[CTA: "Вернуться в город"]
```

### Шаг 5: Завершение Hard Tutorial (15 сек)

```
[Hub. Все доступные здания (Arena, Shop) разблокированы]
[NPC сворачивается в NPCMiniButton (floating)]

NPC: "Я буду рядом если понадоблюсь. 
      Нажми на меня когда захочешь совет."

[NPCMiniButton пульсирует 3 секунды, потом затухает]
[Tutorial complete flag → TutorialManager.hardTutorialCompleted = true]
```

**Итого Hard Tutorial:** ~3-4 минуты. Результат: игрок вооружён, выиграл бой, понимает core loop.

---

## Часть 2: Progressive Building Unlock

### Таблица unlock

| Уровень | Накоп. XP | ~Боёв | Unlock | Время игры |
|---------|----------|-------|--------|-----------|
| **Lv1** | 0 | 0 | Arena, Shop *(tutorial)* | 0 мин |
| **Lv3** | 640 | 3-4 wins | Dungeon | ~15 мин |
| **Lv5** | 1,200 | 6-8 wins | Gold Mine | ~30 мин |
| **Lv7** | 1,960 | 10-12 wins | Tavern (Shell Game, Fortune Wheel) | День 2 |
| **Lv10** | 3,000 | 18-20 wins | Battle Pass, Leaderboard | День 3-4 |
| **Lv15** | ~5,500 | ~35 wins | Guild Hall | Неделя 1-2 |

### Механика unlock

**На Hub:**
- Locked здания видны, но с оверлеем: иконка замка + текст "Lv.5"
- Цвет locked: `DarkFantasyTheme.surfaceDark` с `opacity(0.5)`
- При нажатии на locked: toast "Откроется на уровне 5"

**При достижении уровня:**
1. Level Up модалка (уже есть: `LevelUpModalView`)
2. Если unlock здания → доп. секция в модалке: "Новое здание: Подземелья!"
3. Возврат на Hub → здание появляется с gold glow анимацией (2 сек)
4. `NPCMiniButton` пульсирует → при нажатии NPC даёт квест

### Бэкенд

Таблица `building_unlocks` или поле в Character:

```
model Character {
  // ... existing fields
  tutorialStep    Int      @default(0)  // 0=new, 1=equipped, 2=first_fight, 3=completed
  unlockedBuildings String[] @default(["arena", "shop"]) // прогрессивно расширяется
}
```

Альтернатива: конфиг на клиенте (проще, но не серверно-авторитетно):

```swift
static let buildingUnlockLevels: [String: Int] = [
    "arena": 1,
    "shop": 1,
    "dungeon": 3,
    "gold_mine": 5,
    "tavern": 7,
    "battle_pass": 10,
    "leaderboard": 10,
    "guild": 15
]
```

**Рекомендация:** клиентский конфиг для MVP (быстро), миграция на сервер позже. Уровень персонажа уже серверный — клиент просто проверяет `character.level >= unlockLevel`.

---

## Часть 3: NPC Quest Chain

### NPC персонаж

**Имя:** Каэль (Kael) — смотритель города
**Аватар:** NPC из существующих ассетов (`05_UI_Backgrounds/`)
**Поведение:** появляется как `NPCMiniButton` на Hub, пульсирует когда есть новый квест

### Цепочка квестов

#### Quest 1: "Снаряжение воина" (Lv1, после hard tutorial)

```
NPC: "У тебя есть оружие, но защита хромает. 
      Загляни в Лавку — подбери себе доспех."

Цель: Купить любой предмет в Shop
Награда: 200g бонус
Маркер: NPCMiniButton пульсирует → при нажатии показывает квест
         Shop building имеет quest indicator (восклицательный знак)
```

#### Quest 2: "Боевая закалка" (Lv1-2)

```
NPC: "Один бой — это начало. 
      Выиграй ещё 3 боя на арене чтобы набраться опыта."

Цель: Выиграть 3 PvP боя
Награда: 300g + 1 Health Potion (Medium)
Прогресс: показывается как 1/3, 2/3, 3/3
```

#### Quest 3: "Тьма подземелий" (Lv3, при unlock Dungeon)

```
NPC: "Под городом скрываются подземелья. 
      Мало кто возвращается с первого этажа... 
      Но ты справишься. Победи босса."

Цель: Пройти Dungeon Floor 1
Награда: 200g + Uncommon предмет (random slot)
```

#### Quest 4: "Золотая жила" (Lv5, при unlock Mine)

```
NPC: "Золотая шахта — твой пассивный доход. 
      Запусти добычу и вернись через 4 часа."

Цель: Запустить 1 mining слот
Награда: Мгновенное завершение первого цикла (вместо 4 часов)
```

#### Quest 5: "Испытай удачу" (Lv7, при unlock Tavern)

```
NPC: "В таверне играют на золото. 
      Shell Game — угадай где шарик. Попробуй разок."

Цель: Сыграть 1 раунд Shell Game
Награда: 100g бонус (независимо от результата)
```

#### Quest 6: "Путь славы" (Lv10, при unlock Battle Pass + Leaderboard)

```
NPC: "Ты вырос. Время для серьёзных наград.
      Боевой пропуск хранит сокровища для лучших воинов.
      А таблица лидеров покажет на что ты способен."

Цель: Открыть экран Battle Pass + посмотреть Leaderboard
Награда: 1 бесплатный BP level
```

#### Quest 7: "Братство" (Lv15, при unlock Guild)

```
NPC: "Одинокий волк далеко не уйдёт.
      Вступи в гильдию — или создай свою."

Цель: Вступить в гильдию
Награда: 500g + guild welcome pack
```

### Хранение квестов

```swift
struct TutorialQuest: Identifiable, Codable {
    let id: String           // "equip_gear", "win_3_pvp", etc.
    let unlockLevel: Int
    let title: String
    let npcMessage: String
    let objective: String
    let progress: Int        // текущий (0)
    let target: Int          // цель (3 для "win_3_pvp")
    var isCompleted: Bool
    var isActive: Bool       // показывается NPC
    let rewards: [TutorialReward]
}
```

Прогресс хранится в `UserDefaults` (MVP) или серверно (позже). Квест становится `isActive = true` когда `character.level >= unlockLevel` и предыдущий квест завершён.

---

## Часть 4: First-Entry Micro-Tutorials

Показываются ОДИН раз при первом входе в здание (после unlock). Формат: overlay с spotlight + NPC bubble. Кнопка "Далее" / "Пропустить".

### Arena (если вход не через tutorial)

```
Step 1: [Spotlight на карусель противников]
"Свайпни чтобы выбрать противника. 
 Сравни статы прежде чем сражаться."

Step 2: [Spotlight на кнопку "Сражаться"]
"Готов? Нажми чтобы начать бой."
```

### Dungeon

```
Step 1: [Spotlight на список этажей]
"10 этажей, каждый сложнее предыдущего. 
 Босс на каждом этаже охраняет награду."

Step 2: [Spotlight на difficulty indicator]
"Цвет показывает сложность для тебя: 
 зелёный — легко, красный — опасно."
```

### Gold Mine

```
Step 1: [Spotlight на слоты]
"Выбери слот и запусти добычу. 
 Каждый цикл — 4 часа."

Step 2: [Spotlight на таймер]
"Вернись когда таймер закончится. 
 Не забудь — золото ждёт!"
```

### Shop

```
Step 1: [Spotlight на фильтры]
"Фильтруй по типу снаряжения. 
 Предметы подобраны для твоего уровня."

Step 2: [Spotlight на предмет с best value indicator]
"Зелёная стрелка = улучшение твоих текущих статов."
```

### Passive Tree (при первом получении passive point)

```
Step 1: [Spotlight на дерево]
"Каждый уровень даёт очко пассивок. 
 Выбирай узлы под свой стиль боя."

Step 2: [Spotlight на связи между узлами]
"Некоторые узлы усиливают друг друга. 
 Ищи синергии!"
```

### Tavern

```
Step 1: [Spotlight на Shell Game]
"Shell Game — классика. Следи за шариком, 
 ставь золото, выигрывай вдвойне."
```

---

## Часть 5: Экономика первой сессии

### Поминутный breakdown (оптимальный путь)

| Мин | Действие | Gold Δ | XP Δ | Уровень | Stamina |
|-----|----------|--------|------|---------|---------|
| 0 | Welcome Gift | +500g | — | 1 | 120+50 |
| 1 | Экипировать оружие | — | — | 1 | 170 |
| 2 | Tutorial бот (win, First Win ×2) | +400g | +300 | 1→2 | 170 (free) |
| 5 | NPC Quest 1: купить в шопе | -400g, +200g бонус | — | 2 | 170 |
| 8 | PvP #2 (free daily) | +200g | +150 | 2 | 170 |
| 11 | PvP #3 (free daily) | +200g | +150 | 2→3 | 170 |
| — | **UNLOCK: Dungeon** | — | — | 3 | — |
| 14 | NPC Quest 3: Dungeon Floor 1 | +200g бонус + loot | +200 | 3 | 155 (-15) |
| 18 | PvP #4 (free daily) | +200g | +150 | 3→4 | 155 |
| 21 | PvP #5 (free daily) | +200g | +150 | 4 | 155 |
| 24 | PvP #6 (stamina) | +200g | +150 | 4→5 | 145 (-10) |
| — | **UNLOCK: Gold Mine** | — | — | 5 | — |
| 27 | NPC Quest 4: запустить Mine | мгновенный цикл (+100g) | — | 5 | 145 |
| 30 | Шоп: купить 2-й предмет | -500g | — | 5 | 145 |

### Итоги первой сессии (30 мин)

| Метрика | Значение |
|---------|----------|
| Уровень | 5 |
| Золото (net) | ~1,100g |
| Предметы | 3 (starter weapon + 2 bought) |
| PvP боёв | 6 (5 free + 1 stamina) |
| Dungeons | 1 |
| Здания unlocked | 4 (Arena, Shop, Dungeon, Mine) |
| Квестов выполнено | 4 |
| Stamina остаток | ~145 |

### Вторая сессия (День 2, ~20 мин)

- Daily login reward: +200g (Day 2: stamina potion)
- 5 free PvP → Lv6-7
- Unlock Tavern (Lv7)
- NPC Quest 5: Shell Game
- Passive tree: первые очки
- Mine: забрать золото (60-150g)

### К концу недели 1

- Уровень: ~12-15
- Все здания кроме Guild unlocked
- Battle Pass активен
- 3-5 предметов Uncommon+
- Passive tree: 10+ узлов
- Понимает все core механики

---

## Часть 6: UI компоненты (что нужно создать/изменить)

### Новые компоненты

| Компонент | Описание | Приоритет |
|-----------|----------|-----------|
| `TutorialOverlayView` | Затемнение + spotlight hole + NPC bubble | P0 |
| `BuildingLockOverlay` | Замок + "Lv.X" поверх locked здания | P0 |
| `QuestIndicator` | Восклицательный знак над зданием | P0 |
| `QuestBannerView` | Баннер активного квеста (collapsible) | P1 |
| `UnlockCelebrationView` | Анимация unlock нового здания | P1 |
| `TutorialBotProfile` | Профиль Tutorial Golem для арены | P1 |

### Модификации существующих

| Компонент | Изменение |
|-----------|-----------|
| `NPCGuideWidget` | Добавить квест-mode (progress bar, reward preview) |
| `NPCMiniButton` | Добавить пульсацию при новом квесте |
| `HubView` / `CityMapView` | Lock overlay на зданиях, quest indicators |
| `LevelUpModalView` | Секция "New Building Unlocked!" |
| `TutorialManager` | Расширить: квесты, building unlocks, micro-tutorials |
| `ArenaView` | Поддержка tutorial bot как первого противника |

### Бэкенд изменения

| Что | Описание |
|-----|----------|
| Welcome Gift endpoint | `POST /api/tutorial/welcome-gift` — выдаёт gold + weapon + stamina + potions |
| Tutorial Bot | Запись в `Character` с `is_tutorial_bot: true`, фиксированные статы |
| Tutorial progress | Поле `tutorial_step` в Character (или отдельная таблица) |
| Quest completion | `POST /api/tutorial/complete-quest` — выдаёт награды |

---

## Часть 7: Приоритизация реализации

> Historical implementation checklist. Do not treat this section as the current
> rollout tracker for the shipped onboarding/tutorial runtime.

### Phase 1: MVP (1-2 недели)

- [ ] Welcome Gift (backend + iOS)
- [ ] Tutorial Bot (backend: создать, iOS: показать как первого оппонента)
- [ ] Hard Guided Tutorial (5 шагов, TutorialOverlayView)
- [ ] Building Lock на Hub (клиентский конфиг unlock levels)
- [ ] TutorialManager расширение (шаги + flags)

### Phase 2: Quest System (1 неделя)

- [ ] NPC Quest Chain (7 квестов)
- [ ] Quest UI (NPCGuideWidget quest mode, QuestBannerView)
- [ ] Quest indicators на зданиях
- [ ] Unlock celebration анимация

### Phase 3: Micro-Tutorials (3-4 дня)

- [ ] First-entry tooltips для каждого здания (6 зданий × 2 шага)
- [ ] Passive tree tutorial
- [ ] "Пропустить" / "Больше не показывать"

### Phase 4: Polish (3-4 дня)

- [ ] NPC Каэль: уникальный арт + анимации
- [ ] Звуковые эффекты для unlock / quest complete
- [ ] A/B тест: с tutorial vs без (analytics events)
- [ ] Retention tracking: D1/D3/D7 по когортам

---

## Часть 8: Аналитика

> Historical / planning analytics layer. The current tutorial funnel split is
> documented in `wiki/features/tutorial.md` and `backend/src/lib/game/tutorial-analytics.ts`.

### Ключевые события для трекинга

| Событие | Параметры | Зачем |
|---------|-----------|-------|
| `tutorial_step_completed` | step_id, duration_sec | Где отваливаются |
| `tutorial_skipped` | at_step, total_steps | Сколько скипают |
| `building_unlocked` | building_id, level, session_count | Пейсинг unlock |
| `npc_quest_started` | quest_id | Engagement с квестами |
| `npc_quest_completed` | quest_id, duration_min | Скорость прохождения |
| `micro_tutorial_shown` | building_id | Показы |
| `micro_tutorial_skipped` | building_id, at_step | Скипы |
| `first_pvp_result` | win/loss, duration_sec | Туториальный бой |
| `first_shop_purchase` | item_id, gold_spent | Первая покупка |
| `first_dungeon_result` | floor, win/loss | Первый данж |

### Целевые метрики

| Метрика | Цель | Алерт если |
|---------|------|-----------|
| Tutorial completion rate | > 85% | < 70% |
| D1 retention (с tutorial) | > 40% | < 30% |
| First PvP win rate | > 90% (tutorial bot) | < 85% |
| Lv5 reach rate (Day 1) | > 60% | < 40% |
| Quest completion rate | > 70% per quest | < 50% |

---

## Решения по архитектуре

### NPC арт

Каэль использует **существующий NPC ассет** из `05_UI_Backgrounds/`. Уникальный арт — Phase 4 (polish), не блокирует MVP.

### Клиент vs Сервер — разделение ответственности

| Что | Где | Почему |
|-----|-----|--------|
| Building unlock levels | **Клиент** (статический конфиг) | Это справочная таблица, не state. Уровень персонажа уже серверный — клиент просто сверяет `character.level >= config[building]`. Даже при хаке клиента сервер не даст войти в данж без уровня. |
| Tutorial progress (step) | **Сервер** (поле в Character) | Welcome gift выдаёт бэкенд — без серверного флага можно переустановить приложение и получить gift повторно. |
| Quest completion | **Сервер** (таблица tutorial_quests) | Награды за квесты = золото/предметы — должно быть серверно-авторитетно. |
| Micro-tutorial seen flags | **Клиент** (UserDefaults) | Чисто UI state, не влияет на экономику. Потеря при переустановке = показ tooltips повторно (не критично). |
| First-entry flags | **Клиент** (UserDefaults) | Аналогично micro-tutorials. |

**Бэкенд модель:**

```prisma
// Добавить в model Character
model Character {
  // ... existing fields
  tutorialStep      Int      @default(0)    // 0=new, 1=equipped, 2=first_fight, 3=tutorial_done
  tutorialSkipped   Boolean  @default(false) // true если нажал "Пропустить"
  referredBy        String?  // character_id пригласившего
  prestigeCount     Int      @default(0)    // >0 = не показывать tutorial
}

// Новая таблица
model TutorialQuest {
  id            String   @id @default(cuid())
  characterId   String
  questId       String   // "equip_gear", "win_3_pvp", "first_dungeon", etc.
  progress      Int      @default(0)
  target        Int
  isCompleted   Boolean  @default(false)
  completedAt   DateTime?
  rewardClaimed Boolean  @default(false)
  character     Character @relation(fields: [characterId], references: [id])
  
  @@unique([characterId, questId])
}
```

**API endpoints:**

```
POST /api/tutorial/welcome-gift     — выдаёт starter pack (только если tutorialStep=0)
POST /api/tutorial/advance-step     — продвигает tutorialStep (1→2→3)
POST /api/tutorial/skip             — tutorialStep=3, tutorialSkipped=true, выдаёт welcome gift
POST /api/tutorial/quest/progress   — обновляет progress квеста
POST /api/tutorial/quest/claim      — клеймит награду за завершённый квест
GET  /api/tutorial/state            — возвращает tutorialStep + все квесты + rewards
```

### Skip Tutorial

**Да.** После создания персонажа, перед началом hard tutorial — кнопка "Пропустить обучение".

```
[Экран Hub загружается]
[NPCGuideWidget появляется]

NPC: "Добро пожаловать в Hexbound! Давай покажу город."

[Две кнопки:]
  [Поехали!]                     ← начинает hard tutorial
  [Пропустить (опытный игрок)]   ← мелкий текст, secondary style
```

При скипе:
- `tutorialStep = 3` (completed), `tutorialSkipped = true`
- Welcome Gift выдаётся полностью (500g + weapon + stamina + potions)
- Оружие **НЕ экипируется автоматически** (игрок сам разберётся)
- Все здания для текущего уровня разблокированы
- NPC квесты активируются нормально (мягкие подсказки полезны даже опытным)
- Micro-tutorials при первом входе **показываются** (можно пропустить)
- Аналитика: `tutorial_skipped` event с `at_step=0`

### Referral System

Ссылка приглашения доступна в **Settings** (экран настроек).

**Формат ссылки:** `https://hexboundapp.com/invite/{referral_code}`
**Referral code:** 8-символьный уникальный код, генерируется при создании персонажа.

**Бонусы:**

| Кто | Бонус | Когда |
|-----|-------|-------|
| **Любой новый игрок** | Welcome Gift: 500g + Common weapon (class-specific) + 50 stamina + 2 health potions | При POST /api/tutorial |
| **Новый игрок** (пришёл по ссылке) | Welcome Gift + 250g бонус = 750g total | При POST /api/tutorial с referral_code |
| **Пригласивший** | 500g + 10 gems | Когда приглашённый достигает Lv5 (proof of engagement) |

**Ограничения:**
- Максимум 20 реферальных бонусов на аккаунт (анти-абьюз)
- Приглашённый должен дойти до Lv5 чтобы пригласивший получил бонус
- Self-referral невозможен (проверка по device_id / IP на бэке)

**Бэкенд:**

```prisma
model ReferralCode {
  id          String   @id @default(cuid())
  characterId String   @unique
  code        String   @unique // 8-char alphanumeric
  usedCount   Int      @default(0)
  maxUses     Int      @default(20)
  character   Character @relation(fields: [characterId], references: [id])
}

model ReferralUse {
  id              String   @id @default(cuid())
  referralCodeId  String
  referredCharId  String   @unique // один аккаунт = один реферал
  rewardClaimed   Boolean  @default(false) // бонус пригласившему
  claimedAt       DateTime?
  createdAt       DateTime @default(now())
  referralCode    ReferralCode @relation(fields: [referralCodeId], references: [id])
}
```

**UI в Settings:**

```
┌─────────────────────────────────┐
│ Пригласи друга                   │
│                                  │
│ Твой код: HEXB-A7K2              │
│ [Копировать ссылку]  [Поделиться]│
│                                  │
│ Друг получит: 750g + оружие      │
│ (500g base + 250g bonus)         │
│ Ты получишь: 500g + 10 gems      │
│                                  │
│ Приглашено: 3/20                 │
└─────────────────────────────────┘
```

### Prestige

**Нет, туториал НЕ показывается после prestige.** 

Проверка: `if character.prestigeCount > 0 || character.tutorialStep >= 3 → skip tutorial`.

При prestige:
- `tutorialStep` остаётся = 3
- Здания остаются unlocked (prestige не лочит контент)
- NPC квесты НЕ сбрасываются
- Referral code сохраняется

---

## Обновлённая приоритизация

### Phase 1: MVP (1-2 недели)

- [ ] Prisma: `tutorialStep`, `tutorialSkipped`, `prestigeCount` в Character
- [ ] Prisma: `TutorialQuest` таблица
- [ ] Backend: Welcome Gift endpoint (с проверкой tutorialStep=0)
- [ ] Backend: Tutorial Bot character (is_tutorial_bot, слабые статы)
- [ ] Backend: Tutorial step advancement + skip endpoints
- [ ] iOS: `TutorialOverlayView` (затемнение + spotlight + NPC bubble)
- [ ] iOS: Hard Guided Tutorial (5 шагов с NPC диалогами)
- [ ] iOS: Skip tutorial кнопка
- [ ] iOS: Building Lock overlay на Hub (клиентский конфиг)
- [ ] iOS: `TutorialManager` расширение (шаги + flags + серверная синхронизация)

### Phase 2: Quest System (1 неделя)

- [ ] Backend: Quest progress + claim endpoints
- [ ] iOS: NPC Quest Chain (7 квестов)
- [ ] iOS: Quest UI (NPCGuideWidget quest mode, QuestBannerView)
- [ ] iOS: Quest indicators на зданиях
- [x] iOS: Unlock celebration анимация в LevelUpModalView (dynamic from BuildingUnlockConfig)

### Phase 3: Micro-Tutorials + Referral (1 неделя) — DONE

- [x] iOS: Dungeon entry tutorialOverlay + tutorialAnchor (Arena/Shop were already wired)
- [ ] iOS: Passive tree tutorial (deferred — not yet implemented)
- [x] Prisma: referralCode + referredBy fields on Character model
- [x] Backend: GET/POST /api/tutorial/referral — code generation, validation, apply bonus
- [x] iOS: ReferralSectionView in Settings (code + share + friend input + stats)
- [x] iOS: Referral code entry during character creation (POST /tutorial accepts referral_code)

### Phase 4: Polish (3-4 дня) — DONE

- [x] SFX: uiRewardClaim on quest claim, uiTap on navigate, dungeonUnlock on building unlock in LevelUpModal
- [x] Analytics: structured JSON event logging (tutorial-analytics.ts) — 8 events across all endpoints
- [ ] NPC Каэль: подобрать лучший ассет / заказать арт (using "shopkeeper" placeholder)
- [ ] A/B тест: с tutorial vs без (requires client analytics SDK)
- [ ] Retention tracking: D1/D3/D7 по когортам (requires PostHog/Mixpanel integration)
- [x] "Пропустить" для tutorial — skip endpoint + tutorialSkipped flag

---

## Implementation Summary

### Files Created

| File | Purpose |
|------|---------|
| `backend/src/lib/game/tutorial.ts` | Constants, quest definitions, referral config |
| `backend/src/lib/game/tutorial-analytics.ts` | Structured event logging for funnel |
| `backend/src/app/api/tutorial/route.ts` | GET state, POST initialize |
| `backend/src/app/api/tutorial/step/route.ts` | Advance tutorial step |
| `backend/src/app/api/tutorial/skip/route.ts` | Skip tutorial |
| `backend/src/app/api/tutorial/quest/route.ts` | Quest progress + claim |
| `backend/src/app/api/tutorial/referral/route.ts` | Referral code management |
| `backend/prisma/migrations/20260407_add_tutorial_onboarding/migration.sql` | DB migration |
| `Hexbound/.../TutorialOverlayView.swift` | Spotlight overlay with NPC dialog |
| `Hexbound/.../TutorialQuestBanner.swift` | Collapsible quest banner on Hub |
| `Hexbound/.../BuildingLockOverlay.swift` | Level-gated building lock UI |
| `Hexbound/.../ReferralSectionView.swift` | Referral section in Settings |

### Files Modified

| File | Changes |
|------|---------|
| `TutorialManager.swift` | Server-synced tutorial state, quest CRUD, referral code |
| `CityMapView.swift` | Quest→building mapping, hasQuest indicator on labels |
| `CityBuildingView.swift` | requiredLevel parameter, level-based lock |
| `CityBuildingLabel.swift` | hasQuest golden "!" indicator |
| `HubView.swift` | TutorialQuestBanner integration, tutorial state fetch |
| `LevelUpModalView.swift` | Dynamic unlocks from BuildingUnlockConfig + SFX |
| `DungeonSelectDetailView.swift` | tutorialOverlay + tutorialAnchor |
| `SettingsDetailView.swift` | Referral section integration |
| `project.pbxproj` | 4 new files registered |
| `prisma/schema.prisma` | tutorialStep, tutorialSkipped, referralCode, referredBy, TutorialQuest model |

### Analytics Events

| Event | Endpoint | Fired when |
|-------|----------|------------|
| `tutorial_started` | POST /tutorial | Welcome gift claimed |
| `tutorial_step` | POST /tutorial/step | Step 1→2→3 |
| `tutorial_skipped` | POST /tutorial/skip | "Skip" pressed |
| `tutorial_quest_done` | POST /tutorial/quest | Quest target reached |
| `tutorial_quest_claim` | POST /tutorial/quest | Reward claimed |
| `referral_applied` | POST /tutorial/referral | Code entered |

Query: Vercel > Logs > `tutorial_event`
