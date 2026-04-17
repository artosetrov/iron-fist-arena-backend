#!/usr/bin/env bash
# Check that wiki/_generated/*.json files are up to date with their source files.
#
# Usage: bash scripts/wiki/check-drift.sh
#
# Exit 0: all generated files newer than their sources
# Exit 1: at least one generated file is stale — regenerate with:
#          bash scripts/wiki/generate-all.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

STALE=0

# Most-recent-mtime of any file matching a glob
latest_mtime() {
  # shellcheck disable=SC2068
  local files=()
  for pat in "$@"; do
    while IFS= read -r f; do
      files+=("$f")
    done < <(find $pat -type f 2>/dev/null)
  done
  if [ ${#files[@]} -eq 0 ]; then
    echo 0
    return
  fi
  # Print max mtime
  local max=0
  for f in "${files[@]}"; do
    local m
    m=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || echo 0)
    [ "$m" -gt "$max" ] && max=$m
  done
  echo "$max"
}

check_one() {
  local out="$1"
  shift
  local sources=("$@")

  if [ ! -f "$out" ]; then
    echo "  ❌ $out does not exist"
    STALE=1
    return
  fi

  local out_m
  out_m=$(stat -c %Y "$out" 2>/dev/null || stat -f %m "$out" 2>/dev/null || echo 0)
  local src_m
  src_m=$(latest_mtime "${sources[@]}")

  if [ "$src_m" -gt "$out_m" ]; then
    echo "  ⚠️  $out is stale (source modified later)"
    STALE=1
  else
    echo "  ✅ $out is current"
  fi
}

echo "=== Wiki Generated Files — Drift Check ==="
echo ""

check_one "wiki/_generated/tokens.json" \
  "Hexbound/Hexbound/Theme/DarkFantasyTheme.swift" \
  "Hexbound/Hexbound/Theme/LayoutConstants.swift"

check_one "wiki/_generated/api-routes.json" \
  "backend/src/app/api"

check_one "wiki/_generated/prisma-models.json" \
  "backend/prisma/schema.prisma"

check_one "wiki/_generated/balance-constants.json" \
  "backend/src/lib/game/balance.ts"

check_one "wiki/_generated/ios-screens.json" \
  "Hexbound/Hexbound/App/AppRouter.swift" \
  "Hexbound/Hexbound/Views"

echo ""
if [ "$STALE" -eq 1 ]; then
  echo "⚠️  At least one generated file is stale. Run:"
  echo "   bash scripts/wiki/generate-all.sh"
  exit 1
else
  echo "✅ All generated files current."
  exit 0
fi
