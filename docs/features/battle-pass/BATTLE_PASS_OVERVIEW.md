# Feature: Battle Pass

> **Status:** Complete
> **Owner:** Monetization / Progression
> **Last updated:** 2026-03-26
> **Source of truth:** `Hexbound/Hexbound/Views/BattlePass/` + `backend/src/app/api/battle-pass/`

---

## Overview

Сезонный Battle Pass с free и premium тирами. Прогрессия через XP. Награды: gold, gems, items, cosmetics.

## Key Files

**iOS Views:**
- `Views/BattlePass/BattlePassDetailView.swift` — основной экран, tier progression
- `Views/BattlePass/BPRewardNodeView.swift` — ячейка награды тира
- `Views/BattlePass/SeasonSummaryModalView.swift` — итоги сезона

**ViewModel:** `BattlePassViewModel.swift` — claims, premium purchase, optimistic UI
**Service:** `Services/BattlePassService.swift`
**Model:** `Models/BattlePassData.swift`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/battle-pass` | Текущий статус BP |
| `POST` | `/api/battle-pass/claim/[level]` | Забрать награду тира |
| `POST` | `/api/battle-pass/buy-premium` | Купить premium BP |

**Backend Logic:** `backend/src/lib/game/battle-pass.ts`

## Hub Badge

Building `battlepass` → count of claimable tier rewards (free + premium if owned, level ≤ current)

## Rules

- Optimistic UI: mark tier claimed instantly, silent background refresh
- Badge = gold capsule on hub building

## Dependencies

- Depends on: XP/progression system, Economy
- Depended by: Hub building badge

## Related Docs

- `docs/rules/rules-economy.md`, `docs/02_product_and_features/ECONOMY.md`
