#!/usr/bin/env bash
# =============================================================================
# git-commit-push.sh — Auto commit & push from Claude VM via mounted filesystem
# Usage: ./scripts/git-commit-push.sh "commit message"
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
cd "$REPO_DIR"

clear_stale_lock() {
  local lock_file="$1"
  if [ ! -e "$lock_file" ]; then
    return 0
  fi

  if command -v lsof >/dev/null 2>&1 && lsof "$lock_file" >/dev/null 2>&1; then
    echo "❌ Git lock is active: $lock_file" >&2
    exit 1
  fi

  echo "⚠️  Clearing stale Git lock: $lock_file"
  rm -f "$lock_file"
}

clear_stale_lock .git/index.lock
clear_stale_lock .git/HEAD.lock

# Commit message from argument or default
MSG="${1:-auto: changes from Claude session}"
CURRENT_BRANCH="$(git branch --show-current)"

if [ -z "$CURRENT_BRANCH" ]; then
  echo "❌ Detached HEAD; refusing to auto-push." >&2
  exit 1
fi

# Stage all changes
git add -A

# Check if there's anything to commit
if git diff --cached --quiet; then
  echo "Nothing to commit."
  exit 0
fi

# Commit
git commit -m "$MSG"

# Push current branch
git push origin "$CURRENT_BRANCH"

# Push admin subtree if admin/ was changed
if git diff-tree --no-commit-id --name-only -r HEAD | grep -q "^admin/"; then
  echo "Admin changed — pushing subtree..."
  if git remote get-url admin-deploy >/dev/null 2>&1; then
    git subtree push --prefix=admin admin-deploy main
  else
    echo "Admin remote 'admin-deploy' not configured — skipping subtree push."
  fi
else
  echo "Admin not changed — skipping subtree push."
fi

echo "Done!"
