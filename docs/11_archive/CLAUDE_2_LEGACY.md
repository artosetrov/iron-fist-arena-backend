# Hexbound — Project Rules

## Xcode Project File (CRITICAL)

When creating ANY new `.swift` file in the `Hexbound/` iOS app, you MUST also add it to `Hexbound/Hexbound.xcodeproj/project.pbxproj`.

Each new file requires entries in **4 sections** of `project.pbxproj`:

1. **PBXBuildFile** — `{ID1} /* FileName.swift in Sources */ = {isa = PBXBuildFile; fileRef = {ID2} /* FileName.swift */; };`
2. **PBXFileReference** — `{ID2} /* FileName.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileName.swift; sourceTree = "<group>"; };`
3. **PBXGroup** — Add `{ID2} /* FileName.swift */,` to the correct group's `children` array (match the folder the file lives in, e.g. Auth, Components, Network)
4. **Sources build phase** — Add `{ID1} /* FileName.swift in Sources */,` to the `PBXSourcesBuildPhase` `files` array

Generate unique 24-character hex IDs for `{ID1}` and `{ID2}`. Keep entries alphabetically sorted within each section.

**If you skip this step, the file will NOT compile in Xcode.**

## Design System (STRICT — всегда работать по токенам)

- **ВСЕГДА** использовать `DarkFantasyTheme` цвета и шрифты — **НИКОГДА** не хардкодить `Color(hex:)`, `Color.red`, `.font(.system(...))` или любые raw-значения
- **ВСЕГДА** использовать стили из `ButtonStyles.swift` (`.primary`, `.secondary`, `.neutral`, `.ghost`, `.socialAuth` и т.д.) — **НИКОГДА** не инлайнить стилизацию кнопок
- **ВСЕГДА** использовать `LayoutConstants` для отступов, размеров и шрифтов — минимальный размер шрифта `LayoutConstants.textBadge` (11px)
- Перед использованием стиля кнопки — **проверь его сигнатуру** в `ButtonStyles.swift` (например, `.primary(enabled:)` принимает параметр, а `.secondary` — нет)
- Перед использованием цвета/шрифта — **убедись, что токен существует** в `DarkFantasyTheme.swift`
- Если нужного стиля/токена/варианта **не существует** — **СОЗДАЙ его** в соответствующем файле (`ButtonStyles.swift`, `DarkFantasyTheme.swift`, `LayoutConstants.swift`). **НИКОГДА** не обходи отсутствие стиля костылями (inline opacity, hardcoded colors, ручные `.frame`/`.background`/`.overlay` вместо стиля). Сначала расширь дизайн-систему, потом используй
- **После КАЖДОГО изменения UI** — перечитай `ButtonStyles.swift`, `DarkFantasyTheme.swift`, `LayoutConstants.swift` и сверь, что все используемые токены, стили и константы существуют и вызываются с правильной сигнатурой. Это обязательный шаг, не пропускай
- The theme file is at `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- Button styles are at `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- Layout constants are at `Hexbound/Hexbound/Theme/LayoutConstants.swift`

## Art Style (for AI image generation prompts)

- Full art style guide: `Hexbound/ART_STYLE_GUIDE.md`
- Style: pen and ink illustration, bold black ink outlines, muted earth tones + 1-2 saturated accent colors, grimdark dark fantasy, isolated on white/transparent background
- Reference: D&D Monster Manual / Pathfinder rulebook illustrations (NOT digital painting, NOT concept art, NOT anime)
- Always start prompts with `Pen and ink illustration of...`
- Always end with `isolated on white background, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text`
- The icon `icon-gold-mine` is in a DIFFERENT casual/cartoon style — do NOT use as art style reference

## Property Access (CRITICAL)

- Перед обращением к свойству модели — **убедись, что это свойство существует** в определении структуры/класса. **НЕ** предполагай наличие computed properties вроде `resolvedImageKey`, `resolvedX` и т.п. — они могут быть только у некоторых типов
- Разные модели (`Item`, `ShopItem`, `LootPreview`, `EquippedItem` и т.д.) имеют **разные наборы свойств**, даже если концептуально похожи. Всегда сверяйся с определением конкретного типа
- Если нужное свойство **отсутствует** — используй существующее поле напрямую (например `imageKey` вместо `resolvedImageKey`) или **добавь** computed property в модель

## Self-Documenting Rules (META — ОБЯЗАТЕЛЬНО)

Если в процессе работы обнаруживается паттерн, ошибка или практика, которая:
- **повторяется** из раза в раз (одна и та же ошибка / один и тот же ручной шаг),
- **ломает билд** или вызывает рантайм-краш,
- требует **неочевидного знания** о проекте (особенности API, модели, зависимости),

то **АВТОМАТИЧЕСКИ добавь новое правило** в этот `CLAUDE.md` — не спрашивая. Формат: краткое описание проблемы + что делать / чего не делать. Секцию выбирай по смыслу или создавай новую.

## Architecture

- State management: `@MainActor @Observable` classes
- Navigation: `NavigationStack` with `AppRouter`
- Cache: `GameDataCache` environment object, cache-first pattern
- Views pass `@Bindable var vm` to child components (not `@State`)

## Communication Style (STRICT)

- **НЕ** давать высокоуровневые объяснения — если просят фикс или объяснение, давать **конкретный код** или **конкретное объяснение**
- **НЕ** писать «Here's how you can blablabla» — сразу к делу
- Быть casual, если не указано иное
- Быть кратким (terse)
- Предлагать решения, о которых пользователь не подумал — предугадывать потребности
- Считать пользователя экспертом
- Быть точным и тщательным
- Давать ответ **сразу**. Подробные объяснения и перефразирование — **после** ответа, если нужно
- Ценить хорошие аргументы выше авторитетов, источник не важен
- Рассматривать новые технологии и контринтуитивные идеи, не только conventional wisdom
- Можно спекулировать и предсказывать — просто помечать это
- Без моральных лекций
- Обсуждать безопасность только когда это критично и неочевидно
- Источники — в конце, не инлайн
- При корректировке предоставленного кода — **НЕ** повторять весь код. Давать только пару строк до/после изменений. Несколько блоков кода — ок
- Соблюдать prettier-предпочтения пользователя
- Если один ответ не вмещает — разбивать на несколько
