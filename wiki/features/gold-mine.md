# Feature: Gold Mine

> Single-file map of every file that touches the Gold Mine feature.

## One-liner

Idle gold-generation minigame — player owns mining shafts that accumulate gold over time, with a tap-based minigame to boost yields.

## Status

- **Phase:** In production
- **Last major change:** 2026-10-16 — screen rework (surface + foreman, expedition chest track, tunnel levels with a cart on rails, tunnel sheet); bonus round optional; expedition chest (5 carts); no shaft picker; `economy` block on `/status`
- **Earlier:** 2026-04-11 — Gold Mine schema migration incident (fields added without migration file → prod 500s; fixed via Supabase MCP)
- **Owner / last hands:** Artem

## Entry points

- **iOS screen:** `Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift`
- **Navigation route:** `AppRouter` → tap Gold Mine building on `HubView`
- **Player action:** Tap Gold Mine on city hub → detail view → collect / buy slot / play slot minigame

## Backend

### Routes (all under `/api/minigames/gold-mine/`)

- `POST /boost` — `backend/src/app/api/minigames/gold-mine/boost/route.ts`
- `POST /buy-slot` — `backend/src/app/api/minigames/gold-mine/buy-slot/route.ts`
- `POST /collect` — `backend/src/app/api/minigames/gold-mine/collect/route.ts`
- `POST /collect-all` — `backend/src/app/api/minigames/gold-mine/collect-all/route.ts`
- `POST /minigame-bonus` — `backend/src/app/api/minigames/gold-mine/minigame-bonus/route.ts`
- `POST /slot-minigame` — `backend/src/app/api/minigames/gold-mine/slot-minigame/route.ts`
- `POST /start` — `backend/src/app/api/minigames/gold-mine/start/route.ts`
- `GET  /status` — `backend/src/app/api/minigames/gold-mine/status/route.ts`

### Business logic

- `backend/src/lib/game/gold-mine.ts` — shaft accrual, slot cost/yield, minigame reward calc
- `backend/src/lib/game/gold-mine-expedition.ts` — expedition track: one haul per collected cart, chest at 5 (`EXPEDITION_CHEST_GOLD/GEMS`), next expedition auto-starts
- `backend/src/lib/game/shaft-catalog.ts` — shaft tiers (bonus-round backdrops), bonus-round cap/gem terms
- `backend/src/lib/game/balance.ts` — GOLD_MINE_* constants (rates, caps, cooldowns)

### Prisma models touched

- `GoldMineSession` (`backend/prisma/schema.prisma` line 667) — per-character per-slot mining state
- `MinigameSession` (line 695) — shared minigame session tracking
- `Character` — gold balance, mine_slots_unlocked counter

### Balance constants

- Source: `backend/src/lib/game/balance.ts`
- See generated: `wiki/_generated/prisma-models.json` → `models.GoldMineSession`
- See docs: `docs/06_game_systems/BALANCE_CONSTANTS.md`

## iOS

### Views

- `Hexbound/Hexbound/Views/Minigames/GoldMineDetailView.swift` — main screen: surface, ground beam, expedition track, shaft of tunnel levels, sticky Collect All bar
- `Hexbound/Hexbound/Views/Minigames/MineSurfaceHeader.swift` — gold/gems, head-frame art, Mine Foreman (`npc-mine`) with a live status line; tap him for economy tips
- `Hexbound/Hexbound/Views/Minigames/GoldMineCards.swift` — `MineTunnelLevel` (art + state pill + cart on code-drawn rails), `MineSealedLevel`, `MineExpeditionTrack`, ladder, badges, chips
- `Hexbound/Hexbound/Views/Minigames/GoldMineTunnelSheet.swift` — tap a tunnel: haul range, optional bonus run, double haul, send / collect
- `Hexbound/Hexbound/Views/Minigames/GoldMineMiniGameView.swift` — tap minigame overlay (optional bonus run)
- `Hexbound/Hexbound/Views/Minigames/MineClaimRewardView.swift` — reward ceremony for Collect All, bonus run and the expedition chest (tap to open)
- Assets: `Assets.xcassets/GoldMine/` (carts, chests, hourglass, bonus/boost/lock icons) — prompts in `docs/08_prompts/GOLD_MINE_ASSETS_PROMPTS.md`
- `Hexbound/Hexbound/Views/Minigames/MinigameCatchEffect.swift` — particle burst on successful tap
- `Hexbound/Hexbound/Views/Minigames/TavernDetailView.swift` — sibling screen (Tavern uses same minigame chassis)

### ViewModels

- `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift` — `@Observable` state: slots, expedition, server `economy`, optimistic send/collect/boost/buy, foreman lines, payout refresh when a timer ends

### Reward surface

- **Gold / gem payouts use the mine reward modal, not a toast.**
  - `collect-all` deltas and slot-minigame bonus payouts both flow through `GoldMineViewModel.claimReward`
  - `GoldMineDetailView` presents `MineClaimRewardView`
  - a single-cart collect shows "+N" over its tunnel instead; the modal opens for it only when the cart fills the expedition chest
  - structural toasts remain only for failures (send, collect, boost, tunnel purchase)

### Services

- `Hexbound/Hexbound/Services/GameDataCache.swift` — cached Gold Mine status key
- `Hexbound/Hexbound/Services/GameInitService.swift` — prefetches Gold Mine status on app launch
- `Hexbound/Hexbound/Network/APIEndpoints.swift` — endpoint constants for the 8 routes above
- `Hexbound/Hexbound/Persistence/AmbientManager.swift` — Gold Mine ambient loop
- `Hexbound/Hexbound/Persistence/SFXCatalog.swift` — tap SFX for minigame

### Models

- `Hexbound/Hexbound/Models/MinigameSession.swift` — matches backend `MinigameSession` model

### Cache

- `GameDataCache.goldMineSlots` / `goldMineEconomy` / `goldMineExpedition` — last known mine state, prices and chest track (instant UI on entry)

## Admin

- No dedicated Gold Mine admin page is checked in today
- `admin/src/app/(dashboard)/economy/page.tsx` — adjacent economy review surface
- `admin/src/app/(dashboard)/config/page.tsx` — adjacent live-config tuning surface
- `admin/src/app/(dashboard)/minigame-sessions/page.tsx` — recent minigame session review surface

## Docs

- `docs/06_game_systems/ECONOMY_RULES.md` — gold mine is a gold source
- `docs/06_game_systems/ECONOMY_AUDIT_2026-04-13.md` — audit results including mine economy
- `docs/06_game_systems/BALANCE_CONSTANTS.md` — canonical rate values
- `docs/06_game_systems/PROGRESSION.md` — mine unlock gates
- `docs/04_database/SCHEMA_REFERENCE.md` → GoldMineSession section

## Notable gotchas

- **2026-04-11 incident:** New fields added to `GoldMineSession` in `schema.prisma` without a migration file. Prisma Client generated locally against the new schema, but prod DB didn't have the columns → `PrismaClientKnownRequestError` 500s on every gold-mine endpoint. Fix: apply `ALTER TABLE` via Supabase MCP **before** the code deploy, or include the migration in the commit. This is now part of the project-wide manual-first migration rule.
- Collect endpoint is **optimistic** on iOS — UI adds gold immediately, API runs in background, rollback on failure.
- Shaft catalog changes require admin tuning + live-config reload.

## Tests / fixtures

- No dedicated Gold Mine backend test file is checked in today
- Seed: admin has shaft catalog seeder

## Related features

- [[pvp-combat]] — gold sink (wager, entry fees)
- [[shop]] — gold sink (consumables, upgrades)
