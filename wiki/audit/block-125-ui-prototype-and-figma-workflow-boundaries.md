---
title: Block 125 — UI prototype and Figma workflow boundaries
category: audit
tags: [audit, docs, ui, ux, prototypes, figma, historical-boundary]
sources:
  - docs/07_ui_ux/FIGMA_SCREEN_RULES.md
  - docs/07_ui_ux/INTEGRATED_CARD_UNIFICATION.md
  - docs/07_ui_ux/UNIFIED_PRELOADER_CONCEPT.md
  - docs/07_ui_ux/card-audit-prototype.html
  - docs/07_ui_ux/card-audit-v2.html
  - docs/07_ui_ux/card-audit-v3.html
  - docs/07_ui_ux/card-audit-v4.html
  - docs/07_ui_ux/combat-prototype.html
  - docs/07_ui_ux/daily_login_carousel_prototype.html
  - docs/07_ui_ux/comic-onboarding-prototype.jsx
  - docs/07_ui_ux/skilltree-prototype.html
  - docs/07_ui_ux/prototypes/auth-flow-redesign.html
updated: 2026-04-16
status: Fixed
---

# Block 125 — UI prototype and Figma workflow boundaries

## Scope

- `docs/07_ui_ux/FIGMA_SCREEN_RULES.md`
- `docs/07_ui_ux/INTEGRATED_CARD_UNIFICATION.md`
- `docs/07_ui_ux/UNIFIED_PRELOADER_CONCEPT.md`
- `docs/07_ui_ux/card-audit-prototype.html`
- `docs/07_ui_ux/card-audit-v2.html`
- `docs/07_ui_ux/card-audit-v3.html`
- `docs/07_ui_ux/card-audit-v4.html`
- `docs/07_ui_ux/combat-prototype.html`
- `docs/07_ui_ux/daily_login_carousel_prototype.html`
- `docs/07_ui_ux/comic-onboarding-prototype.jsx`
- `docs/07_ui_ux/skilltree-prototype.html`
- `docs/07_ui_ux/prototypes/auth-flow-redesign.html`

## Why this block

After the earlier dated-doc cleanup, the next ambiguous slice was no longer markdown specs. It was the hybrid layer of:

- one workflow playbook for a very specific Figma authoring setup
- proposal/concept docs that still sounded like open implementation plans
- heavyweight HTML/JSX design prototypes that opened like live product surfaces instead of historical mockups

These files are useful. The problem was framing. Without explicit boundaries, they were still easy to mistake for current implementation truth.

## Related pages

- [[block-121-prototypes-link-parity-and-transition-state]]
- [[block-123-ui-review-and-plan-docs-historical-boundaries]]
- [[block-124-w1-w3-plan-docs-historical-boundaries]]
- [[design-principles]]

## File notes

### `docs/07_ui_ux/FIGMA_SCREEN_RULES.md`

- **Zone:** workflow playbook
- **Purpose:** strict operator checklist for a specific Figma authoring path against `Hexbound-Design`
- **Problems found:**
  - read like universal UI truth instead of a file/tool-specific workflow contract
- **What was fixed:**
  - added an explicit source-of-truth boundary clarifying that live truth still lives in Swift code and audited `wiki/`
- **Status:** Fixed

### `docs/07_ui_ux/INTEGRATED_CARD_UNIFICATION.md`

- **Zone:** design/refactor proposal
- **Purpose:** forensic comparison and unification proposal for `HeroIntegratedCard` vs `OpponentIntegratedCard`
- **Problems found:**
  - status line already said proposal, but the body still contained live-sounding approval questions and “when approved” execution wording
- **What was fixed:**
  - added a historical proposal boundary
  - reframed the approval/questions section and phased plan as original review context, not current execution instructions
- **Status:** Fixed

### `docs/07_ui_ux/UNIFIED_PRELOADER_CONCEPT.md`

- **Zone:** loading UX concept
- **Purpose:** proposal for rationalizing loading patterns into a shared loading system
- **Problems found:**
  - count-heavy concept wording could still be mistaken for the current loading spec
- **What was fixed:**
  - added an explicit historical concept boundary and revalidation warning
- **Status:** Fixed

### `docs/07_ui_ux/card-audit-prototype.html`

- **Zone:** prototype archive
- **Purpose:** early card-layout audit and design exploration
- **Problems found:**
  - opened like a live design artifact with no visible archival boundary
- **What was fixed:**
  - added an archival comment, historical title, and visible historical subtitle
- **Status:** Fixed

### `docs/07_ui_ux/card-audit-v2.html`

- **Zone:** prototype archive
- **Purpose:** second design iteration of unified card-system exploration
- **Problems found:**
  - still looked like an active component exploration surface
- **What was fixed:**
  - added explicit historical title and subtitle framing
- **Status:** Fixed

### `docs/07_ui_ux/card-audit-v3.html`

- **Zone:** prototype archive
- **Purpose:** equal-height/no-buttons card-system experiment
- **Problems found:**
  - still read like current card guidance when opened directly
- **What was fixed:**
  - added explicit historical prototype framing
- **Status:** Fixed

### `docs/07_ui_ux/card-audit-v4.html`

- **Zone:** prototype archive
- **Purpose:** asset-backed avatar/card exploration with theme-token parity
- **Problems found:**
  - could be mistaken for current live card implementation guidance
- **What was fixed:**
  - added explicit historical prototype framing
- **Status:** Fixed

### `docs/07_ui_ux/combat-prototype.html`

- **Zone:** motion/layout prototype
- **Purpose:** combat-screen animation and reveal demo
- **Problems found:**
  - presented itself as a generic combat prototype without saying it was archival
- **What was fixed:**
  - added a historical prototype comment, title, and motion-demo subtitle
- **Status:** Fixed

### `docs/07_ui_ux/daily_login_carousel_prototype.html`

- **Zone:** reward-flow prototype
- **Purpose:** carousel redesign exploration for daily-login rewards
- **Problems found:**
  - subtitle still sounded like current behavior instructions
- **What was fixed:**
  - reframed it as a historical redesign snapshot
- **Status:** Fixed

### `docs/07_ui_ux/comic-onboarding-prototype.jsx`

- **Zone:** onboarding prototype
- **Purpose:** comic-style onboarding narrative experiment
- **Problems found:**
  - lacked any explicit visible boundary when rendered
- **What was fixed:**
  - added both a file-level archival comment and visible historical prototype label near the rendered title
- **Status:** Fixed

### `docs/07_ui_ux/skilltree-prototype.html`

- **Zone:** hero/skills prototype
- **Purpose:** early Hero screen exploration for equipment/skills/talents
- **Problems found:**
  - had no page-level cue that it was an old prototype rather than the live Hero screen contract
- **What was fixed:**
  - added archival comment, historical title, and visible banner at the top of the mockup
- **Status:** Fixed

### `docs/07_ui_ux/prototypes/auth-flow-redesign.html`

- **Zone:** auth UX prototype
- **Purpose:** redesign comparison for guest-first auth and reduced CTA clutter
- **Problems found:**
  - recommendation language remained useful, but the file still looked too close to a live auth-spec page
- **What was fixed:**
  - added archival title/comment and visible historical snapshot framing in the header
- **Status:** Fixed

## Problems found

1. **Prototype files still opened like live product surfaces**
   - Risk: later reviewers can over-trust a historical mockup and miss what the shipped runtime actually does.
   - Fix: added visible historical framing to the HTML/JSX prototypes rather than leaving the archival status implicit.

2. **Proposal docs still contained live-sounding execution language**
   - Risk: old approval questions and phased plans survive as if they are still the current action queue.
   - Fix: reframed proposal sections in `INTEGRATED_CARD_UNIFICATION.md` as historical review context.

3. **A strict Figma workflow document could be mistaken for universal UI truth**
   - Risk: someone can treat a tool-specific authoring playbook as if it outranks current app code.
   - Fix: added an explicit source-of-truth boundary to `FIGMA_SCREEN_RULES.md`.

## Verification

- inspected the opening/title/header surfaces for all twelve files
- confirmed that each now declares or visibly signals its historical/proposal scope
- `git diff --check`

## Follow-up

- Continue through the remaining `docs/07_ui_ux/` prototype/archive surfaces until all direct-open HTML/JSX artifacts self-identify as historical.
- Keep the prototypes; just do not let them masquerade as current implementation contracts.
