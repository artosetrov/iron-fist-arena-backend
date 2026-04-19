#!/usr/bin/env bash
# =============================================================================
# git-watcher.sh — Watches for .git-trigger file and auto-commits
# Run this in a terminal tab: ./scripts/git-watcher.sh
# Claude creates .git-trigger with commit message → this script commits & pushes
#
# Asset sync: optionally runs sync-assets.sh before each commit when
# HEXBOUND_AUTO_SYNC_ASSETS=1 is set in the shell environment.
# Staging mode: tracked changes only by default (`git add -u`). To include
# untracked files, set HEXBOUND_GIT_HELPER_STAGE_ALL=1 in the shell environment.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TRIGGER="$REPO_DIR/.git-trigger"
SYNC_SCRIPT="$REPO_DIR/scripts/sync-assets.sh"
AUTO_SYNC_ASSETS="${HEXBOUND_AUTO_SYNC_ASSETS:-0}"
STAGE_ALL="${HEXBOUND_GIT_HELPER_STAGE_ALL:-0}"

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
if [ "$STAGE_ALL" = "1" ]; then
  echo "📦 Staging mode: tracked + untracked changes (git add -A)"
else
  echo "📦 Staging mode: tracked changes only (git add -u)"
fi

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

    if [ "$STAGE_ALL" = "1" ]; then
      git add -A
    else
      git add -u
      UNTRACKED_COUNT="$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
      if [ "${UNTRACKED_COUNT:-0}" -gt 0 ]; then
        echo "⚠️  Leaving $UNTRACKED_COUNT untracked file(s) unstaged. Set HEXBOUND_GIT_HELPER_STAGE_ALL=1 to include them."
      fi
    fi

    if git diff --cached --quiet; then
      echo "Nothing to commit."
    else
      git commit -m "$MSG"
      git push origin "$CURRENT_BRANCH"
      echo "✅ Commit pushed to origin."
    fi

    # Reconcile admin subtree with admin-deploy/main on EVERY trigger.
    # This catches up after a prior failed subtree push, even when the current
    # trigger had no admin/** changes. Idempotent: no-op if already in sync.
    if git remote get-url admin-deploy >/dev/null 2>&1; then
      if git fetch admin-deploy main -q 2>/dev/null; then
        LOCAL_ADMIN_TREE="$(git rev-parse HEAD:admin 2>/dev/null || true)"
        REMOTE_ADMIN_TREE="$(git rev-parse admin-deploy/main^{tree} 2>/dev/null || true)"
        if [ -n "$LOCAL_ADMIN_TREE" ] && [ -n "$REMOTE_ADMIN_TREE" ] \
            && [ "$LOCAL_ADMIN_TREE" != "$REMOTE_ADMIN_TREE" ]; then
          echo "📜 Admin subtree drifted — pushing catchup to admin-deploy/main..."
          if git subtree push --prefix=admin admin-deploy main; then
            echo "✅ Admin subtree catchup done."
          else
            echo "❌ Admin subtree push failed — admin prod may be stale."
          fi
        fi
      else
        echo "⚠️  Could not fetch admin-deploy/main — skipping subtree drift check."
      fi
    fi

    echo "---"
    echo "🔮 Watching again..."
  fi
  sleep 2
done
