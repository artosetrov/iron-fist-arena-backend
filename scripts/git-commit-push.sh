#!/bin/bash
# =============================================================================
# git-commit-push.sh — Auto commit & push from Claude VM via mounted filesystem
# Usage: ./scripts/git-commit-push.sh "commit message"
# =============================================================================

set -e

REPO_DIR="/Users/artosetrov/Documents/Cursor AI/PVP RPG"
cd "$REPO_DIR"

# Remove stale lock files
rm -f .git/index.lock .git/HEAD.lock

# Commit message from argument or default
MSG="${1:-auto: changes from Claude session}"

# Stage all changes
git add -A

# Check if there's anything to commit
if git diff --cached --quiet; then
  echo "Nothing to commit."
  exit 0
fi

# Commit
git commit -m "$MSG"

# Push backend (origin)
git push origin main

# Push admin subtree if admin/ was changed
if git diff HEAD~1 --name-only | grep -q "^admin/"; then
  echo "Admin changed — pushing subtree..."
  git subtree push --prefix=admin admin-deploy main
else
  echo "Admin not changed — skipping subtree push."
fi

echo "Done!"
