# Hexbound — Source of Truth Matrix

> **Last updated:** 2026-03-26
> Какой документ является истиной для какого домена.
> Если два документа противоречат — побеждает тот, что в колонке "Source of Truth".

---

## Матрица

| Домен | Source of Truth | Secondary Docs | Когда читать |
|-------|----------------|----------------|-------------|
| **Архитектура проекта** | `docs/01_source_of_truth/PROJECT_OVERVIEW.md` | `docs/PROJECT_INDEX.md` | Первое знакомство, обзор систем |
| **DB Schema** | `backend/prisma/schema.prisma` (код) | `docs/04_database/SCHEMA_REFERENCE.md` | Любая работа с БД |
| **API Endpoints** | `backend/src/app/api/` (код) | `docs/03_backend_and_api/API_REFERENCE.md` | Работа с API |
| **Цвета, шрифты, токены** | `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift` (код) | `docs/07_ui_ux/DESIGN_SYSTEM.md` | Любая работа с UI |
| **Стили кнопок** | `Hexbound/Hexbound/Theme/ButtonStyles.swift` (код) | `docs/07_ui_ux/DESIGN_SYSTEM.md` | UI кнопки |
| **Spacing / Layout** | `Hexbound/Hexbound/Theme/LayoutConstants.swift` (код) | `docs/07_ui_ux/DESIGN_SYSTEM.md` | UI layout |
| **Ornamental система** | `Hexbound/Hexbound/Theme/OrnamentalStyles.swift` (код) | `CLAUDE.md` → Ornamental section | UI панели/карточки |
| **Combat формулы** | `backend/src/lib/game/combat.ts` (код) | `docs/06_game_systems/COMBAT.md` | PvP/Combat |
| **Balance константы** | `backend/src/lib/game/balance.ts` + `live-config.ts` | `docs/06_game_systems/BALANCE_CONSTANTS.md` | Баланс, тюнинг |
| **Progression** | `backend/src/lib/game/progression.ts` (код) | `docs/06_game_systems/PROGRESSION.md` | Левелинг, XP |
| **Economy дизайн** | `docs/02_product_and_features/ECONOMY.md` | `BALANCE_CONSTANTS.md`, `ADMIN_CAPABILITIES.md` | Экономика, цены, IAP |
| **Game Systems дизайн** | `docs/02_product_and_features/GAME_SYSTEMS.md` | Feature-specific docs | Общий обзор систем |
| **Экраны iOS** | `docs/07_ui_ux/SCREEN_INVENTORY.md` | Код в `Hexbound/Hexbound/Views/` | Навигация, состояния |
| **Admin capabilities** | `docs/05_admin_panel/ADMIN_CAPABILITIES.md` | Код в `admin/src/` | Работа с админкой |
| **Dev Rules (критичные)** | `CLAUDE.md` (корень) | `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` | ВСЕГДА |
| **UI/UX принципы** | `docs/09_rules_and_guidelines/UI_UX_PRINCIPLES.md` | `docs/07_ui_ux/UX_AUDIT.md` | Дизайн экранов |
| **Audio дизайн** | `docs/02_product_and_features/AUDIO_DESIGN.md` | — | Звук, музыка |
| **Art Style** | `docs/08_prompts/ART_STYLE_GUIDE.md` | `ASSET_PROMPTS_INDEX.md` | Ассеты |
| **Deploy flow** | `docs/10_operations/DEPLOY.md` | `GIT_WORKFLOW.md`, `RELEASE_IOS.md` | Деплой |
| **Achievement catalog** | `backend/src/lib/game/achievement-catalog.ts` (код) | `GAME_SYSTEMS.md` | Достижения |
| **Lore / World** | `docs/02_product_and_features/WORLD_AND_LORE.md` | — | Нарратив, тексты |

---

## Правило разрешения конфликтов

1. **Код > Документация.** Если `schema.prisma` говорит одно, а `SCHEMA_REFERENCE.md` другое — верь коду.
2. **CLAUDE.md > DEVELOPMENT_RULES.md.** CLAUDE.md — самый актуальный, обновляется при каждом таске.
3. **Feature doc > общий doc.** Если есть `docs/features/arena/ARENA_OVERVIEW.md`, он точнее чем описание арены в `GAME_SYSTEMS.md`.
4. **Новый doc > старый doc.** Смотри дату `Last updated` в шапке.
5. **При сомнениях — проверь код.** Открой файл и убедись.
