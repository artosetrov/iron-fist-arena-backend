# Feature: Events

> Single-file map of every file that touches live events — time-boxed promotional / gameplay modifiers (XP boosts, special shops, etc).

## One-liner

Admin-scheduled time-windowed events deliver banners, modifiers, and rewards; active events surface on hub and in relevant screens.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - Hub home — `EventBannerView.swift` slot shows active event
  - Event-specific screens (shop discounts, boosted dungeons, etc) applied inline
- **iOS component:** `Hexbound/Hexbound/Views/Components/EventBannerView.swift` (2 variants in Figma DS)
- **Player action:** Passive (banners appear when events active) / tap banner for details

## Backend

### Routes

- `GET  /api/events/active`   — `backend/src/app/api/events/active/route.ts` — active events relevant to this character

### Business logic

- `backend/src/lib/game/events.ts` — event activation check, modifier resolver, config parser

### Prisma models touched

- `Event` (line 1033) — event catalog:
  - `eventKey` — unique string key
  - `eventType` — enum (`EventType`)
  - `config` — Json (typed per eventType)
  - `startAt` / `endAt` — time window
  - `isActive` — soft on/off
  - `@@index([isActive, startAt, endAt])` — fast "what's live now" query

## iOS

### Views

- `Hexbound/Hexbound/Views/Components/EventBannerView.swift` — rotating banner component (Hub, screens)

### Cache

- `GameDataCache.activeEvents` — refreshed on launch and on hub enter

## Admin

- `admin/src/app/(dashboard)/events/page.tsx` — event cards/admin page
- `admin/src/app/(dashboard)/events/events-client.tsx` — live event CRUD + config JSON surface

## Docs

- `docs/02_product_and_features/GAME_SYSTEMS.md` — high-level liveops/event role in the runtime
- `docs/05_admin_panel/ADMIN_CAPABILITIES.md` — event scheduling

## Notable gotchas

- **Config schema is untyped in DB.** `config: Json` — admin editor must validate per `eventType` or live code will 500.
- **Server time only.** `startAt`/`endAt` are UTC — client only displays; eligibility is server-side.
- **Index matters.** `@@index([isActive, startAt, endAt])` supports the hot active-events query — keep filters aligned.
- **Banner rotation.** Multiple active events cycle — UI must handle 0 / 1 / N events.
- **Event modifiers apply inline.** Boosted XP / discounts are applied by the respective gameplay system (pvp, shop, dungeon) reading active-events from cache, not by the event system directly.

## Tests / fixtures

- No dedicated backend `events` test file is checked in today; event behavior is exercised through the active-events route plus the systems that consume event modifiers

## Related features

- [[daily-login]] — events can boost daily-login rewards
- [[shop]] — events can enable special shop offers
- [[pvp-combat]] — events can grant XP/gold multipliers
- [[quests]] — event-gated quests can be published as time-boxed entries
