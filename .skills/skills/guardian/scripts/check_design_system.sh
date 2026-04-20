#!/bin/bash
# Smart design system violation scanner for Hexbound SwiftUI files.
# Filters out comments, string literals, and known false positives.
# Usage: ./check_design_system.sh [file_or_dir] [project_root]

TARGET="${1:-.}"
ROOT="${2:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
THEME="$ROOT/Hexbound/Hexbound/Theme/DarkFantasyTheme.swift"

swift_files() {
  if [ -f "$TARGET" ]; then
    printf '%s\n' "$TARGET"
  else
    find "$TARGET" -type f -name "*.swift" 2>/dev/null
  fi
}

# Collect real token names from DarkFantasyTheme.swift
if [ -f "$THEME" ]; then
  VALID_TOKENS=$(sed -nE 's/.*static[[:space:]]+(let|var)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\2/p' "$THEME" | sort -u | tr '\n' '|')
fi

# Collect Color/ShapeStyle extension shorthand tokens (bare .tokenName is safe for these)
# These are defined in `extension Color { static var xxx }` and `extension ShapeStyle where Self == Color`
EXTENSION_TOKENS=""
if [ -f "$THEME" ]; then
  EXTENSION_TOKENS=$(grep -A20 'extension Color {' "$THEME" 2>/dev/null | sed -nE 's/.*static var ([A-Za-z_][A-Za-z0-9_]*).*/\1/p' | sort -u)
  EXTENSION_TOKENS="$EXTENSION_TOKENS
$(grep -A20 'extension ShapeStyle' "$THEME" 2>/dev/null | sed -nE 's/.*static var ([A-Za-z_][A-Za-z0-9_]*).*/\1/p' | sort -u)"
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
    token=$(echo "$line" | sed -nE 's/.*\(\.([A-Za-z_][A-Za-z0-9_]*).*/\1/p' | head -1)
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
    size=$(echo "$line" | sed -nE 's/.*size:[[:space:]]*([0-9]+).*/\1/p')
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
swift_files | while IFS= read -r f; do
  perl -CS -ne 'print "$ARGV:$.:$_" if /[\x{2694}\x{1F6E1}\x{1F3AF}\x{1F9BF}\x{1F381}\x{2753}\x{1F3B2}\x{2699}\x{26A1}\x{1F525}\x{2B50}\x{1F4A5}\x{1F9EA}\x{1F48E}]/' "$f" 2>/dev/null
done | \
  grep -v '^\s*//' | \
  grep -v '#Preview' | \
  grep -v '// emoji' | \
  while IFS= read -r line; do
    echo "❌ $line"
  done

echo ""

# --- 3b. Player-facing SF Symbols with asset equivalents (2026-04-19) ---
# Incident: commits a450bfc + c4ee12f swept 15 Image(systemName:) → Image("asset")
# calls across 13 player-facing files. SF Symbols leak iOS system-UI vibe into
# dark-fantasy screens. This scan flags the mappings we have confirmed assets for.
echo "## Player-facing SF Symbols with confirmed asset replacements"
echo ""
# Pattern: Image(systemName: "X") where X has a known dark-fantasy asset swap
# Skip dev views (ScreenCatalog, DevPanel, DesignSystemPreview, *Editor).
grep -rn --include="*.swift" -E 'Image\(systemName:\s*"(lock\.fill|gift\.fill|envelope\.fill|envelope\.badge\.fill|bubble\.left\.fill|scroll\.fill|dice\.fill|trophy\.fill)"' "$TARGET" 2>/dev/null | \
  grep -v 'ScreenCatalog' | \
  grep -v 'DevPanel' | \
  grep -v 'DesignSystemPreview' | \
  grep -vE '/[A-Za-z]*Editor' | \
  grep -v '//' | \
  while IFS= read -r line; do
    echo "❌ SF Symbol with asset swap available: $line"
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

# --- 7. Guard-before-await in ViewModel async methods ---
# Incident: QA audit 2026-04-12 — BUG-C01/C02/C03. Double-tap exploits caused by
# setting guard flag AFTER the first await, allowing two concurrent calls.
echo "## Guard Before Await (Double-Tap Prevention)"
echo ""
find "$TARGET" -type f -name "*ViewModel.swift" 2>/dev/null | while read -r f; do
  # Find async func declarations and check if the first non-blank line after them
  # contains a guard or flag assignment before any await
  grep -n 'func .* async' "$f" 2>/dev/null | while IFS=: read -r lineno rest; do
    # Skip if line is a comment
    echo "$rest" | grep -q '^\s*//' && continue
    # Get the function name
    func_name=$(echo "$rest" | sed -nE 's/.*func[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/p')
    # Check next 30 lines for pattern: has await but no guard/flag before it
    end_line=$((lineno + 30))
    block=$(sed -n "${lineno},${end_line}p" "$f" 2>/dev/null)
    has_await=$(echo "$block" | grep -c 'await ')
    if [ "$has_await" -gt 0 ]; then
      # Find line of first await (relative)
      first_await_rel=$(echo "$block" | grep -n 'await ' | head -1 | cut -d: -f1)
      # Check if there's a guard or bool assignment before it
      before_await=$(echo "$block" | head -n "$((first_await_rel - 1))")
      has_guard=$(echo "$before_await" | grep -cE 'guard\s+!is|= true$|= true\s')
      if [ "$has_guard" -eq 0 ]; then
        abs_line=$((lineno))
        echo "⚠️  [no guard before await] $f:$abs_line — func $func_name() has await but no guard/flag set before it"
      fi
    fi
  done
done

echo ""
echo "## 8. snake_case CodingKeys in DTOs (double-conversion bug)"
# APIClient applies convertFromSnakeCase — CodingKey mapping to "snake_case" will fail at runtime
snake_ck=$(grep -rn 'case [a-zA-Z]* = "[a-z]*_[a-z_]*"' Hexbound/Hexbound/Models/ --include="*.swift" 2>/dev/null)
if [ -n "$snake_ck" ]; then
  echo "⚠️  snake_case CodingKeys found (APIClient already does convertFromSnakeCase — remove them):"
  echo "$snake_ck"
else
  echo "✅ No snake_case CodingKeys in Models/"
fi

echo ""
echo "## 9. Nested 'enum State' shadows SwiftUI.State"
# Incident: 2026-04-14 commit 6244d17 — TalentNodeView had `enum State: Equatable` inside a View body,
# which shadowed the SwiftUI @State property wrapper type and broke the build. Rename to NodeState /
# ViewState / <Feature>State. See also feedback_check_all_callers.md.
state_shadow=$(grep -rn -E '^\s*(private\s+|fileprivate\s+)?enum State\s*(:|\{)' Hexbound/Hexbound/Views/ --include="*.swift" 2>/dev/null | grep -v '^\s*//')
if [ -n "$state_shadow" ]; then
  echo "⚠️  'enum State' inside Views/ shadows SwiftUI.State — rename (e.g. NodeState, ViewState):"
  echo "$state_shadow"
else
  echo "✅ No 'enum State' shadows in Views/"
fi

echo ""
echo "## 10. Monolithic Swift View files (>1000 lines)"
# Incident: 2026-04-14 — split day. BattleResultCardView (1291), GoldMineDetailView (1170),
# HeroDetailView (1358), DungeonRushDetailView (1464), ItemDetailSheet (1221), HubView (2034),
# GuildHallDetailView (1931) all refactored to extension files. Soft-warn when any Swift file
# in Hexbound/Hexbound crosses 1000 lines — time to split sections into extensions.
if [ -d "Hexbound/Hexbound" ]; then
  monoliths=$(find Hexbound/Hexbound -type f -name "*.swift" -exec wc -l {} + 2>/dev/null | awk '$1 > 1000 && $2 != "total" { print $1 " " $2 }' | sort -rn)
  if [ -n "$monoliths" ]; then
    echo "⚠️  Files >1000 lines — consider splitting into extension files or focused modules:"
    echo "$monoliths" | head -10 | while IFS= read -r line; do echo "   $line"; done
  else
    echo "✅ No Swift files >1000 lines in Hexbound/Hexbound"
  fi
fi

echo ""
echo "=== SCAN COMPLETE ==="
