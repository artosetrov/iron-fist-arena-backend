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

### 1.1 — Pattern checks with `rg` (ERR-SW-001 → ERR-SW-006, ERR-SW-011 → ERR-SW-019)

Run each pattern from the catalog against `Hexbound/Hexbound/**/*.swift`. Prefer `rg` because macOS `grep` can miss patterns that rely on `\w`, `\s`, or alternation.
For each match, output:
```
⚠️ ERR-SW-XXX: [description]
   File: [path]:[line]
   Fix: [one-line fix from catalog]
```

**Specific commands:**

```bash
# ERR-SW-001: buttonStyle ternary
rg -n '\.buttonStyle\(.*\?.*\.primary.*:.*\.secondary' Hexbound/Hexbound -g '*.swift'

# ERR-SW-002: double @ViewBuilder
rg -n -A1 '@ViewBuilder' Hexbound/Hexbound -g '*.swift' | rg -B1 '@ViewBuilder.*@ViewBuilder'

# ERR-SW-003: SFX .tap
rg -n 'SFXManager\.shared\.play\(\.tap\)' Hexbound/Hexbound -g '*.swift'

# ERR-SW-004: serverError wrong destructuring
rg -n 'case \.serverError\(let [A-Za-z_][A-Za-z0-9_]*\):' Hexbound/Hexbound -g '*.swift'

# ERR-SW-005: bare color shorthand (excluding standard SwiftUI colors)
rg -n '\.foregroundStyle\(\.[A-Za-z_][A-Za-z0-9_]*\)' Hexbound/Hexbound -g '*.swift' | rg -v 'DarkFantasyTheme|\.primary|\.secondary|\.red|\.blue|\.white|\.black|\.clear|\.gray|\.accentColor'

# ERR-SW-011: APIClient wrong label
rg -n 'APIClient\.shared\.[A-Za-z_][A-Za-z0-9_]*Raw\(\s*endpoint:' Hexbound/Hexbound -g '*.swift'

# ERR-SW-012: queryItems parameter
rg -n 'APIClient\.shared\.[A-Za-z_][A-Za-z0-9_]*\([^)]*queryItems:' Hexbound/Hexbound -g '*.swift'

# ERR-SW-014: PvPRank.displayName
rg -n 'PvPRank\.[A-Za-z0-9_]*\.displayName' Hexbound/Hexbound -g '*.swift'

# ERR-SW-015: hardcoded Color(hex:)
rg -n 'Color\(hex:|Color\(red:|Color\(#' Hexbound/Hexbound -g '*.swift' | rg -v 'OrnamentalStyles|DarkFantasyTheme'

# ERR-SW-016: deprecated stat colors
rg -n 'DarkFantasyTheme\.stat(STR|AGI|VIT|INT|WIS|LCK|DEX|CHA)' Hexbound/Hexbound -g '*.swift'

# ERR-SW-017: [self] in (retain cycles)
rg -n '\[self\] in' Hexbound/Hexbound -g '*.swift'

# ERR-SW-019: currency SF Symbols
rg -n 'dollarsign\.circle|systemName:.*"diamond"' Hexbound/Hexbound -g '*.swift'

# ERR-SW-020: force unwrap (randomElement()! etc)
rg -n 'randomElement\(\)!' Hexbound/Hexbound -g '*.swift'

# ERR-SW-021: ToastType.success (doesn't exist)
rg -n 'ToastType\.success|type: \.success' Hexbound/Hexbound -g '*.swift'

# ERR-SW-022: showToast wrong labels (title:, message:)
rg -n 'showToast\(title:|showToast.*message:' Hexbound/Hexbound -g '*.swift'

# ERR-SW-023: [weak self] in struct (SwiftUI views)
rg -n '\[weak self\]' Hexbound/Hexbound/Views -g '*.swift'

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
find Hexbound/Hexbound.xcodeproj -maxdepth 1 -type f | rg '\.(bak|backup|tmp)$'
```

**ERR-SW-010: Duplicate PBXBuildFile IDs**

```bash
rg 'isa = PBXBuildFile' Hexbound/Hexbound.xcodeproj/project.pbxproj | awk '{print $1}' | sort | uniq -d
```

---

## Phase 2: TypeScript / Backend (backend/src/)

```bash
# ERR-TS-001: missing await on config functions
rg -n 'get[A-Za-z0-9_]*Config\(' backend/src -g '*.ts' | rg -v 'await|function|export|async|=>'

# ERR-TS-002: missing await on runCombat
rg -n 'runCombat\(' backend/src -g '*.ts' | rg -v 'await|function|export|async'

# ERR-TS-003: missing await on calculateCurrentStamina
rg -n 'calculateCurrentStamina\(' backend/src -g '*.ts' | rg -v 'await|function|export|async'

# ERR-TS-006: PII in logs
rg -n 'console\.(log|error|warn)\(.*(email|password|token|secret|apiKey)' backend/src -g '*.ts'

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
rg -n '^(<<<<<<<|=======\s*$|>>>>>>>)' . -g '*.swift' -g '*.ts' -g '*.tsx' -g '*.prisma' -g '*.md' -g '!node_modules/**' -g '!.git/**'
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

---

## Agent Bus (Team Communication)

> Ты часть Agent Team. После завершения работы — запиши результат в bus. Перед началом — проверь bus на сообщения от других агентов.

### При старте
1. `ls .claude/agent-bus/` — проверь есть ли файлы от других агентов
2. Прочитай `.md` файлы (кроме `PROTOCOL.md`, `AGENT_HEADER.md`) — это результаты других агентов
3. Проверь секцию `## Alerts` — если есть `@{твоё-имя}` или `@ALL`, обработай

### При завершении
Запиши результат: `Write tool → .claude/agent-bus/{твоё-имя}.md`

Формат:
```markdown
# {Name} — Result
timestamp: {now}
status: OK | WARNING | BLOCKED

## Findings
- ...

## Decisions
- ...

## Alerts
- @{agent}: описание (если нашёл проблему для другого агента)

## Files Changed
- path/to/file (action)
```
