# Social Features — Full UX Specification

> **Три фичи:** Challenge (PvP-вызов), Message (сообщения), Add Friend (друзья)
> **Статус:** UX-дизайн, ожидает утверждения перед реализацией
> **Дата:** 2026-03-23

---

## Оглавление

1. [Общая архитектура](#1-общая-архитектура)
2. [Flow 1: Challenge (PvP-вызов)](#2-flow-1-challenge-pvp-вызов)
3. [Flow 2: Add Friend (Друзья)](#3-flow-2-add-friend-друзья)
4. [Flow 3: Message (Сообщения)](#4-flow-3-message-сообщения)
5. [Социальный хаб (Social Tab)](#5-социальный-хаб-social-tab)
6. [Уведомления и бейджи](#6-уведомления-и-бейджи)
7. [Backend: новые модели и API](#7-backend-новые-модели-и-api)
8. [Edge Cases и безопасность](#8-edge-cases-и-безопасность)
9. [Приоритизация реализации](#9-приоритизация-реализации)

---

## 1. Общая архитектура

### Точки входа в социальные функции

Все три действия доступны из **одного места** — нижняя часть `LeaderboardPlayerDetailSheet` (профиль оппонента). В будущем — также из друзей и истории боёв.

```
Leaderboard → Tap player → OpponentProfileSheet
                                ├── 🔥 CHALLENGE  (primary CTA)
                                ├── 💬 MESSAGE     (secondary)
                                └── 👤 ADD FRIEND  (secondary)
```

### Новый экран: Social Hub

Нужен **центральный экран** для управления социальными функциями.

**Решение: новое здание "Guild Hall" (Гильдия) на хаб-карте** — зал гильдии, где воины собираются, формируют альянсы, обмениваются вестями и бросают вызовы. Классический RPG-паттерн, идеально ложится на dark fantasy сеттинг.

- **Тематика:** братство воинов, дуэли чести, гильдейские вести
- **Иконка на карте:** щит с мечами (pen-and-ink style, как все hub assets)
- **Навигационный роут:** `.guildHall` (новый, не конфликтует с `.tavern` для мини-игр)

```
Hub Map → Guild Hall Building → Social Hub
                                  ├── Tab: ALLIES (список друзей + запросы)
                                  ├── Tab: SCROLLS (сообщения)
                                  └── Tab: DUELS (challenge log)
```

Бейдж на здании гильдии: суммарное количество непрочитанных (запросы в друзья + сообщения + вызовы).

**Нейминг в контексте гильдии:**
- Friends → **Allies** (соратники)
- Messages/Inbox → **Scrolls** (свитки)
- Challenge Log → **Duels** (дуэли)
- "Send message" → "Send a scroll"
- "Friend request" → "Alliance request"

---

## 2. Flow 1: Challenge (PvP-вызов)

### 2.1 Концепция

Асинхронный PvP-вызов конкретного игрока. Механика идентична арене — бот играет за оппонента, результат мгновенный. Ключевое отличие от арены: ты **выбираешь** кого вызвать (не рандомные оппоненты).

### 2.2 Правила и ограничения

| Параметр | Значение | Обоснование |
|----------|----------|-------------|
| Стоимость стамины | 10 (как PvP) | Consistency с ареной |
| Бесплатные вызовы друзей | Да, 0 стамины | Incentive добавлять друзей |
| Кулдаун на одного игрока | 30 минут | Анти-спам, анти-фарм |
| Ограничение уровня | Нет (любой уровень) | Вызов = осознанный выбор |
| Предупреждение о gap | Да, если разница > 10 лвл | Не блокирует, но предупреждает |
| Влияние на рейтинг | Да, стандартный ELO | Как обычный PvP |
| Попадает в Revenge | Да | Оппонент может отомстить |
| Награды (золото/XP/лут) | Как PvP | Полные награды |
| Максимум в день | Не ограничено | Лимитируется стаминой |

### 2.3 Флоу (Happy Path)

```
Профиль оппонента
  → Tap "CHALLENGE"
    → Confirmation Sheet (средний детент)
      - Показать: имя оппонента, уровень, рейтинг, класс
      - Показать: стоимость стамины (10) или FREE для друзей
      - Показать: предупреждение если gap > 10 уровней
      - [FIGHT] (primary) | [CANCEL] (secondary)
    → Tap "FIGHT"
      → Dismiss profile sheet
      → Navigate to .combat (как из арены)
      → Показать бой
      → Navigate to .combatResult
        - Обычный экран результата (победа/поражение, лут, рейтинг)
        - Доп. кнопка "REMATCH" (если прошло < 30 мин — disabled + таймер)
```

### 2.4 Экраны и состояния

#### Экран: Challenge Confirmation Sheet

**Тип:** Bottom sheet, medium detent (40% экрана)

**Layout:**
```
┌─────────────────────────────────┐
│       ⚔️ CHALLENGE              │  ← OrnamentalTitle
│  ─────────◆───────────          │  ← GoldDivider
│                                 │
│  [Avatar 48px] DarkLord_99      │  ← Имя + уровень + ранг
│                Lv.45 · Gold     │
│                                 │
│  ┌───────────────────────────┐  │
│  │ ⚡ Stamina Cost:  10      │  │  ← Или "FREE" для друзей
│  │ 📊 Rating Risk:  ±15-25  │  │  ← Примерный диапазон
│  │ ⚠️ Level gap: 12 levels  │  │  ← Только если gap > 10
│  └───────────────────────────┘  │
│                                 │
│  ┌─────────────────────────────┐│
│  │        🔥 FIGHT!            ││  ← .fight buttonStyle
│  └─────────────────────────────┘│
│  ┌─────────────────────────────┐│
│  │          Cancel             ││  ← .neutral buttonStyle
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

**Состояния:**

| Состояние | Условие | UI |
|-----------|---------|---|
| Default | Достаточно стамины | FIGHT! активен, стоимость белым |
| Free fight | Оппонент в друзьях | "FREE" зелёным вместо стамины |
| Low stamina | Стамина < 10 | FIGHT! disabled, "Not enough stamina" + кнопка "Get Stamina" |
| Cooldown active | Вызывал < 30 мин назад | FIGHT! disabled, таймер обратного отсчёта "Available in 24:30" |
| Level warning | Gap > 10 уровней | Жёлтый banner "Warning: 12 level difference. Opponent may be much stronger." |
| Loading | После tap FIGHT | FIGHT! → spinner, prevent double-tap |
| Error | Сеть / сервер | Toast error "Challenge failed. Try again." |
| Opponent offline > 7d | Неактивен давно | Info pill "Inactive player — may have outdated gear" |

#### Экран: Combat Result — дополнение для Challenge

К стандартному `CombatResultDetailView` добавляется:

```
[Стандартный результат: Victory/Defeat + лут + XP + рейтинг]

┌──── Post-Challenge Actions ─────┐
│                                  │
│  [🔥 REMATCH]    [👤 PROFILE]   │  ← Реванш + вернуться в профиль
│                                  │
│  [📤 SHARE]      [🏠 HUB]      │  ← Поделиться + выйти
└──────────────────────────────────┘
```

- **REMATCH:** Если кулдаун не истёк — disabled + таймер. Если ок — повторный challenge того же игрока
- **PROFILE:** Открывает профиль оппонента заново
- **HUB:** Стандартный возврат (как сейчас)

### 2.5 Уведомление оппоненту

Оппонент **не получает push** (асинхронный бой). Но при следующем входе в игру:

1. **Если проиграл:** запись появляется в Revenge Queue (как при обычном PvP)
2. **Challenge History:** в Social Hub → Challenges tab — список "You were challenged by X — Lost/Won"
3. **Toast при входе:** "DarkLord_99 challenged you and won! Seek revenge?" → tap → Revenge в арене

### 2.6 Что меняется в оппоненте

- Запись в `PvpMatch` с `matchType: 'challenge'`
- Запись в `RevengeQueue` если оппонент проиграл
- Рейтинг оппонента изменяется (как при обычном PvP — server-authoritative)

---

## 3. Flow 2: Add Friend (Друзья)

### 3.1 Концепция

Система друзей с запросами. Друзья получают бонусы: бесплатные challenge-бои, приоритет в сообщениях, онлайн-статус.

### 3.2 Правила и ограничения

| Параметр | Значение | Обоснование |
|----------|----------|-------------|
| Максимум друзей | 50 | Социальный cap, не перегружает |
| Запрос в друзья | Мгновенный, нужно принять | Стандартный паттерн |
| Время жизни запроса | 7 дней | Авто-отклонение через неделю |
| Блокировка | Да | Заблокированный не видит тебя |
| Макс запросов в день | 20 | Анти-спам |
| Кулдаун повторного запроса | 24 часа | После отклонения |

### 3.3 Флоу: Отправка запроса

```
Профиль оппонента
  → Tap "ADD FRIEND"
    → Кнопка меняется: "ADD FRIEND" → "REQUEST SENT ✓" (disabled, gold tint)
    → Toast: "Friend request sent to DarkLord_99"
    → Сервер создаёт FriendRequest

Оппонент при следующем входе:
  → Бейдж на Tavern (+1)
  → Social Hub → Friends tab → "Requests" секция
    → [Accept] [Decline] на каждом запросе
    → Accept → Toast "You and DarkLord_99 are now friends!"
    → Decline → запрос удаляется, кулдаун 24ч
```

### 3.4 Экраны и состояния

#### Кнопка "Add Friend" в профиле оппонента — состояния

| Состояние | UI | Действие |
|-----------|---|---------|
| Default | `👤 ADD FRIEND` (.secondary style) | Tap → отправить запрос |
| Request sent | `✓ REQUEST SENT` (disabled, gold text) | — |
| Already friends | `✓ FRIENDS` (disabled, green text) | — |
| Friend request from them | `✓ ACCEPT FRIEND` (.primary style, pulsing) | Tap → принять |
| You are blocked | Кнопка не показывается | — |
| They are blocked | `🚫 BLOCKED` (danger text) | Tap → unblock confirmation |
| Max friends reached | `👤 ADD FRIEND` (disabled) + "Friend list full" | — |
| Daily limit reached | `👤 ADD FRIEND` (disabled) + "Too many requests today" | — |
| Loading | Spinner в кнопке | — |
| Error | Toast "Failed to send request" | Кнопка возвращается в default |

#### Экран: Friends List (Social Hub → Friends tab)

**Layout:**
```
┌──────────────────────────────────┐
│  TAVERN                          │  ← OrnamentalTitle
│  ─────────◆───────────           │
│  [FRIENDS] [INBOX] [CHALLENGES]  │  ← TabSwitcher (3 tabs)
├──────────────────────────────────┤
│                                  │
│  ┌─ Friend Requests (2) ───────┐│  ← Секция, только если есть
│  │ [Ava] SkullCrusher Lv.32   ││
│  │        Warrior · Silver     ││
│  │        [✓ Accept] [✗]      ││
│  │                             ││
│  │ [Ava] MageDoom Lv.28       ││
│  │        Mage · Bronze        ││
│  │        [✓ Accept] [✗]      ││
│  └─────────────────────────────┘│
│                                  │
│  ─── Online (3) ────            │  ← Разделитель
│                                  │
│  [Ava] 🟢 NightBlade  Lv.41   │  ← Зелёная точка = онлайн
│           Rogue · Gold          │
│           [⚔️] [💬] [👁️]       │  ← Challenge, Message, View Profile
│                                  │
│  [Ava] 🟢 IronFist   Lv.38    │
│           Tank · Gold           │
│           [⚔️] [💬] [👁️]       │
│                                  │
│  ─── Offline (12) ────          │
│                                  │
│  [Ava] ⚫ DeathMage   Lv.45   │  ← Серая точка = оффлайн
│           Mage · Platinum       │
│           Last seen: 2h ago     │
│           [⚔️] [💬] [👁️]       │
│  ...                            │
│                                  │
│  ─── 15/50 friends ────         │  ← Счётчик внизу
└──────────────────────────────────┘
```

**Состояния списка друзей:**

| Состояние | UI |
|-----------|---|
| Empty (0 друзей, 0 запросов) | Иллюстрация гильдии + "The guild hall stands empty..." + "Find warriors in the Leaderboard" CTA |
| Empty (0 друзей, есть запросы) | Секция запросов + empty state "No friends yet" |
| Loading | Skeleton cards (3 штуки) |
| Error | "Failed to load friends" + Retry кнопка |
| Pull to refresh | Стандартный PTR |

#### Действия со другом (long press / swipe)

**Context menu (long press на друге):**
```
┌──────────────────┐
│ ⚔️ Challenge     │
│ 💬 Send Message  │
│ 👁️ View Profile  │
│ ────────────     │
│ 🚫 Remove Friend │  ← Красный текст
│ 🔇 Block         │  ← Красный текст
└──────────────────┘
```

**Remove Friend:**
```
Confirmation Alert:
  "Remove NightBlade from friends?"
  "You can send a new request later."
  [Remove] (danger) | [Cancel]
```

**Block:**
```
Confirmation Alert:
  "Block NightBlade?"
  "They won't be able to see your profile, send messages, or challenge you."
  [Block] (danger) | [Cancel]
```

### 3.5 Онлайн-статус

| Статус | Условие | Визуал |
|--------|---------|--------|
| Online | Активен < 5 мин | 🟢 Зелёная точка |
| Away | Активен 5-30 мин назад | 🟡 Жёлтая точка |
| Offline | > 30 мин | ⚫ Серая точка + "Last seen: Xh ago" |
| Offline > 7d | Давно не заходил | ⚫ + "Last seen: 7d+ ago" (dimmed) |

Реализация: поле `lastActiveAt` на Character, обновляется при каждом API-запросе.

---

## 4. Flow 3: Message (Сообщения)

### 4.1 Концепция

Простая внутриигровая почта (НЕ real-time чат). Формат "открытки" — короткие сообщения с предустановленными шаблонами и возможностью писать свой текст. Тематически это "свитки, передаваемые через гильдию".

### 4.2 Правила и ограничения

| Параметр | Значение | Обоснование |
|----------|----------|-------------|
| Максимум символов | 200 | Короткие записки, не чат |
| Сообщения незнакомцам | Да, 3 в день | Социальное обнаружение, анти-спам |
| Сообщения друзьям | Неограниченно | Incentive дружить |
| Время жизни сообщения | 30 дней | Авто-удаление, не копить мусор |
| Фильтр мата | Да, серверный | Безопасность |
| Максимум в inbox | 100 | Старые удаляются автоматически |
| Вложения | Нет (v1) | KISS — только текст |
| Блокировка | Заблокированные не могут писать | Связано с friend system |

### 4.3 Типы сообщений

**Quick Messages (предустановленные):**

| ID | Текст | Контекст |
|----|-------|---------|
| `gg` | "Good game! ⚔️" | После боя |
| `nice_fight` | "That was a close one!" | После боя |
| `rematch` | "Rematch? Meet me in the arena!" | Вызов на бой |
| `thanks` | "Thanks, friend!" | Общее |
| `hello` | "Greetings, warrior!" | Знакомство |
| `gl` | "Good luck on your journey!" | Общее |
| `revenge` | "I'll be back for revenge..." | После проигрыша |
| `wow_gear` | "Impressive gear you have!" | Похвала |

Quick messages **не считаются** в лимит 200 символов и не фильтруются (предмодерированы).

### 4.4 Флоу: Отправка сообщения

```
Профиль оппонента
  → Tap "MESSAGE"
    → Message Compose Sheet (medium detent)
      - Quick message pills (горизонтальный скролл)
      - OR текстовое поле (200 char limit)
      - [SEND] кнопка
    → Tap на quick pill → автозаполняет текстовое поле
    → Tap SEND
      → Sheet dismisses
      → Toast: "Message sent to DarkLord_99"
```

### 4.5 Экраны и состояния

#### Экран: Message Compose Sheet

**Тип:** Bottom sheet, medium detent (~50% экрана)

**Layout:**
```
┌─────────────────────────────────┐
│       ✉️ SEND MESSAGE           │  ← OrnamentalTitle
│  ─────────◆───────────          │
│                                 │
│  To: DarkLord_99 (Lv.45)       │  ← Получатель (не редактируемый)
│                                 │
│  Quick:                         │
│  [GG ⚔️] [Nice fight!] [Hello] │  ← Горизонтальный скролл
│  [Rematch?] [GL!] [Revenge...] │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Write your message...     │  │  ← TextEditor, 3 строки
│  │                           │  │
│  │                           │  │
│  └───────────────────────────┘  │
│                       142/200   │  ← Счётчик символов
│                                 │
│  ┌─────────────────────────────┐│
│  │         📤 SEND             ││  ← .primary buttonStyle
│  └─────────────────────────────┘│
└─────────────────────────────────┘
```

**Состояния:**

| Состояние | Условие | UI |
|-----------|---------|---|
| Default | Пустое поле | SEND disabled, counter "0/200" |
| Quick selected | Tap на pill | Текст в поле, pill highlighted, SEND active |
| Custom text | Набрал текст | Counter обновляется, SEND active |
| Char limit | 200 символов | Counter красный "200/200", ввод блокируется |
| Sending | После tap SEND | SEND → spinner |
| Daily limit (strangers) | 3 сообщения незнакомцам | Banner "You can send 3 messages to non-friends per day. 0 remaining." + SEND disabled |
| Blocked | Заблокирован получателем | "This player has blocked messages from you" + SEND disabled |
| Profanity detected | Мат в тексте | Серверная фильтрация, заменяет на *** |
| Error | Сеть / сервер | Toast "Message failed. Try again." |
| Success | Отправлено | Sheet dismiss + toast "Message sent!" |

#### Экран: Inbox (Social Hub → Inbox tab)

**Layout:**
```
┌──────────────────────────────────┐
│  TAVERN                          │
│  [FRIENDS] [INBOX •3] [CHALLENGES]│  ← Бейдж с непрочитанными
├──────────────────────────────────┤
│                                  │
│  ┌─ Today ─────────────────────┐│
│  │ [Ava] SkullCrusher          ││  ← Непрочитанное = bold
│  │        "Good game! ⚔️"       ││  ← Превью текста
│  │        2 min ago            ││
│  │                             ││
│  │ [Ava] MageDoom              ││  ← Прочитанное = dimmed
│  │        "That was a close..." ││
│  │        1 hour ago           ││
│  └─────────────────────────────┘│
│                                  │
│  ┌─ Yesterday ─────────────────┐│
│  │ [Ava] NightBlade            ││
│  │        "Rematch? Meet me..." ││
│  │        Yesterday, 18:34     ││
│  └─────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

**Tap на сообщение → Message Detail:**

```
┌─────────────────────────────────┐
│  ← Back to Inbox                │
│                                 │
│  [Avatar 48px]                  │
│  SkullCrusher · Lv.32          │
│  Warrior · Silver               │
│  2 minutes ago                  │
│                                 │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │  "Good game! That was     │  │  ← Полный текст на "пергаменте"
│  │   an epic battle!"        │  │
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
│  [💬 REPLY]  [👁️ PROFILE]      │  ← Действия
│                                 │
│  [🚫 Block]                    │  ← Серый, мелкий текст внизу
└─────────────────────────────────┘
```

**Состояния inbox:**

| Состояние | UI |
|-----------|---|
| Empty | Иллюстрация свитка + "No messages yet" + "Send a message after your next battle!" |
| Loading | Skeleton cards (3 штуки) |
| Error | "Failed to load messages" + Retry |
| Unread messages | Bold text + gold dot indicator |
| Read messages | Dimmed text |

### 4.6 Сообщения из результата боя

После боя в `CombatResultDetailView` добавляется кнопка "Send GG":

```
[Post-battle actions]
  [🔥 REMATCH]  [💬 SEND GG]  [🏠 HUB]
```

Tap "SEND GG" → мгновенная отправка quick message "Good game! ⚔️" → toast confirmation. Один tap, без compose sheet.

---

## 5. Социальный хаб (Guild Hall)

### 5.1 Здание "Guild Hall" на Hub

**Размещение:** новое здание на CityMapView. Расположение — между ареной и магазином (социальная зона).

**Визуал здания:** Каменный зал с двумя щитами и мечами по бокам входа. Pen-and-ink стиль как все hub assets. Тёплое свечение из окон (gold tint).

**Навигационный роут:** `.guildHall` (новый, не конфликтует с `.tavern` для мини-игр)

**Badge:** Gold capsule (как все hub badges) с суммой:
```
badge = pendingAllianceRequests + unreadScrolls + pendingDuels
```

**Нейминг в контексте гильдии:**
- Friends → **Allies** (соратники)
- Messages/Inbox → **Scrolls** (свитки)
- Challenge Log → **Duels** (дуэли)
- "Send message" → "Send a scroll"
- "Friend request" → "Alliance request"

### 5.2 Layout: Guild Hall Screen

```
┌──────────────────────────────────┐
│       ⚔ GUILD HALL              │  ← OrnamentalTitle
│  ─────────◆───────────           │
│  [ALLIES •2] [SCROLLS •3] [DUELS]│  ← TabSwitcher
├──────────────────────────────────┤
│                                  │
│  [Tab content here]              │
│                                  │
└──────────────────────────────────┘
```

**Tabs:**
1. **ALLIES** — список друзей + входящие запросы (описан в секции 3.4)
2. **SCROLLS** — сообщения (описан в секции 4.5)
3. **DUELS** — Challenge log + боевые события

### 5.3 Challenge Log (Tab: LOG)

```
┌──────────────────────────────────┐
│  ─── Incoming Challenges ───     │
│                                  │
│  [Ava] SkullCrusher challenged   │
│        you — You Lost!           │  ← Красный текст
│        -18 rating · 2h ago       │
│        [🔥 REVENGE] [👁️ PROFILE] │
│                                  │
│  [Ava] MageDoom challenged       │
│        you — You Won!            │  ← Зелёный текст
│        +22 rating · 5h ago       │
│        [👁️ PROFILE]              │
│                                  │
│  ─── Your Challenges ───         │
│                                  │
│  You challenged NightBlade       │
│        Victory! +15 rating       │
│        Yesterday                 │
│                                  │
│  You challenged IronFist         │
│        Defeat. -12 rating        │
│        Yesterday                 │
│                                  │
└──────────────────────────────────┘
```

---

## 6. Уведомления и бейджи

### 6.1 Toast-уведомления

| Событие | Toast | Тип | Action |
|---------|-------|-----|--------|
| Запрос в друзья отправлен | "Friend request sent to X" | .info | — |
| Запрос принят | "X accepted your friend request!" | .reward | "View" → профиль |
| Запрос отклонён | (нет toast) | — | — |
| Сообщение отправлено | "Message sent to X" | .info | — |
| Challenge отправлен | "Challenging X..." | .info | — |
| При входе: тебя вызвали | "X challenged you and won!" | .info | "Revenge" → арена |
| При входе: новые друзья | "2 alliance requests waiting!" | .info | "View" → гильдия |

### 6.2 Hub Building Badges

**Guild Hall badge** в `CityMapView.badgeFor(_ building:)`:
```swift
case "guild-hall":
    let count = cache.pendingAllianceRequests + cache.unreadScrolls + cache.pendingDuels
    return count > 0 ? "\(count)" : nil
```

### 6.3 Push Notifications (v2, не MVP)

В первой версии — только in-app уведомления (toast + badges). Push — в будущем.

---

## 7. Backend: новые модели и API

### 7.1 Новые Prisma модели

```prisma
model Friendship {
  id          String   @id @default(uuid())
  userId      String
  friendId    String
  status      FriendshipStatus @default(pending)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  user        Character @relation("UserFriends", fields: [userId], references: [id])
  friend      Character @relation("FriendOf", fields: [friendId], references: [id])

  @@unique([userId, friendId])
  @@index([userId, status])
  @@index([friendId, status])
}

enum FriendshipStatus {
  pending
  accepted
  blocked
}

model Message {
  id          String   @id @default(uuid())
  senderId    String
  receiverId  String
  content     String   @db.VarChar(200)
  isQuick     Boolean  @default(false)
  quickId     String?
  isRead      Boolean  @default(false)
  createdAt   DateTime @default(now())
  expiresAt   DateTime

  sender      Character @relation("SentMessages", fields: [senderId], references: [id])
  receiver    Character @relation("ReceivedMessages", fields: [receiverId], references: [id])

  @@index([receiverId, isRead])
  @@index([senderId, createdAt])
}
```

### 7.2 Новые API routes

| Method | Route | Описание |
|--------|-------|---------|
| POST | `/api/friends/request` | Отправить запрос в друзья |
| POST | `/api/friends/accept` | Принять запрос |
| POST | `/api/friends/decline` | Отклонить запрос |
| DELETE | `/api/friends/:id` | Удалить из друзей |
| GET | `/api/friends?character_id=X` | Список друзей + запросы |
| POST | `/api/friends/block` | Заблокировать |
| POST | `/api/friends/unblock` | Разблокировать |
| POST | `/api/messages/send` | Отправить сообщение |
| GET | `/api/messages?character_id=X` | Inbox |
| POST | `/api/messages/:id/read` | Пометить прочитанным |
| POST | `/api/pvp/challenge` | Создать challenge (reuses pvp/prepare + pvp/resolve) |
| GET | `/api/social/status?character_id=X` | Счётчики для бейджей (unread, requests, etc.) |

### 7.3 Challenge API — детали

`POST /api/pvp/challenge` это wrapper вокруг существующего PvP-флоу:

```
1. Проверить кулдаун (30 мин на этого оппонента)
2. Проверить стамину (10, или 0 если друзья)
3. Проверить блокировку
4. Создать PvpBattleTicket с matchType: 'challenge'
5. Вернуть battleTicket + seed (как pvp/prepare)
6. Клиент симулирует бой и вызывает pvp/resolve
```

---

## 8. Edge Cases и безопасность

### 8.1 Anti-abuse

| Угроза | Защита |
|--------|--------|
| Спам вызовов | Кулдаун 30 мин на одного оппонента |
| Спам сообщений | 3/день незнакомцам, фильтр мата |
| Спам запросов | 20/день, кулдаун 24ч после отклонения |
| Фарм друзей | Лимит 50 друзей |
| ELO manipulation (challenge low-rank) | Стандартный ELO — мало очков за слабого |
| Harassment | Блокировка + фильтрация |
| Self-challenge | Запрет вызова самого себя |
| Challenge deleted character | 404 → "Player not found" |
| Message to deleted character | 404 → "Player not found" |
| Concurrent challenges | Один тикет за раз (как в арене) |

### 8.2 Offline/Error сценарии

| Сценарий | Поведение |
|----------|----------|
| Нет интернета при challenge | Toast "No connection" + retry |
| Нет интернета при send message | Toast "Message will be sent when online" (не сохраняем локально в v1 — просто retry) |
| Нет интернета при add friend | Toast "No connection" + retry |
| Сервер 500 | Toast "Something went wrong" + retry |
| Rate limit 429 | Toast "Too many requests. Wait a moment." |

---

## 9. Приоритизация реализации

### Phase 1: Foundation (Друзья)
**Почему первым:** друзья — фундамент для бесплатных challenges и неограниченных сообщений.

1. Prisma модель `Friendship` + миграция
2. API routes: request, accept, decline, list, block
3. iOS модели: `FriendEntry`, `FriendRequest`
4. UI: кнопка Add Friend в профиле (все состояния)
5. UI: Guild Hall здание на hub + Social Hub экран + Allies tab

### Phase 2: Challenge
**Почему вторым:** core gameplay value, reuses existing PvP infra.

1. API route: `/api/pvp/challenge` (wrapper)
2. Modify `PvpMatch` — add `matchType` field
3. Challenge confirmation sheet
4. Combat result additions (rematch, profile)
5. Duels log tab в Guild Hall
6. Toast при входе ("you were challenged")
7. Free challenge для allies (0 stamina)

### Phase 3: Messages
**Почему третьим:** nice-to-have, менее критичен для core loop.

1. Prisma модель `Message` + миграция
2. API routes: send, list, read
3. iOS модели: `MessageEntry`
4. UI: Compose sheet
5. UI: Scrolls tab в Guild Hall
6. Quick message pills
7. Post-battle "Send GG" кнопка
8. Profanity filter (серверный)

### Estimated effort

| Phase | Backend | iOS | Total |
|-------|---------|-----|-------|
| Friends | 2-3 дня | 3-4 дня | ~1 неделя |
| Challenge | 1-2 дня | 2-3 дня | ~1 неделя |
| Messages | 2-3 дня | 3-4 дня | ~1 неделя |
| **Total** | **5-8 дней** | **8-11 дней** | **~3 недели** |
