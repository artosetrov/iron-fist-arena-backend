---
title: Block 059 — admin design-system residual debt and warning cleanup
category: audit
tags: [audit, admin, design-system, mail, warnings, cleanup]
sources:
  - admin/src/app/(dashboard)/design-system/figma-components/divider.tsx
  - admin/src/app/(dashboard)/design-system/page.tsx
  - admin/src/app/(dashboard)/design-system/ds-components.tsx
  - admin/src/app/(dashboard)/design-system/ds-components-2.tsx
  - admin/src/app/(dashboard)/items/_components/item-preview-card.tsx
  - admin/src/app/(dashboard)/mail/mail-client.tsx
  - admin/src/app/(dashboard)/social/page.tsx
  - admin/src/components/dashboard/economy-charts.tsx
  - admin/src/components/layout/nav-items.ts
  - admin/src/lib/auth.ts
updated: 2026-04-15
status: Fixed
---

# Block 059 — admin design-system residual debt and warning cleanup

## Scope

- `admin/src/app/(dashboard)/design-system/figma-components/divider.tsx`
- `admin/src/app/(dashboard)/design-system/page.tsx`
- `admin/src/app/(dashboard)/design-system/ds-components.tsx`
- `admin/src/app/(dashboard)/design-system/ds-components-2.tsx`
- `admin/src/app/(dashboard)/items/_components/item-preview-card.tsx`
- `admin/src/app/(dashboard)/mail/mail-client.tsx`
- `admin/src/app/(dashboard)/social/page.tsx`
- `admin/src/components/dashboard/economy-charts.tsx`
- `admin/src/components/layout/nav-items.ts`
- `admin/src/lib/auth.ts`

## Why this block

After the larger admin contract fixes, the main remaining admin noise had shifted into two buckets:

1. small warning-heavy files whose clutter was masking real issues
2. leftover preview/demo surfaces around `design-system` that were no longer obviously part of the live page contract

This block was worth doing because one of those “small warnings” in `mail-client` was actually hiding a real async state bug, not just cosmetic lint noise.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[design-system]]
- [[block-058-admin-appearances-and-design-system-preview-consistency]]

## File notes

### `admin/src/app/(dashboard)/design-system/figma-components/divider.tsx`

- **Zone:** admin / Figma preview wrapper
- **Purpose:** preview ornamental divider variants
- **Problems found:**
  - carried a dead `isGold` local that no longer affected rendering
- **What was fixed:**
  - removed the unused local
- **Status:** Fixed

### `admin/src/app/(dashboard)/design-system/page.tsx`

- **Zone:** admin / design-system page shell
- **Purpose:** top-level framing copy for the DS explorer
- **Problems found:**
  - copy claimed a full “Figma DS and SwiftUI code 1:1” mirror even though the page still contains a mix of Figma-derived previews and legacy fallback preview surfaces
- **What was fixed:**
  - softened the page description to “shared tokens, Figma-aligned component previews, and live reference screens”
- **Status:** Fixed

### `admin/src/app/(dashboard)/design-system/ds-components.tsx`

- **Zone:** admin / legacy fallback preview surface
- **Purpose:** handcrafted preview implementations for DS components that predate the Figma-derived wrappers
- **What was checked:**
  - still imported live by `design-system-client.tsx` for a few components not yet represented by the newer Figma preview set
- **Status:** OK

### `admin/src/app/(dashboard)/design-system/ds-components-2.tsx`

- **Zone:** admin / legacy domain preview surface
- **Purpose:** preview game-specific cards/widgets/screens not all covered by the Figma-derived set
- **Problems found:**
  - `HeroWidgetPreviews` and `StanceDisplayPreviews` now have no live imports from the design-system page
  - this file mixes still-used previews with likely-dead exports, which makes the page harder to treat as a clean source of truth
- **What was fixed in this block:**
  - no blind deletion yet; the file is now explicitly marked in the audit as a deprecation candidate for the next file-by-file pass
- **Status:** Needs review

### `admin/src/app/(dashboard)/items/_components/item-preview-card.tsx`

- **Zone:** admin / items editor preview
- **Purpose:** show a realistic item card while editing catalog data
- **Problems found:**
  - `fallbackImageKey` existed as API surface but was silently unused
- **What was fixed:**
  - used `fallbackImageKey` in the borrowed-art tooltip so the preview communicates where fallback media came from
- **Status:** Fixed

### `admin/src/app/(dashboard)/mail/mail-client.tsx`

- **Zone:** admin / liveops mail UI
- **Purpose:** compose, send, paginate, and delete inbox messages
- **Problems found:**
  - imported dead icons and still carried stale `isPending` references after earlier transition cleanup
  - more importantly, `startTransition(async () => ...)` let `isSending` reset before the async action actually finished
  - delete flow also depended on stale transition state and a captured `messages` array
- **What was fixed:**
  - removed dead icon import
  - replaced transition-driven send/delete flows with explicit awaited async handlers
  - added dedicated `isDeleting` handling
  - switched message removal to functional state update
- **Risk that was removed:**
  - before this fix, operators could see “Sending...” clear too early and potentially double-submit or get misleading UI feedback
- **Status:** Fixed

### `admin/src/app/(dashboard)/social/page.tsx`

- **Zone:** admin / social dashboard
- **Purpose:** read-only social moderation/monitoring page
- **Problems found:**
  - imported `Clock` but did not use it
- **What was fixed:**
  - removed the dead import
- **Status:** Fixed

### `admin/src/components/dashboard/economy-charts.tsx`

- **Zone:** admin / dashboard chart components
- **Purpose:** render economy snapshots and sink/inflow charts
- **Problems found:**
  - imported `ReferenceLine` without using it
- **What was fixed:**
  - removed the dead import
- **Status:** Fixed

### `admin/src/components/layout/nav-items.ts`

- **Zone:** admin / navigation config
- **Purpose:** source of truth for sidebar/grouped nav items
- **Problems found:**
  - imported `Package` without using it
- **What was fixed:**
  - removed the dead import
- **Status:** Fixed

### `admin/src/lib/auth.ts`

- **Zone:** admin / auth and role helpers
- **Purpose:** session resolution and capability helpers
- **Problems found:**
  - `canManagePlayers(role)` accepted a role parameter but ignored it, which was noisy and made the helper look less intentional than it is
- **What was fixed:**
  - made the function explicitly validate against `ALLOWED_ROLES`
- **Status:** Fixed

## Problems found

1. **`mail-client` had a real async-state bug hidden among lint debt**
   - Risk: the UI could leave the “sending” state too early and create duplicate submit/delete confusion for operators.
   - Fix: removed transition-based pseudo-async flow and awaited the actions directly.

2. **Design-system page copy overstated fidelity**
   - Risk: operators could assume every preview on the page was equally canonical when some still come from older handcrafted fallback surfaces.
   - Fix: updated the page copy to describe the page more honestly.

3. **`ds-components-2.tsx` now mixes live previews and probable dead exports**
   - Risk: dead preview code quietly drifts and makes future cleanups riskier.
   - Fix in this block: documented the candidate exports and deferred removal until their whole file slice is audited together.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/design-system/figma-components/divider.tsx`
  - `src/app/(dashboard)/design-system/page.tsx`
  - `src/app/(dashboard)/items/_components/item-preview-card.tsx`
  - `src/app/(dashboard)/mail/mail-client.tsx`
  - `src/app/(dashboard)/social/page.tsx`
  - `src/components/dashboard/economy-charts.tsx`
  - `src/components/layout/nav-items.ts`
  - `src/lib/auth.ts`
- `npx next build` in `admin/`
- `git diff --check`
- `rg -n "HeroWidgetPreviews|StanceDisplayPreviews" admin/src/app/'(dashboard)'/design-system -g '*.tsx'`

## Follow-up

- `admin/src/app/(dashboard)/design-system/ds-components-2.tsx` should get its own focused keep/delete pass
- the next remaining admin warning layer is now concentrated in image-heavy editors:
  - `dungeon-map-client.tsx`
  - `dungeons/[id]/dungeon-editor.tsx`
