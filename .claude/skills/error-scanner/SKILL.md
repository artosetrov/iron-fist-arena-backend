# Проверяла (Error Scanner)

Сканирует кодовую базу Hexbound на известные паттерны ошибок из `ERROR_CATALOG.md`.
Режим: **scan-only** — находит и показывает, не автофиксит.

## Триггеры

- "scan errors", "сканируй ошибки", "проверь код", "error scan", "проверяла"
- "check for known bugs", "проверь на известные баги", "запусти проверялу"
- Перед коммитом или после большого рефакторинга

## Протокол работы

При вызове этого скилла, выполни **ВСЕ** проверки ниже последовательно. Не пропускай ни одной.
Для каждой проверки: если найдены проблемы — выведи файл, строку, и рекомендацию из каталога.
В конце — сводка: сколько проверок прошло, сколько проблем найдено, по severity.

### ОБЯЗАТЕЛЬНО: Прочитай каталог перед началом

```
Read docs/09_rules_and_guidelines/ERROR_CATALOG.md
```

Каталог содержит полные описания, примеры и фиксы. Используй его как reference.

---

## Phase 1: Swift / Xcode (Hexbound/Hexbound/)

### 1.1 — Grep-based checks (ERR-SW-001 → ERR-SW-006, ERR-SW-011 → ERR-SW-019)

Run each grep pattern from the catalog against `Hexbound/Hexbound/**/*.swift`.
For each match, output:
```
⚠️ ERR-SW-XXX: [description]
   File: [path]:[line]
   Fix: [one-line fix from catalog]
```

**Specific grep commands:**

```bash
# ERR-SW-001: buttonStyle ternary
grep -rn '\.buttonStyle(.*?.*\.primary.*:.*\.secondary)' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-002: double @ViewBuilder
grep -rn -A1 '@ViewBuilder' Hexbound/Hexbound/ --include="*.swift" | grep -B1 '@ViewBuilder.*@ViewBuilder'

# ERR-SW-003: SFX .tap
grep -rn 'SFXManager\.shared\.play(\.tap)' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-004: serverError wrong destructuring
grep -rn 'case \.serverError(let \w\+):' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-005: bare color shorthand (excluding standard SwiftUI colors)
grep -rn '\.foregroundStyle(\.\w\+)' Hexbound/Hexbound/ --include="*.swift" | grep -v 'DarkFantasyTheme\|\.primary\|\.secondary\|\.red\|\.blue\|\.white\|\.black\|\.clear\|\.gray\|\.accentColor'

# ERR-SW-011: APIClient wrong label
grep -rn 'APIClient\.shared\.\w\+Raw(\s*endpoint:' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-012: queryItems parameter
grep -rn 'APIClient\.shared\.\w\+(.*queryItems:' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-014: PvPRank.displayName
grep -rn 'PvPRank\.\w*\.displayName' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-015: hardcoded Color(hex:)
grep -rn 'Color(hex:\|Color(red:\|Color(#' Hexbound/Hexbound/ --include="*.swift" | grep -v 'OrnamentalStyles\|DarkFantasyTheme'

# ERR-SW-016: deprecated stat colors
grep -rn 'DarkFantasyTheme\.stat\(STR\|AGI\|VIT\|INT\|WIS\|LCK\|DEX\|CHA\)' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-017: [self] in (retain cycles)
grep -rn '\[self\] in' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-019: currency SF Symbols
grep -rn 'dollarsign\.circle\|systemName:.*"diamond"' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-020: force unwrap (randomElement()! etc)
grep -rn 'randomElement()!' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-021: ToastType.success (doesn't exist)
grep -rn 'ToastType\.success\|type: \.success' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-022: showToast wrong labels (title:, message:)
grep -rn 'showToast(title:\|showToast.*message:' Hexbound/Hexbound/ --include="*.swift"

# ERR-SW-023: [weak self] in struct (SwiftUI views)
grep -rn '\[weak self\]' Hexbound/Hexbound/Views/ --include="*.swift"

# ERR-SW-024: missing .compositingGroup() after 2+ ornamental overlays
# (manual check — look for .surfaceLighting + .innerBorder without .compositingGroup before .shadow)
```

### 1.2 — Multiline checks (use Grep tool with multiline: true)

```
# ERR-SW-002: double @ViewBuilder (multiline)
Pattern: @ViewBuilder\s*\n\s*@ViewBuilder
```

### 1.3 — pbxproj structural checks

**ERR-SW-007: Files in PBXBuildFile but NOT in PBXSourcesBuildPhase**

1. Extract all `.swift` build file IDs from PBXBuildFile section
2. Extract all IDs from PBXSourcesBuildPhase.files
3. Report any IDs present in #1 but missing from #2

**ERR-SW-008: Ghost files (in pbxproj but not on disk)**

1. Extract all `path = FileName.swift` from PBXFileReference
2. For each, verify the file exists in `Hexbound/Hexbound/`
3. Report missing files

**ERR-SW-009: Junk files in .xcodeproj**

```bash
ls Hexbound/Hexbound.xcodeproj/ | grep -E '\.(bak|backup|tmp)$'
```

**ERR-SW-010: Duplicate PBXBuildFile IDs**

```bash
grep 'isa = PBXBuildFile' project.pbxproj | awk '{print $1}' | sort | uniq -d
```

---

## Phase 2: TypeScript / Backend (backend/src/)

```bash
# ERR-TS-001: missing await on config functions
grep -rn 'get\w\+Config(' backend/src/ --include="*.ts" | grep -v 'await\|function\|export\|async\|=>'

# ERR-TS-002: missing await on runCombat
grep -rn 'runCombat(' backend/src/ --include="*.ts" | grep -v 'await\|function\|export\|async'

# ERR-TS-003: missing await on calculateCurrentStamina
grep -rn 'calculateCurrentStamina(' backend/src/ --include="*.ts" | grep -v 'await\|function\|export\|async'

# ERR-TS-006: PII in logs
grep -rn 'console\.\(log\|error\|warn\)(.*\(email\|password\|token\|secret\|apiKey\)' backend/src/ --include="*.ts"

# ERR-TS-009: junk files with spaces
find backend/src/ -name "* *" -o -name "*\ 2*"
```

---

## Phase 3: Prisma / Cross-cutting

**ERR-DB-001: Schema sync check**

```bash
diff backend/prisma/schema.prisma admin/prisma/schema.prisma
```

**ERR-DB-002: Merge conflict markers**

```bash
grep -rn '^<<<<<<<\|^=======\s*$\|^>>>>>>>' . --include="*.swift" --include="*.ts" --include="*.tsx" --include="*.prisma" --include="*.md" | grep -v node_modules | grep -v ".git/"
```

---

## Phase 4: Report

After all checks, output a summary table:

```
╔══════════════════════════════════════════╗
║         ERROR SCANNER REPORT             ║
╠══════════════════════════════════════════╣
║ Total checks run:     XX                 ║
║ Critical issues:      XX 🔴              ║
║ High issues:          XX 🟠              ║
║ Medium issues:        XX 🟡              ║
║ Clean checks:         XX ✅              ║
╠══════════════════════════════════════════╣
║ Findings:                                ║
║  [list each finding with ERR-ID]         ║
╚══════════════════════════════════════════╝
```

If zero issues found: `✅ All XX checks passed. Codebase is clean.`

---

## Adding New Errors

When a new error pattern is discovered:

1. Add entry to `docs/09_rules_and_guidelines/ERROR_CATALOG.md` with next available ID
2. Add corresponding grep check to this SKILL.md in the appropriate phase
3. Update the Changelog table in ERROR_CATALOG.md
4. If the error is critical and common — also add a rule to `CLAUDE.md`
