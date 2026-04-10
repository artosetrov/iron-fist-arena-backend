#!/bin/bash
# =============================================================================
# check_ios_backend_drift.sh — W1.D5 CI guard
# =============================================================================
#
# Detects iOS hardcoding of game constants that MUST live on the backend
# (`backend/src/lib/game/balance.ts`) and flow to the client via `GameConfig`
# → `/api/game/init`. Server-authoritative architecture: client must never
# own balance numbers except as last-resort fallbacks.
#
# What it catches:
#   - New `static let <forbidden>` declarations in `AppConstants.swift`
#     without a `// DEPRECATED` marker on the preceding line.
#   - Forbidden constants outside AppConstants.swift entirely (loose hardcode).
#
# Forbidden constant names (patterns that shipped balance.ts → GameConfig):
#   - freePvpPerDay
#   - maxStamina
#   - pvpStaminaCost
#   - xpPerLevel
#
# How to allowlist an existing fallback:
#   Put a `// DEPRECATED` comment on the line IMMEDIATELY before the
#   declaration. The guard will skip it. Example:
#
#     // DEPRECATED: use cache.gameConfig.maxStamina — W4 removal
#     static let maxStamina = 120
#
# Usage:
#   ./scripts/check_ios_backend_drift.sh [project_root]
#
# Exit codes:
#   0 — clean (no drift)
#   1 — drift detected (forbidden constants without deprecation marker)
#
# =============================================================================

set -euo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$ROOT" || exit 1

APPCONSTANTS="Hexbound/Hexbound/App/AppConstants.swift"
IOS_ROOT="Hexbound/Hexbound"

FORBIDDEN='freePvpPerDay|maxStamina|pvpStaminaCost|xpPerLevel'

VIOLATIONS=0
VIOLATION_LIST=""

echo "=== iOS ↔ Backend Drift Check ==="
echo ""

# -----------------------------------------------------------------------------
# Check 1: AppConstants.swift — forbidden declarations WITHOUT DEPRECATED marker
# -----------------------------------------------------------------------------
if [ -f "$APPCONSTANTS" ]; then
  echo "## AppConstants.swift declarations"

  # awk scan: for each `static let <forbidden> = ...` line, check if the
  # previous non-blank line contains `// DEPRECATED`. If not, report.
  while IFS= read -r match; do
    # match format: "LINENO:    static let forbiddenName = 123"
    lineno="${match%%:*}"
    content="${match#*:}"

    # Look at the line immediately above
    prev_line=$(sed -n "$((lineno - 1))p" "$APPCONSTANTS" 2>/dev/null || echo "")

    if echo "$prev_line" | grep -q '// DEPRECATED'; then
      echo "  ✅ line $lineno: $(echo "$content" | sed 's/^[[:space:]]*//') — deprecated, skipped"
    else
      echo "  ❌ line $lineno: $(echo "$content" | sed 's/^[[:space:]]*//')"
      echo "     → missing \`// DEPRECATED\` marker on line $((lineno - 1))"
      VIOLATION_LIST="$VIOLATION_LIST\n  - $APPCONSTANTS:$lineno ($(echo "$content" | sed 's/^[[:space:]]*//'))"
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  done < <(grep -nE "static let ($FORBIDDEN) *=" "$APPCONSTANTS" 2>/dev/null || true)

  echo ""
else
  echo "  ⚠️  $APPCONSTANTS not found — skipping"
  echo ""
fi

# -----------------------------------------------------------------------------
# Check 2: forbidden constants declared OUTSIDE AppConstants.swift
# (any `static let <forbidden>` or `let <forbidden>` in iOS source)
# -----------------------------------------------------------------------------
if [ -d "$IOS_ROOT" ]; then
  echo "## iOS sources outside AppConstants.swift"

  # Find `(static )?let <forbidden> = <number>` in any .swift file under
  # Hexbound/Hexbound/ except AppConstants.swift itself.
  LOOSE=$(grep -rnE "(static )?let ($FORBIDDEN) *= *[0-9]" "$IOS_ROOT" \
    --include="*.swift" 2>/dev/null \
    | grep -v "$APPCONSTANTS" \
    || true)

  if [ -n "$LOOSE" ]; then
    while IFS= read -r hit; do
      echo "  ❌ $hit"
      VIOLATION_LIST="$VIOLATION_LIST\n  - $hit"
      VIOLATIONS=$((VIOLATIONS + 1))
    done <<< "$LOOSE"
  else
    echo "  ✅ no loose declarations"
  fi

  echo ""
fi

# -----------------------------------------------------------------------------
# Verdict
# -----------------------------------------------------------------------------
echo "================================="
if [ "$VIOLATIONS" -gt 0 ]; then
  echo "⛔ DRIFT DETECTED: $VIOLATIONS violation(s)"
  echo ""
  echo "Forbidden game constants must live in:"
  echo "  backend/src/lib/game/balance.ts"
  echo ""
  echo "And be exposed to iOS via:"
  echo "  GameConfig → /api/game/init → cache.gameConfig.*"
  echo ""
  echo "Violations:"
  echo -e "$VIOLATION_LIST"
  echo "================================="
  exit 1
else
  echo "✅ CLEAN: no iOS/backend constant drift"
  echo "================================="
  exit 0
fi
