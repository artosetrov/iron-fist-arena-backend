# Hexbound — Project Index

> **Главный навигатор проекта.** Если ты агент или разработчик — начни отсюда.
> Last updated: 2026-03-26

---

## Что это за проект

**Hexbound** — PvP dark fantasy RPG для iOS с бэкендом на Next.js и полной админ-панелью. Ranked PvP, подземелья, крафт, прогрессия, Battle Pass, магазин, достижения, ежедневные системы, мини-игры.

## Стек

| Платформа | Технологии |
|-----------|-----------|
| **iOS клиент** | Swift / SwiftUI, iOS 16.4+, 38+ экранов |
| **Backend** | Next.js 15.2 / TypeScript 5.7, Prisma 6.4, PostgreSQL (Supabase), Upstash Redis |
| **Admin** | Next.js 15.2, Tailwind 4.0, Radix UI, Recharts, React Hook Form + Zod |
| **Хостинг** | Vercel (backend + admin), App Store (iOS) |
| **БД** | PostgreSQL (Supabase), 40+ моделей Prisma |

---

## Карта папок проекта

```
Hexbound/                   ← iOS приложение (SwiftUI)
  Hexbound/Views/           ← Экраны и компоненты (Hexbound/Hexbound/Views/)
  Hexbound/ViewModels/      ← @Observable view models (Hexbound/Hexbound/ViewModels/)
  Hexbound/Models/          ← Data models (Codable) (Hexbound/Hexbound/Models/)
  Hexbound/Services/        ← API/network сервисы (Hexbound/Hexbound/Services/)
  Hexbound/Theme/           ← DarkFantasyTheme, ButtonStyles, LayoutConstants, OrnamentalStyles (Hexbound/Hexbound/Theme/)
  Hexbound.xcodeproj/       ← Xcode project (pbxproj!)

backend/                    ← Next.js API
  src/app/api/              ← REST endpoints
  src/lib/game/             ← Game logic (combat, balance, progression, economy)
  prisma/schema.prisma      ← DB schema (SOURCE OF TRUTH)

admin/                      ← Admin panel (Next.js)
  src/                      ← Admin pages, components
  prisma/schema.prisma      ← MUST mirror backend/prisma/schema.prisma

docs/                       ← Документация (ты здесь)
scripts/                    ← Утилиты (git-watcher, deploy)
```

---

## Source of Truth Map

| Домен | Главный документ | Доп. документы |
|-------|-----------------|----------------|
| **Проект в целом** | `docs/01_source_of_truth/PROJECT_OVERVIEW.md` | Этот файл |
| **DB Schema** | `backend/prisma/schema.prisma` | `docs/04_database/SCHEMA_REFERENCE.md` |
| **API** | `docs/03_backend_and_api/API_REFERENCE.md` | Код в `backend/src/app/api/` |
| **UI Design System** | `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift` | `docs/07_ui_ux/DESIGN_SYSTEM.md` |
| **Button Styles** | `Hexbound/Hexbound/Theme/ButtonStyles.swift` | `docs/07_ui_ux/DESIGN_SYSTEM.md` |
| **Layout Constants** | `Hexbound/Hexbound/Theme/LayoutConstants.swift` | `docs/07_ui_ux/DESIGN_SYSTEM.md` |
| **Ornamental System** | `Hexbound/Hexbound/Theme/OrnamentalStyles.swift` | `CLAUDE.md` → Ornamental section |
| **Game Balance** | `backend/src/lib/game/balance.ts` + `live-config.ts` | `docs/06_game_systems/BALANCE_CONSTANTS.md` |
| **Combat System** | `backend/src/lib/game/combat.ts` | `docs/06_game_systems/COMBAT.md` |
| **Economy** | `docs/02_product_and_features/ECONOMY.md` | `BALANCE_CONSTANTS.md` |
| **Экраны iOS** | `docs/07_ui_ux/SCREEN_INVENTORY.md` | Код в `Hexbound/Hexbound/Views/` |
| **Admin Panel** | `docs/05_admin_panel/ADMIN_CAPABILITIES.md` | Код в `admin/src/` |
| **Dev Rules (CRITICAL)** | `CLAUDE.md` (корень проекта) | `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` |
| **Audio** | `docs/02_product_and_features/AUDIO_DESIGN.md` | — |
| **Art Style** | `docs/08_prompts/ART_STYLE_GUIDE.md` | `ASSET_PROMPTS_INDEX.md` |
| **Deploy** | `docs/10_operations/DEPLOY.md` | `GIT_WORKFLOW.md` |

---

## Модульные правила (Rules)

Правила разбиты по доменам. Canonical source — `docs/rules/`, зеркало для Cursor — `.cursor/rules/`.

| Файл | Домен | Когда читать |
|------|-------|-------------|
| `rules-swift.md` | iOS / SwiftUI код | Любая работа с Swift |
| `rules-backend.md` | Backend / TypeScript | Любая работа с API/backend |
| `rules-ui-design.md` | UI дизайн система | Любая работа с UI |
| `rules-combat-pvp.md` | Combat, PvP, Arena | Работа с боевой системой |
| `rules-economy.md` | Economy, Shop, IAP | Работа с экономикой |
| `rules-admin.md` | Admin panel | Работа с админкой |
| `rules-db.md` | Database, Prisma | Работа со схемой/миграциями |
| `rules-deploy.md` | Git, Deploy, CI/CD | Деплой, коммиты |
| `rules-audio.md` | Sound, Music, Haptics | Работа со звуком |
| `rules-art.md` | Art assets, Image gen | Создание ассетов |

---

## Agent Loading Strategy

### "Какие docs читать для моей задачи?"

| Задача | Читать ПЕРВЫМ | Потом |
|--------|--------------|-------|
| **Новый экран iOS** | `rules-swift.md` + `rules-ui-design.md` | `SCREEN_INVENTORY.md`, `DESIGN_SYSTEM.md`, тема в `DarkFantasyTheme.swift` |
| **Новый API endpoint** | `rules-backend.md` + `rules-db.md` | `API_REFERENCE.md`, `SCHEMA_REFERENCE.md` |
| **PvP / Combat** | `rules-combat-pvp.md` | `COMBAT.md`, `BALANCE_CONSTANTS.md`, `backend/src/lib/game/combat.ts` |
| **Arena UI** | `rules-swift.md` + `rules-combat-pvp.md` + `rules-ui-design.md` | `features/arena/ARENA_OVERVIEW.md` |
| **Баланс/экономика** | `rules-economy.md` | `ECONOMY.md`, `BALANCE_CONSTANTS.md`, `ADMIN_CAPABILITIES.md` |
| **Магазин** | `rules-economy.md` + `rules-ui-design.md` | `features/shop/`, `ECONOMY.md` |
| **Подземелья** | `rules-combat-pvp.md` | `features/dungeons/`, `GAME_SYSTEMS.md` |
| **Админка** | `rules-admin.md` + `rules-backend.md` | `ADMIN_CAPABILITIES.md` |
| **Звук/музыка** | `rules-audio.md` | `AUDIO_DESIGN.md` |
| **Ассеты/арт** | `rules-art.md` | `ART_STYLE_GUIDE.md`, `ASSET_PROMPTS_INDEX.md` |
| **DB миграция** | `rules-db.md` + `rules-deploy.md` | `SCHEMA_REFERENCE.md`, `DATABASE_MIGRATIONS.md` |
| **Деплой** | `rules-deploy.md` | `DEPLOY.md`, `GIT_WORKFLOW.md` |
| **Battle Pass** | `rules-economy.md` | `features/battle-pass/`, `GAME_SYSTEMS.md` |
| **Daily login/quests** | `rules-economy.md` + `rules-swift.md` | `features/daily-systems/`, `GAME_SYSTEMS.md` |
| **Social (Guild Hall)** | `rules-swift.md` + `rules-backend.md` | `features/guild-hall/`, `SOCIAL_FLOWS_UX_SPEC.md` |
| **Achievements** | `rules-backend.md` | `features/achievements/`, `GAME_SYSTEMS.md` |
| **Inventory/Equipment** | `rules-swift.md` + `rules-backend.md` | `features/inventory/`, `GAME_SYSTEMS.md` |

---

## Quick Links

| Категория | Файлы |
|-----------|-------|
| **Core docs** | [PROJECT_OVERVIEW](01_source_of_truth/PROJECT_OVERVIEW.md) · [GAME_SYSTEMS](02_product_and_features/GAME_SYSTEMS.md) · [ECONOMY](02_product_and_features/ECONOMY.md) |
| **Backend** | [API_REFERENCE](03_backend_and_api/API_REFERENCE.md) · [SCHEMA_REFERENCE](04_database/SCHEMA_REFERENCE.md) · [COMBAT](06_game_systems/COMBAT.md) · [BALANCE](06_game_systems/BALANCE_CONSTANTS.md) |
| **UI/UX** | [DESIGN_SYSTEM](07_ui_ux/DESIGN_SYSTEM.md) · [SCREEN_INVENTORY](07_ui_ux/SCREEN_INVENTORY.md) · [UX_AUDIT](07_ui_ux/UX_AUDIT.md) |
| **Admin** | [ADMIN_CAPABILITIES](05_admin_panel/ADMIN_CAPABILITIES.md) |
| **Rules** | [rules/](rules/) · [DEVELOPMENT_RULES](09_rules_and_guidelines/DEVELOPMENT_RULES.md) |
| **Ops** | [DEPLOY](10_operations/DEPLOY.md) · [GIT_WORKFLOW](10_operations/GIT_WORKFLOW.md) · [RELEASE_IOS](10_operations/RELEASE_IOS.md) |
| **Art** | [ART_STYLE_GUIDE](08_prompts/ART_STYLE_GUIDE.md) · [ASSET_PROMPTS](08_prompts/ASSET_PROMPTS_INDEX.md) |
| **Features** | [arena](features/arena/) · [shop](features/shop/) · [dungeons](features/dungeons/) · [combat](features/combat/) · [inventory](features/inventory/) · [guild-hall](features/guild-hall/) · [battle-pass](features/battle-pass/) · [daily-systems](features/daily-systems/) · [achievements](features/achievements/) · [gold-mine](features/gold-mine/) · [minigames](features/minigames/) · [social](features/social/) |
| **Templates** | [templates/](templates/) — шаблоны для новых docs |

---

## Навигация по документации

Полный индекс всех файлов: [`DOCUMENTATION_INDEX.md`](01_source_of_truth/DOCUMENTATION_INDEX.md)
Шаблоны для новых docs: [`templates/`](templates/)
Модульные правила: [`rules/`](rules/)
Feature docs: [`features/`](features/)
Ретроспективы: [`retro/`](retro/)
Архив: [`11_archive/`](11_archive/)
