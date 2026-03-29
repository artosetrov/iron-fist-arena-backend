#!/bin/bash
# =============================================================================
# sync-assets.sh — Syncs assets from Supabase Storage → Xcode Assets.xcassets
#
# Usage:
#   ./scripts/sync-assets.sh              # Full sync (items + skins + bosses)
#   ./scripts/sync-assets.sh --items      # Sync only items
#   ./scripts/sync-assets.sh --skins      # Sync only skins
#   ./scripts/sync-assets.sh --bosses     # Sync only bosses
#   ./scripts/sync-assets.sh --dry-run    # Show what would change without downloading
#
# Environment:
#   SUPABASE_URL           — Supabase project URL (auto-detected from backend/.env)
#   SUPABASE_SERVICE_KEY   — Service role key (auto-detected from backend/.env)
#
# This script:
#   1. Lists assets in Supabase Storage buckets
#   2. Compares with local Assets.xcassets (by name + size)
#   3. Downloads new/updated assets
#   4. Creates proper .imageset folders with Contents.json
#   5. Generates a manifest.json for iOS hot-update cache
#
# Integrations:
#   - git-watcher.sh calls this before committing (if --pre-commit flag)
#   - Herald deploy agent calls this before push
# =============================================================================

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$REPO_DIR/Hexbound/Hexbound/Resources/Assets.xcassets"
MANIFEST_DIR="$REPO_DIR/Hexbound/Hexbound/Resources"
MANIFEST_FILE="$MANIFEST_DIR/asset-manifest.json"

# Supabase bucket and path mappings
# Format: "bucket:remote_path:local_folder"
ASSET_MAPPINGS=(
    "assets:items:Items"
    "assets:appearances:Skins"
    "dungeon-assets::Bosses"
)

# ─── Flags ────────────────────────────────────────────────────────────────────

DRY_RUN=false
SYNC_ITEMS=true
SYNC_SKINS=true
SYNC_BOSSES=true
VERBOSE=false
OPTIMIZE=true
PRE_COMMIT=false

for arg in "$@"; do
    case $arg in
        --dry-run)    DRY_RUN=true ;;
        --items)      SYNC_SKINS=false; SYNC_BOSSES=false ;;
        --skins)      SYNC_ITEMS=false; SYNC_BOSSES=false ;;
        --bosses)     SYNC_ITEMS=false; SYNC_SKINS=false ;;
        --verbose)    VERBOSE=true ;;
        --no-optimize) OPTIMIZE=false ;;
        --pre-commit) PRE_COMMIT=true ;;
        --help)
            echo "Usage: $0 [--items|--skins|--bosses] [--dry-run] [--verbose] [--no-optimize] [--pre-commit]"
            exit 0 ;;
        *) echo "Unknown flag: $arg"; exit 1 ;;
    esac
done

# ─── Load Supabase credentials ───────────────────────────────────────────────

load_env() {
    local env_file="$REPO_DIR/backend/.env"
    if [ ! -f "$env_file" ]; then
        env_file="$REPO_DIR/backend/.env.local"
    fi
    if [ ! -f "$env_file" ]; then
        echo "❌ No .env file found in backend/. Set SUPABASE_URL and SUPABASE_SERVICE_KEY manually."
        exit 1
    fi

    if [ -z "${SUPABASE_URL:-}" ]; then
        SUPABASE_URL=$(grep "^NEXT_PUBLIC_SUPABASE_URL=" "$env_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
    if [ -z "${SUPABASE_SERVICE_KEY:-}" ]; then
        SUPABASE_SERVICE_KEY=$(grep "^SUPABASE_SERVICE_ROLE_KEY=" "$env_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi

    if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_KEY" ]; then
        echo "❌ Could not load Supabase credentials from $env_file"
        exit 1
    fi

    $VERBOSE && echo "✅ Loaded Supabase config from $env_file"
    $VERBOSE && echo "   URL: $SUPABASE_URL"
}

# ─── Supabase Storage API helpers ─────────────────────────────────────────────

# List files in a bucket/path
# Returns: JSON array of { name, metadata: { size, mimetype, ... } }
list_bucket_files() {
    local bucket="$1"
    local prefix="${2:-}"

    local body
    if [ -n "$prefix" ]; then
        body="{\"prefix\":\"$prefix/\",\"limit\":1000}"
    else
        body="{\"prefix\":\"\",\"limit\":1000}"
    fi

    curl -s --max-time 30 --retry 2 --retry-delay 3 \
        -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
        -H "Content-Type: application/json" \
        -d "$body" \
        "$SUPABASE_URL/storage/v1/object/list/$bucket" 2>/dev/null || echo ""
}

# Download a file from public bucket
download_file() {
    local bucket="$1"
    local path="$2"
    local output="$3"

    curl -s -L --max-time 60 --retry 2 --retry-delay 3 \
        -o "$output" \
        "$SUPABASE_URL/storage/v1/object/public/$bucket/$path" 2>/dev/null || true
}

# ─── Image optimization ──────────────────────────────────────────────────────

optimize_image() {
    local input="$1"
    local max_dimension="${2:-512}"

    # Skip if sips not available (non-macOS)
    if ! command -v sips &>/dev/null; then
        return
    fi

    # Get current dimensions
    local width height
    width=$(sips -g pixelWidth "$input" 2>/dev/null | tail -1 | awk '{print $2}')
    height=$(sips -g pixelHeight "$input" 2>/dev/null | tail -1 | awk '{print $2}')

    if [ -z "$width" ] || [ -z "$height" ]; then
        return
    fi

    # Downscale if larger than max_dimension
    if [ "$width" -gt "$max_dimension" ] || [ "$height" -gt "$max_dimension" ]; then
        sips --resampleHeightWidthMax "$max_dimension" "$input" --out "$input" &>/dev/null
        $VERBOSE && echo "   📐 Resized to max ${max_dimension}px"
    fi
}

# ─── Imageset creation ────────────────────────────────────────────────────────

# Create a proper .imageset folder with Contents.json
create_imageset() {
    local asset_key="$1"    # e.g. "chest_chain_mail"
    local image_file="$2"   # path to downloaded image
    local target_dir="$3"   # e.g. .../Assets.xcassets/Items

    local imageset_dir="$target_dir/${asset_key}.imageset"
    mkdir -p "$imageset_dir"

    # Determine extension
    local ext="${image_file##*.}"
    local filename="${asset_key}.${ext}"

    # Copy image as the universal (@1x) asset
    cp "$image_file" "$imageset_dir/$filename"

    # Create Contents.json
    cat > "$imageset_dir/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "$filename",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "sync-assets",
    "version" : 1
  }
}
EOF
}

# ─── Sync logic ───────────────────────────────────────────────────────────────

TOTAL_NEW=0
TOTAL_UPDATED=0
TOTAL_SKIPPED=0
MANIFEST_ENTRIES=()

sync_category() {
    local bucket="$1"
    local remote_path="$2"
    local local_folder="$3"
    local category_name="$4"

    local target_dir="$ASSETS_DIR/$local_folder"
    mkdir -p "$target_dir"

    echo ""
    echo "🔄 Syncing $category_name ($bucket/${remote_path:-root})..."

    # List remote files
    local response
    response=$(list_bucket_files "$bucket" "$remote_path")

    if [ -z "$response" ] || echo "$response" | grep -q '"error"'; then
        echo "   ⚠️  Failed to list $bucket/$remote_path"
        $VERBOSE && echo "   Response: $response"
        return
    fi

    # Parse file list — filter only image files (not folders)
    # Also skip:
    #   - loot_* with UUIDs (one-off generated loot images, not catalog items)
    #   - Timestamp-prefixed files (raw uploads like 1709123456_abc123.png)
    local files
    files=$(echo "$response" | python3 -c "
import json, sys, re
data = json.load(sys.stdin)
# Skip patterns: loot UUIDs, raw timestamp uploads
SKIP_PATTERNS = [
    re.compile(r'^loot_[0-9a-f]{8}-'),        # loot_01c8c5de-5083-...
    re.compile(r'^\d{10,}_[a-z0-9]+\.'),       # 1773839797311_90sowr.png
    re.compile(r'^\.emptyFolderPlaceholder$'),  # Supabase placeholder
]
for item in data:
    name = item.get('name', '')
    metadata = item.get('metadata', {}) or {}
    size = metadata.get('size', 0)
    mimetype = metadata.get('mimetype', '')
    # Skip folders (id is null) and non-image files
    if not item.get('id') or not mimetype.startswith('image/'):
        continue
    # Skip junk patterns
    if any(p.match(name) for p in SKIP_PATTERNS):
        continue
    print(f'{name}\t{size}\t{mimetype}')
" 2>/dev/null || echo "")

    if [ -z "$files" ]; then
        echo "   📭 No image files found"
        return
    fi

    local count=0
    local new_count=0
    local updated_count=0
    local skipped_count=0

    while IFS=$'\t' read -r filename remote_size mimetype; do
        count=$((count + 1))

        # Derive asset key from filename (remove extension)
        local asset_key="${filename%.*}"
        # Clean up timestamp prefixes if present (e.g. 1709123456_abc123.png → abc123)
        # But keep meaningful names like "chest_chain_mail.png"

        local ext="${filename##*.}"
        local imageset_dir="$target_dir/${asset_key}.imageset"
        local local_file="$imageset_dir/${asset_key}.${ext}"

        # Build remote path for download
        local download_path
        if [ -n "$remote_path" ]; then
            download_path="$remote_path/$filename"
        else
            download_path="$filename"
        fi

        # Check if local file exists and compare size
        local needs_download=false
        if [ ! -d "$imageset_dir" ]; then
            needs_download=true
            new_count=$((new_count + 1))
            $VERBOSE && echo "   🆕 $asset_key (new)"
        elif [ ! -f "$local_file" ]; then
            needs_download=true
            updated_count=$((updated_count + 1))
            $VERBOSE && echo "   🔄 $asset_key (missing local file)"
        else
            local local_size
            local_size=$(stat -f%z "$local_file" 2>/dev/null || stat -c%s "$local_file" 2>/dev/null || echo "0")
            if [ "$local_size" != "$remote_size" ]; then
                needs_download=true
                updated_count=$((updated_count + 1))
                $VERBOSE && echo "   🔄 $asset_key (size changed: $local_size → $remote_size)"
            else
                skipped_count=$((skipped_count + 1))
                $VERBOSE && echo "   ✓  $asset_key (up to date)"
            fi
        fi

        if $needs_download; then
            if $DRY_RUN; then
                echo "   [DRY RUN] Would download: $asset_key"
            else
                # Download to temp file
                local tmp_file
                tmp_file=$(mktemp "/tmp/sync-asset-XXXXXX.$ext")
                download_file "$bucket" "$download_path" "$tmp_file"

                # Verify download
                if [ ! -s "$tmp_file" ]; then
                    echo "   ❌ Failed to download: $asset_key"
                    rm -f "$tmp_file"
                    continue
                fi

                # Optimize if enabled
                if $OPTIMIZE; then
                    optimize_image "$tmp_file" 512
                fi

                # Create imageset
                create_imageset "$asset_key" "$tmp_file" "$target_dir"
                rm -f "$tmp_file"
            fi
        fi

        # Add to manifest
        local public_url="$SUPABASE_URL/storage/v1/object/public/$bucket/$download_path"
        MANIFEST_ENTRIES+=("{\"key\":\"$asset_key\",\"url\":\"$public_url\",\"size\":$remote_size,\"category\":\"$category_name\"}")

    done <<< "$files"

    TOTAL_NEW=$((TOTAL_NEW + new_count))
    TOTAL_UPDATED=$((TOTAL_UPDATED + updated_count))
    TOTAL_SKIPPED=$((TOTAL_SKIPPED + skipped_count))

    echo "   📊 $count files: $new_count new, $updated_count updated, $skipped_count unchanged"
}

# ─── Manifest generation ─────────────────────────────────────────────────────

generate_manifest() {
    echo ""
    echo "📋 Generating asset manifest..."

    local entries_json=""
    local first=true
    for entry in "${MANIFEST_ENTRIES[@]}"; do
        if $first; then
            entries_json="$entry"
            first=false
        else
            entries_json="$entries_json,$entry"
        fi
    done

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$MANIFEST_FILE" << EOF
{
  "version": "$(date +%s)",
  "generatedAt": "$timestamp",
  "totalAssets": ${#MANIFEST_ENTRIES[@]},
  "assets": [
    $(echo "$entries_json" | sed 's/},{/},\n    {/g')
  ]
}
EOF

    echo "   ✅ Manifest: $MANIFEST_FILE (${#MANIFEST_ENTRIES[@]} entries)"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo "⚔️  Hexbound Asset Sync"
    echo "========================"
    $DRY_RUN && echo "🏳️  DRY RUN MODE — no files will be downloaded"
    echo ""

    load_env

    if $SYNC_ITEMS; then
        sync_category "assets" "items" "Items" "items"
    fi

    if $SYNC_SKINS; then
        sync_category "assets" "appearances" "Skins" "skins"
    fi

    if $SYNC_BOSSES; then
        sync_category "dungeon-assets" "" "Bosses" "bosses"
    fi

    # Generate manifest for iOS hot-update
    if ! $DRY_RUN; then
        generate_manifest
    fi

    # Summary
    echo ""
    echo "========================"
    echo "📊 Sync complete!"
    echo "   🆕 New:       $TOTAL_NEW"
    echo "   🔄 Updated:   $TOTAL_UPDATED"
    echo "   ✓  Unchanged: $TOTAL_SKIPPED"

    if [ $TOTAL_NEW -gt 0 ] || [ $TOTAL_UPDATED -gt 0 ]; then
        echo ""
        echo "💡 Assets changed — commit and rebuild to include in app bundle."
        if $PRE_COMMIT; then
            echo "   (Running as pre-commit — changes will be included in this commit)"
        fi
        return 0
    else
        echo "   No changes needed."
        return 0
    fi
}

main
