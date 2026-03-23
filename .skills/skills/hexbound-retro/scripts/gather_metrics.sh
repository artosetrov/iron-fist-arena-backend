#!/bin/bash
# Hexbound Retro — Metrics Gatherer
# Scans recent git activity and current violation counts for the daily retrospective.
# Usage: ./gather_metrics.sh [project_root] [days_back]
#
# Improvements over chronicler/gather_metrics.sh:
# - Scans all .skills/skills/*/ (not just hexbound-* prefix)
# - Counts bare tokens with extension-coverage awareness
# - Checks merge conflict markers
# - Reports Color extension coverage

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
DAYS="${2:-1}"
SINCE="$(date -d "$DAYS days ago" +%Y-%m-%d 2>/dev/null || date -v-${DAYS}d +%Y-%m-%d 2>/dev/null || echo "$DAYS days ago")"
THEME="$ROOT/Hexbound/Hexbound/Theme/DarkFantasyTheme.swift"

cd "$ROOT" || exit 1

echo "=== HEXBOUND RETRO METRICS ==="
echo "Project: $ROOT"
echo "Period: last $DAYS day(s) (since $SINCE)"
echo ""

# --- 1. Git Activity ---
echo "## 1. Git Activity"
echo ""
COMMIT_COUNT=$(git log --since="$SINCE" --oneline 2>/dev/null | wc -l | tr -d ' ')
echo "Commits: $COMMIT_COUNT"

if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo ""
  echo "No commits in period. Skipping detailed analysis."
  echo ""
  echo "=== METRICS COMPLETE (no activity) ==="
  exit 0
fi

FILES_CHANGED=$(git log --since="$SINCE" --name-only --pretty=format: 2>/dev/null | sort -u | grep -v '^$' | wc -l | tr -d ' ')
echo "Files touched: $FILES_CHANGED"

echo ""
echo "### Files changed by area:"
git log --since="$SINCE" --name-only --pretty=format: 2>/dev/null | sort -u | grep -v '^$' | \
  sed 's|/.*||' | sort | uniq -c | sort -rn
echo ""

echo "### Commit messages:"
git log --since="$SINCE" --oneline 2>/dev/null | head -30
echo ""

# --- 2. Current Violation Snapshot ---
echo "## 2. Current Violation Snapshot"
echo ""

# Hardcoded colors in Views (outside Theme)
COLORS_IN_VIEWS=$(grep -rn --include="*.swift" 'Color(hex:\|Color(red:\|Color(#' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | grep -v '//' | grep -v 'DarkFantasyTheme' | wc -l | tr -d ' ')
echo "Color(hex:) in Views/: $COLORS_IN_VIEWS"

# Bare tokens analysis — with extension awareness
EXTENSION_TOKENS=""
if [ -f "$THEME" ]; then
  EXTENSION_TOKENS=$(grep -A20 'extension Color {' "$THEME" 2>/dev/null | grep -oP 'static var \K\w+' | sort -u)
  EXTENSION_TOKENS="$EXTENSION_TOKENS
$(grep -A20 'extension ShapeStyle' "$THEME" 2>/dev/null | grep -oP 'static var \K\w+' | sort -u)"
  EXTENSION_TOKENS=$(echo "$EXTENSION_TOKENS" | sort -u | grep -v '^$')
  EXTENSION_EXCLUDE=$(echo "$EXTENSION_TOKENS" | tr '\n' '|' | sed 's/|$//')
fi

# Count ALL bare theme tokens (not system colors, not DarkFantasyTheme.xxx)
BARE_TOTAL=$(grep -rn --include="*.swift" -E '\.(foregroundColor|foregroundStyle|background|tint|shadow)\(\.' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | \
  grep -v 'DarkFantasyTheme' | grep -v '^\s*//' | \
  grep -vE '\.\(\.?(white|black|red|blue|green|gray|orange|yellow|pink|purple|cyan|mint|indigo|brown|clear|primary|secondary)\b' | \
  wc -l | tr -d ' ')
echo "Bare theme tokens total: $BARE_TOTAL"

if [ -n "$EXTENSION_EXCLUDE" ]; then
  BARE_SAFE=$(grep -rn --include="*.swift" -E '\.(foregroundColor|foregroundStyle|background|tint|shadow)\(\.' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | \
    grep -v 'DarkFantasyTheme' | grep -v '^\s*//' | \
    grep -vE '\.\(\.?(white|black|red|blue|green|gray|orange|yellow|pink|purple|cyan|mint|indigo|brown|clear|primary|secondary)\b' | \
    grep -E "\.($EXTENSION_EXCLUDE)" | wc -l | tr -d ' ')
  BARE_UNSAFE=$((BARE_TOTAL - BARE_SAFE))
  echo "  - extension-covered (safe): $BARE_SAFE"
  echo "  - UNSAFE (no extension): $BARE_UNSAFE"
  echo "  - Extension tokens: $EXTENSION_EXCLUDE"
fi

# Merge conflict markers (only in source files, skip node_modules/build artifacts)
CONFLICT_MARKERS=$(grep -rn --include="*.swift" --include="*.ts" --include="*.tsx" --include="*.prisma" "^<<<<<<<\|^>>>>>>>" "$ROOT/backend/src/" "$ROOT/admin/src/" "$ROOT/Hexbound/Hexbound/" 2>/dev/null | wc -l | tr -d ' ')
echo "Merge conflict markers: $CONFLICT_MARKERS"

# Buttons without buttonStyle
BUTTONS_TOTAL=$(grep -rn --include="*.swift" 'Button {' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | wc -l | tr -d ' ')
BUTTONS_STYLED=$(grep -rn --include="*.swift" '.buttonStyle(' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | wc -l | tr -d ' ')
echo "Buttons: $BUTTONS_TOTAL total, $BUTTONS_STYLED with .buttonStyle()"

# Accessibility
A11Y_LABELS=$(grep -rn --include="*.swift" 'accessibilityLabel' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | wc -l | tr -d ' ')
echo "accessibilityLabel count: $A11Y_LABELS"

# Junk files (limit search depth to avoid slow traversal)
JUNK=$(find "$ROOT/Hexbound" "$ROOT/backend" "$ROOT/admin" -maxdepth 5 \( -name "* 2.*" -o -name "* 2" \) 2>/dev/null | wc -l | tr -d ' ')
echo "Junk files (* 2*): $JUNK"

# Prisma sync check
if [ -f "$ROOT/backend/prisma/schema.prisma" ] && [ -f "$ROOT/admin/prisma/schema.prisma" ]; then
  PRISMA_DIFF=$(diff "$ROOT/backend/prisma/schema.prisma" "$ROOT/admin/prisma/schema.prisma" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$PRISMA_DIFF" -gt 0 ]; then
    echo "⚠️  Prisma schema OUT OF SYNC ($PRISMA_DIFF diff lines)"
  else
    echo "Prisma schema: in sync ✅"
  fi
fi

echo ""

# --- 3. Agent SKILL.md Inventory ---
echo "## 3. Agent Skills"
echo ""
for skill_dir in "$ROOT/.skills/skills/"*/; do
  if [ -f "$skill_dir/SKILL.md" ]; then
    NAME=$(basename "$skill_dir")
    # Get modification date
    MOD_DATE=$(stat -c '%Y' "$skill_dir/SKILL.md" 2>/dev/null || stat -f '%m' "$skill_dir/SKILL.md" 2>/dev/null)
    MOD_HUMAN=$(date -d "@$MOD_DATE" +%Y-%m-%d 2>/dev/null || date -r "$MOD_DATE" +%Y-%m-%d 2>/dev/null)
    # Count scripts
    SCRIPT_COUNT=$(find "$skill_dir/scripts" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
    echo "  $NAME: updated $MOD_HUMAN, $SCRIPT_COUNT script(s)"
  fi
done
echo ""

# --- 4. Rules Document Version ---
echo "## 4. Rules Document"
RULES_DATE=$(head -5 "$ROOT/docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
echo "DEVELOPMENT_RULES.md updated: $RULES_DATE"
echo ""

# --- 5. Recent fix patterns (heuristic) ---
echo "## 5. Fix Patterns in Commits"
echo ""
echo "### fix() commits:"
git log --since="$SINCE" --oneline 2>/dev/null | grep -i "^[a-f0-9]* fix" | head -10
echo ""
echo "### Files with most churn (excluding binary/assets):"
git log --since="$SINCE" --name-only --pretty=format: 2>/dev/null | grep -v '\.png$\|\.jpg$\|\.wav$\|\.mp3$\|\.json$' | sort | uniq -c | sort -rn | head -10
echo ""

echo "=== METRICS COMPLETE ==="
