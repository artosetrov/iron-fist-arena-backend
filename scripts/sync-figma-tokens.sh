#!/usr/bin/env bash
# Figma → Swift Token Sync
#
# Step 1: Export tokens from Figma DS via Claude Code MCP
#   → Ask Claude: "export figma tokens to figma-tokens.json"
#   → Or manually: run use_figma script that dumps variables
#
# Step 2: Run diff check
#   node scripts/sync-figma-tokens.js
#
# This script runs Step 2 only. Step 1 requires Figma MCP connection.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
cd "$REPO_DIR"

if [ ! -f figma-tokens.json ]; then
  echo "❌ figma-tokens.json not found."
  echo ""
  echo "To generate it, ask Claude Code:"
  echo '  "export figma tokens"'
  echo ""
  echo "Or run the Figma MCP export manually."
  exit 1
fi

echo "🔍 Checking Figma ↔ Swift token sync..."
echo ""
node scripts/sync-figma-tokens.js
