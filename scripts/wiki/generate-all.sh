#!/usr/bin/env bash
# Regenerate all wiki/_generated/*.json files from authoritative source files.
#
# Usage: bash scripts/wiki/generate-all.sh
#
# Run this whenever you change:
#   - Hexbound/Hexbound/Theme/DarkFantasyTheme.swift
#   - Hexbound/Hexbound/Theme/LayoutConstants.swift
#   - backend/src/app/api/**/route.ts
#   - backend/prisma/schema.prisma
#   - backend/src/lib/game/balance.ts
#   - Hexbound/Hexbound/App/AppRouter.swift
#   - Hexbound/Hexbound/Views/**/*.swift
#
# Preflight will warn if any generated file is stale.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "Regenerating wiki indexes..."
echo ""

node scripts/wiki/generate-tokens.mjs
node scripts/wiki/generate-api-routes.mjs
node scripts/wiki/generate-prisma-models.mjs
node scripts/wiki/generate-balance-constants.mjs
node scripts/wiki/generate-ios-screens.mjs

echo ""
echo "Done. Generated files:"
ls -la wiki/_generated/*.json
