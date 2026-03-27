# Rules: Admin Panel

> **Домен:** Admin UI (Next.js), live config, moderation, content management
> **Когда читать:** Работа с admin panel
> **НЕ покрывает:** iOS UI, Combat logic, Deploy

---

## Source of Truth

- Admin pages: `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- Admin code: `admin/src/`
- Schema: `admin/prisma/schema.prisma` (MUST mirror backend)

## Strict Null Checks

Когда функция возвращает `T | null` — ВСЕГДА narrow перед использованием. `if (!x) throw` + explicit non-null assertion.

## Build Before Push

`npx next build` локально ИЛИ проверь Vercel preview перед merge в main.

## Prisma Schema Sync (CRITICAL)

После ЛЮБОГО изменения `backend/prisma/schema.prisma`:
1. `cd backend && npm run db:migrate:dev -- --name your_change`
2. `cp backend/prisma/schema.prisma admin/prisma/schema.prisma`
3. Commit оба файла вместе

**Если пропустишь шаг 2 → CI упадёт, admin может crash на deploy.**

## Admin Subtree Deploy

После `git push origin main`, если `admin/` изменился:
```bash
git subtree push --prefix=admin admin-deploy main
```
**Без этого admin panel НЕ обновится.**

## 80+ Config Keys

Все live config keys описаны в `ADMIN_CAPABILITIES.md`. Перед добавлением нового — проверь существующие.

## Form Validation

React Hook Form + Zod для всех admin форм. Валидация на клиенте + сервере.
