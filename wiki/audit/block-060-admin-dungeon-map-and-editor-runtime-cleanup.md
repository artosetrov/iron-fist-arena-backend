---
title: Block 060 — admin dungeon map and editor runtime cleanup
category: audit
tags: [audit, admin, dungeons, map-editor, images, async-state]
sources:
  - admin/src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx
  - admin/src/app/(dashboard)/dungeons/[id]/dungeon-editor.tsx
updated: 2026-04-15
status: Fixed
---

# Block 060 — admin dungeon map and editor runtime cleanup

## Scope

- `admin/src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx`
- `admin/src/app/(dashboard)/dungeons/[id]/dungeon-editor.tsx`

## Why this block

After the previous warning-heavy cleanup, the next remaining admin hot spot was the dungeon editing layer. These files looked like “mostly image warnings”, but one of them repeated the same async-state mistake we had already found in other admin screens: `useTransition(async ...)` was being used like a real awaited network save indicator.

So this block was about more than lint. It was about making the editor’s loading state truthful again and documenting where plain `<img>` is intentional in admin tooling.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[dungeons]]
- [[block-059-admin-design-system-residual-debt-and-warning-cleanup]]

## File notes

### `admin/src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx`

- **Zone:** admin / dungeon-map placement editor
- **Purpose:** visually position dungeon nodes over the world-map background
- **Problems found:**
  - kept an unused `containerRef`
  - triggered `@next/next/no-img-element` on the map image even though this is an editor surface that needs a direct DOM image ref for drag math
- **What was fixed:**
  - removed the dead `containerRef`
  - added an explicit local lint exemption to the map image so the warning does not keep masking unrelated problems
- **Why plain `<img>` is acceptable here:**
  - the editor relies on `getBoundingClientRect()` from the rendered image for node positioning math
  - the source is a fixed local map asset, not an ordinary content image in a production-facing surface
- **Status:** Fixed

### `admin/src/app/(dashboard)/dungeons/[id]/dungeon-editor.tsx`

- **Zone:** admin / dungeon content editor
- **Purpose:** edit dungeon metadata, bosses, waves, drops, and preview images
- **Problems found:**
  - used `useTransition(async ...)` as if it tracked the real network save lifecycle
  - this could clear the “Saving...” state before the `PUT` request actually finished
  - image preview blocks triggered repeated `<img>` warnings even though they intentionally render arbitrary operator-supplied URLs
- **What was fixed:**
  - replaced transition-based save flow with explicit awaited async save and a real `isSaving` state
  - kept the existing error/saved feedback but tied it to the actual request lifecycle
  - added explicit local lint exemptions for preview `<img>` tags where arbitrary admin-uploaded URLs are expected
- **Risk that was removed:**
  - the editor no longer implies “save complete” before the request has actually returned
- **Status:** Fixed

## Problems found

1. **Dungeon editor had false loading-state semantics**
   - Risk: operators could click around as if the save was done while the request was still in flight, especially on slower admin connections.
   - Fix: replaced `useTransition(async ...)` with explicit awaited save flow and a dedicated `isSaving` state.

2. **Dungeon admin image warnings were noisy but intentional**
   - Risk: real issues were getting buried under repeated `<img>` warnings from editor/preview surfaces that cannot cleanly move to `next/image`.
   - Fix: documented and localized the lint exemptions only where plain `<img>` is genuinely the right tool.

3. **Map editor carried dead state**
   - Risk: not dangerous by itself, but it added clutter to a file that needs to stay easy to reason about because drag math is UI-sensitive.
   - Fix: removed the unused ref.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/dungeon-map/dungeon-map-client.tsx`
  - `src/app/(dashboard)/dungeons/[id]/dungeon-editor.tsx`
- `npx next build` in `admin/`
- `git diff --check`
- `rg -n "isPending|useTransition" ...` confirms the old transition-based save path is gone from these files

## Follow-up

- the next remaining admin media-heavy layer is smaller now, but image-handling/editor consistency still deserves a broader pass outside the dungeon surfaces
- if we later want richer operator feedback, the dungeon editor would benefit from the same shared toast-based success/error pattern already used in newer admin screens
