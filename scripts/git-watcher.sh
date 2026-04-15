#!/usr/bin/env bash
# =============================================================================
# git-watcher.sh — Watches for .git-trigger file and auto-commits
# Run this in a terminal tab: ./scripts/git-watcher.sh
# Claude creates .git-trigger with commit message → this script commits & pushes
#
# Asset sync: optionally runs sync-assets.sh before each commit when
# HEXBOUND_AUTO_SYNC_ASSETS=1 is set in the shell environment.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TRIGGER="$REPO_DIR/.git-trigger"
SYNC_SCRIPT="$REPO_DIR/scripts/sync-assets.sh"
AUTO_SYNC_ASSETS="${HEXBOUND_AUTO_SYNC_ASSETS:-0}"

clear_stale_lock() {
  local lock_file="$1"
  if [ ! -e "$lock_file" ]; then
    return 0
  fi

  if command -v lsof >/dev/null 2>&1 && lsof "$lock_file" >/dev/null 2>&1; then
    echo "❌ Git lock is active: $lock_file"
    return 1
  fi

  echo "⚠️  Clearing stale Git lock: $lock_file"
  rm -f "$lock_file"
}

echo "🔮 Git watcher started. Watching for $TRIGGER..."

while true; do
  if [ -f "$TRIGGER" ]; then
    MSG="$(<"$TRIGGER")"
    rm -f "$TRIGGER"

    echo ""
    echo "⚔️  Trigger detected! Committing: $MSG"
    echo "---"

    cd "$REPO_DIR"
    clear_stale_lock .git/index.lock || continue
    clear_stale_lock .git/HEAD.lock || continue
    CURRENT_BRANCH="$(git branch --show-current)"
    if [ -z "$CURRENT_BRANCH" ]; then
      echo "❌ Detached HEAD; skipping auto-push."
      continue
    fi

    # 🎨 Optional asset sync from Supabase before committing
    if [ "$AUTO_SYNC_ASSETS" = "1" ] && [ -x "$SYNC_SCRIPT" ]; then
      echo "🎨 Syncing assets from Supabase..."
      "$SYNC_SCRIPT" --pre-commit 2>&1 | tail -5
      echo "---"
    fi

    git add -A

    if git diff --cached --quiet; then
      echo "Nothing to commit."
    else
      git commit -m "$MSG"
      git push origin "$CURRENT_BRANCH"

      # Push admin subtree if admin/ changed
      if git diff-tree --no-commit-id --name-only -r HEAD | grep -q "^admin/"; then
        echo "📜 Admin changed — pushing subtree..."
        if git remote get-url admin-deploy >/dev/null 2>&1; then
          git subtree push --prefix=admin admin-deploy main
        else
          echo "Admin remote 'admin-deploy' not configured — skipping subtree push."
        fi
      fi

      echo "✅ Done!"
    fi
    echo "---"
    echo "🔮 Watching again..."
  fi
  sleep 2
done
