#!/bin/bash
# Hexbound pre-commit/pre-push preflight checker.
# Runs only checks relevant to actually changed files.
# Usage: ./preflight_check.sh [project_root]

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo '.')}"
cd "$ROOT" || exit 1

echo "=== HEXBOUND PREFLIGHT ==="
echo ""

# Get changed files (staged + unstaged)
CHANGED=$(git diff --name-only HEAD 2>/dev/null; git diff --cached --name-only 2>/dev/null)
CHANGED=$(echo "$CHANGED" | sort -u)

if [ -z "$CHANGED" ]; then
  echo "No changes detected."
  exit 0
fi

echo "## Changed Files"
echo "$CHANGED" | while IFS= read -r f; do echo "  - $f"; done
echo ""

VERDICT="READY"
WARNINGS=""
BLOCKERS=""

# --- 1. pbxproj check (if new Swift files) ---
NEW_SWIFT=$(echo "$CHANGED" | grep 'Hexbound/.*\.swift$' || true)
if [ -n "$NEW_SWIFT" ]; then
  echo "## Xcode Project File Check"
  PBXPROJ="Hexbound/Hexbound.xcodeproj/project.pbxproj"
  if [ -f "$PBXPROJ" ]; then
    while IFS= read -r f; do
      basename=$(basename "$f")
      count=$(grep -c "$basename" "$PBXPROJ" 2>/dev/null || echo 0)
      if [ "$count" -lt 3 ]; then
        echo "  ❌ MISSING: $basename (found $count refs, need 4+)"
        BLOCKERS="$BLOCKERS\n  - $basename not in pbxproj"
        VERDICT="BLOCKED"
      else
        echo "  ✅ $basename ($count refs)"
      fi
    done <<< "$NEW_SWIFT"
  else
    echo "  ⚠️  pbxproj not found at $PBXPROJ"
  fi
  echo ""
fi

# --- 2. Prisma schema sync (if schema changed) ---
SCHEMA_CHANGED=$(echo "$CHANGED" | grep 'prisma/schema.prisma' || true)
if [ -n "$SCHEMA_CHANGED" ]; then
  echo "## Prisma Schema Sync"
  if [ -f "backend/prisma/schema.prisma" ] && [ -f "admin/prisma/schema.prisma" ]; then
    if diff -q "backend/prisma/schema.prisma" "admin/prisma/schema.prisma" > /dev/null 2>&1; then
      echo "  ✅ Schemas identical"
    else
      echo "  ❌ Schemas DIFFER — run: cp backend/prisma/schema.prisma admin/prisma/schema.prisma"
      BLOCKERS="$BLOCKERS\n  - Prisma schemas out of sync"
      VERDICT="BLOCKED"
    fi
  fi

  # Check for migration
  MIGRATION_CHANGED=$(echo "$CHANGED" | grep 'prisma/migrations/' || true)
  if [ -z "$MIGRATION_CHANGED" ]; then
    echo "  ⚠️  Schema changed but no migration found — did you run db:migrate:dev?"
    WARNINGS="$WARNINGS\n  - No migration for schema change"
  fi
  echo ""
fi

# --- 3. Admin subtree reminder (if admin/ changed) ---
ADMIN_CHANGED=$(echo "$CHANGED" | grep '^admin/' || true)
if [ -n "$ADMIN_CHANGED" ]; then
  echo "## Admin Deploy Reminder"
  echo "  ⚠️  admin/ files changed — after push, run:"
  echo "     git subtree push --prefix=admin admin-deploy main"
  WARNINGS="$WARNINGS\n  - Admin subtree push needed"
  echo ""
fi

# --- 4. Design system quick check (on changed Swift view files only) ---
VIEW_FILES=$(echo "$CHANGED" | grep 'Hexbound/.*Views/.*\.swift$' || true)
if [ -n "$VIEW_FILES" ]; then
  echo "## Design System Quick Check (changed views only)"
  ISSUES=0

  while IFS= read -r f; do
    [ ! -f "$f" ] && continue

    # Hardcoded colors (excluding comments and DarkFantasyTheme)
    hc=$(grep -n 'Color(' "$f" 2>/dev/null | grep -v 'DarkFantasyTheme' | grep -v '^\s*//' | grep -v 'Color("' | wc -l)
    if [ "$hc" -gt 0 ]; then
      echo "  ❌ $f: $hc hardcoded color(s)"
      ISSUES=$((ISSUES + hc))
    fi

    # Small fonts
    sf=$(grep -oP '\.system\(size:\s*\K[0-9]+' "$f" 2>/dev/null | awk '$1 < 16' | wc -l)
    if [ "$sf" -gt 0 ]; then
      echo "  ❌ $f: $sf font(s) < 16px"
      ISSUES=$((ISSUES + sf))
    fi

    # Emoji
    em=$(grep -cP '[\x{2694}\x{1F6E1}\x{1F3AF}\x{1F9BF}\x{1F381}\x{2753}]' "$f" 2>/dev/null || echo 0)
    if [ "$em" -gt 0 ]; then
      echo "  ⚠️  $f: $em emoji usage(s)"
      WARNINGS="$WARNINGS\n  - Emoji in $f"
    fi

  done <<< "$VIEW_FILES"

  if [ "$ISSUES" -gt 0 ]; then
    BLOCKERS="$BLOCKERS\n  - $ISSUES design system violations in views"
    VERDICT="BLOCKED"
  fi
  echo ""
fi

# --- 5. Junk files ---
JUNK=$(find backend admin Hexbound -not -path '*/node_modules/*' -not -path '*/.next/*' \( -name "* 2.*" -o -name "* 2" \) 2>/dev/null | head -10)
if [ -n "$JUNK" ]; then
  echo "## Junk Files Detected"
  echo "$JUNK" | while IFS= read -r f; do echo "  ❌ $f"; done
  BLOCKERS="$BLOCKERS\n  - Junk files found"
  VERDICT="BLOCKED"
  echo ""
fi

# --- 6. .env check ---
ENV_STAGED=$(git diff --cached --name-only 2>/dev/null | grep '\.env' || true)
if [ -n "$ENV_STAGED" ]; then
  echo "## ⛔ .env File Staged!"
  echo "$ENV_STAGED" | while IFS= read -r f; do echo "  ❌ $f — REMOVE FROM STAGING"; done
  BLOCKERS="$BLOCKERS\n  - .env file staged"
  VERDICT="BLOCKED"
  echo ""
fi

# --- 7. Backend TS quick check (on changed .ts files only) ---
TS_FILES=$(echo "$CHANGED" | grep -E '\.(ts|tsx)$' || true)
if [ -n "$TS_FILES" ]; then
  echo "## TypeScript Quick Check"
  while IFS= read -r f; do
    [ ! -f "$f" ] && continue

    # Missing await on common async patterns
    noawait=$(grep -n 'get.*Config()' "$f" 2>/dev/null | grep -v 'await' | grep -v '^\s*//' | wc -l)
    if [ "$noawait" -gt 0 ]; then
      echo "  ❌ $f: $noawait get*Config() call(s) without await"
      BLOCKERS="$BLOCKERS\n  - Missing await in $f"
      VERDICT="BLOCKED"
    fi

  done <<< "$TS_FILES"
  echo ""
fi

# --- VERDICT ---
echo "==============================="
if [ "$VERDICT" = "BLOCKED" ]; then
  echo "⛔ VERDICT: NEEDS FIXES"
  echo ""
  echo "Blockers:"
  echo -e "$BLOCKERS"
else
  echo "✅ VERDICT: READY TO COMMIT"
fi

if [ -n "$WARNINGS" ]; then
  echo ""
  echo "Warnings:"
  echo -e "$WARNINGS"
fi
echo "==============================="
