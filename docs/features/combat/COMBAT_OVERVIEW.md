# Feature: Combat System

> **Status:** Complete
> **Owner:** Core gameplay
> **Last updated:** 2026-03-26
> **Source of truth:** `backend/src/lib/game/combat.ts`

---

## Overview

Turn-based server-authoritative combat с seeded RNG. Используется в PvP (арена, revenge, duels) и PvE (подземелья). Damage popups, VFX, combat log.

## Key Files

**iOS Views:**
- `Views/Combat/CombatDetailView.swift` — live combat UI (HP bars, turn log, damage popups)
- `Views/Combat/CombatResultDetailView.swift` — результаты (XP, loot, rating)
- `Views/Combat/LootDetailView.swift` — loot reward claiming
- `Views/Combat/VFX/CombatVFXManager.swift` — оркестрация эффектов
- `Views/Combat/VFX/CombatVFXOverlay.swift` — render layer
- `Views/Combat/VFX/Effects/DamageHitEffects.swift` — damage numbers
- `Views/Combat/VFX/Effects/HealEffect.swift` — heal popups
- `Views/Combat/VFX/Effects/DodgeMissBlock.swift` — miss/dodge indicators

**ViewModel:** `CombatViewModel.swift` — playback, turn log, damage popups (capped at 5)
**Services:** `CombatService.swift`, `CombatEngine.swift`, `BattlePreloader.swift`
**Model:** `Models/CombatData.swift`

**Backend Logic:**
- `backend/src/lib/game/combat.ts` — `runCombat()` (async!), damage calc, RNG
- `backend/src/lib/game/combat-loader.ts` — load combat data
- `backend/src/lib/game/stamina.ts` — stamina regen
- `backend/src/lib/game/durability.ts` — equipment degradation

## CombatResult Fields

`winnerId`, `loserId`, `turns: Turn[]`, `totalTurns: number`, `finalHp: Record<string, number>`

НЕТ `.log`, `.duration`, `.player1FinalHp`.

## DamageType Enum

`physical`, `magical`, `true_damage`, `poison`

## Performance Rules

- `.compositingGroup()` after ornamental stacks
- Damage popups capped at 5 concurrent
- `.repeatForever` animations stop on `.onDisappear`

## Rules (CRITICAL)

- **Server-authoritative:** клиент НЕ считает результаты
- **`runCombat()` is async** — всегда `await`
- **`calculateCurrentStamina()` takes 3 args** — не 4

## Dependencies

- Used by: Arena (PvP), Dungeons (PvE), Guild Hall (Duels)
- Depends on: Character stats, Equipment, Stamina

## Related Docs

- `docs/rules/rules-combat-pvp.md`, `docs/06_game_systems/COMBAT.md`, `docs/06_game_systems/BALANCE_CONSTANTS.md`
