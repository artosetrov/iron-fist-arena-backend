# HEXBOUND — Ultra-Deep Asset Consistency Audit

**Date:** 2026-04-03
**Auditor:** Claude (Principal Design Systems Auditor + Senior UI Engineer)
**Scope:** Full pipeline: Figma DS → Export → xcassets → Code → Runtime

**Status boundary:** historical asset audit snapshot from `2026-04-03`. The concrete findings remain useful, but current asset health should be revalidated against live `Assets.xcassets`, export/sync scripts, and `wiki/` before using this document as an operational truth source.

---

## A. CRITICAL ISSUES

### A1. 🔴 ALL 362 IMAGESETS ARE 1x-ONLY — NO @2x/@3x RETINA ASSETS

**Root cause #1 of ALL pixelation.**

Every single `.imageset` in `Assets.xcassets` follows the same pattern:
```json
{
  "images": [
    {"filename": "asset.png", "idiom": "universal", "scale": "1x"},
    {"idiom": "universal", "scale": "2x"},    // ← EMPTY
    {"idiom": "universal", "scale": "3x"}     // ← EMPTY
  ]
}
```

On iPhone 14 Pro (3x display), iOS upscales every 1x PNG by 3× at runtime → **guaranteed pixelation** on every image in the app.

**Impact:** 100% of bundled images are affected. Every iPhone Pro/Max user sees blurry assets.

---

### A2. 🔴 Historical Finding — sync-assets.sh originally resized downloaded images to max 512px

**Historical file state at audit time:** `scripts/sync-assets.sh`
```bash
optimize_image "$tmp_file" 512    # ← MAX 512px dimension
```

All Items (68), Skins, and Bosses (40+) downloaded from Supabase are forcefully resized to max 512px before being saved to xcassets. If original art is 1024px+, it loses 75% of its pixel data before it even reaches the app.

Combined with the 1x-only issue → a 1024px original becomes 512px, which gets upscaled 3× on Pro devices → effectively 6× quality loss.

**Later resolution:** the cap was subsequently raised to `1024px`, so this section should now be read as historical provenance for the rule, not as a statement about the current script implementation.

---

### A3. 🔴 BUILDING IMAGES: 5-7× UPSCALE ON HUB SCREEN

**File:** `Hexbound/Hexbound/Views/Hub/CityBuildingView.swift:39`

| Building | Source Px | Display (pt) | 3x Needed (px) | Upscale Ratio |
|---|---|---|---|---|
| building-arena | 300×300 | ~566 | 1698 | **5.66×** |
| building-battlepass | 300×300 | ~555 | 1665 | **5.55×** |
| building-tavern | 300×300 | ~532 | 1596 | **5.32×** |
| building-achievements | 300×300 | ~507 | 1521 | **5.07×** |
| building-shop | 300×300 | ~492 | 1476 | **4.92×** |
| building-gold-mine | 128×128 | ~285 | 855 | **6.68×** |
| building-dungeon | 128×128 | ~272 | 816 | **6.38×** |

**This is the most visible pixelation in the app** — hub is the first screen every player sees.

---

### A4. 🔴 MISSING ASSET → RUNTIME CRASH

**File:** `Hexbound/Hexbound/Views/DungeonRush/DungeonRushDetailView.swift:1120`
```swift
Image("rush-ui-escape")    // ← ASSET DOES NOT EXIST
```

No `rush-ui-escape.imageset` in Assets.xcassets. This will show a blank image or crash on access.

---

### A5. 🔴 NETWORK IMAGES LACK SCALE METADATA

**AssetManager.swift** loads network images with `UIImage(data:)` and `UIImage(contentsOfFile:)` — both assume **1x scale** regardless of device. A 512×512 network image displays as 512pt on a 2x device (should be 256pt).

The manifest (`asset-manifest.json`) contains only `url` and `size` — **no width, height, or @2x/@3x variants**.

---

## B. MISMATCH LIST: FIGMA ↔ CODE

### B1. Export Script Gaps (29 assets missing from Figma export)

| Category | Missing Assets | Reason |
|---|---|---|
| Characters/Skins | 47 imagesets (all empty, no PNG files) | Art not created yet |
| JPG backgrounds | 6 (bg-dungeon-map.jpg, bg-rush-elite/event/miniboss/shop.jpeg, hub-terrain.jpg) | Script only handles `*.png` |
| Potion aliases | 3 (pot_health_large/medium/small) | Intentionally skipped |
| preloader-hex | 1 | Not in script's hardcoded list |

### B2. CLAUDE.md Claims vs Reality

| Category | CLAUDE.md Claims | Actually Exported | Gap |
|---|---|---|---|
| 01_Characters | — | 0 | All empty |
| 02_Enemies | 100 | 100 | ✅ Match |
| 03_Items | 68 | 65 | 3 aliases skipped |
| 04_Icons | 82 | 82 | ✅ Match |
| 05_UI_Backgrounds | 27 | 21 | 6 JPGs missing |
| 06_FX | 39 | 39 | ✅ Match |
| 07_Buildings | 20 | 20 | ✅ Match |
| **TOTAL** | **350** | **327** | **23 gap** |

---

## C. DUPLICATE / LEGACY ASSETS

### C1. sidebar/ Folder — 45 Raw PNGs (Legacy Pattern)

**Location:** `Hexbound/Hexbound/Resources/Assets.xcassets/sidebar/`

45 PNG files stored as raw files, NOT proper `.imageset` folders. Missing `Contents.json` at folder level. 20 of these icons are **completely orphaned** — never referenced in code:

```
icon-arena, icon-balance, icon-design-system, icon-dev-panel, icon-dungeons,
icon-leaderboard, icon-lobby, icon-losses, icon-shop, icon-stamina-timer,
icon-switch-char, icon-tavern, icon-training, icon-wins + 6 more
```

### C2. Oversized Files Masquerading as Icons

| File | Size | Expected Size | Dimensions | Display Size |
|---|---|---|---|---|
| icon-wins.png | 1.6 MB | ~20 KB | 1024×1024 | 16pt |
| icon-losses.png | 1.8 MB | ~20 KB | 1024×1024 | 16pt |

These are 80-90× larger than they need to be. 21× downscale at runtime wastes GPU and RAM.

### C3. Naming Convention Violations

Mixed naming conventions across 362 imagesets:
- **kebab-case:** 50 assets (icon-agility, bg-rush-combat)
- **snake_case:** 81 assets (amu_phoenix_heart, acc_iron_shield)
- **Mixed:** 231 assets

Items from Supabase use snake_case, UI assets use kebab-case. No canonical standard enforced.

### C4. 25 Empty Imagesets (Placeholder Only)

Character skins — imagesets with `Contents.json` but **no PNG file inside:**
- 8 avatar variants (avatar-barbarian through avatar-warlord)
- 8 full-body variants (fullbody-barbarian through fullbody-warlord)
- 9 additional skin variants

---

## D. PIXELATION ROOT CAUSES (Ranked by Severity)

| # | Cause | Severity | Scope | Fix Effort |
|---|---|---|---|---|
| **D1** | 1x-only assets on 3x Retina devices | 🔴 CRITICAL | ALL 362 assets | HIGH — re-export at 2x/3x or use PDF vectors |
| **D2** | Historical: sync-assets.sh resized to 512px max at audit time | 🔴 CRITICAL | 168 assets (Items+Bosses+Skins) | LOW — later raised to 1024; continue revalidating source resolution rather than assuming this exact cap still exists |
| **D3** | Building images 128-300px displayed at 500+ pt | 🔴 CRITICAL | 10 buildings on Hub | MEDIUM — re-export at 1024px+ |
| **D4** | Network images loaded as UIImage(data:) = 1x scale | 🔴 CRITICAL | All network assets | MEDIUM — add scale-aware loading |
| **D5** | No .interpolation() control anywhere | 🟡 MODERATE | All Image() views | LOW — add .interpolation(.high) |
| **D6** | FIFO cache eviction, no LRU | 🟡 MODERATE | AssetManager memory cache | MEDIUM — refactor cache |
| **D7** | No retry on failed downloads | 🟡 MODERATE | Network assets | LOW — add retry logic |
| **D8** | False "preserves-vector-representation" on 126 PNGs | 🟡 LOW | 126 raster assets | LOW — remove flag |

---

## E. EXACT FILES/COMPONENTS/SCREENS TO FIX

### E1. Hub Screen (HIGHEST PRIORITY)

**Screen:** `CityMapView.swift` → `CityBuildingView.swift`
**Problem:** All 10 building images are severely pixelated
**Files to fix:**
- `Hexbound/Hexbound/Views/Hub/CityBuildingView.swift` — add interpolation
- `Hexbound/Hexbound/Views/Hub/CityBuildingConfig.swift` — document required sizes
- All `building-*.imageset/` — re-export at 1024×1024 minimum

### E2. Item Grid (HIGH PRIORITY)

**Screen:** `InventoryView.swift`, `ShopView.swift`, `LootPreviewSheet.swift`
**Component:** `ItemImageView.swift`, `ItemCardView.swift`
**Problem:** Item images 128×140px displayed at 82pt = 246px@3x → noticeable upscale
**Files to fix:**
- `scripts/sync-assets.sh` — historical fix already landed by raising the old 512px cap to 1024; re-audit should start from the current script, not this old number
- All `Items/*.imageset/` — verify source resolution on Supabase

### E3. Boss Portraits (MEDIUM PRIORITY)

**Screen:** `DungeonRushDetailView.swift`, `DungeonBossCard.swift`
**Problem:** Boss portraits 256×256 displayed at 80-90pt = 240-270px@3x → borderline
**Files to fix:**
- `Bosses/*.imageset/` — verify dimensions, re-export if <512px

### E4. Avatar / Skins (MEDIUM PRIORITY)

**Component:** `AvatarImageView.swift`
**Problem:** Network skins loaded as 1x, no scale awareness
**Files to fix:**
- `Hexbound/Hexbound/Services/AssetManager.swift` — add scale-aware loading
- `Hexbound/Hexbound/Views/Components/AvatarImageView.swift`

### E5. Missing Asset (BLOCKER)

**Screen:** `DungeonRushDetailView.swift:1120`
**Fix:** Create `rush-ui-escape.imageset` or update code reference

### E6. sidebar/ Cleanup

**Location:** `Assets.xcassets/sidebar/`
**Fix:** Convert active icons to proper `.imageset` or load from bundle correctly; delete orphaned icons

---

## F. WHAT SHOULD BE DELETED

| Item | Reason | Size Saved |
|---|---|---|
| 20 orphaned sidebar/ icons | Never used in code | ~2 MB |
| icon-wins.png (1024×1024 version) | 80× oversized for 16pt display | 1.6 MB |
| icon-losses.png (1024×1024 version) | 80× oversized for 16pt display | 1.8 MB |
| 25 empty Skins imagesets (if art not coming) | Dead placeholders | negligible |
| False `preserves-vector-representation` flags | Misleading on raster PNGs | 0 |
| **~319 orphaned imagesets** (per code audit) | 88% of assets never referenced directly | **~120 MB** |

**⚠️ NOTE on "orphaned" imagesets:** Many are loaded dynamically via computed properties (`.iconAsset`, `.imageKey`), enum-based string construction, or AssetManager network fetches. Before mass deletion, verify each against dynamic loading patterns. The 20 sidebar orphans are confirmed safe to delete.

---

## G. SOURCE OF TRUTH DESIGNATION

| Layer | Source of Truth | Status |
|---|---|---|
| **Art originals** | Figma DS (fileKey: `uDjXIz7CdJxcEOI5jCBcjY`) | 🟡 Partial — 327/362 exported |
| **Asset names** | Figma DS component names = code imageset names | 🟡 23 gaps |
| **Asset dimensions** | Should be Figma DS | 🔴 Not tracked — no dimension metadata anywhere |
| **Scale variants** | Should be xcassets Contents.json | 🔴 All 1x-only |
| **Network assets** | Supabase Storage buckets | ✅ Working but no dimension metadata |
| **Runtime cache** | AssetManager disk cache | 🟡 No eviction, no scale awareness |

**DECISION REQUIRED:** Figma DS MUST become the single source of truth for:
1. Canonical asset names
2. Required dimensions (1x, 2x, 3x)
3. Export format (PNG vs PDF vector)
4. Approved asset list (nothing in code without Figma entry)

---

## H. STEP-BY-STEP FIX PLAN

### Phase 1: STOP THE BLEEDING (1-2 days)

1. **Fix missing asset crash:**
   - Create `rush-ui-escape.imageset` or fix code reference in `DungeonRushDetailView.swift:1120`

2. **Historical resolution note: old sync-assets.sh 512px cap**
   - At audit time the script used `optimize_image "$tmp_file" 512`
   - That cap was later raised to `1024`
   - Re-audits should verify current source-asset resolution and runtime presentation rather than treating `512` as still-live behavior

3. **Re-export building assets at 1024×1024:**
   - All 10 `building-*.imageset` need source art at minimum 1024px
   - Priority: arena, shop, tavern, battlepass, achievements (displayed largest)

4. **Downsize icon-wins and icon-losses:**
   - Resize from 1024×1024 → 256×256 (still 5× larger than display needs)

### Phase 2: SCALE VARIANTS (3-5 days)

5. **For top-50 most-visible assets, add @2x and @3x PNGs:**
   - Buildings: export at 512/1024/1536 (1x/2x/3x)
   - Boss portraits: export at 256/512/768
   - Item icons: export at 128/256/384
   - UI icons: convert to PDF vectors where possible (scale-independent)
   - Update each Contents.json with filenames for all 3 scales

6. **Fix network image scale:**
   - `AssetManager.swift:279` — change `UIImage(data:)` to scale-aware:
   ```swift
   let scale = UIScreen.main.scale
   let image = UIImage(data: data, scale: scale)
   ```

7. **Add interpolation hints:**
   - All Image() views showing icons: `.interpolation(.high)`
   - Background images: `.interpolation(.medium)` (performance)

### Phase 3: PIPELINE FIX (2-3 days)

8. **Fix export script for JPG:**
   - Update `scripts/export-assets-for-figma.sh` to handle `.jpg`/`.jpeg` files
   - Add preloader-hex to export list

9. **Add dimensions to asset-manifest.json:**
   ```json
   {"key": "wpn_excalibur", "url": "...", "size": 33648, "width": 512, "height": 512}
   ```

10. **Create sidebar/Contents.json:**
    - Add proper Xcode metadata
    - Convert active sidebar icons to proper `.imageset` folders
    - Delete 20 orphaned sidebar icons

### Phase 4: GOVERNANCE (1 day)

11. **Add asset dimension tracking to Figma DS:**
    - Each asset component in Figma must document: canonical name, export size, format

12. **Update CLAUDE.md with Permanent Asset Rules** (see Section I below)

13. **Add pre-commit check:**
    ```bash
    # Reject 1x-only imagesets for new assets
    # Reject images < required minimum dimensions
    # Reject unnamed sidebar PNGs
    ```

---

## I. PERMANENT ASSET CONSISTENCY RULES

### Rule 1: Figma DS = Single Source of Truth
Every visual asset in the app MUST have a corresponding named component in Figma DS (`uDjXIz7CdJxcEOI5jCBcjY`). If it's not in Figma, it doesn't ship.

### Rule 2: No Direct Code Addition
New assets CANNOT be added directly to `Assets.xcassets` without first creating a Figma DS component. Workflow: Figma → Export → xcassets → Code.

### Rule 3: No Duplicate Assets
One canonical version per asset. No copies in sidebar/, no old/new versions coexisting. If an asset is renamed, the old imageset is deleted in the same commit.

### Rule 4: No Local Temporary Replacements
Placeholder/temp assets are forbidden in production branches. Use `AssetPlaceholderView` (the DS-approved placeholder component) until real art is ready.

### Rule 5: Canonical Naming Convention
All assets use **kebab-case**: `building-arena`, `icon-gold`, `boss-shadow-wolf`. Items from Supabase sync retain snake_case (`wpn_excalibur`) as exception for backwards compatibility, but new items should use kebab-case.

### Rule 6: Mandatory Dimensions & Format
Each asset MUST have documented:
- **Minimum source dimension** (in Figma component description)
- **Export format** (PNG raster or PDF vector)
- **Required scales:** @1x + @2x + @3x for raster; single PDF for vector

### Rule 7: Scale Variants Required
Every raster `.imageset` MUST contain all 3 scale files:
```
asset-name.imageset/
├── asset-name.png        (1x)
├── asset-name@2x.png     (2x)
├── asset-name@3x.png     (3x)
└── Contents.json
```
Exception: PDF vector assets (single file, auto-scales).

### Rule 8: Minimum Pixel Density
| Display Size | Min Source @1x | Min Source @3x |
|---|---|---|
| Icon (16-36pt) | 36px | 108px |
| Card image (80-100pt) | 100px | 300px |
| Building (200-600pt) | 600px | 1800px |
| Full-screen background | Screen width | Screen width × 3 |

If source PNG is smaller than display frame × device scale → **CRITICAL BUG**.

### Rule 9: Figma Change → Code Update Same Day
If an asset is updated in Figma DS, the code mapping (export, imageset, references) MUST be updated in the same work session. Stale assets = bug.

### Rule 10: Pixelated/Blurry/Stretched = Critical UI Bug
Any asset that appears pixelated, blurry, or stretched on ANY supported device is classified as a **P0 Critical** bug. Same priority as crash.

### Rule 11: Network Image Scale Awareness
`AssetManager` MUST load network images with device scale factor:
```swift
UIImage(data: data, scale: UIScreen.main.scale)
```
Never use bare `UIImage(data:)` for display images.

### Rule 12: No sync-assets.sh Downsizing Below Display Needs
`sync-assets.sh` optimization MUST NOT resize below the maximum display size × 3 (for 3x devices). At audit time the current 512px cap was insufficient for buildings (need 1800px); later script updates raised that floor, but the rule itself remains live.

### Rule 13: Pre-Commit Asset Validation
Before every commit touching assets:
```bash
# Check for 1x-only imagesets (new assets must have 2x/3x)
find Assets.xcassets -name "Contents.json" -path "*.imageset/*" \
  -exec grep -L '"filename.*@2x"' {} \;

# Check for oversized files (> 2MB for icons)
find Assets.xcassets -name "*.png" -size +2M

# Check for raw PNGs outside imagesets
find Assets.xcassets -name "*.png" -not -path "*.imageset/*"

# Check for empty imagesets
find Assets.xcassets -name "Contents.json" -path "*.imageset/*" \
  -exec grep -L '"filename"' {} \;
```

### Rule 14: Export Script Must Cover All Formats
`export-assets-for-figma.sh` must handle PNG, JPG, JPEG, and PDF. Any format in xcassets but not in export script = sync gap.

### Rule 15: Quarterly Asset Audit
Every 3 months, run full cross-reference: Figma DS components → figma-assets/ → xcassets → code references. Any drift = immediate fix sprint.

---

## APPENDIX: AUDIT METHODOLOGY

### Tools Used
- `sips --getProperty pixelWidth/pixelHeight` — actual PNG dimensions
- `find` + `grep` — Contents.json analysis across 362 imagesets
- Code grep — all `Image()`, `UIImage(named:)`, `.frame()`, `.resizable()` calls
- Script analysis — `export-assets-for-figma.sh`, `sync-assets.sh`
- AssetManager.swift deep read — caching, loading, scale handling
- asset-manifest.json — network asset metadata

### Files Audited
- 362 imageset Contents.json files
- 45 sidebar raw PNGs
- 90+ Image() references in 40+ Swift files
- AssetManager.swift (342 lines)
- CachedAssetImage.swift (79 lines)
- AvatarImageView.swift (55 lines)
- ItemImageView.swift (62 lines)
- AssetPlaceholderView.swift (29 lines)
- CityBuildingView.swift + CityBuildingConfig.swift
- sync-assets.sh (400+ lines)
- export-assets-for-figma.sh (85 lines)
- asset-manifest.json (65 items)
- backend/src/app/api/assets/manifest/route.ts (133 lines)
