# Hexbound — Agent Loading Guide

> **Last updated:** 2026-03-26
> Для AI-агентов. Перед началом работы — загрузи ТОЛЬКО нужные документы.
> Не читай всё подряд. Читай по задаче.

---

## Быстрый старт

1. **ВСЕГДА** начни с `CLAUDE.md` (корень проекта) — он уже в контексте
2. Определи тип задачи по таблице ниже
3. Загрузи ТОЛЬКО перечисленные документы
4. Если нужны правила — читай из `docs/rules/`

---

## Матрица загрузки

### iOS Frontend

| Задача | Загрузить |
|--------|----------|
| Новый экран | `docs/rules/rules-swift.md` → `docs/rules/rules-ui-design.md` → `docs/07_ui_ux/SCREEN_INVENTORY.md` |
| Новый компонент | `docs/rules/rules-ui-design.md` → проверить `Hexbound/Hexbound/Theme/` файлы |
| Рефакторинг экрана | `docs/rules/rules-swift.md` → соответствующий `docs/features/` doc |
| Анимации / Motion | `docs/rules/rules-ui-design.md` → `docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md` |
| Combat UI (боевка) | `docs/rules/rules-combat-pvp.md` → `docs/rules/rules-ui-design.md` |

### Backend

| Задача | Загрузить |
|--------|----------|
| Новый endpoint | `docs/rules/rules-backend.md` → `docs/03_backend_and_api/API_REFERENCE.md` |
| Изменение схемы | `docs/rules/rules-db.md` → `backend/prisma/schema.prisma` |
| Game logic | `docs/rules/rules-backend.md` → соответствующий `docs/06_game_systems/` doc |
| Economy endpoint | `docs/rules/rules-economy.md` → `docs/rules/rules-backend.md` |
| Auth / Security | `docs/rules/rules-backend.md` → `API_REFERENCE.md` (auth section) |

### Game Design / Balance

| Задача | Загрузить |
|--------|----------|
| Баланс тюнинг | `docs/rules/rules-economy.md` → `docs/06_game_systems/BALANCE_CONSTANTS.md` |
| Новая механика | `docs/02_product_and_features/GAME_SYSTEMS.md` → `docs/rules/rules-combat-pvp.md` |
| Экономика | `docs/rules/rules-economy.md` → `docs/02_product_and_features/ECONOMY.md` |
| Прогрессия | `docs/06_game_systems/PROGRESSION.md` → `BALANCE_CONSTANTS.md` |

### Admin Panel

| Задача | Загрузить |
|--------|----------|
| Новая страница | `docs/rules/rules-admin.md` → `docs/05_admin_panel/ADMIN_CAPABILITIES.md` |
| Live config | `docs/rules/rules-admin.md` → `ADMIN_CAPABILITIES.md` (config keys section) |
| Admin + backend sync | `docs/rules/rules-admin.md` → `docs/rules/rules-db.md` |

### Operations

| Задача | Загрузить |
|--------|----------|
| Деплой backend | `docs/rules/rules-deploy.md` → `docs/10_operations/DEPLOY.md` |
| iOS release | `docs/rules/rules-deploy.md` → `docs/10_operations/RELEASE_IOS.md` |
| DB migration | `docs/rules/rules-db.md` → `docs/10_operations/DATABASE_MIGRATIONS.md` |
| Git workflow | `docs/rules/rules-deploy.md` → `docs/10_operations/GIT_WORKFLOW.md` |

### Art / Audio

| Задача | Загрузить |
|--------|----------|
| Новый ассет | `docs/rules/rules-art.md` → `docs/08_prompts/ART_STYLE_GUIDE.md` |
| AI image prompt | `docs/rules/rules-art.md` → `docs/08_prompts/ASSET_PROMPTS_INDEX.md` |
| Звук / музыка | `docs/rules/rules-audio.md` → `docs/02_product_and_features/AUDIO_DESIGN.md` |

### Cross-cutting

| Задача | Загрузить |
|--------|----------|
| Новая фича (end-to-end) | `PROJECT_INDEX.md` → rules по доменам → feature doc если есть |
| Code review | `docs/rules/rules-swift.md` (iOS) или `rules-backend.md` (TS) → `CLAUDE.md` |
| UX audit | `docs/rules/rules-ui-design.md` → `docs/07_ui_ux/UX_AUDIT.md` |
| Documentation update | `docs/SOURCE_OF_TRUTH.md` → соответствующий doc |

---

## Правила для агентов

1. **Не читай всё.** Загружай только то, что указано для твоей задачи.
2. **CLAUDE.md — всегда в контексте.** Его не нужно загружать отдельно.
3. **Код > документация.** При конфликте — верь коду (см. `SOURCE_OF_TRUTH.md`).
4. **После работы — обнови docs.** Если ты изменил API, экран, схему — обнови соответствующий doc.
5. **Не создавай дублей.** Перед созданием нового doc — проверь `PROJECT_INDEX.md`.
