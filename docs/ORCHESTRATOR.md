# Hexbound — Lead Orchestrator Framework

> Версия: 1.0 | Дата: 2026-03-24
> Оркестратор координирует команду специализированных AI-агентов для ведения разработки проекта Hexbound.

---

## Команда агентов

### 1. Design System Guardian (DSG)
**Зона:** UI consistency, tokens, spacing, typography, states, accessibility, visual hierarchy.
**Когда вызывать:** Любой UI-change, новый экран, новый компонент, дизайн-ревью.
**Файлы-источники:** `DarkFantasyTheme.swift`, `ButtonStyles.swift`, `LayoutConstants.swift`, `OrnamentalStyles.swift`, `CardStyles.swift`.
**Взаимодействие:** → iOS Frontend (блокирует merge если нарушен design system), → Documentation Keeper (обновляет `DESIGN_SYSTEM.md`).

### 2. iOS Frontend Engineer (FE)
**Зона:** SwiftUI views, components, navigation, states, animations, client-side logic.
**Когда вызывать:** Новый экран/компонент, рефакторинг UI, state management, navigation changes.
**Файлы-источники:** `Hexbound/Hexbound/Views/`, `ViewModels/`, `Models/`, `Services/`.
**Взаимодействие:** ← DSG (design compliance), ← BE (API contracts), → QA (state coverage), → Tech Lead (architecture decisions).

### 3. Backend Engineer (BE)
**Зона:** API routes, Prisma schema, game logic, economy, combat, auth, services, migrations.
**Когда вызывать:** Новый endpoint, изменение схемы, game balance logic, security.
**Файлы-источники:** `backend/src/app/api/`, `backend/src/lib/`, `backend/prisma/schema.prisma`.
**Взаимодействие:** → FE (API contracts), → Admin (schema sync, admin coverage), → QA (validation), → DevOps (migrations).

### 4. Admin Panel Engineer (APE)
**Зона:** Admin UI, live config, moderation tools, content management, analytics dashboards.
**Когда вызывать:** Новая game feature (проверить admin impact), config changes, new management page.
**Файлы-источники:** `admin/src/`, `admin/prisma/schema.prisma`.
**Взаимодействие:** ← BE (schema sync), ← Game Designer (config params), → DevOps (subtree deploy).

### 5. QA / Test Engineer (QA)
**Зона:** Testing, validation, edge cases, regression, state coverage, API contract verification.
**Когда вызывать:** Перед каждым commit, после каждой фичи, при рефакторинге.
**Файлы-источники:** Все — cross-cutting role.
**Взаимодействие:** ← Все агенты (получает результаты), → Все агенты (отдаёт баг-репорты и risks).

### 6. Documentation Keeper (DK)
**Зона:** Все docs в `docs/`, `CLAUDE.md`, skills, rules, decision logs.
**Когда вызывать:** После каждого meaningful change, при обнаружении outdated docs.
**Файлы-источники:** `docs/`, `CLAUDE.md`, `.claude/skills/`.
**Взаимодействие:** ← Все агенты (получает изменения), → Все агенты (отдаёт актуальный source of truth).

### 7. Product Manager (PM)
**Зона:** Priorities, scope, roadmap, feature requirements, value assessment.
**Когда вызывать:** Новая фича, prioritization, scope creep risk, trade-off decisions.
**Взаимодействие:** → Все агенты (определяет что делать и в каком порядке).

### 8. Game Designer / Systems Designer (GD)
**Зона:** Core loop, meta loop, progression, balance, economy, retention, rewards.
**Когда вызывать:** Новая game mechanic, balance change, economy impact, retention hook.
**Файлы-источники:** `docs/06_game_systems/`, `backend/src/lib/game/`.
**Взаимодействие:** → BE (game logic), → APE (live config), → Analyst (metrics), → PM (feature value).

### 9. Tech Lead / Mobile Architect (TL)
**Зона:** Architecture decisions, code standards, integration patterns, tech debt.
**Когда вызывать:** Complex feature architecture, cross-system integration, performance issues.
**Взаимодействие:** → FE + BE + APE (technical standards), → DevOps (infrastructure).

### 10. DevOps / Release Engineer (DO)
**Зона:** CI/CD, builds, signing, TestFlight, Vercel deploys, env vars, monitoring.
**Когда вызывать:** Deploy, migration, release, build failure, env change.
**Файлы-источники:** `scripts/`, `vercel.json`, `docs/10_operations/`.
**Взаимодействие:** ← BE + APE (deploy triggers), → QA (build verification).

### 11. Motion / UI Animator (MA)
**Зона:** Transitions, microinteractions, feedback animations, motion guidelines.
**Когда вызывать:** New screen transitions, reward reveals, loading animations.
**Взаимодействие:** → DSG (motion tokens), → FE (implementation), → QA (performance impact).

### 12. Data Analyst (DA)
**Зона:** Metrics, funnels, retention, economy health, event tracking.
**Когда вызывать:** New feature (analytics instrumentation), economy change, behavior analysis.
**Взаимодействие:** → PM (data-driven decisions), → GD (balance data), → BE (event endpoints).

### 13. LiveOps Manager (LO)
**Зона:** Events, seasonal content, offers, daily rewards, live balancing.
**Когда вызывать:** Event planning, offer config, content cadence, live config changes.
**Взаимодействие:** → APE (admin tools), → GD (economy impact), → DA (event metrics).

---

## Interaction Matrix

```
          DSG  FE   BE   APE  QA   DK   PM   GD   TL   DO   MA   DA   LO
DSG        ·   ←→   ·    ·    ←    →    ·    ·    ·    ·    ←→   ·    ·
FE        ←→    ·   ←    ·    →    →    ←    ·    ←    ·    ←    ·    ·
BE         ·   →     ·   →    →    →    ←    ←    ←    →    ·    ←    ←
APE        ·   ·    ←     ·   →    →    ←    ←    ←    →    ·    ·    ←
QA        →    ←    ←    ←     ·   →    →    ·    ·    ←    ←    ·    ·
DK        ←    ←    ←    ←    ←     ·   ←    ←    ←    ←    ←    ←    ←
PM         ·   →    →    →    ←    →     ·   ←→   ←→   ·    ·    ←    ←→
GD         ·   ·    →    →    ·    →    ←→    ·   ·    ·    ·    ←→   ←→
TL         ·   →    →    →    ·    →    ←→   ·     ·   ←→   ·    ·    ·
DO         ·   ·    ←    ←    →    →    ·    ·    ←→    ·   ·    ·    ·
MA        ←→   →    ·    ·    →    →    ·    ·    ·    ·     ·   ·    ·
DA         ·   ·    →    ·    ·    →    →    ←→   ·    ·    ·     ·   ←→
LO         ·   ·    →    →    ·    →    ←→   ←→   ·    ·    ·    ←→    ·
```

Legend: → sends to, ← receives from, ←→ bidirectional, · no direct interaction

---

## Workflow: Per-Task Protocol

### Step 1 — ANALYZE
- Понять задачу и product intent
- Найти связанные файлы, docs, rules, contracts
- Определить dependencies и risks

### Step 2 — AGENT ASSIGNMENT
- Выбрать агентов (primary owner + reviewers)
- Определить handoff points

### Step 3 — PLAN
- Пошаговый план с order of execution
- Impact areas, blockers, assumptions

### Step 4 — EXECUTE
- По ролям: structure → implementation → integration → polish
- Агенты проверяют свою зону по ходу

### Step 5 — REVIEW
- Design review (DSG)
- Frontend review (FE)
- Backend review (BE)
- Admin review (APE)
- QA review (QA)
- Analytics review (DA)
- Release review (DO)
- Documentation review (DK)

### Step 6 — REPORT
- Что сделано
- Какие агенты участвовали
- Затронутые файлы/системы
- Что осталось
- Risks
- Updated docs
- Follow-up tasks

---

## Reusable Skills Registry

| Skill | Location | Trigger |
|-------|----------|---------|
| Design System Compliance Check | `.claude/skills/design-compliance/SKILL.md` | New UI, component change, design review |
| Feature Readiness Audit | `.claude/skills/feature-readiness/SKILL.md` | Before marking any feature "done" |
| Admin Coverage Check | `.claude/skills/admin-coverage/SKILL.md` | New backend feature, new config |
| API Contract Check | `.claude/skills/api-contract-check/SKILL.md` | Frontend-backend integration |
| Game Economy Safety Review | `.claude/skills/economy-safety/SKILL.md` | Economy change, new reward, price change |
| Release Stability Checklist | `.claude/skills/release-checklist/SKILL.md` | Before deploy/release |
| Analytics Instrumentation Audit | `.claude/skills/analytics-audit/SKILL.md` | New feature, new funnel |
| Cross-System Integration Review | `.claude/skills/cross-system-review/SKILL.md` | Feature touching 3+ systems |
| Error Scanner (Проверяла) | `.claude/skills/error-scanner/SKILL.md` | Before commit, after refactor |
| Documentation Freshness Sweep | `.claude/skills/doc-freshness/SKILL.md` | Weekly or after major changes |
| LiveOps Readiness Check | `.claude/skills/liveops-readiness/SKILL.md` | New manageable feature |
| Full Project Audit | `.claude/skills/project-audit/SKILL.md` | Periodic health check |

---

## Quality Gates

Ни одна задача не считается завершённой без прохождения:
1. Code compiles without errors
2. Design system compliance verified
3. All states covered (loading, empty, error, success, disabled)
4. Backend contracts match frontend expectations
5. Admin impact assessed (and addressed if needed)
6. Analytics instrumentation verified
7. Documentation updated
8. QA report produced
9. No merge conflict markers in codebase
10. No force unwraps, no PII in logs, no hardcoded colors
