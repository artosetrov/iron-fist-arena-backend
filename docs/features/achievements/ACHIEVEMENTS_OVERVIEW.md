# Feature: Achievements

> **Status:** Complete (3 categories, 21 achievements)
> **Owner:** Progression / Retention
> **Last updated:** 2026-03-26
> **Source of truth:** `backend/src/lib/game/achievement-catalog.ts`

---

## Overview

21 достижение в 3 категориях. Все tracked автоматически. Rewards можно claim.

## Categories & Tracking

| Category | Count | Where tracked |
|----------|-------|--------------|
| `pvp` | 9 | `pvp/fight`, `pvp/resolve`, `pvp/revenge/[id]` |
| `progression` | 5 | `applyLevelUp()`, `prestige/route.ts` |
| `ranking` | 4 | `pvp/fight`, `pvp/resolve` (after ELO update) |

**`absolute: true` mode** — for streaks, ratings, levels (SET value, not increment).

## Key Files

**iOS Views:**
- `Views/Achievements/AchievementsDetailView.swift` — 3 вкладки: PvP, Progress, Ranking
- `Views/Achievements/AchievementCardView.swift` — карточка достижения

**ViewModel:** `AchievementsViewModel.swift` — tabs `["pvp", "progression", "ranking"]`
**Service:** `Services/AchievementService.swift`
**Model:** `Models/Achievement.swift`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/achievements` | Все достижения |
| `POST` | `/api/achievements/claim` | Забрать награду |
| `POST` | `/api/achievements/[key]/claim` | Забрать конкретное |

**Backend Logic:**
- `backend/src/lib/game/achievement-catalog.ts` — catalog (SOURCE OF TRUTH)
- `backend/src/lib/game/achievements.ts` — `updateMultipleAchievements()` engine

## Adding New Achievements (CRITICAL)

1. Add to `ACHIEVEMENT_CATALOG` in `achievement-catalog.ts`
2. Add tracking call in relevant route
3. Add display metadata in `achievements/route.ts`
4. Verify iOS `tabCategories` includes category
5. **НЕ добавляй без шага 2** — будет 0/N навсегда

## Hub Badge

Building `achievements` → count of unclaimed rewards (`cache.achievements.filter(\.canClaim).count`)

## Related Docs

- `docs/rules/rules-backend.md`, `docs/02_product_and_features/GAME_SYSTEMS.md`
