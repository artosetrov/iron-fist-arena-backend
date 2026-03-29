# Skill: Летописец Документации (Doc Keeper)

> **Trigger:** "doc keeper", "летописец документации", "обнови документацию", "doc audit", "проверь docs", "что не задокументировано", "documentation sweep", "freshness check", "создай doc для фичи"
> **Version:** 1.0
> **Created:** 2026-03-26

---

## Purpose

Полный аудит документации проекта + автоматическое создание/обновление документов. Сканирует проект, находит undocumented features, проверяет freshness, создаёт новые docs по шаблонам, ведёт учёт.

---

## Modes

### Mode 1: AUDIT (default trigger: "doc audit", "проверь docs", "freshness check")

Полный скан документации.

### Mode 2: CREATE (trigger: "создай doc для X", "document X")

Создание нового документа по шаблону.

### Mode 3: NAVIGATE (trigger: "где найти доку про X", "what docs for X")

Подсказка какие docs читать для конкретной задачи.

---

## Mode 1: AUDIT Protocol

### Phase 1 — Inventory Scan

```bash
# 1. Count all docs
find docs/ -name "*.md" -type f | wc -l

# 2. List all docs with modification dates
find docs/ -name "*.md" -type f -exec stat -c '%Y %n' {} \; | sort -rn | head -40

# 3. Check feature folders coverage
ls docs/features/

# 4. Check rules coverage
ls docs/rules/

# 5. Count iOS screens vs documented screens
find Hexbound/Hexbound/Views/ -name "*DetailView.swift" -o -name "*View.swift" | grep -v Components | wc -l
```

### Phase 2 — Freshness Check

For each doc in `docs/`, check:
1. `Last updated` date in header — if >14 days old, flag as STALE
2. Referenced files still exist in codebase
3. Referenced API endpoints still exist
4. Referenced models still match schema

```bash
# Check for referenced files that don't exist
# Exclude template placeholders ({path}, {ScreenName}) and archive docs
# Note: use grep without -h to keep filenames, then filter out templates/archive
grep -rn "Hexbound/.*\.swift" docs/ --include="*.md" | \
  grep -v "docs/templates/" | grep -v "docs/11_archive/" | grep -v "docs/retro/" | \
  grep -oP 'Hexbound/[^\s`|,)]+\.swift' | grep -v '{' | sort -u | while read f; do
  [ ! -f "$f" ] && echo "MISSING: $f"
done
```

### Phase 3 — Gap Analysis

Find undocumented areas:

```bash
# iOS screens without feature docs
for view in $(find Hexbound/Hexbound/Views/ -maxdepth 2 -name "*DetailView.swift" -exec basename {} .swift \;); do
  feature=$(echo "$view" | sed 's/DetailView//' | tr '[:upper:]' '[:lower:]')
  if ! find docs/features/ -name "*.md" | xargs grep -li "$feature" 2>/dev/null | head -1 > /dev/null; then
    echo "NO DOC: $view"
  fi
done

# API routes without API_REFERENCE coverage
# Note: API_REFERENCE.md uses paths like /pvp/fight (no api/ prefix), but also has section headers /api/pvp/*
find backend/src/app/api/ -name "route.ts" | while read f; do
  route=$(echo "$f" | sed 's|backend/src/app/api/||' | sed 's|/route.ts||')
  if ! grep -q "$route" docs/03_backend_and_api/API_REFERENCE.md 2>/dev/null; then
    echo "UNDOC API: /$route"
  fi
done

# Backend game logic files without docs
find backend/src/lib/game/ -name "*.ts" | while read f; do
  base=$(basename "$f" .ts)
  if ! grep -rli "$base" docs/06_game_systems/ 2>/dev/null | head -1 > /dev/null; then
    echo "UNDOC GAME LOGIC: $f"
  fi
done
```

### Phase 4 — Cross-Reference Integrity

```bash
# Check PROJECT_INDEX.md links
grep -oP '\[.*?\]\(.*?\)' docs/PROJECT_INDEX.md | grep -oP '\(.*?\)' | tr -d '()' | while read link; do
  resolved="docs/$link"
  [ ! -f "$resolved" ] && echo "BROKEN LINK: $link in PROJECT_INDEX.md"
done

# Check SOURCE_OF_TRUTH.md references
grep -oP '`[^`]+`' docs/SOURCE_OF_TRUTH.md | tr -d '`' | grep "/" | while read path; do
  [ ! -f "$path" ] && [ ! -d "$path" ] && echo "BROKEN REF: $path in SOURCE_OF_TRUTH.md"
done
```

### Phase 5 — Report

Produce a report with sections:
1. **Summary:** Total docs, stale count, gap count, broken links
2. **Stale Documents:** List with last-updated date and what changed
3. **Missing Documentation:** Features/screens/APIs without docs
4. **Broken References:** Dead links and file refs
5. **Recommendations:** Prioritized list of docs to create/update

---

## Mode 2: CREATE Protocol

### Step 1 — Determine template

| Creating | Template |
|----------|---------|
| Feature doc | `docs/templates/TEMPLATE_FEATURE.md` |
| Screen doc | `docs/templates/TEMPLATE_SCREEN.md` |
| API module doc | `docs/templates/TEMPLATE_API_MODULE.md` |
| Rule file | `docs/templates/TEMPLATE_RULE.md` |

### Step 2 — Gather data from codebase

Scan the relevant code files to auto-fill:
- File paths
- Function names
- Model references
- API endpoints
- Component usage

### Step 3 — Generate document

1. Copy template
2. Fill in all sections from gathered data
3. Save to correct location:
   - Feature: `docs/features/{feature-name}/{FEATURE_NAME}_OVERVIEW.md`
   - Screen: `docs/features/{feature-name}/{SCREEN_NAME}_SCREEN.md`
   - API: `docs/03_backend_and_api/{MODULE}_API.md`
   - Rule: `docs/rules/rules-{domain}.md` + copy to `.cursor/rules/rules-{domain}.mdc`

### Step 4 — Update indexes

1. Add to `docs/PROJECT_INDEX.md` if it's a new feature
2. Add to `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`
3. If rule file — add to Agent Loading Guide

---

## Mode 3: NAVIGATE Protocol

1. Parse user's task description
2. Match against Agent Loading Strategy in `docs/AGENT_LOADING_GUIDE.md`
3. Return ordered list of docs to read

---

## File Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Feature overview | `{FEATURE}_OVERVIEW.md` | `ARENA_OVERVIEW.md` |
| Screen doc | `{SCREEN}_SCREEN.md` | `SHOP_SCREEN.md` |
| Rule file | `rules-{domain}.md` | `rules-combat-pvp.md` |
| API module | `{MODULE}_API.md` | `PVP_API.md` |
| Cursor rule | `rules-{domain}.mdc` | `rules-swift.mdc` |

---

## Documentation Structure (Reference)

```
docs/
├── PROJECT_INDEX.md              ← Главный навигатор
├── SOURCE_OF_TRUTH.md            ← Матрица источников истины
├── AGENT_LOADING_GUIDE.md        ← Гид для AI-агентов
├── 01_source_of_truth/           ← Обзор проекта, индексы
├── 02_product_and_features/      ← Game design docs
├── 03_backend_and_api/           ← API reference
├── 04_database/                  ← Schema, migrations
├── 05_admin_panel/               ← Admin capabilities
├── 06_game_systems/              ← Combat, balance, progression
├── 07_ui_ux/                     ← Design system, screens, UX
├── 08_prompts/                   ← Art prompts
├── 09_rules_and_guidelines/      ← Legacy rules (keep for compat)
├── 10_operations/                ← Deploy, git, release
├── 11_archive/                   ← Deprecated docs
├── features/                     ← Per-feature documentation
│   ├── arena/
│   ├── guild-hall/
│   ├── dungeons/
│   ├── shop/
│   ├── battle-pass/
│   ├── daily-systems/
│   ├── combat/
│   ├── inventory/
│   ├── social/
│   ├── gold-mine/
│   ├── achievements/
│   └── minigames/
├── rules/                        ← Modular domain rules
│   ├── rules-swift.md
│   ├── rules-backend.md
│   ├── rules-ui-design.md
│   ├── rules-combat-pvp.md
│   ├── rules-economy.md
│   ├── rules-admin.md
│   ├── rules-db.md
│   ├── rules-deploy.md
│   ├── rules-audio.md
│   └── rules-art.md
├── templates/                    ← Doc templates
│   ├── TEMPLATE_FEATURE.md
│   ├── TEMPLATE_SCREEN.md
│   ├── TEMPLATE_API_MODULE.md
│   └── TEMPLATE_RULE.md
└── retro/                        ← Retrospectives
```

---

## Quality Criteria

After any doc operation, verify:
- [ ] No duplicate docs for the same topic
- [ ] All links resolve to existing files
- [ ] Source of Truth matrix is up to date
- [ ] Feature doc covers: overview, files, API, UI states, dependencies
- [ ] Rule file specifies: domain, when to read, what NOT covered
- [ ] `Last updated` header is current date
- [ ] Templates were used correctly

---

## When to Run

- **After major feature completion** — create feature doc
- **Weekly** — freshness check (Mode 1)
- **Before release** — full audit (Mode 1)
- **When agent asks "what docs exist for X"** — navigate (Mode 3)
- **When new API/screen/system is added** — create (Mode 2)

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
