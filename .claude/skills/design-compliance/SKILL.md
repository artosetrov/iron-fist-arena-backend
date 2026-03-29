# Design System Compliance Check

> Trigger: "design check", "проверь дизайн-систему", "design compliance", "token audit", or when reviewing any UI change.

## Purpose
Verify that UI code strictly follows the Hexbound design system: tokens, components, patterns, and rules from CLAUDE.md.

## Workflow

### Phase 1 — Token Verification
1. Open `DarkFantasyTheme.swift` — verify all color references exist
2. Open `ButtonStyles.swift` — verify all button styles exist
3. Open `LayoutConstants.swift` — verify all spacing/sizing tokens exist
4. Open `OrnamentalStyles.swift` — verify ornamental patterns used correctly

### Phase 2 — Grep Checks
Run these greps on changed/new Swift files:
```bash
# Hardcoded colors (FAIL if found)
grep -rn 'Color(hex:' --include="*.swift" | grep -v DarkFantasyTheme.swift | grep -v Theme/
grep -rn 'Color\.white\|Color\.black' --include="*.swift" | grep -v 'opacity(0.0[1-9])' | grep -v OrnamentalStyles

# Missing theme prefix (FAIL if found)
grep -rn '\.foregroundStyle(\.\|\.foregroundColor(\.' --include="*.swift" | grep -v DarkFantasyTheme

# Hardcoded cornerRadius (FAIL if found)
grep -rn 'cornerRadius: [0-9]' --include="*.swift" | grep -v LayoutConstants | grep -v 'width/2'

# SF Symbol currency icons (FAIL if found)
grep -rn 'dollarsign.circle\|diamond.fill' --include="*.swift" | grep -v '//'

# Wrong SFX names (FAIL if found)
grep -rn '\.tap\b\|\.confirm\b\|\.success\b\|\.error\b' --include="*.swift" | grep 'SFX\|sfx\|SoundManager'
```

### Phase 3 — Component Reuse
Check that these reusable components are used (not duplicated):
- `ItemCardView` for all item displays
- `UnifiedHeroWidget` for character summary
- `StanceDisplayView` for stance display
- `CurrencyDisplay` for gold/gems
- `TabSwitcher` for tab UI
- `GoldDivider` for dividers
- `RadialGlowBackground` for panel backgrounds

### Phase 4 — Ornamental Pattern
For every panel/card, verify:
- RadialGlowBackground (not flat bgSecondary)
- .surfaceLighting overlay
- .innerBorder overlay
- .cornerBrackets (on visible panels)
- Dual shadow (type + abyss)

### Phase 5 — States
Every interactive element must have: default, pressed, selected, disabled, loading, error.
Every list must have: empty state with CTA.
Loading: skeletons > spinners > blank.

## Output Format
```
✅ PASS: [description]
⚠️ WARN: [description] — [recommendation]
❌ FAIL: [description] — [exact fix needed]
```

## Severity
- ❌ FAIL = blocks merge
- ⚠️ WARN = should fix before release
- ✅ PASS = compliant

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
