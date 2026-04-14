---
title: Design System
category: entities
tags: [ui, theme, tokens, colors, typography, spacing]
sources: [Hexbound/Hexbound/Theme/DarkFantasyTheme.swift, docs/07_ui_ux/DESIGN_SYSTEM.md]
updated: 2026-04-14
---

# Design System

Dark Fantasy Premium theme. All UI uses `DarkFantasyTheme` tokens — never hardcoded values.

## Color Palette

### Backgrounds
| Token | Hex | Use |
|-------|-----|-----|
| `bgAbyss` | #08080C | Deepest black |
| `bgPrimary` | #0D0D12 | Main background |
| `bgSecondary` | #1A1A2E | Card/panel fill |
| `bgTertiary` | #16213E | Elevated surfaces |
| `bgElevated` | #1E2240 | Overlays |

### Gold System
| Token | Hex | Use |
|-------|-----|-----|
| `gold` | #D4A537 | Primary accent |
| `goldBright` | #FFD700 | CTA highlights |
| `goldDim` | #8B6914 | Muted gold |

### Feedback
| Token | Hex |
|-------|-----|
| `danger` | #E63946 |
| `success` | #2ECC71 |
| `info` | #3498DB |
| `cyan` | #00D4FF |
| `purple` | #9B59B6 |

### Text
| Token | Hex |
|-------|-----|
| `textPrimary` | #F5F5F5 |
| `textSecondary` | #A0A0B0 |
| `textTertiary` | #6B6B80 |
| `textOnGold` | #1A1A2E |
| `textDisabled` | #555566 |

### Zone Colors
| Zone | Token | Hex |
|------|-------|-----|
| Head | `zoneHead` | #E66666 (red) |
| Chest | `zoneChest` | #6699E6 (blue) |
| Legs | `zoneLegs` | #66E666 (green) |

## Typography

Two font families: **Oswald** (headers, uppercase) + **Inter** (body).

| Token | Font | Size | Use |
|-------|------|------|-----|
| `cinematicTitle` | Oswald | 40 | Full-screen ceremonies |
| `title` | Oswald | 28 | Screen titles |
| `section` | Oswald | 22 | Section headers |
| `cardTitle` | Oswald | 18 | Card headers |
| `buttonLabel` | Oswald | 18 | Button text |
| `body` | Inter | 16 | Body text |
| `uiLabel` | Inter | 14 | Labels |
| `caption` | Inter | 12 | Captions |
| `badge` | Inter | 11 bold | Badges |

**Minimum font: 16px** for readable text (exceptions: badge 11pt).

## Spacing Scale

| Token | Value |
|-------|-------|
| `spaceXS` | 4 |
| `spaceSM` | 8 |
| `spaceMS` | 12 |
| `spaceMD` | 16 |
| `spaceLG` | 24 |
| `spaceXL` | 32 |
| `space2XL` | 48 |

Key: `screenPadding` = 16, `sectionGap` = 16, `cardRadius` = 12, `modalRadius` = 16.

## Ornamental System

Pure SwiftUI — no PNG assets for UI chrome:
- `RadialGlowBackground` — replaces flat fills
- `SurfaceLightingOverlay` — convex top-bright/bottom-dark
- `CornerBracketOverlay`, `CornerDiamondOverlay` — edge accents
- `InnerBorderOverlay` — inset gradient stroke
- `BarFillHighlight` — top-edge shine on progress bars

## Opacity Scale

9-point: `opacityMicro` (0.04) → `opacityOpaque` (0.85).

## Pill System

`pill()` factory: 10 variants (heal, urgent, energy, stat, warn, pvp, streak, bonus, error, offline) × 3 layers (bg, border, text).

## See Also

- [[screens]]
- [[classes]] (zone colors)
