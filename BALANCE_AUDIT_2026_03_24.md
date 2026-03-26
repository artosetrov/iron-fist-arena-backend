# Hexbound — Комплексный аудит баланса и прогрессии

**Дата:** 2026-03-24
**Версия:** 1.0
**Автор:** Senior Game Economy & Progression Analyst

---

## 1. Executive Summary

Hexbound — мобильная PvP RPG с 8 статами, 4 классами, системой экипировки, стамины, ELO-рейтинга и множественными валютами (gold/gems). Игра находится в стадии активной разработки. После глубокого анализа всех формул, констант и систем я выявил **5 критических проблем**, **8 серьёзных дисбалансов** и **12 рекомендаций по улучшению**.

### Общая оценка: 6.5/10

**Сильные стороны:**
- Продуманная боевая система с 8 статами и стойками (stance zones)
- Хороший фундамент для экономики: две валюты, prestige, battle pass
- Сервер-авторитетная архитектура — защита от читов
- Live config для горячей перенастройки баланса

**Ключевые проблемы:**
- Золото обесценивается к mid-game (уровень 20+)
- XP-кривая слишком пологая на ранних уровнях и слишком крутая позже
- Апгрейд экипировки +6…+10 — лотерея без safety net
- Стамина-гейт создаёт жёсткий потолок в 12 PvP боёв в день
- Отсутствует стабильный gold sink после покупки экипировки

---

## 2. Balance Audit — Детальный разбор систем

### 2.1 Прогрессия (XP и уровни)

**Формула XP:** $XP(L) = 100L + 20L^2$

| Уровень | XP до следующего | PvP побед для level-up | Дней (6 побед/день) |
|---------|-----------------|----------------------|---------------------|
| 1→2 | 280 | 3 | 0.5 |
| 5→6 | 1,320 | 11 | 1.8 |
| 10→11 | 3,520 | 30 | 5.0 |
| 20→21 | 10,920 | 91 | 15.2 |
| 30→31 | 22,320 | 186 | 31.0 |
| 40→41 | 37,720 | 315 | 52.5 |
| 49→50 | 55,000 | 459 | 76.5 |

**XP за PvP:** победа = 120 XP, поражение = 40 XP (с level scaling: $+2\%$ за каждый уровень выше 1-го).

**Проблема:** На уровне 40 нужно **315 PvP побед** для одного уровня. При лимите ~12 боёв в день (120 стамины ÷ 10 за бой) и ~50% winrate = ~6 побед/день → **52.5 дней на один уровень**. Это неприемлемо.

**Stat points per level:** 3 очка. За 50 уровней: $3 \times 50 = 150$ stat points + базовые стартовые статы.

### 2.2 Боевая система

**Формулы урона по классам:**

| Класс | Формула | Primary stat |
|-------|---------|-------------|
| Warrior | $STR \times 1.5 + Level \times 2$ | STR |
| Tank | $STR \times 1.3 + VIT \times 0.3 + Level \times 2$ | STR/VIT |
| Rogue | $AGI \times 1.5 + Level \times 2$ | AGI |
| Mage | $INT \times 1.2 + WIS \times 0.5 + Level \times 2$ | INT/WIS |

**Крит/Додж:**
- Крит: $\min(LUK \times 0.7 + AGI \times 0.15 + stance\_crit,\ 50\%)$
- Додж: $\min(AGI \times 0.2 + LUK \times 0.1 + class\_bonus + stance\_dodge,\ 30\%)$

**Анализ баланса классов:**

Предположим уровень 25, 75 total allocated stat points (25 × 3), оптимальная раскачка:

**Warrior** (55 STR, 10 VIT, 10 END):
- Базовый урон: $55 \times 1.5 + 25 \times 2 = 132.5$
- HP: $80 + 10 \times 5 + 10 \times 3 = 160$
- Armor: $10 \times 2 + 55 \times 0.5 = 47.5$

**Mage** (55 INT, 20 WIS):
- Базовый урон: $55 \times 1.2 + 20 \times 0.5 + 25 \times 2 = 126$
- HP: $80 + 0 \times 5 + 0 \times 3 = 80$ (стеклянная пушка!)
- Magic Resist: $20 \times 2 + 55 \times 0.5 = 67.5$

**Rogue** (45 AGI, 15 LUK, 15 STR):
- Базовый урон: $45 \times 1.5 + 25 \times 2 = 117.5$
- Крит: $15 \times 0.7 + 45 \times 0.15 = 17.25\%$
- Додж: $45 \times 0.2 + 15 \times 0.1 + 3 = 13.5\%$

**Вывод:** Warrior имеет лучший DPS И лучшую выживаемость одновременно. Mage проигрывает по урону (-5%) и имеет вдвое меньше HP. **Warrior доминирует в текущем мете.**

### 2.3 Экономика золота

**Источники дохода (gold/день при активной игре):**

| Источник | Gold/день | Условия |
|----------|-----------|---------|
| PvP (12 боёв, 50% WR) | ~1,500 | 6 побед × 150 + 6 поражений × 50 + level scaling |
| First Win Bonus | +150 | ×2 за первую победу дня |
| Daily Quests (3 + bonus) | ~800 | В зависимости от наград |
| Daily Login (avg) | ~400 | 200-1000 gold в неделю |
| Gold Mine (3 slots) | ~525 | 3 × 175 avg × 1 collect/day |
| Item Sell | ~200 | Продажа дропа |
| Win Streak (+20-100%) | ~200 | При удачных сериях |
| **ИТОГО** | **~3,775** | **Активный игрок** |

**Основные расходы (gold sinks):**

| Расход | Стоимость | Частота |
|--------|-----------|---------|
| Апгрейд +1→+5 | 100-500 gold | Всегда успех |
| Апгрейд +6 | 600 gold (80% шанс) | Может фейлить |
| Апгрейд +7 | 700 gold (60% шанс) | Часто фейлит |
| Апгрейд +8 | 800 gold (40% шанс) | Обычно фейлит |
| Апгрейд +9 | 900 gold (25% шанс) | Почти всегда фейлит |
| Апгрейд +10 | 1,000 gold (15% шанс) | Лотерея |
| Покупка предмета в магазине | 400-12,000+ | Rarity × Level × 4 |
| Learn Skill | 200 gold | Разовая |
| Upgrade Skill | 500 + 500/rank | Линейная |
| Inventory Expansion | 5,000 gold | Max 3 раза |

**Ожидаемая стоимость апгрейда +10:**

Для одного предмета с +0 до +10:

$$E[cost] = \sum_{i=0}^{4} (i+1) \times 100 + \sum_{i=5}^{9} \frac{(i+1) \times 100}{P_i}$$

Где $P_i$ — шанс успеха:

| Уровень | Стоимость попытки | Шанс | Ожидаемые попытки | Ожидаемая стоимость |
|---------|-------------------|------|-------------------|-------------------|
| +1→+5 | 100-500 | 100% | 1 каждый | 1,500 |
| +6 | 600 | 80% | 1.25 | 750 |
| +7 | 700 | 60% | 1.67 | 1,167 |
| +8 | 800 | 40% | 2.5 | 2,000 |
| +9 | 900 | 25% | 4 | 3,600 |
| +10 | 1,000 | 15% | 6.67 | 6,667 |
| **ИТОГО** | | | | **15,684 gold** |

А у персонажа **12 слотов экипировки**. Полный апгрейд всего: $15,684 \times 12 \approx 188,000$ gold. При доходе ~3,775 gold/день — это **~50 дней** только на апгрейды (без покупок нового снаряжения).

**Вывод:** Апгрейд — мощный gold sink, но он "взрывной" (большие суммы за RNG), а не "текучий" (маленькие регулярные траты). После полного апгрейда gold начинает накапливаться без цели.

### 2.4 Стамина

**Параметры:**
- Максимум: 120
- Реген: 1 point / 8 минут = 7.5 в час
- Полное восстановление: $120 \div 7.5 = 16$ часов
- Рефил за гемы: 30 gems

**Расход стамины:**

| Активность | Стоимость | Боёв из полной стамины |
|------------|-----------|----------------------|
| PvP | 10 | 12 |
| Dungeon Easy | 15 | 8 |
| Dungeon Normal | 20 | 6 |
| Dungeon Hard | 25 | 4-5 |
| Boss | 40 | 3 |
| Training | 5 | 24 |

**Free PvP:** 3 бесплатных боёв в день (без стамины).

**Анализ:**
- Игрок входит утром с 120 стамины, делает 3 free PvP + 12 paid PvP = 15 боёв
- К обеду стамина кончается. До вечера восстанавливается ~45 стамины = ещё 4 боя
- Итого: **~19 PvP боёв/день** максимум (при чистом PvP фокусе)
- Если чередует с данжами: ~12 PvP + 2-3 данжа

**Проблема:** Сессия длится 10-15 минут (PvP бой ≈ 30-60 секунд × 15 боёв). После этого — стена. Для мобильной RPG целевая сессия 2-5 минут ок, но **отсутствует механизм "ещё один бой"** кроме gem-рефила.

### 2.5 ELO и Матчмейкинг

**Параметры:**
- K-фактор: 48 (калибровка, первые 10 игр), 32 (обычный)
- Стартовый рейтинг: не указан в коде (вероятно ~1000)
- Ранги: Bronze (0), Silver (1200), Gold (1500), Platinum (1800), Diamond (2100), Grandmaster (2400)

**Анализ ELO-сдвигов:**

При $K = 32$ и равных рейтингах ($E = 0.5$):
- Победа: $+32 \times (1 - 0.5) = +16$ рейтинга
- Поражение: $-16$ рейтинга

При победе над +200 рейтинга противником:
- $E = \frac{1}{1 + 10^{200/400}} = 0.24$
- Победа: $+32 \times 0.76 = +24$

**Проблема ранговой системы:**
- От Bronze (0) до Silver (1200): нужно $\frac{1200}{16} = 75$ нетто-побед при 50% WR = теоретически бесконечно (random walk)
- При 55% WR: нетто +1.6 ELO за бой → $\frac{1200}{1.6} = 750$ игр
- **750 игр × 10 стамины = 7,500 стамины ÷ 120/день ≈ 39 дней** только до Silver (при 19 боях/день)

Это слишком медленно — **39 дней** при 55% WR. При 52% WR (более реалистично): +0.64 ELO/game → 1,875 игр → ~99 дней. Ранговая прогрессия будет ощущаться как стагнация.

### 2.6 Лут и предметы

**Drop chances:**
- PvP: 15%, Training: 5%
- Dungeon: Easy 20%, Normal 30%, Hard 40%, Boss 75%
- LUK бонус: +0.3% за очко LUK, кап 95%

**Rarity distribution:** Common 50%, Uncommon 30%, Rare 15%, Epic 4%, Legendary 1%

**Level-based rarity bonus:** +0.2% за уровень, распределение: Rare 40%, Epic 35%, Legendary 25% от бонуса

На уровне 50: бонус = $49 \times 0.2 = 9.8\%$
- Common: $\max(50 - 9.8, 10) = 40.2\%$
- Rare: $15 + 9.8 \times 0.4 = 18.9\%$
- Epic: $4 + 9.8 \times 0.35 = 7.4\%$
- Legendary: $1 + 9.8 \times 0.25 = 3.5\%$

**Ожидаемые дропы за день (19 PvP при 15% шанс):** $19 \times 0.15 = 2.85$ предмета/день

**Ожидание легендарки:** $\frac{1}{2.85 \times 0.01} = 35$ дней на уровне 1, $\frac{1}{2.85 \times 0.035} = 10$ дней на уровне 50.

### 2.7 Gold Mine

- 3 слота, 4 часа каждый, reward 100-250 gold (avg 175)
- Gem drop: 10% шанс, 1-3 гема за сбор
- Максимум при идеальном тайминге (6 сборов/день на слот): $3 \times 6 \times 175 = 3,150$ gold/день
- Реалистичный доход (1-2 сбора/день): ~525-1,050 gold/день

### 2.8 Daily Login

| День | Награда | Gold-эквивалент |
|------|---------|----------------|
| 1 | 200 gold | 200 |
| 2 | 1× Stamina Potion (small) | ~150 |
| 3 | 500 gold | 500 |
| 4 | 2× Stamina Potion (small) | ~300 |
| 5 | 1,000 gold | 1,000 |
| 6 | 1× Stamina Potion (large) | ~300 |
| 7 | 5 gems | ~250 |
| **Неделя** | | **~2,700** |

### 2.9 Battle Pass

- XP за PvP: 20, за данж-этаж: 30, за квест: 50, за ачивку: 100
- XP на уровень: $100 + Level \times 50$ (Level 1 = 150 XP, Level 30 = 1,600 XP)
- Premium: 500 gems ($\approx \$5)

---

## 3. Критические проблемы

### 🔴 CP-1: Warrior превосходит все классы

**Проблема:** Warrior имеет высший raw DPS ($STR \times 1.5$) И может вкладывать в выживаемость (VIT/END для HP/Armor). Mage с $INT \times 1.2 + WIS \times 0.5$ наносит меньше урона при том же количестве stat points, а его Magic Resist бесполезен в матчапах против Warrior/Rogue/Tank.

**Импакт:** Мета сколлапсирует в "все играют Warrior". Остальные классы — sub-optimal choice.

**Метрика:** При одинаковых stat points Warrior имеет на **~5-15% больше DPS** чем Mage при вдвое большем HP.

### 🔴 CP-2: XP-кривая ломает late-game прогрессию

**Проблема:** $XP(L) = 100L + 20L^2$ — квадратичная. Экспоненциальные XP-кривые ($XP = base \times mult^L$) более стандартны и создают ощущение "каждый уровень примерно одинаковый по времени" с учётом растущих наград. Текущая квадратичная кривая в сочетании с фиксированными XP-наградами создаёт проблему: время на уровень растёт **линейно** (а не логарифмически).

**Данные:**
- Level 10→11: ~30 побед (5 дней)
- Level 30→31: ~186 побед (31 день)
- Level 49→50: ~459 побед (76.5 дней)

### 🔴 CP-3: Апгрейд +8/+9/+10 — чистый гэмблинг без safety net

**Проблема:** Шансы 40%/25%/15% с линейной стоимостью и **возможным даунгрейдом** выше порога (threshold = +5). Нет системы pity, нет накопления шанса, нет гарантии. Игрок может потерять 10,000+ gold и остаться на +7.

**Импакт:** Frustration → churn. Это не "сложная задача", это рулетка. Игрок не может улучшить свои шансы через мастерство.

**Ожидаемая стоимость +9→+10:** 6,667 gold = ~2 дня фарма. При фейле + даунгрейде до +8 — ещё 2 дня на восстановление. Потенциально **4-6 дней** на одну +10 попытку с recovery.

### 🔴 CP-4: Gold обесценивается в mid-late game

**Проблема:** После полного апгрейда экипировки (~50 дней) единственные gold sinks — покупка новых предметов (редко нужны) и skill upgrades (конечный ресурс). Gold накапливается без применения.

**Признак проблемы:** Игрок с 50,000+ gold и нечего покупать — теряет мотивацию фармить.

### 🔴 CP-5: Стамина-гейт слишком жёсткий для engaged игроков

**Проблема:** 120 стамины = 12 PvP боёв = ~8 минут геймплея. Полный реген 16 часов. Gem refill (30 gems ≈ $0.30) даёт жалкие 120 стамины — ещё 8 минут.

**Импакт:** Engaged игроки, готовые платить временем, ограничены. Whales могут рефилить, но cost-per-minute плохой. Казуалы — ок, но hardcore-аудитория уйдёт.

---

## 4. Серьёзные дисбалансы

### 🟡 SP-1: CHA — бесполезный стат

CHA даёт +1% gold bonus и intimidation (-0.15% вражеского урона за очко, кап 15%). При 100 CHA = +100% gold и -15% урона. Но 100 очков в CHA вместо STR/AGI — это -150 единиц базового урона. **Gold-бонус не компенсирует потерю в бою.**

### 🟡 SP-2: LUK слишком слабый для крита

LUK даёт +0.7% крита за очко. 50 LUK = 35% крита (хорошо). Но те же 50 очков в STR дадут +75 постоянного урона. Крит ×1.5 при 35% = avg +17.5% урона. 50 STR = +75/132 = +57% урона. **STR выгоднее в 3 раза.**

### 🟡 SP-3: Poison damage type нуждается в буффе

Rogue auto-attack = poison, который пробивает только 30% армора. Physical пробивает 0% (но через формулу $100/(100+armor)$). При 50 армора: physical = 67% damage, poison = 74% damage. Разница всего 7%. Poison должен давать что-то ещё (DoT? stack?).

### 🟡 SP-4: Данж-система не описана балансно

Drop chances для данжей (20-75%) хорошие, но нет данных о: enemy scaling, rewards per floor, difficulty curve, boss mechanics. Без этого невозможно оценить данж-экономику.

### 🟡 SP-5: Shell Game / Tavern не интегрированы в прогрессию

Мини-игры упомянуты, но не привязаны к core loop. Они должны давать уникальные награды или бонусы, иначе игроки их проигнорируют.

### 🟡 SP-6: Prestige — reset на уровень 1 слишком болезненный

+5% ко всем статам за prestige — слабо. Игрок теряет доступ к high-level контенту и должен перефармить 50 уровней. Мотивация: получить +5%? Это ~4-8 очков к каждому стату. **Цена не соответствует награде.**

### 🟡 SP-7: Battle Pass XP progression слишком медленная

BP XP per PvP = 20. XP на уровень 30 = $100 + 30 \times 50 = 1,600$. Для level 30 нужно $\sum_{i=1}^{30}(100 + 50i) = 3000 + 23,250 = 26,250$ BP XP. При 20 XP/PvP = 1,313 PvP матчей. При 19 боях/день = **69 дней**. Сезон обычно 90 дней — тайминг ок, но только если игрок играет КАЖДЫЙ день.

### 🟡 SP-8: Daily Login Day 7 — всего 5 gems

5 gems = ~$0.05. Это не "большая награда за 7-дневную серию", это оскорбление. Day 7 должен быть wow-момент: гарантированный Epic+ предмет, 50 gems, или exclusive cosmetic.

---

## 5. Рекомендации по изменениям

### R-1: Ребаланс классов (Critical)

**Mage:**
- Увеличить $INT$ мультипликатор с 1.2 до 1.4
- Добавить unique mechanic: "Arcane Penetration" — магический урон игнорирует 20% Magic Resist
- Добавить scaling: $WIS \times 0.7$ (с 0.5)

**Rogue:**
- Увеличить Crit multiplier для Rogue с 1.5× до 1.8× (class-specific)
- Poison auto-attacks: добавить 3-turn DoT equal to 15% hit damage

**Tank:**
- Добавить "Thorns" mechanic: отражает 10% получаемого урона обратно
- Tank damage reduction: 85% → 82% (buff)

### R-2: Flatten XP curve (Critical)

Заменить $XP(L) = 100L + 20L^2$ на:

$$XP(L) = 100 + 80 \times (L-1) + 5 \times (L-1)^{1.5}$$

Это даёт:
- Level 1→2: 100 (быстро!)
- Level 10→11: 862 (вместо 3,320 — в 4 раза быстрее)
- Level 30→31: 2,814 (вместо 19,320 — в 7 раз быстрее)
- Level 49→50: 4,862 (вместо 53,020 — в 11 раз быстрее)

И одновременно увеличить XP rewards на уровне:

$$XP_{reward}(L) = base \times (1 + 0.03 \times (L-1))$$

Это даёт scaling +3% за уровень (вместо +2%), компенсируя рост XP-требований.

### R-3: Upgrade Pity System (Critical)

Ввести **Forge Luck** — скрытый счётчик неудач:

$$chance_{effective} = chance_{base} + forge\_luck \times 5\%$$

Каждый фейл увеличивает forge_luck на 1. Успех сбрасывает до 0.

Пример для +10 (base 15%): после 5 фейлов шанс = 15% + 25% = 40%.

**Гарантия:** максимум 17 попыток для +10 (при forge_luck = 17 → 15% + 85% = 100%).

### R-4: Recurring gold sinks (Critical)

Добавить:
1. **Equipment Repair** — снаряжение деградирует на 5% durability за бой. Ремонт = $level \times rarity\_mult \times 10$ gold. (~100-500 gold/день)
2. **Stat Respec** — сброс stat points за 2,000 gold (сейчас только passive respec за gems)
3. **Re-roll Shop** — обновить ассортимент магазина за 500 gold
4. **Guild Donations** — вносить gold в казну гильдии для collective buffs
5. **Enchanting** — добавить socket gems к экипировке, removable за gold

### R-5: Stamina reform (Critical)

**Вариант A — Увеличить базу:**
- MAX: 120 → 200
- PvP cost: 10 → 8
- Результат: 25 PvP боёв из полного бака (~15 минут)

**Вариант B — Overflow system:**
- Стамина продолжает регенить до 200% (240), но дневной кап на активности = 30 PvP
- Игрок может накопить стамину и "слить" за длинную сессию

**Вариант C (рекомендуемый) — Hybrid:**
- Stamina MAX: 160
- Реген: 1/6 min (вместо 1/8 min) = 10/час
- Полный реген: 16 часов (не меняется)
- PvP cost: 8
- Free PvP: 5/день (вместо 3)
- Результат: 25 PvP = ~15 минут, + 5 free = 30 total

### R-6: CHA rework

Текущий CHA: +1% gold, -0.15% enemy damage.

**Новый CHA:**
- +1.5% gold bonus (buff)
- -0.2% enemy damage (buff, кап 20%)
- **NEW:** +0.5% XP bonus per CHA point
- **NEW:** +1% shop discount per 5 CHA points (кап 20%)

Это делает CHA "efficiency stat" — не сильнее в бою, но быстрее прогрессирует и экономит.

### R-7: Prestige rewards buff

Текущий: +5% all stats per prestige.

**Новый:**
- +5% all stats (оставить)
- +1 passive point per prestige level
- +500 starting gold per prestige
- Exclusive prestige cosmetic (portrait frame, name color)
- Prestige shop — items buyable only with prestige tokens
- **First prestige:** unlock 6th daily quest slot

### R-8: Daily Login Day 7 overhaul

| День | Текущая награда | Рекомендация |
|------|----------------|-------------|
| 1 | 200 gold | 300 gold |
| 2 | 1× Stamina Potion | 1× Stamina Potion + 100 gold |
| 3 | 500 gold | 500 gold |
| 4 | 2× Stamina Potion | 2× Stamina Potion + 200 gold |
| 5 | 1,000 gold | 1,000 gold + 5 gems |
| 6 | 1× Large Stamina | Rare Equipment Chest |
| 7 | 5 gems | **25 gems + Epic Equipment Chest** |

### R-9: Win Streak protection

Текущие стрики: 3-win +20%, 5-win +50%, 8-win +100%.

Добавить **Loss Streak Protection:**
- 3 поражения подряд: +30% gold за следующую победу
- 5 поражений: +50% gold + guaranteed loot drop
- 7 поражений: matchmaking soft-caps (ищет ±100 рейтинга, не ±200)

### R-10: ELO Rank acceleration

Проблема: слишком медленная ранговая прогрессия.

**Решение — Rank Floors + Bonus ELO:**
- Нельзя упасть ниже ранга (Silver floor = 1200, Gold floor = 1500)
- Первые 3 PvP дня: $K = 48$ (как калибровка), потом 32
- Weekly rank quest: "Win 10 PvP this week" → +100 bonus rating
- Это сокращает путь до Silver с ~63 дней до ~20-25 дней

### R-11: Battle Pass catch-up mechanic

Если игрок пропустил неделю, BP XP за квесты ×2 на следующую неделю. Это предотвращает "я слишком позади, нет смысла покупать premium".

### R-12: Мini-game integration

Shell Game / Tavern должны давать:
- Shell Game: Gold + chance at upgrade materials
- Tavern quests: Unique "Tavern Quests" с повышенными наградами
- Weekly tournament mini-game с leaderboard и gem prizes

---

## 6. Улучшенная модель экономики

### 6.1 Income Model (рекомендуемая)

| Источник | Текущий | Рекомендуемый | Изменение |
|----------|---------|---------------|-----------|
| PvP (per day) | ~1,500 | ~2,200 | +47% (больше боёв, level scaling +3%) |
| Daily Quests | ~800 | ~1,000 | +25% |
| Daily Login (avg) | ~385 | ~550 | +43% |
| Gold Mine | ~525 | ~700 | +33% (buff rewards) |
| Item Sell | ~200 | ~300 | +50% (buff sell prices) |
| Win Streak | ~200 | ~300 | Stable |
| **ИТОГО** | **~3,610** | **~5,050** | **+40%** |

### 6.2 Expense Model (рекомендуемая)

| Расход | Текущий/день | Рекомендуемый/день | Notes |
|--------|-------------|-------------------|-------|
| Upgrades | ~500 (если активно) | ~500 | Без изменений |
| Equipment Repair | 0 | ~400 | **NEW sink** |
| Shop Refresh | 0 | ~250 | **NEW sink** |
| Skill Upgrades | ~100 | ~200 | Buff skill trees |
| Random purchases | ~200 | ~300 | More items to buy |
| **ИТОГО sinks** | **~800** | **~1,650** | **+106%** |

### 6.3 Net daily gold

| | Текущий | Рекомендуемый |
|---|---------|---------------|
| Income | 3,610 | 5,050 |
| Expenses | 800 | 1,650 |
| **Net** | **+2,810** | **+3,400** |
| Days to 50k | 18 дней | 15 дней |

**Ключевое отличие:** в рекомендуемой модели gold постоянно тратится (repair, refresh, skills), поэтому не накапливается "мёртвым грузом". Игрок всегда чувствует "мне нужно ещё gold".

### 6.4 Gem Economy

| Источник gems | Кол-во/неделю |
|---------------|--------------|
| Daily Login Day 5 | 5 |
| Daily Login Day 7 | 25 (buff) |
| Gold Mine drops | ~3 |
| BP Free rewards | ~5-10 |
| Achievements | ~10-20 (one-time) |
| **Итого F2P** | **~38-43/неделю** |

| Gem sink | Стоимость |
|----------|-----------|
| Stamina Refill | 30 gems |
| BP Premium | 500 gems |
| Passive Respec | 50 gems |
| Gold Mine Slot | 50 gems |
| Upgrade Protection | 30 gems |
| Extra PvP | 50 gems |

F2P игрок может купить BP Premium за ~12 недель F2P gems. Это нормальный таймлайн (1 BP per season).

---

## 7. Улучшенная модель прогрессии

### 7.1 Milestones Timeline (рекомендуемая)

| Milestone | Текущий | Рекомендуемый | Target experience |
|-----------|---------|---------------|-------------------|
| Level 10 | ~5 дней | ~3 дня | "Ого, я уже 10!" |
| Level 25 | ~25 дней | ~14 дней | Mid-game unlock |
| Level 50 | ~120+ дней | ~45 дней | Achievement, prestige available |
| Full +5 gear | ~10 дней | ~8 дней | "I'm getting strong" |
| First +10 item | ~20 дней | ~15 дней | Major achievement |
| Silver Rank | ~63 дня | ~20 дней | "I'm competitive!" |
| Gold Rank | ~120+ дней | ~40 дней | Hardcore milestone |
| First Prestige | ~150+ дней | ~50 дней | Veteran status |

### 7.2 Power Curve

С новой XP-кривой, stat points, и экипировкой:

**Неделя 1 (Level 1-8):**
- 24 stat points вложено
- Common/Uncommon gear +0…+3
- Power feel: "I'm learning, getting stronger every session"

**Неделя 2-3 (Level 8-18):**
- 54 stat points
- Rare gear появляется, +5 на ключевых слотах
- Power feel: "I can build my character MY way"

**Неделя 4-6 (Level 18-30):**
- 90 stat points
- Epic gear, +7-8 на weapon
- Unlocked most skills, building passive tree
- Power feel: "I have a build, it works, I'm competitive"

**Месяц 2-3 (Level 30-45):**
- 135 stat points
- Legendary gear hunting begins
- +10 goals, prestige planning
- Power feel: "I'm optimizing, min-maxing, dominating"

**Месяц 3+ (Level 45-50 + Prestige):**
- Full build, prestige cycle begins
- Endgame: ranking, competitive PvP, guild wars
- Power feel: "I'm a veteran, this is MY game"

### 7.3 Emotional Arc по сессиям

```
Session 1:  "Wow, easy to understand" → Level up! → "Cool, more stats!"
Session 2:  First PvP win → Gold → Buy first item → "I'm stronger!"
Session 3:  Lose a fight → "I need better gear" → Upgrade → Win!
Session 5:  Rank up to Silver → "I'm competitive!" → Set new goals
Session 10: First Epic drop → "JACKPOT!" → Upgrade to +7
Session 20: Build specialization → "My Rogue is unique" → Guild content
Session 50: Prestige decision → "New beginning with bonus" → Fresh start
```

---

## 8. Стратегия удержания и мотивации

### 8.1 Daily Hooks (причины заходить каждый день)

| Hook | Текущий | Рекомендуемый |
|------|---------|---------------|
| Daily Login | ✅ Есть | Buff Day 7 rewards |
| Daily Quests | ✅ Есть | Add 6th quest for prestige |
| Free PvP | ✅ 3/day | Buff to 5/day |
| Gold Mine | ✅ Collect | Add notification push |
| First Win Bonus | ✅ ×2 gold/XP | Add visual celebration |
| **NEW: Daily Dungeon** | ❌ | 1 free dungeon/day with bonus loot |
| **NEW: Mystery Merchant** | ❌ | Random daily deal (1 item, 50% off) |

### 8.2 Weekly Hooks

| Hook | Текущий | Рекомендуемый |
|------|---------|---------------|
| Battle Pass Tiers | ✅ Slow | Add catch-up mechanic |
| Weekly Login Streak | ✅ Day 7 gems | Buff to 25 gems + chest |
| **NEW: Weekly Boss** | ❌ | Co-op boss, unique drops |
| **NEW: Arena Tournament** | ❌ | Weekend tourney, gem prizes |
| **NEW: Rank Decay** | ❌ | Lose 50 rating/week if inactive (floor protected) |

### 8.3 Monthly/Seasonal Hooks

| Hook | Текущий | Рекомендуемый |
|------|---------|---------------|
| Battle Pass Season | ✅ Есть | Add 10 bonus levels post-50 |
| Achievements | ✅ 21 total | Expand to 40+ |
| **NEW: Seasonal Event** | ❌ | Time-limited dungeon, exclusive rewards |
| **NEW: Prestige Race** | ❌ | First-to-prestige leaderboard |

### 8.4 Anti-frustration mechanics

1. **Loss streak protection** (R-9) — soft matchmaking + bonus gold
2. **Upgrade pity** (R-3) — guarantee cap at 17 attempts
3. **Rank floors** (R-10) — never drop below earned rank
4. **Stamina overflow** — stockpile for longer sessions
5. **Mercy timer on legendary drops** — if no legendary in 30 days, next rare drop becomes legendary
6. **"Try Again" toast** on failed upgrade shows current forge luck progress

### 8.5 Monetization touchpoints (non-blocking)

| Момент | Offer |
|--------|-------|
| Stamina ends | "Refill for 30 gems?" + "Or watch ad for 20 stamina" |
| Upgrade fails 3× | "Protection scroll (30 gems) prevents downgrade" |
| Epic+ drop | "Double it for 50 gems?" |
| Rank promotion | "Celebrate with rank frame (150 gems)" |
| Daily streak Day 7 | "Premium bundle: 100 gems + 5,000 gold ($2.99)" |

---

## 9. Next Steps — Приоритезированный план

### Phase 1: Quick Wins (1 неделя)

1. ⬜ Buff Mage INT multiplier: 1.2 → 1.4
2. ⬜ Buff Daily Login Day 7: 5 → 25 gems
3. ⬜ Free PvP per day: 3 → 5
4. ⬜ Add loss streak protection (soft matchmaking)
5. ⬜ Buff CHA gold bonus: 1% → 1.5%

### Phase 2: Core Fixes (2-3 недели)

6. ⬜ New XP curve: flatten late-game
7. ⬜ Upgrade pity system (Forge Luck)
8. ⬜ Equipment durability/repair gold sink
9. ⬜ Shop refresh mechanic
10. ⬜ Rank floors (can't drop below rank threshold)

### Phase 3: Retention Systems (3-4 недели)

11. ⬜ Prestige rewards overhaul
12. ⬜ Battle Pass catch-up mechanic
13. ⬜ Weekly boss / tournament
14. ⬜ Mystery Merchant daily deal
15. ⬜ Shell Game integration

### Phase 4: Long-term (1-2 месяца)

16. ⬜ Class rebalance (Rogue DoT, Tank thorns)
17. ⬜ Guild system economy
18. ⬜ Seasonal events framework
19. ⬜ Advanced matchmaking (win-rate + power-level factors)
20. ⬜ Economy monitoring dashboard (track inflation, gear saturation)

---

## Appendix A: Формулы (справочник)

**XP to level:** $XP(L) = 100L + 20L^2$

**Proposed XP:** $XP(L) = 100 + 80(L-1) + 5(L-1)^{1.5}$

**Damage (Warrior):** $DMG = STR \times 1.5 + Level \times 2$

**Armor reduction:** $DMG_{final} = DMG_{raw} \times \frac{100}{100 + Armor}$

**Crit chance:** $\min(LUK \times 0.7 + AGI \times 0.15 + stance,\ 50\%)$

**Dodge chance:** $\min(AGI \times 0.2 + LUK \times 0.1 + class + stance,\ 30\%)$

**ELO change:** $\Delta R = K \times (S - E)$ где $E = \frac{1}{1 + 10^{(R_{opp} - R_{self})/400}}$

**Expected upgrade cost (+0 → +10):** $\approx 15,684$ gold

**Gold per day (active F2P):** $\approx 3,775$ gold

**HP formula:** $HP = 80 + VIT \times 5 + END \times 3$

**Sell price:** $rarity\_base \times item\_level$

**Buy price:** $sell\_price \times 4$

## Appendix B: Рекомендуемые A/B тесты

1. **XP curve variants** — текущая vs. предложенная vs. промежуточная. Метрика: D7 retention, average level at D30
2. **Stamina 120 vs 160 vs 200** — Метрика: sessions/day, revenue per user
3. **Upgrade pity ON vs OFF** — Метрика: upgrade gold spent, D14 retention
4. **Free PvP 3 vs 5 vs 7** — Метрика: engagement time, stamina refill purchases
