#!/bin/bash
# =============================================================================
# git-watcher.sh — Watches for .git-trigger file and auto-commits
# Run this in a terminal tab: ./scripts/git-watcher.sh
# Claude creates .git-trigger with commit message → this script commits & pushes
#
# Asset sync: Automatically runs sync-assets.sh before each commit to pull
# latest assets from Supabase Storage into the Xcode bundle.
# =============================================================================

REPO_DIR="/Users/artosetrov/Documents/Cursor AI/PVP RPG"
TRIGGER="$REPO_DIR/.git-trigger"
SYNC_SCRIPT="$REPO_DIR/scripts/sync-assets.sh"

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

    # 🎨 Auto-sync assets from Supabase before committing
    if [ -x "$SYNC_SCRIPT" ]; then
      echo "🎨 Syncing assets from Supabase..."
      "$SYNC_SCRIPT" --pre-commit 2>&1 | tail -5
      echo "---"
    fi

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
