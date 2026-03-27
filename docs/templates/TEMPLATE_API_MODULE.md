# API Module: {MODULE_NAME}

> **Base path:** `/api/{module}/`
> **Source:** `backend/src/app/api/{module}/`
> **Last updated:** {YYYY-MM-DD}

---

## Overview

{Что покрывает этот модуль API}

## Endpoints

### `{METHOD} /api/{module}/{path}`

**Purpose:** {description}

**Auth:** Required / Optional / Admin-only

**Request:**
```json
{
  "field": "type — description"
}
```

**Response (200):**
```json
{
  "field": "type — description"
}
```

**Errors:**
| Code | Message | When |
|------|---------|------|
| 400 | {msg} | {condition} |
| 401 | Unauthorized | No/invalid token |
| 404 | Not found | {condition} |

---

## DB Models Used

- `{ModelName}` — {role}

## Game Logic

- Calls: `{function}()` from `{file}`
- Balance: uses `{config key}` from live-config

## Security

- Rate limiting: {yes/no, params}
- Row locking: {yes/no, for what}
- Input validation: {Zod schema / manual}

## Related

- iOS service: `{ServiceName}.swift`
- Admin page: `admin/src/...`
- Rules: `docs/rules/rules-backend.md`
