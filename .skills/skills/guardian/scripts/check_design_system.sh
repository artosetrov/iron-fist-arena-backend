#!/bin/bash
# Smart design system violation scanner for Hexbound SwiftUI files.
# Filters out comments, string literals, and known false positives.
# Usage: ./check_design_system.sh [file_or_dir] [project_root]

TARGET="${1:-.}"
ROOT="${2:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
THEME="$ROOT/Hexbound/Hexbound/Theme/DarkFantasyTheme.swift"

# Collect real token names from DarkFantasyTheme.swift
if [ -f "$THEME" ]; then
  VALID_TOKENS=$(grep -oP 'static\s+(let|var)\s+\K\w+' "$THEME" | sort -u | tr '\n' '|')
fi

# Collect Color/ShapeStyle extension shorthand tokens (bare .tokenName is safe for these)
# These are defined in `extension Color { static var xxx }` and `extension ShapeStyle where Self == Color`
EXTENSION_TOKENS=""
if [ -f "$THEME" ]; then
  EXTENSION_TOKENS=$(grep -A1 'extension Color {' "$THEME" 2>/dev/null | grep -oP 'static var \K\w+' | sort -u)
  EXTENSION_TOKENS="$EXTENSION_TOKENS
$(grep -A20 'extension ShapeStyle' "$THEME" 2>/dev/null | grep -oP 'static var \K\w+' | sort -u)"
  EXTENSION_TOKENS=$(echo "$EXTENSION_TOKENS" | sort -u | grep -v '^$')
  # Build grep exclusion pattern: bgAbyss|bgPrimary|textPrimary|...
  EXTENSION_EXCLUDE=$(echo "$EXTENSION_TOKENS" | tr '\n' '|' | sed 's/|$//')
fi

echo "=== DESIGN SYSTEM SCAN ==="
echo ""

# --- 1. Hardcoded colors ---
echo "## Hardcoded Colors"
echo ""
grep -rn --include="*.swift" 'Color(' "$TARGET" 2>/dev/null | \
  grep -v 'DarkFantasyTheme' | \
  grep -v '^\s*//' | \
  grep -v '// *MARK' | \
  grep -v 'Color("' | \
  grep -v '\.colorScheme' | \
  grep -v 'ColorPicker' | \
  grep -v 'withAnimation' | \
  grep -v '#Preview' | \
  grep -v '_Preview' | \
  grep -v 'Tests/' | \
  while IFS= read -r line; do
    echo "❌ $line"
  done

# Also catch .foregroundColor/.foregroundStyle with system colors
grep -rn --include="*.swift" -E '\.(foregroundColor|foregroundStyle|background|tint)\(\.(white|black|red|blue|green|gray|orange|yellow|pink|purple|cyan|mint|indigo|brown|clear)' "$TARGET" 2>/dev/null | \
  grep -v '^\s*//' | \
  grep -v '#Preview' | \
  while IFS= read -r line; do
    echo "❌ $line"
  done

echo ""

# --- 1b. Bare DarkFantasyTheme tokens (without DarkFantasyTheme. prefix) ---
echo "## Bare Theme Tokens (without DarkFantasyTheme. prefix)"
echo ""
# Find .foregroundStyle(.xxx), .shadow(color: .xxx), .background(.xxx) where xxx looks like a theme token
# but is NOT a system color and NOT in the Color/ShapeStyle extension
BARE_UNSAFE=0
BARE_SAFE=0
grep -rn --include="*.swift" -E '\.(foregroundColor|foregroundStyle|background|tint|shadow\(color:)\s*\(\.' "$TARGET" 2>/dev/null | \
  grep -v 'DarkFantasyTheme' | \
  grep -v '^\s*//' | \
  grep -v '#Preview' | \
  grep -v '\.\(white\|black\|red\|blue\|green\|gray\|orange\|yellow\|pink\|purple\|cyan\|mint\|indigo\|brown\|clear\|primary\|secondary\)' | \
  while IFS= read -r line; do
    # Extract the token name after (. pattern, e.g. .foregroundStyle(.textPrimary) → textPrimary
    token=$(echo "$line" | grep -oP '\(\.\K\w+' | head -1)
    if [ -n "$EXTENSION_EXCLUDE" ] && echo "$token" | grep -qwE "$EXTENSION_EXCLUDE"; then
      # Covered by Color/ShapeStyle extension — safe but noted
      echo "ℹ️  [extension-covered] $line"
    else
      echo "❌ [UNSAFE bare token] $line"
    fi
  done

echo ""

# --- 1c. Deprecated .foregroundColor() usage ---
echo "## Deprecated .foregroundColor() (use .foregroundStyle() instead)"
echo ""
grep -rn --include="*.swift" '\.foregroundColor(' "$TARGET" 2>/dev/null | \
  grep -v '^\s*//' | \
  grep -v '#Preview' | \
  grep -v 'Tests/' | \
  while IFS= read -r line; do
    echo "⚠️  [deprecated API] $line"
  done

echo ""

# --- 2. Small fonts (< 16px) ---
echo "## Fonts Below 16px"
echo ""
grep -rn --include="*.swift" -E '\.system\(size:\s*[0-9]+' "$TARGET" 2>/dev/null | \
  grep -v '^\s*//' | \
  grep -v '#Preview' | \
  grep -v 'Tests/' | \
  while IFS= read -r line; do
    size=$(echo "$line" | grep -oP 'size:\s*\K[0-9]+')
    if [ -n "$size" ] && [ "$size" -lt 16 ]; then
      echo "❌ [${size}px] $line"
    fi
  done

# Also catch .font(.caption) .font(.caption2) .font(.footnote) which are < 16px
grep -rn --include="*.swift" -E '\.font\(\.(caption2?|footnote)\)' "$TARGET" 2>/dev/null | \
  grep -v '^\s*//' | \
  grep -v '#Preview' | \
  while IFS= read -r line; do
    echo "❌ [system small font] $line"
  done

echo ""

# --- 3. Emoji in views (combat zone icons, card decorations) ---
echo "## Emoji in Views"
echo ""
grep -rn --include="*.swift" -P '[\x{2694}\x{1F6E1}\x{1F3AF}\x{1F9BF}\x{1F381}\x{2753}\x{1F3B2}\x{2699}\x{26A1}\x{1F525}\x{2B50}\x{1F4A5}\x{1F9EA}\x{1F48E}]' "$TARGET" 2>/dev/null | \
  grep -v '^\s*//' | \
  grep -v '#Preview' | \
  grep -v '// emoji' | \
  while IFS= read -r line; do
    echo "❌ $line"
  done

echo ""

# --- 4. Inline button styling (not using ButtonStyles.swift) ---
echo "## Suspicious Inline Button Styling"
echo ""
grep -rn --include="*.swift" -E 'Button\s*\{' "$TARGET" 2>/dev/null | \
  while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    lineno=$(echo "$line" | cut -d: -f2)
    # Validate lineno is a number before arithmetic
    if ! [[ "$lineno" =~ ^[0-9]+$ ]]; then
      continue
    fi
    # Check next 8 lines for .buttonStyle — if missing, flag it
    end_line=$((lineno + 8))
    has_style=$(sed -n "${lineno},${end_line}p" "$file" 2>/dev/null | grep -c 'buttonStyle\|\.plain\|\.borderless')
    if [ "$has_style" -eq 0 ]; then
      echo "⚠️  No .buttonStyle: $line"
    fi
  done

echo ""

# --- 5. Hardcoded spacing ---
echo "## Hardcoded Spacing (common values)"
echo ""
grep -rn --include="*.swift" -E '\.padding\(\s*[0-9]+\s*\)' "$TARGET" 2>/dev/null | \
  grep -v '^\s*//' | \
  grep -v '#Preview' | \
  grep -v 'LayoutConstants' | \
  head -20 | \
  while IFS= read -r line; do
    echo "⚠️  $line"
  done

echo ""

# --- 6. @Observable ViewModels with stored DI properties must have explicit init ---
# Incident: commit 712c696 (2026-04-11) — GoldMineViewModel init(appState:cache:)
# was wiped when a `mineNames` block was pasted at the top of the class. Swift
# compiler catches this ("Class has no initializers"), but only at build time —
# cheaper to catch in pre-commit grep. See memory `feedback_observable_init_preservation.md`.
echo "## @Observable ViewModels — missing init(appState:cache:)"
echo ""
find "$TARGET" -type f -name "*ViewModel.swift" 2>/dev/null | while read -r f; do
  # Only check @Observable classes that store appState or cache as let properties
  if grep -q '@Observable' "$f" 2>/dev/null; then
    has_stored_di=$(grep -cE '^\s*(private\s+)?let\s+(appState|cache)\s*:\s*(AppState|GameDataCache)' "$f")
    if [ "$has_stored_di" -gt 0 ]; then
      has_init=$(grep -cE '^\s*(public\s+|internal\s+)?init\s*\(' "$f")
      if [ "$has_init" -eq 0 ]; then
        echo "❌ [missing init] $f — has let appState/cache but no init(...). Build will fail with 'Class has no initializers'."
      fi
    fi
  fi
done

echo ""
echo "=== SCAN COMPLETE ==="
