# Hexbound — Development Rules

*Canonical rules document. Agent System Rules v3. Updated: 2026-03-21*

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
- **ALWAYS** use `LayoutConstants` for spacing, sizing, and fonts
  - **Readable text** (labels, body, captions): minimum **16px** (`LayoutConstants.textCaption`)
  - **Decorative badges** (damage pills, status indicators, bar labels): minimum **11px** (`LayoutConstants.textBadge`)
  - **SF Symbol icons inside badges**: minimum **11px** (same as badge text)
  - Dev-only views (HubEditor, DesignSystemPreview) may use smaller sizes

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

## Accessibility (REQUIRED)

### Every Button Must Have an accessibilityLabel

- **All** `Button { }` views must have `.accessibilityLabel("descriptive text")`
- Labels should describe the **action**, not the visual element (e.g., "Go back" not "Arrow button")
- Icon-only buttons (arrows, toggles, close) are the highest priority — VoiceOver users can't see the icon
- Buttons with visible text labels (e.g., `Text("LOG IN")`) still benefit from labels when the text is abbreviated or ambiguous
- Dynamic state → dynamic label: `.accessibilityLabel(isVisible ? "Hide password" : "Show password")`

### No Emoji as Functional Icons

- **NEVER** use emoji (⚔️ 🛡️ 🎯 etc.) as the primary icon for interactive/functional UI
- Use asset images from `Assets.xcassets` or SF Symbols
- Emoji are acceptable in decorative/flavor contexts (chat messages, flavor text) but not as zone/status/navigation indicators
- Existing: `StanceSelectorViewModel.zoneAsset(for:)` returns the correct image asset for zones

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

## Game System Design Principles (Five Hallmarks)

Every game system in Hexbound must satisfy these five qualities. When adding new mechanics, modifying balance, or extending content — run each change through this checklist.

### Comprehensible

You must understand all parts of the system you're touching. Know how values are chosen, why they work that way, and what other rules/content they impact. If you want to adjust gameplay in a specific way, you should know exactly what to change to get that result.

**Hexbound check:** Before modifying any formula (damage, XP, gold, drop rates), trace the full dependency chain: what feeds into it, what it feeds, and what breaks if it changes.

### Consistent

Game rules and content must function the same in all areas of the game. Armor works the same for all classes. Gold formulas don't secretly change at high levels. Damage types behave identically in PvP, dungeons, and training.

**Hexbound check:** If a rule applies differently in different contexts (e.g., PvP vs. dungeon), that exception must be explicit in `BALANCE_CONSTANTS.md` and `live-config`. No silent special-casing in code.

### Predictable

You should be able to determine how systems will behave in new circumstances. If you multiply XP by 2x or introduce a monster with double armor, the results should be calculable in advance using documented formulas.

**Hexbound check:** Every formula in `balance.ts`, `combat.ts`, `progression.ts` must be documented in the corresponding `docs/06_game_systems/` file with worked examples. If you can't predict the outcome — the system needs better documentation or simplification.

### Extensible

When you create new types of content, you should be able to extend existing systems to include it easily. New class? New item rarity? New dungeon type? The existing system should accommodate it without rewriting core rules.

**Hexbound check:** New content types (skills, items, bosses, events) must plug into existing Parameters → Rules → Content pipeline. If adding a new feature requires touching 10+ files — the system isn't extensible enough. Consider adding config-driven abstractions first.

### Elegant

Rich situations from a small number of moving parts. The stance system (3 zones × attack/defense) creating meaningful tactical depth is a good example. Resist the urge to add parameters — instead, find more interactions between existing ones.

**Hexbound check:** Before adding a new stat or parameter, ask: can this be achieved by combining existing stats? The 8-stat system (STR/AGI/VIT/END/INT/WIS/LUK/CHA) should be the ceiling, not the floor.

---

## Game System Taxonomy: Parameters → Rules → Content

When designing or modifying any system, always think in these three layers:

**Parameters** — The values your systems use: health, damage, armor, crit chance, XP, gold, stamina, cooldown, etc. These are the atoms of your system. Keep the parameter list lean — every new parameter adds complexity everywhere.

**Rules** — The formulas and functions that determine outcomes: damage calculation pipeline, XP curve, drop chance formula, ELO rating, etc. Rules should be no more complex than necessary. Simple formulas with clear inputs → outputs are easier to balance and debug.

**Content** — The things in the game: characters, items, skills, dungeons, bosses, quests. Each content type has parameters that define it. Content is the most extensible layer — you should be able to add hundreds of items without changing rules.

**Design order for new systems:**
1. Choose parameters (what values does this system need?)
2. Design rules (simplest formulas that implement the vision)
3. Define progressions (how do parameters change over time?)
4. Design content types (as complex and interesting as you can manage)
5. Add new layers as needed (iterate, don't over-design upfront)

**Hexbound mapping:**
- Parameters: STR, AGI, VIT, END, INT, WIS, LUK, CHA, HP, armor, magicResist, critChance, dodgeChance, ELO, gold, gems, stamina, XP, battlePassXP
- Rules: Damage pipeline (12 steps), XP curve ($100N + 20N^2$), armor formula ($\text{dmg} \times 100/(100+\text{armor})$), ELO formula, drop chances, gold scaling
- Content: 4 classes, 5 origins, 80+ skills, 200+ items, 150+ passive nodes, dungeons, bosses, achievements, quests, battle pass rewards

---

## RPG Sub-Genre Classification

Hexbound is an **Action RPG** with PvP focus. This classification determines which mechanics are expected by players and which are optional.

### Expected Mechanics (Action RPG)

| Category | Hexbound Implementation |
|----------|------------------------|
| **Combat** | Real-time PvP, spells, abilities, defensive actions (stance system), item use |
| **Traversal** | Dungeon floor progression, fast travel (hub-based) |
| **Strategy** | Stat allocation, skill loadout, stance selection, equipment optimization |
| **Progression** | Skill tree (passive nodes), ability tree, equipment upgrades, prestige system |

### Deliberately Excluded (Not Our Sub-Genre)

- Turn-based combat, isometric grid, party management, NPC training — these belong to Tactical/Turn-Based RPGs
- Heavy exploration, mounts, open world — these belong to CRPGs
- Branching dialogue trees, player-driven story arcs — these belong to CRPGs/Narrative RPGs

### Target Audience Archetype

Hexbound targets a mix of these player motivations (from most to least important):

1. **Self-Expression** — Players build unique characters via stat allocation, skill loadouts, passive trees. Each build feels personal and optimized. (Example reference: Baldur's Gate 3)
2. **Collection & Completion** — Players collect items, achievements, battle pass rewards, passive nodes. Completionist drive keeps them engaged. (Example reference: Persona 5)
3. **Progression** — Even in PvP context, players want to see their character grow stronger over time. Visible power growth is key. (Example reference: Skyrim)
4. **Narrative-Driven** — Minimal. Lore exists as flavor, not motivation. (Example reference: N/A for Hexbound)

When designing features, prioritize Self-Expression and Collection mechanics. Do not invest in narrative systems that don't serve these primary motivations.

---

## Systems Follow Gameplay (Core Design Principle)

Systems are a tool for creating and managing content — not the starting point. Before designing any new system, answer:

1. **What is the core game loop?** → Short-session PvP combat with character progression
2. **What interesting decisions do players make?** → Stat allocation, skill loadout, stance selection, equipment choices, resource spending
3. **What are the appeals?** → Competitive ranking, visible power growth, collection, dark fantasy aesthetic

Every new system must serve at least one of these. If it doesn't support the core loop or player decisions — it's bloat, not depth.

### Design Orientation (GNS Framework)

Hexbound is intentionally positioned on the GNS spectrum:

- **Gamist (primary)** — PvP competition, ELO ranking, build optimization, min-maxing stats. The game rewards system mastery and strategic thinking. Every system should create interesting *decisions* for the player.
- **Simulationist (secondary)** — Detailed damage formulas, stat interactions, armor mitigation curves. Systems feel like they have internal logic and "physics." Players can theory-craft because the math is consistent.
- **Narrativist (minimal)** — Lore exists as flavor (item descriptions, dungeon intros, boss names), not as gameplay driver. No dialogue trees, no branching stories, no cutscenes. This is a deliberate constraint — narrative costs dev time and doesn't serve 2-5 minute sessions.

When designing new features, ask: does this serve the **Gamist** or **Simulationist** angle? If it's purely narrative with no gameplay impact — it belongs in `WORLD_AND_LORE.md` as flavor text, not as a new system.

### Three Pillars of Gameplay

| Pillar | Hexbound Status | Priority | Notes |
|--------|----------------|----------|-------|
| **Combat** | Core pillar | Critical | PvP, dungeons, training — all combat-driven |
| **Exploration** | Secondary | Medium | Dungeon floors, loot discovery, passive tree exploration |
| **Social** | Minimal | Low | No chat, no guilds (planned), no trading. Leaderboard is passive social. |

New features should strengthen Combat first, Exploration second. Social features (guilds, chat, trading) are roadmap items that should not compromise the core combat loop.

---

## Loot & Randomness Design Principles

When designing item drops, random rewards, or any outcome variability:

### Risk ↔ Reward Proportionality

Player effort/risk must correlate with reward quality. A chest behind a hard dungeon floor must never drop common-only loot. Even with RNG, the *floor* of the reward must match the *ceiling* of the effort.

### Fixed vs. Random Loot Placement

- **Fixed loot:** Quest rewards, achievement unlocks, battle pass tiers, boss-specific drops. Player expects a known reward — deliver it.
- **Random loot:** Dungeon chests, PvP bonus drops, daily rewards. Randomness creates excitement — but apply rarity floor based on context.
- **Never fully random for high-effort content.** If a player cleared 10 dungeon floors, at least one guaranteed rare+ drop.

### Rarity Consistency

Each rarity tier must have distinct and predictable stat ranges. A Legendary item is always better than an Epic in its stat budget — no exceptions. Rarity naming, colors, and stat ranges are defined in `BALANCE_CONSTANTS.md`.

### Pity / Bad Luck Protection

If a system uses RNG (gacha, drop chances), implement escalating probability or pity counters. After $N$ failed attempts, guarantee a minimum rarity. This prevents frustration spirals and is critical for retention.

---

## Game System Alignment

Always align with: `GAME_SYSTEMS.md`, `ECONOMY.md`, `BALANCE_CONSTANTS.md`, `COMBAT.md`, `PROGRESSION.md`

- No balance values invented without checking config/docs/code
- No forked economy logic or duplicate formulas
- No hidden reward logic
- No inconsistent item/stat terminology
- If mismatch found → verify against code/config, fix canonical docs

### Game System Change Checklist

Before modifying any game system (combat, economy, progression, items, skills):

- [ ] **Comprehensible** — I can explain what this change does and why, and trace its impact chain
- [ ] **Consistent** — This rule works the same everywhere it applies (PvP, dungeon, training)
- [ ] **Predictable** — I can calculate the outcome of this change with a concrete example
- [ ] **Extensible** — This doesn't break when we add new content (classes, items, skills)
- [ ] **Elegant** — This achieves the goal with minimum new parameters/complexity
- [ ] **Documented** — Formula and examples updated in `docs/06_game_systems/`
- [ ] **Config-driven** — Tunable values exposed via `GameConfig` / admin panel, not hardcoded

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
