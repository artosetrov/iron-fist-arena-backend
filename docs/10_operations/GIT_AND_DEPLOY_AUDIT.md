# Hexbound — Git & Deploy Audit

*Date: 2026-03-19. Derived from actual git config, Vercel configs, package.json, Fastlane, env files.*

---

## 1. EXECUTIVE SUMMARY

**Repos**: 1 monorepo (local), pushed to **2 GitHub repos** via 2 git remotes.

| Remote | GitHub Repo | Что содержит | Deploy |
|--------|-------------|-------------|--------|
| `origin` | `artosetrov/iron-fist-arena-backend` | Весь monorepo (backend + admin + iOS + docs + assets) | Backend → Vercel |
| `admin-deploy` | `artosetrov/iron-fist-arena-admin` | Subtree `/admin` | Admin → Vercel |

**Ветки**: только `main` (+ техническая `admin-subtree` для subtree push).

**CI/CD**: отсутствует полностью — нет GitHub Actions, нет workflows.

**Deploy**: Vercel auto-deploy при push в `main` (и backend, и admin — разные проекты).

**iOS**: Fastlane настроен, но release полностью ручной (Xcode → TestFlight).

**Главные проблемы**:
- Нет веток разработки — всё прямо в `main`
- Нет CI (ни тестов, ни lint, ни build check)
- 136 uncommitted файлов (включая наш cleanup)
- Prisma schema рассинхронизированы между backend и admin
- Миграции применяются вручную
- iOS Fastlane Appfile не настроен (placeholder Apple ID)

---

## 2. GIT STRUCTURE

### Remotes

| Remote | URL | Тип |
|--------|-----|-----|
| `origin` | `github.com/artosetrov/iron-fist-arena-backend` | Full monorepo |
| `admin-deploy` | `github.com/artosetrov/iron-fist-arena-admin` | Admin subtree only |

### Branches

| Branch | Remote tracking | Назначение |
|--------|----------------|-----------|
| `main` | `origin/main`, `admin-deploy/main` | Единственная рабочая ветка. Всё: dev, staging, prod |
| `admin-subtree` | — (local only) | Техническая ветка для `git subtree push` admin/ |

### Branch Strategy

**Фактическая**: trunk-based, один человек, всё в main.

Нет: feature branches, develop, staging, release, hotfix.

### Коммит стиль

- Conventional commits (`feat:`, `fix:`) — соблюдается
- Squash/rebase: нет, обычные коммиты
- Единственный автор: Artem Osetrov (37 коммитов)

### Uncommitted state

**136 файлов** с изменениями (наш docs cleanup + ранее несохранённые iOS/backend изменения).

---

## 3. DEPLOY FLOW

### Backend (Next.js API)

```
Local dev (npm run dev, port 3000)
    ↓
git push origin main
    ↓
Vercel auto-deploy (project: hexbound-backend)
    ↓
Production: api.hexboundapp.com (inference — based on iOS AppConstants)
```

- **Vercel project**: `prj_XbOGDTioVSx9uCibkGq3JI92sVJS`
- **Build command**: `prisma generate && next build`
- **TypeScript errors**: IGNORED в build (`ignoreBuildErrors: true` в next.config)
- **Preview deploys**: каждый push/PR получает preview URL от Vercel
- **Env vars**: настроены в Vercel Dashboard (Supabase, DB, CORS, Apple keys)

### Admin Panel (Next.js)

```
Local dev (npm run dev, port 3001)
    ↓
git subtree push --prefix=admin admin-deploy main
    ↓
Vercel auto-deploy (project: admin)
    ↓
Production: admin Vercel URL
```

- **Vercel project**: `prj_BiMipu3CdZ5topnENQxd9H2svcOc`
- **Build command**: `prisma generate && next build`
- **Деплой**: через `git subtree push`, НЕ из `origin` main
- **Env vars**: настроены в Vercel Dashboard

### hexbound-site (Static landing)

```
Static HTML (privacy.html, support.html)
    ↓
Deploy mechanism: NOT FOUND (no .vercel/ folder)
    ↓
Probably manual Vercel deploy or separate hosting
```

**Status**: вероятно, не задеплоен через CI. *inference*

### iOS App

```
Xcode → Build → Archive
    ↓
fastlane beta (increment build → build → upload TestFlight)
    ↓
TestFlight → Manual testing
    ↓
App Store submission (manual)
```

- **Bundle ID**: `com.hexbound.app`
- **Fastlane**: настроен (`beta`, `build`, `bump_*` lanes)
- **Appfile**: НЕ НАСТРОЕН (placeholder `YOUR_APPLE_ID@example.com`)
- **API URL**: hardcoded `https://api.hexboundapp.com` в `AppConstants.swift`
- **Supabase**: hardcoded URL + anon key в `AppConstants.swift`
- **Нет staging/dev переключателя** — всегда production endpoint

---

## 4. CI/CD INVENTORY

| Файл | Триггер | Назначение | Окружение | Статус |
|------|---------|-----------|-----------|--------|
| — | — | — | — | **НЕТ CI/CD ВООБЩЕ** |

`.github/workflows/` — директория не существует.

Нет: build checks, lint, tests, deploy automation, migration checks.

---

## 5. MIGRATION FLOW

### Где хранятся

`backend/prisma/migrations/` — 3 миграции:
1. `20260306_baseline` — начальная
2. `20260312_add_pvp_battle_tickets`
3. `20260316_add_daily_gem_card`

### Как применяются

- **Локально**: `npm run db:migrate:dev`
- **Production**: `npm run db:migrate:deploy` (вручную, или через Vercel build)
- **Admin**: нет своих миграций, нет `migrate deploy`

### Prisma Schema Sync

**CRITICAL**: Backend и Admin schema **РАЗЛИЧАЮТСЯ**.

Различия:
- Backend schema имеет `DailyGemCard` модель — Admin **нет**
- Backend имеет дополнительные `@@index` (9+ индексов)
- Backend имеет `gearScore` field на Character — Admin **нет**
- Backend имеет inline комментарии для PushCampaign/PushLog полей — Admin нет

### Риски

1. **Schema drift**: admin может крашиться на query к полям/моделям которые есть только в backend schema
2. **No migration CI**: можно забыть применить миграцию на production
3. **`db:push` warning**: есть в scripts, но с ручным предупреждением "local-only"

---

## 6. iOS RELEASE FLOW

### Текущий процесс

1. Разработка в Xcode (единственный разработчик)
2. `fastlane bump_patch` — инкремент версии
3. `fastlane beta` — build + upload TestFlight
4. Тестирование в TestFlight
5. Ручной submit в App Store Connect

### Проблемы

| Проблема | Критичность |
|----------|-------------|
| Appfile не настроен (placeholder Apple ID) | **Critical** — fastlane не сработает |
| API URL hardcoded production | **Medium** — нет staging/dev toggle |
| Supabase anon key hardcoded в Swift | **Medium** — при ротации ключа нужен re-build |
| Нет CI для iOS | Low — один разработчик, ok на данном этапе |
| Нет version/build в git tags | Low — теряется trace какой commit = какой build |

---

## 7. CONTRADICTIONS / RISKS

### Critical

| # | Проблема | Детали |
|---|----------|--------|
| 1 | **Prisma schema drift** | backend и admin имеют разные schema. Admin может крашиться. |
| 2 | **No CI/CD** | Можно запушить нерабочий код напрямую в production. |
| 3 | **TS build errors ignored** | `ignoreBuildErrors: true` в backend next.config — маскирует реальные ошибки. |
| 4 | **136 uncommitted files** | Большой diff может потерять историю или создать мерж конфликты. |

### High

| # | Проблема | Детали |
|---|----------|--------|
| 5 | **Всё в main** | Нет возможности тестировать перед production deploy. |
| 6 | **Admin subtree manual push** | Легко забыть — admin не деплоится при обычном `git push origin main`. |
| 7 | **No migration automation** | Миграции могут отстать от кода на production. |
| 8 | **Fastlane Appfile placeholder** | iOS release pipeline не работает без настройки. |

### Medium

| # | Проблема | Детали |
|---|----------|--------|
| 9 | **Hardcoded API URL в iOS** | Нет способа переключить на staging без пересборки. |
| 10 | **Нет git tags** | Невозможно определить какой commit соответствует какому iOS build или backend deploy. |
| 11 | **hexbound-site не в deploy pipeline** | Видимо деплоится вручную или не деплоится вовсе. |

### Low

| # | Проблема | Детали |
|---|----------|--------|
| 12 | **Нет branch protection** | Технически можно force push в main. |
| 13 | **GitHub token в git config** | Token в plaintext в .git/config (PAT). Не критично для local, но risk если repo shared. |

---

## 8. RECOMMENDED WORKFLOW

### Для текущего масштаба (1 разработчик)

Не нужно усложнять — trunk-based + preview deploys достаточно:

```
main (production)
  ↑
feature/xxx (short-lived, 1-3 days max)
  ↑
local dev
```

### Конкретные шаги

**Web/Admin/Backend deploy:**
1. Разработка в `feature/*` ветке
2. Push → Vercel Preview Deploy (автоматический)
3. Проверка preview URL
4. Merge в `main` → Vercel Production Deploy (автоматический)
5. Для admin: после merge в main → `git subtree push --prefix=admin admin-deploy main`

**iOS release:**
1. Разработка в Xcode
2. Настроить Appfile (Apple ID, Team ID)
3. `fastlane beta` для TestFlight
4. Git tag: `ios-v1.0.1-build42`

**Migrations:**
1. Создать: `npm run db:migrate:dev` (локально)
2. Синхронизировать admin schema: копировать `backend/prisma/schema.prisma` → `admin/prisma/schema.prisma`
3. Deploy: миграция применяется автоматически через Vercel build command `prisma generate && next build` — **НО** нужно добавить `prisma migrate deploy` в build command

**Минимальный CI (рекомендация):**
```yaml
# .github/workflows/check.yml
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd backend && npm ci && npm run build
      - run: cd admin && npm ci && npm run build
```

---

## 9. ACTION PLAN

### Quick Wins (можно сделать сегодня)

1. **Синхронизировать Prisma schema** — копировать backend → admin
2. **Закоммитить 136 файлов** — docs cleanup + iOS changes
3. **Создать `.github/workflows/build.yml`** — минимальный build check

### Medium Fixes (эта неделя)

4. **Добавить `prisma migrate deploy`** в Vercel build commands (backend + admin)
5. **Настроить Fastlane Appfile** — реальный Apple ID + Team ID
6. **Добавить iOS env switching** — dev/staging/prod через Xcode schemes или build config
7. **Убрать `ignoreBuildErrors: true`** из backend next.config (после фикса TS ошибок)
8. **Начать использовать git tags** для iOS builds

### Critical Fixes (перед launch)

9. **Настроить branch protection** на main (require PR, require build check)
10. **Добавить CI tests** — хотя бы для critical paths (PvP resolve, shop buy, auth)
11. **Задокументировать admin subtree push** — или автоматизировать через CI
12. **Вынести secrets из git config** — использовать SSH keys или `gh auth` вместо PAT в URL

---

## SOURCE OF TRUTH MAP

| Что | Source of Truth | Статус |
|-----|----------------|--------|
| **Web/Backend deploy** | Vercel project `hexbound-backend` + `origin/main` branch | ✅ Работает |
| **Admin deploy** | Vercel project `admin` + `admin-deploy/main` (subtree) | ⚠️ Ручной subtree push |
| **DB schema** | `backend/prisma/schema.prisma` | ⚠️ Admin schema отстаёт |
| **DB migrations** | `backend/prisma/migrations/` | ⚠️ Ручной deploy |
| **Mobile release** | Xcode + Fastlane (local) | ⚠️ Appfile не настроен |
| **Env/secrets** | Vercel Dashboard (web), `.env` files (local), `AppConstants.swift` (iOS) | ⚠️ iOS hardcoded |
| **Branch policy** | not found | ❌ Нет protection rules |
| **CI/CD** | not found | ❌ Нет workflows |
| **Git tags / releases** | not found | ❌ Нет тегирования |
| **Landing site deploy** | not found | ❌ Неясно как деплоится |
