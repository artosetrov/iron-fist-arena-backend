# Analytics Instrumentation Audit

> Trigger: "analytics check", "проверь аналитику", "tracking audit", or when new feature affects user behavior.

## Purpose
Verify that key user actions and funnels have proper event tracking.

## Workflow

### Step 1 — Feature Events
For the feature, identify events that MUST be tracked:
- **Action events**: button taps, purchases, battles started, items used
- **Funnel events**: screen viewed, step started, step completed, step abandoned
- **Error events**: API failures, validation errors, timeout
- **Economy events**: gold earned, gold spent, gems earned, gems spent (with source/sink label)
- **Session events**: session start, session end, duration

### Step 2 — Check Backend Tracking
Verify backend logs/tracks:
- Purchase transactions
- Combat results
- Reward grants
- Level ups
- Economy transactions

### Step 3 — Check Client Tracking
Verify iOS tracks (if analytics SDK integrated):
- Screen views
- Button taps on key CTAs
- Funnel step completion
- Error encounters

### Step 4 — Funnel Coverage
For each user flow, verify the complete funnel is trackable:
- Onboarding: register → character create → tutorial → first battle
- PvP: arena enter → opponent select → fight → result → reward claim
- Shop: shop open → item view → purchase → use
- Dungeon: select → enter → room clear → boss → loot

### Step 5 — Gap Analysis
List:
- Events that should exist but don't
- Funnels that can't be analyzed
- Economy transactions without audit trail

## Output
```
FEATURE: [name]
EVENTS NEEDED: [list]
EVENTS PRESENT: [list]
GAPS: [list]
PRIORITY: [Critical/High/Medium/Low]
```

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
