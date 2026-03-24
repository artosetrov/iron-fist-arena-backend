# Multi-Hero Integration Plan

> **Статус:** План + прототип
> **Дата:** 2026-03-24
> **Автор:** Claude + Артём

## TL;DR

Бэкенд уже поддерживает 1:Many (User → до 5 Character). iOS-клиент написан как 1:1. Нужно вставить экран выбора героя между авторизацией и Hub, добавить switch/create в Settings.

---

## Текущий флоу

```
App Launch → Keychain tokens? → AuthService.tryAutoLogin()
  → loadCharacter() → takes FIRST character → isAuthenticated=true → Hub
```

**Проблема:** `loadCharacter()` вызывает `GET /api/characters` и берёт `characters[0]`. Нет выбора.

## Целевой флоу

```
App Launch → Keychain tokens? → AuthService.tryAutoLogin()
  → loadCharacters() → returns [Character]
    → 0 heroes  → CharacterSelection (empty state + "Создать героя")
    → 1 hero    → auto-select → GameInit → Hub (сохраняем быстрый вход)
    → 2+ heroes → CharacterSelection (список + "Войти в игру")

CharacterSelection:
  → Tap hero + "Войти в игру" → selectCharacter(id) → GameInit → Hub
  → "Создать героя" → Onboarding → CharacterSelection
  → [Guest] "Создать аккаунт" → Register flow

Settings:
  → "Сменить героя" → CharacterSelection
  → "Создать героя" → Onboarding (if slots < 5)
```

**Оптимизация:** Если у юзера ровно 1 герой — пропускаем экран выбора, сразу в Hub (как сейчас). Это сохраняет быстрый onboarding для новых игроков.

---

## Изменения по файлам

### Phase 1: iOS — Новый экран выбора героя

#### 1.1 `CharacterSelectionView.swift` (NEW)
- **Путь:** `Hexbound/Hexbound/Views/Auth/CharacterSelectionView.swift`
- **Описание:** Список героев юзера, кнопка создать, кнопка войти
- **Модель:** `CharacterSelectionViewModel` (в том же файле или отдельно)
- **Данные:** Загружает `GET /api/characters`, показывает карточки
- **Компоненты:** Переиспользует `RadialGlowBackground`, `OrnamentalTitle`, corner brackets
- **Guest баннер:** Если `appState.isGuest` — показать предупреждение + кнопку "Создать аккаунт"
- **Empty state:** Если heroes = 0, большая CTA "Создать первого героя"
- **Не забыть:** Добавить в `project.pbxproj` (4 секции!)

#### 1.2 `CharacterSelectionViewModel.swift` (NEW)
- **Путь:** `Hexbound/Hexbound/ViewModels/CharacterSelectionViewModel.swift`
- **Свойства:**
  - `characters: [CharacterSummary]` — список героев
  - `selectedCharacterId: String?` — выбранный
  - `isLoading: Bool`
  - `error: String?`
  - `slotsUsed: Int` (из characters.count)
- **Методы:**
  - `loadCharacters()` — `GET /api/characters`
  - `selectAndEnter(characterId:)` — выбрать + вызвать GameInit
  - `deleteCharacter(id:)` — (Phase 2)
- **Не забыть:** Добавить в `project.pbxproj`

#### 1.3 `CharacterSummary.swift` (NEW, optional)
- **Путь:** `Hexbound/Hexbound/Models/CharacterSummary.swift`
- **Описание:** Лёгкая модель для списка выбора (id, name, class, origin, level, avatar, pvpRating, currentHp, maxHp)
- **Альтернатива:** Можно использовать существующий `Character` — он уже содержит все поля. Но он тяжёлый.
- **Решение:** Использовать `Character` напрямую — бэкенд уже возвращает полные объекты через `GET /api/characters`

### Phase 2: iOS — Изменения навигации

#### 2.1 `AppRouter.swift` — добавить роут
```swift
case characterSelection  // новый роут
```

#### 2.2 `AppState.swift` — новый стейт
```swift
// Новые свойства:
var userCharacters: [Character] = []  // все герои юзера
var selectedCharacterId: String?       // выбранный герой

// Новый промежуточный стейт:
// isAuthenticated = true, currentCharacter = nil → показать CharacterSelection
// isAuthenticated = true, currentCharacter != nil → показать Hub
```

**Или проще:** Добавить enum `AppScreen`:
```swift
enum AppScreen {
    case auth           // не залогинен
    case characterSelect // залогинен, герой не выбран
    case game           // залогинен, герой выбран → Hub
}
```

#### 2.3 `HexboundApp.swift` — обновить корневой switch
```swift
// Было:
if appState.isAuthenticated { MainRouterView() }
else { AuthRouterView() }

// Стало:
switch appState.currentScreen {
case .auth: AuthRouterView()
case .characterSelect: CharacterSelectionView()
case .game: MainRouterView()
}
```

#### 2.4 `AuthService.swift` — изменить `tryAutoLogin()`
```swift
// Было: loadCharacter() → берёт first, ставит currentCharacter
// Стало: loadCharacters() → возвращает массив
//   if count == 1 → auto-select, return .hasCharacter
//   if count == 0 → return .noCharacter (→ CharacterSelection с empty state)
//   if count >= 2 → return .multipleCharacters (NEW)
```

Добавить новый результат `AutoLoginResult`:
```swift
enum AutoLoginResult {
    case hasCharacter      // 1 герой, auto-selected
    case multipleCharacters // 2+ героев, нужен выбор
    case noCharacter       // 0 героев
    case noTokens          // не залогинен
}
```

#### 2.5 `GameInitService.swift` — параметризовать
Уже принимает `character_id` — просто убедиться, что он берётся из `selectedCharacterId`, а не из `currentCharacter.id` (для случая переключения).

### Phase 3: iOS — Settings

#### 3.1 `SettingsDetailView.swift` — добавить кнопки
В секцию "Account" добавить:
- **"Сменить героя"** — `appState.switchToCharacterSelection()` (сбрасывает currentCharacter, показывает CharacterSelectionView)
- **"Создать нового героя"** — если `userCharacters.count < 5`, навигация в Onboarding

#### 3.2 `SettingsViewModel.swift` — добавить данные
- `characterCount: Int` (из `appState.userCharacters.count`)
- `canCreateNewHero: Bool` (count < 5)

### Phase 4: Backend (минимально)

#### 4.1 `GET /api/characters` — уже работает ✅
Возвращает все героев юзера, сортировка по `createdAt desc`.

#### 4.2 `POST /api/characters` — уже работает ✅
Создаёт нового героя, лимит 5. После создания iOS должен вернуться на CharacterSelection (не в Hub).

#### 4.3 `DELETE /api/characters/:id` — (NEW, Phase 2)
- Удаление героя (с подтверждением на клиенте)
- Нельзя удалить последнего героя? Или можно? (Решить)
- Каскадное удаление: inventory, quests, combat history
- Проверка: `character.userId === authUser.id`

#### 4.4 `GET /api/game/init` — уже принимает `character_id` ✅
Работает как есть.

---

## UX-решения

### Auto-select при 1 герое
Если у юзера ровно 1 герой — пропускаем экран выбора, сразу GameInit → Hub. Это сохраняет текущий быстрый вход для 95% юзеров.

### Onboarding возвращает на CharacterSelection
После создания героя через Onboarding — возвращаемся на список героев (не в Hub). Юзер видит нового героя в списке и может сразу войти.

### Guest баннер
На экране выбора героя для гостей — заметный, но не блокирующий баннер с кнопкой "Создать аккаунт". Не пушим агрессивно, но даём понять, что прогресс не в безопасности.

### Swipe-to-delete (Phase 2)
Свайп влево на карточке героя → кнопка "Удалить" → confirmation sheet.

---

## Порядок реализации

1. **Phase 1A** — `CharacterSelectionView` + `CharacterSelectionViewModel` (UI)
2. **Phase 1B** — `AppState` / `AppRouter` / `HexboundApp` (навигация)
3. **Phase 1C** — `AuthService.tryAutoLogin()` обновление
4. **Phase 1D** — Settings (кнопки switch/create)
5. **Phase 2** — DELETE endpoint + swipe-to-delete
6. **Phase 3** — Анимации переключения, polish

## Файлы для создания
- `Hexbound/Hexbound/Views/Auth/CharacterSelectionView.swift` (NEW)
- `Hexbound/Hexbound/ViewModels/CharacterSelectionViewModel.swift` (NEW)

## Файлы для изменения
- `Hexbound/Hexbound/App/AppState.swift`
- `Hexbound/Hexbound/App/AppRouter.swift`
- `Hexbound/Hexbound/App/HexboundApp.swift`
- `Hexbound/Hexbound/Services/AuthService.swift`
- `Hexbound/Hexbound/Views/Settings/SettingsDetailView.swift`
- `Hexbound/Hexbound/Views/Settings/SettingsViewModel.swift`
- `Hexbound/Hexbound.xcodeproj/project.pbxproj` (2 new files → 8 entries)

## Файлы НЕ затронутые
- Backend routes — уже поддерживают multi-hero
- `GameInitService` — уже параметризован по `character_id`
- `GameDataCache` — данные кэшируются per-character через GameInit
- Все game views (Arena, Shop, Dungeon, etc.) — они работают с `appState.currentCharacter`, который будет просто установлен после выбора
