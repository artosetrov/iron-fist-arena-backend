# Feature: Stamina

> Single-file map of every file that touches stamina — time-gated resource consumed by PvP / dungeons / training, regenerates over time, refillable for gems with diminishing returns.

## One-liner

Stamina gates combat activities (PvP fight, dungeon run, training). Regenerates 1 point per 8 minutes, max 180. Players can refill for gems up to 4× per day on a 1× / 1.6× / 2.8× / 4.8× curve.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS component:** `Hexbound/Hexbound/Views/Components/StaminaBarView.swift` — shared stamina bar (3 Figma variants: compact / widget / large)
- **Surfaced on:** Hub header, PvP card, Dungeon cards, Hero screen
- **Player action:** Tap stamina bar → refill modal (gem cost + day-index) OR auto-wait for regen

## Backend

### Routes

- `GET  /api/stamina`          — `backend/src/app/api/stamina/route.ts` — current stamina, max, next-tick, refills-today
- `POST /api/stamina/refill`   — `backend/src/app/api/stamina/refill/route.ts` — gem-cost refill (diminishing returns enforced)

Consuming routes (call internal stamina lib, not the HTTP route):
- `/api/pvp/fight` — spends `STAMINA.PVP_COST`
- `/api/dungeons/start` — spends `STAMINA.DUNGEON_EASY|NORMAL|HARD` based on tier
- `/api/minigames/training/*` — spends `STAMINA.TRAINING`

### Business logic

- `backend/src/lib/game/stamina.ts` — lazy-regen calculator (reads `lastStaminaUpdate`, credits regen on access), spend guards, refill cost resolver
- `backend/src/lib/game/balance.ts` → `STAMINA` (costs + regen rate), `STAMINA_REFILL_DR` (cost curve + daily cap), `GEM_COSTS.STAMINA_REFILL`, `staminaRefillGemCost()` helper

### Prisma models touched

- `Character.currentStamina` (line 345, `@map("current_stamina")`) — int, default 180
- `Character.maxStamina` (line 346, `@map("max_stamina")`) — int, default 180
- `Character.lastStaminaUpdate` (line 347, `@map("last_stamina_update")`) — DateTime, anchor for lazy regen
- `Character.staminaRefillsToday` (line 363) — int, default 0
- `Character.staminaRefillsDate` (line 364) — DateTime for day-rollover reset

### Balance constants

```
STAMINA.MAX = 180
STAMINA.REGEN_RATE = 1
STAMINA.REGEN_INTERVAL_MINUTES = 8      // 0 → max in 24h
STAMINA.PVP_COST = 10
STAMINA.DUNGEON_EASY = 15
STAMINA.DUNGEON_NORMAL = 20
STAMINA.DUNGEON_HARD = 25
STAMINA.BOSS = 40
STAMINA.TRAINING = 5
STAMINA.FREE_PVP_PER_DAY = 3
STAMINA_REFILL_DR.COST_MULTIPLIERS = [1, 1.6, 2.8, 4.8]
STAMINA_REFILL_DR.DAILY_CAP = 4         // 5th+ refill blocked
GEM_COSTS.STAMINA_REFILL = 50           // base; actual = base × multiplier[n]
```

## iOS

### Views

- `Hexbound/Hexbound/Views/Components/StaminaBarView.swift` — the shared component (Figma-backed; see Progress Bars page)

### Consumable item path

Stamina potions are a separate delivery path — handled by [[inventory]] (`ConsumableInventory` rows with `consumableType` ∈ `stamina_potion_small` / `_medium` / `_large`) and use the `/api/inventory/use` endpoint, not the refill endpoint.

### Cache

- `GameDataCache.currentCharacter` — `currentStamina`, `maxStamina`, `staminaRefillsToday`, `lastStaminaUpdate`. Tick-regen is recomputed client-side using `lastStaminaUpdate` + wall clock for UI, but authoritative value comes from backend every refresh.

## Admin

- No dedicated per-character stamina editor is checked in today
- `admin/src/app/(dashboard)/config/page.tsx` — live tuning surface for stamina and refill config keys
- `admin/src/app/(dashboard)/balance/page.tsx` — adjacent balance review surface

## Docs

- `docs/06_game_systems/BALANCE_CONSTANTS.md` — STAMINA table + refill curve
- `docs/02_product_and_features/ECONOMY.md` → R8 (stamina rules, refill DR)

## Notable gotchas

- **Lazy regen, not a cron.** Stamina only "ticks" when a request reads `Character.currentStamina`. Backend lib checks `lastStaminaUpdate`, computes elapsed minutes, credits `(elapsed / REGEN_INTERVAL) × REGEN_RATE`, caps at `maxStamina`, then writes back. No scheduled job.
- **Client UI tick is cosmetic.** iOS decrements visible timer, but the authoritative current/max always comes from backend — never spend client-side.
- **Refill day rollover = `staminaRefillsDate`.** Compare stored date to server UTC day; reset counter when day changes. Client doesn't compute this.
- **Diminishing returns are enforced by backend.** `staminaRefillGemCost()` returns `null` past `DAILY_CAP=4` — UI must render "refill locked until tomorrow".
- **Two price envelopes.** `GEM_COSTS.STAMINA_REFILL = 50` is base; actual cost = base × `COST_MULTIPLIERS[n]` → 50 / 80 / 140 / 240.
- **Potions ≠ refill.** Using a `stamina_potion_*` is an inventory action, not a gem refill — does NOT count against `staminaRefillsToday`.
- **Economy v3 raised MAX from 120 → 180** (2026-04-14). Two daily check-ins now fully use overnight regen. Balance migration already live — don't revert to 120.

## Tests / fixtures

- `backend/tests/api/stamina-refill.test.ts`
- `backend/tests/lib/stamina.test.ts`
- `backend/tests/lib/stamina-refill-dr.test.ts`

## Related features

- [[pvp-combat]] — largest stamina consumer
- [[dungeons]] — cost per tier
- [[inventory]] — stamina potions delivered via consumables, not refill endpoint
- [[daily-login]] — rewards granting stamina potions
- [[shop]] — gem bundles purchased to fund refills
