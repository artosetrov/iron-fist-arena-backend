# Hexbound — Full Product Audit

*Дата: 2026-03-21. Все 5 агентов запущены параллельно.*

---

## Общий вердикт: ⛔ NEEDS FIXES

| Агент | Статус | Ключевое |
|-------|--------|----------|
| **Swift Review** | ⚠️ 160 issues | 90+ кнопок без `.buttonStyle()`, 193 hardcoded colors, 18 emoji в UI |
| **Backend Review** | ⛔ CRITICAL | 282 missing `await`, 4 junk-директории, schema sync ✅ |
| **UX Audit** | ⚠️ 6.5/10 | 0 accessibility labels, missing error/empty states, 193 color violations |
| **Preflight** | ⛔ NEEDS FIXES | 10 junk-файлов, missing await в game/init, 103 design system violations |
| **Build Verify** | ⛔ BUILD BROKEN | 4 Swift-файла не в pbxproj, 68 hardcoded colors, 204 system fonts |

---

## 🔴 CRITICAL (Блокеры билда / крэши)

### 1. Четыре Swift-файла отсутствуют в pbxproj
iOS проект НЕ СКОМПИЛИРУЕТСЯ:
- `EmailConfirmationView.swift`
- `UpgradeGuestView.swift`
- `GuestGateView.swift`
- `GuestNudgeBanner.swift`

**Фикс:** Добавить в `project.pbxproj` (4 секции: PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase).

### 2. 282 missing `await` в бэкенде
Системная проблема: `get*Config()` и Prisma-запросы вызываются без `await`.

**Самый критичный файл:** `backend/src/app/api/game/init/route.ts` (строки 249-260) — 11 config-функций в `Promise.all()` без `await`. Возвращают Promise-объекты вместо значений → runtime crash.

**Другие горячие точки:**
- `pvp/fight/route.ts` (5 missing)
- `pvp/resolve/route.ts` (5 missing)
- `shop/offers/route.ts` (множественные Prisma без await)
- `admin/src/actions/dashboard.ts` (55+ missing)

### 3. Junk-файлы с " 2" в названиях
10 файлов/директорий в source tree (не node_modules):
- `backend/src/app/api/mail/[id] 2`
- `backend/src/app/api/mail/unread-count 2`
- `admin/src/app/api/admin/item-balance 2`
- `Hexbound/ART_STYLE_GUIDE 2.md`
- `Hexbound/Hexbound/Resources/Hub bg 2.jpg` / `.png`
- 4× `Contents 2.json` в xcassets

---

## 🟡 HIGH (Рантайм баги / UX дефекты)

### 4. 90+ кнопок без `.buttonStyle()`
ButtonStyles.swift определяет 20+ стилей, но большинство кнопок используют inline-стилизацию. Особо критично для AUTH-вьюшек (LoginView, OnboardingDetailView).

### 5. 193 hardcoded colors в SwiftUI
Вместо `DarkFantasyTheme` используются `Color(hex:)`, `.white`, `.black`:
- CityMapEffects.swift (12 цветов)
- DailyLoginPopupView.swift (6 hex)
- DungeonMapBuildingConfig.swift (10 glow colors)
- zoneColor() в StanceSelectorViewModel возвращает хардкод вместо theme tokens

### 6. Zero accessibility labels
0 `accessibilityLabel` во всём проекте → полный провал WCAG AA. VoiceOver пользователи не могут навигировать. Может быть проблемой для App Store Review.

### 7. Missing error/empty states
- Shop: нет обработки failed purchases
- Inventory: нет empty state
- Combat: нет error state при падении battle init
- Нет app-wide "Network unavailable — Retry"

---

## 🟡 MEDIUM (Нарушения правил)

### 8. Шрифты ниже 16px (93 случая)
- CombatDetailView: 7px и 8px (нечитаемо)
- InboxRowView: 11-15px labels
- DungeonMapBuildingView: 9-10px

### 9. Emoji вместо ассетов (18 штук)
- DungeonRushDetailView: массив emoji `["⚔️", "❓", ...]`
- StanceSelectorViewModel: зоны = emoji `"head": "🎯"`
- ArenaDetailView: `Text("⚔️")`

### 10. Type safety в TypeScript
- 20+ `: any` параметров
- 4 single-cast вместо double-cast для Prisma JSON fields
- ~20 `findUnique()` без null check

---

## ✅ ЧТО РАБОТАЕТ ХОРОШО

- **Schema sync** — backend и admin Prisma schemas идентичны
- **DarkFantasyTheme** — 104+ семантических цвета, отличная архитектура
- **ButtonStyles** — 20+ готовых стилей (просто не все используются)
- **LayoutConstants** — strict 4px grid, хорошая дисциплина по spacing
- **Arena UX** — лучший экран по state coverage (скелетоны, empty states, CTAs) → шаблон для остальных
- **Game enums** — все соответствуют спецификации
- **No ignoreBuildErrors** — флаг отсутствует
- **No .env в git**

---

## 📋 ПЛАН ДЕЙСТВИЙ (по приоритету)

### P0 — Блокеры (до следующего коммита)
1. ✏️ Добавить 4 файла в pbxproj
2. ✏️ Добавить `await` в game/init/route.ts (11 вызовов)
3. 🗑️ Удалить 10 junk-файлов с " 2"

### P1 — Critical Quality (эта неделя)
4. ✏️ Добавить `await` в остальные ~270 мест
5. 🎨 Вынести zone colors в DarkFantasyTheme
6. 🎨 Заменить inline button styling на ButtonStyles (начать с AUTH views)
7. ♿ Добавить accessibility labels на все кнопки

### P2 — High Quality (следующая неделя)
8. 🎨 Заменить 193 hardcoded colors на theme tokens
9. 📐 Фикс шрифтов < 16px (combat log, inbox)
10. 🖼️ Заменить 18 emoji на asset images
11. 📱 Стандартизировать empty/error/loading states (создать reusable компоненты)

### P3 — Polish (бэклог)
12. Убрать private color functions из ViewModels
13. Добавить lint rules для `Color(hex:` в CI
14. Добавить "Battle Again" кнопку после combat result
15. Показать stamina recovery countdown на хабе

---

## UX Health Scorecard

| Категория | Оценка | Комментарий |
|-----------|--------|-------------|
| Color Tokens | 8/10 | Отличная система, но 193 нарушения |
| Typography | 6/10 | Хорошая иерархия, но мелкие шрифты в combat |
| Spacing | 9/10 | 4px grid соблюдается |
| Components | 7/10 | UnifiedHeroWidget, NPC guides — сильно. Не хватает empty/error |
| State Coverage | 5/10 | Loading частично есть, empty/error — нет |
| Accessibility | 1/10 | Zero labels, контраст concerns |
| Game Systems | 6/10 | Progression понятно, retention hooks слабые |
| **Overall** | **6.5/10** | |

---

*Сгенерировано 5 параллельными агентами: hexbound-swift-review, hexbound-backend-review, hexbound-ux-audit, hexbound-preflight, hexbound-build-verify*
