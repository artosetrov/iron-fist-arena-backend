---
title: Block 050 — admin skills and passives proxy alignment
category: audit
tags: [audit, admin, skills, passives, proxy, auth]
sources:
  - admin/src/lib/backend-api.ts
  - admin/src/app/api/admin/skills/route.ts
  - admin/src/app/api/admin/passives/route.ts
  - admin/src/app/api/admin/passives/connections/route.ts
  - admin/src/app/(dashboard)/skills/skills-client.tsx
  - admin/src/app/(dashboard)/passives/passives-client.tsx
  - admin/src/app/(dashboard)/skills/page.tsx
  - admin/src/app/(dashboard)/passives/page.tsx
updated: 2026-04-15
status: Fixed
---

# Block 050 — admin skills and passives proxy alignment

## Scope

- `admin/src/lib/backend-api.ts`
- `admin/src/app/api/admin/skills/route.ts`
- `admin/src/app/api/admin/passives/route.ts`
- `admin/src/app/api/admin/passives/connections/route.ts`
- `admin/src/app/(dashboard)/skills/skills-client.tsx`
- `admin/src/app/(dashboard)/passives/passives-client.tsx`
- `admin/src/app/(dashboard)/skills/page.tsx`
- `admin/src/app/(dashboard)/passives/page.tsx`

## Why this block

After `item-balance` moved to authenticated admin proxy routes, `skills` and `passives` were the next obvious outliers:

1. both editors still fetched the backend directly from the browser;
2. both parsed `admin-token` manually in client code;
3. both duplicated backend base URL fallback logic in the UI layer.

The runtime was working, but the architecture had split into two admin patterns again.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[passive-tree]]
- [[progression]]
- [[bug-patterns]]

## File notes

### `admin/src/app/api/admin/skills/route.ts`

- **Zone:** admin / proxy API
- **Purpose:** same-origin proxy for canonical backend skills admin mutations
- **Depends on:** `getAdminUser()`, `proxyBackendAdminRoute(...)`
- **What was fixed:** added a thin authenticated proxy so the dashboard no longer sends browser requests straight to the backend app
- **Status:** Fixed

### `admin/src/app/api/admin/passives/route.ts`

- **Zone:** admin / proxy API
- **Purpose:** same-origin proxy for passive node CRUD
- **Depends on:** `getAdminUser()`, `proxyBackendAdminRoute(...)`
- **What was fixed:** added the missing proxy layer for passive node create/update/delete flows
- **Status:** Fixed

### `admin/src/app/api/admin/passives/connections/route.ts`

- **Zone:** admin / proxy API
- **Purpose:** same-origin proxy for passive connection create/delete flows
- **Depends on:** `getAdminUser()`, `proxyBackendAdminRoute(...)`
- **What was fixed:** added the missing proxy layer for connection mutations too, so the whole passive-tree editor now shares one auth/integration pattern
- **Status:** Fixed

### `admin/src/app/(dashboard)/skills/skills-client.tsx`

- **Zone:** admin / skills editor UI
- **Purpose:** create, update, delete, and filter combat skills
- **Problems found:**
  - manual browser cookie parsing for `admin-token`
  - duplicated backend API base URL helper
  - dead ternary that built the same URL in both branches
- **What was fixed:** switched the editor to same-origin `/api/admin/skills`, removed direct token parsing, and deleted the dead URL branch
- **Status:** Fixed

### `admin/src/app/(dashboard)/passives/passives-client.tsx`

- **Zone:** admin / passive-tree editor UI
- **Purpose:** create/update/delete passive nodes and graph connections
- **Problems found:**
  - manual browser cookie parsing for `admin-token`
  - duplicated direct-backend base URL logic
  - client-side auth plumbing mixed into every mutation path
- **What was fixed:** switched all node/connection mutations to same-origin admin proxy routes and removed the client token/API URL shims
- **Status:** Fixed

### `admin/src/app/(dashboard)/skills/page.tsx` and `admin/src/app/(dashboard)/passives/page.tsx`

- **Zone:** admin / page shells
- **Purpose:** read-side page entrypoints for skills and passive-tree editors
- **Status:** OK

## Problems found

1. **Admin browser code still talked to the backend app directly**
   - Risk: auth, base URL, and mutation behavior could drift file by file instead of being owned centrally.
   - Fix: added same-origin proxy routes for skills, passive nodes, and passive connections.

2. **Client code parsed `admin-token` manually**
   - Risk: UI code kept carrying auth details that belong in server-side admin integration code.
   - Fix: removed browser cookie parsing and let proxy routes own the auth boundary.

3. **`skills-client` carried dead URL branching**
   - Risk: small noise like this makes later contract drift harder to see.
   - Fix: collapsed to one canonical proxy URL.

## Verification

- targeted admin `eslint`:
  - `src/app/api/admin/skills/route.ts`
  - `src/app/api/admin/passives/route.ts`
  - `src/app/api/admin/passives/connections/route.ts`
  - `src/app/(dashboard)/skills/skills-client.tsx`
  - `src/app/(dashboard)/passives/passives-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- `skills` and `passives` page shells still read Prisma directly on the server side; that is acceptable for read-only list hydration today
- the broader admin app still has other direct backend/browser paths outside this slice, but the highest-risk mutation editors in the combat/talent area now follow the same proxy pattern as `item-balance`
