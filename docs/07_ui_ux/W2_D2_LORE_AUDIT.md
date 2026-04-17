# W2.D2 — LoreIntroView audit & decision

**Дата:** 2026-04-10
**Статус:** 🔵 Decision — requires minimal code change (navigation reorder), no content rewrite
**Исходные plan items:** `QA_FIX_PLAN_2026-04-10.md` W2.D2 — *«ONB-04 Welcome lore — cinematic вместо wall-of-text»*

> **Status boundary:** historical audit/decision memo for one onboarding-content discussion. Use it as context, not as the live onboarding narrative spec without checking the current tutorial/onboarding surfaces.

---

## TL;DR

`LoreIntroView.swift` (545 LOC, 6-slide cinematic) **уже соответствует** intent'у плана («cinematic вместо wall-of-text»). Текст хорошо написан (snarky fantasy humor à la Discworld), каждый слайд визуально насыщен (full-bleed background + inline assets + particles), навигация работает.

**Проблема не в содержании, а в позиции в flow.** Сейчас lore показывается **между character creation и hub reveal** — это блокирует dopamine hit на ~60–90 секунд чтения до того, как игрок совершит первое действие. Это противоречит best practice F2P RPG «first minute = power fantasy».

**Моё решение:** **reorder, не rewrite.** Перенести trigger `.loreIntro` из «после character creation» в «после первой победы в scripted tutorial fight» (Epic Seven pattern). Контент сохраняется 1:1, меняется только момент показа.

Код-change: ~5 строк в `OnboardingViewModel.swift` + ~5 строк в месте завершения scripted fight (появится в W2.D3).

---

## Audit текущего состояния

### Структурный обзор

`Hexbound/Hexbound/Views/Auth/LoreIntroView.swift` — 545 LOC, 6 slides:

| # | Title | Body (word count) | Footnote (word count) | BG asset | Inline assets |
|---|---|---|---|---|---|
| 1 | THE CITY OF HEXBOUND | 9 | 8 | `bg-hub` | `building-arena` |
| 2 | THE ARENA RULES ALL | 15 | 19 | `bg-arena` | `building-arena` (140pt) |
| 3 | THINGS BELOW / WANT YOU DEAD | 19 | 10 | `bg-dungeon` | `boss-ghoul-brute-portrait` |
| 4 | GEAR UP OR DIE TRYING | 13 | 10 | `bg-forge` | `wpn_flamebrand` |
| 5 | EVERY LEGEND / STARTED LIKE YOU | 9 | 16 | `bg-arena` | `result-victory` |
| 6 | TIME TO RISE, {HERO} | 7 | 11 | `bg-hub` | `building-ranks` |
| **Total** | | **72 words** | **74 words** | | **~146 words across 6 slides** |

Reading speed средняя 200 wpm → ~44 sec чистого чтения. С curtain transitions и `contentOpacity` анимациями (строки 29–35) — **реальное время прохождения ~60–90 секунд**.

### Visual quality

- Full-bleed background art ✅
- Inline 3D-style game assets поверх background ✅
- Particle effects (`particlePhase`) ✅
- Curtain in/out transitions (`curtainOpacity`) ✅
- Slide offset animation (`slideOffset`) ✅
- Content fade + upward slide (`contentOpacity` + `assetsOffsetY`) ✅

Это **полноценный cinematic experience**. План ожидал увидеть wall-of-text и просил сделать cinematic — реальность уже это делает.

### Quality of writing

Я не буду цитировать текст целиком, но каждая фраза — осознанно комедийная, с self-aware tone: *«and frankly — it smells a little»*, *«categorically denies it»*, *«songs are sung about them. Embarrassing ones, but still.»* Этот стиль consistent с brand voice Hexbound (grimdark + humor) и удалять его — потеря.

**Это хороший текст.** Его нельзя выкидывать.

### Где триггерится в flow

Navigation chain:

```
OnboardingViewModel.finalizeCreation()
  ↓ (line 401)
appState.currentScreen = .loreIntro(heroName: character.characterName)
  ↓ (HexboundApp.swift:24 routes)
LoreIntroView(heroName:)
  ↓ (user swipes through 6 slides)
  ↓ (line 500)
appState.currentScreen = .game
  ↓
CityMapView (hub)
```

**Проблема:** между первым character creation и hub reveal проходит 60–90 секунд без interaction. Новичок не сделал ни одного значимого действия, а уже «ослаблен» длинной cutscene. Это противоречит правилу F2P — **first meaningful action ≤ 60 секунд от tap «PLAY AS GUEST»**.

---

## Three options considered

### Option R — Reorder (рекомендую)

Переставить lore из *между creation и hub* в *после scripted tutorial victory*.

**Новый flow:**

```
Welcome → Class → Appearance → Name
  ↓
[NEW] CinematicOpenIntro (≤ 20 sec, ≤ 2 slides, skippable)
  ↓
[NEW] Scripted Tutorial Fight (guaranteed win, ~60 sec)
  ↓
[NEW] Victory overlay with reward
  ↓
LoreIntroView (6 slides, existing — moved here) ← НОВАЯ ПОЗИЦИЯ
  ↓
Daily Login popup (gated on tutorialCompleted)
  ↓
CityMapView (hub)
```

**Плюсы:**
- Сохраняет весь текст и визуал (zero content loss)
- Lore теперь показывается на эмоциональном high после первой победы — максимальная receptivity к narrative
- Epic Seven / Raid: Shadow Legends pattern — **доказан** на ретеншене (Epic Seven D1 ~55%, что очень высоко для Gacha RPG)
- Dopamine hit раньше → первые 60 сек игры теперь насыщены действием
- Cheap implementation: ~10 LOC navigation change

**Минусы:**
- Без cold-open хотя бы minimal cinematic игрок может быть confused *«кто я, где я, зачем сражаюсь?»* перед scripted fight → нужна **короткая 1–2 slide intro** (см. ниже Option R+)
- Требует завершённого scripted fight flow (зависимость от W2.D3)

**Implementation:**

```swift
// OnboardingViewModel.swift:401 — BEFORE
appState.currentScreen = .loreIntro(heroName: character.characterName)

// OnboardingViewModel.swift:401 — AFTER
appState.currentScreen = .cinematicOpen(heroName: character.characterName)
// → .cinematicOpen → .scriptedTutorial → .victoryOverlay → .loreIntro → .dailyLogin → .game
```

`AppState.swift` получает новые кейсы: `.cinematicOpen`, `.scriptedTutorial`, `.victoryOverlay`, `.dailyLogin`. После `LoreIntroView` flow продолжается в hub.

### Option R+ — Reorder + добавить cold-open (лучший вариант, рекомендую)

Option R страдает от проблемы «игрок не знает зачем сражаться» перед scripted fight. Добавляем **очень короткий cold-open cinematic**: 1–2 слайда, ≤ 15 секунд total, skippable с первого тапа.

**Cold-open содержание** (новый компонент, не часть LoreIntroView):
- Slide 1: *«The Arena has called. One rise, one fall.»* + фон `bg-arena` + silhouette противника
- Slide 2 (optional): *«Show them who you are, {HERO}.»* + фон `bg-arena` + hero silhouette

Это **hook**, не lore. 15 секунд максимум. Достаточно чтобы понять контекст, но не блокирует dopamine hit.

Затем — scripted tutorial fight.
Затем — victory overlay.
Затем — **полный 6-slide LoreIntroView как reward для игрока**. *«Ты победил. А теперь — вот твой мир.»*

**Implementation:**

Создать новый компонент `Hexbound/Hexbound/Views/Onboarding/CinematicOpenView.swift` (~150 LOC, переиспользует слайд-инфраструктуру из `LoreIntroView` через shared protocol).

**Это мой рекомендуемый вариант.**

### Option C — Compress (не рекомендую)

Сократить `LoreIntroView` до 3 слайдов, объединив thematic beats:
- Slide 1: City + Arena → «City ruled by Arena»
- Slide 2: Dungeons + Gear → «Die below, forge above»
- Slide 3: Legend + Rise → «Every legend started broken. Your turn, hero.»

**Плюсы:**
- Короче (≤ 30 sec total)
- Не требует reorder (оставляем trigger на прежнем месте)

**Минусы:**
- **Теряем witty texts** — лучшая часть контента
- Всё равно блокирует первые 30 секунд без action
- Compression уничтожает ритм повествования (6 слайдов работают как cадcadencia: City → Arena → Dungeons → Forge → Legend → You. Сжатие в 3 слайда — информационный брикет)
- Dope pattern «first dopamine hit» всё равно нарушен

### Option D — Compress + reorder (max compliance)

Сжать до 3 слайдов И перенести после first victory. Формально максимально соответствует best practice.

**Минусы:**
- Убирает эмоциональный peak lore (когда игрок готов к narrative, мы показываем компрессию — это странный trade-off)
- Реализация сложнее (compression требует rewriting, review, approval на тексты)
- Двойная рискованная изменение в один sprint

### Итоговое решение: **Option R+ (Reorder + Cold-Open)**

Уверенность: **высокая.** Обоснование:
1. Сохраняет весь написанный контент (это работа narrative designer'а, её нельзя выкидывать)
2. Cold-open решает проблему «нет контекста перед боем» (15 сек — приемлемая цена)
3. Lore после победы использует эмоциональную receptivity игрока (proven Epic Seven pattern)
4. Cheap implementation относительно написания нового контента
5. Масштабируемо: архитектура cinematic slide infrastructure (slide + background + assets + particles) теперь может переиспользоваться для pre-dungeon cinematic, chapter intro'ов, event launches

---

## Architecture для масштабируемости (важно для «качественный и масштабируемый продукт»)

Сейчас в `LoreIntroView.swift` слайд-инфраструктура **вшита в конкретный view**. Это блокирует переиспользование.

### Рефактор: вынести slide infrastructure в shared component

Создать новый файл `Hexbound/Hexbound/Views/Onboarding/CinematicSlideView.swift`:

```swift
import SwiftUI

/// Generic cinematic slide presenter — reusable for:
/// - Onboarding cold-open (W2.D2)
/// - Lore intro (W2.D2, repositioned)
/// - Chapter transitions (future W5+)
/// - Boss fight intro cinematics (future W5+)
/// - Event launch cinematics (future LiveOps)
struct CinematicSlide {
    let backgroundAsset: String
    let assets: [SlideAsset]
    let accentColor: Color
    let title: String
    let body: String
    let footnote: String?

    struct SlideAsset {
        let name: String
        let size: CGFloat
        let offsetY: CGFloat
    }
}

struct CinematicSlideView: View {
    let slides: [CinematicSlide]
    let onComplete: () -> Void
    let autoAdvance: Bool  // false = swipe, true = timer-based
    let autoAdvanceDuration: TimeInterval  // 5.0 default

    // ... existing animation state from LoreIntroView ...
}
```

**Миграция:**
1. Создать `CinematicSlideView.swift` с общей infrastructure
2. Перевести `LoreIntroView` на использование `CinematicSlideView(slides: loreSlides, onComplete: { appState.currentScreen = .game })` — становится 30-LOC wrapper
3. Создать `CinematicOpenView.swift` как второй wrapper с 1–2 слайдами для cold-open
4. Будущие cinematics (chapter intros, boss intros) — просто передают свои `slides: [CinematicSlide]`

**Это именно то, что делает продукт масштабируемым:** один раз написанная slide engine обслуживает все cinematic моменты игры. Без этого каждый новый cinematic будет duplicate 545 LOC из `LoreIntroView`.

**Расчёт затрат:**
- Extract + rewire `LoreIntroView`: ~3 часа
- New `CinematicOpenView`: ~2 часа
- Navigation reorder: ~1 час
- Total W2.D2: **~0.75 дня** (6 часов)

---

## Implementation plan (для approval)

Порядок шагов (НЕ начинаю без одобрения Артёма):

### Step 1: Extract slide infrastructure (3ч)
1. Create `Hexbound/Hexbound/Views/Components/Cinematic/CinematicSlideView.swift`
2. Move `LoreSlide` → `CinematicSlide` (rename + make public)
3. Move animation state (curtainOpacity, slideOffset, contentOpacity, particlePhase) into `CinematicSlideView`
4. Provide `onComplete: () -> Void` callback
5. Add to pbxproj (4 sections + unique hex IDs via `openssl rand -hex 12`)

### Step 2: Refactor LoreIntroView (1.5ч)
1. `LoreIntroView` становится 30-LOC wrapper:
   ```swift
   struct LoreIntroView: View {
       let heroName: String
       @Environment(AppState.self) private var appState
       var body: some View {
           CinematicSlideView(
               slides: Self.loreSlides(heroName: heroName),
               onComplete: { appState.currentScreen = .game },
               autoAdvance: false,
               autoAdvanceDuration: 0
           )
       }
       private static func loreSlides(heroName: String) -> [CinematicSlide] { /* existing 6 slides */ }
   }
   ```
2. Verify all 6 slides render идентично оригиналу через `get_screenshot` preview

### Step 3: Create CinematicOpenView (2ч)
1. `Hexbound/Hexbound/Views/Onboarding/CinematicOpenView.swift`
2. Two slides:
   - Slide 1: title = «THE ARENA CALLS», body = «One rise, one fall.», bg = `bg-arena`, asset = none (pure ambient)
   - Slide 2: title = «SHOW THEM WHO YOU ARE», body = «{HERO}», bg = `bg-arena`, asset = `hero silhouette`
3. `onComplete: { appState.currentScreen = .scriptedTutorial }`
4. Auto-advance = true, duration = 5.0 sec per slide
5. Skippable: tap anywhere → next slide / exit
6. Add to pbxproj

### Step 4: Navigation rewire (1.5ч)
1. `AppState.swift` — add states: `.cinematicOpen(heroName: String)`, `.scriptedTutorial`, `.victoryOverlay(reward: TutorialReward)`, `.dailyLogin`
2. `OnboardingViewModel.swift:401`:
   ```swift
   // BEFORE: .loreIntro(heroName: name)
   // AFTER:  .cinematicOpen(heroName: name)
   ```
3. `HexboundApp.swift` — route all new states
4. Scripted fight completion → `.victoryOverlay` → `.loreIntro` (existing state, repositioned) → `.dailyLogin` → `.game`

### Step 5: Verify & test (manual QA by Artem)
1. Full replay: guest login → class → appearance → name → cinematic open (15s) → scripted fight (60s) → victory → lore (60–90s) → daily login → hub
2. Total time target: ≤ 4 minutes (acceptable given scripted fight is 60s)
3. Skip buttons работают на всех cinematic stages
4. `.loreIntro` рендерится идентично оригиналу

### Step 6: Agent review
- `hexbound-studio:guardian` — SwiftUI compliance new files
- `hexbound-studio:flow` — new UX timing
- `hexbound-studio:ember` — cold-open text proposals
- `hexbound-studio:lore` — verify cold-open tonally matches lore voice

---

## Dependencies

- **W2.D2 Step 4** depends on **W2.D3** (scripted tutorial fight must exist to route `.scriptedTutorial` state)
- **Solution:** implement Step 1–3 first (extraction + cold-open + lore refactor), then W2.D3 scripted fight, then Step 4 navigation rewire when scripted fight is ready

**Order of execution:**
1. W2.D2 Step 1–3 (extract + cold-open + lore refactor)
2. W2.D3 (scripted fight — biggest item)
3. W2.D2 Step 4 (navigation rewire — connects everything)
4. W2.D4–D5 (gating + badges)
5. W2 checkpoint

---

## Questions for Artem (BLOCKING — design-level decisions)

1. ✅/❌ **Option R+ (Reorder + Cold-Open) — твой выбор**?
2. ✅/❌ **Extract slide infrastructure в `CinematicSlideView.swift`** — важный рефактор для масштабируемости, согласен ли на ~3 часа этой работы сейчас, чтобы потом chapter intros / boss cinematics / event launches **не дублировали 545 LOC**?
3. **Cold-open тексты** — я предлагаю:
   - Slide 1: «THE ARENA CALLS / One rise, one fall.»
   - Slide 2: «SHOW THEM WHO YOU ARE / {HERO}.»
   Или хочешь чтобы я вызвал `hexbound-studio:lore` + `hexbound-studio:ember` для tone-matched variants? (добавит ~0.5 дня)
4. ✅/❌ **Skip everywhere** — cinematic open и lore intro — оба тапабельны для skip?

---

## Risk assessment

| Risk | Severity | Mitigation |
|---|---|---|
| `LoreIntroView` refactor ломает existing animation feel | 🟡 Medium | Сделать extract bit-identical, через `get_screenshot` сравнить до/после. Если mismatch → revert extract, только navigation reorder |
| Cold-open тексты не попадают в tone | 🟢 Low | Можно итеративно править, это 2 строки. Вызвать lore/ember агентов на validation |
| Navigation rewire вводит regression (back button, state transitions) | 🟡 Medium | Test matrix: каждый новый state → verify back button disabled (это one-way flow), no orphan states |
| Scripted fight задерживает W2.D2 Step 4 | 🟢 Low | Step 1–3 могут быть залиты отдельно, даже без Step 4 Lore просто остаётся на старой позиции пока scripted fight не готов (no breakage) |
| Перенос lore ломает текущие тесты / save state | 🟢 Low | `LoreIntroView` не хранит state в persistence, только локальные `@State` — безопасно |

---

## Expected impact

- **Первые 60 секунд игры** теперь включают scripted fight вместо 60–90 секунд чтения → **dopamine hit → да**
- **D1 retention hypothesis:** +3–7% от только этого изменения (lore reorder). Основной вклад в retention — от scripted fight (D3), не от lore reorder
- **Масштабируемость:** `CinematicSlideView` как reusable engine — **значительный long-term win**. Без неё каждый будущий cinematic — это duplicate 545 LOC

---

## Файлы, которые будут затронуты

### Новые
- `Hexbound/Hexbound/Views/Components/Cinematic/CinematicSlideView.swift` (~200 LOC)
- `Hexbound/Hexbound/Views/Onboarding/CinematicOpenView.swift` (~80 LOC)

### Изменённые
- `Hexbound/Hexbound/Views/Auth/LoreIntroView.swift` (-450 LOC, becomes thin wrapper)
- `Hexbound/Hexbound/App/AppState.swift` (+4 enum cases)
- `Hexbound/Hexbound/App/HexboundApp.swift` (+4 route cases)
- `Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift` (1 line: `.loreIntro` → `.cinematicOpen`)
- `Hexbound/Hexbound.xcodeproj/project.pbxproj` (4 sections × 2 new files = 8 entries)

### Документация
- `docs/07_ui_ux/W2_D2_LORE_AUDIT.md` ← this doc
- `docs/07_ui_ux/SCREEN_INVENTORY.md` ← update with new CinematicOpenView entry
- Обновить диаграмму flow в `docs/07_ui_ux/UX_AUDIT.md` если есть

---

**Status:** ⏳ Waiting for Artem approval (4 вопроса выше). Ни одной строки кода не написано.
