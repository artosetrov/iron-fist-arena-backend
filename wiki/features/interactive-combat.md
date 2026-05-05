# Feature: Interactive Combat

> Single-file map of every file that touches Interactive Combat v1 — round-by-round active-skill layer on top of PvP.

## One-liner

Optional combat mode where the player slots up to N "active skills" before the fight and fires them during rounds, with cooldowns and opponent AI also firing actives. Runs on top of the classic PvP pipeline.

## Status

- **Phase:** Talents v2 ult action types shipped 2026-04-29 (`stealth` / `aoe_damage` / `cooldown_reset` / `aoe_stun` — see `wiki/audit/block-262-talents-v2-ult-action-types-and-class-trees`). Phase 3.B shipped 2026-04-13 (5 active effects + opp AI firing + iOS fire banner). Phase 3 shipped 2026-04-13 (burst_damage firing + cooldown ticks + iOS HUD + opponent preview). Phase 1 shipped 2026-04-13 (Active Slot schema + CRUD + iOS UI).
- **Last major change:** 2026-04-29 — Talents v2 ult action types + cross-round buff state pattern (`interactiveActives.{p1,p2}_buffs`)
- **Owner / last hands:** Artem

## Entry points

- **iOS screen(s):**
  - `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift` — main interactive combat screen
  - `Hexbound/Hexbound/Views/Combat/ActiveSkillsHUD.swift` — cooldown HUD (bottom-of-screen active-skill buttons)
- **Slot configuration UI:** Passive tree / hero screens → active-slot assignment
- **Player action:** Enter PvP via Arena → interactive path → tap active-skill button during round

## Backend

### Routes

#### Active Slot management
- `GET  /api/passives/active-slots`          — `backend/src/app/api/passives/active-slots/route.ts` — list current slots
- `POST /api/passives/active-slots`          — same file — slot change / persist
- `POST /api/passives/active-slots/batch`    — `backend/src/app/api/passives/active-slots/batch/route.ts` — bulk slot persist

#### Interactive match
- `POST /api/pvp/match/start`    — `backend/src/app/api/pvp/match/start/route.ts` — create interactive PvpMatch row
- `POST /api/pvp/strike`         — `backend/src/app/api/pvp/strike/route.ts` — submit one round; strike resolver fires actives, ticks cooldowns, returns round log
- `POST /api/pvp/match/complete` — `backend/src/app/api/pvp/match/complete/route.ts` — final resolution + rewards

### Business logic

- `backend/src/lib/game/active-slots.ts` — slot CRUD, validation, effect resolution
- `backend/src/lib/game/combat.ts` — shared combat core (inline calls into active-slots)
- `backend/src/lib/game/consumable-effects.ts` — some active effects overlap with consumables

### Prisma models touched

- `CharacterActiveSlot` (line 1325) — per-character-per-slot active skill binding
- `PvpMatch` (line 562) — match state, `status` column added for interactive tracking (migration applied via Supabase MCP)
- `Character` (line 429) — back-relation to active slots

## iOS

### Views

- `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift` — main screen, round animation, fire banner
- `Hexbound/Hexbound/Views/Combat/InteractiveBattleViewModel.swift` — `@Observable` state: round, HP, cooldowns
- `Hexbound/Hexbound/Views/Combat/ActiveSkillsHUD.swift` — cooldown HUD for actives
- `Hexbound/Hexbound/Views/Combat/InteractiveCombatComponents.swift` — shared sub-components (banners, cooldown pills, opponent active preview)
- `Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift` — per-round log card in the battle log

### Active-slot configuration

- Slot editor UI lives in the passive tree / hero screens (reuses existing slot pattern)
- Look under `Hexbound/Hexbound/Views/Hero/Talents/` for slot assignment

### Services

- `Hexbound/Hexbound/Services/PvPService.swift` — interactive match API calls
- `Hexbound/Hexbound/Services/PassiveTreeService.swift` — active-slot persistence
- `Hexbound/Hexbound/Services/CombatEngine.swift` — shared combat animation driver

## Admin

- No dedicated interactive-combat admin dashboard is checked in today
- `admin/src/app/(dashboard)/matches/page.tsx` — adjacent match-review surface
- `admin/src/app/(dashboard)/skills/page.tsx` — active-skill catalog/admin editing
- `admin/src/app/(dashboard)/passives/page.tsx` — adjacent active-slot / passive-tree editing surface

## Docs

- `docs/06_game_systems/COMBAT.md` — combat foundation
- `docs/features/combat/INTERACTIVE_COMBAT_PLAN.md` — checked-in rollout/deferred-work plan
- `docs/07_ui_ux/COMBAT_SCREEN_REDESIGN.md` — historical combat redesign exploration; current checked-in prototypes now include `prototypes/combat-proto-v3.html` and `prototypes/combat-duel-header-compact.html` as discussion-only follow-up surfaces
- `wiki/features/combat-unification-remaining.md` — current remaining unification tails around combat mode consolidation

## Notable gotchas

- **Server-authoritative.** Clients must NEVER compute active-skill damage or cooldown ticks — server owns all of it.
- **Migration-before-deploy rule.** `pvp_matches.status` column addition needed a production `ALTER TABLE` via Supabase MCP BEFORE the code deploy — shipping without it = 500s. Treat this as the same manual-first migration rule already documented by the interactive-combat/stash migration audit wave.
- **9 active effect types** supported as of Talents v2 (2026-04-29): `burst_damage`, `heal_self`, `shield_self`, `stun_enemy`, `execute`, `stealth`, `aoe_damage`, `cooldown_reset`, `aoe_stun`. Adding a 10th requires: enum migration via Supabase MCP **before** code deploy + resolver case + AI tier classification + iOS exhaustive-switch updates in 4 sites (`PassiveTree.swift`, `CombatLogEvent.swift`, `ActiveSkillsHUD.swift`, `InteractiveBattleViewModel.swift`). See `block-262`.
- **Talents v2 polish tail is bounded.** The four new ult action types are live in the resolver and HUD today; the remaining follow-up is presentation-only. `CombatLogEvent.talentAsset` and `InteractiveBattleViewModel.playActiveFireSFX` still use fallback VFX/SFX for `stealth`, `aoe_damage`, `cooldown_reset`, and `aoe_stun` until dedicated Vanish / Cataclysm / Rewind / Quake assets are commissioned.
- **Cross-round buff state.** `interactiveActives.{p1,p2}_buffs: ActiveBuffsState` holds effects that persist beyond the round of their fire. Currently used only by `aoe_stun` (`stunRoundsRemaining`); future cross-round effects (DoTs, charges, multi-round shields) attach the same way.
- **Opponent AI.** Opponent actives fire deterministically based on match seed — classic flow doesn't need to care, but interactive preview shows upcoming opp active.
- **Fire banner** was shipped 2026-04-13 as part of 3.B — iOS UI highlights which active just fired that round.

## Tests / fixtures

- No dedicated interactive-combat strike/active-slot backend test file is checked in today
- Adjacent PvP/runtime coverage lives in:
  - `backend/tests/api/pvp-resolve.test.ts`
  - `backend/tests/api/pvp-prepare-bot-ticket.test.ts`
  - `backend/tests/api/pvp-history.test.ts`

## Related features

- [[pvp-combat]] — parent feature; Interactive Combat is a flavor of PvP
- [[shop]] — consumables and some actives share effect resolver code
