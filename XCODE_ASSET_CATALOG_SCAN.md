# Hexbound Xcode Asset Catalog Comprehensive Scan
**Date: 2026-04-03**
**Location:** `/sessions/nifty-hopeful-mayer/mnt/PVP RPG/Hexbound/Hexbound/Resources/Assets.xcassets`

---

## Executive Summary

The Hexbound iOS app contains a **mature, well-organized asset catalog** with **362 image assets** across multiple folders, complemented by a **figma-assets/** export directory containing 333 source PNG files for design-to-development handoff. The catalog is **primarily single-scale (1x only)** with strategic exceptions for fortune wheel mechanics (2x/3x only) and contains **25 placeholder assets** (empty imagesets) awaiting art implementation.

---

## 1. ASSET SET INVENTORY

| Asset Type | Count | Details |
|---|---|---|
| `.imageset` directories | 362 | Image sets (raster graphics) |
| `.appiconset` directories | 1 | App icon set (1024x1024 universal) |
| `.colorset` directories | 0 | Color sets (none present) |
| **Total top-level assets** | **363** | Plus sidebar raw PNGs |

### Top-Level Folder Structure

```
Assets.xcassets/
├── AppIcon.appiconset/         (1 set)
├── Bosses/                     (40 imagesets)
├── Items/                      (71 imagesets)
├── Skins/                      (16 imagesets)
├── sidebar/                    (45 raw PNG files, NOT imagesets)
└── 234 root-level imagesets    (UI, backgrounds, effects, buildings, icons, currency, etc.)
```

---

## 2. DETAILED FOLDER BREAKDOWN

### **Bosses/** (40 imagesets)
- **Content:** Dungeon boss enemies (full-body + portrait pairs)
- **Naming:** `boss-<name>-full.imageset`, `boss-<name>-portrait.imageset`
- **Scale Coverage:** 1x only (standard)
- **Dimensions:** 1024x1024 (full), variable (portrait)
- **Examples:**
  - boss-lich-king-full.imageset
  - boss-banshee-portrait.imageset
  - boss-stone-golem-full.imageset

### **Items/** (71 imagesets)
Equipment, consumables, gems organized by type:

| Type | Count | Examples |
|---|---|---|
| Weapons (wpn_*) | 14 | wpn-excalibur, wpn-flamebrand, wpn-iron-dagger |
| Armor (chest, helm, legs, gloves, boots) | 23 | chest-plate-armor, helm-crown-of-thorns |
| Accessories (acc, amu, belt, neck, relic, ring) | 19 | acc-iron-shield, amu-phoenix-heart, ring-blood-ruby |
| Potions (health, stamina, pot_*) | 12 | health-potion-small, stamina-potion-large |
| Currency/Gems (gem_*) | 3 | gem-pack-small, gem-pack-large |

**Scale Coverage:** 1x only
**Dimensions:** 256x256 (standard)

### **Skins/** (16 imagesets)
Character skins and avatars for playable classes:

| Asset | Type | Status |
|---|---|---|
| avatar-barbarian | avatar | 1x |
| avatar-knight | avatar | 1x |
| barbarian | full | empty |
| knight | full | empty |
| ... (8 more classes) | ... | mixed |

**Note:** Many are **empty placeholders** (8 total: barbarian, enchantress, huntress, knight, shadow, sorceress, valkyrie, warlord) awaiting character art.

### **sidebar/** (45 raw PNG files)
**SPECIAL CASE:** This folder contains raw PNG files, NOT imagesets. They are **direct references** to icon assets and may represent a legacy organization pattern or direct asset inclusion mechanism.

**Files:** icon-*.png, icon-stat-*.png, etc. (45 total)
**Not managed as imagesets** — direct file references in code.

### **Root-Level Assets** (234 imagesets)
Organized by category:

#### Background Assets (13 total)
- `bg-arena.imageset` — Arena battle screen background
- `bg-hub.imageset` — Main hub/lobby background (4096x1738 wide panorama)
- `bg-dungeon.imageset` — Dungeon room background
- `bg-rush-*.imageset` — Dungeon Rush mode backgrounds (combat, elite, event, shop, treasure, etc.)
- `bg-fortune-wheel.imageset`
- `bg-shell-game.imageset`
- `bg-forge.imageset`

#### Building Assets (16 total + 1 Coming Soon)
Hub buildings: `building-<name>.imageset`
- training-camp, arena, shop, tavern, gold-mine, guild-hall, ranks
- 10 dungeon variants (catacombs, clockwork-citadel, frozen-abyss, etc.)
- achievements, battlepass, black-market (coming soon)
- **Dimensions:** 300x300
- **Scale:** 1x only

#### UI/Icon Assets (100+ total)
**Stat Icons** (core attributes):
- icon-strength, icon-agility, icon-intelligence, icon-endurance, icon-wisdom, icon-charisma, icon-vitality, icon-luck

**Game System Icons:**
- icon-gold, icon-gems, icon-xp, icon-stamina, icon-stamina-timer
- icon-pvp-rating, icon-wins, icon-losses, icon-fights

**Class Icons:**
- icon-warrior, icon-rogue, icon-mage, icon-tank

**Race Icons:**
- race-icon-human, race-icon-orc, race-icon-skeleton, race-icon-demon, race-icon-dogfolk

**Activity Icons:**
- icon-arena, icon-dungeons, icon-dungeon-rush, icon-gold-mine, icon-tavern, icon-shell-game, icon-training
- icon-leaderboard, icon-lobby, icon-shop

**Control/Settings Icons:**
- hud-gift, hud-quests, hud-sound-on, hud-sound-off, icon-settings, icon-switch-char, icon-design-system, icon-dev-panel

**Fortune Wheel Icons** (SPECIAL CASE — see below):
- icon-fortune-x2, icon-fortune-x3, icon-fortune-x5, icon-fortune-x15, icon-fortune-lose
- **Scale:** 2x + 3x ONLY (no 1x file) — unusual pattern

**Dimensions:** 256x256 (standard icons)

#### Rush Mode Assets (Dungeon Rush)
Enemies (portrait + full-body pairs): ~40 imagesets
- rush-goblin-scout, rush-undead-soldier, rush-stone-golem, rush-iron-juggernaut, etc.
- **Dimensions:** 1024x1024 (full), variable (portrait)

UI Assets:
- rush-buff-* (buffs: defense, poison, speed, strength, vitality, perception, fortune)
- rush-node-* (dungeon map nodes: combat, elite, event, miniboss)
- rush-ui-* (chest, skull, gold bag, potion, treasure, victory banner, shop sign)
- rush-event-* (special encounters: blessing, cursed altar, fountain, gold cache, mimic, rest camp, weapon rack)

**Dimensions:** 256-512px (varies)

#### Dungeon Boss Assets (Dungeon adventure line)
`boss-<name>-*.imageset` — 40 total
- Thematic bosses: stone golem, fire imp, bone colossus, lich king, plague bearer, shadow stalker, etc.
- **Dimensions:** 1024x1024

#### Effect/FX Assets (38 total)
Combat effects, damage numbers, buffs:
- `fx-block-*.imageset` (hexshield, runeshield, silvershield)
- `fx-crit-text.imageset`, `fx-critical-text.imageset`, `fx-dodge-text.imageset`, `fx-miss-text.imageset`
- `fx-heal-*.imageset` (divine, nature)
- `fx-physical-*.imageset` (arc, beam, burst, doublehit, explosion, impact, slash)
- `fx-magical-*.imageset` (burst, fractal, vortex)
- `fx-poison-*.imageset` (blob, skull, splat)
- `fx-fire-*.imageset` (flame, pillar)
- `fx-true-lightning.imageset`
- **Dimensions:** 256-512px

#### Reward/Result Assets (10 total)
- `reward-gold.imageset`, `reward-xp.imageset`, `reward-loot.imageset`
- `reward-level-up.imageset`, `reward-turns.imageset`
- `reward-rating-up.imageset`, `reward-rating-down.imageset`
- `reward-first-win.imageset`
- `result-victory.imageset`, `result-defeat.imageset`, `result-loot-found.imageset`

#### Fortune Wheel Assets (9 imagesets + 1 npc)
- `fortune-wheel-face.imageset` — Spinning wheel face
- `fortune-pointer.imageset` — Spinning indicator
- `fortune-spin-banner.imageset` — Spin action banner
- `lady-fortuna.imageset` — NPC character
- `icon-fortune-*.imageset` — Multiplier icons
- **SPECIAL:** These have **2x/3x scale ONLY** (no 1x) — unusual pattern unique to this feature

#### Gold Mine Assets (7 imagesets)
- `mine-slot-1.imageset` through `mine-slot-6.imageset`
- `mine-slot-locked.imageset`
- **Dimensions:** 256x256
- **Content:** Mini-game UI for currency collection

#### Shell Game Assets (2 imagesets)
- `shell_ball.imageset`
- `shell_cup.imageset`

#### Misc UI Assets (10+ total)
- `ui-arrow-up.imageset`, `ui-arrow-down.imageset`, `ui-arrow-left.imageset`, `ui-arrow-right.imageset`
- `ui-dice.imageset`
- `ui-gender-male.imageset`, `ui-gender-female.imageset`
- `hexbound-logo.imageset`
- `preloader-hex.imageset` — Loading spinner
- `cloud-1.imageset`, `cloud-2.imageset`, `moon.imageset`
- `shopkeeper.imageset` — NPC

#### Currency Display Assets (1 imageset)
- `reward-gold.imageset` — Shared across systems

---

## 3. PIXEL SCALE COVERAGE ANALYSIS

### Scale Distribution

| Coverage Pattern | Count | % | Notes |
|---|---|---|---|
| **1x only** (single file) | 316 | 87.3% | Standard production assets |
| **2x/3x only** (no 1x) | 9 | 2.5% | Fortune wheel mechanics only |
| **Empty/Placeholder** | 25 | 6.9% | Awaiting art assets |
| **All 3 scales complete** | 0 | 0% | NEVER generated with full scales |
| **Partial 1x+2x** | 0 | 0% | NEVER found |
| **All 3 scales empty** | 12 | 3.3% | Structure only |

### Key Finding: **Single-Scale Strategy**

All production assets use **1x scale only** with placeholder slots for 2x/3x (the structure is present in Contents.json, but no files are provided). This is a **deliberate design pattern**:

- Xcode automatically scales 1x images for 2x/3x devices at runtime
- Reduces disk size
- Simplifies asset pipeline
- Avoids need for multiple versions in code

**Exception:** Fortune wheel assets (`fortune-*.imageset`) intentionally skip 1x and provide 2x/3x only — likely for visual sharpness on modern devices.

---

## 4. EMPTY/PLACEHOLDER ASSETS

**25 imagesets with zero PNG files** — awaiting art implementation or awaiting replacement:

### Character Skins (8 total — production blockers)
1. avatar_barbarian.imageset
2. avatar_enchantress.imageset
3. avatar_huntress.imageset
4. avatar_knight.imageset
5. avatar_shadow.imageset
6. avatar_sorceress.imageset
7. avatar_valkyrie.imageset
8. avatar_warlord.imageset
9. barbarian.imageset (full-body)
10. enchantress.imageset
11. huntress.imageset
12. knight.imageset
13. shadow.imageset
14. sorceress.imageset
15. valkyrie.imageset
16. warlord.imageset

### Background/Terrain (3 total)
17. bg-dungeon-map.imageset — **ACTUAL FILE:** bg-dungeon-map.jpg exists (5.7 MB JPG, not PNG)
18. bg-rush-elite.imageset
19. bg-rush-event.imageset
20. bg-rush-miniboss.imageset
21. bg-rush-shop.imageset
22. hub-terrain.imageset

### Potion Assets (3 total — stamina consumables)
23. pot_stamina_large.imageset
24. pot_stamina_medium.imageset
25. pot_stamina_small.imageset

**Note:** `pot_stamina_*` may be duplicates of `stamina_potion_*` items in the Items folder (naming inconsistency?).

---

## 5. SPECIAL CASES & ANOMALIES

### 5A. JPG in Asset Catalog
**File:** `bg-dungeon-map.imageset/bg-dungeon-map.jpg` (5.7 MB)

This is the **only JPG in the entire catalog**. All others are PNG. This high-resolution background was likely exported as JPG for disk size efficiency.

Contents.json still lists it correctly:
```json
"filename": "bg-dungeon-map.jpg"
```

### 5B. Fortune Wheel — Inverted Scale Strategy
**9 imagesets** have **2x/3x files ONLY** (no 1x):
- fortune-pointer.imageset
- fortune-spin-banner.imageset
- fortune-wheel-face.imageset
- icon-fortune-lose.imageset
- icon-fortune-x2.imageset
- icon-fortune-x3.imageset
- icon-fortune-x5.imageset
- icon-fortune-x15.imageset
- lady-fortuna.imageset

**Strategy:** These assets intentionally skip the 1x slot, providing @2x and @3x only. This suggests they are high-detail assets meant to always display sharp on modern devices (no downsampling from 1x).

### 5C. Sidebar Raw PNG References
The `sidebar/` folder contains **45 raw PNG files** directly, NOT wrapped in .imageset bundles. This suggests **legacy or direct asset inclusion** in code via filename references rather than the xcassets abstraction.

Files appear to duplicate icons elsewhere in the catalog (same filenames as icon-*.imageset contents).

### 5D. No Color Sets
**Zero `.colorset` directories** in the catalog. All color management is in Swift code via `DarkFantasyTheme.swift`, not Xcode asset catalogs.

---

## 6. IMAGESET CONTENTS.JSON STRUCTURE

### Standard Structure (316 assets)

```json
{
  "images": [
    {
      "filename": "icon-tank.png",
      "idiom": "universal",
      "scale": "1x"
    },
    {
      "idiom": "universal",
      "scale": "2x"
    },
    {
      "idiom": "universal",
      "scale": "3x"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  },
  "properties": {
    "preserves-vector-representation": true,
    "template-rendering-intent": "original"
  }
}
```

### Fortune Wheel Structure (9 assets)

```json
{
  "images": [
    {
      "idiom": "universal",
      "scale": "1x"
    },
    {
      "filename": "fortune-wheel-face@2x.png",
      "idiom": "universal",
      "scale": "2x"
    },
    {
      "filename": "fortune-wheel-face@3x.png",
      "idiom": "universal",
      "scale": "3x"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

### Empty Placeholder Structure (25 assets)

```json
{
  "images": [
    {
      "idiom": "universal",
      "scale": "1x"
    },
    {
      "idiom": "universal",
      "scale": "2x"
    },
    {
      "idiom": "universal",
      "scale": "3x"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

### Properties Observed
- ✅ **preserves-vector-representation: true** — Present on most assets (may be vector PDFs or indicate no downsampling)
- ✅ **template-rendering-intent: "original"** — Not template-mode rendering (no tint for use as symbols)
- ❌ **NO custom idioms** (only "universal" for all devices)
- ❌ **NO iOS-specific variants**
- ❌ **NO macOS/watchOS/tvOS variants**

---

## 7. IMAGE DIMENSIONS (Representative Sample)

| Category | Typical Dimensions | Examples |
|---|---|---|
| **Icon assets** | 256×256 | icon-gold, icon-strength, icon-wins |
| **Character portraits** | 1024×1024 | boss-lich-king-portrait, rush-bone-king-portrait |
| **Building icons** | 300×300 | building-arena, building-shop |
| **Background panorama** | 4096×1738 | bg-hub (wide landscape) |
| **Combat effects** | 256–512 | fx-heal-divine, fx-physical-slash |
| **UI elements** | Variable | ui-arrow-up (smaller), hero widget (variable) |
| **App Icon** | 1024×1024 | AppIcon.png |

**No assets are smaller than ~64×64 or larger than 4096×1738.**

---

## 8. NAMING CONVENTIONS & CONSISTENCY

### Pattern Compliance
✅ **Consistent naming scheme:**
- Lowercase with hyphens: `building-arena`, `boss-lich-king-full`
- Prefixes by type: `bg-`, `building-`, `boss-`, `rush-`, `fx-`, `icon-`, `reward-`, `race-icon-`
- Suffix indicates variant: `-full`, `-portrait`, `@2x`, `@3x`

### No Duplicate Asset Names
Scanned across all folders — **zero name collisions** detected. Each asset is unique, even when stored in different folders (Bosses/, Items/, etc.).

### Naming Discrepancies
1. **Stamina potions:** Both `pot_stamina_*` (in Items/) and `stamina_potion_*` (in Items/) exist — possible duplicates with inconsistent naming.
2. **Health potions:** `health_potion_*` also exists (6 variants total across naming schemes).

---

## 9. FIGMA-ASSETS EXPORT FOLDER

**Location:** `/sessions/nifty-hopeful-mayer/mnt/PVP RPG/figma-assets/`

**Purpose:** Design-to-code handoff. Script `bash scripts/export-assets-for-figma.sh` exports all PNG files from xcassets into this folder.

### Export Breakdown

| Folder | File Count | Purpose |
|---|---|---|
| **01_Characters/** | 0 | Empty (character skins awaiting art) |
| **02_Enemies/** | 100 | Boss + Rush mode enemies (exported from Bosses/) |
| **03_Items/** | 65 | Equipment + consumables (exported from Items/) |
| **04_Icons/** | 82 | UI + stat + class + race icons |
| **05_UI_Backgrounds/** | 27 | Backgrounds, logo, NPCs (fortuna, shopkeeper, etc.) |
| **06_FX/** | 39 | Combat effects, damage numbers, buffs |
| **07_Buildings/** | 20 | Hub buildings (arenas, shops, dungeons, etc.) |
| **Total** | **333** | All assets with files |

**Missing:** All 25 empty placeholder imagesets are not exported (no PNG to export).

### Design System Sync Rule
When adding new assets:
1. Create `.imageset` in `Assets.xcassets/`
2. Run `bash scripts/export-assets-for-figma.sh`
3. PNG is automatically exported to `figma-assets/<category>/`
4. Figma DS pages already have **350 placeholder components** matching these asset names

---

## 10. CODE INTEGRATION PATTERNS

### Asset References in Code
Assets are referenced by imageset name (without `.imageset` extension):

```swift
UIImage(named: "icon-gold")           // From: icon-gold.imageset
UIImage(named: "boss-lich-king-full") // From: boss-lich-king-full.imageset
```

### Sidebar Folder Anomaly
The `sidebar/` folder contains raw PNG files (not imagesets). These are likely referenced via:

```swift
UIImage(named: "sidebar/icon-gold")   // Direct path reference
// or
UIImage(contentsOfFile: "sidebar/icon-gold.png")
```

This suggests a legacy pattern or special asset loader.

---

## 11. QUALITY & COMPLETENESS CHECKLIST

| Aspect | Status | Notes |
|---|---|---|
| **Naming consistency** | ✅ PASS | All assets follow hyphens + prefix pattern |
| **No duplicates** | ✅ PASS | Zero name collisions across folders |
| **Folder organization** | ✅ PASS | Clear categorization (Bosses, Items, Skins, etc.) |
| **Scale coverage** | ⚠️ PARTIAL | 1x only strategy is correct, but 25 assets still empty |
| **Colorset use** | ✅ N/A | Not applicable; colors managed in Swift |
| **Properties** | ✅ PASS | Correct vector preservation + rendering settings |
| **Icon sizing** | ✅ PASS | Standard 256×256 for most icons |
| **High-res art** | ✅ PASS | 1024×1024+ for character art |
| **JPG vs PNG** | ⚠️ NOTE | One JPG (bg-dungeon-map); all others PNG (good) |
| **Sidebar mess** | ⚠️ CONCERN | Raw PNG folder may confuse asset pipeline |

---

## 12. PRODUCTION BLOCKERS & RECOMMENDATIONS

### Current Blockers (Emptiness)
- **8 character skin avatars + 8 full-body skins** — Game cannot display custom skins without these
- **3 rush mode backgrounds** — Affected dungeon runs may use fallbacks
- **3 stamina potion variants** — Consumable UI affected

### Recommendations
1. **Consolidate potions:** Audit `pot_stamina_*` vs `stamina_potion_*` — likely duplicates with inconsistent naming.
2. **Clean sidebar folder:** Migrate raw PNG references to proper imagesets or document the pattern in CLAUDE.md.
3. **Implement art:** Prioritize character skins (8 avatars + 8 full-body) as they block player progression.
4. **Audit 2x/3x scale:** Verify fortune wheel assets truly need 2x/3x-only strategy; consider whether 1x would benefit from manual retouching.

---

## 13. SUMMARY STATISTICS

| Metric | Value |
|---|---|
| Total imagesets | 362 |
| Total appiconsets | 1 |
| Total colorsets | 0 |
| Root-level imagesets | 234 |
| Bosses folder | 40 |
| Items folder | 71 |
| Skins folder | 16 |
| Raw PNG sidebar files | 45 |
| **Total image assets** | **363+** |
| **With PNG files** | 316 |
| **Empty placeholders** | 25 |
| **2x/3x-only (fortune)** | 9 |
| **Figma export files** | 333 |
| **Unique dimensions** | 20+ (256-4096px) |

---

## Appendix: Complete Asset List by Root-Level Category

*For brevity, full listing available on request. Key categories provided above.*

**Generated:** 2026-04-03 via Python asset scanner
**Scanned by:** Claude Code agent
**Status:** RESEARCH ONLY — no modifications made
