#!/bin/bash
# Gathers metrics from recent work to feed the retrospective analysis.
# Usage: ./gather_metrics.sh [project_root] [days_back]
#
# Output: structured summary of recent changes, current violations, and agent health.

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
DAYS="${2:-7}"
SINCE="$(date -d "$DAYS days ago" +%Y-%m-%d 2>/dev/null || date -v-${DAYS}d +%Y-%m-%d 2>/dev/null || echo '7 days ago')"

cd "$ROOT" || exit 1

echo "=== HEXBOUND RETROSPECTIVE METRICS ==="
echo "Project: $ROOT"
echo "Period: last $DAYS days (since $SINCE)"
echo ""

# --- 1. Git Activity ---
echo "## 1. Git Activity"
echo ""
COMMIT_COUNT=$(git log --since="$SINCE" --oneline 2>/dev/null | wc -l | tr -d ' ')
echo "Commits: $COMMIT_COUNT"

FILES_CHANGED=$(git log --since="$SINCE" --name-only --pretty=format: 2>/dev/null | sort -u | grep -v '^$' | wc -l | tr -d ' ')
echo "Files touched: $FILES_CHANGED"

echo ""
echo "### Files changed by area:"
git log --since="$SINCE" --name-only --pretty=format: 2>/dev/null | sort -u | grep -v '^$' | \
  sed 's|/.*||' | sort | uniq -c | sort -rn
echo ""

echo "### Recent commit messages:"
git log --since="$SINCE" --oneline 2>/dev/null | head -20
echo ""

# --- 2. Current Violation Counts ---
echo "## 2. Current Violation Snapshot"
echo ""

# Hardcoded colors in Views
COLORS_IN_VIEWS=$(grep -rn --include="*.swift" 'Color(hex:' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | grep -v '//' | grep -v 'DarkFantasyTheme' | wc -l | tr -d ' ')
echo "Color(hex:) in Views/: $COLORS_IN_VIEWS"

# Hardcoded colors in Theme (expected — these are definitions)
COLORS_IN_THEME=$(grep -c 'Color(hex:' "$ROOT/Hexbound/Hexbound/Theme/DarkFantasyTheme.swift" 2>/dev/null | tr -d ' ')
echo "Color(hex:) in DarkFantasyTheme (definitions): $COLORS_IN_THEME"

# Buttons without buttonStyle
BUTTONS_TOTAL=$(grep -rn --include="*.swift" 'Button {' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | wc -l | tr -d ' ')
BUTTONS_STYLED=$(grep -rn --include="*.swift" '.buttonStyle(' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | wc -l | tr -d ' ')
echo "Buttons: $BUTTONS_TOTAL total, $BUTTONS_STYLED with .buttonStyle()"

# Accessibility labels
A11Y_LABELS=$(grep -rn --include="*.swift" 'accessibilityLabel' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | wc -l | tr -d ' ')
echo "accessibilityLabel count: $A11Y_LABELS"

# Small fonts (< 11px)
TINY_FONTS=$(grep -rn --include="*.swift" '\.font(\.system(size: [0-9]\b' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | grep -v 'Editor\|Preview\|Debug\|Dev/' | wc -l | tr -d ' ')
echo "Fonts < 10px (non-dev views): $TINY_FONTS"

# Emoji in functional UI
EMOJI_FUNCTIONAL=$(grep -rn --include="*.swift" 'Text("[\x{2600}-\x{27BF}\x{1F300}-\x{1F9FF}]' "$ROOT/Hexbound/Hexbound/Views/" 2>/dev/null | wc -l | tr -d ' ')
echo "Emoji in Text(): $EMOJI_FUNCTIONAL (check manually — some may be decorative)"

# Junk files
JUNK=$(find "$ROOT/Hexbound" "$ROOT/backend" "$ROOT/admin" -name "* 2.*" -o -name "* 2" 2>/dev/null | wc -l | tr -d ' ')
echo "Junk files (* 2*): $JUNK"

echo ""

# --- 3. Agent SKILL.md Freshness ---
echo "## 3. Agent SKILL.md Last Modified"
echo ""
for skill_dir in "$ROOT/.skills/skills/hexbound-"*; do
  if [ -f "$skill_dir/SKILL.md" ]; then
    NAME=$(basename "$skill_dir")
    MOD=$(stat -c '%Y' "$skill_dir/SKILL.md" 2>/dev/null || stat -f '%m' "$skill_dir/SKILL.md" 2>/dev/null)
    MOD_DATE=$(date -d "@$MOD" +%Y-%m-%d 2>/dev/null || date -r "$MOD" +%Y-%m-%d 2>/dev/null)
    echo "  $NAME: $MOD_DATE"
  fi
done
echo ""

# --- 4. DEVELOPMENT_RULES.md Version ---
echo "## 4. Rules Document"
RULES_DATE=$(head -3 "$ROOT/docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
echo "DEVELOPMENT_RULES.md updated: $RULES_DATE"
echo ""

# --- 5. Scanner Script Inventory ---
echo "## 5. Scanner Scripts"
echo ""
find "$ROOT/.skills/skills/hexbound-"*/scripts -name "*.sh" 2>/dev/null | while read -r script; do
  echo "  $(echo "$script" | sed "s|$ROOT/||")"
done
echo ""

# --- 6. Potential New Patterns (heuristic) ---
echo "## 6. Potential New Patterns to Investigate"
echo ""

# New DarkFantasyTheme tokens added recently
NEW_TOKENS=$(git log --since="$SINCE" -p -- "$ROOT/Hexbound/Hexbound/Theme/DarkFantasyTheme.swift" 2>/dev/null | grep '^+.*static let' | grep -v '^\+\+\+' | wc -l | tr -d ' ')
echo "New DarkFantasyTheme tokens added: $NEW_TOKENS"

# New button styles added
NEW_STYLES=$(git log --since="$SINCE" -p -- "$ROOT/Hexbound/Hexbound/Theme/ButtonStyles.swift" 2>/dev/null | grep '^+.*struct\|^+.*case\|^+.*static' | grep -v '^\+\+\+' | wc -l | tr -d ' ')
echo "New ButtonStyles additions: $NEW_STYLES"

# Files deleted (cleanup work)
DELETED=$(git log --since="$SINCE" --diff-filter=D --name-only --pretty=format: 2>/dev/null | grep -v '^$' | wc -l | tr -d ' ')
echo "Files deleted (cleanup): $DELETED"

echo ""
echo "=== METRICS COMPLETE ==="
