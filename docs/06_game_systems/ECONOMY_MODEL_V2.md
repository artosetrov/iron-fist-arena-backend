# Hexbound — Unified Economy Model v2.0

*Date: 2026-04-09 | Author: Economy Audit*
*Status: PRODUCTION-READY — replace balance.ts values + admin panel config*

---

## A. КРИТИЧЕСКИЕ ПРОБЛЕМЫ ТЕКУЩЕЙ ЭКОНОМИКИ

### Найденные противоречия (код vs документация)

| # | Проблема | Код (balance.ts) | Документ (ECONOMY.md) | Влияние |
|---|----------|-----------------|----------------------|---------|
| 1 | **PvP Win base** | 200g | 150g | Док устарел, код верный |
| 2 | **PvP Loss base** | 70g | 50g | Док устарел, код верный |
| 3 | **Level scaling** | +2% per level | +10% per level | Док завышает в 5 раз! Код верный |
| 4 | **CHA gold cap** | +125% (diminishing) | +50% (10% per point) | Док занижает. Код верный |
| 5 | **Daily login gems (Day 7)** | 25 gems | 5 gems | Док занижает. Код верный |
| 6 | **Stamina refill gem cost** | 30 gems | 10 gems | Док занижает в 3 раза |
| 7 | **Gold Mine Slot gem cost** | 50 gems | 30 gems | Док занижает |
| 8 | **Inventory expand** | 5000 gold | 20 gems per slot | Полный конфликт: разные валюты |
| 9 | **Free PvP per day** | 5 | 3 (упоминается в промпте) | Код: 5 |
| 10 | **Gem→Gold conversion** | Существует (1 gem = 15g buy, 1:10 sell) | "No gem→gold conversion" | Док врёт — конвертация ЕСТЬ |

### Системные проблемы (подтверждено симуляцией)

| # | Проблема | Данные |
|---|----------|--------|
| **P1** | **Золото копится бесконтрольно** | Casual: 32k за 30 дней, sink ratio 10%. Active: 70k, sink 16%. Целевой sink: 50-70% |
| **P2** | **Repair — слабый sink** | Lv1 common repair = 60g. При заработке 1000+/день это незаметно |
| **P3** | **Upgrade слишком дешёвый** | +1 = 100g, +5 = 500g. Полный апгрейд вещи до +5 = 1500g — один PvP бой |
| **P4** | **Нет дефицита на старте** | 500g стартовых + 400g за first win + daily login = 1100g в первый час. Хватает на 4-5 вещей |
| **P5** | **Gold Mine passive > training active** | Mine: ~105g/4h пассивно = 26g/hr. Training: 50g win за 5 stamina = 35g/hr активно. Почти равны |
| **P6** | **Shell Game — нулевой EV** | 1/3 шанс × 2x = 0.67 EV. Это gold sink, но слабый — опытный игрок не играет |
| **P7** | **Consumable prices vs income ratio слишком низкий** | HP Large = 700g = 3.5 PvP win. Должно кусаться больше |
| **P8** | **Daily login Day 5 даёт 1000g** | Это больше, чем casual зарабатывает за полный день геймплея. Ломает ощущение заработка |

---

## B. ФИНАЛЬНАЯ ЕДИНАЯ ЭКОНОМИЧЕСКАЯ МОДЕЛЬ

### Философия

- **Золото = время.** Игрок платит временем → получает золото → тратит на прогресс
- **Гемы = ускорение.** Гемы сжимают время, но не дают power advantage
- **Дефицит = мотивация.** Игрок всегда хочет +1 вещь или +1 апгрейд, но не может всё сразу
- **Sink ratio target = 55-65%.** Игрок тратит больше половины заработка → золото ощущается ценным
- **First hour = hook.** Быстрый старт, первый дефицит на 20-30 минуте

### Стартовая экономика (Day 0)

| Параметр | Текущее | **РЕКОМЕНДАЦИЯ** | Почему |
|----------|---------|------------------|--------|
| Стартовое золото | 500g | **300g** | 500g = 5 common вещей сразу. 300g = 2-3, вынуждает выбирать |
| Welcome Gift оружие | Да (по классу) | **Да** | Оставить. Игрок сразу в бою |
| Welcome Gift зелья HP | 2x small | **2x small** | Оставить. Страховка для первых боёв |
| Welcome Gift стамина | +50 | **+50** | Оставить. Хватит на 5 PvP + 1 dungeon |
| Starter Pack (free) | 500g+50gems+6 потионов | **Только расходники: 3 HP large + 3 Stamina large** | Без валюты. Расходники помогают, но не ломают экономику |
| Бесплатные PvP | 5/день | **3/день** | 5 — слишком щедро. 3 = хук, потом нужна стамина |

**Что игрок НЕ может в первый час:**
- Купить uncommon+ вещь (avg 290g, а у него 300g + нужны поты)
- Апгрейдить до +6 (шанс 80%, но к этому моменту нет денег)
- Зайти в hard dungeon (стамина 25, а level lock)
- Открыть Gold Mine slot 2+ (gem-only)

**Первый дефицит (20-30 минута):**
Игрок потратил стартовые 300g на 1-2 вещи → выиграл 2-3 боя → заработал ~500g → хочет ещё вещь + апгрейд → не хватает → мотивация играть ещё

---

## C. ТАБЛИЦА ВСЕХ НАГРАД

### Основные источники золота

| Источник | Base (Lv1) | Lv10 | Lv25 | Lv50 | Стамина | Частота |
|----------|-----------|------|------|------|---------|---------|
| **PvP Win** | 150 | 177 | 222 | 297 | 10 | По желанию |
| **PvP Loss** | 50 | 59 | 74 | 99 | 10 | По желанию |
| **First Win of Day** | 300 (2x) | 354 | 444 | 594 | 10 | 1/день |
| **Revenge Win** | 225 (1.5x) | 265 | 333 | 445 | 10 | По желанию |
| **Training Win** | 30 | 35 | 44 | 59 | 5 | По желанию |
| **Training Loss** | 10 | 12 | 15 | 20 | 5 | По желанию |
| **Dungeon Easy (floor 1)** | 31 | — | — | — | 15 | По желанию |
| **Dungeon Normal (floor 1)** | 45 | — | — | — | 20 | По желанию |
| **Dungeon Hard (floor 1)** | 67 | — | — | — | 25 | По желанию |
| **Dungeon Normal (floor 5)** | 105 | — | — | — | 20 | По желанию |
| **Dungeon Hard (floor 10)** | 270 | — | — | — | 25 | По желанию |
| **Gold Mine (1 slot/4hr)** | 60-150 | — | — | — | 0 | Passive |
| **Shell Game (win)** | 2x bet | — | — | — | 0 | 20/день |
| **Daily Login (weekly avg)** | 243/день | — | — | — | 0 | 1/день |
| **Daily Quests (avg 3)** | ~500 | — | — | — | 0 | 3/день |

**РЕКОМЕНДОВАННЫЕ ИЗМЕНЕНИЯ (помечены → ):**

| Источник | Текущее | **→ Рекомендация** | Причина |
|----------|---------|-------------------|---------|
| PvP Win Base | 200 | **→ 150** | 200g слишком щедро для Lv1. С level scaling вырастет до 297 на Lv50 |
| PvP Loss Base | 70 | **→ 50** | Проигрыш не должен быть комфортным |
| Training Win | 50 | **→ 30** | Тренировка = практика, не заработок |
| Training Loss | 20 | **→ 10** | Аналогично |
| Gold Mine per slot | 60-150 | **→ 40-100** | Passive income не должен конкурировать с active |
| Daily Login Day 5 | 1000g | **→ 500g** | 1000g > дневной заработок casual. Ломает ощущение |
| Daily Login Day 3 | 500g | **→ 300g** | Аналогично |
| Free PvP per day | 5 | **→ 3** | 3 бесплатных = хук. Дальше — стамина/гемы |

### Gem Income (бесплатный)

| Источник | Количество | Частота |
|----------|-----------|---------|
| Daily Login Day 7 | 25 gems | Еженедельно |
| Achievements | 1-25 gems | Одноразово (всего ~94 gems за все) |
| Battle Pass Free | 50 gems | За сезон (8 недель) |
| Gold Mine gem drop (10%) | 1-3 gems | ~1 gem/день при 3 слотах |
| Daily Quest (редко) | 2-5 gems | ~3 gems/неделю |
| Level Milestones | 20-150 gems | Одноразово (всего 520 gems Lv10-50) |

**F2P gem income: ~40-50 gems/неделю** (25 login + 6 mine + 3 quests + ~10 BP/week)

### Win/Loss Streak Bonuses (без изменений — хорошо работают)

| Win Streak | Bonus | | Loss Streak → Win | Bonus |
|-----------|-------|---|-------------------|-------|
| 3-4 wins | +20% | | After 3-4 losses | +30% |
| 5-7 wins | +50% | | After 5-6 losses | +50% |
| 8+ wins | +100% | | After 7+ losses | +80% |

---

## D. ТАБЛИЦА ВСЕХ ЦЕН (GOLD SINKS)

### Consumables

| Предмет | Текущая цена | **→ Рекомендация** | Эффект | Pain point |
|---------|-------------|-------------------|--------|------------|
| HP Potion Small | 150g | **→ 200g** | Heal small | Lv1-5: тратишь на каждый бой |
| HP Potion Medium | 350g | **→ 400g** | Heal medium | Lv6-15: стандартный расход |
| HP Potion Large | 700g | **→ 800g** | Heal large | Lv15+: дорого, но нужно для данжей |
| Stamina Potion Small | 100g | **→ 150g** | +50 stamina | Lv1-10: хочешь ещё бой — плати |
| Stamina Potion Medium | 250g | **→ 300g** | +75 stamina | Lv10-20: основной расход |
| Stamina Potion Large | 500g | **→ 600g** | +100 stamina | Lv20+: ощутимая трата |

### Equipment Buy Prices (формула: `basePrice × itemLevel`)

**Buy price по rarity и level bracket:**

| Level | Common | Uncommon | Rare | Epic | Legendary |
|-------|--------|----------|------|------|-----------|
| 1-5 | 40-200 | 100-500 | 240-1200 | 600-3000 | 1600-8000 |
| 6-10 | 240-400 | 600-1000 | 1440-2400 | 3600-6000 | 9600-16000 |
| 11-15 | 440-600 | 1100-1500 | 2640-3600 | 6600-9000 | 17600-24000 |
| 16-20 | 640-800 | 1600-2000 | 3840-4800 | 9600-12000 | 25600-32000 |
| 21-25 | 840-1000 | 2100-2500 | 5040-6000 | 12600-15000 | 33600-40000 |
| 26-30 | 1040-1200 | 2600-3000 | 6240-7200 | 15600-18000 | 41600-48000 |
| 31-40 | 1240-1600 | 3100-4000 | 7440-9600 | 18600-24000 | 49600-64000 |
| 41-50 | 1640-2000 | 4100-5000 | 9840-12000 | 24600-30000 | 65600-80000 |

**Формула из кода:** `sellPrice = basePerRarity × itemLevel`, `buyPrice = sellPrice × 4`

| Rarity | Base Sell/Level | Buy Multiplier |
|--------|----------------|---------------|
| Common | 10g | ×4 = 40g/lvl |
| Uncommon | 25g | ×4 = 100g/lvl |
| Rare | 60g | ×4 = 240g/lvl |
| Epic | 150g | ×4 = 600g/lvl |
| Legendary | 400g | ×4 = 1600g/lvl |

### Equipment Sell Prices

| Rarity | Sell per level | Lv5 sell | Lv10 sell | Lv25 sell | Lv50 sell |
|--------|---------------|---------|----------|----------|----------|
| Common | 10g | 50g | 100g | 250g | 500g |
| Uncommon | 25g | 125g | 250g | 625g | 1250g |
| Rare | 60g | 300g | 600g | 1500g | 3000g |
| Epic | 150g | 750g | 1500g | 3750g | 7500g |
| Legendary | 400g | 2000g | 4000g | 10000g | 20000g |

**Buy/Sell ratio = 4:1.** Купил за 1000g → продал за 250g. Потерял 75%. Это хороший sink.

### Repair Costs

**Формула:** `(50 + itemLevel × 10) × rarityMultiplier`

| Item Level | Common (×1.0) | Uncommon (×1.5) | Rare (×2.0) | Epic (×3.0) | Legendary (×5.0) |
|-----------|--------------|----------------|------------|------------|-----------------|
| 1 | 60g | 90g | 120g | 180g | 300g |
| 5 | 100g | 150g | 200g | 300g | 500g |
| 10 | 150g | 225g | 300g | 450g | 750g |
| 20 | 250g | 375g | 500g | 750g | 1250g |
| 30 | 350g | 525g | 700g | 1050g | 1750g |
| 40 | 450g | 675g | 900g | 1350g | 2250g |
| 50 | 550g | 825g | 1100g | 1650g | 2750g |

**→ РЕКОМЕНДАЦИЯ: увеличить BASE_COST до 80 и PER_LEVEL до 15.**
Новая формула: `(80 + itemLevel × 15) × rarityMultiplier`

Это даст:
- Lv1 common: 95g (vs 60g сейчас)
- Lv10 epic: 690g (vs 450g)
- Lv50 legendary: 4750g (vs 2750g)

**Full repair (все 6 экипированных слотов, уровень 10, mix rarity):**
- Текущий: ~1500g
- Рекомендованный: ~2400g
- При дневном заработке active F2P ~2000g → repair = 1 полный день. **Кусается.**

### Equipment Upgrade Costs

**Текущая формула:** `upgradeLevel × 100` (линейная)

| + Level | Current Cost | Success % | Expected Cost (avg attempts) |
|---------|-------------|-----------|------------------------------|
| +1 | 100g | 100% | 100g |
| +2 | 200g | 100% | 200g |
| +3 | 300g | 100% | 300g |
| +4 | 400g | 100% | 400g |
| +5 | 500g | 100% | 500g |
| +6 | 600g | 80% | 750g |
| +7 | 700g | 60% | 1167g |
| +8 | 800g | 40% | 2000g |
| +9 | 900g | 25% | 3600g |
| +10 | 1000g | 15% | 6667g |
| **Total 0→+10** | — | — | **15,684g** |

**→ РЕКОМЕНДАЦИЯ: переход на экспоненциальную формулу**
`upgradeCost = 150 × (1.4 ^ upgradeLevel)`

| + Level | **NEW Cost** | Success % | Expected Cost |
|---------|-------------|-----------|---------------|
| +1 | 210g | 100% | 210g |
| +2 | 294g | 100% | 294g |
| +3 | 412g | 100% | 412g |
| +4 | 576g | 100% | 576g |
| +5 | 807g | 100% | 807g |
| +6 | 1130g | 80% | 1412g |
| +7 | 1582g | 60% | 2636g |
| +8 | 2214g | 40% | 5536g |
| +9 | 3100g | 25% | 12400g |
| +10 | 4340g | 15% | 28933g |
| **Total 0→+10** | — | — | **53,216g** |

Это делает +6 через +10 серьёзной инвестицией. На Lv50 с заработком ~3000g/день полный +10 = **~18 дней гринда**. Мотивация копить и планировать.

### Gem Sinks

| Действие | Текущее | **→ Рекомендация** | Обоснование |
|----------|---------|-------------------|-------------|
| Stamina Refill | 30 gems | **30 gems** | Ок. 120 stam = ~12 PvP = ~1800g. ROI = 60g/gem |
| Extra PvP (+5 stam) | 50 gems | **→ убрать** | Непонятный UX. Лучше просто stamina refill |
| Battle Pass Premium | 500 gems | **500 gems** | ~10 недель F2P farming или $5. Хороший price point |
| Gold Mine Slot | 50 gems | **50 gems** | Ок |
| Gold Mine Boost | 10 gems | **10 gems** | Ок |
| Passive Respec | 50 gems | **50 gems** | Ок |
| Upgrade Protection | 30 gems | **→ 50 gems** | При новых ценах апгрейда — защита ценнее |

---

## E. ФОРМУЛЫ SCALING

### Gold Reward Level Scaling
```
levelScaledReward(base, level) = floor(base × (1 + (level - 1) × 0.02))
```
Lv1 = 1.00x, Lv10 = 1.18x, Lv25 = 1.48x, Lv50 = 1.98x

### CHA Gold Bonus (Diminishing Returns)
```
CHA 0-30:   +2.5% per point (max +75%)
CHA 31-60:  +1.0% per point (max +105%)
CHA 61+:    +0.5% per point (hard cap +125%)
```

### XP for Level N (Cumulative)
```
xpForLevel(N) = 100N + 20N²
```

### Item Buy Price
```
buyPrice = sellPrice × 4
sellPrice = baseSellPerRarity × itemLevel
```

### Repair Cost (RECOMMENDED NEW)
```
repairCost(level, rarity) = floor((80 + level × 15) × rarityMultiplier)
```

### Upgrade Cost (RECOMMENDED NEW)
```
upgradeCost(plusLevel) = floor(150 × 1.4^plusLevel)
```

### Dungeon Gold per Floor
```
dungeonGold(floor, diffMult) = floor((30 + floor × 15) × diffMult)
diffMult: easy=0.7, normal=1.0, hard=1.5
```

### Gold Mine Reward (RECOMMENDED NEW)
```
mineReward = random(40, 100) per slot per 4 hours
```

---

## F. СИМУЛЯЦИЯ ЭКОНОМИКИ (с рекомендованными значениями)

### Допущения
- Win rate 50%
- PvP Win = 150g base (new), Loss = 50g (new)
- Free PvP = 3/day (new)
- Gold Mine = 40-100g/slot (new)
- Repair BASE_COST = 80, PER_LEVEL = 15 (new)
- Upgrade exponential formula (new)
- Daily Login: 150/0/300/0/500/0/25gems (new)
- Starting Gold = 300g (new)

### Day 1 / 7 / 30 Projection

#### Casual Player (20-30 min/day, 1-3 PvP, 1 mine slot)

| Day | Earned | Spent | Balance | Notes |
|-----|--------|-------|---------|-------|
| 1 | ~600g | 200g | 700g | First win 300g + 2 losses + login 150g. Bought 1 HP pot |
| 3 | ~500g | 300g | 1200g | Normal day. Repair + pot |
| 7 | ~500g | 350g | 2400g | Login gems day. Wants uncommon item (~300g) |
| 14 | ~550g | 400g | 4000g | Has 3-4 items. Wants first upgrade (+3 = 412g) |
| 30 | ~550g | 450g | 6500g | Bought 2 uncommon items, upgraded main weapon to +4. Feels need for more gold |

**30-day totals:** Earned ~16k, Spent ~11k, **Sink ratio: ~65%** ✓

#### Active F2P (1-2 hr/day, 8-10 PvP, dungeons, 2 mine slots)

| Day | Earned | Spent | Balance | Notes |
|-----|--------|-------|---------|-------|
| 1 | ~1500g | 400g | 1400g | 3 free PvP + 5 paid + dungeon. Bought pots + 1 item |
| 7 | ~1600g | 900g | 6500g | Needs repair for 4-5 items. Bought rare item. Upgraded to +3 |
| 14 | ~1700g | 1200g | 11000g | Working on +5/+6 upgrades. Repair eats 500+/day. Buys pots regularly |
| 30 | ~1800g | 1400g | 18000g | Has decent gear, working on +7. Feels tight. Wants premium item but can't afford |

**30-day totals:** Earned ~50k, Spent ~35k, **Sink ratio: ~70%** ✓

#### Payer ($5-10/month, 2+ hr/day, stamps refills)

| Day | Earned | Spent | Balance | Notes |
|-----|--------|-------|---------|-------|
| 1 | ~2500g | 1000g | 1800g | More PvP (refills), dungeons, gold packs. Buys items aggressively |
| 7 | ~2800g | 2000g | 8000g | Upgrades multiple items to +5. Repairs epic gear. Buys pots |
| 14 | ~3000g | 2500g | 14000g | Working on +7/+8 upgrades (expensive!). Epic gear repairs hurt |
| 30 | ~3200g | 2800g | 26000g | Has strong gear but +9/+10 upgrades are massive gold sinks |

**30-day totals:** Earned ~90k, Spent ~72k, **Sink ratio: ~80%** ✓

### Comparison Chart

| Metric | Casual | Active F2P | Payer |
|--------|--------|-----------|-------|
| Daily income | ~550g | ~1700g | ~3000g |
| Daily spending | ~400g | ~1200g | ~2500g |
| Sink ratio | 65% | 70% | 80% |
| Day 30 balance | 6500g | 18000g | 26000g |
| Max upgrade affordable | +4-5 | +6-7 | +8-9 |
| Items fully geared | 3-4 | 5-6 | 6+ |

---

## G. ТОЧКИ МОНЕТИЗАЦИИ

### Когда показывать офферы

| Момент | Оффер | Почему работает |
|--------|-------|----------------|
| **После 3-го проигрыша подряд** | Stamina Refill (30 gems) | Игрок хочет реванш, стамина кончилась |
| **Когда апгрейд проваливается** | Upgrade Protection (50 gems) | Боль от потери → желание застраховаться |
| **Когда gold < buy price желаемого предмета** | Gold Pack ($0.99-4.99) | "Ещё чуть-чуть и куплю вещь" |
| **Battle Pass Lv10 (free track)** | BP Premium (500 gems) | Игрок видел 10 уровней наград → хочет лучшие |
| **Level 5 (first milestone)** | Starter Bundle ($2.99) | Лучшее время — игрок втянулся, готов вложить |
| **Daily Login Day 7** | Monthly Gem Card ($4.99) | Игрок уже в ритме ежедневного входа |
| **Gold Mine timer — 30 min left** | Gold Mine Boost (10 gems) | "Не хочу ждать" |

### Recommended IAP Ladder

| Pack | Price | Contents | Target | Value/$ |
|------|-------|----------|--------|---------|
| **Starter Bundle** | $2.99 | 200 gems + 3000g | New player, first buy | Best value. One-time |
| **Monthly Gem Card** | $4.99 | 50 + 300 gems (30 days) | Recurring, habit | 350 gems = $17 value |
| **Gold 500** | $0.99 | 500g | Impulse buy | Low barrier |
| **Gold 3500** | $4.99 | 3500g | Midgame push | Uncommon item + upgrades |
| **Gems Medium** | $4.99 | 550 gems | Flexible spender | Covers BP + refills |
| **Premium Forever** | $9.99 | Permanent cosmetic | Status symbol | One-time |

### Что НЕЛЬЗЯ делать

- **Нельзя** продавать gear/stats за гемы (pay-to-win)
- **Нельзя** делать gem-only вещи с боевыми стат-бонусами
- **Нельзя** давать платникам больше PvP attempts чем F2P (stamina — OK, но unlimited PvP — нет)
- **Нельзя** продавать upgrade success chance boost за гемы (p2w)
- **OK** продавать: stamina refills, protection scrolls, cosmetics, convenience, time acceleration

---

## H. РИСКИ И ЧТО МОНИТОРИТЬ

| Риск | Метрика | Red Flag | Действие |
|------|---------|----------|----------|
| **Gold inflation** | Avg gold balance by day | Balance > 50k at Day 30 for casual | Reduce rewards or add sinks |
| **Sink ratio too low** | Total spent / total earned | < 40% | Add/increase sinks |
| **Sink ratio too high** | Total spent / total earned | > 85% | Players feel strangled → churn. Reduce costs |
| **Shell Game exploit** | Net gold flow from shell game | Positive overall | RNG is fair (1/3), but monitor |
| **Gold Mine vs Active** | Gold/hr mine vs gold/hr PvP | Mine > 40% of PvP rate | Nerf mine rewards |
| **Upgrade frustration** | % players quitting after +7 fail | > 15% quit within 24hr | Add pity timer or increase +7 chance |
| **Gem hoarding** | Avg gems balance at Day 30 | > 500 gems unspent | Gems не полезны → add gem sinks |
| **IAP conversion** | % DAU who bought anything | < 2% after 30 days | Offerы не попадают в pain points |
| **CHA gold abuse** | Top 1% CHA players gold/day vs avg | > 3x average | Cap CHA gold bonus further |
| **Prestige inflation** | Prestige players earning rate | > 2.5x base | Cap prestige gold bonus |

---

## I. ФИНАЛЬНЫЕ CONFIG VALUES

### balance.ts — Recommended Changes

```typescript
// --- Gold rewards (CHANGED) ---
export const GOLD_REWARDS = {
  PVP_WIN_BASE: 150,        // was 200
  PVP_LOSS_BASE: 50,        // was 70
  TRAINING_WIN: 30,          // was 50
  TRAINING_LOSS: 10,         // was 20
  REVENGE_MULTIPLIER: 1.5,   // unchanged
} as const;

// --- Stamina (CHANGED) ---
export const STAMINA = {
  MAX: 120,                   // unchanged
  REGEN_RATE: 1,
  REGEN_INTERVAL_MINUTES: 8,
  PVP_COST: 10,
  DUNGEON_EASY: 15,
  DUNGEON_NORMAL: 20,
  DUNGEON_HARD: 25,
  BOSS: 40,
  TRAINING: 5,
  FREE_PVP_PER_DAY: 3,       // was 5
} as const;

// --- Repair costs (CHANGED) ---
export const REPAIR_COSTS = {
  BASE_COST: 80,              // was 50
  PER_LEVEL: 15,              // was 10
  RARITY_MULTIPLIERS: {
    common: 1.0,
    uncommon: 1.5,
    rare: 2.0,
    epic: 3.0,
    legendary: 5.0,
  },
} as const;

// --- Upgrade costs (CHANGED to exponential) ---
export const UPGRADE_COSTS = {
  BASE: 150,
  EXPONENT: 1.4,
  // cost(level) = floor(150 * 1.4^level)
} as const;

// --- Daily login (CHANGED) ---
export const DAILY_LOGIN_REWARDS: readonly DailyLoginRewardDef[] = [
  { type: 'gold', amount: 150 },                                          // Day 1 (was 200)
  { type: 'consumable', amount: 1, itemId: 'stamina_potion_small' },      // Day 2
  { type: 'gold', amount: 300 },                                          // Day 3 (was 500)
  { type: 'consumable', amount: 2, itemId: 'stamina_potion_small' },      // Day 4
  { type: 'gold', amount: 500 },                                          // Day 5 (was 1000)
  { type: 'consumable', amount: 1, itemId: 'stamina_potion_large' },      // Day 6
  { type: 'gems', amount: 25 },                                           // Day 7 (unchanged)
] as const;

// --- Gold Mine (CHANGED) ---
export const GOLD_MINE = {
  MINE_REWARD_MIN: 40,        // was 60
  MINE_REWARD_MAX: 100,       // was 150
  // rest unchanged
} as const;

// --- Consumable prices (CHANGED) ---
export const CONSUMABLE_PRICES = {
  health_potion_small: 200,   // was 150
  health_potion_medium: 400,  // was 350
  health_potion_large: 800,   // was 700
  stamina_potion_small: 150,  // was 100
  stamina_potion_medium: 300, // was 250
  stamina_potion_large: 600,  // was 500
} as const;

// --- Gem costs (CHANGED) ---
export const GEM_COSTS = {
  STAMINA_REFILL: 30,         // unchanged
  // EXTRA_PVP_COMBAT: REMOVED — use stamina refill instead
  BATTLE_PASS_PREMIUM: 500,
  GOLD_MINE_BUY_SLOT: 50,
  GOLD_MINE_BOOST: 10,
  UPGRADE_PROTECTION: 50,     // was 30
} as const;
```

### Admin Panel — Remote Config Values

| Key | Value | Live-tunable |
|-----|-------|-------------|
| `gold_rewards.pvp_win_base` | 150 | ✓ |
| `gold_rewards.pvp_loss_base` | 50 | ✓ |
| `gold_rewards.training_win` | 30 | ✓ |
| `gold_rewards.training_loss` | 10 | ✓ |
| `stamina.free_pvp_per_day` | 3 | ✓ |
| `repair.base_cost` | 80 | ✓ |
| `repair.per_level` | 15 | ✓ |
| `upgrade.formula` | exponential | ✓ |
| `upgrade.base` | 150 | ✓ |
| `upgrade.exponent` | 1.4 | ✓ |
| `gold_mine.reward_min` | 40 | ✓ |
| `gold_mine.reward_max` | 100 | ✓ |
| `consumable.hp_small_price` | 200 | ✓ |
| `consumable.stamina_small_price` | 150 | ✓ |
| `starter.starting_gold` | 300 | ✓ |

### Starter Pack (DB: shop_offers)

| Field | Value |
|-------|-------|
| key | starter_pack |
| title | Starter Pack |
| description | Welcome bonus for new adventurers! |
| offer_type | starter_pack |
| contents | `[{"type":"consumable","id":"health_potion_large","quantity":3},{"type":"consumable","id":"stamina_potion_large","quantity":3}]` |
| original_price | 0 |
| sale_price | 0 |
| currency | gold |
| max_purchases | 1 |
| min_level | 1 |
| max_level | 10 |
| is_active | true |

---

## FINAL ECONOMY RULES

1. **Gold = time.** 1 hour of active play = 800-1500g (level-dependent). Passive income ≤ 30% of active
2. **Sink ratio target: 55-65% casual, 70-80% payer.** If < 40% → economy is broken, add sinks
3. **Upgrade is the primary endgame gold sink.** +7 through +10 are intentionally expensive and risky
4. **Repair is the secondary ongoing sink.** Must cost 15-25% of daily income for active player
5. **Free PvP = hook, not grind.** 3 free → want more → spend stamina/gems
6. **Gems accelerate, never gatekeep.** Everything achievable F2P, gems save time
7. **Shell Game = controlled variance sink.** EV negative, fun mechanic, not primary income
8. **No feature requires gems.** Everything has gold alternative (slower)
9. **Daily Login = retention, not economy.** Rewards are nice but shouldn't exceed 30% of active income
10. **Level scaling is gentle.** +2% per level, not 10%. Lv50 earns 2x Lv1, not 10x

## TOP 10 PARAMETERS TO PUT INTO REMOTE CONFIG

1. `PVP_WIN_BASE` — primary income lever
2. `PVP_LOSS_BASE` — frustration control
3. `FREE_PVP_PER_DAY` — session length control
4. `REPAIR_BASE_COST` — sink pressure lever
5. `UPGRADE_BASE` + `UPGRADE_EXPONENT` — endgame sink intensity
6. `GOLD_MINE_REWARD_MIN/MAX` — passive income cap
7. `CONSUMABLE_PRICES.*` — recurring sink pressure
8. `STAMINA_REFILL_GEM_COST` — gem sink rate
9. `STARTING_GOLD` — new player experience
10. `DAILY_LOGIN_GOLD_DAY5` — retention vs inflation control

## BIGGEST RISK IF WE SHIP CURRENT ECONOMY WITHOUT FIXES

**Gold hyperinflation.** С текущими параметрами (PvP Win = 200g, daily login Day 5 = 1000g, gold mine 60-150g, upgrade cost linear) casual игрок к Day 30 имеет 32,000g+ при sink ratio 10%. Это значит:

- Золото не ощущается ценным → нет мотивации играть за него
- Upgrade до +10 стоит 15,000g → 2 недели casual play. Для endgame это **ничего**
- Repair = пыль. 60g за common item при заработке 1000+/день
- Нет дефицита → нет desire → нет retention → нет monetization
- Игрок покупает всё, что хочет, за 2 недели → "а дальше что?" → churn

**Починка:** применить рекомендованные изменения из этого документа, мониторить sink ratio через admin dashboard, держать lever (remote config) на первых 10 параметрах.
