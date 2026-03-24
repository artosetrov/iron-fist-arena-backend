#!/bin/bash
# =============================================================================
# git-watcher.sh — Watches for .git-trigger file and auto-commits
# Run this in a terminal tab: ./scripts/git-watcher.sh
# Claude creates .git-trigger with commit message → this script commits & pushes
# =============================================================================

REPO_DIR="/Users/artosetrov/Documents/Cursor AI/PVP RPG"
TRIGGER="$REPO_DIR/.git-trigger"

echo "🔮 Git watcher started. Watching for $TRIGGER..."

while true; do
  if [ -f "$TRIGGER" ]; then
    MSG=$(cat "$TRIGGER")
    rm -f "$TRIGGER"

    echo ""
    echo "⚔️  Trigger detected! Committing: $MSG"
    echo "---"

    cd "$REPO_DIR"
    rm -f .git/index.lock .git/HEAD.lock

    git add -A

    if git diff --cached --quiet; then
      echo "Nothing to commit."
    else
      git commit -m "$MSG"
      git push origin main

      # Push admin subtree if admin/ changed
      if git diff HEAD~1 --name-only | grep -q "^admin/"; then
        echo "📜 Admin changed — pushing subtree..."
        git subtree push --prefix=admin admin-deploy main
      fi

      echo "✅ Done!"
    fi
    echo "---"
    echo "🔮 Watching again..."
  fi
  sleep 2
done
