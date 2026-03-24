# Hexbound — Error Catalog

> Каталог известных ошибок билда, собранный из реальных инцидентов.
> Используется скиллом `error-scanner` для автоматического сканирования кодовой базы.

---

## Формат записи

Каждая ошибка описана в блоке:
- **ID** — уникальный код ошибки
- **Severity** — critical / high / medium / low
- **Platform** — swift / typescript / pbxproj / prisma
- **Pattern** — regex для grep
- **File glob** — где искать
- **Description** — что не так
- **Fix** — как исправить
- **Example** — пример кода с ошибкой → исправленный

---

## SWIFT ERRORS

### ERR-SW-001: PrimitiveButtonStyle ternary mismatch
- **Severity:** critical
- **Platform:** swift
- **Pattern:** `\.buttonStyle\(.*\?.*\.primary.*:.*\.secondary\)`
- **File glob:** `*.swift`
- **Description:** Тернарный оператор в `.buttonStyle()` с `.primary` и `.secondary` — разные типы (`PrimaryButtonStyle` vs `SecondaryButtonStyle`). Swift не может вывести общий тип и фоллбэчит на `PrimitiveButtonStyle`.
- **Fix:** Использовать `if/else` с отдельными `.buttonStyle()` вызовами в каждой ветке.
- **Example:**
  ```swift
  // BAD
  .buttonStyle(condition ? .primary : .secondary)

  // GOOD
  if condition {
      Button { ... }.buttonStyle(.primary)
  } else {
      Button { ... }.buttonStyle(.secondary)
  }
  ```

### ERR-SW-002: Double @ViewBuilder attribute
- **Severity:** critical
- **Platform:** swift
- **Pattern:** `@ViewBuilder\s*\n\s*@ViewBuilder`
- **File glob:** `*.swift`
- **Description:** Два `@ViewBuilder` подряд на одной функции — "Only one result builder attribute can be attached to a declaration".
- **Fix:** Удалить дублирующий `@ViewBuilder`.

### ERR-SW-003: SFX enum — nonexistent member `.tap`
- **Severity:** critical
- **Platform:** swift
- **Pattern:** `SFXManager\.shared\.play\(\.tap\)`
- **File glob:** `*.swift`
- **Description:** `SFX` enum не имеет `.tap`. Правильное значение — `.uiTap`.
- **Fix:** Заменить `.tap` на `.uiTap`.

### ERR-SW-004: APIError.serverError — wrong destructuring
- **Severity:** critical
- **Platform:** swift
- **Pattern:** `case \.serverError\(let \w+\):`
- **File glob:** `*.swift`
- **Description:** `APIError.serverError` имеет 2 associated values: `(statusCode: Int, message: String)`. Pattern `case .serverError(let msg)` пытается захватить tuple целиком.
- **Fix:** Использовать `case .serverError(_, let msg):` или `case .serverError(let code, let msg):`.

### ERR-SW-005: Color shorthand without DarkFantasyTheme prefix
- **Severity:** high
- **Platform:** swift
- **Pattern:** `\.foregroundStyle\(\.\w+\)|\.foregroundColor\(\.\w+\)`
- **File glob:** `*.swift`
- **Description:** Bare shorthand `.textPrimary` вместо `DarkFantasyTheme.textPrimary`. Работает только если есть Color extension. Без него — build fail или неправильный тип.
- **Fix:** Всегда использовать полный префикс `DarkFantasyTheme.xxx`.
- **Exceptions:** `.primary`, `.secondary`, `.red`, `.blue`, `.white`, `.black`, `.clear`, `.gray`, `.accentColor` — стандартные SwiftUI цвета.

### ERR-SW-006: Force unwrap (!)
- **Severity:** high
- **Platform:** swift
- **Pattern:** `\w+![\s\.\,\)\]]`
- **File glob:** `*.swift`
- **Description:** Force unwrap может крашнуть приложение при nil. Zero force-unwrap policy в проекте.
- **Fix:** Использовать `if let`, `guard let`, `?? defaultValue`.
- **Exceptions:** Hardcoded URL literals с `// swiftlint:disable:this force_unwrap`.

### ERR-SW-007: Missing file in pbxproj Sources build phase
- **Severity:** critical
- **Platform:** pbxproj
- **Pattern:** _(special check — compare .swift files on disk vs PBXSourcesBuildPhase entries)_
- **File glob:** `project.pbxproj`
- **Description:** Файл `.swift` добавлен в PBXBuildFile и PBXFileReference, но НЕ добавлен в PBXSourcesBuildPhase. Xcode видит файл, но не компилирует → "Cannot find type in scope" каскадные ошибки.
- **Fix:** Добавить `{buildFileID} /* FileName.swift in Sources */,` в PBXSourcesBuildPhase.files.

### ERR-SW-008: Ghost file in pbxproj (file doesn't exist on disk)
- **Severity:** critical
- **Platform:** pbxproj
- **Pattern:** _(special check — pbxproj references vs actual files on disk)_
- **File glob:** `project.pbxproj`
- **Description:** pbxproj ссылается на файл, которого нет на диске → "Build input file cannot be found".
- **Fix:** Удалить все 4 записи из pbxproj (PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase).

### ERR-SW-009: Junk files inside .xcodeproj bundle
- **Severity:** critical
- **Platform:** pbxproj
- **Pattern:** _(special check — ls *.bak, *.backup, *.tmp in .xcodeproj/)_
- **File glob:** `Hexbound.xcodeproj/`
- **Description:** Temp/backup файлы внутри `.xcodeproj` bundle ломают загрузку проекта — "Couldn't load project".
- **Fix:** `rm -f Hexbound.xcodeproj/*.bak *.backup *.tmp*`

### ERR-SW-010: Duplicate PBXBuildFile entries (same ID)
- **Severity:** high
- **Platform:** pbxproj
- **Pattern:** _(special check — find duplicate IDs in PBXBuildFile section)_
- **File glob:** `project.pbxproj`
- **Description:** Один и тот же ID в PBXBuildFile появляется дважды. Xcode может путаться.
- **Fix:** Удалить дубликат, оставить одну запись.

### ERR-SW-011: APIClient wrong call signature
- **Severity:** critical
- **Platform:** swift
- **Pattern:** `APIClient\.shared\.(get|post|patch)Raw\(\s*endpoint:`
- **File glob:** `*.swift`
- **Description:** `getRaw`/`postRaw` используют позиционный первый аргумент (без label `endpoint:`). Правильно: `getRaw(APIEndpoints.xxx, params: ...)`.
- **Fix:** Убрать label `endpoint:`, использовать позиционный аргумент.

### ERR-SW-012: APIClient queryItems parameter (doesn't exist)
- **Severity:** critical
- **Platform:** swift
- **Pattern:** `APIClient\.shared\.\w+\(.*queryItems:`
- **File glob:** `*.swift`
- **Description:** APIClient не имеет параметра `queryItems`. Используйте `params: [String: String]`.
- **Fix:** Заменить `queryItems: [URLQueryItem(...)]` на `params: ["key": "value"]`.

### ERR-SW-013: Type-checker timeout (complex expression)
- **Severity:** high
- **Platform:** swift
- **Pattern:** _(detected by Xcode, not grep — but can check for deeply nested Canvas/GeometryReader/TimelineView)_
- **File glob:** `*.swift`
- **Description:** "The compiler is unable to type-check this expression in reasonable time". Обычно — сложные вычисления внутри `body` с неявными типами.
- **Fix:** Разбить на отдельные функции, добавить явные аннотации типов (`: Double`, `: CGPoint`).

### ERR-SW-014: PvPRank.displayName (doesn't exist)
- **Severity:** medium
- **Platform:** swift
- **Pattern:** `PvPRank\.\w*\.displayName`
- **File glob:** `*.swift`
- **Description:** `PvPRank` не имеет `.displayName`. Использовать `.rawValue`.
- **Fix:** `.displayName` → `.rawValue`.

### ERR-SW-015: Hardcoded Color(hex:) or raw color values
- **Severity:** medium
- **Platform:** swift
- **Pattern:** `Color\(hex:|Color\(red:|Color\(#|Color\(\.init\(red:`
- **File glob:** `*.swift`
- **Description:** Проект использует `DarkFantasyTheme` токены. Хардкод цветов нарушает design system.
- **Fix:** Использовать `DarkFantasyTheme.xxx` вместо raw color.
- **Exceptions:** `OrnamentalStyles.swift` — `Color.white`/`Color.black` at low opacity в overlays.

### ERR-SW-016: Deprecated stat colors (per-stat rainbow)
- **Severity:** medium
- **Platform:** swift
- **Pattern:** `DarkFantasyTheme\.stat(STR|AGI|VIT|INT|WIS|LCK|DEX|CHA)`
- **File glob:** `*.swift`
- **Description:** Per-stat colors deprecated. Используй unified gold palette: `statBoosted`, `statBase`, `statBarFill`.
- **Fix:** Заменить на `DarkFantasyTheme.statBarColor(value:base:)` или `statBarFill`.

### ERR-SW-017: Missing [weak self] in callback closures
- **Severity:** high
- **Platform:** swift
- **Pattern:** `\[self\] in`
- **File glob:** `*.swift`
- **Description:** `[self]` capture создаёт retain cycle. Все callback closures должны использовать `[weak self]`.
- **Fix:** `[self] in` → `[weak self] in guard let self else { return }`.

### ERR-SW-018: Hardcoded cornerRadius (no LayoutConstants token)
- **Severity:** medium
- **Platform:** swift
- **Pattern:** `cornerRadius:\s*\d+[^.]`
- **File glob:** `*.swift`
- **Description:** Raw числа вместо `LayoutConstants` токенов для cornerRadius.
- **Fix:** Использовать `LayoutConstants.radiusSM`, `.cardRadius`, `.modalRadius` и т.д.
- **Exceptions:** Circle skeletons (`cornerRadius: width/2`).

### ERR-SW-019: Currency display with SF Symbols instead of CurrencyDisplay
- **Severity:** medium
- **Platform:** swift
- **Pattern:** `dollarsign\.circle|systemName:.*"diamond"`
- **File glob:** `*.swift`
- **Description:** Для валюты используйте `CurrencyDisplay` компонент, не SF Symbols.
- **Fix:** Заменить на `CurrencyDisplay(gold:gems:size:)`.

---

## TYPESCRIPT / BACKEND ERRORS

### ERR-TS-001: Missing await on async config functions
- **Severity:** critical
- **Platform:** typescript
- **Pattern:** `[^await]\s+get\w+Config\(`
- **File glob:** `*.ts`
- **Description:** Все `get*Config()` из `live-config.ts` — async. Без `await` получаем `Promise<number>` вместо `number`.
- **Fix:** Добавить `await`.

### ERR-TS-002: Missing await on runCombat()
- **Severity:** critical
- **Platform:** typescript
- **Pattern:** `[^await]\s+runCombat\(`
- **File glob:** `*.ts`
- **Description:** `runCombat()` — async. Без `await` — `Promise<CombatResult>`.
- **Fix:** `const result = await runCombat(attacker, defender)`.

### ERR-TS-003: Missing await on calculateCurrentStamina()
- **Severity:** critical
- **Platform:** typescript
- **Pattern:** `[^await]\s+calculateCurrentStamina\(`
- **File glob:** `*.ts`
- **Description:** `calculateCurrentStamina()` — async.
- **Fix:** `const stamina = await calculateCurrentStamina(current, max, lastUpdate)`.

### ERR-TS-004: DB query inside loop (N+1)
- **Severity:** high
- **Platform:** typescript
- **Pattern:** `\.map\(.*=>\s*\{[^}]*findUnique|\.map\(.*=>\s*\{[^}]*findFirst|\.forEach\(.*=>\s*\{[^}]*getGameConfig`
- **File glob:** `*.ts`
- **Description:** DB queries или config lookups внутри `.map()`/`.forEach()` — N+1 проблема.
- **Fix:** Batch query с `findMany({ where: { id: { in: ids } } })` + Map.

### ERR-TS-005: Missing try/catch in API route handler
- **Severity:** high
- **Platform:** typescript
- **Pattern:** `export\s+(async\s+)?function\s+(GET|POST|PUT|PATCH|DELETE)\(`
- **File glob:** `route.ts`
- **Description:** API routes без try/catch возвращают raw 500 со stack traces.
- **Fix:** Обернуть тело в `try { ... } catch (error) { console.error(...); return NextResponse.json({message: 'Internal error'}, {status: 500}); }`.

### ERR-TS-006: Logging PII (email, password, token)
- **Severity:** critical
- **Platform:** typescript
- **Pattern:** `console\.(log|error|warn)\(.*\b(email|password|token|secret|apiKey)\b`
- **File glob:** `*.ts`
- **Description:** PII в логах — нарушение безопасности.
- **Fix:** Логировать только userId, characterName, request path.

### ERR-TS-007: TOCTOU — validation outside transaction
- **Severity:** high
- **Platform:** typescript
- **Pattern:** _(manual review — check for limit validation before $transaction)_
- **File glob:** `route.ts`
- **Description:** Проверка лимитов ДО транзакции — race condition. Два одновременных запроса проходят проверку.
- **Fix:** Валидация ВНУТРИ `$transaction` с `SELECT FOR UPDATE`.

### ERR-TS-008: Non-atomic counter increment (read-then-write)
- **Severity:** high
- **Platform:** typescript
- **Pattern:** `findFirst.*progress.*update.*progress\s*\+\s*1|findFirst.*count.*update.*count\s*\+\s*1`
- **File glob:** `*.ts`
- **Description:** Read-then-write pattern для счётчиков — race condition при concurrent requests.
- **Fix:** `$executeRawUnsafe('UPDATE ... SET progress = LEAST(progress + $1, target) WHERE ...')`.

### ERR-TS-009: File with spaces or " 2" in name
- **Severity:** medium
- **Platform:** typescript
- **Pattern:** _(special check — find files matching "* 2.*" or "* copy.*")_
- **File glob:** `*.ts`
- **Description:** macOS создаёт копии с ` 2` в имени. Мусорные файлы.
- **Fix:** Удалить.

---

## PRISMA / DATABASE ERRORS

### ERR-DB-001: Schema out of sync (backend vs admin)
- **Severity:** critical
- **Platform:** prisma
- **Pattern:** _(special check — diff backend/prisma/schema.prisma vs admin/prisma/schema.prisma)_
- **Description:** `backend/prisma/schema.prisma` — single source of truth. Admin копия должна быть идентичной.
- **Fix:** `cp backend/prisma/schema.prisma admin/prisma/schema.prisma`.

### ERR-DB-002: Merge conflict markers in code
- **Severity:** critical
- **Platform:** all
- **Pattern:** `^<<<<<<<|^=======\s*$|^>>>>>>>`
- **File glob:** `*.swift,*.ts,*.tsx,*.prisma,*.md`
- **Description:** Неразрешённые конфликты мержа — ломают билд.
- **Fix:** Разрешить конфликт вручную, убрать маркеры.

---

## Changelog

| Date | Error ID | Added by | Context |
|------|----------|----------|---------|
| 2026-03-24 | ERR-SW-001 | Claude | `.buttonStyle` ternary in ItemDetailSheet |
| 2026-03-24 | ERR-SW-002 | Claude | Double @ViewBuilder in ItemDetailSheet |
| 2026-03-24 | ERR-SW-003 | Claude | `.tap` → `.uiTap` in SettingsDetailView |
| 2026-03-24 | ERR-SW-004 | Claude | `serverError` destructuring in BattlePassService |
| 2026-03-24 | ERR-SW-005 | Claude | Color shorthand post-merge violations |
| 2026-03-24 | ERR-SW-007 | Claude | Social.swift missing from Sources build phase |
| 2026-03-24 | ERR-SW-008 | Claude | CharacterSelectionViewModel.swift ghost reference |
| 2026-03-24 | ERR-SW-010 | Claude | Duplicate Social.swift in PBXBuildFile |
| 2026-03-24 | ERR-SW-011 | Claude | `endpoint:` label in SocialService |
| 2026-03-24 | ERR-SW-013 | Claude | SpinningRaysView type-checker timeout |
| 2026-03-24 | ERR-SW-003 | Claude | `.tap`/`.confirm` → `.uiTap`/`.uiConfirm` in CharacterSelectionView |
| 2026-03-24 | ERR-SW-008 | Claude | CharacterSelectionViewModel removed from pbxproj but file existed |
