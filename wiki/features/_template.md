# Feature: {{Name}}

> **Purpose.** A single-file map of every file that touches this feature — backend, iOS, admin, docs, tests.
> Use this when you need to reason about the feature end-to-end without opening every folder.
> Keep it flat. One file per bullet. No prose essays.

## One-liner

{{One sentence describing what the feature does for the player.}}

## Status

- **Phase:** {{MVP / In production / Deprecated}}
- **Last major change:** {{YYYY-MM-DD — commit or note}}
- **Owner / last hands:** {{name}}

## Entry points

- **iOS screen(s):** `Hexbound/Hexbound/Views/.../{{Screen}}.swift`
- **Navigation route:** `AppRouter.{{case}}`
- **Player action that starts the flow:** {{e.g. tap Gold Mine on hub}}

## Backend

### Routes

- `{{METHOD}} /api/{{path}}` — `backend/src/app/api/{{path}}/route.ts` — {{one-line purpose}}

### Business logic

- `backend/src/lib/.../{{file}}.ts` — {{what it does}}

### Prisma models touched

- `{{ModelName}}` (`backend/prisma/schema.prisma`) — {{role in this feature}}

### Balance constants

- `backend/src/lib/game/balance.ts` → `{{CONSTANT_NAME}}` — {{value / meaning}}

## iOS

### Views

- `Hexbound/Hexbound/Views/.../{{File}}.swift` — {{role}}

### ViewModels

- `Hexbound/Hexbound/ViewModels/{{VM}}.swift` — {{state it owns}}

### Services

- `Hexbound/Hexbound/Services/{{Service}}.swift` — {{API it wraps}}

### Cache

- `GameDataCache.{{key}}` — {{what is cached}}

## Admin

- `admin/src/app/.../{{page}}.tsx` — {{tuning/monitoring UI}}

## Docs

- `docs/06_game_systems/{{file}}.md` — {{canonical spec}}
- `docs/02_product_and_features/{{file}}.md` — {{product-level description}}

## Notable gotchas

- {{Known pitfall, past incident, rule that isn't obvious from the code}}

## Tests / fixtures

- `backend/src/__tests__/.../{{file}}.test.ts`
- Fixtures / seed: `{{file}}`

## Related features

- [[{{other-feature-slug}}]] — {{how they interact}}
