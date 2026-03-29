#!/bin/bash
# Deploy Hexbound Landing to production (Vercel via GitHub)
# Usage: cd hexbound-landing && bash deploy.sh
#
# What it does:
# 1. Clones the hexbound-landing GitHub repo to /tmp
# 2. Copies all local files into the clone
# 3. Commits and pushes to GitHub
# 4. Vercel auto-deploys from GitHub push
#
# Prerequisites:
# - Git configured with GitHub access
# - Remote repo: github.com/artosetrov/hexbound-landing

set -e

REPO_URL="git@github.com:artosetrov/hexbound-landing.git"
TMP_DIR="/tmp/hexbound-landing-deploy"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Hexbound Landing — Deploy to Production"
echo "════════════════════════════════════════════"
echo "  Source: $LOCAL_DIR"
echo "  Target: $REPO_URL"
echo ""

# Get commit message
MSG="${1:-Update landing page $(date '+%Y-%m-%d %H:%M')}"

# Step 1: Clean clone
echo "📥 Cloning deploy repo..."
rm -rf "$TMP_DIR"
git clone --depth 1 "$REPO_URL" "$TMP_DIR" 2>/dev/null || {
    echo "❌ Failed to clone. Check SSH keys / GitHub access."
    exit 1
}

# Step 2: Sync local files (delete old, copy new)
echo "📋 Syncing files..."
# Remove old content (keep .git)
find "$TMP_DIR" -maxdepth 1 -not -name '.git' -not -name '.' -not -name '..' -exec rm -rf {} + 2>/dev/null || true

# Copy local files
cp -R "$LOCAL_DIR/index.html" "$TMP_DIR/"
cp -R "$LOCAL_DIR/privacy.html" "$TMP_DIR/"
cp -R "$LOCAL_DIR/support.html" "$TMP_DIR/"
cp -R "$LOCAL_DIR/vercel.json" "$TMP_DIR/"
cp -R "$LOCAL_DIR/assets" "$TMP_DIR/"

# Don't copy dev scripts to deploy
# (serve.sh, deploy.sh, copy-assets.sh stay local only)

# Step 3: Commit and push
echo "📤 Committing and pushing..."
cd "$TMP_DIR"
git add -A
if git diff --cached --quiet; then
    echo "✅ No changes to deploy. Production is up to date."
else
    git commit -m "$MSG"
    git push origin main
    echo ""
    echo "✅ Deployed! Vercel will auto-build in ~30 seconds."
    echo "   https://hexboundapp.com"
fi

# Cleanup
rm -rf "$TMP_DIR"
echo "🧹 Cleaned up temp files."
