# Feature: {FEATURE_NAME}

> **Status:** {Draft | In Progress | Complete | Deprecated}
> **Owner:** {who is responsible}
> **Last updated:** {YYYY-MM-DD}
> **Source of truth:** {link to canonical source — code file or doc}

---

## Overview

{1-3 предложения: что делает эта фича, зачем она нужна}

## User Value

{Какую ценность получает игрок}

## Systems Involved

| System | Role | Source file |
|--------|------|------------|
| {iOS screen} | {UI display} | `Hexbound/Hexbound/Views/...` |
| {Backend route} | {Logic/data} | `backend/src/app/api/...` |
| {DB model} | {Storage} | `backend/prisma/schema.prisma` → Model |
| {Admin page} | {Management} | `admin/src/...` |

## Key Files

- iOS: `{path}`
- Backend: `{path}`
- Admin: `{path}`
- Tests: `{path}`

## Game Design

{Механика, формулы, ограничения}

## API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/...` | {description} |
| `POST` | `/api/...` | {description} |

## UI States

- **Loading:** {skeleton / spinner / cached}
- **Empty:** {empty state CTA}
- **Error:** {error toast + retry}
- **Success:** {normal display}

## Dependencies

- Depends on: {other features/systems}
- Depended by: {features that rely on this}

## Known Issues / TODOs

- [ ] {issue}

## Related Docs

- Rules: `docs/rules/{relevant-rule}.md`
- Design: `docs/07_ui_ux/...`
- Balance: `docs/06_game_systems/...`
