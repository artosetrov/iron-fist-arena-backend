#!/bin/bash
# Hexbound build verification — static checks + optional npm build.
# Can run offline (static-only mode) or with network (full build).
# Usage: ./verify_build.sh [project_root] [--static-only]

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
STATIC_ONLY="${2:-}"
cd "$ROOT" || exit 1

echo "=== HEXBOUND BUILD VERIFICATION ==="
echo ""

PASS=0
FAIL=0
WARN=0

report() {
  local status="$1" section="$2" detail="$3"
  case "$status" in
    PASS) echo "✅ $section"; PASS=$((PASS+1)) ;;
    FAIL) echo "❌ $section: $detail"; FAIL=$((FAIL+1)) ;;
    WARN) echo "⚠️  $section: $detail"; WARN=$((WARN+1)) ;;
  esac
}

# --- 1. Schema sync ---
echo "## Schema Consistency"
if [ -f "backend/prisma/schema.prisma" ] && [ -f "admin/prisma/schema.prisma" ]; then
  if diff -q "backend/prisma/schema.prisma" "admin/prisma/schema.prisma" > /dev/null 2>&1; then
    report PASS "Prisma schemas identical"
  else
    DIFF_LINES=$(diff "backend/prisma/schema.prisma" "admin/prisma/schema.prisma" | head -20)
    report FAIL "Prisma schemas DIFFER" "$DIFF_LINES"
  fi
else
  report WARN "Schema files" "One or both schema files not found"
fi
echo ""

# --- 2. pbxproj completeness ---
echo "## Xcode Project Completeness"
PBXPROJ="Hexbound/Hexbound.xcodeproj/project.pbxproj"
MISSING=0
MISSING_FILES=""
if [ -f "$PBXPROJ" ]; then
  while IFS= read -r f; do
    basename=$(basename "$f")
    if ! grep -q "$basename" "$PBXPROJ" 2>/dev/null; then
      MISSING=$((MISSING+1))
      MISSING_FILES="$MISSING_FILES $basename"
    fi
  done < <(find Hexbound/Hexbound -name "*.swift" -type f 2>/dev/null)

  if [ "$MISSING" -eq 0 ]; then
    report PASS "All Swift files in pbxproj"
  else
    report FAIL "Swift files missing from pbxproj ($MISSING)" "$MISSING_FILES"
  fi
else
  report WARN "pbxproj" "File not found"
fi
echo ""

# --- 3. Design system violations (project-wide scan) ---
echo "## Design System Violations"
HC_COUNT=$(grep -rn --include="*.swift" 'Color(' Hexbound/Hexbound/Views/ 2>/dev/null | grep -v 'DarkFantasyTheme' | grep -v '^\s*//' | grep -v 'Color("' | grep -v '#Preview' | wc -l)
SF_COUNT=$(grep -rn --include="*.swift" -oP '\.system\(size:\s*\K[0-9]+' Hexbound/Hexbound/Views/ 2>/dev/null | awk '$1 < 16' | wc -l)
EM_COUNT=$(grep -rcP --include="*.swift" '[\x{2694}\x{1F6E1}\x{1F3AF}\x{1F9BF}\x{1F381}\x{2753}\x{1F3B2}]' Hexbound/Hexbound/Views/ 2>/dev/null | awk -F: '$2 > 0' | wc -l)

[ "$HC_COUNT" -eq 0 ] && report PASS "No hardcoded colors" || report FAIL "Hardcoded colors" "$HC_COUNT instances"
[ "$SF_COUNT" -eq 0 ] && report PASS "No small fonts (<16px)" || report FAIL "Small fonts" "$SF_COUNT instances below 16px"
[ "$EM_COUNT" -eq 0 ] && report PASS "No emoji in views" || report WARN "Emoji in views" "$EM_COUNT files with emoji"
echo ""

# --- 4. Junk files ---
echo "## File Hygiene"
JUNK_COUNT=$(find backend admin Hexbound -not -path '*/node_modules/*' -not -path '*/.next/*' \( -name "* 2.*" -o -name "* 2" \) 2>/dev/null | wc -l)
[ "$JUNK_COUNT" -eq 0 ] && report PASS "No junk/duplicate files" || report FAIL "Junk files" "$JUNK_COUNT files with spaces/' 2' in name"

# ignoreBuildErrors
IBE=$(grep -rl 'ignoreBuildErrors' backend/next.config.* admin/next.config.* 2>/dev/null | wc -l)
[ "$IBE" -eq 0 ] && report PASS "No ignoreBuildErrors flag" || report FAIL "ignoreBuildErrors found" "Remove from next.config"

# .env staged
ENV=$(git diff --cached --name-only 2>/dev/null | grep '\.env' | wc -l)
[ "$ENV" -eq 0 ] && report PASS "No .env files staged" || report FAIL ".env staged" "Remove .env from staging"
echo ""

# --- 5. Optional: actual builds ---
if [ "$STATIC_ONLY" != "--static-only" ]; then
  echo "## Backend Build"
  if [ -d "backend" ] && [ -f "backend/package.json" ]; then
    cd backend
    PRISMA_OUT=$(npx prisma generate 2>&1)
    if [ $? -eq 0 ]; then
      report PASS "Prisma generate (backend)"
      BUILD_OUT=$(npx next build 2>&1)
      if [ $? -eq 0 ]; then
        report PASS "Backend build"
      else
        ERRORS=$(echo "$BUILD_OUT" | grep -c 'Error:' || echo "?")
        report FAIL "Backend build" "$ERRORS error(s) — see details above"
      fi
    else
      report FAIL "Prisma generate (backend)" "Schema error or network issue"
      report WARN "Backend build" "Skipped (prisma generate failed)"
    fi
    cd "$ROOT"
  fi
  echo ""

  echo "## Admin Build"
  if [ -d "admin" ] && [ -f "admin/package.json" ]; then
    cd admin
    PRISMA_OUT=$(npx prisma generate 2>&1)
    if [ $? -eq 0 ]; then
      report PASS "Prisma generate (admin)"
      BUILD_OUT=$(npx next build 2>&1)
      if [ $? -eq 0 ]; then
        report PASS "Admin build"
      else
        ERRORS=$(echo "$BUILD_OUT" | grep -c 'Error:' || echo "?")
        report FAIL "Admin build" "$ERRORS error(s)"
      fi
    else
      report FAIL "Prisma generate (admin)" "Schema error or network issue"
      report WARN "Admin build" "Skipped (prisma generate failed)"
    fi
    cd "$ROOT"
  fi
  echo ""
else
  echo "## Builds: Skipped (--static-only mode)"
  echo ""
fi

# --- VERDICT ---
echo "==============================="
echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "⛔ VERDICT: BUILD BROKEN — $FAIL issue(s) must be fixed"
elif [ "$WARN" -gt 0 ]; then
  echo "⚠️  VERDICT: WARNINGS — $WARN item(s) need attention"
else
  echo "✅ VERDICT: ALL CLEAR"
fi
echo "==============================="
