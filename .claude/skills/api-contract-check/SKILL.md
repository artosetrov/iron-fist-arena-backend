# API Contract Consistency Check

> Trigger: "api check", "проверь контракты", "contract check", or when frontend-backend integration changes.

## Purpose
Verify frontend Swift models match backend API responses exactly.

## Workflow

### Step 1 — Identify Endpoints
List all endpoints involved in the feature. Read `docs/03_backend_and_api/API_REFERENCE.md`.

### Step 2 — Backend Response Shapes
For each endpoint, open the route handler and document:
- HTTP method + path
- Request body shape (if POST/PUT)
- Response JSON shape (exact field names, types)
- camelCase vs snake_case (check `NextResponse.json()` call)

### Step 3 — Frontend Models
For each response, find the matching Swift `Codable` struct and verify:
- Property names match JSON keys
- Types match (Int vs String, optional vs required)
- CodingKeys: present only if backend sends snake_case (see CLAUDE.md CodingKeys rule)
- No invented properties that don't exist in API response

### Step 4 — APIClient Usage
Verify correct usage:
- `getRaw(_:params:)` — no `endpoint:` label, `params:` not `queryItems:`
- `postRaw(_:body:)` — returns `[String: Any]`, not `Data`
- `get(_:params:)` / `post(_:body:)` — generic typed versions
- Check async/await usage

### Step 5 — Error Handling
- API errors decoded correctly (`APIError` enum)
- `.serverError` has 2 associated values: `(statusCode:, message:)`
- 401 triggers session expiry flow (not toast)
- Network errors show retry toast

## Output
Per endpoint:
```
ENDPOINT: [method] [path]
BACKEND SHAPE: [fields]
FRONTEND MODEL: [struct name] — MATCH / MISMATCH [details]
CODINGKEYS: Correct / Incorrect / Unnecessary
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
