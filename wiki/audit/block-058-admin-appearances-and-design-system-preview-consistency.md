---
title: Block 058 — admin appearances and design-system preview consistency
category: audit
tags: [audit, admin, appearances, design-system, ui-contracts]
sources:
  - admin/src/lib/appearance-skins.ts
  - admin/src/actions/appearances.ts
  - admin/src/app/(dashboard)/appearances/appearances-client.tsx
  - backend/src/app/api/characters/route.ts
  - Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift
  - Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift
  - admin/src/app/layout.tsx
  - admin/src/app/(dashboard)/design-system/design-system-client.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/button.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/card.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/currency-display.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/navigation.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/hero-widget.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/tab-switcher.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/ornamental-title.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/state-view.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/wager-button.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/widget-pill.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/loading-overlay.tsx
  - admin/src/app/(dashboard)/design-system/figma-components/stance-display.tsx
updated: 2026-04-15
status: Fixed
---

# Block 058 — admin appearances and design-system preview consistency

## Scope

- `admin/src/lib/appearance-skins.ts`
- `admin/src/actions/appearances.ts`
- `admin/src/app/(dashboard)/appearances/appearances-client.tsx`
- `backend/src/app/api/characters/route.ts`
- `Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`
- `Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift`
- `admin/src/app/layout.tsx`
- `admin/src/app/(dashboard)/design-system/design-system-client.tsx`
- `admin/src/app/(dashboard)/design-system/figma-components/{button,card,currency-display,navigation,hero-widget,tab-switcher,ornamental-title,state-view,wager-button,widget-pill,loading-overlay,stance-display}.tsx`

## Why this block

Two adjacent admin surfaces had drifted in ways that were easy to miss in day-to-day editing:

1. the `appearances` editor allowed impossible or dangerous states for the live client runtime, especially around default skins and their prices
2. the `design-system` page was loading Google fonts inline inside preview components instead of using the app layout, which created noisy Next warnings and made preview fidelity depend on component-local side effects

Both issues were product-facing: default-skin mistakes affect onboarding/profile fallback behavior, and preview-font drift makes the design-system page less trustworthy as an operator tool.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[design-system]]
- [[screens]]
- [[bug-patterns]]
- [[block-057-admin-achievements-runtime-parity]]

## File notes

### `admin/src/lib/appearance-skins.ts`

- **Zone:** admin / shared appearance validation
- **Purpose:** canonical normalization and validation for appearance-skin writes
- **What was added:**
  - normalized `skinKey` generation
  - strict parsing for `origin`, `gender`, and `rarity`
  - non-negative integer validation for prices and sort order
  - normalized nullable `imageUrl` / `imageKey`
  - forced `priceGold = 0` and `priceGems = 0` for `isDefault` skins
- **Status:** Fixed

### `admin/src/actions/appearances.ts`

- **Zone:** admin / appearance mutations
- **Purpose:** list, create, update, and delete appearance skins
- **Problems found:**
  - accepted raw payloads with weak validation
  - allowed duplicate `skinKey` drift to surface only as database failure
  - allowed multiple defaults for one `origin + gender` pair
  - allowed deletion of a default skin, which could leave onboarding/profile fallback without a valid default avatar
- **What was fixed:**
  - routed create/update through shared sanitizer
  - added explicit duplicate `skinKey` rejection
  - made default replacement transactional by clearing the previous default in the same `origin + gender` pair
  - blocked deletion of a default skin until another default is assigned
  - upgraded audit payloads with structured details
- **Status:** Fixed

### `admin/src/app/(dashboard)/appearances/appearances-client.tsx`

- **Zone:** admin / appearances UI
- **Purpose:** manage purchasable/default character skins
- **Problems found:**
  - stale `useTransition` cleanup left dead `isPending` references
  - numeric parsing relied on weak fallbacks
  - success/error flow depended only on inline error state
  - UI allowed priced default skins even though product/runtime treat defaults as free
- **What was fixed:**
  - replaced stale transition remnants with explicit `submitting` / `deleting` state
  - moved operator feedback to toast success/error flow
  - disabled price inputs for default skins and auto-zeroed them on toggle
  - added explicit UI note that saving a new default replaces the old default for the same `origin + gender`
- **Status:** Fixed

### `backend/src/app/api/characters/route.ts`

- **Zone:** backend / runtime reference
- **Purpose:** character list/runtime fallback source for appearance defaults
- **Why it mattered here:**
  - fallback avatar resolution uses `findFirst({ origin, gender, isDefault: true })`
  - multiple defaults or zero defaults for the same `origin + gender` pair would make that fallback ambiguous or empty
- **Status:** OK

### `Hexbound/Hexbound/Views/Profile/AppearanceEditorViewModel.swift`

- **Zone:** iOS / profile runtime reference
- **Purpose:** client-side appearance editor and ownership rules
- **Why it mattered here:**
  - it treats `isDefault` skins as free/default space
  - admin can no longer author priced defaults that contradict this runtime assumption
- **Status:** OK

### `Hexbound/Hexbound/Views/Auth/OnboardingViewModel.swift`

- **Zone:** iOS / onboarding runtime reference
- **Purpose:** initial character appearance selection
- **Why it mattered here:**
  - onboarding relies on the existence of a sane default-skin set for each `origin + gender`
- **Status:** OK

### `admin/src/app/layout.tsx`

- **Zone:** admin / root layout
- **Purpose:** global font and shell wiring
- **Problems found:**
  - preview components were compensating for missing `Oswald` by injecting their own `<link>` tags
- **What was fixed:**
  - added `Oswald` through `next/font/google` at the app root next to `Inter`
- **Status:** Fixed

### `admin/src/app/(dashboard)/design-system/design-system-client.tsx`

- **Zone:** admin / design-system explorer
- **Purpose:** interactive preview catalog for DS tokens and components
- **Problems found:**
  - carried unused fallback preview imports
  - injected Google font tags inside tab bodies
- **What was fixed:**
  - removed unused `HeroWidgetPreviews` and `StanceDisplayPreviews` imports
  - removed inline font loading now that fonts are owned by the app layout
- **Status:** Fixed

### `admin/src/app/(dashboard)/design-system/figma-components/*`

- **Zone:** admin / DS preview components
- **Purpose:** render pixel-oriented Figma preview variants inside the admin design-system page
- **Problems found:**
  - many preview wrappers injected external font `<link>` tags locally
  - this triggered `@next/next/no-page-custom-font` warnings and made preview correctness depend on component-local side effects
- **What was fixed:**
  - removed component-level Google font tags from:
    - `button.tsx`
    - `card.tsx`
    - `currency-display.tsx`
    - `navigation.tsx`
    - `hero-widget.tsx`
    - `tab-switcher.tsx`
    - `ornamental-title.tsx`
    - `state-view.tsx`
    - `wager-button.tsx`
    - `widget-pill.tsx`
    - `loading-overlay.tsx`
    - `stance-display.tsx`
  - preview components now rely on the same root-loaded fonts as the rest of the admin app
- **Status:** Fixed

## Problems found

1. **Default-skin policy was not enforced at the admin write boundary**
   - Risk: onboarding/profile fallback could become ambiguous or broken if admins created multiple defaults or deleted the active default.
   - Fix: centralized validation, transactional default replacement, and blocked default deletion.

2. **Admin UI allowed paid default skins**
   - Risk: operator-authored pricing could contradict iOS/runtime assumptions that defaults are free.
   - Fix: shared sanitizer forces zero pricing for defaults and the UI disables paid-default editing.

3. **Design-system previews loaded fonts through component-local `<link>` tags**
   - Risk: preview fidelity depended on ad hoc network-loaded fonts, and Next correctly reported the page as using custom fonts the wrong way.
   - Fix: loaded `Oswald` once in the root layout and removed local font tags from preview surfaces.

4. **Legacy preview exports still exist in `ds-components-2.tsx`**
   - Risk: dead preview code can drift quietly and confuse future audits.
   - Fix in this block: removed live imports from the active page; full cleanup is deferred to the next design-system/file-by-file pass.

## Verification

- targeted admin `eslint`:
  - `src/lib/appearance-skins.ts`
  - `src/actions/appearances.ts`
  - `src/app/(dashboard)/appearances/appearances-client.tsx`
  - `src/app/layout.tsx`
  - `src/app/(dashboard)/design-system/design-system-client.tsx`
  - touched `figma-components/*` preview files
- `npx next build` in `admin/`
- `git diff --check`

## Follow-up

- `admin/src/app/(dashboard)/design-system/figma-components/divider.tsx` still carries an unused `isGold` local and belongs in the next design-system warning cleanup slice
- `admin/src/app/(dashboard)/design-system/ds-components-2.tsx` now has preview exports that appear deprecated from the live screen and should be audited as deletion candidates rather than removed blindly
- if product ever wants “replace default while deleting” UX for appearances, that should be an explicit guided flow, not an implicit fallback inside `deleteAppearance`
