# HEXBOUND — ПОЛНЫЙ UX/UI АУДИТ v2.0

> **Версия:** 2.0 — Критический аудит перед масштабированием
> **Дата:** 2026-03-16
> **Метод:** Nielsen Norman Group 10 Heuristics + Mobile Game UX Best Practices
> **Платформа:** iOS (SwiftUI, Portrait 1170×2532)
> **Скоуп:** 26 экранов, 31+ View-файл, 4 файла темы, все пользовательские флоу
> **Предыдущий аудит:** v1.0 от 2026-03-15 (оценка B+) — **пересмотрена вниз до B−**
> **Статус:** ПОЛНЫЙ АУДИТ + РЕКОМЕНДАЦИИ + СТАНДАРТ

---

## A. EXECUTIVE SUMMARY

### Общая оценка: **B− (Удовлетворительно, с серьёзными пробелами)**

Предыдущий аудит (v1.0) оценил систему на B+. **Это завышенная оценка.** При глубоком анализе флоу, мобильных паттернов и edge-кейсов выявлены системные проблемы, которые при масштабировании (больше игроков, больше экранов) станут критичными.

**Что реально хорошо:**
- Архитектура дизайн-системы (`DarkFantasyTheme`, `ButtonStyles`, `CardStyles`, `LayoutConstants`) — грамотная основа
- Тематическая целостность «Dark Fantasy Premium» выдержана на ~80% экранов
- Компонентная библиотека (`TabSwitcher`, `SkeletonViews`, `ToastOverlayView`) — зрелая
- Кэширование данных и предзагрузка — хороший продуктовый подход

**Что реально плохо (и v1 недооценил):**
- Онбординг — первый экран, который видит новый игрок — **полностью вне дизайн-системы** (1019 строк монолита, 30+ хардкодов)
- Боевой экран не даёт **никакой обратной связи** при нажатии FIGHT (0.5–2 сек тишины)
- Нет **ни одного** confirmation dialog перед тратой стамины в PvP (10 стамины = ценный ресурс)
- Нет offline-режима, нет обработки потери сети, нет retry-механизмов
- **Нет bottom navigation** — вся навигация через CityMap, что красиво, но anti-pattern для мобильных RPG с 10+ экранами
- Отсутствует tutorial/onboarding для игровых механик (стэнсы, статы, руны, экипировка)
- **Нет push-уведомлений о стамине** — игрок не знает, когда вернуться

### Топ-10 UX-рисков (по убыванию severity)

| # | Риск | Severity | Heuristic | Impact на retention |
|---|------|----------|-----------|---------------------|
| 1 | Онбординг вне дизайн-системы (30+ hardcoded values, монолит) | CRITICAL | #4 Consistency | Первое впечатление = отток D1 |
| 2 | Нет loading feedback при инициации боя (FIGHT → пустота 0.5-2с) | CRITICAL | #1 Visibility | Игрок думает «кнопка сломана» |
| 3 | Нет confirmation перед тратой стамины (10 STA в PvP) | HIGH | #5 Error Prevention | Случайная трата = frustration |
| 4 | Нет offline/network error UX (нет banner, нет retry) | HIGH | #9 Error Recovery | Потеря данных, непонятные ошибки |
| 5 | BattlePass показывает mock-данные (TODO в коде) | HIGH | #2 Real World Match | Игрок видит фейковый прогресс |
| 6 | HP Bar имеет 3 разные реализации (кроваво-красная, зелёно-красная, дизайн-док) | HIGH | #4 Consistency | Один метрик — три визуала |
| 7 | Нет tutorial для stance-системы (attack/defense zones) | HIGH | #10 Help & Docs | Ключевая механика непонятна |
| 8 | 3-буквенные коды статус-эффектов (BLD, BRN, STN) в бою | MEDIUM | #6 Recognition | Заставляет запоминать |
| 9 | Нет buy-back для проданных предметов | MEDIUM | #3 User Control | Ошибка необратима |
| 10 | Нет поиска/сортировки в инвентаре | MEDIUM | #7 Efficiency | Долго искать в 50+ предметах |

### Самые непоследовательные паттерны

1. **HP Bar** — DarkFantasyTheme (кроваво-красные градиенты), HubCharacterCard (зелёный→жёлтый→красный), дизайн-документ (зелёный→янтарный→красный)
2. **Валюта** — `TopCurrencyBar` и `currencyRow` внутри `HubCharacterCard` — два компонента для одних данных
3. **Кнопки на онбординге** — `AppearanceButtonStyle` вместо системного `PrimaryButtonStyle`
4. **Табы** — Arena использует кастомные табы, остальные экраны — `TabSwitcher`
5. **Иконки** — часть экранов использует emoji (🎖️🎯), часть — custom `Image("hud-*")`

### Самые запутанные флоу

1. **Onboarding → Hub** — 4 шага без возможности пропустить для опытных игроков
2. **Arena → Combat → Result → Loot → Hub** — 4 экрана после одного боя, нет shortcut «ещё раз»
3. **Inventory → Equip** — нужно найти предмет → тап → sheet → Equip, нет «auto-equip best»
4. **Stance selection** — спрятан в Character screen, не виден в Arena перед боем

### Biggest opportunities

1. **+15-20% D1 retention** — переделать онбординг с дизайн-системой + добавить tutorial
2. **+10% session length** — добавить «Rematch» и «Quick Fight» после боя
3. **+5% conversion** — исправить Shop UX (нет preview экипированного предмета)
4. **−30% support tickets** — добавить offline mode + error recovery

---

## B. ПОЛНЫЙ HEURISTIC REVIEW (Nielsen Norman Group)

### B.1 — Visibility of System Status

**Оценка: 5/10** (v1 ставил 7/10 — завышено)

#### Проблемы

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| V-01 | Arena → Combat | FIGHT button | Нет loading indicator после нажатия FIGHT. Генерация 7-14 ходов = 0.5-2 сек тишины | Игрок думает кнопка не работает, жмёт повторно | CRITICAL | Добавить `LoadingOverlay` с текстом «Подготовка к бою...» сразу после тапа | Fix now |
| V-02 | Hub | BattlePassCard | Показывает mock-данные `level: 7, maxLevel: 30` с TODO в коде | Игрок видит фейковый прогресс, подрывает доверие | HIGH | Подключить реальные данные из `BattlePassService` | Fix now |
| V-03 | Hub | Free PvP counter | Показатель «Free: 2/3» виден ТОЛЬКО внутри Arena, не на Hub | Игрок не знает, что есть бесплатные бои, не заходит | HIGH | Добавить индикатор free PvP на Hub (в StaminaBar или NavTile) | Fix soon |
| V-04 | Combat | Status effects | Статус-эффекты показаны как 3-буквенные коды (BLD, BRN, STN) | Нет визуального индикатора, что эффект активен на персонаже | MEDIUM | Добавить иконки статус-эффектов под HP Bar каждого бойца | Fix soon |
| V-05 | Hub | Stamina recovery | Нет таймера восстановления стамины на Hub | Игрок не знает, когда вернуться в игру | HIGH | Добавить countdown «Full STA in: 2h 15m» в StaminaBarView | Fix now |
| V-06 | Shop | Purchase result | После покупки — только toast. Нет анимации предмета в инвентаре | Покупка не чувствуется значимой | MEDIUM | Добавить анимацию «предмет летит в инвентарь» + particle burst | Nice to improve |
| V-07 | Dungeon | Floor progress | В DungeonRoom текущий прогресс — маленький ряд точек внизу | На маленьком экране прогресс трудно разглядеть | LOW | Увеличить прогресс-индикатор, добавить «Floor 3/10» текст | Nice to improve |
| V-08 | Global | Network state | Нет индикатора offline/плохого соединения | Игрок не понимает, почему данные не грузятся | HIGH | Добавить banner «No connection» + retry button | Fix now |
| V-09 | Combat Result | Rating change | Rating change (+/-) показан как число без контекста | Игрок не понимает, близко ли он к следующему рангу | LOW | Добавить progress bar до следующего ранга | Nice to improve |

#### Что работает хорошо:
- ✅ HP/Stamina/XP bars на Hub обновляются в реальном времени
- ✅ Toast-система для success/error/info
- ✅ Skeleton loading views при загрузке данных
- ✅ Анимации claim-наград (gold particle burst)

---

### B.2 — Match Between System and the Real World

**Оценка: 7/10**

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| M-01 | Combat | Status codes | BLD, BRN, STN, PSN — требует запоминания | Нарушает «Recognition over Recall» | MEDIUM | Полные слова + цветные иконки: 🩸 Bleed, 🔥 Burn, ⚡ Stun, ☠️ Poison | Fix soon |
| M-02 | Character | Prestige label | «Prestige: 0» показывается, когда prestige не объяснён | Новый игрок видит непонятный метрик | LOW | Скрыть «Prestige» когда value = 0 | Nice to improve |
| M-03 | Character | Stat abbreviations | STR, AGI, VIT, END, INT, WIS, LUK, CHA — 8 аббревиатур | Не все игроки знают RPG-терминологию | LOW | Показать полные названия при первом просмотре, tooltip при тапе | Nice to improve |
| M-04 | Arena | Difficulty badges | Easy/Medium/Hard — но непонятно по какому критерию | Игрок не знает, что difficulty = разница рейтингов | LOW | Добавить пояснение «Based on rating difference» | Nice to improve |
| M-05 | Hub | CityMap buildings | Здания как навигация — красиво, но неочевидно для новых игроков | Нет label'ов «Arena», «Shop» при первом визите | MEDIUM | Добавить tooltip-подписи при первом входе в Hub | Fix soon |

#### Что работает хорошо:
- ✅ Rarity colors следуют индустриальному стандарту (серый → зелёный → синий → фиолетовый → золотой)
- ✅ Терминология Gold/Gems/Stamina/XP — интуитивная
- ✅ Иконки классов и цвета понятны (Warrior=оранжевый, Mage=синий)

---

### B.3 — User Control and Freedom

**Оценка: 5/10** (v1 ставил 7/10 — завышено)

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| C-01 | Combat | Mid-combat exit | Нет способа выйти из боя (только Skip до конца) | Игрок застрял, если нужно срочно выйти | HIGH | Добавить «Forfeit» с confirmation (ты проигрываешь, но выходишь) | Fix soon |
| C-02 | Onboarding | Skip option | 4-шаговый wizard без skip для вернувшихся игроков | Returning player проходит 4 шага заново | MEDIUM | Добавить «Quick Create» для опытных | Fix soon |
| C-03 | Stat allocation | Undo | Нельзя отменить распределение стат-поинтов до Save | Ошибка в аллокации = потеря поинтов | MEDIUM | Добавить «Reset» кнопку для сброса к оригинальным значениям | Fix soon |
| C-04 | Shop / Inventory | Buy-back | Нет возможности выкупить обратно проданные предметы | Случайная продажа = потеря легендарки | HIGH | Добавить buy-back tab (последние 10 продаж) | Fix soon |
| C-05 | Item equip | Sell equipped | Кнопка Sell disabled для equipped items, но нет пояснения ПОЧЕМУ | Игрок не понимает, что делать | MEDIUM | Добавить текст «Unequip first to sell» или auto-unequip + confirm | Fix soon |
| C-06 | Arena | Re-fight | После боя нельзя сразу переиграть того же оппонента | 4 экрана назад в Arena, потом искать оппонента | MEDIUM | Добавить «Rematch» кнопку на CombatResult | Fix soon |
| C-07 | Global | Navigation depth | Hub → Arena → Comparison → Combat → Result → Loot = 5 уровней | Глубже рекомендованных 3 уровней | LOW | Считать Combat flow как modal overlay, не как уровень навигации | Nice to improve |
| C-08 | Dungeon | Exit mid-dungeon | Нет явного «Exit Dungeon» до завершения всех комнат | Если нужно уйти — только HubLogoButton, прогресс неясен | MEDIUM | Добавить «Leave Dungeon» с сохранением прогресса | Fix soon |

#### Что работает хорошо:
- ✅ `HubLogoButton` — 1 тап возврат на Hub с любого экрана
- ✅ Tab-навигация (Opponents/Revenge/History) — быстрое переключение
- ✅ Combat speed toggle (1X/2X/Skip)

---

### B.4 — Consistency and Standards

**Оценка: 5/10** (v1 ставил 6/10 — всё ещё завышено)

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| CS-01 | Onboarding | Все компоненты | 30+ hardcoded hex colors, кастомные кнопки, нестандартные размеры шрифтов | Первый экран = другая визуальная система | CRITICAL | Полный рефакторинг: извлечь компоненты, использовать theme tokens | Fix now |
| CS-02 | Multiple | HP Bar | 3 реализации: `DarkFantasyTheme` (кроваво-красные), `HubCharacterCard` (зелёно-красные), Design Doc (зелёно-янтарные) | Один метрик отображается тремя способами | HIGH | Одна каноничная реализация: зелёный→янтарный→красный | Fix now |
| CS-03 | Hub | Currency display | `TopCurrencyBar` + `currencyRow` в `HubCharacterCard` — два разных компонента для Gold/Gems | Одни данные — два разных UI | MEDIUM | Выбрать один каноничный компонент | Fix soon |
| CS-04 | Arena | Tab implementation | Кастомная реализация табов вместо `TabSwitcher` | Разное поведение/вид табов на разных экранах | MEDIUM | Мигрировать на `TabSwitcher` | Fix soon |
| CS-05 | Hub banners | Icons | BattlePassCard и FirstWinBonusCard используют emoji (🎖️🎯), остальные — custom `Image("hud-*")` | Смешение emoji и asset-иконок | MEDIUM | Создать custom assets для всех HUD-иконок | Fix soon |
| CS-06 | Multiple | Hardcoded colors | 15-20 `Color(hex:)` в ArenaDetailView, CombatDetailView, HubCharacterCard, LoadingOverlay, ItemCardView, DailyLoginDetailView | Изменение темы не пропагируется | HIGH | Все цвета через `DarkFantasyTheme.*` | Fix now |
| CS-07 | Login | Button pattern | `.primary(enabled:)` — кастомный параметр, не используется нигде больше | Разный способ disabled state | LOW | Стандартный `.primary` + `.disabled()` modifier | Nice to improve |
| CS-08 | Combat | Speed buttons | Inline button styling вместо `ButtonStyles` | 3 кнопки (1X/2X/Skip) стилизованы ad-hoc | LOW | Извлечь в `CombatSpeedButtonStyle` | Nice to improve |
| CS-09 | Global | Back navigation | HubLogoButton на большинстве экранов, custom back на onboarding, нет back на combat | 3 разных паттерна «назад» | MEDIUM | Документировать исключения, обеспечить единообразие | Fix soon |
| CS-10 | Hub | Banner padding | Банneры используют 14px padding, всё остальное — 16px (`cardPadding`) | Magic number не в LayoutConstants | LOW | Добавить `bannerPadding` в LayoutConstants | Nice to improve |

---

### B.5 — Error Prevention

**Оценка: 5/10** (v1 ставил 7/10 — значительно завышено)

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| E-01 | Arena | FIGHT button | Нет confirmation перед тратой 10 стамины | Случайный тап = -10 STA, особенно при scroll | HIGH | Добавить «Spend 10 STA?» confirmation для платных боёв | Fix now |
| E-02 | Shop | Premium purchase | Нет double-confirmation для gem purchases | Случайная покупка за premium валюту | HIGH | Добавить «Spend X Gems?» dialog с ценой и предметом | Fix now |
| E-03 | Inventory | Sell action | Sell button disabled для equipped items — нет объяснения | Игрок не понимает, почему не может продать | MEDIUM | Добавить «Unequip first» label или auto-unequip flow | Fix soon |
| E-04 | Onboarding | Name validation | Проверка уникальности имени только через API (после submit) | Игрок вводит имя, ждёт, получает ошибку | MEDIUM | Debounce-проверка уникальности при вводе (onBlur) | Fix soon |
| E-05 | Auth | Guest login | Нет предупреждения о потере данных для Guest | Гость не знает, что прогресс может пропасть | HIGH | Warning banner: «Guest progress may be lost. Link account to save.» | Fix now |
| E-06 | Stat allocation | Point allocation | Нельзя «попробовать» аллокацию и откатить | Игрок боится ошибиться с distribution | MEDIUM | Preview mode + Reset button | Fix soon |
| E-07 | Combat | Accidental forfeit | Если добавим forfeit (рек. C-01), нужен confirmation | Случайный выход из боя = проигрыш | MEDIUM | Double-confirmation для forfeit | Fix soon |
| E-08 | Arena | Refresh opponents | «NEW OPPONENTS» кнопка циклирует пул, не фетчит новых | Игрок думает, что получит новых оппонентов | MEDIUM | Изменить label на «SHUFFLE» или реально фетчить новых | Fix soon |
| E-09 | Shop | Insufficient funds | Можно тапнуть Buy без проверки баланса до API-ответа | Frustrating error после тапа | LOW | Disable Buy button если `gold < price`, показать tooltip | Nice to improve |

---

### B.6 — Recognition Rather Than Recall

**Оценка: 6/10**

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| R-01 | Arena | Current stance | Текущая stance (attack/defense zones) не видна в Arena перед боем | Игрок забывает, какую stance выбрал | HIGH | Показать мини-превью стэнса рядом с FIGHT кнопкой | Fix soon |
| R-02 | Combat Result | Quest progress | Active quest objectives не видны на Result/Loot экранах | Игрок не знает, приблизился ли к квесту | MEDIUM | Добавить `ActiveQuestBanner` на CombatResult и Loot | Fix soon |
| R-03 | Inventory | Upgrade potential | В grid-виде инвентаря нет индикатора «этот предмет лучше текущего» | Нужно тапнуть каждый предмет для сравнения | MEDIUM | Зелёные/красные стрелки на карточках (upgrade/downgrade) | Fix soon |
| R-04 | Hub | Battle Pass progress | BP progress виден только внутри Battle Pass экрана | На Hub — только mock-карточка | MEDIUM | Показать реальный BP level + next reward на Hub banner | Fix soon |
| R-05 | Shop | Equipped comparison | В Shop нет превью «как будет на моём персонаже» | Нужно запоминать свои текущие статы | MEDIUM | Добавить comparison overlay: текущий vs покупаемый | Fix soon |
| R-06 | Arena | Rating context | Рейтинг оппонента без контекста «это выше/ниже меня» | Нужно запоминать свой рейтинг | LOW | Показать delta: «+150 above you» или цветовой код | Nice to improve |

---

### B.7 — Flexibility and Efficiency of Use

**Оценка: 6/10**

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| F-01 | Post-combat | Rematch | Нет «Rematch» после боя — нужно пройти 4 экрана назад | Friction для repeat play | HIGH | Кнопка «Fight Again» (тот же оппонент) + «New Opponent» на CombatResult | Fix now |
| F-02 | Inventory | Search/Sort | Нет поиска и сортировки (только 10 фильтров по типу) | При 50+ предметах — долго искать | MEDIUM | Sort dropdown (level, rarity, power) + search bar | Fix soon |
| F-03 | Inventory | Auto-equip | Нет «Optimize Equipment» / «Auto-equip best» | Ручной подбор 10 слотов = 10 тапов × сравнение | MEDIUM | Кнопка «Auto-Equip Best» с preview изменений | Fix soon |
| F-04 | Arena | Quick PvP | Нет «Quick Fight» (выбрать случайного оппонента и сразу в бой) | Для repeat players — слишком много шагов | MEDIUM | Кнопка «Quick Fight» на Arena (skip opponent selection) | Fix soon |
| F-05 | Shop | Bulk buy | Нет покупки нескольких consumables за раз | 10 зелий = 10 тапов + 10 confirmations | LOW | Количество + Buy button | Nice to improve |
| F-06 | Daily | One-tap claims | Нет «Claim All» для daily quests | Каждый квест = отдельный тап | MEDIUM | Кнопка «Claim All Completed» | Fix soon |
| F-07 | Dungeon | Skip animation | Нет skip для анимаций победы в dungeon rooms | После 5-10 боссов одинаковые анимации раздражают | LOW | «Skip» кнопка на DungeonVictoryView | Nice to improve |

---

### B.8 — Aesthetic and Minimalist Design

**Оценка: 8/10** (самая сильная сторона)

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| A-01 | Hub | Floating icons | 3-4 floating action icons (Daily Login, Quests, Sound, Gift) + character card + city + banners | Визуальный шум в thumb zone | MEDIUM | Группировать floating icons в expandable FAB (1 кнопка → раскрывающееся меню) | Fix soon |
| A-02 | Hub banners | Emoji | BattlePassCard (🎖️) и FirstWinBonusCard (🎯) — emoji среди custom icons | Визуальная непоследовательность | LOW | Custom HUD assets | Nice to improve |
| A-03 | Character screen | Info density | 8 статов + 6 derived stats + equipment + stance — много на одном экране | Cognitive overload для новых игроков | LOW | Progressive disclosure: collapsed sections, tap to expand | Nice to improve |
| A-04 | Combat log | Text density | Combat log = текстовые строки с дамагом, критами, промахами | Трудно читать на маленьком экране во время анимации | MEDIUM | Визуальные карточки ходов вместо текста | Fix soon |

#### Что работает отлично:
- ✅ Dark Fantasy тема — атмосферная и целостная
- ✅ Ornamental dividers добавляют дух, не мешают чтению
- ✅ Rarity glow system — чёткая визуальная иерархия
- ✅ Цветовое кодирование осмысленное (stat colors, class colors, rank colors)
- ✅ CityMapView — иммерсивная навигация, отличный game feel

---

### B.9 — Help Users Recognize, Diagnose, and Recover from Errors

**Оценка: 4/10** (v1 ставил 6/10 — сильно завышено)

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| H-01 | Global | Network errors | API ошибки = generic toast без actionable guidance | Игрок не знает, что делать | HIGH | Конкретные сообщения: «Server busy, tap to retry», «Check your connection» | Fix now |
| H-02 | Global | Offline state | Нет offline mode, нет «No connection» banner | При потере сети — пустые экраны или молчание | HIGH | Persistent banner «No connection» + retry + cached data display | Fix now |
| H-03 | Inventory | Empty state | Пустой инвентарь показывает generic текст | Нет guidance — что делать, чтобы получить предметы | MEDIUM | «Your inventory is empty. Win battles to earn loot!» + CTA → Arena | Fix soon |
| H-04 | Shop | Purchase fail | Ошибка покупки = toast «Error», нет деталей | Игрок не знает: недостаточно золота? Серверная ошибка? Баг? | MEDIUM | Разные сообщения: «Not enough gold (need 500, have 300)», «Server error, try again» | Fix soon |
| H-05 | Combat | Disconnect | Если сеть падает во время боя — поведение непредсказуемо | Бой на сервере, клиент не получает результат | HIGH | Reconnect flow: «Reconnecting...» → show result, или «Battle result saved, view in History» | Fix now |
| H-06 | Auth | Login error | Login error показывается, но нет «Forgot Password» подсказки | Игрок с неправильным паролем не видит hint | LOW | Добавить «Wrong password? Reset it» link рядом с ошибкой | Nice to improve |

---

### B.10 — Help and Documentation

**Оценка: 3/10** (v1 не ставил оценку — это серьёзный пробел)

| # | Screen / Flow | Component | Problem | Why it hurts UX | Severity | Recommendation | Priority |
|---|--------------|-----------|---------|-----------------|----------|---------------|----------|
| D-01 | Post-onboarding | Tutorial | Нет tutorial после создания персонажа — сразу Hub с 7+ зданиями | Новый игрок потерян, не знает куда тапнуть | CRITICAL | Guided tutorial: highlight Training → first combat → first reward → inventory | Fix now |
| D-02 | Arena | Stance system | Stance (attack/defense zones) нигде не объяснён | Ключевая боевая механика непонятна без внешних гайдов | HIGH | Tooltip/tutorial при первом бое: «Choose where to attack and defend» | Fix soon |
| D-03 | Character | Stats meaning | 8 статов, derived stats — нет пояснений | Игрок не знает, что STR влияет на Physical damage | MEDIUM | Info button → tooltip с формулой: «STR → Attack Power: STR×2 + weapon» | Fix soon |
| D-04 | Shop | Item comparison | Предметы без контекста «зачем мне это» | Новый игрок не знает, какие статы нужны его классу | MEDIUM | Добавить «Recommended for [Class]» badge + class-specific sorting | Fix soon |
| D-05 | Dungeon | Difficulty system | Easy/Normal/Hard стамина-стоимость (15/20/25), но reward scaling не объяснён | Игрок не знает, стоит ли платить больше стамины | LOW | Tooltip: «Higher difficulty = better loot chance & more XP» | Nice to improve |
| D-06 | Combat | Damage types | Physical/Poison/Magical — нет объяснения когда какой тип эффективен | Тактическая глубина теряется | MEDIUM | Цветовые индикаторы + tooltip: «This enemy is weak to Magic» | Fix soon |
| D-07 | Global | First-time tooltips | Ни один экран не имеет first-time tooltip или spotlight | Каждый экран — self-discovery | HIGH | Систему progressive tooltips для первого входа на каждый экран | Fix soon |

---

## C. MOBILE GAME–SPECIFIC CHECKS

### C.1 — Thumb Reach & One-Hand Usability

| # | Screen | Problem | Severity | Recommendation |
|---|--------|---------|----------|---------------|
| TH-01 | Hub | HubLogoButton (back) в top-left — за пределами thumb zone | MEDIUM | Оставить (стандарт iOS), но убедиться, что основные CTA внизу |
| TH-02 | Arena | FIGHT button внизу карточки — ✅ хорошо | — | Сохранить |
| TH-03 | Character | «Save Stats» button внизу scroll — ✅ хорошо | — | Сохранить |
| TH-04 | Shop | Tab switcher вверху экрана — трудно достать одной рукой | MEDIUM | Рассмотреть bottom-positioned tabs или swipe-навигацию между категориями |
| TH-05 | Combat | Speed toggle (1X/2X/Skip) в top-right — трудно достать | LOW | Перенести вниз или добавить swipe gesture для speed change |

### C.2 — Tap Target Size

| # | Screen | Component | Current Size | Minimum | Status | Fix |
|---|--------|-----------|-------------|---------|--------|-----|
| TT-01 | Global | All buttons | 48-56px height | 48px | ✅ Pass | — |
| TT-02 | Inventory | Item cards (4-col grid) | ~80px width | 48px | ✅ Pass | — |
| TT-03 | Combat | Status effect codes | Text only, no tap target | 44px | ❌ Fail | Сделать тапаемыми с tooltip |
| TT-04 | Hub | Floating action icons | 50-56px | 48px | ✅ Pass | — |
| TT-05 | BattlePass | Reward nodes | Varies | 48px | ⚠️ Check | Убедиться что все nodes ≥ 48px |
| TT-06 | Leaderboard | Player rows | Full-width, ~44px height | 48px | ❌ Fail | Увеличить row height до 48px minimum |

### C.3 — Readability on Small Screens

| # | Component | Problem | Recommendation |
|---|-----------|---------|---------------|
| RD-01 | Combat log text | 12-14px text во время анимации — трудно читать | Увеличить до 16px minimum, добавить контрастный фон |
| RD-02 | Item stats in grid | В 4-колоночной сетке stat text обрезается | Показать только rarity color + level в grid, полные stats в detail |
| RD-03 | Dungeon boss names | Длинные имена могут обрезаться | `lineLimit(2)` + `.minimumScaleFactor(0.8)` |
| RD-04 | Currency amounts | Большие числа (100,000+) занимают много места | Использовать «100K» формат (уже есть для leaderboard, добавить везде) |

### C.4 — Gesture Conflicts & Accidental Taps

| # | Screen | Risk | Severity | Recommendation |
|---|--------|------|----------|---------------|
| GC-01 | Hub CityMap | Horizontal scroll конфликтует с vertical scroll Hub | MEDIUM | Чёткое разграничение: CityMap = только horizontal, остальной Hub = vertical |
| GC-02 | Inventory | Close swipe на item detail sheet vs scroll внутри sheet | LOW | Добавить drag indicator + large scroll area |
| GC-03 | Arena opponent cards | Тап на карточку (comparison) vs тап на FIGHT button | MEDIUM | Увеличить padding между card body и FIGHT button (минимум 16px) |
| GC-04 | Combat | Skip button рядом с forfeit (если добавим) | HIGH | Физическое разделение: Skip вверху, Forfeit внизу с confirmation |

### C.5 — Modal Fatigue

| # | Flow | Problem | Severity | Recommendation |
|---|------|---------|----------|---------------|
| MF-01 | Hub entry | DailyLoginPopup + LevelUpModal + Quest toast — всё сразу при входе | HIGH | Queue system: показывать по одному с задержкой 500ms между |
| MF-02 | Post-combat | CombatResult → Loot → LevelUp → QuestComplete — каскад модалов | MEDIUM | Объединить в один экран результатов с секциями |
| MF-03 | Shop purchase | Confirmation → Loading → Success toast — 3 шага для каждой покупки | LOW | Optimistic UI: сразу показать успех, откатить при ошибке |

### C.6 — Perceived Performance

| # | Screen | Problem | Recommendation |
|---|--------|---------|---------------|
| PP-01 | Arena → Combat | 0.5-2 сек пустоты после FIGHT | Instant transition + loading overlay |
| PP-02 | Hub → any screen | Skeleton views показываются, но без shimmer animation в некоторых | Убедиться, что ВСЕ skeleton views имеют shimmer |
| PP-03 | Shop item purchase | Loading → toast — без анимации | Optimistic UI: instant feedback, item appears in inventory |
| PP-04 | Dungeon room load | Может быть задержка при загрузке boss info | Предзагрузить следующего босса при завершении текущего |

---

## D. SCREEN-BY-SCREEN AUDIT

### D.1 — Splash Screen (HexboundApp.swift)

**Что есть:** Анимированный логотип с glow эффектом, золотой progress indicator, auto-login check.

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Race condition: auto-login vs 10s timeout — игрок может ждать 10 секунд при плохом интернете | #1 Visibility | HIGH | Показать «Connecting...» через 3 сек, «Retry» через 5 сек, timeout через 10 сек с offline option |
| Нет «Tap to retry» если auto-login зависает | #3 Control | MEDIUM | Добавить retry button после 5 сек |

### D.2 — Login Screen (LoginView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| `.primary(enabled:)` — нестандартный паттерн кнопки | #4 Consistency | LOW | Использовать `.primary` + `.disabled()` |
| `SocialAuthButtonStyle` — `Color.black` hardcoded | #4 Consistency | LOW | Добавить `bgOAuth` в тему |
| Guest login без предупреждения о потере данных | #5 Error Prevention | HIGH | Warning text: «Guest data may be lost» |
| Нет biometric auth (Face ID / Touch ID) | #7 Efficiency | MEDIUM | Добавить Face ID для repeat logins |

### D.3 — Register Screen (RegisterDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| 3 поля (email, password, confirm) без real-time validation | #5 Error Prevention | MEDIUM | Inline validation при onBlur |
| Нет password strength indicator | #1 Visibility | LOW | Добавить strength bar |

### D.4 — Onboarding (OnboardingDetailView.swift) — **КРИТИЧЕСКИЙ ЭКРАН**

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| **1019 строк монолита** без extracted components | #4 Consistency | CRITICAL | Разбить на `RaceStepView`, `GenderStepView`, `ClassStepView`, `NameStepView` |
| **30+ hardcoded hex colors** | #4 Consistency | CRITICAL | Все цвета через `DarkFantasyTheme` |
| **Custom `AppearanceButtonStyle`** не из ButtonStyles | #4 Consistency | HIGH | Использовать `PrimaryButtonStyle` |
| **Hardcoded font sizes** (14, 12, 10, 22px) | #4 Consistency | HIGH | Использовать `LayoutConstants.text*` |
| **Hardcoded spacing** | #4 Consistency | HIGH | Использовать `LayoutConstants.space*` |
| Нет Skip для returning players | #3 Control | MEDIUM | «Quick Create» опция |
| Нет preview итогового персонажа перед confirmation | #5 Error Prevention | MEDIUM | Summary screen: «Your hero: Orc Warrior named Gruk» с Edit/Confirm |
| Name availability проверяется только при submit | #5 Error Prevention | MEDIUM | Debounce-проверка при вводе |
| Нет back confirmation (потеря прогресса шагов) | #5 Error Prevention | LOW | «Go back? You'll lose this step's selection» |

### D.5 — Hub Screen (HubView.swift + CityMapView)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| CityMap buildings без подписей при первом визите | #10 Help | MEDIUM | First-time tooltips с названиями зданий |
| 3-4 floating action icons = визуальный шум | #8 Aesthetic | MEDIUM | Группировать в FAB |
| BattlePassCard mock data | #2 Real World | HIGH | Wire real data |
| Нет stamina recovery timer | #1 Visibility | HIGH | Countdown на StaminaBarView |
| Currency отображается в двух местах | #4 Consistency | MEDIUM | Один каноничный компонент |
| Нет notification badge для невостребованных наград | #1 Visibility | MEDIUM | Badge на соответствующих зданиях |
| Modal queue (DailyLogin + LevelUp + Quest) при входе | Mobile: Modal Fatigue | HIGH | Последовательная очередь с задержкой |

### D.6 — Arena Screen (ArenaDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Нет loading feedback при FIGHT | #1 Visibility | CRITICAL | LoadingOverlay сразу после тапа |
| Нет confirmation перед тратой 10 STA | #5 Error Prevention | HIGH | Confirmation dialog |
| «NEW OPPONENTS» циклирует пул, не фетчит | #2 Real World | MEDIUM | Ребрендинг в «SHUFFLE» или real refresh |
| Кастомные табы вместо TabSwitcher | #4 Consistency | MEDIUM | Миграция на TabSwitcher |
| Hardcoded colors | #4 Consistency | MEDIUM | Theme tokens |
| Нет текущей stance preview | #6 Recognition | HIGH | Mini stance display |
| Free PvP counter не виден до входа в Arena | #1 Visibility | MEDIUM | Индикатор на Hub |

### D.7 — Combat Screen (CombatDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Нет mid-combat exit (forfeit) | #3 Control | HIGH | Forfeit + confirmation |
| 3-буквенные коды статусов (BLD, BRN, STN) | #6 Recognition | MEDIUM | Полные слова + иконки |
| Hardcoded background `0x0A0A14` | #4 Consistency | LOW | `DarkFantasyTheme.bgAbyss` |
| Inline speed button styling | #4 Consistency | LOW | Extract to ButtonStyles |
| Combat log = dense text | #8 Aesthetic | MEDIUM | Visual cards per turn |
| Нет disconnect recovery | #9 Error Recovery | HIGH | Reconnect flow |
| Status effects не отображаются под HP bars | #1 Visibility | MEDIUM | Icon row под HP bar каждого бойца |

### D.8 — Combat Result (CombatResultDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Нет «Rematch» кнопки | #7 Efficiency | HIGH | «Fight Again» + «New Opponent» + «Return to Hub» |
| Нет прогресса квестов | #6 Recognition | MEDIUM | ActiveQuestBanner |
| Нет прогресса до следующего ранга | #1 Visibility | LOW | Rating progress bar |

### D.9 — Loot Screen (LootDetailView.swift)

**Статус: ✅ В целом хорошо** — анимация reveal, rarity styling, proper CTAs.

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| «Take All» без preview куда пойдут предметы | #5 Error Prevention | LOW | Показать «→ Inventory» рядом |
| Нет сравнения с текущим equipment | #6 Recognition | MEDIUM | «Better than equipped» / «Worse» badge |

### D.10 — Dungeon Select (DungeonSelectDetailView.swift)

**Статус: ✅ Хорошо** — difficulty tabs, dungeon cards, progress bars.

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Locked dungeons не объясняют требования чётко | #10 Help | LOW | «Reach Level 10 to unlock» под padlock |
| Нет рекомендуемого difficulty | #10 Help | LOW | «Recommended» badge на подходящей difficulty |

### D.11 — Dungeon Room (DungeonRoomDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Mini-node progress row мелкий | #1 Visibility | LOW | Увеличить + добавить «Floor X/10» |
| Нет exit mid-dungeon | #3 Control | MEDIUM | «Leave Dungeon» с сохранением прогресса |
| Boss carousel может быть неочевидным | #10 Help | LOW | Swipe indicator при первом визите |

### D.12 — Shop Screen (ShopDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Нет preview на персонаже | #6 Recognition | MEDIUM | «Preview on character» overlay |
| Нет buy-back для проданных | #3 Control | HIGH | Buy-back tab |
| Нет «Recommended for your class» | #10 Help | MEDIUM | Class-specific badges/sorting |
| Tabs вверху — трудно достать одной рукой | Mobile: Thumb | MEDIUM | Swipe navigation или bottom tabs |

### D.13 — Character Screen (CharacterDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| 8 статов + derived stats — информационная перегрузка | #8 Aesthetic | LOW | Collapsible sections |
| Нет tooltip для stat formulas | #10 Help | MEDIUM | Info icon → tooltip |
| Stance selection спрятан далеко | #6 Recognition | MEDIUM | Prominent stance section |

### D.14 — Inventory / Equipment

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Нет search/sort | #7 Efficiency | MEDIUM | Sort + search |
| Нет auto-equip | #7 Efficiency | MEDIUM | «Optimize Equipment» button |
| DurabilityRing hardcoded colors | #4 Consistency | LOW | Theme tokens |
| Нет upgrade indicator в grid view | #6 Recognition | MEDIUM | Green/red arrows |

### D.15 — Settings (SettingsDetailView.swift)

**Статус: ✅ Полностью compliant** — custom `.settingsCard()` хорошо реализован.

### D.16 — Daily Login (DailyLoginDetailView.swift + Popup)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Hardcoded `Color(red:green:blue:)` в day circles | #4 Consistency | LOW | Theme tokens |
| Popup автоматически появляется — может мешать | Mobile: Modal Fatigue | MEDIUM | Очередь с другими модалами |

### D.17 — Daily Quests (DailyQuestsDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Каждый квест клеймится отдельно | #7 Efficiency | MEDIUM | «Claim All» button |

### D.18 — Achievements (AchievementsDetailView.swift)

**Статус: ✅ Compliant** — category tabs, progress bars, claim system.

### D.19 — Battle Pass (BattlePassDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Нет countdown до конца сезона | #1 Visibility | MEDIUM | «Season ends in X days» banner |
| Нет объяснения источников XP | #10 Help | LOW | «Earn BP XP from: PvP, Dungeons, Quests» |
| Нет preview содержимого наград | #6 Recognition | LOW | Tap reward → details popup |

### D.20 — Leaderboard (LeaderboardDetailView.swift)

| Problem | Heuristic | Severity | Fix |
|---------|-----------|----------|-----|
| Row height может быть < 48px | Mobile: Tap Target | LOW | Min height 48px |
| Нет tap → player profile | #7 Efficiency | MEDIUM | Открывать mini profile при тапе |
| Нет «last updated» timestamp | #1 Visibility | LOW | Timestamp внизу |

### D.21 — Minigames (Shell Game, Gold Mine, Dungeon Rush)

**Статус: ✅ Compliant** — proper theming, animation states, button styles.

---

## E. FLOW AUDIT

### E.1 — Onboarding Flow

```
Login/Register → Onboarding (4 steps) → Hub
```

**Problems:**
1. ❌ Онбординг вне дизайн-системы (CRITICAL)
2. ❌ Нет skip для experienced players
3. ❌ Нет summary/confirmation шага перед finalization
4. ❌ Нет tutorial после онбординга → игрок «брошен» на Hub
5. ❌ Name validation только при submit
6. ⚠️ 4 шага — на грани слишком долго для мобильного онбординга

**Recommendation:** Рефакторинг на 3 шага (Race+Gender → Class → Name+Confirm) + tutorial flow после создания.

### E.2 — PvP Combat Flow

```
Hub → Arena → Select Opponent → [Comparison] → FIGHT → Combat → Result → Loot → Hub
```

**Problems:**
1. ❌ Нет loading feedback после FIGHT (CRITICAL)
2. ❌ Нет confirmation для stamina cost
3. ❌ 5 экранов от FIGHT до Hub — слишком длинный path
4. ❌ Нет Rematch на Result
5. ❌ Stance не видна перед боем
6. ❌ Нет disconnect recovery
7. ⚠️ Comparison Sheet открывается только из карточки — неочевидно

**Recommendation:** FIGHT → confirmation (STA cost) → loading overlay → Combat (с forfeit) → unified Result+Loot экран → Rematch/New/Hub.

### E.3 — Dungeon Flow

```
Hub → Dungeon Select → Difficulty → Room → Boss Fight → Victory → Next Room → ... → Complete
```

**Problems:**
1. ❌ Нет exit mid-dungeon (только HubLogoButton, прогресс неясен)
2. ⚠️ Victory animation повторяется 10 раз per dungeon
3. ⚠️ Нет общего прогресса «Boss 3/10 defeated» prominent на экране

**Recommendation:** Добавить «Leave Dungeon» с save progress, skip victory animation option, prominent floor counter.

### E.4 — Shop Purchase Flow

```
Hub → Shop → Browse Tabs → Select Item → [Detail] → Buy → [Confirmation] → Success Toast
```

**Problems:**
1. ❌ Нет comparison с текущим equipment
2. ❌ Нет buy-back
3. ❌ Нет «Recommended» для класса
4. ⚠️ Tab navigation вверху — трудно достать

**Recommendation:** Add comparison overlay, buy-back tab, class recommendations, swipe-between-tabs.

### E.5 — Inventory Management Flow

```
Hub → Character/Inventory → Filter → Tap Item → Detail Sheet → Equip/Sell/Compare
```

**Problems:**
1. ❌ Нет search/sort
2. ❌ Нет auto-equip
3. ❌ Sell disabled для equipped без объяснения
4. ❌ Нет bulk actions (sell all common items)
5. ⚠️ Upgrade indicators только в detail sheet

**Recommendation:** Sort/search bar, auto-equip, «Sell All Common» with confirmation, grid-level upgrade arrows.

### E.6 — Daily Engagement Flow

```
Open App → Splash → Auto-login → Hub → DailyLoginPopup → [LevelUpModal] → [QuestToast] → Play
```

**Problems:**
1. ❌ Multiple modals при входе = modal fatigue
2. ❌ Нет queue system для модалов
3. ⚠️ DailyLoginPopup блокирует Hub до dismiss

**Recommendation:** Sequential queue: DailyLogin (auto-dismiss 3s if no claim) → LevelUp (if pending) → Quest toast (non-blocking). Never show more than 1 blocking modal.

---

## F. PERFORMANCE PERCEPTION AUDIT

### F.1 — Places Where UX Feels Slow

| # | Location | Perceived Latency | Real Cause | Fix |
|---|----------|-------------------|------------|-----|
| 1 | FIGHT button → Combat screen | 0.5-2 sec | Combat generation (7-14 turns) | Instant transition + LoadingOverlay + precompute while showing transition |
| 2 | Splash → Hub | Up to 10 sec | Auto-login timeout | Progressive: show after 3s «Connecting...», after 5s «Retry», after 10s fallback |
| 3 | Hub initial load | 1-3 sec | Prefetch opponents, shop, achievements, dungeons | Show Hub with skeleton → progressive reveal (character first, then buildings, then banners) |
| 4 | Shop purchase → success | 0.5-1 sec | API call | Optimistic UI: show success immediately, revert on error |
| 5 | Item equip → update | 0.3-0.5 sec | API call | Optimistic UI: update locally first, sync in background |
| 6 | Dungeon room transition | Variable | Boss data load | Preload next boss while current fight |

### F.2 — Recommended Improvements

1. **Skeleton States:** Убедиться что ВСЕ skeleton views имеют shimmer animation (не static gray). Проверить: BattlePass, Leaderboard, Dungeon.
2. **Optimistic UI:** Для equip, sell, buy, claim actions — немедленный UI update, rollback при ошибке.
3. **Button Feedback:** Все кнопки уже имеют scalePress — ✅. Но добавить haptic feedback (UIImpactFeedbackGenerator) для primary actions.
4. **Transition Improvements:** Matched geometry effect для item equip (предмет «летит» в слот). Hero animation для навигации Hub → Screen.
5. **Instant State Updates:** При level up — сразу обновить все метрики на UI, не ждать API refresh.
6. **Reduce Confirmations:** Для повторных действий (buy same potion 2nd time) — skip confirmation.
7. **Loading Communication:** Для операций > 2 sec — показать estimated time или progress.

---

## G. GLOBAL UI CONSISTENCY AUDIT

### G.1 — Buttons

| Aspect | Current State | Inconsistency | Standard |
|--------|--------------|---------------|----------|
| Primary CTA | `PrimaryButtonStyle` — gold gradient, 56px | ✅ Consistent on 90% screens | Except: Onboarding uses custom `AppearanceButtonStyle` |
| Secondary | `SecondaryButtonStyle` — gold outline, 48px | ✅ Consistent | — |
| Danger | `DangerButtonStyle` — crimson, 48px | ✅ Consistent | — |
| Ghost | `GhostButtonStyle` — text only | ✅ Consistent | — |
| Nav tiles | `NavGridButtonStyle` — Hub only | ✅ Consistent | — |
| Combat speed | Inline styled | ❌ Not in ButtonStyles | Extract to `CombatSpeedButtonStyle` |
| Login enabled | `.primary(enabled:)` | ❌ Custom parameter | Use `.primary` + `.disabled()` |
| **Standard:** Все кнопки MUST использовать ButtonStyles.swift. Zero custom inline styles. |

### G.2 — Tabs

| Aspect | Current State | Standard |
|--------|--------------|----------|
| Arena | Custom implementation | ❌ Migrate to TabSwitcher |
| Achievements | TabSwitcher | ✅ |
| Leaderboard | TabSwitcher | ✅ |
| Shop | TabSwitcher | ✅ |
| Inventory | Filter chips (not tabs) | ✅ Different component — OK |
| **Standard:** Все tab interfaces MUST использовать `TabSwitcher`. |

### G.3 — Cards

| Aspect | Current State | Standard |
|--------|--------------|----------|
| Standard containers | `.panelCard()` | ✅ 90% screens |
| Item containers | `.rarityCard()` | ✅ Consistent |
| Info panels | `.infoPanel()` | ✅ Consistent |
| Modals | `.modalOverlay()` | ✅ Consistent |
| Hub character | Custom gradient (hardcoded) | ❌ Add `bgCardGradient` to theme |
| Hub banners | 14px padding (not 16px) | ⚠️ Document as exception |
| **Standard:** Все containers из CardStyles.swift. Hub banners = 14px exception. |

### G.4 — Colors

| Aspect | Current State | Standard |
|--------|--------------|----------|
| Theme system | 60+ tokens in DarkFantasyTheme | ✅ Comprehensive |
| View compliance | ~80% views use theme tokens | ❌ 15-20 hardcoded Color(hex:) |
| HP Bar | 3 implementations | ❌ Standardize to green→amber→red |
| Missing tokens | xpRing, textWarning, bgCardGradient | ❌ Need to add |
| **Standard:** ZERO hardcoded Color(hex:) in View files. |

### G.5 — Typography

| Aspect | Current State | Standard |
|--------|--------------|----------|
| Font system | Oswald (titles) + Inter (body) | ✅ Correct |
| Scale | 11px (badge) → 40px (cinematic) | ✅ Well-defined |
| Onboarding | Hardcoded sizes | ❌ Use LayoutConstants |
| Level Up modal | Hardcoded 64px, 44px | ⚠️ Add to LayoutConstants |
| **Standard:** Все font sizes из LayoutConstants. Min 11px. Min weight 500. |

### G.6 — Spacing

| Aspect | Current State | Standard |
|--------|--------------|----------|
| Screen padding | 16px | ✅ Consistent |
| Card padding | 16px | ✅ 90% |
| Hub banners | 14px | ⚠️ Exception to document |
| Onboarding | Hardcoded 14, 12, 10, 22px | ❌ Use LayoutConstants |
| **Standard:** Все spacing из LayoutConstants.space* |

### G.7 — Icons

| Aspect | Current State | Standard |
|--------|--------------|----------|
| HUD icons | Custom `Image("hud-*")` | ✅ |
| Hub banners | Mix of emoji + custom | ❌ All custom |
| Class icons | Enum-based SF Symbol + custom | ✅ |
| Race icons | Emoji-based | ⚠️ Consider custom assets |
| **Standard:** Все gameplay icons = custom assets. Zero emoji в production UI. |

### G.8 — Loading States

| Aspect | Current State | Standard |
|--------|--------------|----------|
| Screen data | Skeleton views | ✅ Good |
| Button actions | Some have loading | ⚠️ ALL buttons with API calls MUST show spinner |
| Combat init | NO loading | ❌ CRITICAL — add LoadingOverlay |
| Full-screen | LoadingOverlay | ✅ Exists but hardcoded colors |
| **Standard:** Skeleton для экранов. Spinner для кнопок. LoadingOverlay для transitions. |

### G.9 — Empty States

| Aspect | Current State | Standard |
|--------|--------------|----------|
| Inventory empty | Generic text | ❌ Add CTA |
| Opponents empty | Refresh message | ⚠️ Better messaging needed |
| History empty | Generic text | ❌ Add CTA to Arena |
| **Standard:** Все empty states: Icon + Title + Actionable subtitle + CTA button. |

### G.10 — Error States

| Aspect | Current State | Standard |
|--------|--------------|----------|
| API errors | Generic toast | ❌ Specific messages + retry |
| Network loss | No handling | ❌ CRITICAL — add offline banner |
| Auth errors | Form-level messages | ✅ |
| **Standard:** Specific error messages. Network banner. Retry mechanism. |

---

## H. STANDARDIZATION GUIDE (Mini Design Governance)

### H.1 — Button System

```
PRIMARY:    Gold gradient, 56px, UPPERCASE Oswald 18px
            → Use for: Main CTA (1 per screen max)
            → Code: .buttonStyle(.primary)

SECONDARY:  Gold outline, 48px, UPPERCASE Oswald 16px
            → Use for: Alternative actions
            → Code: .buttonStyle(.secondary)

DANGER:     Crimson #E63946, 48px, UPPERCASE
            → Use for: Destructive actions (ALWAYS with confirmation)
            → Code: .buttonStyle(.danger)

GHOST:      Text only, textSecondary
            → Use for: Cancel, Skip, Dismiss
            → Code: .buttonStyle(.ghost)

COMPACT:    Content-sized variants of Primary/Danger
            → Use for: Inline CTAs in cards
            → Code: .buttonStyle(.compactPrimary)

DISABLED:   40% opacity, #333340 bg, #555566 text
            → Automatic when .disabled(true) applied

RULES:
- Maximum 1 Primary button per screen
- Danger buttons ALWAYS paired with confirmation dialog
- No inline styling — all from ButtonStyles.swift
- All button text: UPPERCASE
- All buttons: press state (scale 0.97, 150ms)
- Minimum touch target: 48×48pt
```

### H.2 — Icon Behavior

```
INTERACTIVE ICONS:
- Minimum 48×48pt touch target (even if icon is 24px)
- contentShape(.rect) for full hit area
- Press state: scale 0.9 + color brighten
- Badge: 14px red circle with pulse animation

DECORATIVE ICONS:
- No touch target needed
- SF Symbols preferred for system icons
- Custom assets for game icons (hud-*, class-*, race-*)
- NO emoji in production UI — all custom assets

ICON SIZING:
- Navigation: 24px icon, 48px touch target
- Cards: 20-24px
- Hub floating: 28px icon, 56px circle
- HUD: 40px
```

### H.3 — Modal Rules

```
MODAL TYPES:
1. Sheet (bottom-up): For detail views, info, comparisons
   → .sheet(isPresented:) with presentationDetents
   → Drag indicator + content scroll

2. Overlay (center): For confirmations, celebrations, daily login
   → Custom overlay with bgModal backdrop
   → .modalOverlay() modifier
   → Scale 0.9→1.0 + fade entrance

3. Toast (top banner): For feedback, notifications
   → ToastOverlayView system
   → Auto-dismiss 3 seconds
   → Max 3 stacked

RULES:
- NEVER show 2 blocking modals simultaneously
- Queue system: show one, wait dismiss, show next
- Every modal MUST have a close mechanism (X button OR tap backdrop)
- Confirmation modals: Cancel (secondary) + Confirm (primary/danger)
- Modal padding: 24px
- Modal corner radius: 16px
- Modal border: 3px borderOrnament
```

### H.4 — Card Structure

```
PANEL CARD (default container):
  ┌──────────────────────────────┐
  │ bgSecondary                  │
  │ 16px padding                 │
  │ 12px corner radius           │
  │ 1px borderSubtle             │
  │ 1px metallic top highlight   │
  └──────────────────────────────┘
  → .panelCard()

RARITY CARD (items):
  ┌──────────────────────────────┐
  │ bgTertiary                   │
  │ 2px rarity color border      │
  │ Rarity glow shadow           │
  │ 12px corner radius           │
  └──────────────────────────────┘
  → .rarityCard(.epic)

INFO PANEL (read-only):
  ┌──────────────────────────────┐
  │ bgPrimary (darker)           │
  │ 1px borderSubtle             │
  │ 8px corner radius            │
  └──────────────────────────────┘
  → .infoPanel()
```

### H.5 — Spacing Rules

```
SCREEN:
- Horizontal padding: 16px (screenPadding)
- Top gap below header: 16px (screenTopGap)

BETWEEN ELEMENTS:
- 2px  (space2XS) — within tight groups
- 4px  (spaceXS)  — between closely related items
- 8px  (spaceSM)  — between cards in a list
- 12px (spaceMD-) — between sub-sections
- 16px (spaceMD)  — between sections
- 24px (spaceLG)  — between major sections
- 32px (spaceXL)  — between screen areas
- 48px (space2XL) — hero spacing

CARD INTERNAL: 16px (cardPadding)
HUB BANNERS: 14px (bannerPadding — documented exception)
MODALS: 24px (spaceLG)
```

### H.6 — Typography Hierarchy

```
CINEMATIC TITLE: Cinzel Bold 40px    → Victory/Defeat screens
SCREEN TITLE:    Oswald Bold 28px    → Top-of-screen titles
SECTION HEADER:  Oswald SemiBold 22px → Panel headers
CARD TITLE:      Oswald Medium 18px  → Item names, character names
BUTTON LABEL:    Oswald SemiBold 18px → All button text, UPPERCASE
BODY TEXT:       Inter Medium 16px    → Descriptions, instructions
UI LABEL:        Inter SemiBold 14px  → Stat labels, small info
CAPTION:         Inter Medium 12px    → Timestamps, fine print
BADGE:           Inter Bold 11px      → Notification counts, "NEW"

RULES:
- Never weight < 500 (Medium)
- Never size < 11px
- Body + buttons = 16px minimum
- All titles: UPPERCASE + letter spacing
- Gold color for screen titles (goldBright)
- White for body text (textPrimary)
- Gray for secondary (textSecondary)
```

### H.7 — Navigation Rules

```
BACK:    HubLogoButton → top-left toolbar → clears mainPath to Hub
DEPTH:   Maximum 3 levels (Hub → Screen → Sub-screen)
TABS:    TabSwitcher component → within screen
MODALS:  Sheet or Overlay → don't count as nav depth
COMBAT:  Treated as modal flow (not nav depth)

EXCEPTIONS (documented):
- Hub: No header, uses CityMapView
- Combat: Fullscreen immersive, no header
- Onboarding: Step-based, custom back buttons

RULES:
- Hub reachable in 1 tap from ANY screen
- No dead-end screens
- Always provide back/continue/close/exit
```

### H.8 — State Rules

```
DEFAULT:   Standard appearance
HOVER:     N/A (mobile — no hover)
PRESSED:   Scale 0.97 (buttons), 0.95 (tiles), 150ms
SELECTED:  2px gold border + gold glow
DISABLED:  40% opacity, #333340 bg, no interaction
LOCKED:    Grayscale + padlock icon + 50% opacity
EQUIPPED:  Rarity border + [E] badge + star icon
CLAIMABLE: Pulsing gold border + notification dot
CLAIMED:   Green checkmark + "Claimed" text
LOADING:   Skeleton shimmer (screen) / Spinner (button)
ERROR:     Red border + error message
EMPTY:     Icon + title + actionable subtitle + CTA
```

### H.9 — Feedback Rules

```
BUTTON TAP:     Scale press + color shift ≤ 100ms
NAVIGATION:     Screen transition (fade/slide) 300ms
API START:      Loading indicator immediate
API SUCCESS:    Toast (success) + data refresh ≤ 200ms
API FAILURE:    Toast (error) + retry option ≤ 200ms
REWARD CLAIM:   Gold particle burst + value animation 500ms
LEVEL UP:       Full-screen modal + scale animation 800ms
ITEM EQUIP:     Slot highlight + badge appear 300ms
PURCHASE:       Item fly-to-inventory animation + particle 500ms
DESTRUCTIVE:    Confirmation dialog BEFORE execution (blocking)
STAT SAVE:      Button text → "Saved!" 1s → reset

HAPTICS (recommended):
- Primary button tap: UIImpactFeedbackGenerator(.medium)
- Reward claim: UINotificationFeedbackGenerator(.success)
- Error: UINotificationFeedbackGenerator(.error)
- Level up: UIImpactFeedbackGenerator(.heavy) × 3
```

### H.10 — Interaction Rules

```
DESTRUCTIVE ACTIONS (require confirmation):
- Sell item
- Logout
- Delete account
- Reset stat allocation
- Spend gems (premium currency)
- Forfeit combat

NON-DESTRUCTIVE (no confirmation needed):
- Equip item
- Buy with gold (non-premium)
- Claim reward
- Change stance
- Navigate between screens
- Use consumable (small cost)

REPEAT ACTIONS (skip confirmation after first):
- Buy same consumable 2nd+ time in session
- Quick rematch same opponent
```

---

## I. СВОДНАЯ ТАБЛИЦА ВСЕХ НАЙДЕННЫХ ПРОБЛЕМ

### Priority: Fix Now (before next release)

| ID | Screen | Problem | Severity |
|----|--------|---------|----------|
| V-01 | Arena→Combat | Нет loading feedback после FIGHT | CRITICAL |
| CS-01 | Onboarding | 1019-строчный монолит, 30+ hardcoded values | CRITICAL |
| D-01 | Post-onboarding | Нет tutorial для нового игрока | CRITICAL |
| V-02 | Hub | BattlePass mock data | HIGH |
| V-05 | Hub | Нет stamina recovery timer | HIGH |
| V-08 | Global | Нет offline/network error UX | HIGH |
| E-01 | Arena | Нет confirmation перед тратой STA | HIGH |
| E-02 | Shop | Нет double-confirm для gem purchases | HIGH |
| E-05 | Auth | Нет guest data loss warning | HIGH |
| H-01 | Global | Generic error toasts | HIGH |
| H-02 | Global | Нет offline banner | HIGH |
| CS-06 | Multiple | 15-20 hardcoded colors | HIGH |
| F-01 | Post-combat | Нет Rematch button | HIGH |

### Priority: Fix Soon (within 2 sprints)

| ID | Screen | Problem | Severity |
|----|--------|---------|----------|
| C-01 | Combat | Нет mid-combat exit (forfeit) | HIGH |
| C-04 | Shop | Нет buy-back | HIGH |
| D-02 | Arena | Stance system не объяснён | HIGH |
| D-07 | Global | Нет first-time tooltips | HIGH |
| R-01 | Arena | Stance не видна перед боем | HIGH |
| MF-01 | Hub | Modal queue (multiple modals at once) | HIGH |
| H-05 | Combat | Нет disconnect recovery | HIGH |
| CS-02 | Multiple | HP Bar — 3 реализации | HIGH |
| M-01 | Combat | 3-letter status codes | MEDIUM |
| M-05 | Hub | CityMap без подписей | MEDIUM |
| CS-03 | Hub | Двойной currency display | MEDIUM |
| CS-04 | Arena | Кастомные табы | MEDIUM |
| CS-05 | Hub | Emoji icons | MEDIUM |
| C-02 | Onboarding | Нет Skip | MEDIUM |
| C-03 | Stats | Нет Reset | MEDIUM |
| C-05 | Inventory | Sell disabled без объяснения | MEDIUM |
| C-06 | Arena | Нет re-fight | MEDIUM |
| C-08 | Dungeon | Нет exit mid-dungeon | MEDIUM |
| R-02 | Result | Нет quest progress | MEDIUM |
| R-03 | Inventory | Нет upgrade indicators | MEDIUM |
| R-05 | Shop | Нет equipped comparison | MEDIUM |
| F-02 | Inventory | Нет search/sort | MEDIUM |
| F-03 | Inventory | Нет auto-equip | MEDIUM |
| F-06 | Quests | Нет Claim All | MEDIUM |
| D-03 | Character | Нет stat tooltips | MEDIUM |
| D-06 | Combat | Damage types не объяснены | MEDIUM |
| A-01 | Hub | Floating icons clutter | MEDIUM |
| A-04 | Combat | Dense text log | MEDIUM |

### Priority: Nice to Improve (quarter backlog)

| ID | Screen | Problem | Severity |
|----|--------|---------|----------|
| M-02 | Character | Prestige: 0 visible | LOW |
| M-03 | Character | Stat abbreviations | LOW |
| CS-07 | Login | .primary(enabled:) pattern | LOW |
| CS-08 | Combat | Inline speed button styling | LOW |
| CS-10 | Hub | Banner 14px magic number | LOW |
| V-06 | Shop | Purchase animation | LOW |
| V-07 | Dungeon | Floor progress visibility | LOW |
| V-09 | Result | Rating context | LOW |
| F-05 | Shop | Bulk buy consumables | LOW |
| F-07 | Dungeon | Skip victory animation | LOW |
| R-04 | Hub | BP progress on Hub | LOW |
| R-06 | Arena | Rating delta context | LOW |

---

## J. ОЦЕНКИ ПО КАЖДОМУ HEURISTIC (ФИНАЛЬНЫЕ)

| # | Heuristic | Score | v1 Score | Key Problem |
|---|-----------|-------|----------|-------------|
| 1 | Visibility of System Status | **5/10** | 7/10 | Нет combat loading, нет stamina timer, нет offline indicator |
| 2 | Match Between System and Real World | **7/10** | 8/10 | Status codes, CityMap без подписей |
| 3 | User Control and Freedom | **5/10** | 7/10 | Нет forfeit, нет buy-back, нет rematch, нет dungeon exit |
| 4 | Consistency and Standards | **5/10** | 6/10 | Onboarding монолит, 3 HP bars, hardcoded colors |
| 5 | Error Prevention | **5/10** | 7/10 | Нет STA confirmation, нет gem confirm, нет guest warning |
| 6 | Recognition Rather Than Recall | **6/10** | 8/10 | Stance скрыта, нет upgrade indicators, нет quest progress on result |
| 7 | Flexibility and Efficiency | **6/10** | 8/10 | Нет rematch, нет search/sort, нет auto-equip, нет claim all |
| 8 | Aesthetic and Minimalist Design | **8/10** | 9/10 | Hub visual noise, combat log density |
| 9 | Error Recognition and Recovery | **4/10** | 6/10 | Generic toasts, нет offline, нет disconnect recovery |
| 10 | Help and Documentation | **3/10** | N/A | Нет tutorial, нет tooltips, нет stat explanations |

**Средний балл: 5.4/10** (v1 давал ~7.5/10 — значительно завышено)

---

## K. ИТОГОВЫЕ РЕКОМЕНДАЦИИ

### Immediate (Week 1):
1. LoadingOverlay на FIGHT flow
2. Stamina confirmation dialog
3. Guest data loss warning
4. Offline/network error banner
5. Wire real BattlePass data
6. Replace all hardcoded Color(hex:) with theme tokens

### Short-term (Weeks 2-3):
1. **Onboarding refactor** — extract components, use theme system
2. **Post-onboarding tutorial** — guided first combat
3. **Rematch button** на CombatResult
4. **HP Bar unification** — single implementation
5. **Combat forfeit** option
6. **Buy-back** в Shop
7. **Modal queue** system
8. **Stamina recovery timer** на Hub
9. **Stance preview** в Arena

### Medium-term (Month 2):
1. First-time tooltips system
2. Inventory search/sort/auto-equip
3. Claim All for quests
4. Player profiles from leaderboard
5. Disconnect recovery for combat
6. Stat tooltips and explanations
7. Shop item comparison with equipped

### Long-term (Quarter):
1. Face ID / biometric auth
2. Bulk purchases
3. Dungeon progress saving
4. Progressive disclosure for complex screens
5. Animation skip options
6. Full offline mode with sync

---

> **Document Status:** COMPLETE v2.0
> **Methodology:** Nielsen Norman 10 Heuristics + Mobile Game UX Best Practices
> **Total Issues Found:** 87
> **Critical:** 3 | High: 22 | Medium: 38 | Low: 24
> **Estimated Fix Effort:** 20-30 developer-days (all priorities)
> **Next Review:** After Critical + High fixes implemented
