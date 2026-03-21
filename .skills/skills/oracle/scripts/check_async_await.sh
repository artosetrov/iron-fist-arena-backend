#!/bin/bash
# Scans TypeScript files for missing await on known async functions.
# Usage: ./check_async_await.sh [file_or_dir] [project_root]

TARGET="${1:-.}"
ROOT="${2:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"

echo "=== ASYNC/AWAIT SCAN ==="
echo ""

# --- 1. Known async functions that MUST be awaited ---
# These are all async in Hexbound but easy to forget
ASYNC_PATTERNS=(
  'get.*Config('      # All get*Config() in live-config.ts are async
  'prisma\.'          # All Prisma queries are async
  'fetch('            # fetch() is async
  'supabase\.'        # Supabase client calls are async
)

echo "## Missing await on async calls"
echo ""

# Context-aware scan: exclude calls inside Promise.all/allSettled/race blocks.
# Simple grep can't detect multi-line Promise.all context, so we use two passes:
# Pass 1: grep for missing await (same-line exclusions)
# Pass 2: for each hit, check surrounding lines for Promise.all context

TMPFILE=$(mktemp)
for pattern in "${ASYNC_PATTERNS[@]}"; do
  grep -rn --include="*.ts" --include="*.tsx" "$pattern" "$TARGET" 2>/dev/null | \
    grep -v 'await' | \
    grep -v '^\s*//' | \
    grep -v 'import' | \
    grep -v 'type ' | \
    grep -v 'interface ' | \
    grep -v '\.d\.ts' | \
    grep -v 'node_modules' | \
    grep -v '.next' >> "$TMPFILE"
done

# Pass 2: Filter out hits that are inside Promise.all/allSettled/race blocks
REAL_COUNT=0
FALSE_POS=0
while IFS= read -r hit; do
  FILE=$(echo "$hit" | cut -d: -f1)
  LINENUM=$(echo "$hit" | cut -d: -f2)
  # Check 15 lines above for Promise.all( that hasn't been closed yet
  START=$((LINENUM - 15))
  [ "$START" -lt 1 ] && START=1
  CONTEXT=$(sed -n "${START},${LINENUM}p" "$FILE" 2>/dev/null)
  if echo "$CONTEXT" | grep -qE 'Promise\.(all|allSettled|race)\s*\('; then
    FALSE_POS=$((FALSE_POS + 1))
  else
    echo "❌ [no await] $hit"
    REAL_COUNT=$((REAL_COUNT + 1))
  fi
done < "$TMPFILE"
rm -f "$TMPFILE"

echo ""
echo "Found $REAL_COUNT real issues ($FALSE_POS excluded — inside Promise.all/allSettled/race)"

echo ""

# --- 2. Null safety ---
echo "## Potential null safety issues"
echo ""
# Find patterns like variable.property where variable came from findFirst/findUnique
grep -rn --include="*.ts" --include="*.tsx" -B2 'findFirst\|findUnique' "$TARGET" 2>/dev/null | \
  grep -v 'node_modules' | \
  head -20

echo ""

# --- 3. Json field casts ---
echo "## Prisma Json field casts (should be double-cast)"
echo ""
grep -rn --include="*.ts" --include="*.tsx" ' as [A-Z]' "$TARGET" 2>/dev/null | \
  grep -v 'as unknown' | \
  grep -v 'node_modules' | \
  grep -v '\.d\.ts' | \
  grep -v 'import' | \
  grep -E '(Json|json|JSON)' | \
  while IFS= read -r line; do
    echo "⚠️  [single cast on Json] $line"
  done

echo ""

# --- 4. Junk files ---
echo "## Junk TS files"
echo ""
find "$TARGET" -name "* 2.*" -o -name "* 2" 2>/dev/null | \
  grep -E '\.(ts|tsx)$' | \
  while IFS= read -r line; do
    echo "❌ [junk file] $line"
  done

# Also check directories
find "$TARGET" -type d -name "* 2" 2>/dev/null | \
  while IFS= read -r line; do
    echo "❌ [junk dir] $line"
  done

echo ""
echo "=== SCAN COMPLETE ==="
