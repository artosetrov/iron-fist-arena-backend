---
title: Audit Block 160 — iOS Strike Reveal Partial Implementation Boundary
category: audit
tags: [audit, ios, combat, ui-ux, prototypes, docs]
sources:
  - Hexbound/Hexbound/Models/RoundVerdict.swift
  - Hexbound/Hexbound/Models/RoundExchange.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift
  - Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift
  - Hexbound/Hexbound/Views/Combat/VFX/CombatVerdictFlash.swift
  - docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md
  - prototypes/strike-reveal-b.html
  - prototypes/strike-reveal-compact.html
  - prototypes/strike-reveal-integration.html
updated: 2026-04-17
status: Fixed
---

# Audit Block 160 — iOS Strike Reveal Partial Implementation Boundary

## Scope

- `Hexbound/Hexbound/Models/RoundVerdict.swift`
- `Hexbound/Hexbound/Models/RoundExchange.swift`
- `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift`
- `Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift`
- `Hexbound/Hexbound/Views/Combat/VFX/CombatVerdictFlash.swift`
- `docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md`
- `prototypes/strike-reveal-b.html`
- `prototypes/strike-reveal-compact.html`
- `prototypes/strike-reveal-integration.html`

## Why this block

This slice had drifted into an awkward middle state:

- live iOS code already shipped the core strike-reveal verdict framing;
- the design doc still claimed `Awaiting approval before code`;
- the prototype trio looked like stray HTML residue unless you already knew they belonged to the same reveal experiment.

That made the repo harder to trust than it needed to be. The problem here was not missing runtime behavior. It was missing boundary language.

## What is live now

The following pieces are already implemented in product code:

1. `RoundVerdict` classification from server-authoritative strike data
2. `RoundExchange.verdict` threading into reveal presentation
3. `CombatVerdictFlash` mounted in `InteractiveBattleView`
4. `RoundVerdictHeader` mounted in `InteractiveRoundLogCard`

In other words, the Phase 1 / Phase 2 core from the Shape B plan is no longer hypothetical.

## What remains proposal-only

These parts are still design/prototype territory:

1. Clash strip row (`Phase 3`)
2. Portrait winner/loser treatment and peak amp (`Phase 4`)
3. The alternative reveal-shape explorations kept in the strike-reveal prototype HTML files

## Fix applied

### `docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md`

- changed the status line from pre-code proposal language to a partial-implementation snapshot
- added a reality-check section that explicitly says Phases 1-2 are live and Phases 3-4 remain proposal
- rewrote the effort/checklist tail so it talks about remaining work instead of pretending Phase 1 has not started

### Prototype boundary

- kept `prototypes/strike-reveal-b.html`
- kept `prototypes/strike-reveal-compact.html`
- kept `prototypes/strike-reveal-integration.html`

These remain intentional historical/design references for the strike-reveal direction, not orphaned residue.

## File records

| Path | Role | Status |
|------|------|--------|
| `Hexbound/Hexbound/Models/RoundVerdict.swift` | Player-perspective verdict taxonomy used by reveal presentation | OK |
| `Hexbound/Hexbound/Models/RoundExchange.swift` | Carries the derived verdict into the rendered exchange payload | OK |
| `Hexbound/Hexbound/Views/Combat/InteractiveBattleView.swift` | Hosts the flash overlay for reveal timing | OK |
| `Hexbound/Hexbound/Views/Combat/InteractiveRoundLogCard.swift` | Shows the verdict header already shipped in the log card | OK |
| `Hexbound/Hexbound/Views/Combat/VFX/CombatVerdictFlash.swift` | Live verdict flash surface | OK |
| `docs/07_ui_ux/STRIKE_REVEAL_SHAPE_B_PLAN.md` | Mixed implementation record plus remaining proposal | Fixed |
| `prototypes/strike-reveal-b.html` | Historical/proposal prototype for reveal framing | OK |
| `prototypes/strike-reveal-compact.html` | Historical/proposal compact reveal variant | OK |
| `prototypes/strike-reveal-integration.html` | Main reference prototype for the remaining reveal direction | OK |

## Result

The repo now tells the truth about this feature slice:

- it is not "awaiting approval before code";
- it is also not fully shipped end-to-end;
- and the remaining prototype HTML files are there on purpose.

That is a much healthier state than a half-implemented feature disguised as a pure plan.

## Verification

- `rg -n "RoundVerdict|CombatVerdictFlash|verdict" Hexbound/Hexbound/Views/Combat Hexbound/Hexbound/Models`
- `git diff --check`

Both passed for this truth-sync block.
