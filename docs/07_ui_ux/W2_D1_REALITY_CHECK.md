# W2.D1 — Reality Check: ONB-02 уже сделано

**Дата:** 2026-04-10
**Статус:** ✅ CLOSED (no code changes)
**Исходный plan item:** `QA_FIX_PLAN_2026-04-10.md` W2.D1 — *«ONB-02 part 1: compress gender + appearance into single screen»*

---

## TL;DR

Задача из плана описывает состояние проекта, которого уже нет. Compression gender+appearance **уже реализована** в `AppearanceStepView.swift`, и реализована **в более компактной форме, чем предлагает план** (icon toggle вместо TabSwitcher).

Ни одной строки кода не меняется. Задача помечается как done и закрывается.

Эта заметка существует чтобы: (а) зафиксировать evidence для будущих аудитов, (б) объяснить почему acceptance criteria плана буквально не могут быть выполнены (искомых файлов не существует), (в) дать ссылку для `W2_CHECKPOINT`.

---

## Что говорил план

`QA_FIX_PLAN_2026-04-10.md`, строка ~624:

> **Bug:** 5 отдельных экранов для создания персонажа — слишком длинный funnel.
>
> **Approach:** объединить Gender picker и Appearance picker в один экран с табами «♂ Male / ♀ Female».
>
> **Files to change:**
> 1. Найти `GenderPickerView.swift` и `AppearancePickerView.swift`
> 2. Создать `AppearanceWithGenderView.swift` — объединённый экран с Tab switcher (существующий `TabSwitcher.swift` из DS — 2-tab variant)
> 3. Обновить navigation flow в `OnboardingCoordinator` или `AppRouter`
> 4. Добавить новый файл в pbxproj, удалить старые
>
> **Acceptance criteria:**
> ```bash
> # Старые экраны удалены или объединены
> grep -rn "GenderPickerView\|AppearancePickerView" Hexbound/Hexbound/Views/
>
> # Новый экран существует
> ls Hexbound/Hexbound/Views/**/AppearanceWithGenderView.swift
>
> # pbxproj обновлён
> grep "AppearanceWithGenderView" Hexbound/Hexbound.xcodeproj/project.pbxproj
> ```

---

## Что в реальности

### Wizard уже 3-step, не 5

`Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift:5`:

```swift
// 3-step wizard: 0 = Class, 1 = Appearance (race + gender + avatar), 2 = Name
var step = 0
```

И ниже:

```swift
var totalSteps: Int { 3 }
```

**Step 1 уже объединяет race + gender + avatar** в одном экране — это буквально то, что план просит сделать, только выполнено иначе.

### Искомых файлов не существует

```bash
$ find Hexbound/Hexbound/Views -name "GenderPickerView*"
# (no output)

$ find Hexbound/Hexbound/Views -name "AppearancePickerView*"
# (no output)
```

План ищет файлы, которых никогда не было в том состоянии кода, к которому у меня доступ, или которые были удалены в предыдущих рефакторингах.

### AppearanceStepView уже делает то, что просит план

`Hexbound/Hexbound/Views/Auth/AppearanceStepView.swift:3-8`:

```swift
/// Onboarding Step 2: Race + Gender + Avatar selection with a hero-card preview.
///
/// The central element is an Arena-style hero card (mirrors NameStepView)
/// — level badge, hero summary, class tag, NEW pill, and combined stat bonuses —
/// flanked by the gender toggle + dice on top and prev/next arrows on the bottom.
/// Arrows swap the avatar *inside* the card via a directional slide transition.
```

Layout компонентов в `avatarArea` (строки 126–215):

```
┌────────────────────────────────────────┐
│  [Gender       ]                       │
│  [   ♂/♀      ]                        │
│                ┌───────────────────┐   │
│                │   HERO CARD       │   │
│                │  (200 × 280)      │   │
│                │   avatar slide    │   │
│  [  ←  prev   ]│   transition      │   │
│                │   + stats + class │   │
│                └───────────────────┘   │
│                [ 🎲 dice        ]      │
│                                        │
│                [  →  next       ]      │
├────────────────────────────────────────┤
│         [ Race row: 5 icons ]          │
└────────────────────────────────────────┘
```

Gender переключатель — `AppearanceStepView.swift:134-148`:

```swift
squareButton(
    content: AnyView(
        Image(vm.selectedGender == .male ? "ui-gender-male" : "ui-gender-female")
            .resizable()
            .scaledToFit()
            .frame(width: sideSize * 0.6, height: sideSize * 0.6)
    ),
    size: sideSize,
    bg: DarkFantasyTheme.xpRing.opacity(0.1),
    border: DarkFantasyTheme.xpRing,
    shadow: DarkFantasyTheme.xpRing.opacity(0.2)
) {
    SFXManager.shared.play(.uiTap)
    withAnimation(MotionConstants.snappy) { vm.toggleGender() }
}
```

Avatar pool фильтруется по gender в `OnboardingViewModel.swift:69`:

```swift
let matchesGender = skin.gender == selectedGender.rawValue
```

Это **полное решение задачи ONB-02**. Другое имя компонента, другой UI-примитив (icon toggle вместо TabSwitcher), но цель — gender + appearance + race на одном экране без переключения между screens — достигнута.

---

## Почему icon toggle лучше TabSwitcher (именно здесь)

План предлагал использовать готовый `TabSwitcher.swift` из DS. Я изучил его и считаю что в контексте `AppearanceStepView` замена icon toggle → TabSwitcher **была бы регрессией**:

| Критерий | Current icon toggle | TabSwitcher replacement |
|---|---|---|
| Footprint | 48×48 pt (1 квадрат в колонке) | `maxWidth: .infinity × buttonHeightLG` = ~52pt full width |
| Где размещается | Левая колонка рядом с heroCard, над `←` стрелкой | Сверху или снизу heroCard — сломает двух-колоночный layout |
| Visual language | Единый стиль с dice (🎲) и arrows (←/→) — все в `squareButton` helper'е | Отдельный визуальный блок, не вписывается в 5-кнопочную симметрию |
| Cognitive load | Одна кнопка, tap — swap | Two labels ("MALE" / "FEMALE"), sliding indicator — больше визуального шума |
| Feedback | Image swap + haptic + SFX | Animated indicator slide |
| Touch target | 48×48 (comfortable) | 50+ высота, но разделена на 2 tappable зоны по ½ width каждая — *меньше* на каждую |

Icon toggle выигрывает по footprint, cognitive load и визуальной когерентности с остальными 4 кнопками (dice, arrows). TabSwitcher был бы правильным выбором если бы это был отдельный экран с только gender-селектором — но у нас комбинированный экран.

**Для чего TabSwitcher реально нужен в проекте:** `AchievementsViewModel.swift` использует 3-tab variant для переключения между PvP/Progress/Ranking категориями. Там footprint и семантика tab-bar'а уместна.

---

## Minor polish — что можно сделать (opt-in)

Я **не делаю** это в рамках W2.D1 (не влияет на compression), но фиксирую для будущего:

1. **Accessibility label на gender toggle** — сейчас `squareButton` не получает `accessibilityLabel`. VoiceOver читает как «Button». Должен читать «Gender: Male, double-tap to switch to Female». Простой fix на 2 строки.

2. **Подпись "MALE"/"FEMALE" под иконкой** — новички могут не сразу понять что это переключатель. Можно добавить `Text(vm.selectedGender == .male ? "MALE" : "FEMALE")` под иконкой в 10px badge font. Риск: ломает симметрию с dice/arrows кнопками, которые подписей не имеют.

3. **Cross-fade при смене gender** — сейчас swap резкий (`MotionConstants.snappy`). Cross-fade между male/female аватарами был бы более премиальным, но требует преcache следующего аватара. Low priority.

Любой из этих фиксов можно включить в W2.D5 polish pass или в W4.

---

## Итог

| | |
|---|---|
| **Acceptance criteria плана** | ❌ Не могут быть буквально выполнены — искомых файлов нет |
| **Design intent плана** | ✅ Уже выполнен — step 1 объединяет gender + race + appearance |
| **Код написан** | 0 строк |
| **Файлы изменены** | 0 |
| **Статус** | CLOSED — задача уже сделана в предыдущих рефакторингах |
| **Evidence** | `OnboardingViewModel.swift:5`, `AppearanceStepView.swift:3-8, 126-215`, `grep` для отсутствующих файлов |

**Следующий шаг W2:** W2.D2 — `LoreIntroView` audit + decision (compress vs reorder).

---

## Footnote: урок для будущих планов

`QA_FIX_PLAN_2026-04-10.md` был написан как статичный snapshot. Между составлением плана и началом его исполнения прошло время, за которое часть задач уже решилась. Уроки:

1. **Recon before execute** — перед любым week'ом плана делать recon текущего состояния и писать `REALITY_CHECK.md` если есть расхождения
2. **План — живой документ** — после recon обновлять `QA_FIX_PLAN` с текущим статусом каждого item'а
3. **Evidence-based closure** — закрывать задачи только с grep/Read evidence, не «на глаз»

Эти практики теперь в `MEMORY.md` и будут применяться ко всем week'ам дальше.
