#!/bin/bash
# Hexbound Deploy Script
# Commits all changes and pushes to all remotes (Vercel auto-deploys)
# Usage: bash .skills/skills/herald/scripts/deploy.sh <project-root> [--skip-build] [--skip-ios] [--dry-run]

set -euo pipefail

# ─── Args ───────────────────────────────────────────────────────────────
ROOT="${1:-.}"
SKIP_BUILD=false
SKIP_IOS=false
DRY_RUN=false

for arg in "${@:2}"; do
  case "$arg" in
    --skip-build) SKIP_BUILD=true ;;
    --skip-ios)   SKIP_IOS=true ;;
    --dry-run)    DRY_RUN=true ;;
  esac
done

cd "$ROOT"

# ─── Colors ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

pass() { echo -e "  ${GREEN}✅ $1${NC}"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}⛔ $1${NC}"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; WARN=$((WARN + 1)); }
info() { echo -e "  ${BLUE}ℹ️  $1${NC}"; }

echo ""
echo "═══════════════════════════════════════════════════"
echo "  HEXBOUND DEPLOY"
echo "═══════════════════════════════════════════════════"
echo ""

# ─── Phase 1: Pre-flight ────────────────────────────────────────────────
echo "📋 Phase 1: Pre-flight checks"
echo "─────────────────────────────"

# Check if there are changes to commit
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo ""
  echo -e "${YELLOW}Nothing to deploy — working tree is clean.${NC}"
  exit 0
fi

# Prisma schema sync
if ! diff -q backend/prisma/schema.prisma admin/prisma/schema.prisma >/dev/null 2>&1; then
  warn "Prisma schemas differ — syncing admin from backend..."
  cp backend/prisma/schema.prisma admin/prisma/schema.prisma
  git add admin/prisma/schema.prisma
  pass "Prisma schemas synced"
else
  pass "Prisma schemas in sync"
fi

# Junk files (excluding node_modules, .next, build artifacts)
JUNK=$(find backend admin Hexbound \
  -path "*/node_modules" -prune -o \
  -path "*/.next" -prune -o \
  -path "*/build" -prune -o \
  -path "*/.build" -prune -o \
  \( -name "* 2.*" -o -name "* 2" \) -print 2>/dev/null || true)
if [ -n "$JUNK" ]; then
  fail "Junk files found:"
  echo "$JUNK" | while read -r f; do echo "    → $f"; done
else
  pass "No junk files"
fi

# .env files in staging
STAGED_ENV=$(git diff --cached --name-only 2>/dev/null | grep '\.env' || true)
if [ -n "$STAGED_ENV" ]; then
  fail ".env files staged — unstage them!"
  echo "$STAGED_ENV" | while read -r f; do echo "    → $f"; done
else
  pass "No .env files staged"
fi

# ignoreBuildErrors check
if grep -r "ignoreBuildErrors" backend/next.config.* admin/next.config.* 2>/dev/null | grep -v "^#" | grep -q "true"; then
  fail "ignoreBuildErrors is enabled — remove it!"
else
  pass "No ignoreBuildErrors"
fi

echo ""

# Bail if blockers found
if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}⛔ DEPLOY BLOCKED — fix $FAIL issue(s) above${NC}"
  exit 1
fi

# ─── Phase 2: Build verification ────────────────────────────────────────
if [ "$SKIP_BUILD" = true ]; then
  echo "⏭️  Phase 2: Build verification (SKIPPED)"
  echo ""
else
  echo "🔨 Phase 2: Build verification"
  echo "─────────────────────────────"

  # Backend build
  echo "  Building backend..."
  if (cd backend && npm ci --silent 2>/dev/null && npx prisma generate --no-hints 2>/dev/null && npx next build 2>&1 | tail -5); then
    pass "Backend build"
  else
    fail "Backend build failed"
  fi

  # Admin build
  echo "  Building admin..."
  if (cd admin && npm ci --silent 2>/dev/null && npx prisma generate --no-hints 2>/dev/null && npx next build 2>&1 | tail -5); then
    pass "Admin build"
  else
    fail "Admin build failed"
  fi

  # iOS build
  if [ "$SKIP_IOS" = true ]; then
    info "iOS build skipped (--skip-ios)"
  elif ! command -v xcodebuild &>/dev/null; then
    warn "xcodebuild not available — iOS build skipped"
  else
    echo "  Building iOS..."
    if (cd Hexbound && xcodebuild -scheme IronFistArena -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5); then
      pass "iOS build"
    else
      fail "iOS build failed"
    fi
  fi

  echo ""

  if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}⛔ DEPLOY BLOCKED — build failures detected${NC}"
    exit 1
  fi
fi

# ─── Phase 3: Commit ────────────────────────────────────────────────────
echo "📝 Phase 3: Commit"
echo "─────────────────"

# Stage all product files
git add backend/ admin/ Hexbound/ docs/ User/ 2>/dev/null || true
git add hexbound-site/ 2>/dev/null || true
git add CLAUDE.md .github/ .skills/ 2>/dev/null || true

# Remove .DS_Store if accidentally staged
git reset HEAD -- '*.DS_Store' 2>/dev/null || true
git reset HEAD -- '*/.DS_Store' 2>/dev/null || true

# Show what's being committed
CHANGED=$(git diff --cached --stat | tail -1)
info "Changes: $CHANGED"

if git diff --cached --quiet; then
  echo -e "${YELLOW}Nothing staged to commit.${NC}"
  exit 0
fi

# Generate commit message from diff
DIFF_SUMMARY=$(git diff --cached --stat | head -20)
FILES_CHANGED=$(git diff --cached --name-only)

# Detect scope
HAS_BACKEND=$(echo "$FILES_CHANGED" | grep -c "^backend/" || true)
HAS_ADMIN=$(echo "$FILES_CHANGED" | grep -c "^admin/" || true)
HAS_IOS=$(echo "$FILES_CHANGED" | grep -c "^Hexbound/" || true)
HAS_SITE=$(echo "$FILES_CHANGED" | grep -c "^hexbound-site/" || true)
HAS_DOCS=$(echo "$FILES_CHANGED" | grep -c "^docs/" || true)

# Build commit message
SCOPES=()
[ "$HAS_BACKEND" -gt 0 ] && SCOPES+=("backend")
[ "$HAS_ADMIN" -gt 0 ] && SCOPES+=("admin")
[ "$HAS_IOS" -gt 0 ] && SCOPES+=("ios")
[ "$HAS_SITE" -gt 0 ] && SCOPES+=("site")
[ "$HAS_DOCS" -gt 0 ] && SCOPES+=("docs")

SCOPE_STR=$(IFS=','; echo "${SCOPES[*]}")
FILE_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
COMMIT_MSG="chore(${SCOPE_STR}): deploy — ${FILE_COUNT} files changed"

info "Commit message: $COMMIT_MSG"

if [ "$DRY_RUN" = true ]; then
  echo ""
  echo -e "${YELLOW}🏃 DRY RUN — skipping commit and push${NC}"
  echo "Would commit: $COMMIT_MSG"
  echo "Would push to: origin, admin-deploy (subtree)"
  exit 0
fi

git commit -m "$COMMIT_MSG"
COMMIT_HASH=$(git rev-parse --short HEAD)
pass "Committed: $COMMIT_HASH"

echo ""

# ─── Phase 4: Deploy ────────────────────────────────────────────────────
echo "🚀 Phase 4: Deploy (push to remotes)"
echo "─────────────────────────────────────"

# Push to origin (backend + site)
echo "  Pushing to origin (backend + site)..."
if git push origin main 2>&1; then
  pass "Pushed to origin/main"
else
  fail "Push to origin failed"
fi

# Admin subtree push
if [ "$HAS_ADMIN" -gt 0 ] || [ "$DRY_RUN" = false ]; then
  echo "  Pushing admin subtree..."
  if git subtree push --prefix=admin admin-deploy main 2>&1; then
    pass "Admin subtree pushed"
  else
    warn "Subtree push failed — trying force push..."
    SPLIT_SHA=$(git subtree split --prefix=admin)
    if git push admin-deploy "$SPLIT_SHA":main --force 2>&1; then
      pass "Admin subtree force-pushed"
    else
      fail "Admin subtree push failed completely"
    fi
  fi
fi

echo ""

# ─── Phase 5: Report ────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════"
if [ "$FAIL" -gt 0 ]; then
  echo -e "  ${RED}⚠️  PARTIAL DEPLOY — $FAIL failure(s)${NC}"
else
  echo -e "  ${GREEN}🚀 DEPLOYED SUCCESSFULLY${NC}"
fi
echo ""
echo "  Commit: $COMMIT_HASH — $COMMIT_MSG"
echo "  Passed: $PASS | Warnings: $WARN | Failures: $FAIL"
echo ""
echo "  Next: monitor Vercel dashboards for build status"
echo "═══════════════════════════════════════════════════"

exit $FAIL
