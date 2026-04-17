# Feature: Prestige

> Single-file map of every file that touches prestige — level reset with permanent multiplier carryover, unlocked after hitting max level.

## One-liner

At max level, players prestige: reset level + XP + passive allocations; keep a permanent prestige level with stat multiplier and unlock cosmetic badge.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS display:** Prestige level rendered on `IntegratedCharacterCard` / `CharacterDisplay` — see shared profile components
- **Trigger UI:** Prestige button / modal appears at max level (exact screen depends on build — search `HeroDetailView` / `CharacterProfileView`)
- **Player action:** Hit max level → prestige CTA → confirm → ceremony

## Backend

### Routes

- `POST /api/prestige`   — `backend/src/app/api/prestige/route.ts` — execute prestige (level check, reset, grant, fire achievements)

### Business logic

- `backend/src/lib/game/progression.ts` — level caps, prestige trigger
- `backend/src/lib/game/balance.ts` — `PRESTIGE_MULTIPLIER`, `MAX_PRESTIGE`, level cap per prestige tier
- `backend/src/lib/game/equipment-stats.ts` + `build-stats.ts` — apply prestige multiplier to derived stats
- `backend/src/lib/game/live-config.ts` — live-tuned prestige values

### Prisma models touched

- `Character.prestigeLevel` (line 323) — int, default 0, increments per prestige
- Reset cascade: `Character.level`, `Character.xp`, `CharacterPassive[]` (allocations wiped)

## iOS

### Views

- `Hexbound/Hexbound/Views/Components/IntegratedCharacterCard.swift` — displays prestige badge
- `Hexbound/Hexbound/Views/Components/CharacterDisplay.swift` — shared display component
- Prestige confirmation modal lives in Hero/Profile flow (search for `prestige` CTA in those views)

### Services

- No dedicated service — `APIClient` call to `/api/prestige` + character refresh

### Cache

- `GameDataCache.currentCharacter` — updates `prestigeLevel` on success; level/XP/passives reset

## Admin

- `admin/src/app/(dashboard)/characters/` — admin can manually adjust prestige level

## Docs

- `docs/06_game_systems/COMBAT.md` — prestige multiplier in stat math
- `docs/06_game_systems/BALANCE_CONSTANTS.md` — level caps + multipliers
- `docs/02_product_and_features/GAME_SYSTEMS.md` — progression narrative

## Notable gotchas

- **Destructive action.** Prestige wipes level, XP, allocated passives. Must gate with explicit confirmation modal — no double-tap path.
- **Atomic transaction.** Reset + grant + achievement fire must be in one transaction; partial = broken character (orphaned CharacterPassive rows, etc.).
- **Achievement hook.** `progression` category achievements fire on prestige (`updateMultipleAchievements()` called inside route).
- **Inventory preserved.** Prestige does NOT reset gear/gold/gems. Only level/XP/passives.
- **Not the same as season reset.** Battle Pass has its own seasonal reset — unrelated.
- **Max prestige cap.** `MAX_PRESTIGE` in `balance.ts` — past this, CTA must hide or show "max".

## Tests / fixtures

- `backend/src/__tests__/prestige/*` (if present)

## Related features

- [[characters]] — prestige lives on the Character row
- [[passive-tree]] — allocations wiped on prestige
- [[achievements]] — progression category counter increments
- [[pvp-combat]] — prestige multiplier affects stats
