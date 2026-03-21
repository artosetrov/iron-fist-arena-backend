# HEXBOUND — Motion, Juice & Game Feel Audit v1.0

> **Роль:** Senior Game UX/UI Director + Monetization Designer + Motion Designer
> **Дата:** 2026-03-20
> **Скоуп:** 26 экранов, дизайн-система, motion framework, retention UX, monetization flows
> **Платформа:** iOS SwiftUI, Portrait, Dark Fantasy Premium
> **Цель:** Превратить функциональный UI в top-grossing-tier game feel без потери readability

---

## 1. EXECUTIVE SUMMARY

### Где интерфейс уже сильный

Hexbound имеет зрелую дизайн-систему: 60+ цветовых токенов, 18 стилей кнопок, rarity glow system, skeleton loading, 7 типов тостов, VFX-подсистема для боя. CityMapView — отличный иммерсивный хаб. Тематическая целостность Dark Fantasy выдержана на ~80% экранов. Компонентная библиотека (panelCard, GoldDivider, TabSwitcher, HPBarView, StaminaBarView) — это серьёзный фундамент.

### Где интерфейс слишком статичный

Проблема Hexbound — **функциональная корректность без эмоциональной отдачи**. Экраны правильные, но «мёртвые». Конкретно:

- **Hub** — карточка персонажа, банеры, floating icons — всё статично. Нет idle-движения, нет «живого» мира. Персонаж не дышит, город не мерцает.
- **Arena** — карточки оппонентов появляются без анимации. FIGHT-кнопка не пульсирует, не зовёт. Переход в бой — 0.5–2 сек пустоты.
- **Combat Result** — самый эмоциональный момент игры (победа/поражение) подаётся как информационный экран. Нет celebration, нет dramatic reveal.
- **Loot** — предметы показываются сразу, без anticipation. Legendary drop выглядит так же, как common, только с другой рамкой.
- **Shop** — покупка = toast. Нет анимации приобретения, нет «предмет летит в инвентарь».
- **Battle Pass / Achievements / Daily Login** — claim-моменты без satisfying feedback. Нажал — получил. Без burst, без звука, без celebration.
- **Inventory / Equipment** — equip = instant swap. Нет визуальной «установки» предмета.

### Где не хватает эмоции, anticipation, payoff

- **Pre-combat anticipation** — от нажатия FIGHT до начала боя: тишина. Нужен dramatic build-up.
- **Reward reveal** — все награды показываются мгновенно. Нет suspense, нет поэтапного раскрытия.
- **Level up** — LevelUpModalView существует, но без wow-момента: нет числового countdown, нет particle explosion.
- **Rating change** — число появляется, но нет анимации подъёма/падения по рейтинговой шкале.
- **Win streak** — нигде визуально не отмечается как горящая серия.
- **First win of the day** — 2x бонус виден только как множитель, без special presentation.

### Где есть риск перегруза или «cheap casino feel»

- CityMapEffects уже добавляет ambient particles — хорошо, но это единственное место с VFX вне боя. Если добавить particles везде — станет визуальный шум.
- Shop/ShellGame/GoldMine — это зоны, где «casino UI» может легко выйти из-под контроля. Shimmer на кнопках покупки, мигающие цены, countdown timers — всё это fast track к дешёвому F2P feel.
- Modal cascade при входе (DailyLogin + LevelUp + Quest) — уже сейчас borderline aggressive.

**Ключевой принцип:** Hexbound — dark fantasy combat game, не казино. Juice должен усиливать ощущение могущества, опасности и награды, а не создавать FOMO-тревогу.

---

## 2. SCREEN-BY-SCREEN AUDIT

### 2.1 — Splash Screen

**Цель:** Создать первое впечатление, проверить auth, перевести в игру.

**Текущее UX:** Анимированный логотип с glow, золотой progress indicator, auto-login. Это уже хорошо.

**Что статично:**
- Progress indicator — линейный, без характера. Просто полоска.

**Рекомендации:**
- Добавить subtle particle dust вокруг логотипа (золотые искры, медленный drift). Duration: бесконечный цикл, 20-30 частиц, opacity 0.3–0.6.
- Progress bar → segmented with glow pulse на leading edge. Easing: `easeInOut`, 0.8s per segment.
- При успешном auto-login: логотип делает subtle scale pulse (1.0 → 1.05 → 1.0, 0.3s) перед transition.
- При ошибке/timeout (>3s): fade-in «Connecting...» text с subtle breathing opacity (0.5 → 1.0, 1.2s loop).

**Нельзя перегружать:** Splash должен быть быстрым. Если auto-login <1s — не задерживать ради анимации.

**Priority:** Medium | **Dev Complexity:** Low

---

### 2.2 — Login / Guest / Register

**Цель:** Быстрый вход в игру. Минимум friction.

**Текущее UX:** Форма с email/password, social auth кнопки, guest option.

**Что статично:**
- Форма появляется мгновенно, без входной анимации.
- Кнопки не реагируют на tap кроме scalePress.

**Рекомендации:**
- Фоновые элементы: subtle dark particle field (как на splash, но тише). Создаёт «живой» фон.
- Form fields: staggered fade-in снизу вверх. Delay: 0.05s между полями, duration 0.3s, easing `easeOut`.
- Login button при заполнении формы: gold shimmer проходит по кнопке слева направо (1 раз, 0.6s). Сигнал «готово к действию».
- Error state: shake animation на форме (±8px, 3 цикла, 0.4s total). Haptic: `.notification(.error)`.
- Success login: кнопка → green flash (0.2s) → transition.

**Нельзя перегружать:** Это утилитарный экран. Не добавлять декоративных VFX. Фокус на speed и clarity.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.3 — Onboarding (Character Creation)

**Цель:** Создать эмоциональную привязку к персонажу за 60–90 секунд.

**Текущее UX:** 4-шаговый wizard (Name → Class → Origin → Appearance). Монолитный код, вне дизайн-системы.

**Что статично:**
- Переходы между шагами — instant, без анимации.
- Выбор класса/расы — карточки не реагируют на hover/selection с WOW-эффектом.
- Нет visual build-up к финальному персонажу.

**Рекомендации:**
- **Step transitions:** Горизонтальный slide (current → left, new → from right). Duration: 0.35s, easing `easeInOut`. Progress dots сверху с заполняющейся gold линией.
- **Class selection:** При тапе на класс — карточка scale up (1.0 → 1.08, 0.2s), gold border fade-in, class-color glow pulse за карточкой. Остальные карточки — dim (opacity 0.5, 0.2s).
- **Origin selection:** Аналогично, но с subtle отличием — accent color меняется на origin-specific.
- **Name input:** При вводе валидного имени — subtle gold underline glow. При невалидном — red shake.
- **Final step — Character Summary:** Самый важный moment. Персонаж «собирается» из выбранных частей: portrait fade-in (0.4s) → name text type-on effect (как печать, 0.03s/char) → class icon slide-in → stats appear с tick-up animation. Финальная кнопка «Create Hero» пульсирует gold glow.
- **Creation confirm:** Screen-wide gold particle burst (50 частиц, 0.8s), haptic `.success`, transition в Hub.

**Нельзя перегружать:** Онбординг должен быть быстрым. Все анимации skippable по тапу. Не добавлять кат-сцены или лор.

**Priority:** High | **Dev Complexity:** Medium

---

### 2.4 — Hub Screen

**Цель:** Центральная точка навигации. Игрок должен за 3 секунды понять: что делать, сколько ресурсов, что нового.

**Текущее UX:** CityMap с зданиями, карточка персонажа, floating buttons, банеры (BattlePass, FirstWin, Quests). StaminaBar.

**Что статично:**
- Карточка персонажа — статичный snapshot. Персонаж не «живой».
- Город — CityMapEffects добавляет particles, но здания не реагируют на ничего.
- Floating icons — висят неподвижно.
- Банеры — появляются без анимации, висят статично.

**Рекомендации:**
- **Character card idle:** Portrait имеет subtle breathing scale (1.0 → 1.01 → 1.0, 3s loop, easeInOut). HP/XP bars — periodic shimmer на filled portion (каждые 5s, 0.6s duration).
- **City buildings:** При availability новых действий — building icon получает subtle bounce (1 раз при входе, 0.3s). Badge (красный dot) для unclaimed rewards.
- **Floating action icons:** При входе — staggered pop-in (scale 0→1, 0.2s each, 0.1s stagger). Иконки с unclaimed content — subtle pulse (scale 1.0→1.05→1.0, 2s loop).
- **Banners:** Slide-in сверху при входе (0.3s, easeOut), staggered. FirstWinBonus banner — gold shimmer loop на border.
- **Stamina bar:** При изменении — animated fill (0.5s, easeOut). При 0 stamina — bar blinks red (0.5s loop), gentle не aggressive.
- **Currency changes:** При получении gold/gems — number tick-up animation (old → new, 0.4s). Иконка валюты делает quick bounce.
- **Notification badges:** Scale-in pop (0→1, spring animation, 0.3s) при появлении новых.
- **CityMap ambient:** Добавить 2–3 firefly-like particles (gold, slow drift, random path), факелы на зданиях с flicker glow.

**Нельзя перегружать:** Hub — это safe space. Не добавлять urgency UI, мигающие CTA, countdown timers. Город должен чувствоваться как «дом», не как рекламный щит.

**Priority:** High | **Dev Complexity:** Medium

---

### 2.5 — Character / Hero Detail

**Цель:** Показать статы, экипировку, прогресс. Дать ощущение роста.

**Текущее UX:** 8 статов, derived stats, equipment slots, stance. Много информации.

**Что статично:**
- Все числа появляются мгновенно.
- Equipment слоты — статичные иконки.
- Stat allocation — клик +/- без feedback.

**Рекомендации:**
- **Stats entry:** При открытии — staggered number count-up (0 → actual value, 0.3s each, 0.05s stagger). Easing: `easeOut`.
- **Stat allocation:** При нажатии «+» — число flash gold (0.15s), stat bar fills с glow pulse. Haptic: `.light`. При нажатии «-» — flash red.
- **Equipment slot tap:** Slot scale press (0.95, 0.1s) + gold border pulse. При equip — item «slides into» slot (0.25s, easeOut), slot flash gold (0.2s), haptic `.medium`.
- **Equipment change comparison:** Зелёные/красные стрелки рядом со статами animate in (fade + slide right, 0.2s).
- **Portrait:** Subtle parallax при scroll (portrait moves slower чем content, 2-3px offset).
- **XP ring (HeroIntegratedCard):** При получении XP — ring animated fill + gold particle trail по кругу.

**Нельзя перегружать:** Это информационный экран. Анимации должны быть subtle и functional, не decorative.

**Priority:** Medium | **Dev Complexity:** Medium

---

### 2.6 — Stance Selector

**Цель:** Выбрать тактическую позицию (attack/defense zones) перед боем.

**Текущее UX:** Выбор зон атаки и защиты. Механика сложная, нигде не объяснённая.

**Что статично:**
- Зоны — тапаешь, выбираешь. Без визуального feedback.

**Рекомендации:**
- **Zone selection:** При тапе — зона подсвечивается class-color glow (0.3s fade-in). Attack zones — pulsing red/orange outline. Defense zones — pulsing blue/green outline.
- **Zone activation:** Scale pulse (1.0→1.05→1.0, 0.2s) + haptic `.selection`.
- **Preview panel:** Показать expected stat modifiers с анимированным +/- рядом с числами (green tick-up / red tick-down).
- **Confirm button:** Когда все зоны выбраны — button fade-in с gold shimmer.
- **First-time tooltip:** Spotlight overlay — highlight одну зону, dim остальное, показать текст «Tap to set attack zone».

**Нельзя перегружать:** Stance — тактический выбор. Анимации должны помогать понять, а не отвлекать.

**Priority:** Medium | **Dev Complexity:** Low

---

### 2.7 — Inventory

**Цель:** Управление предметами. Найти, сравнить, экипировать, продать.

**Текущее UX:** 4-колоночная grid, filter chips, item detail sheet.

**Что статично:**
- Grid появляется мгновенно.
- Нет визуальных индикаторов «этот предмет лучше».
- Equip/sell — мгновенно, без feedback.

**Рекомендации:**
- **Grid entry:** Staggered fade-in (0.02s между items, opacity 0→1, 0.15s each). Начинать сверху-слева.
- **Item rarity ambient:** Legendary items — subtle gold particle shimmer на карточке (3–5 частиц, медленный loop). Epic — purple dim glow pulse (3s loop). Остальные — static.
- **Item tap → sheet:** Spring animation для sheet появления (damping: 0.7, response: 0.3).
- **Equip action:** Item «flies» из sheet в equipment slot (matched geometry, 0.3s). Slot flash gold. Haptic `.medium`. Old item falls back into grid (если есть).
- **Sell action:** Item shrinks → gold coins explode out (5 coin particles, scatter, 0.4s). Gold counter tick-up. Haptic `.light`.
- **New item indicator:** Пульсирующий gold dot в углу карточки (2s loop).
- **Upgrade arrows:** Green ↑ / Red ↓ badges на карточках в grid — scale-in pop при включении comparison mode.

**Нельзя перегружать:** Grid — utility screen. Ambient glow только для Legendary/Epic, не для каждого предмета.

**Priority:** Medium | **Dev Complexity:** Medium

---

### 2.8 — Item Detail Sheet

**Цель:** Показать полную информацию о предмете, сравнить с текущим, принять решение (equip/sell/dismantle).

**Текущее UX:** Sheet с stats, rarity border, action buttons.

**Что статично:**
- Stats появляются мгновенно.
- Comparison (если есть) — static numbers.

**Рекомендации:**
- **Sheet entry:** Content staggered: icon (0s) → name + rarity badge (0.1s) → stats (0.2s) → buttons (0.3s). Duration 0.2s each.
- **Rarity-based presentation:**
  - Common: Clean, minimal, no effects.
  - Uncommon: Subtle green shimmer on border (1 pass).
  - Rare: Blue border glow pulse (2s loop, subtle).
  - Epic: Purple particle mist behind icon (5 частиц).
  - Legendary: Full gold border glow + particle aura + ambient звук (subtle chime on open).
- **Stat comparison:** «Better» stats slide right с green tint. «Worse» — red. Animated, 0.2s.
- **Action buttons:** Primary CTA (Equip) — gold shimmer если предмет лучше текущего.

**Нельзя перегружать:** Sheet — decision point. Rarity effects subtle. Legendary должен чувствоваться special, но не flashy.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.9 — Equipment Screen

**Цель:** Управление снаряжением 10 слотов. Видеть текущий build.

**Текущее UX:** HeroIntegratedCard с equipment grid, portrait, HP/XP bars.

**Что статично:**
- Слоты — static icons.
- Нет визуальной feedback при drag/equip.

**Рекомендации:**
- **Empty slots:** Subtle pulse border (gold dim, 3s loop). Сигнал «заполни меня».
- **Slot tap:** Scale press (0.93) + border flash, haptic `.selection`.
- **Item equip animation:** Item materializes в слоте (scale 0.5→1.0, opacity 0→1, 0.25s). Gold spark burst на слоте (10 частиц, 0.3s).
- **Total power number:** При изменении экипировки — tick-up/tick-down animation (0.4s). Green flash при improvement, red при downgrade.
- **Set bonus activation:** Если будет система сетов — при сборе полного сета, все предметы сета одновременно flash gold + connecting lines между ними (0.5s).

**Priority:** Medium | **Dev Complexity:** Medium

---

### 2.10 — Arena

**Цель:** Выбрать оппонента и начать PvP бой.

**Текущее UX:** Tabs (Opponents/Revenge/History), карточки оппонентов с FIGHT кнопкой, ArenaCarouselView.

**Что статично:**
- Карточки оппонентов — static cards.
- FIGHT button — стандартная кнопка без пульсации.
- Tab switch — мгновенный.
- Revenge tab — нет visual urgency для revenge opportunities.
- Нет stance preview.

**Рекомендации:**
- **Opponent cards entry:** Staggered slide-up (0.1s stagger, 0.25s duration, easeOut). Каждая карточка «вырастает» снизу.
- **FIGHT button:** Idle glow pulse (gold, 2s loop). При hover/long press — intensify glow + subtle vibration haptic. Это ГЛАВНАЯ кнопка всей игры — она должна ЗВАТЬ в бой.
- **FIGHT press:** Scale down (0.92) → release → instant LoadingOverlay с «Preparing battle...» text. Haptic `.heavy`.
- **Revenge cards:** Red/crimson subtle border glow pulse (1.5s loop). Revenge icon bounce (once on appear). Это мотивирует revenge — «этот парень тебя побил».
- **Tab switch:** Content crossfade (0.2s), не instant swap.
- **Difficulty badges (Easy/Medium/Hard):** Color-coded shimmer on load (green/amber/red, single pass).
- **Stance mini-preview:** Добавить compact stance indicator рядом с FIGHT. При тапе — expand to edit.
- **Win streak indicator:** Если streak ≥3, показать fire icon с flame animation рядом с profile. Чем выше streak — больше пламя.
- **Carousel swipe:** Card входит с inertia + settle (spring animation, damping 0.65).

**Нельзя перегружать:** Arena — competitive screen. Не добавлять particles. Glow только на FIGHT и Revenge. Чистота и фокус.

**Priority:** High | **Dev Complexity:** Medium

---

### 2.11 — Combat

**Цель:** Показать автоматический бой, создать excitement и tension.

**Текущее UX:** VFX подсистема (DamageHitEffects, DodgeMissBlock, HealEffect, StatusVFX), combat log, speed controls. Это уже сильная сторона.

**Что статично:**
- Status effects — 3-буквенные коды без визуального representation.
- Combat log — dense text.
- Transition in — 0.5-2s пустоты после FIGHT.

**Рекомендации:**
- **Battle intro sequence:** КРИТИЧЕСКИЙ МОМЕНТ. Экран затемняется (0.3s) → VS screen (player avatar left, opponent right, scale in from edges, 0.4s) → «VS» text slam (scale 2.0→1.0, 0.15s, bounce) → flash white (0.1s) → combat starts. Total: 1.0-1.2s. Haptic: `.heavy` на VS slam. Это создаёт anticipation вместо пустоты.
- **HP bar damage:** При получении урона — bar shake (±3px, 2 cycles, 0.15s) + flash red background (0.1s). Хил — flash green.
- **Critical hit:** Screen border flash red (0.15s) + screen shake (±5px, 3 cycles, 0.2s) + damage number enlarged (1.5x size, gold color, float up). Haptic: `.heavy`.
- **Dodge/Miss:** Dodging character silhouette shift (10px sideways, 0.2s, spring back). «DODGE» text — italic, slide away.
- **Status effects:** Заменить BLD/BRN/STN на colored icons under HP bars. При application — icon pop-in (scale 0→1, 0.15s, spring). При tick (damage from bleed/poison) — icon flash + small particle burst.
- **Kill shot:** Slow-mo effect на последнем ударе (0.3s slow, then normal speed). Defeated character fade to grayscale (0.5s). Winner — brief gold outline pulse.
- **Combat log:** Заменить text lines на visual turn cards: [attacker icon] → [action icon] → [damage number] → [defender reaction]. Scroll horizontally или stacked cards.
- **Speed toggle:** Animated transition between speeds. При 2x — subtle screen filter (slightly warmer). При Skip — fast-forward visual effect (blur lines from center).

**Нельзя перегружать:** Бой уже имеет VFX. Не добавлять больше particles. Фокус на screen feedback (shake, flash, slow-mo) и status clarity.

**Priority:** High | **Dev Complexity:** High

---

### 2.12 — Combat Result

**Цель:** Самый эмоциональный экран. Подать ПОБЕДУ как celebration, ПОРАЖЕНИЕ как мотивацию.

**Текущее UX:** Win/loss summary card с loot. BattleResultCardView. Нет Rematch.

**Что статично:**
- Результат появляется мгновенно — нет build-up.
- Rating change — просто число.
- Rewards — instant display.
- Win/loss ощущаются одинаково по weight.

**Рекомендации:**
- **VICTORY:**
  1. Screen flash gold (0.15s) → «VICTORY» text slam (scale 3.0→1.0, 0.2s, bounce). Haptic: `.success` (triple tap pattern).
  2. VictoryParticlesView — уже есть, включить на full power. Gold confetti burst (50 частиц, 0.8s).
  3. Rating change: Animated counter (+24, tick up from 0, 0.5s). Если rank up — special animation: rank badge scales in + gold burst + «RANK UP!» text. Haptic: `.heavy`.
  4. Gold earned: Coins rain animation (5-10 coins falling, 0.6s) → number tick-up.
  5. XP earned: XP bar animated fill (0.5s). Если level up — interrupt с LevelUpModal.
  6. Loot items: Staggered reveal (one by one, 0.3s each). Legendary item — screen shakes, gold explosion, special sound cue. Common — simple fade-in.
  7. CTAs appear last: «Fight Again» (gold shimmer) + «New Opponent» + «Return to Hub». Staggered (0.15s).
- **DEFEAT:**
  1. Screen tint red (0.3s) → «DEFEAT» text — no slam, somber fade-in (0.4s).
  2. No particles. Muted palette.
  3. Rating loss: Animated counter, red number (-18, tick down, 0.4s). Не aggressive.
  4. Consolation gold: Small coin animation (3 coins, 0.3s).
  5. Revenge CTA: «SEEK REVENGE» button с red glow pulse. Мотивация вернуться.
  6. Loss причина: Brief «Opponent had +30% DEF advantage» — helps player learn.

**Нельзя перегружать:** Victory — celebration, но не 10-секундная. Всё skippable по тапу. Defeat — не depressing, а motivating.

**Priority:** High (самый высокий ROI на perception) | **Dev Complexity:** Medium

---

### 2.13 — Loot Screen

**Цель:** Показать полученные предметы. Создать anticipation и excitement.

**Текущее UX:** Item reveal с rarity styling, Take All. «В целом хорошо» (из UX аудита).

**Что статично:**
- Все предметы видны сразу.
- Legendary и Common выглядят почти одинаково.

**Рекомендации:**
- **Loot anticipation:** Вместо instant reveal — chest/bag animation opening (0.5s), затем предметы «выпадают» по одному.
- **Rarity-gated reveal:**
  - Common: Simple fade-in (0.15s). Без эффектов.
  - Uncommon: Fade-in + green border flash.
  - Rare: Blue beam of light (0.3s) + card flip animation.
  - Epic: Purple vortex spiral (0.4s) + card materializes + screen dim.
  - Legendary: FULL CEREMONY — screen darkens → gold light beam from top → item descends (0.6s) → lands → gold explosion (30 частиц) → screen flash → item card appears with animated border. Haptic: `.heavy` sustained. Sound cue: chime + reverb. Это МОМЕНТ. Игрок должен сделать скриншот.
- **Take All:** Items fly towards bottom (converge animation, 0.3s) → «Added to inventory» toast.
- **Comparison badge:** «↑ Better than equipped» / «↓ Worse» — appears after reveal, animated.

**Нельзя перегружать:** Ceremony ТОЛЬКО для Epic и Legendary. Common/Uncommon — fast. Иначе 10 items = 10 animations = player rage.

**Priority:** High | **Dev Complexity:** Medium

---

### 2.14 — Dungeon Select

**Цель:** Выбрать подземелье и сложность. Понять, что получишь.

**Текущее UX:** Dungeon cards, difficulty tabs, progress bars. «В целом хорошо».

**Что статично:**
- Dungeon карточки — static images.
- Difficulty switch — instant.

**Рекомендации:**
- **Dungeon cards:** Subtle parallax при scroll (background shifts 2-3px). Cards have dim glow в цвете сложности.
- **Difficulty tabs:** Animated color transition (0.2s crossfade).
- **Locked dungeons:** Lock icon has subtle jiggle on tap (3 cycles, 0.2s) + tooltip «Reach Level X».
- **Reward preview:** Gold/XP numbers tick-up при switch difficulty (0.3s).
- **Enter dungeon:** Transition — screen wipe (dark fog sweeping left to right, 0.5s) → dungeon room loads.

**Нельзя перегружать:** Этот экран — utility. Не добавлять сложных анимаций.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.15 — Dungeon Room

**Цель:** Проходить этажи, бить монстров, собирать лут.

**Текущее UX:** Room view, boss fight, loot. Progress dots.

**Что статично:**
- Room transitions — instant.
- Progress indicators маленькие.

**Рекомендации:**
- **Room transition:** Slide transition (current room → left, new room → from right, 0.35s). Progress bar animated fill.
- **Boss encounter:** Boss portrait dramatic entrance (scale up from center, 0.5s, with dark vignette). «BOSS FIGHT» text slam. Haptic `.heavy`.
- **Floor counter:** «Floor X/10» с animated progression. При boss floor — text turns gold + pulse.
- **Room clear:** Brief «CLEARED» stamp animation (rubber stamp feel, 0.2s, slight rotation settle).

**Priority:** Medium | **Dev Complexity:** Low

---

### 2.16 — Shop

**Цель:** Продать предметы, привлечь к покупке. Monetization без давления.

**Текущее UX:** Equipment/Consumables/Premium tabs, ShopItemCardView, ShopOfferBannerView.

**Что статично:**
- Items — static grid.
- Purchase — toast only.
- Offer banners — static.

**Рекомендации:**
- **Merchant character:** MerchantStripView — добавить idle animation (subtle sway, blink, 3-5s loop). Merchant «живой».
- **Daily deal banner:** Subtle gold border shimmer (loop). НЕ мигающий, не aggressive. Один проход shimmer каждые 5 секунд.
- **Flash sale timer:** Countdown с tick-animation последних 10 минут. Число мигает при <1 час. Haptic на 5-min warning если app open.
- **Purchase flow:**
  1. Tap Buy → confirmation sheet (spring animation, 0.3s).
  2. Confirm → кнопка shrinks → gold burst → item flies to «My Items» area. Haptic: `.success`.
  3. Gold counter tick-down (animated).
- **Premium tab:** Items с premium badge имеют subtle shimmer. НЕ over-the-top.
- **Gem purchase:** При покупке gems — gems rain animation (like coins but blue). Number tick-up. Haptic `.medium`.
- **Insufficient funds:** Button disabled + subtle red tint. При тапе — shake + «Not enough gold. Need X more.»

**Нельзя перегружать:** Shop — САМАЯ ОПАСНАЯ зона для «casino feel». Никаких мигающих prices, никаких rotating banners, никаких «limited time ONLY 5 LEFT». Один shimmer на deal banner — максимум.

**Priority:** Medium | **Dev Complexity:** Medium

---

### 2.17 — Battle Pass

**Цель:** Показать progression, мотивировать играть, конвертировать в premium.

**Текущее UX:** Free/Premium tracks, BPRewardNodeView. Сейчас с mock данными.

**Что статично:**
- Nodes — static.
- XP progress — static bar.
- Claim — instant.

**Рекомендации:**
- **Track visualization:** Animated path — gold line «рисуется» от начала до текущего уровня при открытии (0.5s). Unclaimed nodes — pulse gold.
- **Node claim:** Tap claimed node → reward pops out (scale 0→1, spring, 0.3s) → flies to inventory. Gold burst on node. Haptic `.medium`.
- **Level up in pass:** Track extends animation. New node «unlocks» — lock icon shatters (particle fragments, 0.3s).
- **Premium upgrade CTA:** Soft gold border на premium track. НЕ popup, не modal, не blocking. Только visual difference between tracks.
- **Season countdown:** «X days remaining» — при <7 дней text turns amber. При <3 дней — red. Без мигания, без FOMO-pressure.
- **XP bar:** Animated fill при получении XP. Glow pulse on leading edge.

**Нельзя перегружать:** Battle Pass — НЕ казино. Не добавлять lootbox-style reveals. Progression должна быть visible и honest.

**Priority:** Medium | **Dev Complexity:** Medium

---

### 2.18 — Achievements

**Цель:** Показать прогресс, дать claim satisfaction.

**Текущее UX:** Category tabs, progress bars, AchievementCardView с состояниями (locked, in-progress, claimable, claimed). «Compliant».

**Что статично:**
- Progress bars — static fill.
- Claim — instant swap state.

**Рекомендации:**
- **Claimable achievements:** Card glow pulse gold (2s loop). «CLAIM» badge bounce (once on appear).
- **Claim action:** Button → gold burst (20 частиц) → reward flies to currency counter → card state transition (checkmark stamp, 0.2s). Haptic `.success`.
- **Progress bar fill:** Animated при обновлении данных (0.3s, easeOut).
- **Category badge count:** При claim — number decrement с fade animation.
- **Milestone achievements (50 wins, etc.):** Enhanced claim — bigger burst, unique sound. Trophy icon scale-in.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.19 — Daily Quests

**Цель:** Показать задания дня, мотивировать выполнить, дать claim.

**Текущее UX:** Quest list с completion status. No «Claim All».

**Что статично:**
- Quest cards — static.
- Progress — static bars.

**Рекомендации:**
- **Quest completion:** При переходе 99%→100% — progress bar flash green + «COMPLETE» badge pop-in (spring). Haptic `.light`.
- **Claim:** Same pattern as achievements — gold burst + reward fly.
- **Claim All button:** При наличии ≥2 completed quests — кнопка «Claim All» появляется с scale-in. При нажатии — все rewards cascade fly (staggered, 0.1s). Haptic pattern: rapid succession `.light`.
- **All complete state:** Celebratory text «All Done!» + subtle confetti (10 частиц, gold). Check back timer.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.20 — Daily Login

**Цель:** Reward за вход. Поддержка streak.

**Текущее UX:** Calendar grid с day rewards, DailyLoginPopupView auto-popup.

**Что статично:**
- Day circles — static.
- Streak counter — static.

**Рекомендации:**
- **Popup entry:** Slide-up (0.3s, spring). Calendar days staggered fade-in (0.02s each).
- **Today's reward highlight:** Day circle glow pulse gold + scale (1.1x). «TAP TO CLAIM» text pulse.
- **Claim animation:** Day circle → reward flies out (gold coin/gem/potion icon, 0.4s arc trajectory) → counter update. Haptic `.medium`.
- **Streak milestone (Day 7):** Enhanced claim — double burst, bigger rewards fly in sequence, «7-DAY STREAK!» text slam. Haptic pattern.
- **Missed day:** Грayed с subtle sadness (no animation, just dim). НЕ punishing визуально.

**Нельзя перегружать:** Popup не должен задерживать больше 3-5 секунд. Auto-claim если streak continues, manual only для big milestones.

**Priority:** Medium | **Dev Complexity:** Low

---

### 2.21 — Leaderboard

**Цель:** Показать позицию игрока среди всех. Мотивировать подняться.

**Текущее UX:** Rating/Level/Gold tabs, LeaderboardRowView.

**Что статично:**
- Rows — static list.
- Player's own row — highlighted но static.

**Рекомендации:**
- **Player row highlight:** Persistent subtle gold glow border. При открытии — brief flash для привлечения внимания.
- **Rank number animation:** При изменении ранга — old number flies away, new number slides in (0.3s).
- **Top 3 special treatment:** Crown/medal icons с subtle shine animation (gold shimmer, 3s loop).
- **Scroll to me:** При open — auto-scroll с animation к позиции игрока (0.5s).
- **Rating change indicator:** «↑15 since yesterday» — green animated slide-in.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.22 — Profile

**Цель:** Статистика и identity игрока.

**Текущее UX:** Character stats overlay.

**Рекомендации:**
- Stats count-up при открытии (как Character screen).
- Win/Loss ratio — animated pie chart fill (0.5s).
- Total battles counter — tick up.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.23 — Shell Game

**Цель:** Мини-игра. Fun gambling mechanic с fair odds.

**Текущее UX:** 3-cup game с betting/playing/result states. «Compliant».

**Рекомендации:**
- **Cup shuffle:** Smooth interpolation, speed increases per round. Trail effect за cups.
- **Selection:** Cup lift animation с anticipation pause (0.3s before reveal).
- **Win:** Cup lifts → gold burst → coins fly to counter. Haptic `.success`.
- **Loss:** Cup lifts → empty. Brief dim. «Try Again» CTA immediate.
- **Bet increase:** Gold numbers tick-up при slider adjust.

**Нельзя перегружать:** Shell Game — казино-механика. НЕ добавлять мигающий свет, slot-machine sounds, «JACKPOT» visuals. Это card game в таверне, не Лас-Вегас.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.24 — Gold Mine

**Цель:** Passive income. «Поставил и забыл».

**Текущее UX:** Idle/mining/ready/collecting states.

**Что статично:**
- Mining state — should feel «active» but may be too subtle.

**Рекомендации:**
- **Mining state:** Pickaxe subtle swing animation (2s loop). Dust particles at mine entrance (5 частиц).
- **Ready to collect:** Gold glow intensifies + notification badge pulse. Mine cart full of gold — subtle sparkle.
- **Collection:** Gold cascades from cart → counter. Multiple coins, staggered. Haptic rapid `.light`.
- **Slot unlock:** New slot materializes (fade-in, 0.4s) с gold frame flash.
- **Boost (gem spend):** Fast-forward effect — pickaxe animation 5x speed for 1s → «COMPLETE» stamp.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.25 — Dungeon Rush

**Цель:** Endless wave mode. Максимальный engagement.

**Текущее UX:** Fighting/shopping/result states.

**Рекомендации:**
- **Wave counter:** Large, animated. При milestone floors (5, 10, 15) — number flash gold + screen pulse.
- **Shop between waves:** Items slide-in from sides (0.2s stagger). Gold counter prominent.
- **Death/result:** Score count-up с multiplier reveal. Total gold — coin rain. «NEW RECORD» if applicable — slam text + gold burst.
- **Difficulty escalation visual:** Background subtly darkens per floor. Enemy color intensity increases.

**Priority:** Low | **Dev Complexity:** Low

---

### 2.26 — Settings

**Цель:** Utility. Настройки аудио, языка, аккаунта.

**Текущее UX:** «Fully compliant».

**Рекомендации:** Минимальные. Toggle switches с smooth animation (0.2s). Section expand/collapse если добавим. Никаких decorative анимаций.

**Priority:** Low | **Dev Complexity:** Low

---

## 3. MOTION SYSTEM (Unified Framework)

### 3.1 — Animation Philosophy

**Принцип:** Motion в Hexbound служит трём целям:
1. **Feedback** — подтвердить действие (тап, swipe, claim)
2. **Storytelling** — создать эмоцию (победа, поражение, legendary drop)
3. **Guidance** — направить внимание (pulsing CTA, badge, new content)

Motion НЕ служит: декорации, «wow-эффекту ради wow», отвлечению от слабого дизайна, маскировке загрузки (skeleton — да, fancy loading — нет).

### 3.2 — Speed Tiers

| Tier | Duration | Easing | Use Cases |
|------|----------|--------|-----------|
| **Instant** | 0.1–0.15s | `easeOut` | Button press, toggle, micro-feedback |
| **Fast** | 0.2–0.3s | `easeOut` | Tab switch, card appear, sheet open |
| **Normal** | 0.35–0.5s | `easeInOut` | Screen transition, panel slide, progress fill |
| **Reward** | 0.5–0.8s | custom (slow start, fast end) | Loot reveal, level up, rank change |
| **Epic** | 0.8–1.5s | custom (dramatic pause + burst) | Legendary drop, first win, rank up ceremony |

### 3.3 — Easing Presets

```swift
// Определить как static properties в MotionConstants
static let snappy = Animation.easeOut(duration: 0.2)
static let smooth = Animation.easeInOut(duration: 0.35)
static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.55)
static let reward = Animation.easeIn(duration: 0.3).delay(0.15) // anticipation + payoff
static let dramatic = Animation.spring(response: 0.5, dampingFraction: 0.6)
```

### 3.4 — Button Press Behavior

Все кнопки уже используют `.scalePress(0.97)`. Расширить:

| Button Type | Press Scale | Press Duration | Release | Haptic | Extra |
|-------------|-----------|----------------|---------|--------|-------|
| Primary (gold) | 0.95 | 0.08s | spring back 0.2s | `.medium` | — |
| Secondary | 0.97 | 0.08s | spring back 0.15s | `.light` | — |
| Fight | 0.92 | 0.1s | spring back 0.25s | `.heavy` | Shine burst on release |
| Danger | 0.96 | 0.08s | spring back 0.15s | `.warning` | Red flash on release |
| Ghost | 0.98 | 0.05s | ease back 0.1s | none | — |
| Claim (reward) | 0.90 | 0.1s | spring back 0.3s | `.success` | Gold burst on release |

### 3.5 — Card Behavior

| State | Animation | Duration | Details |
|-------|-----------|----------|---------|
| Appear | Fade + slide up (8px) | 0.25s | easeOut. Stagger 0.05s in lists |
| Press | Scale 0.97, dim background 5% | 0.08s | easeOut |
| Select | Scale 1.02, gold border fade-in | 0.2s | spring |
| Deselect | Scale 1.0, border fade-out | 0.15s | easeOut |
| Remove | Scale 0.8, opacity 0 | 0.2s | easeIn |

### 3.6 — Panel Enter/Exit

| Direction | Animation | Duration | Easing |
|-----------|-----------|----------|--------|
| From bottom (sheets) | Slide up + spring settle | 0.35s | spring(0.3, 0.7) |
| From right (navigation push) | Slide right→left | 0.3s | easeInOut |
| Modal overlay | Fade background (0→0.5 opacity) + scale center (0.9→1.0) | 0.25s | spring(0.3, 0.7) |
| Dismiss | Reverse of enter, slightly faster | 0.2s | easeIn |

### 3.7 — Tab Switch

Content crossfade, 0.2s. Indicator bar — slide to new position (0.25s, spring). Не instant swap.

### 3.8 — Reward Reveal Sequence

Стандартизированный паттерн для любого reward moment:

1. **Anticipation** (0.2–0.5s): Screen dim, container pulse, sound cue начинается
2. **Reveal** (0.15–0.4s): Item/reward appears (scale, fade, or fly-in)
3. **Celebration** (0.2–0.5s): Particles, glow, haptic
4. **Settle** (0.1–0.2s): Item settles в final position, UI returns to normal

Длительность каждой фазы зависит от rarity:
- Common: фазы 2+4 only (total 0.3s)
- Uncommon: фазы 2+3+4 (total 0.5s)
- Rare: все 4 фазы (total 0.8s)
- Epic: все 4 фазы extended (total 1.0s)
- Legendary: все 4 фазы full ceremony (total 1.5s)

### 3.9 — Number Tick-Up Animation

```swift
// Для gold, gems, XP, rating, stat points
// Start: display old value
// Animate: interpolate old → new over duration
// Easing: easeOut (fast start, slow end — feels like "counting")
// Duration: 0.3–0.5s depending on delta magnitude
// Flash: brief color change on completion (gold for gain, red for loss)
// Sound: subtle click per digit change (optional)
```

### 3.10 — Currency Gain Animation

При получении gold:
1. Gold icon at source bounces
2. 3–10 gold coin particles fly to currency counter (arc trajectory, staggered 0.05s)
3. Counter number tick-up
4. Brief gold flash on counter background
5. Haptic: `.light` per coin landing

При получении gems: Same pattern, blue/cyan particles.

### 3.11 — Progress Bar Fill

```swift
// Fill animation
// Duration: max(0.3, delta_percentage * 1.0)s — bigger change = longer animation
// Easing: easeOut
// Leading edge: glow pulse (gold dot traveling)
// Completion (100%): flash entire bar + brief gold burst
// Overshoot: bar fills to 100%, flashes, resets to new percentage (level up)
```

### 3.12 — Rarity-Based Motion Language

| Rarity | Ambient | Reveal | Claim | Colors |
|--------|---------|--------|-------|--------|
| Common | None | Fade 0.15s | Simple | Gray border |
| Uncommon | None | Fade + green flash | Green spark | Green border |
| Rare | None | Blue beam + flip | Blue burst (15 particles) | Blue border + dim glow |
| Epic | Purple dim pulse (3s) | Purple vortex + materialize | Purple burst (25 particles) + screen dim | Purple border + glow |
| Legendary | Gold shimmer (persistent) | Full ceremony 1.5s | Gold explosion (40 particles) + screen shake + haptic chain | Gold border + animated glow + particle aura |

---

## 4. JUICE / GAME FEEL LAYER

### 4.1 — Approved Effects (Premium Feel)

| Effect | Where to Use | Intensity | Why It's Premium |
|--------|-------------|-----------|------------------|
| **Gold shimmer pass** | Primary CTA, legendary items, deal banners | Subtle, 1 pass per 5s | Signals value without screaming |
| **Glow pulse** | Claimable rewards, active FIGHT button, current player in leaderboard | 2-3s loop, 20% opacity variance | Draws attention without blinking |
| **Particle dust** | Splash bg, Hub city ambient, legendary item detail | 10-20 particles, slow drift | Creates «alive» feeling |
| **Screen shake** | Critical hit, legendary reveal, boss encounter | ±3-5px, 2-3 cycles | Physical impact feeling |
| **Number tick-up** | Gold/Gem/XP/Rating changes | 0.3-0.5s | Satisfying «counting money» |
| **Coin fly** | Purchase, claim reward, sell item | 3-10 particles, arc | Visual confirmation of value transfer |
| **Icon bounce** | New notification, unclaimed reward badge | Single bounce on appear | Attention without annoyance |
| **Spring settle** | Sheets, modals, cards | damping 0.65-0.75 | Physical, weighted, not floaty |
| **Staggered appear** | Lists, grids, cards | 0.03-0.1s between items | Content «flows in» instead of appearing |
| **Stamp effect** | Achievements claimed, floors cleared, quests done | Scale 1.5→1.0, slight rotation | Feels «official» and permanent |

### 4.2 — What Is TOO MUCH (Avoid)

| Effect | Where It Would Go Wrong | Why It's Bad |
|--------|------------------------|-------------|
| **Persistent screen-wide particles** | Hub, Shop, every screen | Performance drain, visual noise, mobile battery |
| **Maching shimmer on prices** | Shop, gem packs | «Casino» feel. Prices should be clean and readable |
| **Blinking countdown timers** | Daily deal, flash sale, BP season end | Creates anxiety, not excitement. Feels manipulative |
| **Sound on every tap** | Buttons, toggles, filters | Sensory overload. Reserve sound for KEY moments |
| **Constant haptic feedback** | Scrolling, swiping, passive viewing | Desensitizes. Haptic = special moments only |
| **Rainbow/multicolor effects** | Anywhere | Breaks dark fantasy aesthetic. This isn't Candy Crush |
| **Popup cascade** | Hub entry, post-combat | Modal fatigue. Queue system, max 1 blocking popup |
| **Auto-playing reward ceremonies** | Common items, small gold amounts | 50g reward doesn't deserve 2 seconds of animation |
| **Parallax on everything** | Every screen background | Dizzy, distracting, performance cost |
| **Bounce on every element** | All icons, text, dividers | Juvenile feel. Reserve bounce for interactive elements |

### 4.3 — What Would Feel Manipulative (RED LINE)

| Pattern | Description | Why It's Toxic |
|---------|-------------|---------------|
| **Fake scarcity countdowns** | «Only 2 left!» on infinite-stock items | Lie that creates pressure. Ruins trust |
| **Loss aversion framing** | «You'll LOSE these rewards if you don't buy now» | Exploits psychological weakness |
| **Reward streak interruption** | «Your daily streak will BREAK if you miss tomorrow» — aggressive visual | Makes player feel obligated, not excited |
| **Premium shimmer on free content** | Making free items look worse to push premium | Demeaning free players |
| **Rigged preview** | Showing best-case scenario in shop but delivering average | Bait and switch |
| **Gem cost buried in fine print** | Large «BUY» button, tiny gem cost | Hiding real price |
| **Artificial loading for «suspense»** | Fake progress bar before instant operation | Wastes player time |
| **Social pressure notifications** | «Your friend passed you in rankings!» push notification | Toxic competition |

### 4.4 — What Should Be AVOIDED in Dark Fantasy Context

| Effect | Why |
|--------|-----|
| Bright neon colors | Breaks grimdark palette |
| Kawaii/cute animations | Wrong tone for dark fantasy |
| Emoji in UI | Already flagged in audit — replace with custom assets |
| Confetti rainbow | Victory = gold/warm, not party |
| Slot machine reels | Even for loot — this isn't a casino |
| «Lucky» sound effects | Cheesy, undermines premium |
| Pop-up ads internal | Never show interstitial ads for own products |

---

## 5. RETENTION & ENGAGEMENT MOMENTS

### 5.1 — First Session

| Moment | Current Emotion | Target Emotion | Motion/UX Treatment | Why It Improves Retention |
|--------|----------------|----------------|---------------------|---------------------------|
| Character creation complete | Neutral «okay, done» | Pride, attachment | Gold burst + type-on name + stats reveal cascade | Player feels invested in THEIR hero |
| First Hub view | Confused, overwhelmed | Curious, guided | Tutorial spotlight → Training building glow | Player knows next step |
| First training fight | Uncertain | Confident | Easy win → Victory ceremony (simplified) | «I can do this» feeling |
| First item equip | Meh | Empowered | Item flies into slot + stat increase tick-up + «POWER UP» text | Tangible improvement feeling |

### 5.2 — First PvP Win

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Emotion | «I won, okay» | «YES! I crushed them!» | Full victory ceremony: slam text + particles + coin rain + rating tick-up |
| Rating context | Number without meaning | «I'm climbing!» | Show rank tier progress bar, animate fill |
| Next action | Go back to hub | «One more fight!» | «FIGHT AGAIN» button pulsing gold, front and center |
| Reward weight | Toast notification | Feels earned and substantial | Itemized reward breakdown with individual animations |

### 5.3 — First Rare Drop

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Emotion | «Blue border, okay» | «WHOA, is that rare?!» | Blue beam reveal + card flip + screen dim + brief haptic |
| Context | No comparison | «This is better than what I have» | Animated «↑ +15 ATK» comparison badge |
| Action | Take All | «I want to equip this NOW» | «Equip Now» shortcut button on loot screen |

### 5.4 — Low Stamina Moment

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Emotion | Frustration «can't play» | Understanding + anticipation | Stamina bar gentle red pulse (NOT aggressive) + «Full in 2h 15m» countdown + «Explore Dungeons» CTA (costs less stamina) |
| Monetization | Hidden | Visible but not pushy | Small «Refill» button near timer. NO popup. NO modal. Player finds it if they want it |
| Retention | Player leaves, maybe forgets | Player sets mental timer | Push notification (if enabled): «Your stamina is full! Time for battle.» |

### 5.5 — Revenge Availability

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Emotion | Passive «Revenge tab exists» | Burning motivation | Red glow on Revenge tab badge + enemy name in bold + «They beat you 3h ago» context |
| Entry point | Arena → Revenge tab | Multiple | Hub notification: «[Enemy] is available for revenge!» + direct shortcut |
| Victory emotion | Same as normal win | EXTRA satisfying | «REVENGE!» text instead of «VICTORY» + crimson+gold particles + 1.5x gold shown prominently |

### 5.6 — Daily Login

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Emotion | Obligation | Surprise + delight | Popup auto-shows today's reward with anticipation pause (0.3s before reveal) |
| Streak | Counter number | Visual progression | Calendar fills with gold, streak fire icon grows with consecutive days |
| Day 7 milestone | Same as other days | Celebration | Extended ceremony: bigger reward, unique animation, «WEEKLY BONUS» banner |

### 5.7 — Daily Quests

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Progress | Static bar | Alive bar | Animate fill on data refresh, glow at >80% |
| Completion | State change | Mini celebration | «COMPLETE» stamp + quest card gold flash + reward preview pop |
| All complete | Generic text | Achievement feeling | «ALL DONE!» confetti (subtle) + bonus reward if applicable |

### 5.8 — Battle Pass Progress

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| XP gain | Not shown | Visible | After combat: «+45 BP XP» animated counter, track fills |
| Level unlock | Unknown | Anticipation | «2 more battles to next reward» — progress ring filling |
| Reward claim | Instant | Satisfying | Node unlock animation (lock shatters) + reward reveal per rarity |

### 5.9 — Achievement Completion

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Trigger | No in-context notification | Immediate | Toast overlay during gameplay: «Achievement Unlocked: First Blood» |
| Claim | Tap in list | Ceremonial | Gold stamp + reward burst + card transition to «Claimed» state |

### 5.10 — Near-Upgrade Success/Failure

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Almost won | Same as lost | «So close!» | Show HP comparison: «Enemy had 3% HP left» — motivates retry |
| Almost leveled | No indicator | Anticipation | XP bar at 95%+ — glow pulse + «Almost there!» micro-text |
| Almost ranked up | No indicator | Drive | Rating bar near threshold — animated glow + rank preview |

### 5.11 — Leaderboard Climb

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Rank change | Static list | Animated | Player row slides up/down to new position (0.3s) |
| New personal best | No recognition | Celebration | «NEW PERSONAL BEST: #47!» banner + gold flash on player row |

### 5.12 — Season Reset / Rewards

| Aspect | Current | Target | Treatment |
|--------|---------|--------|-----------|
| Season end | TBD | Closure + excitement | Summary screen: total battles, rank achieved, rewards earned — all animated tick-up → «NEW SEASON BEGINS» transition |
| Rewards delivery | TBD | Gift opening | Season rewards presented as a «package» — tap to reveal each |

---

## 6. MONETIZATION UX WITHOUT PAY-TO-WIN FEEL

### 6.1 — General Principles

- **Monetization UI lives IN the game world**, not on top of it. Shop is a building in the city, not a popup.
- **Value is shown, not told.** Don't say «BEST VALUE!» — show the per-gem price comparison visually.
- **Player initiates.** Never push monetization unprompted. No «You're out of stamina! Buy gems?» popup.
- **Transparency always.** Show what you get. Show the odds. Show the real price.
- **Free path is dignified.** Free rewards look good. Free track progression feels real. Never make free players feel like second-class citizens.

### 6.2 — Energy Refill (10 Gems)

**Current:** Implicit — player discovers when out of stamina.

**Recommendation:**
- Small «⚡ Refill» button appears NEXT TO stamina bar when STA < cost of next action. NOT a popup.
- Button style: compact secondary, NOT primary. Not screaming for attention.
- Tap → confirmation: «Refill 120 Stamina for 10 Gems?» Clean sheet, gem icon, current balance shown.
- Animation on refill: Stamina bar fills with blue energy wave (0.5s). Satisfying, not flashy.
- **DO NOT:** Auto-prompt refill. Flash the button. Show refill count limit per day aggressively.

### 6.3 — Premium Battle Pass (500 Gems)

**Current:** Two-track display.

**Recommendation:**
- Premium track items visible but dimmed with lock icon. NOT blurred, NOT hidden. Player can see exactly what they're missing.
- Upgrade CTA: Single «Unlock Premium Track» button at top of BP screen. Gold outline, NOT pulsing, NOT popup.
- Value display: Show total value of premium rewards as «X items + Y gold + Z gems worth [amount]».
- Animation on upgrade: Premium track «lights up» — gold line draws through all locked nodes (0.5s), locks shatter in sequence, all rewards briefly flash. This is the ONE big moment.
- **DO NOT:** Show premium upgrade popup on every BP level. Put premium ads on Hub. Flash «limited time» on premium.

### 6.4 — Gem Packs

**Current:** CurrencyPurchaseView.

**Recommendation:**
- Layout: Cards from small to large, left to right. «Recommended» badge on medium pack (value per gem best).
- Value visualization: Gem icon stack size increases per tier. 100 gems = small pile. 6500 = overflowing treasure chest.
- «Bonus gems» for larger packs shown as «+50 BONUS» badge (real, not fake markup).
- Animation on purchase: Gem rain from top + counter tick-up + «Thank you» toast (brief, warm, not performative).
- **DO NOT:** Use countdown timers on standard packs. Show «Sale» that never ends. Auto-display after level up.

### 6.5 — Premium Reward Track (Battle Pass)

Covered in 6.3. Keep premium rewards cosmetic only. Show clearly what's cosmetic vs functional.

### 6.6 — Limited Events

**When events exist:**
- Event banner on Hub — themed art, event timer, entry point. Appears naturally among other banners, not overlaying them.
- Timer: Clean countdown, NOT red, NOT blinking until final hour.
- Final 24h: Timer text turns amber. Still no blinking. Just color.
- Entry: Event has own screen in game world (e.g., special dungeon, special arena).
- **DO NOT:** Popup when event starts. Push notifications every hour. Show «LAST CHANCE» more than once.

### 6.7 — Comeback Offers

**For returning players (inactive 7+ days):**
- Welcome back screen with «Here's what you missed» summary.
- One-time comeback bundle: discounted gem pack or bonus items. Shown ONCE, dismissable.
- Clean presentation: «Welcome Back Pack: 200 Gems + 5000 Gold + Rare Item for $2.99 (normally $4.99)». Real discount, not fake.
- **DO NOT:** Show comeback offer every time they open app. Stack with daily login popup. Create artificial urgency.

### 6.8 — Daily Offers

**If daily rotating offers exist:**
- One slot on Shop screen with «Today's Deal» banner. Subtle gold shimmer on border (1 pass per 5s).
- Clear before/after pricing. Show savings as percentage.
- Timer: «Refreshes in 14h 23m» — clean text, no urgency formatting.
- **DO NOT:** More than 1 daily deal banner. Flash. Popup. Push notification about deals.

---

## 7. PRIORITIZED IMPLEMENTATION PLAN

### Wave 1: Quick Wins (1–2 weeks)

Максимальный impact при минимальном effort.

| # | Task | Impact: Perception | Impact: Retention | Impact: Monetization | Effort |
|---|------|-------------------|-------------------|---------------------|--------|
| 1 | **Battle intro VS screen** (Arena → Combat transition) | ★★★★★ | ★★★★ | — | Low |
| 2 | **Victory/Defeat ceremony** on Combat Result | ★★★★★ | ★★★★★ | ★★ | Medium |
| 3 | **Number tick-up** for gold/gems/XP/rating everywhere | ★★★★ | ★★★ | ★★ | Low |
| 4 | **FIGHT button glow pulse** + proper press feedback | ★★★★ | ★★★★ | — | Low |
| 5 | **Staggered card entry** on Arena, Inventory, Achievements | ★★★★ | ★★ | — | Low |
| 6 | **Haptic feedback** on key actions (fight, claim, equip, buy) | ★★★★ | ★★★ | ★★ | Low |
| 7 | **Claim animation** on Achievements/Quests/DailyLogin (gold burst) | ★★★★ | ★★★★ | — | Low |
| 8 | **Stamina bar animated fill** + low-stamina timer | ★★★ | ★★★★ | ★★★ | Low |
| 9 | **Currency counter tick-up** when gaining/spending gold/gems | ★★★★ | ★★★ | ★★ | Low |
| 10 | **Tab switch crossfade** (replace instant swaps) | ★★★ | ★ | — | Low |

### Wave 2: Important Upgrades (2–4 weeks)

Builds on Wave 1. Creates the «polished» feeling.

| # | Task | Impact: Perception | Impact: Retention | Impact: Monetization | Effort |
|---|------|-------------------|-------------------|---------------------|--------|
| 11 | **Rarity-based loot reveal** (common=fast, legendary=ceremony) | ★★★★★ | ★★★★★ | ★★★ | Medium |
| 12 | **Onboarding refactor** (design system + step animations + character build-up) | ★★★★★ | ★★★★★ | — | High |
| 13 | **Item equip «fly to slot» animation** | ★★★★ | ★★★ | — | Medium |
| 14 | **Hub idle life** (character breathing, city ambient, floating icon pop-in) | ★★★★ | ★★★ | — | Medium |
| 15 | **Revenge system UX** (red glow, notification, enhanced reward presentation) | ★★★★ | ★★★★★ | — | Medium |
| 16 | **Modal queue system** (Hub entry: DailyLogin → LevelUp → Quests, sequential) | ★★★ | ★★★★ | — | Medium |
| 17 | **Combat critical hit/dodge enhanced VFX** (screen shake, slow-mo kill) | ★★★★★ | ★★★★ | — | Medium |
| 18 | **Shop purchase flow** (confirmation sheet + item fly + gold tick-down) | ★★★★ | ★★ | ★★★★ | Medium |
| 19 | **Battle Pass track animation** (gold line draw + node unlock) | ★★★★ | ★★★★ | ★★★★ | Medium |
| 20 | **Win streak fire indicator** on Arena | ★★★ | ★★★★ | — | Low |

### Wave 3: Polish / Premium Layer (4–8 weeks)

«Top-grossing tier» polish.

| # | Task | Impact: Perception | Impact: Retention | Impact: Monetization | Effort |
|---|------|-------------------|-------------------|---------------------|--------|
| 21 | **Dungeon boss intro** (dramatic entrance + «BOSS FIGHT» slam) | ★★★★ | ★★★ | — | Medium |
| 22 | **Shell Game enhanced** (cup trail, anticipation pause, win burst) | ★★★ | ★★ | — | Medium |
| 23 | **Gold Mine idle animation** (pickaxe swing, dust, collection cascade) | ★★★ | ★★ | — | Low |
| 24 | **Leaderboard rank change animation** | ★★★ | ★★★ | — | Low |
| 25 | **Character Detail parallax + stat count-up** | ★★★ | ★★ | — | Low |
| 26 | **Near-miss motivation** (HP comparison on close losses, «Almost there» XP) | ★★★ | ★★★★ | — | Low |
| 27 | **Season reset ceremony** + summary screen | ★★★★ | ★★★★ | ★★★ | Medium |
| 28 | **Dungeon room transitions** (slide + floor counter animation) | ★★★ | ★★ | — | Low |
| 29 | **Profile stats animated** (count-up, pie charts) | ★★ | ★ | — | Low |
| 30 | **Event system motion** (event banner, themed transitions) | ★★★★ | ★★★★ | ★★★★ | High |

---

## 8. DELIVERABLES

### A. Top 20 Animation Improvements (by ROI)

1. Battle intro VS screen (Arena → Combat)
2. Victory ceremony (VICTORY text slam + particles + reward cascade)
3. Rarity-based loot reveal sequence
4. Number tick-up animation system (universal)
5. FIGHT button idle glow + press feedback
6. Haptic feedback layer (fight, claim, equip, buy)
7. Claim animations (achievements, quests, daily login)
8. Onboarding character creation build-up
9. Item equip «fly to slot»
10. Combat critical hit screen shake + slow-mo
11. Currency gain coin fly animation
12. Hub idle life (character, city, badges)
13. Staggered card entry (lists, grids)
14. Defeat → revenge motivation UX
15. Battle Pass track unlock animation
16. Progress bar animated fill (universal)
17. Shop purchase flow animation
18. Win streak fire indicator
19. Tab switch crossfade
20. Dungeon boss intro ceremony

### B. Top 10 Highest-ROI Changes

1. **Victory/Defeat ceremony** — transforms emotional peak from «info screen» to celebration. Retention: +5-10% session repeat.
2. **Battle intro VS screen** — eliminates 0.5-2s void, creates anticipation. Perception: from «broken» to «epic».
3. **Number tick-up system** — one component, used everywhere. Every number change feels satisfying.
4. **Rarity loot reveal** — legendary drops become memorable moments, drive chase behavior.
5. **Claim animation pattern** — applies to 3+ screens (achievements, quests, login). Single implementation, big reward.
6. **Haptic feedback layer** — zero visual change, massive feel upgrade. iOS advantage.
7. **FIGHT button glow** — the #1 button in the game should feel like #1.
8. **Onboarding polish** — first impression = D1 retention. Currently the weakest screen.
9. **Revenge UX** — drives return visits. Red glow + notification = «I MUST come back».
10. **Shop purchase flow** — makes spending feel good, not transactional. Monetization: +conversion.

### C. Top 10 Screens That Need Most Attention

1. **Combat Result** — highest emotional moment, currently flattest.
2. **Arena** — core interaction point, FIGHT button needs life.
3. **Loot** — reward moments define game feel. Currently static.
4. **Onboarding** — first impression, currently outside design system.
5. **Hub** — player's home, currently too static.
6. **Combat** — already has VFX but needs VS intro, enhanced crits, status clarity.
7. **Battle Pass** — progression visualization needs animation.
8. **Daily Login** — daily first impression, claim should satisfy.
9. **Shop** — monetization UX needs purchase flow polish.
10. **Inventory** — equip/sell actions need satisfying feedback.

### D. «Do Not Do» List

1. ❌ Не добавлять persistent particles на каждый экран — battery drain + visual noise.
2. ❌ Не добавлять shimmer/glow на цены в магазине — casino feel.
3. ❌ Не добавлять blinking countdown timers — FOMO manipulation.
4. ❌ Не показывать monetization popups unprompted — breaks trust.
5. ❌ Не задерживать loading искусственно для «anticipation» — уважай время игрока.
6. ❌ Не анимировать Common item drops дольше 0.3s — player will rage quit loot screen.
7. ❌ Не добавлять rainbow/neon effects — breaks dark fantasy aesthetic.
8. ❌ Не добавлять звуки на каждый тап — sensory overload.
9. ❌ Не использовать bounce animation на text/dividers — juvenile feel.
10. ❌ Не добавлять «SALE» banners, которые никогда не заканчиваются — ложь разрушает доверие.
11. ❌ Не показывать больше 1 blocking modal при входе в игру — modal fatigue.
12. ❌ Не добавлять emoji в production UI — заменить на custom assets.
13. ❌ Не анимировать Settings/utility screens — waste of effort.
14. ❌ Не добавлять social pressure notifications — «Friend passed you» = toxic.
15. ❌ Не использовать slot machine reels для loot — even if tempting.

### E. Final Art/Motion Direction Summary

Hexbound motion language — это **controlled power**. Каждая анимация должна чувствоваться как меч, извлекаемый из ножен: тяжёлый, точный, с весом. Не как конфетти из хлопушки. Gold shimmer = тлеющие угли в кузнице, не неоновая вывеска. Screen shake = удар молота, не землетрясение. Particle bursts = искры от наковальни, не фейерверк. Всё в палитре тёмного золота, приглушённых земляных тонов, с crimson для danger и cyan для magic. Motion подчёркивает три состояния игрока: **power** (при победе и прогрессе), **danger** (при бое и ставках) и **reward** (при получении ценности). Каждый экран, не получивший свою анимацию, — это пропущенная возможность для эмоции. Но каждый экран, получивший ЛИШНЮЮ анимацию, — это шаг к дешёвому F2P trash. Золотое правило: если анимация не помогает игроку что-то понять, почувствовать или решить — она не нужна.

---

*Документ создан 2026-03-20. Использовать как production roadmap для motion/juice implementation.*
