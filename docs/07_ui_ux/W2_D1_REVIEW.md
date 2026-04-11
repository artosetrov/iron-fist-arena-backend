# W2.D1 — Recon & Review (review BEFORE code)

**Автор:** Claude (orchestrator)
**Дата:** 2026-04-10
**Скоуп:** W2 Onboarding hook (5 дней) — pre-implementation recon
**Статус:** 🔍 Review — требуется выбор Артёма перед любой имплементацией

---

## Зачем этот документ

По правилу `feedback_review_before_code.md` (и ранее прямому указанию Артёма: *«UX reviews must produce report + prototype FIRST, discuss with user, then implement only on approval»*) я обязан **сначала показать находки, предложить варианты, получить одобрение — и только потом писать код**.

Перед имплементацией W2 я провёл recon всех 5 дней (`W2.D1`–`W2.D5` из `QA_FIX_PLAN_2026-04-10.md`, строки 620–830) и сверил каждое предложение с текущим состоянием кода. Обнаружилось **существенное расхождение между планом и реальностью**: план был написан на устаревший снимок проекта, и часть задач **уже решена**, часть — **частично решена**, и только 2–3 задачи действительно требуют новой работы.

Ниже — полный расклад по каждому дню W2 и варианты для решения.

---

## TL;DR (если читать только одно)

| Day | Plan says | Reality | Verdict |
|---|---|---|---|
| **W2.D1** — ONB-02 compress gender+appearance | *«5 экранов, объединить в 1 с TabSwitcher»* | **Уже 3-step wizard.** Step 1 = `AppearanceStepView` уже объединяет race + gender + avatar (icon toggle + slide avatar + race row) | ✅ **Уже сделано в духе плана.** TabSwitcher — избыточен, сломает компактный layout. |
| **W2.D2** — ONB-04 Welcome lore | *«wall-of-text, сократить до 15 слов, добавить full-screen BG»* | **`LoreIntroView.swift` — уже 6-slide cinematic** с full-bleed backgrounds, game assets, particle effects (545 LOC) | ✅ **Уже cinematic.** Нужна только проверка длины текстов на каждом слайде. |
| **W2.D2** — ONB-06 Guest prominence | *«Guest не в первой focus zone»* | **`WelcomeView.swift:30` — "PLAY AS GUEST" УЖЕ `.primary` CTA**, "LOG IN" secondary, social ниже | ✅ **Уже сделано.** Hierarchy правильная. |
| **W2.D3** — ONB-01 Tutorial fight | *«Нет guided первого боя, создать scripted»* | **Tutorial infrastructure ЕСТЬ:** `TutorialManager`, `TutorialView`, `TutorialStepCard`, `TutorialOverlayView`, `TutorialTooltipView`, `TutorialQuestBanner`, `NPCSpeechBubble`, `FTUEObjective` enum (firstBattle/gearUp/exploreDungeon), backend routes `/api/tutorial/{referral,step,skip,quest}`. **НО:** нет scripted tutorial fight (гарантированная победа) — только tooltip-based guidance. Также нет `tutorialCompleted` в Prisma schema. | 🟡 **Частично сделано.** Нужна scripted fight layer поверх существующей FTUE. |
| **W2.D4** — HUB-02 Building gating | *«10 зданий на Lv1 = choice overload, добавить unlockLevel»* | Нет `unlockLevel` в `CityBuildingConfig.swift`. Есть только `route: AppRoute?` pattern для Coming Soon (nil = hidden). **10 зданий всё равно все видны сразу.** | ❌ **Не сделано.** Валидная задача. |
| **W2.D5** — HUB-04 Today's goals panel | *«Нет panel что делать сегодня»* | Нет `TodayGoalsPanel.swift`. Вероятно, частично перекрывается FTUE `firstBattle/gearUp/exploreDungeon`. | ❌ **Не сделано.** Но возможно дублирует FTUE. |
| **W2.D5** — HUB-03 Badge hierarchy | *«Бейджи шумные, нужны priority levels»* | Badges существуют на зданиях, но без `badgePriority` enum. | 🟡 **Частично** — нужна категоризация critical/info/none. |
| **W2.D5** — ONB-05 Daily login timing | *«Слишком рано, показывать после tutorial»* | Зависит от ONB-01 — если нет tutorial fight, то и gating нечему применить. | ⏳ **Заблокирован** пока ONB-01 не оформлен. |

**Bottom line:** из ~7 задач W2 **3 уже сделаны**, **2 частично сделаны**, **2 требуют работы с нуля**. Буквальное следование плану приведёт к **регрессии** (TabSwitcher в AppearanceStepView, переписывание уже-cinematic LoreIntro).

---

## Детальные находки

### 1. W2.D1 — ONB-02 compress gender + appearance (уже сделано)

**Что говорит план** (строка 625 `QA_FIX_PLAN`):
> 5 отдельных экранов для создания персонажа — слишком длинный funnel. Объединить Gender picker и Appearance picker в один экран с табами «♂ Male / ♀ Female». Создать `AppearanceWithGenderView.swift` — объединённый экран с Tab switcher (существующий `TabSwitcher.swift` из DS — 2-tab variant).

**Что в коде** (`Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift:5`):
```swift
// 3-step wizard: 0 = Class, 1 = Appearance (race + gender + avatar), 2 = Name
var step = 0
// ...
var totalSteps: Int { 3 }
```

**Step 1 — `AppearanceStepView.swift`** — уже объединяет всё в одном экране:
- Hero card по центру (200×280) с slide-in анимацией аватара
- Слева сверху: **icon toggle** `ui-gender-male` / `ui-gender-female` → `vm.toggleGender()`
- Слева снизу: ← arrow (prev avatar)
- Справа сверху: 🎲 dice (randomize)
- Справа снизу: → arrow (next avatar)
- Внизу: `raceRow` — горизонтальный ряд 5 рас (human/orc/skeleton/demon/dogfolk)
- Filter: `skin.gender == selectedGender.rawValue` применяется к avatar pool

Это **более компактный UX, чем предложенный TabSwitcher**: icon toggle занимает 48×48pt, а `TabSwitcher(tabs: ["MALE", "FEMALE"])` — `maxWidth: .infinity` × `buttonHeightLG`. Замена сломает layout колонки arrows.

**Никаких `GenderPickerView.swift`, `AppearancePickerView.swift` в проекте нет** — они уже были схлопнуты. План эту компрессию пропустил.

**Что реально можно улучшить в AppearanceStepView (если вообще):**
- Gender toggle — просто иконка без подписи, новички могут не понять что это переключатель. Можно добавить пилюлю "MALE/FEMALE" снизу иконки или в accessibility label.
- На больших экранах `raceRow` уходит слишком вниз от hero card — minor.
- Нет анимации при смене gender (только snappy swap). Можно добавить cross-fade.

Но это **polish, не compression**. Основной дизайн-интент W2.D1 — *«убрать длинный funnel»* — уже достигнут.

---

### 2. W2.D2 — ONB-04 Welcome lore (уже cinematic)

**Что говорит план:**
> Длинный текст welcome/lore intro — никто не читает. Сократить текст до 15 слов. Добавить full-screen background illustration. Одна мощная фраза типа «Веками клан сражался за эти земли...».

**Что в коде** (`Hexbound/Hexbound/Views/Auth/LoreIntroView.swift`, **545 LOC**):
```swift
// Shown once after first hero creation, before entering the hub.
// 6-slide cinematic presentation about the world of Hexbound.
// Full-bleed background art, real game assets, particle effects.
```

6 слайдов с:
- `backgroundAsset: "bg-hub"` / и другие full-bleed фоны
- `assets: [SlideAsset]` — вложенные игровые ассеты с offset'ами
- `accentColor` per slide
- `particlePhase` animation
- Curtain in/out переходы
- `heroName` interpolation

Это **уже cinematic**, не wall-of-text. План был написан когда этот файл либо не существовал, либо выглядел иначе.

**Что реально проверить:**
- Длина `.body` на каждом из 6 слайдов (≤ 15 слов на слайд?)
- Skip button (может быть заметнее?)
- Итоговое время всех слайдов (должно быть ≤ 30 сек)

**Verdict:** план «создать cinematic» уже реализован. Нужна только ревизия текстов на лаконичность. Это задача для `hexbound-studio:lore` + `hexbound-studio:ember`, не для переписывания компонента.

---

### 3. W2.D2 — ONB-06 Guest prominence (уже сделано)

**Что говорит план:**
> «Play as Guest» не в первой фокус-зоне. Swap hierarchy: большая primary CTA «PLAY AS GUEST», ниже secondary «Sign up / Sign In».

**Что в коде** (`Hexbound/Hexbound/Views/Auth/WelcomeView.swift:24-45`):
```swift
VStack(spacing: LayoutConstants.spaceMD) {
    // Play as Guest — primary CTA
    Button { ... } label: { Text("PLAY AS GUEST") }
        .buttonStyle(.primary(enabled: !vm.isLoading))   // ← ГЛАВНАЯ CTA

    // Log In — secondary
    Button { ... } label: { Text("LOG IN") }
        .buttonStyle(.secondary)                         // ← secondary

    // Social divider "OR"
    // Apple + Google buttons (tertiary)
    // Create Account ghost link
}
```

Иерархия **уже правильная**:
1. `PLAY AS GUEST` — `.primary` (gold CTA)
2. `LOG IN` — `.secondary`
3. `OR` divider
4. Apple / Google — plain
5. `Create Account` — ghost

**Verdict:** уже сделано. Только warning текст *«Guest progress may be lost»* можно сделать тоньше — но это polish.

---

### 4. W2.D3 — ONB-01 Tutorial fight (частично, нужна scripted layer)

**Что говорит план:**
> После хаба reveal → автоматически tutorial fight. Против Lv 1 Orc Grunt. Подсказки на stance selector, defense zones, FIGHT. Гарантированная победа. Epic reward screen. Prisma: `tutorialCompleted: Boolean`.

**Что в коде:**

**A. Tutorial infrastructure — есть:**
- `Hexbound/Hexbound/Tutorial/TutorialManager.swift` — state machine
- `Hexbound/Hexbound/Tutorial/TutorialTooltipView.swift` — tooltip overlay
- `Hexbound/Hexbound/Views/Tutorial/TutorialView.swift` — main view
- `Hexbound/Hexbound/Views/Tutorial/TutorialStepCard.swift` — шаги
- `Hexbound/Hexbound/Views/Components/TutorialQuestBanner.swift` — баннер
- `Hexbound/Hexbound/Views/Components/TutorialOverlayView.swift` — overlay
- `Hexbound/Hexbound/Views/Components/NPCSpeechBubble.swift` — диалоги NPC

**B. FTUE система — уже есть (3-step big objectives):**
`CityBuildingConfig.swift:3-28`:
```swift
enum FTUEObjective: String, CaseIterable, Identifiable {
    case firstBattle   = "ftue_first_battle"
    case gearUp        = "ftue_gear_up"
    case exploreDungeon = "ftue_explore_dungeon"
}
```
→ полноценная 3-этапная FTUE, показывается после character creation.

**C. Backend routes — есть:**
- `backend/src/app/api/tutorial/route.ts`
- `backend/src/app/api/tutorial/step/route.ts`
- `backend/src/app/api/tutorial/skip/route.ts`
- `backend/src/app/api/tutorial/quest/route.ts`
- `backend/src/app/api/tutorial/referral/route.ts`

**D. Что ОТСУТСТВУЕТ:**
1. **Нет scripted tutorial fight** — FTUE «firstBattle» просто указывает *«иди в Arena и сражайся»*, но не создаёт guided сценарий с гарантированной победой, scripted противником и подсказками на stance zones.
2. **Нет `tutorialCompleted` в Prisma** — `grep -c "tutorialCompleted" schema.prisma` → 0. Backend хранит tutorial state где-то ещё (через tutorial step routes), но поле для scripted-fight gating отсутствует.
3. **Daily Login не зависит от tutorial completion** — ONB-05 timing fix нечему gating применить.

**Verdict:** infrastructure есть, но scripted-fight layer отсутствует. Это **реальная работа** — 1.5–2 дня.

**Подводный камень:** если мы добавим scripted tutorial fight **поверх FTUE firstBattle**, получится либо дублирование (две системы говорят «иди в бой»), либо replacement (scripted заменяет FTUE firstBattle). Нужно решить дизайн до кода.

---

### 5. W2.D4 — HUB-02 Building gating (не сделано, валидно)

**Что в коде** (`Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift:5-16`):
```swift
struct CityBuilding: Identifiable {
    let id: String
    let imageName: String
    let label: String
    let route: AppRoute?         // nil = Coming Soon placeholder
    var relativeX, relativeY, relativeSize: CGFloat
    let glowColor: Color
    let fallbackIcon: String
    var labelYOffset: CGFloat
}
```

**Нет** `unlockLevel: Int`, нет `var isLocked(at level: Int) -> Bool`, нет `BuildingUnlockCeremony.swift`. 10 зданий отрисовываются безусловно (строка 155: `defaultCityBuildings.filter { $0.route != nil }`).

**Verdict:** задача валидна. 1 день работы. **Но:** перед имплементацией нужен `hexbound-studio:ascent` review на конкретную gating таблицу — план предлагает:
- Lv1: Arena, Inbox, Daily Login
- Lv2: Training, Quests
- Lv3: Dungeon
- Lv4: Shop
- Lv5: Battle Pass, Achievements
- Lv7: Gold Mine

Это агрессивное gating — на Lv1 только 3 здания. Нужен sanity check: не сломает ли это loop «бой → reward → apply → next action» для новичка.

---

### 6. W2.D5 — HUB-04 Today's goals + HUB-03 badges + ONB-05 timing (не сделано, с caveat)

**HUB-04 Today's goals panel:**
- Нет `TodayGoalsPanel.swift`
- **Caveat:** FTUE уже показывает 3 big objectives после character creation (firstBattle/gearUp/exploreDungeon). Если ещё добавить `TodayGoalsPanel` на хаб с *«3 wins / 1 dungeon / Claim BP / Daily login»*, получится **две UI-системы** которые обе говорят новичку что делать. Нужно решить: FTUE только на первые 10 мин, TodayGoals — постоянный хаб-widget? Или TodayGoals заменяет FTUE полностью? Или они отображают разные вещи (FTUE = one-time milestones, TodayGoals = daily reset)?

**HUB-03 Badge hierarchy:**
- Badges на зданиях уже есть (Арена: "FREE 3", Daily Login: "!", etc.)
- Нет `badgePriority: .critical/.info/.none` enum
- Нужно просто добавить поле + condition в renderer

**ONB-05 Daily login timing:**
- Зависит от `tutorialCompleted` field, которого нет в Prisma
- Сейчас Daily Login показывается сразу на первом заходе в хаб
- Эмоциональный порядок плана («Молодец, первая победа! Держи бонус») валиден, но требует ONB-01 чтобы быть осмысленным

**Verdict:** всё валидно, но взаимозависимо. Не трогать пока ONB-01 дизайн не решён.

---

## Options для решения W2 (выбор за Артёмом)

### Option A — Следовать буквально (не рекомендую)

Переписать `AppearanceStepView` под TabSwitcher, переписать `LoreIntroView` под один слайд, добавить guest CTA (уже есть), написать scripted tutorial fight, добавить building gating, добавить TodayGoals panel.

- ⛔ Регрессия: заменим хороший компактный icon toggle на TabSwitcher, потеряем 6-slide cinematic lore
- ⛔ Duplication: TodayGoalsPanel поверх FTUE без решения о их разделении
- ⛔ ~5 дней работы, из которых ~2 дня тратятся на ломание уже-работающего

---

### Option B — Фокус на реальном дефиците (рекомендую)

Признать что W2.D1, W2.D2 (обе части) **уже сделаны**, и сделать актуальный W2 план:

| New day | Task | Estimate |
|---|---|---|
| **W2.D1** | ✅ Уже сделано. Выпустить мини-отчёт `W2_D1_REALITY_CHECK.md` с grep-evidence, пометить задачу closed. Minor polish `AppearanceStepView` (gender label visibility) — 1–2 часа. | 0.25 дня |
| **W2.D2** | 🔍 Audit `LoreIntroView` текстов на лаконичность (вызвать `hexbound-studio:lore` + `hexbound-studio:ember`), сократить где надо, добавить более заметный Skip. ✅ `WelcomeView` — уже сделано, noop. | 0.5 дня |
| **W2.D3 + W2.D4** | **Главная работа:** scripted tutorial fight поверх FTUE. Дизайн-решение: **scripted fight заменяет FTUE firstBattle, но FTUE gearUp/exploreDungeon остаются**. Prisma: добавить `tutorialCompleted`. Backend: `/api/tutorial/scripted-fight` endpoint с гарантированным исходом. iOS: `TutorialFightView` + `TutorialFightViewModel`. | 2 дня |
| **W2.D5** | HUB-02 building gating с более мягкой таблицей (Lv1: 5 зданий — добавить Training и Shop в день 1 чтобы gear up loop работал, Lv3: Dungeon, Lv5: BP/Achievements, Lv7: Gold Mine). `BuildingUnlockCeremony.swift` компонент. + HUB-03 `badgePriority` enum. | 1.5 дня |
| **W2 checkpoint** | 🚫 HUB-04 TodayGoalsPanel — **выкинуть из W2**. Дублирует FTUE, требует отдельного дизайна отношений FTUE ↔ Daily goals. Перенести в **W3 или W4** отдельной задачей «daily vs one-time tracker architecture». | — |
| | 🚫 ONB-05 daily login timing — gate на `tutorialCompleted` из W2.D3, сделать в рамках D3. | в D3 |

**Итого:** ~4.25 дня вместо 5. Один лишний день — buffer на неожиданности в tutorial fight (оно по плану уже high-risk).

**Плюсы:**
- Не ломаем работающее
- Реальная user-facing работа: scripted первый бой + building gating — это ощутимые изменения для D1 retention hypothesis
- Честный scope

**Минусы:**
- Отказываюсь от 2 задач плана (TodayGoalsPanel перенос, некоторые polish)
- Нужен `hexbound-studio:flow` + `hexbound-studio:heartbeat` review решения «scripted fight заменяет FTUE firstBattle»

---

### Option C — Только fight + gating (minimal)

Делать только W2.D3 (scripted fight) и W2.D4 (building gating), остальное пометить как done/deferred. ~3.5 дня. Самый низкий риск.

Минус: без D2 lore audit и HUB-03 badges W2 выглядит как полторы задачи.

---

### Option D — Вызвать агентов до выбора

Перед моим решением — запустить:
- `hexbound-studio:flow` → независимый UX review текущего онбординга (есть ли что сжимать ещё)
- `hexbound-studio:heartbeat` → нужен ли scripted tutorial fight или FTUE firstBattle достаточно
- `hexbound-studio:psyche` → что реально двигает D1 retention в текущем flow

И только после их вердиктов — выбирать между B и C.

**Плюс:** независимая валидация, что я не проморгал дефицит.
**Минус:** +1 день orchestration прежде чем начнётся имплементация.

---

## Моя рекомендация

**Option B**, без предварительного агент-run (Option D — избыточен, recon уже достаточен).

Обоснование:
1. Находки жёсткие и проверяемые — это не мнение, это grep/Read от кода
2. Option A создаёт измеримую регрессию
3. Option C слишком минимален — теряем возможность отполировать lore audit
4. Option D тормозит на день ради валидации того, что уже очевидно из grep'ов

Если Артём выберет B:
1. Первый шаг — `W2_D1_REALITY_CHECK.md` (1 час): отдельный короткий отчёт с evidence что D1 уже closed
2. Второй — `W2_D2_LORE_AUDIT.md` (3 часа): lore agent вызывается, смотрим тексты слайдов
3. Третий — дизайн-документ `W2_D3_SCRIPTED_FIGHT_DESIGN.md` (0.5 дня): **review-before-code опять** — я не начну писать scripted fight, пока Артём не одобрит дизайн
4. И только потом — код W2.D3–D5

---

## Вопросы к Артёму (выбери что хочешь ответить)

1. **Option A / B / C / D — твой выбор?**
2. **По Option B (если он):**
   - OK с «scripted fight заменяет FTUE firstBattle» или FTUE должна остаться нетронутой и scripted fight добавляется как ещё одна step ДО FTUE?
   - HUB-02 gating: мягкая таблица (5 зданий на Lv1) или агрессивная из плана (3 зданий на Lv1)?
   - TodayGoalsPanel — действительно выкинуть из W2 или всё-таки держать параллельно FTUE?
3. **Есть ли что-то, что я проглядел?** Я проверил Auth views, Hub config, Tutorial manager, FTUE, backend tutorial routes, Prisma schema, и `WelcomeView`/`LoreIntroView` содержимое. Но я не проверял: `AppRouter` flow между onboarding/lore/hub, нет ли ещё одного слоя navigation. Если там есть что-то важное — ткни меня.
4. **Тебя устраивает документ-first подход** (прежде чем начну W2.D3 писать scripted fight — сделаю `W2_D3_SCRIPTED_FIGHT_DESIGN.md` и тоже покажу тебе)?

---

## Evidence (для аудита моих утверждений)

| Claim | File / grep |
|---|---|
| 3-step wizard, step 1 = race+gender+avatar | `OnboardingViewModel.swift:5` — комментарий + `totalSteps = 3` |
| AppearanceStepView уже объединяет всё | `AppearanceStepView.swift:3` — комментарий «Race + Gender + Avatar selection» + lines 131–213 (avatarArea layout) |
| Gender = icon toggle, не TabSwitcher | `AppearanceStepView.swift:136` — `Image(vm.selectedGender == .male ? "ui-gender-male" : "ui-gender-female")` |
| LoreIntroView уже cinematic 6-slide | `LoreIntroView.swift:22-25` — комментарий + private var slides: [LoreSlide] с backgroundAsset/assets/particlePhase |
| WelcomeView: Guest = primary CTA | `WelcomeView.swift:25-34` — `Text("PLAY AS GUEST")` с `.buttonStyle(.primary(...))` |
| Tutorial infrastructure существует | `find Hexbound -name "Tutorial*"` → 7 файлов (Manager, Tooltip, View, StepCard, QuestBanner, OverlayView, NPCSpeechBubble) |
| FTUE 3-step уже есть | `CityBuildingConfig.swift:3-28` — `enum FTUEObjective` с firstBattle/gearUp/exploreDungeon |
| Backend tutorial routes есть | `find backend/src/app/api/tutorial -type f` → 5 routes (route, step, skip, quest, referral) |
| Нет tutorialCompleted в Prisma | `grep -c "tutorialCompleted" backend/prisma/schema.prisma` → **0** |
| Нет unlockLevel в CityBuilding | `grep "unlockLevel" CityBuildingConfig.swift` → **no match** |
| Нет TodayGoalsPanel файла | `find Hexbound -name "TodayGoals*"` → **no results** |

---

## Статус

⏳ **Waiting for Artem** — выбор Option A/B/C/D и ответы на вопросы.

**Ни одной строки кода не написано** — это чистый recon report. Следующий шаг зависит от твоего ответа.
