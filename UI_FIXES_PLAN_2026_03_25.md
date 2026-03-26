# UI/UX Fixes Plan — 2026-03-25

> 20 задач, 4 волны, ~8-10 часов

---

## Wave 1: Quick Fixes (5-10 мин каждая)

### 1. Leaderboard — убрать плашку "Your Position"
- **Файл:** `LeaderboardDetailView.swift` (строки 155-191)
- **Что:** Удалить секцию `yourRankBanner` — занимает место, не несёт ценности
- **Риск:** Нулевой
- **Время:** 5 мин

### 2. Item Detail — перенести rarity на отдельную строку
- **Файл:** `ItemDetailSheet.swift` (строки 180-185)
- **Что:** HStack `[itemType] [rarity]` → VStack `[itemType]` / `[rarity]`
- **Проблема:** "Uncommon" переносится по слогам на маленьких экранах
- **Время:** 5 мин

### 3. Arena — UI растягивается при входе
- **Файл:** `ArenaDetailView.swift`
- **Диагноз:** `.transaction { $0.animation = nil }` уже на месте (строка 117). Скорее всего проблема в том, что `UnifiedHeroWidget` или другие вложенные компоненты получают данные асинхронно и меняют layout. Нужно проверить, не приходят ли данные с задержкой, которая вызывает перерисовку.
- **Fix:** Добавить skeleton/placeholder state с фиксированными размерами для всех секций до загрузки данных
- **Время:** 15 мин

### 4. Victory — кнопка "Send Message" не по дизайну
- **Файл:** `BattleResultCardView.swift` (строки 583-622)
- **Что:** Кнопка "SEND MESSAGE" использует `.ghost` style (прозрачная, без хрома). Нужно заменить на `.secondary` — полноценная кнопка с рамкой и фоном
- **Fix:** В `CombatResultDetailView` строка 134: `style: .ghost` → `style: .secondary`
- **Время:** 5 мин

### 5. Gold Mine Claim — оптимистичный UI
- **Файл:** `GoldMineViewModel.swift` (строки 80-105)
- **Диагноз:** Код уже оптимистичный! Проблема может быть в `actionSlotId` показывающем спиннер ДО обновления UI. Нужно убрать спиннер, обновить UI мгновенно, API вызвать в фоне
- **Fix:** Переместить `withAnimation { ... }` и toast ПЕРЕД `await` вызовом API
- **Время:** 10 мин

---

## Wave 2: Medium Fixes (15-30 мин каждая)

### 6. Character Selection — аватарка не грузится
- **Файл:** `CharacterSelectionView.swift` (строки 413-419), `AvatarImageView.swift`
- **Диагноз:** `AvatarImageView` пытает найти local asset → remote fallback → emoji. Если `character.avatar` содержит ключ, но ассета нет локально, и URL не резолвится — падает на emoji
- **Fix:** Проверить что AvatarImageView корректно строит URL из `avatar` ключа. Возможно нужен fallback на `portraitAsset` computed property
- **Время:** 20 мин

### 7. UnifiedHeroWidget — обновить до ornamental дизайна
- **Файл:** `UnifiedHeroWidget.swift` (строки 66-77)
- **Что:** Сейчас простой `.fill(bgCardGradient)` + 1px stroke. Нужно обновить до standard panel pattern:
  - `RadialGlowBackground` вместо flat fill
  - `.surfaceLighting()`
  - `.innerBorder()`
  - `.cornerBrackets()`
  - `.compositingGroup()`
  - `.shadow()`
- **Влияние:** Виджет используется на: Shop, Arena, Dungeon, Hero — все экраны обновятся
- **Время:** 20 мин

### 8. Guild Hall — аватарки в списке друзей
- **Файл:** `GuildHallDetailView.swift` (строки 1422-1432)
- **Диагноз:** `characterAvatar()` показывает только первую букву имени на тёмном фоне. Не использует `AvatarImageView` или портрет
- **Fix:** Заменить на `AvatarImageView(skinKey: friend.avatar, ...)` — но нужно проверить, что `FriendEntry` модель содержит поле `avatar`. Если нет — добавить на бэкенд
- **Время:** 25 мин (может потребовать backend change)

### 9. Chat — аватарка собеседника в header
- **Файл:** `GuildHallDetailView.swift` (строки 796-799)
- **Что:** Сейчас тоже первая буква имени. Заменить на `AvatarImageView` + возможно мини-виджет героя (уровень, класс, рейтинг)
- **Время:** 20 мин

### 10. Chat — убрать timestamps, добавить read status
- **Файл:** `GuildHallDetailView.swift` (строки 849-854)
- **Что:** Убрать `formatRelativeTime()`. Вместо этого — маленькая галочка или "Read" под последним сообщением
- **Проблема:** Нужно проверить, есть ли `isRead` поле на `DirectMessageItem` модели
- **Время:** 15 мин

### 11. Chat — quick replies как bubbles в чате
- **Файл:** `GuildHallDetailView.swift` (строки 887-908)
- **Что:** Перенести horizontal ScrollView с quick replies из compose bar наверх — как фоновые bubble-подсказки в пустом чате или как floating chips над input
- **Время:** 20 мин

### 12. Chat — два back button, стилизация
- **Файл:** `GuildHallDetailView.swift` (строки 63-77, 786-793)
- **Что:** Убрать стрелку рядом с аватаркой (thread header chevron). Оставить только toolbar back button, но заменить SF Symbol `chevron.left` на кастомный ассет (как на других страницах)
- **Время:** 10 мин

---

## Wave 3: Bigger Changes (30-60 мин)

### 13. Victory → Message — не показывать Guild Hall
- **Файл:** `CombatResultDetailView.swift` (строки 134-150), `AppRouter.swift`
- **Диагноз:** Сейчас навигация: combat → guildHall(openMessageTo:) → auto-opens thread. Пользователь видит мелькание GuildHall экрана
- **Fix варианты:**
  - A) Добавить отдельный route `AppRoute.directMessage(characterId:, characterName:)` → показывает только чат без Guild Hall shell
  - B) GuildHallDetailView: если `openMessageTo != nil` — не рендерить табы и контент гильдии, сразу показать thread full-screen
- **Предпочтительно:** Вариант B — меньше изменений
- **Время:** 30 мин

### 14. Chat — клавиатура открывается медленно
- **Файл:** `GuildHallDetailView.swift` (строки 912-915)
- **Что:** Добавить `@FocusState` на TextField и установить `.focused(true)` при открытии thread. Также проверить что нет тяжёлых вычислений при открытии чата
- **Время:** 15 мин

### 15. Chat — отправка сообщения моментально (optimistic)
- **Файл:** `GuildHallViewModel` или аналогичный
- **Что:** Добавить сообщение в список мгновенно (с временным ID), показать его в чате, отправить API в фоне. При ошибке — показать retry
- **Время:** 25 мин

### 16. Enter Game — preloader при входе
- **Файл:** `CharacterSelectionView.swift` (строки 195-216)
- **Что:** Сейчас просто текст "ENTERING..." — нужен полноценный оверлей как heroCreationOverlay в OnboardingDetailView: затемнение + модал с анимацией + текст "Entering the Realm..."
- **Время:** 20 мин

### 17. Appearance Editor — добавить кнопку смены персонажа
- **Файл:** `AppearanceEditorDetailView.swift`
- **Что:** Добавить кнопку "Switch Character" / "Change Hero" которая ведёт на `CharacterSelectionView` (route `.characterSelection`)
- **Время:** 15 мин

### 18. Appearance Editor — dice рандомизирует только текущий пол
- **Файл:** `AppearanceEditorViewModel.swift` (строки 170-180)
- **Диагноз:** `randomize()` уже рандомизирует только текущий origin+gender. Но user говорит что меняется и пол. Нужно проверить — возможно баг в том что `randomize()` случайно меняет `selectedGender`
- **Fix:** Убедиться что `randomize()` НЕ трогает gender/origin, только скин
- **Время:** 15 мин

### 19. Onboarding — показывать стат-бонусы при смене расы
- **Файл:** Экран выбора расы в onboarding flow (OriginStepView или AppearanceStepView)
- **Что:** Добавить grid стат-бонусов (как в NameStepView) — с иконками, полными именами, красивыми ячейками
- **Время:** 25 мин

### 20. Новый персонаж не появляется в списке
- **Файл:** `CharacterSelectionView.swift`
- **Диагноз:** `loadCharacters()` вызывается в `.task {}` — это однократно при первом appear. Если пользователь создал персонажа и вернулся — `.task` не перезапустится
- **Fix:** Добавить `.onAppear { Task { await vm.loadCharacters() } }` или использовать `.task(id:)` с триггером
- **Время:** 10 мин

---

## Dependency Graph

```
Волна 1: [1] [2] [3] [4] [5] — все независимые
Волна 2: [6] [7] [8→9] [10] [11] [12]
Волна 3: [13→14→15] [16] [17] [18] [19] [20]
```

- 8→9: Обе задачи про аватарки в GuildHall, делать вместе
- 13→14→15: Все про чат-flow, делать последовательно

## Оценка времени

| Волна | Задачи | Время |
|-------|--------|-------|
| Wave 1 | 5 задач | ~40 мин |
| Wave 2 | 7 задач | ~2 часа |
| Wave 3 | 8 задач | ~2.5 часа |
| **Итого** | **20 задач** | **~5 часов** |

## Риски

- **Backend changes (8, 9, 10, 15)** — если модели не содержат нужных полей (avatar, isRead), потребуется менять API
- **Arena stretch (3)** — причина может быть не в `.transaction`, а в NavigationStack + данные. Может потребовать более глубокого debug
- **Chat optimistic (15)** — нужна аккуратная работа с временными ID и revert при ошибке
