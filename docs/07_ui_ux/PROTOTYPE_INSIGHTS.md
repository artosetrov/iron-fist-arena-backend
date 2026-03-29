# Prototype Insights Archive

> Extracted from 67 HTML/JSX/MD prototype files in project root (2026-03-21 — 2026-03-28).
> Original files deleted after extraction. This is the canonical reference.

## 1. Input Field Token System

Full input field spec (not yet in production):
- Height: **56px**, border-radius: 10px, padding: `0 14px`
- Background: layered radial-gradient (`bgTertiary` → `bgSecondary`) + surface lighting
- Default border: `0 0 0 1px borderSubtle` (inset shadow, not CSS border)
- **Focused:** `goldDim` border + `gold 0.15` outer ring + `gold 0.12` glow (18px)
- **Error:** `danger 0.5` border + red 12px glow
- **Valid:** `success 0.45` border + green 10px glow
- Floating label: starts center-left, animates on focus to top-left (10px, uppercase)
- Corner L-brackets appear **only on focus** (opacity 0→1)
- Caret color: `gold`

## 2. Back Button — Option D (Etched Shield)

Recommended pattern for navigation back button:
- 40×40pt rounded square (radius 10), `bgSecondary` fill, 1px `goldDim55` border
- `SurfaceLighting` (0.06/0.08), `brightness(0.94)` press
- Arrow: 22px `textPrimary`, not gold
- Title centering: right spacer must match back button width for optical centering

## 3. Arena Opponent Card Layout

- Full-bleed avatar background, 172pt wide × 280pt tall
- Bottom gradient: transparent → bgAbyss (4-stop)
- Rating: 28px Oswald bold — dominant visual
- Press: `translateY(-4px)` lift + `brightness(0.94)`, spring 200ms
- Animated conic gradient border for selected card
- Class accent colors: Warrior `#E68C33`, Rogue `#4DD958`, Mage `#6680FF`, Tank `#9999B2`
- Rank colors: Bronze `#B38040`, Silver `#BFBFCC`, Gold `#FFD700`, Platinum `#66CCCC`

## 4. Bar System Variants

### Engraved Stone Trough (recommended dark fantasy style)
- Inset shadow: `inset 0 2px 4px rgba(0,0,0,0.7), inset 0 -1px 0 rgba(255,255,255,0.04)`
- Stone texture: repeating hairline segments every 18px
- Liquid shimmer: bright streak moving left→right in 3s
- Meniscus: 6px soft glow at fill edge
- Stone cap elements framing the trough

### HP Bar Color States
- Full (>50%): `#2ECC71 → #55EFC4` (green)
- Medium (25-50%): `#E67E22 → #F1C40F` (amber)
- Critical (<25%): `#C0392B → #E74C3C` (red) + pulsing glow

## 5. Chat / Messaging Typography

- Message body: `Crimson Text` serif font (lore/manuscript feel)
- Online status dot: bottom-right of avatar, 10pt, 2pt border
  - Online <5min: success; Away <30min: `#f39c12`; Offline: textTertiary

## 6. Dungeon Rush Room Colors

| Room Type | Color | Glow |
|-----------|-------|------|
| Elite | `#f97316` (orange) | `rgba(249,115,22,0.35)` |
| Boss | `#9333ea` (purple) | `rgba(147,51,234,0.35)` |
| Treasure | `#d97706` (amber) | `rgba(217,119,6,0.3)` |
| Event | `#0ea5e9` (sky blue) | `rgba(14,165,233,0.3)` |
| Shop | `#14b8a6` (teal) | `rgba(20,184,166,0.3)` |
| Danger | `#dc2626` (red) | `rgba(220,38,38,0.35)` |

## 7. Floating Dust Particle System

Recipe for ambient particles (used in portals, ceremonies):
- 14 particles, gold (`#D4A537`) + purple (`#8B5CF6`) 50/50
- Opacity: 0.08–0.28; Size: 2–5px; Duration: 8–20s
- Larger (>3px) get `blur(1px)`
- Keyframe: 0→1 at 15%, peak at 50%, 1 at 85%, 0 at 100%

## 8. Product Audit Key Findings (2026-03-27)

### Balance
- Mage dual-stat: `INT×1.4 + WIS×0.5` = effective 1.9× vs Warrior 1.5× — WIS should be ×0.25
- Tank vs Tank = timeout (turn 15 cap). Fix: escalation +10% damage/turn after turn 10
- CHA gold bonus has no ceiling — cap at +50% or use diminishing returns

### Economy
- L25 player accumulates ~1,100g/day surplus → 33,000g in 30 days
- F2P earns ~216 gems/month → Battle Pass every 2.3 months (possibly too generous)
- Gold sinks needed: stat reroll (500–2,000g), enchanting, cosmetic gold shop

### Monetization
- No "first purchase" trigger — industry standard: Starter Bundle $0.99, 5–10× value, 48hr timer
- Gold packs bad value vs F2P earning — reposition as "Instant Gear Bundle"

### Matchmaking
- Rating NOT used — only level (±10) + gear score (±80%). Fix: primary rating ±200

### Retention
- No FTUE quest chain — recommend 7-day guided quest with specific rewards
- No live events — start with config-driven "Double Gold Weekend"

## 9. Multi-Hero Architecture Decisions

- Auto-select when user has exactly 1 hero (skip selection)
- After character creation → return to CharacterSelection, not Hub
- DELETE /api/characters/:id — Phase 2 (cascades: inventory, quests, history)
- Guest banner on CharacterSelection: visible but non-blocking
- Max 5 characters per user

## 10. Landing Page Art Style

Separate from in-game pen-and-ink:
- **Landing style:** "Caricature grotesque fantasy cartoon, thick black outlines, watercolor shading"
- Generator: ChatGPT (DALL-E) with reference images
- 27 assets needed, pipeline: DALL-E → remove.bg → ImageMagick → cwebp -q 85
- OG image: 1200×630, logo added in Figma post-generation

## 11. UX Bugs from Audits (not yet fixed)

- Upgrade sound plays before server result (server-authoritative violation)
- `catalogId` visible to users in ItemDetailSheet description — wrap in `#if DEBUG`
- No sell confirmation for rare+ items
- Consumable items don't show effect preview ("Restores 50 HP")
- LootPreviewSheet missing item type badge
- Leaderboard search has no debounce (every keystroke → API call, needs 300ms)
- CharacterSelectionView `.task` doesn't re-fire on return from creation
- Appearance Editor `randomize()` may change gender (should only change skin)
