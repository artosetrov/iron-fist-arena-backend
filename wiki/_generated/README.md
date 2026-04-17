# Generated Indexes

**Do not edit these files by hand.** They are auto-generated from authoritative source files.

## Files

| File | Generated from | Regenerate with |
|---|---|---|
| `tokens.json` | `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`, `Hexbound/Hexbound/Theme/LayoutConstants.swift` | `scripts/wiki/generate-tokens.mjs` |
| `api-routes.json` | `backend/src/app/api/**/route.ts` | `scripts/wiki/generate-api-routes.mjs` |
| `prisma-models.json` | `backend/prisma/schema.prisma` | `scripts/wiki/generate-prisma-models.mjs` |

## Regenerate everything

```bash
bash scripts/wiki/generate-all.sh
```

## When to regenerate

- After any change to `DarkFantasyTheme.swift`, `LayoutConstants.swift`
- After any change to `backend/src/app/api/**/route.ts`
- After any change to `backend/prisma/schema.prisma`
- Before commit (preflight will warn if stale)

## Why

These JSON files exist so Claude and other tools can answer questions like
"does token `rarity_legendary` exist?" or "what API routes require auth?"
with a single file read + grep, instead of scanning source code and guessing.

Markdown is for humans. JSON is for machines and fast lookup.

## Schema drift

If a generator output conflicts with the source file during commit, the source wins.
Regenerate and re-commit.
