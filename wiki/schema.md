# Hexbound Wiki — Schema

This wiki is an LLM-maintained knowledge base for the Hexbound game project. The LLM writes and maintains all pages. The human curates sources, asks questions, and directs analysis.

## Directory Structure

```
wiki/
  schema.md        — this file (rules for the LLM)
  index.md         — catalog of all pages with one-line summaries
  log.md           — chronological record of ingests, queries, updates
  systems/         — game systems (combat, economy, progression, PvP, dungeons...)
  decisions/       — design decisions with rationale, tradeoffs, alternatives considered
  entities/        — key models, screens, services, components
```

## Page Format

Every wiki page uses this template:

```markdown
---
title: Page Title
category: systems | decisions | entities
tags: [combat, balance, pvp]
sources: [docs/06_game_systems/COMBAT.md, commit abc123]
updated: 2026-04-14
---

# Page Title

Content here. Use [[wiki-links]] to cross-reference other wiki pages.

## See Also
- [[Related Page 1]]
- [[Related Page 2]]
```

## Naming Conventions

- Filenames: kebab-case (`pvp-rating-system.md`, `why-no-gem-to-gold.md`)
- Wiki-links: `[[filename]]` without extension (Obsidian-compatible)
- Tags: lowercase, no spaces

## Operations

### Ingest
When processing a new source (doc, commit, conversation insight):
1. Read the source fully
2. Discuss key takeaways with the user
3. Create or update relevant wiki pages
4. Update `index.md` with new/changed pages
5. Append entry to `log.md`
6. Check for contradictions with existing pages — flag them

### Query
When answering a question:
1. Read `index.md` to find relevant pages
2. Read those pages
3. Synthesize answer with `[[wiki-links]]` as citations
4. If the answer is valuable, offer to save it as a new wiki page

### Lint
Periodic health check:
1. Orphan pages (no inbound links)
2. Contradictions between pages
3. Stale data (newer sources supersede)
4. Missing pages (concepts mentioned but no page exists)
5. Data gaps worth investigating

## Rules

- **Never modify `raw/` sources** — they are immutable
- **Always update `index.md`** after creating or significantly updating a page
- **Always append to `log.md`** after any operation
- **Cross-reference aggressively** — every page should link to related pages
- **Cite sources** — use the `sources:` frontmatter to trace back to raw docs/commits
- **Flag contradictions** — if new data conflicts with existing page, note both versions
- **Numbers are sacred** — never round or approximate game constants. Copy exact values.
- **Decisions need "why"** — every decisions/ page must explain the rationale, not just the what
- **Keep pages focused** — one topic per page. Split if a page exceeds ~200 lines.

## Source Hierarchy

When sources conflict, trust in this order:
1. Backend code (`backend/src/lib/game/balance.ts`) — the actual running values
2. `docs/06_game_systems/BALANCE_CONSTANTS.md` — documented constants
3. CLAUDE.md rules — architectural decisions
4. Commit messages — context for changes
5. Wiki pages — synthesized knowledge (update if wrong)

## Integration with Existing Tools

- **Graphify** (`graphify-out/graph.json`) — use for code architecture questions
- **Docs** (`docs/`) — primary source material for initial wiki population
- **Memory** (`.claude/projects/.../memory/`) — cross-session facts (different purpose: memory = for Claude, wiki = for human)
