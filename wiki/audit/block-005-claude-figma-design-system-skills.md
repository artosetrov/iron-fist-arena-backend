---
title: Audit Block 005 — Claude Figma and Design-System Skills
category: audit
tags: [audit, claude, figma, design-system, skills]
sources:
  - .claude/skills/apply-design-system/
  - .claude/skills/audit-design-system/
  - .claude/skills/cc-figma-*/
  - .claude/skills/ds-*/
  - .claude/skills/figma-*/
  - .claude/skills/fix-design-system-finding/
  - .claude/skills/rad-spacing/
updated: 2026-04-15
---

# Audit Block 005 — Claude Figma and Design-System Skills

## Scope

This block covers the remaining tracked `.claude` Figma/design-system skills, Figma reference docs, Code Connect docs, Figma Plugin API helper scripts, and YAML agent interface files.

- **Files audited in this sub-block:** 62
- **Primary file types:** Markdown skill protocols/reference docs, JavaScript Figma helper scripts, YAML agent metadata, TypeScript declaration reference
- **Status:** Fixed docs/scripts hazards; live Figma state revalidation remains required
- **Related pages:** [[audit-index]], [[project-file-inventory]], [[block-004-claude-product-governance-skills]], [[design-system]], [[screens]]

## Summary

- The Figma skill tree has a clear role: create, audit, sync, prototype, and implement design-system-backed Figma work.
- Main risks were stale hardcoded Figma file IDs/counts, missing `.component-contracts` setup, unsafe temp-file guidance, old `grep` commands, broken internal links, and helper scripts using `setPluginData` despite the skill docs requiring `setSharedPluginData`.
- Safe fixes were applied to docs and helper scripts only. No Figma file was modified.

## Problems Fixed In This Block

| Priority | Problem | Risk | Fix |
|----------|---------|------|-----|
| P1 | `cc-figma-component` told agents to write generated working files into tracked `scripts/` and to add `scripts/` to `.gitignore`. | Could hide or delete real project scripts and mix generated Figma cache with source files. | Added `.claude/tmp/` to `.gitignore` and changed working directory guidance to `.claude/tmp/cc-figma-component/<run-id>/`. |
| P1 | `figma-generate-library` helper scripts used `setPluginData/getPluginData` while the skill docs say these are not supported in `use_figma`. | Recovery/cleanup/idempotency tags become unreadable across runs. | Updated helper scripts to use `setSharedPluginData/getSharedPluginData` with namespace `dsb`. |
| P1 | `cc-figma-component` recommended `new Function(code)()` as a general workaround for blocked `eval`. | Dynamic execution of untrusted text can become code-injection in Figma automation. | Restricted dynamic execution to trusted code generated in the current run temp directory; never user/network/arbitrary repo/Figma text. |
| P1 | `ds-code-audit` used macOS-fragile `grep` checks and a broken merge-conflict marker pattern. | Design-system scanner can silently miss violations. | Converted commands to `rg` and fixed the conflict marker check. |
| P2 | `ds-ecosystem` and `ds-qa-coverage` treated 2026-04-03 Figma counts/screen counts as current. | False coverage results after file moves or new screens. | Marked as historical snapshots and required refresh from current Swift tree, `SCREEN_INVENTORY.md`, Figma metadata, and wiki. |
| P2 | Several DS skills used hardcoded Figma file keys without a freshness guard. | Work could be written into stale DS/Screens files. | Added "verify keys before writing/auditing" notes. |
| P2 | `cc-figma-tokens` referenced `.component-contracts.example`, but no such file exists in repo. | Setup instructions send user to a nonexistent file. | Changed behavior to stop and request config or create a safe example in a separate setup step. |
| P2 | Relative Markdown links pointed to nonexistent `figma-code-connect-components` and wrong `token-creation.md` path. | Skill handoff and reference navigation fail. | Fixed links to `figma-code-connect` and correct relative path. |

## File Records

| Path | Zone / Role | Purpose / What It Does | Depends On / Used By | Main Rules / Business Logic | Problems / Fixes | Status |
|------|-------------|------------------------|----------------------|-----------------------------|------------------|--------|
| `.claude/skills/apply-design-system/SKILL.md` | Figma DS repair | Connects existing Figma designs to shared components/tokens one section at a time. | Figma MCP, design-system components, `audit-design-system`. | Back up target, inventory screen, map sections, validate changed area only. | No direct defect. | OK |
| `.claude/skills/apply-design-system/agents/openai.yaml` | Agent metadata | UI prompt/display metadata for apply-design-system. | Claude/OpenAI agent interface. | Default prompt routes to Figma screen review + DS connection. | YAML parses. | OK |
| `.claude/skills/audit-design-system/SKILL.md` | Figma DS audit | Audits Figma screen/component drift: missing shared components, local overrides, unbound tokens. | Figma MCP metadata/screenshots/variables. | Evidence must come from visible Figma structure, raw values, repetition, or token drift. | No direct defect. | OK |
| `.claude/skills/audit-design-system/agents/openai.yaml` | Agent metadata | UI prompt/display metadata for audit-design-system. | Claude/OpenAI agent interface. | Routes credible findings to fix/apply skills. | YAML parses. | OK |
| `.claude/skills/cc-figma-component/SKILL.md` | Component-contract to Figma | Builds Figma component sets from component contracts and semantic tokens. | `.component-contracts`, token/contract dirs, `cc-figma-tokens`, `figma-use`. | Semantic-only variable binding, HUG sizing, generated notes, controlled cleanup. | Fixed temp directory guidance, missing config handling, and dynamic-code safety. | Fixed |
| `.claude/skills/cc-figma-tokens/SKILL.md` | Component-contract tokens | Builds Figma Primitive/Semantic variable collections from token files. | `.component-contracts`, DTCG token files, Figma MCP. | Read all token files first, never output Figma token, set precise scopes/code syntax. | Fixed missing `.component-contracts.example` guidance. | Fixed |
| `.claude/skills/ds-code-audit/SKILL.md` | Swift DS code audit | Scans SwiftUI code for DS violations, duplicate UI patterns, orphan/missing components, unused tokens. | Swift theme files, Views tree, CLAUDE rules. | Every visual pattern should be tokenized or extracted into reusable component. | Converted fragile `grep` commands to `rg`; fixed conflict scan. | Fixed |
| `.claude/skills/ds-ecosystem/SKILL.md` | DS master plan | Orchestrates full Figma DS ecosystem: audit, tokens, components, screens, prototype, QA. | Swift UI, Figma DS/Screens files, DS skills. | DS file holds tokens/components only; Screens file holds screens only. | Marked 2026-04-03 counts as historical and required current inventory refresh. | Fixed |
| `.claude/skills/ds-extract-component/SKILL.md` | DS component extraction | Extracts repeated Swift inline UI into reusable Swift component and matching Figma component. | Swift Views, Theme files, pbxproj, Figma DS file. | Extract repeated patterns, update callers, add pbxproj refs, then create Figma component. | Converted verification examples to `rg`; added current DS key verification. | Fixed |
| `.claude/skills/ds-figma-sync/SKILL.md` | Code/Figma parity | Checks Swift token/component parity against Figma DS file. | `DarkFantasyTheme.swift`, `LayoutConstants.swift`, Figma file keys. | Figma DS token/style/component data must match Swift source of truth. | Added hardcoded-key freshness guard. | Fixed |
| `.claude/skills/ds-prototype/SKILL.md` | Figma prototype | Creates prototype interactions for screen flows. | Screens file, `figma-use`, built screen frames. | Prototype coverage should follow current screen inventory. | Added file-key verification and historical baseline wording. | Fixed |
| `.claude/skills/ds-qa-coverage/SKILL.md` | DS QA coverage | Final QA for Figma ecosystem: screens, states, tokens, components, naming, prototype links. | DS/Screens files, screen inventory, Swift tree, wiki screens. | 100% current screen inventory, no fake components, no unbound tokens. | Replaced hardcoded 48/48 scoring with current inventory and historical baseline note. | Fixed |
| `.claude/skills/ds-screen-builder/SKILL.md` | Screen builder | Builds app screens in Figma Screens file using DS components/tokens/styles. | `FIGMA_SCREEN_RULES.md`, DS/Screens file keys, Swift view code. | Zero hardcoded colors/text/styles/components; post-creation audit must pass. | Added hardcoded-key freshness guard. | Fixed |
| `.claude/skills/edit-figma-design/SKILL.md` | Figma authoring | Creates or updates Figma designs from written UI/product descriptions. | Figma MCP, optional code/design context. | Resolve destination file first, search DS before authoring, use small `use_figma` steps. | No direct defect. | OK |
| `.claude/skills/figma-code-connect/SKILL.md` | Code Connect templates | Creates and validates `.figma.js` Code Connect templates. | Figma URL, component props, code components, Code Connect CLI. | Parserless template structure, property mapping, descendant discovery. | No direct defect. | OK |
| `.claude/skills/figma-code-connect/references/advanced-patterns.md` | Code Connect reference | Advanced examples for metadata, descendants, recursive templating, inheritance. | `figma-code-connect/SKILL.md`. | Use instance metadata/examples/descendants deliberately. | No direct defect. | OK |
| `.claude/skills/figma-code-connect/references/api.md` | Code Connect API reference | Long API/config reference for Code Connect templates. | Code Connect CLI/API. | Required metadata, config, supported languages, publish flow. | Contains placeholder token examples only, no real secret found. | OK |
| `.claude/skills/figma-create-design-system-rules/SKILL.md` | Rule generator | Creates project-specific design-system rules for Figma-to-code workflows. | Figma MCP, codebase analysis. | Analyze code conventions before writing rules. | No direct defect. | OK |
| `.claude/skills/figma-create-new-file/SKILL.md` | Figma file creation | Creates blank Figma/FigJam files and resolves planKey. | Figma MCP `whoami` and create-file tool. | Resolve plan before creation; return usable file. | No direct defect. | OK |
| `.claude/skills/figma-generate-design/SKILL.md` | Build/update Figma screens | Builds full screens/pages in Figma from code/description using DS assets. | `figma-use`, DS search/import, source code. | Reuse components/variables/styles; validate full screen. | Fixed broken Code Connect handoff link. | Fixed |
| `.claude/skills/figma-generate-library/SKILL.md` | Figma DS builder | High-level workflow for building/updating professional Figma design systems. | `figma-use`, helper scripts, references. | Multi-phase, checkpoints, state ledger, no parallel `use_figma`, shared plugin data. | Clarified helper script folder and cleanup semantics. | Fixed |
| `.claude/skills/figma-generate-library/references/code-connect-setup.md` | Library reference | Code Connect setup and mapping strategy. | Figma Code Connect MCP/tools. | Use per-component or final-pass mapping strategy. | No direct defect. | OK |
| `.claude/skills/figma-generate-library/references/component-creation.md` | Library reference | Component architecture, variant matrix, docs, component properties. | Figma Plugin API, `figma-use`. | Atoms before molecules, variant caps, shared plugin data for idempotency. | No direct defect. | OK |
| `.claude/skills/figma-generate-library/references/discovery-phase.md` | Library reference | Codebase/Figma discovery before DS creation. | Code tokens, Figma metadata, subscribed libraries. | Resolve conflicts before writes; ask user on code/Figma mismatch. | No direct defect. | OK |
| `.claude/skills/figma-generate-library/references/documentation-creation.md` | Library reference | Cover/foundations/docs pages and swatches/type/spacing/shadow examples. | Figma Plugin API. | Documentation pages should bind to variables/styles. | No direct defect. | OK |
| `.claude/skills/figma-generate-library/references/error-recovery.md` | Library reference | Error recovery, cleanup, idempotency, state ledger, resume protocol. | Figma shared plugin data, state files. | Stop-inspect-fix-retry; cleanup by shared tags, not names. | Aligns with updated helper scripts. | OK |
| `.claude/skills/figma-generate-library/references/naming-conventions.md` | Library reference | Naming conventions for variables, components, pages, variants. | Figma DS conventions. | Slash hierarchy, PascalCase components, clear variant names. | No direct defect. | OK |
| `.claude/skills/figma-generate-library/references/token-creation.md` | Library reference | Variable collections, modes, aliases, scopes, styles. | Figma Variables API. | Primitive/semantic architecture, precise scopes, code syntax. | No direct defect. | OK |
| `.claude/skills/figma-generate-library/scripts/bindVariablesToComponent.js` | JS helper | Binds variables to fills/strokes/spacing/radius on a component/frame/rect. | Figma Variables API. | Mutate only supplied bindings and return mutated IDs. | `node --check` passes. | OK |
| `.claude/skills/figma-generate-library/scripts/cleanupOrphans.js` | JS helper | Removes nodes/variables/collections tagged with a run id. | Shared plugin data, Figma node/variables APIs. | Cleanup only by shared `dsb/run_id`, never by name. | Switched from pluginData to sharedPluginData; `node --check` passes. | Fixed |
| `.claude/skills/figma-generate-library/scripts/createComponentWithVariants.js` | JS helper | Creates variant components, combines them, grids them, tags for cleanup. | Figma Component API, shared plugin data. | Deterministic variant names and grid layout. | Switched from pluginData to sharedPluginData; `node --check` passes. | Fixed |
| `.claude/skills/figma-generate-library/scripts/createDocumentationPage.js` | JS helper | Creates documentation page with root frame, header, sections. | Figma fonts, page/frame/text APIs. | Verify/load fonts before text writes. | Switched from pluginData to sharedPluginData; `node --check` passes. | Fixed |
| `.claude/skills/figma-generate-library/scripts/createSemanticTokens.js` | JS helper | Creates semantic variables from token map and sets values/scopes/code syntax. | Figma Variables API. | Convert hex to Figma colors; fail on missing mode ids. | Switched from pluginData to sharedPluginData; `node --check` passes. | Fixed |
| `.claude/skills/figma-generate-library/scripts/createVariableCollection.js` | JS helper | Creates variable collection and modes, returns mode ids. | Figma Variables API. | Require at least one mode; tag collection for cleanup. | Switched from pluginData to sharedPluginData; `node --check` passes. | Fixed |
| `.claude/skills/figma-generate-library/scripts/inspectFileStructure.js` | JS helper | Read-only inventory of pages, variables, component sets, styles. | Figma document/style APIs. | Restore original page after scanning. | `node --check` passes. | OK |
| `.claude/skills/figma-generate-library/scripts/rehydrateState.js` | JS helper | Reconstructs run state from shared tags plus variables/styles inventory. | Shared plugin data and Figma APIs. | Scan pages and descendants; return state map. | Switched from pluginData to sharedPluginData; `node --check` passes. | Fixed |
| `.claude/skills/figma-generate-library/scripts/validateCreation.js` | JS helper | Validates expected node existence/type/name/child count. | Figma node lookup. | Fail fast with reason strings for partial creation. | `node --check` passes. | OK |
| `.claude/skills/figma-implement-design/SKILL.md` | Design implementation | Translates Figma design into production code with visual parity. | Figma context/screenshot/assets, project code conventions. | Fetch context, screenshot, assets; map to project tokens; validate parity. | Fixed broken Code Connect handoff link. | Fixed |
| `.claude/skills/figma-use/SKILL.md` | Figma Plugin API usage | Mandatory rules for `use_figma` JavaScript execution. | Figma Plugin API references. | Return all IDs, load fonts, no parallel writes, use shared plugin data. | No direct defect. | OK |
| `.claude/skills/figma-use/references/api-reference.md` | API reference | Figma Plugin API common operations. | `figma-use`. | Node creation, libraries, variables, images, traversal. | No direct defect. | OK |
| `.claude/skills/figma-use/references/common-patterns.md` | API patterns | Common scripts for shapes, text, frames, variables, components. | `figma-use`. | Return created IDs and work incrementally. | No direct defect. | OK |
| `.claude/skills/figma-use/references/component-patterns.md` | API patterns | Component/variant creation, imports, instances, overrides. | Figma Component API. | Variant layout after combine, property APIs, avoid ID invalidation. | No direct defect. | OK |
| `.claude/skills/figma-use/references/effect-style-patterns.md` | API patterns | Effect style listing/creation/import/apply patterns. | Figma EffectStyle API. | Use styles for reusable shadows/effects. | No direct defect. | OK |
| `.claude/skills/figma-use/references/gotchas.md` | API gotchas | Common Figma mistakes and unsupported operations. | `figma-use`. | No `figma.notify`, no unsupported pluginData, always return values. | Negative pluginData examples are intentional. | OK |
| `.claude/skills/figma-use/references/plugin-api-patterns.md` | API patterns | Broader plugin API execution, node creation, fills/strokes. | Figma Plugin API. | Page context, incremental scripts, return results. | No direct defect. | OK |
| `.claude/skills/figma-use/references/plugin-api-standalone.d.ts` | Type reference | Large standalone Figma Plugin API type declaration. | `figma-use` grep/search. | Source of exact types/methods. | No syntax validation run; version/source date not documented. | Needs review |
| `.claude/skills/figma-use/references/plugin-api-standalone.index.md` | Type index | Index into the large `.d.ts` file. | `plugin-api-standalone.d.ts`. | Search index first, then inspect relevant type sections. | No direct defect. | OK |
| `.claude/skills/figma-use/references/text-style-patterns.md` | API patterns | Text style listing/creation/import/apply patterns. | Figma TextStyle API. | Font load before text style operations. | No direct defect. | OK |
| `.claude/skills/figma-use/references/validation-and-recovery.md` | API workflow | Validation via metadata/screenshots and recovery after failed `use_figma`. | Figma MCP validation tools. | Validate after major creation steps. | No direct defect. | OK |
| `.claude/skills/figma-use/references/variable-patterns.md` | API patterns | Variable collections, modes, bindings, scopes, aliasing, imports. | Figma Variables API. | Use specific scopes, alias deliberately. | Fixed broken link to token-creation reference. | Fixed |
| `.claude/skills/figma-use/references/working-with-design-systems/wwds-components--creating.md` | WWDS reference | Short guide for creating DS components. | WWDS component docs. | Reflect code component surface where useful. | No direct defect. | OK |
| `.claude/skills/figma-use/references/working-with-design-systems/wwds-components--using.md` | WWDS reference | Short guide for using DS components. | WWDS component docs. | Prefer component instances over fake frames. | No direct defect. | OK |
| `.claude/skills/figma-use/references/working-with-design-systems/wwds-components.md` | WWDS reference | Component model, descriptions, usage, code patterns. | Figma Components. | Components should carry usage guidance. | No direct defect. | OK |
| `.claude/skills/figma-use/references/working-with-design-systems/wwds-effect-styles.md` | WWDS reference | Effect style model, gotchas, code patterns. | Figma Effect Styles. | Effects should be styles when reused. | No direct defect. | OK |
| `.claude/skills/figma-use/references/working-with-design-systems/wwds-text-styles.md` | WWDS reference | Text style model, variable bindings, usage patterns. | Figma Text Styles. | Text styles handle typography tokens/composites. | No direct defect. | OK |
| `.claude/skills/figma-use/references/working-with-design-systems/wwds-variables--creating.md` | WWDS reference | Short guide for creating variables. | Variables reference. | Use variable creation with proper modes/scopes. | No direct defect. | OK |
| `.claude/skills/figma-use/references/working-with-design-systems/wwds-variables--using.md` | WWDS reference | Short guide for using variables. | Variables reference. | Watch mode mismatch and specific collections. | No direct defect. | OK |
| `.claude/skills/figma-use/references/working-with-design-systems/wwds-variables.md` | WWDS reference | Variable model, aliasing, scopes, grouping, guidelines. | Figma Variables. | Variables are not composite tokens; use styles for type/effects. | Fixed broken relative link. | Fixed |
| `.claude/skills/figma-use/references/working-with-design-systems/wwds.md` | WWDS reference | General design-system reasoning guide. | Figma DS model. | Match code definitions when definitive, otherwise use judgment. | No direct defect. | OK |
| `.claude/skills/fix-design-system-finding/SKILL.md` | Targeted DS fix | Fixes one specific design-system audit finding in Figma. | `audit-design-system`, Figma MCP, variables/screenshots. | Fix one finding only; back up affected area; validate targeted result. | No direct defect. | OK |
| `.claude/skills/fix-design-system-finding/agents/openai.yaml` | Agent metadata | UI prompt/display metadata for targeted DS fix. | Claude/OpenAI agent interface. | Fix only the specific finding. | YAML parses. | OK |
| `.claude/skills/rad-spacing/SKILL.md` | Spacing guidance | Figma spacing heuristic based on proximity and 8/4px increments. | Figma layout work and library spacing variables. | Outer containers get larger spacing than inner elements. | No direct defect. | OK |

## Duplicate Logic Found

- `ds-ecosystem`, `ds-screen-builder`, `ds-qa-coverage`, `figma-generate-design`, and `edit-figma-design` all define overlapping Figma screen-building workflows.
- `figma-generate-library` and `cc-figma-*` both cover token/component creation, but `cc-figma-*` assumes a component-contracts setup that is not present in this repo.
- `figma-use` references duplicate some rules already embedded in `figma-generate-library`; this is useful for lookup but should stay synchronized.

## Files Without Clear Current Role

- `.claude/skills/cc-figma-component/SKILL.md` and `.claude/skills/cc-figma-tokens/SKILL.md` are blocked until `.component-contracts` exists or a setup page is added.
- `.claude/skills/ds-ecosystem/SKILL.md` is partly a historical execution plan, partly an active orchestrator. It needs a refreshed current-state section before use.
- `.claude/skills/figma-use/references/plugin-api-standalone.d.ts` lacks a recorded upstream version/date.

## Candidates For Removal / De-Tracking

- None safe to delete now. The main candidates are not deletion but either refresh (`ds-ecosystem`) or setup completion (`cc-figma-*`).

## Documentation Missing Or Stale

- Missing `.component-contracts` / `.component-contracts.example` setup documentation.
- Figma DS/Screens file keys and library key need a canonical source-of-truth page with "last verified" date.
- DS ecosystem counts from April 3, 2026 are historical and must be refreshed from code/Figma before use.
- Plugin API `.d.ts` reference should record upstream source/version/date.

## Verification

- All `figma-generate-library/scripts/*.js` pass `node --check`.
- All three Figma YAML agent metadata files parse with Ruby YAML.
- Relative Markdown links in the 62-file block resolve after fixes.
- Search found no remaining broken `figma-code-connect-components` links or GNU-only `grep -P`/`grep -oP` in this block.
