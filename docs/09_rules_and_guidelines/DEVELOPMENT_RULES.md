# Hexbound — Development Rules

*Canonical rules document. Agent System Rules v3. Updated: 2026-03-19*

---

## Xcode Project File (CRITICAL)

When creating ANY new `.swift` file in the `Hexbound/` iOS app, you MUST also add it to `Hexbound/Hexbound.xcodeproj/project.pbxproj`.

Each new file requires entries in **4 sections** of `project.pbxproj`:

1. **PBXBuildFile** — `{ID1} /* FileName.swift in Sources */ = {isa = PBXBuildFile; fileRef = {ID2} /* FileName.swift */; };`
2. **PBXFileReference** — `{ID2} /* FileName.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileName.swift; sourceTree = "<group>"; };`
3. **PBXGroup** — Add `{ID2} /* FileName.swift */,` to the correct group's `children` array (match the folder the file lives in, e.g. Auth, Components, Network)
4. **Sources build phase** — Add `{ID1} /* FileName.swift in Sources */,` to the `PBXSourcesBuildPhase` `files` array

Generate unique 24-character hex IDs for `{ID1}` and `{ID2}`. Keep entries alphabetically sorted within each section.

**If you skip this step, the file will NOT compile in Xcode.**

---

## Design System Enforcement (CRITICAL)

### Always Use Design System Tokens

- **ALWAYS** use `DarkFantasyTheme` color/font tokens — **NEVER** hardcode `Color(hex:)`, `Color.red`, `.font(.system(...))` or any raw values
- **ALWAYS** use button styles from `ButtonStyles.swift` (`.primary`, `.secondary`, `.neutral`, `.ghost`, `.socialAuth`, etc.) — **NEVER** inline button styling
- **ALWAYS** use `LayoutConstants` for spacing, sizing, and fonts — minimum font size is `LayoutConstants.textBadge` (11px)

### Verification Before Use

- **NEVER GUESS token names.** Before using any `DarkFantasyTheme.xxx`, open `DarkFantasyTheme.swift` and confirm the property exists.
- **NEVER GUESS button style names.** Open `ButtonStyles.swift` and verify before using.
- Before using a button style, **check its signature** in `ButtonStyles.swift` (e.g., `.primary(enabled:)` takes a parameter, `.secondary` does not).
- Before using a color/font, **ensure the token exists** in `DarkFantasyTheme.swift`.

### Common Mistakes (DO NOT DO)

- **NEVER use:** `.accent`, `.primary` (as a color), `.background`, `.text` — these DO NOT EXIST
- **ALWAYS use instead:** `.gold`, `.bgPrimary`, `.textPrimary`, etc. — verify these exist in `DarkFantasyTheme.swift`

### Extending the Design System

If a needed style/token/variant does **NOT EXIST**:
- **CREATE IT** in the appropriate file (`ButtonStyles.swift`, `DarkFantasyTheme.swift`, `LayoutConstants.swift`)
- **NEVER** work around missing styles with inline opacity, hardcoded colors, manual `.frame`/`.background`/`.overlay` instead of a proper style
- Extend the design system first, then use the new token

### Verification After Every UI Change

After EVERY change to UI code:
1. Re-read `ButtonStyles.swift`, `DarkFantasyTheme.swift`, `LayoutConstants.swift`
2. Verify all used tokens, styles, and constants exist
3. Verify they are called with the correct signature
4. This is mandatory, do not skip

### File Locations

- Theme: `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- Button styles: `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- Layout constants: `Hexbound/Hexbound/Theme/LayoutConstants.swift`

---

## Swift Concurrency Rules (CRITICAL)

- Any enum, struct, or class that accesses `@MainActor`-isolated properties (e.g. `String.localized`, `LocalizationManager.shared`) MUST itself be marked `@MainActor`.
- `L10n` enum is `@MainActor`. Any new type-safe key enums/extensions follow the same pattern.
- When a function returns `T?` and you guard with `if (!result) throw` — always use a non-optional binding after the guard: `guard let safeResult = result else { throw ... }` in Swift. TypeScript strict mode may not narrow type after throw.

---

## Architecture

- **State management:** `@MainActor @Observable` classes
- **Navigation:** `NavigationStack` with `AppRouter`
- **Cache:** `GameDataCache` environment object, cache-first pattern
- **Views:** Pass `@Bindable var vm` to child components (not `@State`)

---

## Property Access (CRITICAL)

Before accessing any property on a model:
- **Verify that the property exists** in the structure/class definition. Do not assume computed properties like `resolvedImageKey`, `resolvedX`, etc. exist — they may be unique to certain types.
- Different models (`Item`, `ShopItem`, `LootPreview`, `EquippedItem`, etc.) have **different property sets**, even if conceptually similar. Always check the specific type definition.
- If the needed property **does NOT exist**, either:
  - Use an existing field directly (e.g., `imageKey` instead of `resolvedImageKey`), or
  - Add a computed property to the model

---

## Art Style (for AI image generation prompts)

- Full art style guide: `Hexbound/ART_STYLE_GUIDE.md`
- Style: **pen and ink illustration**, bold black ink outlines, muted earth tones + 1-2 saturated accent colors, **grimdark dark fantasy**, isolated on white/transparent background
- Reference: **D&D Monster Manual / Pathfinder rulebook** illustrations (NOT digital painting, NOT concept art, NOT anime)
- Always start prompts with: `Pen and ink illustration of...`
- Always end with: `isolated on white background, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text`
- **Warning:** The icon `icon-gold-mine` is in a DIFFERENT casual/cartoon style — do NOT use as art style reference

---

## Server-Authoritative Rule (CRITICAL)

The client MUST NOT calculate:
- Combat results
- Reward amounts
- Rating changes
- Economy values
- Balance formulas

**Always display what the server returns.** Never perform client-side calculations for game state that affects progression.

---

## Admin Panel (Next.js / TypeScript)

- **Strict null checks:** When a function returns `T | null`, always narrow the type before use. Prefer `if (!x) throw` followed by explicit non-null assertion or destructuring, not bare `x.property` access.
- **Build before push:** Run `npx next build` locally or check Vercel preview before merging to `main`.

---

## Self-Documenting Rules (META — MANDATORY)

If during work you discover a pattern, error, or practice that:
- **repeats** from time to time (same mistake / same manual step),
- **breaks the build** or causes a runtime crash,
- requires **non-obvious knowledge** about the project (API quirks, model structure, dependencies),

then **automatically add a new rule** to these development rules — do not ask first. Format: brief description of the problem + what to do / what not to do. Choose the relevant section or create a new one.

---

## UI/UX Design Rules

### Before Any Design Work

1. **Read the design system files** — do not guess which tokens exist. Open `DarkFantasyTheme.swift`, `ButtonStyles.swift`, `LayoutConstants.swift` and verify.
2. **Check existing components** — look in `Hexbound/Hexbound/Views/Components/` before proposing new ones. We already have: `panelCard()`, `GoldDivider()`, `TabSwitcher`, `HubLogoButton`, `ActiveQuestBanner`, skeleton cards, and others.

### Product Principles (Hard Requirements)

- **3-second rule** — player understands the screen in under 3 seconds
- **One goal per screen** — one primary CTA, everything else is secondary
- **No dead ends** — every state (empty, error, loading) has a clear next action
- **Short sessions** — 2-5 minutes per session, respect the player's time
- **Monetization = acceleration** — never hard-block fair play

### Mobile UX Standards

- Minimum touch target: 48×48pt, primary buttons 56pt+
- Key actions in bottom 60% (thumb zone)
- Max 4-6 actions visible at once
- Minimum font: 11px (`LayoutConstants.textBadge`)
- Every interactive element: define default, pressed, selected, disabled, loading, error, success states
- Every list: define empty state with CTA
- Loading: skeletons > spinners > blank screens

### UX Audit Format

When reviewing a screen, always:
1. **Start with strengths** — what's working well (3-5 items)
2. **Then issues** — each with: What → Problem → Impact → Fix → Priority (Critical/High/Medium/Low)
3. **Reference real tokens** from the design system files
4. **Check existing components** before suggesting new ones

### Game Systems Checklist

Every UX decision must account for:
- Retention hooks
- Fairness (anti-exploit)
- Progression clarity
- Reward anticipation
- Economy health
- Anti-frustration after losses
- First-session friendliness
- Live ops extensibility

---

## Communication Style

When proposing changes or explaining issues:
- Be concrete — give specific code or concrete explanations, not high-level overviews
- Be direct — go straight to the solution, not "Here's how you can..."
- Be brief and casual (terse)
- Propose solutions the user may not have thought of
- Assume the user is an expert
- Be precise and thorough
- Answer immediately, then provide detailed explanation or context if needed
- Value good arguments over authority; source doesn't matter
- Consider new technologies and counter-intuitive ideas, not just conventional wisdom
- Speculation is fine — just mark it as such
- No moral lectures
- Discuss security only when critical and non-obvious
- When correcting provided code, do NOT repeat all of it. Give a few lines before/after changes. Multiple code blocks are fine.
- Respect prettier preferences
- If one answer is too long, split into multiple responses

---

## Core Mission & Priority Order

Your mission:
- preserve system integrity
- avoid duplication
- keep docs, code, UI, balance, and admin aligned
- make changes that are minimal, reversible, and easy to verify

Priority order:
1. correctness
2. consistency
3. safety
4. clarity
5. speed

---

## Source of Truth Hierarchy

Code is the ultimate source of truth:
- backend → admin panel → iOS/SwiftUI app → database schema → live config

Canonical docs live only in `/docs/*`. Main entry point: `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`

If docs conflict with code → update docs. Do not invent behavior. Do not trust outdated notes over implementation.

---

## Documentation Governance

- One topic = one file. No duplicate docs. No parallel versions. No shadow documentation in random folders.
- Allowed statuses: `canonical`, `legacy` (pointer/stub), `archived` (frozen, no edits).
- When changing docs: update existing canonical file. Do not create a new competing file.
- Update `DOCUMENTATION_INDEX.md` if structure changes.
- Legacy files must contain: status label + replacement path.
- Archive instead of delete if history may matter. Archive files must not be edited.

---

## File Safety Rules

Before move / rename / archive / delete — always search: exact filename, old path, title/mentions, references in code, imports, prompts, scripts, CI, README, CLAUDE, SKILL, comments, docs index.

If any reference exists → do not hard-delete. Keep as stub or legacy.

Preferred action order: **keep → keep as stub → archive → delete**

Never break: agent entry points, prompt references, asset paths, imports, docs links, scripts, CI workflows.

---

## Development Principles

- No silent failures
- No fake implementations
- No dead code if avoidable
- Strict typing
- Predictable state
- Explicit errors
- Minimal diff
- Reversible changes
- Do not over-engineer
- Do not introduce duplicate logic

---

## Admin-First Rule

If a value/system is expected to be tuned by team/admin:
- expose via admin/config
- document in `ADMIN_CAPABILITIES.md`
- do not bury tunable product logic in code

When adding feature, ask: should this be configurable? visible in admin? documented for live tuning?

---

## Game System Alignment

Always align with: `GAME_SYSTEMS.md`, `ECONOMY.md`, `BALANCE_CONSTANTS.md`, `COMBAT.md`, `PROGRESSION.md`

- No balance values invented without checking config/docs/code
- No forked economy logic or duplicate formulas
- No hidden reward logic
- No inconsistent item/stat terminology
- If mismatch found → verify against code/config, fix canonical docs

---

## Prompt / Asset Safety

Always align with: `ART_STYLE_GUIDE.md`, `ASSET_PROMPTS_INDEX.md`

- No random art direction or style drift
- No new prompt file without indexing it
- Preserve naming consistency
- Do not move asset/prompt files unless reference safety is verified

---

## Agent Execution Model

Before any task:
1. Read `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`
2. Find relevant canonical docs
3. Verify with code if behavior/structure is involved
4. Determine task type: new work / modification / cleanup / migration / bugfix / UI polish / docs sync
5. Apply smallest correct change

Never: guess architecture, recreate existing systems, invent APIs, create duplicates, make broad refactors without need.

---

## Self-Audit Checklist (Before Every Action)

**A. CONTEXT** — What system? What source of truth? Which canonical docs? Existing pattern?
**B. DEPENDENCY** — What depends on this? Could it break imports, links, paths, agents, admin flows?
**C. DUPLICATION** — Am I creating a duplicate? Does this exist under another name?
**D. CONSISTENCY** — Matches naming, tokens, architecture, balance vocabulary, UX patterns?
**E. RISK** — Low / medium / high? Can I achieve this with a smaller change?
**F. DOCUMENTATION** — Which canonical doc must be updated?

If any answer is unclear → inspect more, do not guess.

---

## Change Protocol

1. Identify exact goal
2. Identify source of truth
3. Search dependencies/references
4. Make smallest safe change
5. Update canonical docs if needed
6. Verify outputs
7. Report clearly

Cleanup: prefer label/stub/archive over delete. Delete only with zero active references.
Feature: reuse existing systems first. Check admin/config + docs + UI/system consistency.

---

## Strict PR Flow

Every change must pass:
- **PR-1 Scope** — small and clear?
- **PR-2 System Fit** — fits architecture, docs, tokens, game systems?
- **PR-3 Duplication** — avoided duplicates?
- **PR-4 Safety** — could break references, imports, config, assets, prompts, agents?
- **PR-5 Documentation** — relevant canonical docs updated?
- **PR-6 Validation** — affected flows checked?
- **PR-7 Output Quality** — understandable for next human/agent?

---

## Cursor / IDE Auto-Checklist

### General
- [ ] Checked `DOCUMENTATION_INDEX.md`
- [ ] Used canonical docs, not legacy
- [ ] Confirmed source of truth in code
- [ ] Smallest safe change
- [ ] No duplicates

### Code
- [ ] No hardcoded tunable gameplay values
- [ ] Naming matches conventions
- [ ] No dead/placeholder logic
- [ ] Explicit error handling
- [ ] No hidden side effects

### UI
- [ ] Design tokens used
- [ ] Existing component/button patterns
- [ ] Primary action clear
- [ ] Consistent spacing/colors/styles
- [ ] No dead ends

### Game / Balance
- [ ] Values verified against config/docs/code
- [ ] Economy consistent
- [ ] No duplicate formulas
- [ ] Terminology matches

### Admin / Config
- [ ] Tunable values considered for admin
- [ ] New config keys documented
- [ ] No hidden product controls in code only

### Docs
- [ ] Canonical doc updated
- [ ] No duplicate doc created
- [ ] Index updated if structure changed

### Cleanup
- [ ] Searched references before move/delete
- [ ] Stub/archive preferred over deletion
- [ ] No risky prompt/asset/agent changes without proof

---

## Output Format For Every Task

Report:
1. What changed
2. Where it changed
3. Why it changed
4. Source of truth used
5. Affected systems
6. Docs updated
7. Risk level: low / medium / high
8. Follow-up concerns

---

## Forbidden Actions

- Create duplicate docs or parallel "v2/final/fixed/new" files
- Invent architecture or API behavior
- Hardcode tunable balance values
- Ignore admin/config responsibility
- Use random tokens/colors/components
- Break stubs without checking references
- Move/delete prompts/assets/agent files carelessly
- Trust outdated legacy docs over code
- Make broad refactors when narrow change is enough

---

## Decision Rule When Unsure

Inspect more → search references → verify in code → choose safer action → prefer preserving compatibility.

Elegant-but-risky vs safe-but-less-elegant → **choose safe**.

---

## Final Operating Principle

**Clarity over speed.**
**Consistency over novelty.**
**System integrity over local optimization.**
**Small safe changes over big clever changes.**

Your role is not just to complete tasks.
Your role is to protect the project from chaos while improving it.
