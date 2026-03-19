# Hexbound — UI Design Document

> **Version:** 3.0 — AAA Quality Standard
> **Platform:** Mobile (iOS, Portrait 1170×2532)
> **Engine:** Godot 4.3+
> **Quality Target:** Blizzard-tier UI (Diablo IV, Path of Exile 2, World of Warcraft, Baldur's Gate 3)
> **Status:** Reflects actual implemented code + planned screens

---

## Table of Contents

0. [AAA Visual Design Language](#0-aaa-visual-design-language) — Core principles, materials, typography, button/card/panel systems
1. [Screen Map](#1-screen-map) — Full navigation diagram
2. [Screen Definitions](#2-screen-definitions) — 26 screens with ASCII wireframes, elements, actions
3. [User Flows](#3-user-flows) — 6 core player journeys
4. [Design Tokens (AAA)](#4-design-tokens-aaa-standard) — Colors, typography, spacing, shadows, animations
5. [Interaction States & Feedback](#5-interaction-states--feedback) — Button/card/tab/input states, toast, haptic, loading
6. [Visual Material & Surface Design](#6-visual-material--surface-design) — Material implementation, ornaments, particles, VFX
7. [Figma Implementation Notes](#7-figma-implementation-notes) — Page structure, components, naming, auto-layout, workflow

---

## 0. AAA Visual Design Language

### Core Principles

| Principle | Description |
|---|---|
| **Maximum Readability** | Player understands any screen in under 3 seconds. Large type, high contrast, zero ambiguity. |
| **Clear Visual Hierarchy** | Title → Section Header → Card → Body → Caption. Every element has an obvious rank. |
| **Large Interactive Elements** | Minimum touch target 48×48dp. Primary buttons are 56dp+ tall. No tiny text links. |
| **Minimal Cognitive Load** | Maximum 4-6 actions visible at once. Group related actions. Hide complexity behind tabs/panels. |
| **Fast Navigation** | Hub → any screen in 1 tap. Any screen → Hub in 1 tap. No dead ends. |
| **Cinematic Immersion** | Dark fantasy world, not a flat modern app. Every surface tells a story. |

### Visual Style — Dark Fantasy Premium

**Material Language:**
| Material | Usage | Texture Reference |
|---|---|---|
| Dark Stone | Screen backgrounds, deep panels | Obsidian, volcanic rock — nearly black with subtle grain |
| Worn Metal | Borders, frames, dividers | Aged iron, hammered steel — subtle scratches and patina |
| Engraved Frames | Card borders, section headers | Ornamental gothic engravings — like Diablo IV inventory frames |
| Parchment | Info panels, tooltips, descriptions | Aged yellowed paper — warm tone behind readable text |
| Leather | Button surfaces, interactive cards | Dark tooled leather — warm brown with subtle stitch lines |
| Enchanted Crystal | Accent elements, gems, premium features | Glowing crystalline facets — purple/cyan inner light |

**Surface Effects:**
| Effect | Usage | Implementation |
|---|---|---|
| Subtle Outer Glow | Active/selected items, gold accents | 4-8px blur, 20-40% opacity, accent color |
| Soft Inner Shadow | Panels, inset containers | 2-4px offset, 50% opacity black |
| Metallic Highlight | Borders, divider lines | 1px bright line on top edge of dark borders |
| Magical Particles | Premium features, legendary items, victory | Floating ember/sparkle particle overlay |
| Vignette | Screen edges, focus areas | Radial gradient from transparent center to dark edges |
| Engraved Inset | Section headers, ornamental dividers | Beveled inset text/pattern on dark stone |

### Typography Scale (AAA Standard)

All text must be **immediately readable on mobile without squinting.** Thin/light weights are forbidden.

| Level | Font | Weight | Size | Line Height | Use | Letter Spacing |
|---|---|---|---|---|---|---|
| **Cinematic Title** | Cinzel | Bold | 40px | 48px | Victory/Defeat, Screen hero titles | +2px |
| **Screen Title** | Cinzel | Bold | 28px | 34px | Top-of-screen titles: "ARENA", "INVENTORY" | +1.5px |
| **Section Header** | Oswald | SemiBold | 22px | 28px | Panel headers: "Core Stats", "Rewards" | +1px |
| **Card Title** | Oswald | Medium | 18px | 24px | Item names, character names, dungeon names | +0.5px |
| **Button Label** | Oswald | SemiBold | 18px | 22px | All button text, UPPERCASE mandatory | +2px |
| **Body Text** | Inter | Medium | 16px | 22px | Descriptions, flavor text, instructions | 0 |
| **UI Label** | Inter | SemiBold | 14px | 18px | Stat labels, filter tags, small info | +0.5px |
| **Caption** | Inter | Medium | 12px | 16px | Timestamps, version numbers, fine print | 0 |
| **Badge** | Inter | Bold | 11px | 14px | Notification counts, "NEW" badges | +0.5px |

> **Rule:** Never use font weight below Medium (500). Never use size below 11px. Body text and button labels must be 16px+.

### Color Intensity Rules

| Context | Minimum Contrast Ratio | Notes |
|---|---|---|
| Primary text on background | 7:1 (WCAG AAA) | #F5F5F5 on #0D0D12 = 15.3:1 ✓ |
| Secondary text on background | 4.5:1 (WCAG AA) | #A0A0B0 on #0D0D12 = 7.8:1 ✓ |
| Button label on button bg | 4.5:1 | Dark text on gold: #1A1A2E on #D4A537 = 5.2:1 ✓ |
| Gold accent on dark panel | 4.5:1 | #FFD700 on #1A1A2E = 8.7:1 ✓ |

### Navigation Architecture

```
┌─────────────────────────────────────────┐
│              BOTTOM NAV BAR             │
│  (Persistent across ALL game screens)   │
│                                         │
│  🏠 HUB    👤 HERO    🏆 RANKS         │
│                                         │
│  Always visible. Gold icon = active.    │
│  Gray icon = inactive. Large 48px       │
│  touch targets with labels below.       │
└─────────────────────────────────────────┘

Navigation Depth Rule:
  Hub → Screen = 1 tap (maximum)
  Screen → Sub-screen = 1 tap
  Any screen → Hub = 1 tap (bottom nav or back)

  Maximum depth: 3 levels
  Level 1: Hub
  Level 2: Arena / Dungeon / Inventory / Shop / etc.
  Level 3: Combat / Item Detail / Dungeon Room
```

### Button Design System

**Primary Button (CTA — Call to Action):**
```
┌─────────────────────────────────┐
│  ══════════════════════════════  │  ← Ornamental top border (gold engraving)
│                                 │
│         ⚔ ENTER ARENA ⚔        │  ← UPPERCASE, Oswald SemiBold 18px, centered
│                                 │  ← Dark leather texture background
│  ══════════════════════════════  │  ← Ornamental bottom border
└─────────────────────────────────┘
Height: 56px minimum
Padding: 24px horizontal, 16px vertical
Corner radius: 8px
Background: Gold gradient (#D4A537 → #B8860B)
Text: Dark (#1A1A2E)
Border: 2px ornamental gold frame
Shadow: 0 4px 12px rgba(212, 165, 55, 0.3)
```

**Secondary Button:**
```
Height: 48px
Background: Transparent
Border: 1px solid #D4A537 (gold outline)
Text: Gold (#D4A537), Oswald SemiBold 16px
Hover: Background fills to 10% gold
```

**Danger Button:**
```
Height: 48px
Background: #E63946 (crimson)
Text: White
Use for: Sell, Logout, Destroy
```

**Disabled State (any button):**
```
Opacity: 40%
Background: #333340 (dark gray)
Text: #555566
No hover/press effects
```

### Card Design System

**Standard Game Card (Items, Opponents, Dungeons):**
```
┌──── Metallic Border Frame ──────┐
│ ┌────────────────────────────┐  │
│ │                            │  │
│ │  [Icon/Art]  ITEM NAME     │  │  ← Card title: Oswald 18px
│ │              EPIC WEAPON   │  │  ← Subtitle: Inter 14px, rarity color
│ │              Level 12      │  │  ← Caption: Inter 12px
│ │                            │  │
│ │  ─── ornamental divider ───│  │  ← Thin engraved line
│ │                            │  │
│ │  STR +15    AGI +5         │  │  ← Stat row: Inter SemiBold 14px
│ │                            │  │
│ └────────────────────────────┘  │
│                                 │
│  [    ACTION BUTTON    ]        │  ← Primary button inside card
└─────────────────────────────────┘

Background: --bg-tertiary (#16213E) with subtle noise texture
Border: 2px solid, color varies by rarity
  Common:    #555566 (dim iron)
  Uncommon:  #4DCC4D (green glow)
  Rare:      #4D80FF (blue glow)
  Epic:      #A64DE6 (purple glow)
  Legendary: #FFBF1A (gold glow, animated pulse)
Corner radius: 12px
Inner padding: 16px
Shadow: 0 2px 8px rgba(0,0,0,0.5)
```

### Panel Design System

**Info Panel (Stats, Rewards, Derived Info):**
```
Background: #0D0D12 (deepest black) with stone texture
Border: 1px solid #2A2A3E (subtle iron)
Border-top: 1px solid #3A3A50 (metallic highlight — top edge catch light)
Corner radius: 8px
Padding: 16px
Header: Oswald SemiBold 18px, gold color, with ornamental underline
```

**Overlay Modal (Item Detail, Daily Login):**
```
Backdrop: #000000 at 75% opacity
Panel: --bg-secondary (#1A1A2E) with worn metal frame
Border: 3px ornamental frame in gold/iron
Corner radius: 16px
Shadow: 0 8px 32px rgba(0,0,0,0.8)
Animation: Scale 0.9→1.0 + fade 0→1 over 300ms ease-out
```

### Progress Bar Design

**HP Bar:**
```
Track: #1A1A2E with 1px #2A2A3E border
Height: 12px
Corner radius: 6px (fully rounded)
Fill gradient:
  >60%: #2ECC71 → #27AE60 (green)
  30-60%: #F1C40F → #F39C12 (amber)
  <30%: #E74C3C → #C0392B (red) with pulse animation
Shine: 1px white line at 10% opacity on top edge of fill (metallic reflection)
```

**XP Bar:**
```
Same structure as HP but:
Fill: #9B59B6 → #8E44AD (purple gradient)
```

**Stamina Bar:**
```
Fill: #E67E22 → #D35400 (orange gradient)
```

---

## 1. Screen Map

```
                        ┌──────────────┐
                        │ Splash Screen│
                        └──────┬───────┘
                               │
                        ┌──────▼───────┐
                   ┌────│ Login Screen  │────┐
                   │    └──────┬───────┘    │
                   │           │            │
            ┌──────▼──┐ ┌─────▼─────┐ ┌────▼─────┐
            │ Register │ │ Guest     │ │ Forgot   │
            │ Screen   │ │ Login     │ │ Password │
            └──────┬───┘ └─────┬─────┘ └──────────┘
                   │           │
                   └─────┬─────┘
                         │ (No character?)
                  ┌──────▼────────────────┐
                  │  Onboarding (4 steps) │
                  │ Race→Gender→Class→Name│
                  └──────┬────────────────┘
                         │
          ┌──────────────▼──────────────────────────────────┐
          │                  HUB SCREEN                     │
          │              (Central Navigation)               │
          └─┬──────┬──────┬──────┬──────┬──────┬──────┬────┘
            │      │      │      │      │      │      │
     ┌──────▼┐ ┌──▼───┐ ┌▼─────┐│ ┌────▼──┐ ┌▼────┐ │
     │Arena  │ │Dung- │ │Inven-││ │Leader-│ │Sett-│ │
     │Screen │ │eon   │ │tory  ││ │board  │ │ings │ │
     └──┬────┘ │Select│ │Screen││ └───────┘ └─────┘ │
        │      └──┬───┘ └──┬───┘│                    │
        │         │        │    │                    │
   ┌────▼────┐ ┌──▼─────┐ ┌▼────▼──┐  ┌─────────┐  │
   │Opponent │ │Dungeon │ │Equip-  │  │ Profile │  │
   │Cards    │ │Room    │ │ment    │  │ Screen  │  │
   └────┬────┘ └──┬─────┘ │Screen  │  └─────────┘  │
        │         │       └────────┘                │
   ┌────▼─────────▼────┐              ┌─────────────┤
   │   Combat Screen   │              │             │
   └────────┬──────────┘    ┌─────────▼──┐  ┌──────▼────┐
            │               │Daily Quests│  │Achieve-   │
   ┌────────▼──────────┐    └────────────┘  │ments      │
   │  Combat Result    │                    └───────────┘
   └────────┬──────────┘    ┌────────────┐  ┌───────────┐
            │               │Battle Pass │  │Daily Login│
   ┌────────▼──────────┐    └────────────┘  │(Popup)    │
   │   Loot Screen     │                    └───────────┘
   └───────────────────┘    ┌────────────┐  ┌───────────┐
                            │  Shop      │  │Shell Game │
                            │  Screen    │  │(Minigame) │
                            └────────────┘  └───────────┘
                            ┌────────────┐  ┌───────────┐
                            │Gold Mine   │  │Dungeon    │
                            │(Minigame)  │  │Rush(Mini) │
                            └────────────┘  └───────────┘
```

---

## 2. Screen Definitions

---

### 2.1 — Splash Screen

**Purpose:** Brand introduction, loading assets, auto-login check.
**Source:** `scenes/main/splash_screen.gd`

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│                                 │
│         ⚔  IRON FIST  ⚔        │
│            A R E N A            │
│                                 │
│        [Particle Effects]       │
│                                 │
│                                 │
│                                 │
│                                 │
│        ─── Tap to Start ───     │
│                                 │
│          Version 1.0.0          │
└─────────────────────────────────┘
```

**UI Elements:**
| Element | Type | Notes |
|---|---|---|
| Game Logo | Image | Centered, animated glow effect |
| Subtitle | Label | "A R E N A" with letter-spacing |
| Particles | VFX | Ember/flame particles behind logo |
| Tap Prompt | Label | Pulsing opacity animation |
| Version | Label | Bottom-center, small text |
| Loading Bar | ProgressBar | Shown during asset load, hidden after |

**Actions:**
- Tap anywhere → Auto-login check via `AuthManager`
- Token found + valid → Fetch character → `HubScreen`
- Token found + expired → `LoginScreen`
- No token → `LoginScreen`

**Navigation:**
- → `LoginScreen` (no saved token)
- → `HubScreen` (valid saved token + existing character)
- → `OnboardingScreen` (valid token but no character)

---

### 2.2 — Login Screen

**Purpose:** Player authentication via email/password, registration, or guest access.
**Source:** `scenes/auth/login_screen.gd`

```
┌─────────────────────────────────┐
│                                 │
│         ⚔ IRON FIST ⚔          │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 📧 Email                  │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ 🔒 Password               │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │        ⚔ LOG IN ⚔         │  │
│  └───────────────────────────┘  │
│                                 │
│       Forgot Password?          │
│                                 │
│  ── ── ── ── OR ── ── ── ──    │
│                                 │
│  ┌───────────────────────────┐  │
│  │     CREATE ACCOUNT        │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │     PLAY AS GUEST         │  │
│  └───────────────────────────┘  │
│                                 │
│    Error message area           │
│                                 │
└─────────────────────────────────┘
```

**UI Elements:**
| Element | Type | Notes |
|---|---|---|
| Logo | Image | Smaller version of splash logo |
| Email Input | TextInput | Placeholder "Email", keyboard: email type |
| Password Input | TextInput | Placeholder "Password", toggle visibility icon |
| Login Button | Button | Primary CTA, gold/amber style |
| Forgot Link | TextButton | Navigates to password reset flow |
| Divider | HRule | "OR" separator line |
| Register Button | Button | Secondary style, outlined border |
| Guest Button | Button | Tertiary/ghost style |
| Error Label | Label | Red text, hidden by default, shows validation/API errors |
| Loading Spinner | Spinner | Overlay during auth API requests |
| Email Confirmation | Label | "Check your email to confirm" after registration |

**Actions:**
- Login → Validate fields → `AuthManager.login(email, password)` → Route based on character
- Register → Validate email + password match → `AuthManager.register()` → Show confirmation
- Guest → `AuthManager.guest_login()` → Always → `OnboardingScreen`
- Forgot Password → Password reset flow

**Navigation:**
- → `HubScreen` (existing character found)
- → `OnboardingScreen` (new account, no character)

---

### 2.3 — Onboarding Screen (Character Creation)

**Purpose:** New player creates a hero through a 4-step wizard: Race → Gender/Avatar → Class → Name.
**Source:** `scenes/auth/onboarding_screen.gd`

#### Step 1 of 4: Choose Race

```
┌─────────────────────────────────┐
│  ◀ Back        CREATE HERO      │
│─────────────────────────────────│
│      Step 1 of 4: Choose Race   │
│          ● ○ ○ ○                │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 😈 HUMAN                  │  │
│  │ +2 CHA  +1 LUK            │  │
│  │ Adaptable and charismatic. │  │
│  │ Bonus to gold & diplomacy. │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ 👹 ORC                    │  │
│  │ +3 STR  -1 CHA            │  │
│  │ Brutal and powerful. Born  │  │
│  │ warriors with primal str. │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ 💀 SKELETON               │  │
│  │ +2 END  +1 INT            │  │
│  │ Undying resilience.        │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ 😈 DEMON                  │  │
│  │ +2 INT  +1 STR            │  │
│  │ Infernal power. Dark magic │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ 🐕 DOGFOLK                │  │
│  │ +2 AGI  +1 WIS            │  │
│  │ Pack hunters. Enhanced     │  │
│  │ senses and swift reflexes. │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │       CONTINUE ▶          │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**UI Elements (Step 1):**
| Element | Type | Notes |
|---|---|---|
| Back Button | TextButton | "< Back", returns to LoginScreen |
| Title | Label | "CREATE HERO" in Cinzel gold |
| Step Label | Label | "Step 1 of 4: Choose Race" |
| Progress Dots | ProgressDots | 4 dots, first filled gold |
| Race Cards (×5) | SelectableCard | Vertical scrollable list, gold border on selected |
| Race Icon | Emoji/Image | Per race (skull, demon face, etc.) |
| Race Name | Label | Bold, white text |
| Stat Bonuses | Label | Gold text, e.g. "+2 CHA +1 LUK" |
| Description | Label | Secondary text, 1-2 lines flavor |
| Continue Button | Button | Bottom-pinned, disabled until selection, gold style |

**Race Data:**
| Race | Bonuses | Description |
|---|---|---|
| Human | +2 CHA, +1 LUK | Adaptable and charismatic. Bonus to gold and diplomacy. |
| Orc | +3 STR, -1 CHA | Brutal and powerful. Born warriors with primal strength. |
| Skeleton | +2 END, +1 INT | Undying resilience. Immune to poison, resistant to bleed. |
| Demon | +2 INT, +1 STR | Infernal power. Dark magic runs through their veins. |
| Dogfolk | +2 AGI, +1 WIS | Pack hunters. Enhanced senses and swift reflexes. |

#### Step 2 of 4: Choose Gender & Avatar

```
┌─────────────────────────────────┐
│  ◀ Back        CREATE HERO      │
│─────────────────────────────────│
│    Step 2 of 4: Choose Gender   │
│          ● ● ○ ○                │
│                                 │
│  ┌──────────┐  ┌──────────┐    │
│  │ ♂ MALE   │  │ ♀ FEMALE │    │
│  └──────────┘  └──────────┘    │
│                                 │
│        Choose Avatar            │
│                                 │
│  ┌──────────┐  ┌──────────┐    │
│  │          │  │          │    │
│  │ [Photo]  │  │ [Photo]  │    │
│  │          │  │          │    │
│  │ WARLORD  │  │ KNIGHT   │    │
│  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐    │
│  │          │  │          │    │
│  │ [Photo]  │  │ [Photo]  │    │
│  │          │  │          │    │
│  │BARBARIAN │  │ SHADOW   │    │
│  └──────────┘  └──────────┘    │
│                                 │
│  ┌───────────────────────────┐  │
│  │       CONTINUE ▶          │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**UI Elements (Step 2):**
| Element | Type | Notes |
|---|---|---|
| Gender Toggle | ToggleGroup | 2 pill buttons: Male / Female. Selected = gold fill, unselected = outlined |
| Gender Icons | Icon | ♂ / ♀ symbols before labels |
| "Choose Avatar" | Label | Section subtitle, centered |
| Avatar Cards (×4) | SelectableCard | 2×2 grid of dark fantasy character portrait photos |
| Avatar Image | Image | Full-bleed photo in card with rounded corners |
| Avatar Name | Label | Bottom of card, centered, white bold text with shadow |
| Selected State | Border | Gold border + subtle glow on selected avatar |
| Continue Button | Button | Disabled until both gender and avatar selected |

**Avatar Sets:**
| Gender | Avatar 1 | Avatar 2 | Avatar 3 | Avatar 4 |
|---|---|---|---|---|
| Male | Warlord | Knight | Barbarian | Shadow |
| Female | Valkyrie | Sorceress | Enchantress | Huntress |

> Avatar selection is cosmetic only — no stat impact. Gender determines which 4-avatar set is shown.

#### Step 3 of 4: Choose Class

```
┌─────────────────────────────────┐
│  ◀ Back        CREATE HERO      │
│─────────────────────────────────│
│    Step 3 of 4: Choose Class    │
│          ● ● ● ○                │
│                                 │
│  ┌──────────┐  ┌──────────┐    │
│  │    ⚔     │  │    🗡️    │    │
│  │ WARRIOR  │  │  ROGUE   │    │
│  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐    │
│  │    🔮    │  │    🛡️    │    │
│  │  MAGE    │  │   TANK   │    │
│  └──────────┘  └──────────┘    │
│                                 │
│  ┌───────────────────────────┐  │
│  │ WARRIOR                   │  │
│  │ +3 STR  +2 VIT            │  │
│  │ Masters of melee combat.  │  │
│  │ Fearless front-liners who │  │
│  │ crush foes with raw power.│  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │       CONTINUE ▶          │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**UI Elements (Step 3):**
| Element | Type | Notes |
|---|---|---|
| Class Cards (×4) | SelectableCard | 2×2 grid, icon + label per card |
| Class Icon | Icon/Emoji | ⚔ Warrior, 🗡️ Rogue, 🔮 Mage, 🛡️ Tank |
| Selected State | Border | Gold border on selected card |
| Info Panel | Panel | Appears below grid when class selected |
| Class Name | Label | Bold white |
| Stat Bonuses | Label | Gold text "+3 STR +2 VIT" |
| Description | Label | Secondary text, flavor description |
| Continue Button | Button | Disabled until class selected |

**Class Data:**
| Class | Bonuses | Description |
|---|---|---|
| Warrior | +3 STR, +2 VIT | Masters of melee combat. Fearless front-liners who crush foes with raw power. |
| Rogue | +3 AGI, +2 LUK | Silent and deadly. Strike from the shadows with precision and speed. |
| Mage | +3 INT, +2 WIS | Wielders of arcane power. Devastate enemies with elemental magic. |
| Tank | +3 VIT, +2 END | Living fortresses. Absorb punishment and protect allies with iron will. |

#### Step 4 of 4: Name Hero

```
┌─────────────────────────────────┐
│  ◀ Back        CREATE HERO      │
│─────────────────────────────────│
│    Step 4 of 4: Name Hero       │
│          ● ● ● ●                │
│                                 │
│  Choose a name for your hero    │
│  (max 16 characters)            │
│                                 │
│  ┌───────────────────────────┐  │
│  │        Degon|              │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │         DEGON              │  │
│  │    Female Orc Warrior      │  │
│  │  +3 STR +2 VIT | +3 STR   │  │
│  │       -1 CHA               │  │
│  └───────────────────────────┘  │
│                                 │
│                                 │
│                                 │
│  ┌───────────────────────────┐  │
│  │         CONFIRM            │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**UI Elements (Step 4):**
| Element | Type | Notes |
|---|---|---|
| Instruction | Label | "Choose a name for your hero (max 16 characters)" |
| Name Input | TextInput | Gold border, centered text, max 16 chars, Cinzel font |
| Summary Panel | Panel | Dark panel with full hero summary |
| Hero Name | Label | Large, Cinzel bold, centered |
| Race/Class/Gender | Label | "Female Orc Warrior" — secondary text |
| Combined Stats | Label | Gold text, class bonuses + race bonuses separated by pipe |
| Confirm Button | Button | Full-width gold, "CONFIRM", creates character via API |

**Actions across all steps:**
- Select race → Gold highlight, show bonuses → Enable Continue
- Select gender → Load matching 4-avatar set → Select avatar → Enable Continue
- Select class → Show stat bonuses + description in info panel → Enable Continue
- Enter name → Summary panel updates live → Confirm → `POST /api/characters` → `HubScreen`
- Back on any step → Returns to previous step
- Back on step 1 → Returns to `LoginScreen`

**Navigation:**
- ← `LoginScreen` (back on step 1)
- → `HubScreen` (after character created on step 4)

---

### 2.4 — Hub Screen (Main Menu)

**Purpose:** Central navigation hub. Shows character summary, currencies, quick actions, and access to all game systems.
**Source:** `scenes/hub/hub_screen.gd`

```
┌─────────────────────────────────┐
│ ⚙                          🔔³ │
│                                 │
│  ┌──────┐ Lv.15 DEGON           │
│  │ [Ava-│ Orc Warrior           │
│  │ tar] │                       │
│  └──────┘                       │
│  ████████████████████░░  340/450│
│  STA ██████████████░░░░  87/100 │
│  XP  █████████████░░░░  780/850 │
│                                 │
│  ┌──────────────────────────┐   │
│  │ 💰 12,450  💎 23  🏆 1,240│   │
│  └──────────────────────────┘   │
│                                 │
│  ┌────────────┐ ┌────────────┐  │
│  │    ⚔       │ │    🏰      │  │
│  │  ARENA     │ │  DUNGEONS  │  │
│  │ PvP Battle │ │  Explore   │  │
│  └────────────┘ └────────────┘  │
│  ┌────────────┐ ┌────────────┐  │
│  │    🗡️      │ │    🛒      │  │
│  │ TRAINING   │ │   SHOP     │  │
│  │ Practice   │ │ Buy & Sell │  │
│  └────────────┘ └────────────┘  │
│                                 │
│  ┌─ Daily Quest Progress ── ▶─┐ │
│  │ ████████░░░░░░░░░    2/4   │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ ⚡ Season 1 Battle Pass ─▶─┐│
│  │ Exclusive rewards await!    ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─ 🟢 First Win Bonus ──────┐ │
│  │ First Win Bonus available!  │ │
│  └────────────────────────────┘ │
│                                 │
│─────────────────────────────────│
│   🏠        👤        🏆       │
│   HUB      HERO     LEADER     │
└─────────────────────────────────┘
```

**UI Elements:**
| Element | Type | Node | Notes |
|---|---|---|---|
| Settings Icon | IconButton | top-left | Gear icon ⚙, navigates to SettingsScreen |
| Notification Bell | IconButton | top-right | 🔔 with red badge count (e.g. "3") |
| Character Avatar | Image | left of name | Class avatar in rounded frame with dark border |
| Character Name | Label | `character_name_label` | "Lv.15 DEGON" — level prefix + Cinzel bold gold |
| Class/Race | Label | `class_label`, `race_label` | "Orc Warrior" — secondary gray text |
| HP Bar | ProgressBar | `hp_bar` | Full-width, green gradient, value right-aligned "340/450" |
| Stamina Bar | ProgressBar | `stamina_bar` | Full-width, orange/yellow gradient, "STA" prefix left, "87/100" right |
| XP Bar | ProgressBar | `xp_bar` | Full-width, purple gradient, "XP" prefix left, "780/850" right |
| Currency Row | Panel | contains 3 values | Horizontal row with gold (💰), gems (💎), PvP rating (🏆) |
| Gold | Label | `gold_label` | 💰 coin icon + "12,450" (formatted with commas) |
| Gems | Label | `gems_label` | 💎 diamond icon + "23" |
| PvP Rating | Label | `rating_label` | 🏆 trophy icon + "1,240" |
| Arena Tile | NavTile | `arena_btn` | Large card, icon ⚔ + "ARENA" title + "PvP Battle" subtitle |
| Dungeons Tile | NavTile | `dungeon_btn` | Icon 🏰 + "DUNGEONS" + "Explore" |
| Training Tile | NavTile | `train_button` | Icon 🗡️ + "TRAINING" + "Practice" |
| Shop Tile | NavTile | `shop_btn` | Icon 🛒 + "SHOP" + "Buy & Sell" |
| Daily Quest Progress | Banner | `quests_btn` | Tappable row with progress bar, "2/4" text, arrow ▶ |
| Battle Pass Banner | Banner | tappable | Purple/gold gradient card, ⚡ icon + "Season 1 Battle Pass" + "Exclusive rewards await!" + arrow ▶ |
| First Win Banner | Banner | `first_win_banner` | Gold-tinted row, green dot 🟢 + "First Win Bonus available!" |
| Bottom Nav Bar | TabBar | 3 tabs | 🏠 HUB (active), 👤 HERO, 🏆 LEADER — centered icons + labels |

**Nav Tile Layout (2×2 Grid):**
Each tile is a rounded dark card with:
- Center icon (custom icon, not emoji — Godot icons or imported SVG)
- Title below icon (bold, white, uppercase)
- Subtitle below title (small, gray)
- Subtle dark border with slight highlight on press

```
┌────────────┐ ┌────────────┐
│    [icon]  │ │    [icon]  │
│   ARENA    │ │  DUNGEONS  │
│  PvP Battle│ │   Explore  │
└────────────┘ └────────────┘
┌────────────┐ ┌────────────┐
│    [icon]  │ │    [icon]  │
│  TRAINING  │ │    SHOP    │
│  Practice  │ │ Buy & Sell │
└────────────┘ └────────────┘
```

**Bottom Navigation Bar:**
| Tab | Icon | Label | Action |
|---|---|---|---|
| Hub | 🏠 (house) | HUB | Current screen (active state) |
| Hero | 👤 (person with shield) | HERO | → `CharacterScreen` |
| Leader | 🏆 (trophy) | LEADER | → `LeaderboardScreen` |

Active tab: Gold icon + gold label. Inactive tabs: Gray icon + gray label.

**Actions:**
| Action | Trigger | Behavior |
|---|---|---|
| Settings | ⚙ icon press | → `SettingsScreen` |
| Notifications | 🔔 icon press | → Notification panel (planned) |
| Arena | Arena tile press | → `ArenaScreen` |
| Dungeons | Dungeons tile press | → `DungeonSelectScreen` |
| Training | Training tile press | Check stamina ≥ 5 → Deduct 5 STA → Generate mock combat (67% win) → `CombatScreen` |
| Shop | Shop tile press | → `ShopScreen` |
| Daily Quests | Quest progress banner tap | → `DailyQuestsScreen` |
| Battle Pass | Battle Pass banner tap | → `BattlePassScreen` |
| Character Panel | Avatar/name area tap | → `CharacterScreen` |
| Bottom Nav: Hero | Hero tab press | → `CharacterScreen` |
| Bottom Nav: Leader | Leader tab press | → `LeaderboardScreen` |

**Data Refresh:**
- Listens to `CacheManager.cache_updated` signal to refresh all displayed data
- On `_ready()`: loads character from `GameManager.current_character` or `CacheManager`
- Training combat generates mock NPC: random class/race, level ±2, HP 150-250

**Mock Training Combat:**
- Generates 6-12 turns per fight
- Damage: 15-40 per hit, 20% crit chance (2x damage), 12% miss chance
- Status effects: bleed, stun, burn
- Win rewards: 50-100 gold, 40-70 XP
- Loss rewards: 10 gold, 15 XP

**Daily Login Popup:**
- Auto-triggered on first session of each day
- Shows as overlay modal (see section 2.20)

---

### 2.5 — Character Screen

**Purpose:** View and allocate stats, view derived stats. Inspired by Diablo IV's character panel.
**Source:** `scenes/hub/character_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back        CHARACTER         │
│─────────────────────────────────│
│                                 │
│    DarkBlade                    │
│    Warrior • Orc                │
│    Level 15                     │
│    XP ████████░░ 780/850        │
│    Prestige: 0                  │
│    Stat Points: 6               │
│                                 │
│  ┌─ Core Stats (4-col grid) ──┐ │
│  │ STR  38   [−]  [+]         │ │
│  │ AGI  22   [−]  [+]         │ │
│  │ VIT  30   [−]  [+]         │ │
│  │ END  18   [−]  [+]         │ │
│  │ INT  12   [−]  [+]         │ │
│  │ WIS  15   [−]  [+]         │ │
│  │ LUK  14   [−]  [+]         │ │
│  │ CHA  11   [−]  [+]         │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ Derived Stats (2-col) ────┐ │
│  │ Max HP        450           │ │
│  │ Armor         24            │ │
│  │ Magic Resist  15            │ │
│  │ Max Stamina   120           │ │
│  │ Crit Chance   7.0%          │ │
│  │ Dodge         6.6%          │ │
│  │ PvP Rating    1240          │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐  │
│  │    ⚔ SET STANCE ⚔         │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │    💾 SAVE CHANGES         │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**UI Elements:**
| Element | Type | Node | Notes |
|---|---|---|---|
| Character Name | Label | `char_name_label` | Bold header |
| Class • Race | Label | `class_race_label` | "Class • Origin" format |
| Level | Label | `level_label` | "Level X" |
| XP Bar | ProgressBar | `xp_bar` | Max = 100 + level × 50 |
| Prestige | Label | `prestige_label` | Visible only if prestige > 0 |
| Stat Points | Label | `stat_points_label` | "Stat Points: X", highlighted when > 0 |
| Stats Grid | GridContainer | `stats_grid` | 4 columns: Name \| Value \| [−] \| [+] |
| Stat Values | Label[] | dynamic | Green if increased from original, white if unchanged |
| [+] Buttons | Button[] | dynamic | Disabled if stat_points == 0 |
| [−] Buttons | Button[] | dynamic | Disabled if stat == original value |
| Derived Grid | GridContainer | `derived_grid` | 2 columns: Name \| Value, read-only |
| Set Stance | Button | via signal | → Opens `StanceSelectorScreen` |
| Save Button | Button | `save_button` | Disabled until changes made. `PATCH /api/characters/{id}/allocate-stats` |
| Back Button | Button | `back_button` | → `HubScreen` |

**Stat Colors:**
| Stat | Color (RGB) |
|---|---|
| STR | (0.9, 0.35, 0.3) — Red |
| AGI | (0.3, 0.9, 0.4) — Green |
| VIT | (0.9, 0.5, 0.5) — Pink |
| END | (0.7, 0.7, 0.3) — Yellow |
| INT | (0.4, 0.5, 1.0) — Blue |
| WIS | (0.6, 0.4, 0.9) — Purple |
| LUK | (0.9, 0.85, 0.3) — Gold |
| CHA | (0.9, 0.6, 0.8) — Light Pink |

**Derived Stat Formulas:**
| Derived Stat | Formula |
|---|---|
| Max HP | VIT × 15 |
| Armor | STR × 0.5 + END × 0.3 |
| Magic Resist | WIS × 0.5 + INT × 0.2 |
| Max Stamina | Fixed 120 |
| Crit Chance | LUK × 0.5% |
| Dodge | AGI × 0.3% |

---

### 2.6 — Stance Selector

**Purpose:** Choose attack zone and defense zone for combat.
**Source:** `scenes/hub/stance_selector.gd`

```
┌─────────────────────────────────┐
│ ◀ Back       COMBAT STANCE      │
│─────────────────────────────────│
│                                 │
│      ATTACK ZONE                │
│   ┌──────┐ ┌──────┐ ┌──────┐   │
│   │ HEAD │ │CHEST │ │ LEGS │   │
│   │  🔴  │ │      │ │      │   │
│   └──────┘ └──────┘ └──────┘   │
│                                 │
│      DEFENSE ZONE               │
│   ┌──────┐ ┌──────┐ ┌──────┐   │
│   │ HEAD │ │CHEST │ │ LEGS │   │
│   │      │ │  🔵  │ │      │   │
│   └──────┘ └──────┘ └──────┘   │
│                                 │
│  Attack: Head | Defense: Chest  │
│                                 │
│  ┌───────────────────────────┐  │
│  │      SAVE STANCE ⚔        │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**Zone Colors:**
| Zone | Color |
|---|---|
| Head | Red — RGB(0.9, 0.4, 0.4) |
| Chest | Blue — RGB(0.4, 0.6, 0.9) |
| Legs | Green — RGB(0.4, 0.9, 0.4) |

**UI States:**
- Selected zone: 100% opacity, colored text in zone color
- Unselected zone: 50% opacity, default text
- Summary updates live: "Attack: X | Defense: Y"
- Save button: Disabled until changed from current stance
- Save feedback: Text changes to "Saved!" for 1 second, then resets

**API:** `POST /api/characters/{id}/stance` with `{"attack": zone, "defense": zone}`

**Navigation:** Back → `CharacterScreen`

---

### 2.7 — Inventory Screen

**Purpose:** Browse, filter, sort, and manage all items. Inspired by Diablo IV's grid inventory.
**Source:** `scenes/inventory/inventory_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back         INVENTORY        │
│─────────────────────────────────│
│ 💰 12,450 gold                  │
│─────────────────────────────────│
│ [All][Wpn][Helm][Chest][Glvs]   │
│ [Legs][Boots][Acc][Amlt][Ring]   │
│─────────────────────────────────│
│                                 │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌────┐│
│ │[E]W │ │  H  │ │  C  │ │ Ri ││
│ │Epic │ │Rare │ │Com  │ │Leg ││
│ │Lv12 │ │Lv10 │ │Lv8  │ │Lv15││
│ │+3   │ │+1   │ │+0   │ │+5  ││
│ └─────┘ └─────┘ └─────┘ └────┘│
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌────┐│
│ │  B  │ │  G  │ │  A  │ │ Am ││
│ │Unco │ │Rare │ │Epic │ │Com ││
│ │Lv6  │ │Lv9  │ │Lv11 │ │Lv3 ││
│ └─────┘ └─────┘ └─────┘ └────┘│
│                                 │
│  ┌───────────────────────────┐  │
│  │    🛡️ VIEW EQUIPMENT       │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Filter Tabs (10):**
| Key | Label | Filters |
|---|---|---|
| all | All | Everything |
| weapon | Wpn | weapon |
| helmet | Helm | helmet |
| chest | Chest | chest |
| gloves | Glvs | gloves |
| legs | Legs | legs |
| boots | Boots | boots |
| accessory | Acc | accessory |
| amulet | Amlt | amulet |
| ring | Ring | ring |

**Sort Order:** Equipped items first → by rarity (legendary > epic > rare > uncommon > common) → by level

**Item Card (per item in grid):**
| Element | Notes |
|---|---|
| Icon Letter | W/H/C/G/L/B/A/Am/Be/R/N/Ri — colored by rarity |
| Rarity Frame | Background tinted with rarity color at 25% alpha |
| Item Name | Rarity-colored, "[E] " prefix if equipped, "+X" suffix if upgraded |
| Level | "Lv.X" |
| Border | 1px rarity color at 40% opacity |

**Item Card Signals:** `item_pressed(item_data)` → Opens `ItemDetailModal`

**Navigation:**
- Back → `HubScreen`
- View Equipment → `EquipmentScreen`

---

### 2.8 — Item Detail Modal

**Purpose:** Full item stats, comparison with equipped item, equip/sell actions.
**Source:** `scenes/inventory/item_detail_modal.gd`

```
┌─────────────────────────────────┐
│              ✕ Close             │
│─────────────────────────────────│
│                                 │
│     🗡️ Shadowfang Blade +3      │
│     ══════════════════          │
│     EPIC                        │
│     Weapon                      │
│     Level 12                    │
│                                 │
│  ┌─ Stats ────────────────────┐ │
│  │ STR   +15        ▲ +8     │ │
│  │ AGI   +5         ▲ +2     │ │
│  │ CRIT  +3.0%      ▲ +1.5%  │ │
│  └────────────────────────────┘ │
│                                 │
│  Set: Shadow Warrior            │
│                                 │
│  "Bleeds target for 3 turns"    │
│  Passive: +5% lifesteal         │
│                                 │
│  Sell: 850 gold                 │
│                                 │
│ ┌────────────┐ ┌──────────────┐ │
│ │  ⚔ EQUIP   │ │  💰 SELL     │ │
│ └────────────┘ └──────────────┘ │
└─────────────────────────────────┘
```

**UI Elements:**
| Element | Type | Notes |
|---|---|---|
| Overlay | ColorRect | Semi-transparent click-to-close background |
| Close Button | Button | Top-right X |
| Item Name | Label | Rarity-colored, "+X" if upgraded |
| Rarity | Label | Capitalized, rarity-colored |
| Type | Label | Capitalized item type |
| Level | Label | "Level X" |
| Stat Rows | Dynamic | Stat name + "+value" per stat |
| Comparison Deltas | Label | "▲ +X" green (better) or "▼ -X" red (worse) vs equipped |
| Set Name | Label | "Set: {name}" (visible if set_name exists) |
| Special Effect | Label | Italic text (visible if exists) |
| Unique Passive | Label | "Passive: ..." (visible if exists) |
| Sell Price | Label | "Sell: X gold" |
| Equip Button | Button | Shows "Equip" or "Unequip" based on `is_equipped` |
| Sell Button | Button | Disabled if item is equipped |

**Signals emitted:**
- `item_equipped(item)` — triggers equip API call
- `item_unequipped(item)` — triggers unequip API call
- `item_sold(item)` — removes from inventory, adds gold
- `modal_closed()` — closes overlay

**Rarity Colors:**
| Rarity | Color |
|---|---|
| Common | Gray (0.6, 0.6, 0.6) |
| Uncommon | Green (0.3, 0.8, 0.3) |
| Rare | Blue (0.3, 0.5, 1.0) |
| Epic | Purple (0.65, 0.3, 0.9) |
| Legendary | Gold (1.0, 0.75, 0.1) |

---

### 2.9 — Equipment Screen

**Purpose:** Visual display of all 12 equipment slots with stat summary.
**Source:** `scenes/inventory/equipment_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back        EQUIPMENT         │
│─────────────────────────────────│
│                                 │
│  ┌─ 12 Slots (3-col grid) ───┐ │
│  │                            │ │
│  │ [Helmet]  [Amulet] [Weapon]│ │
│  │                            │ │
│  │ [Chest]  [Off-hand][Gloves]│ │
│  │                            │ │
│  │ [Belt]    [Ring]   [Legs]  │ │
│  │                            │ │
│  │[Necklace] [Boots]  [Relic] │ │
│  │                            │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ Equipment Bonuses ────────┐ │
│  │ STR +42   AGI +18          │ │
│  │ VIT +25   END +12          │ │
│  │ INT +8    WIS +5           │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐  │
│  │    🎒 OPEN INVENTORY       │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Slot Order (3 columns × 4 rows):**
| Col 1 | Col 2 | Col 3 |
|---|---|---|
| Helmet | Amulet | Weapon |
| Chest | Off-hand | Gloves |
| Belt | Ring | Legs |
| Necklace | Boots | Relic |

**Per Slot Display:**
- Slot label (e.g. "Helmet")
- Item name + "+X" upgrade (rarity-colored) or "— Empty —" (gray)
- Tap filled slot → `ItemDetailModal` (with Unequip)
- Tap empty slot → no action (could navigate to filtered inventory)

**Equipment Bonuses Panel:**
- Header: "Equipment Bonuses"
- 4-column grid: stat name (uppercase) + "+value" (green) for each stat contributed by all equipped items (base + rolled stats combined)

**Navigation:**
- Back → `InventoryScreen`
- Open Inventory → `InventoryScreen`

---

### 2.10 — Arena Screen (PvP)

**Purpose:** PvP matchmaking with opponent selection, revenge list, and match history.
**Source:** `scenes/arena/arena_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back           ARENA  ⚔       │
│─────────────────────────────────│
│                                 │
│  Rating: 1240                   │
│  Rank: Gold (gold color)        │
│  Free: 2/3 (green)             │
│  First Win: x2! (yellow)       │
│  STA: 87/120                    │
│                                 │
│ [Opponents] [Revenge] [History] │
│─────────────────────────────────│
│                                 │
│  ┌───────────────────────────┐  │
│  │ ShadowBlade               │  │
│  │ Lv.14 Rogue Human         │  │
│  │ Rating: 1180               │  │
│  │              [⚔ FIGHT]    │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ IronGuard                 │  │
│  │ Lv.16 Tank Orc            │  │
│  │ Rating: 1310               │  │
│  │              [⚔ FIGHT]    │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ FireMage                  │  │
│  │ Lv.13 Mage Demon          │  │
│  │ Rating: 1150               │  │
│  │              [⚔ FIGHT]    │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │     🔍 FIND MATCH          │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**UI Elements:**
| Element | Node | Notes |
|---|---|---|
| Rating | `rating_label` | "Rating: X" |
| Rank | `rank_label` | Color-coded by tier |
| Free PvP | `free_pvp_label` | "Free: X/3" — green if >0, gray if 0 |
| First Win | `first_win_label` | "First Win: x2!" (yellow) or "First Win: Done" (gray) |
| Stamina | `stamina_label` | "STA: X/Y" |
| Tab Buttons | `tab_opponents/revenge/history` | Active=100% opacity, inactive=50% |
| Opponent Cards | dynamic in `opponents_list` | Name, class, race, level, rating, fight button |
| Revenge Cards | dynamic in `revenge_list` | Same + "Xh remaining" timer |
| History Cards | dynamic in `history_list` | Result + opponent + rating change |
| Find Match | `find_match_btn` | Disables during search, text="Searching..." |
| Empty Label | `empty_label` | Shows when list is empty |

**Rank Tiers:**
| Rank | Min Rating | Color |
|---|---|---|
| Bronze | 0 | RGB(0.7, 0.5, 0.3) |
| Silver | 1100 | RGB(0.75, 0.75, 0.8) |
| Gold | 1300 | RGB(1.0, 0.84, 0.0) |
| Platinum | 1500 | RGB(0.4, 0.8, 0.8) |
| Diamond | 1700 | RGB(0.6, 0.8, 1.0) |
| Grandmaster | 2000 | RGB(1.0, 0.3, 0.3) |

**Opponent Card Layout (`opponent_card.gd`):**
- Character Name (white, 20px)
- "Lv.X ClassName Origin" (15px, class-colored: warrior=orange, rogue=green, mage=blue, tank=gray)
- "Rating: X" (14px, gray)
- Fight Button (140×60, gold style)

**PvP Combat Flow:**
- Fight → Check: free PvP remaining (no stamina cost) OR stamina ≥ 10
- Generate 7-14 combat turns, damage 18-45, 16% crit (2x), 12% miss
- Status effects on crits: 33% chance of bleed/stun/burn
- → `CombatScreen`

**Mock Opponents:** ShadowBlade (warrior), IronGuard (tank), FireMage (mage), SwiftDagger (rogue)

**Navigation:**
- Back → `HubScreen`
- Fight → `CombatScreen`

---

### 2.11 — Combat Screen

**Purpose:** Animated turn-by-turn combat. Used for PvP, PvE training, and dungeon encounters.
**Source:** `scenes/combat/combat_screen.gd` + `combat_animation_player.gd`

```
┌─────────────────────────────────┐
│  [1x Speed]        [▶▶ Skip]   │
│─────────────────────────────────│
│                                 │
│  ┌──────────┐   ┌──────────┐   │
│  │  ENEMY   │   │   YOU    │   │
│  │ ┌──────┐ │   │ ┌──────┐ │   │
│  │ │class │ │   │ │class │ │   │
│  │ │color │ │   │ │color │ │   │
│  │ └──────┘ │   │ └──────┘ │   │
│  │IronGolem │   │DarkBlade │   │
│  │Lv.16 Tank│   │Lv.15 War│   │
│  │HP 340/400│   │HP 280/340│   │
│  │██████░░░ │   │█████░░░░ │   │
│  └──────────┘   └──────────┘   │
│                                 │
│        Turn 5 / 15              │
│                                 │
│  ┌─ Status Effects ───────────┐ │
│  │ BLD(2)  BRN(1)             │ │
│  └────────────────────────────┘ │
│                                 │
│       [-45 CRIT!]               │
│       [DODGE!]                  │
│       [+20 heal]                │
│                                 │
└─────────────────────────────────┘
```

**UI Elements:**
| Element | Node | Notes |
|---|---|---|
| Player Name | `player_name_label` | Character name |
| Player Class | `player_class_label` | "Lv.X ClassName" |
| Player Avatar | `player_avatar` | ColorRect tinted by class color |
| Player HP Bar | `player_hp_bar` | Green→Yellow→Red gradient |
| Player HP Label | `player_hp_label` | "current / max" |
| Player Status | `player_status` | HBoxContainer of status icons |
| Enemy (same set) | `enemy_*` | Same layout, left side |
| Turn Counter | `turn_counter_label` | "Turn X / Y" |
| Turn Label | `turn_label` | "Fight!", "Your turn" (green), "Enemy turn" (red), "VICTORY!", "DEFEAT" |
| Speed Button | `speed_button` | Toggles 1x/2x speed |
| Skip Button | `skip_button` | Skips to result, becomes "Continue" after combat |

**Class Avatar Colors:**
| Class | Color |
|---|---|
| Warrior | #E68C33 (orange) |
| Rogue | #4DD958 (green) |
| Mage | #6680FF (blue) |
| Tank | #9999B2 (gray) |

**Combat Animation Details (`CombatAnimationPlayer`):**
| Animation | Timing |
|---|---|
| Attacker slide forward | 40px, 0.15s |
| Defender flash white | 0.15s |
| Crit screen shake | 4 tweens, 0.04s each |
| Damage popup float up + fade | 0.7s |
| HP bar smooth tween | 0.3s |
| Between-turn delay | 0.3s |

**Speed Modes:**
| Mode | Speed Multiplier | Skip? |
|---|---|---|
| 1x (normal) | 1.0 | No |
| 2x (fast) | 0.5 | No |
| Skip (instant) | 0.0 | Yes |

**Damage Popup Format:**
- Regular: "-45" in damage color
- Critical: "-90 CRIT!" in larger font
- Miss: "MISS" in gray
- Dodge: "DODGE" in blue
- Heal: "+20" in green

**Status Effect Icons (3-letter codes):**
| Effect | Code | Color |
|---|---|---|
| Bleed | BLD | Red |
| Burn | BRN | Orange |
| Stun | STN | Yellow |
| Poison | PSN | Green |
| Freeze | FRZ | Cyan |

**Navigation:** → `CombatResultScreen` (after all turns complete, via "Continue" button)

---

### 2.12 — Combat Result Screen

**Purpose:** Show victory/defeat, rewards earned, XP gains, and level-up.
**Source:** `scenes/combat/combat_result_screen.gd`

```
┌─────────────────────────────────┐
│                                 │
│        ⚔ VICTORY! ⚔             │
│   You defeated IronGolem!       │
│                                 │
│  ┌─ Rewards ──────────────────┐ │
│  │ Gold Earned:       +350    │ │
│  │ XP Earned:         +120    │ │
│  │ Turns:             8       │ │
│  │ First Win Bonus!   x2     │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ LEVEL UP! → Level 16 ────┐ │
│  │ (animated banner)          │ │
│  └────────────────────────────┘ │
│                                 │
│  Rating: +25 (green)            │
│                                 │
│  ┌───────────────────────────┐  │
│  │     🗡️ VIEW LOOT           │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │      CONTINUE ▶            │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**UI Elements:**
| Element | Node | Notes |
|---|---|---|
| Result Title | `result_label` | "VICTORY!" (gold) or "DEFEAT" (red) |
| Subtitle | `subtitle_label` | "You defeated {name}!" or "Better luck next time..." |
| Rewards | `rewards_container` | Dynamic rows: Gold (gold color), XP (cyan), Turns (gray) |
| First Win Bonus | dynamic row | "First Win Bonus!" + "x2" (orange), only if applicable |
| Level Up | `level_up_label` | "LEVEL UP! → Level X" (visible only on level up) |
| Rating Change | `rating_change_label` | "+X" (green) or "-X" (red), only for PvP |
| Loot Button | `loot_button` | Visible only if loot exists in combat result |
| Continue Button | `continue_button` | Returns to source screen |

**Continue Navigation (source-based):**
| Source | Destination |
|---|---|
| "arena" | `ArenaScreen` |
| "training" | `HubScreen` |
| "dungeon" | `DungeonRoomScreen` (next floor) |
| default | `HubScreen` |

---

### 2.13 — Loot Screen

**Purpose:** Dramatic item reveal with animation.
**Source:** `scenes/combat/loot_screen.gd`

```
┌─────────────────────────────────┐
│                                 │
│       ✨ Loot Dropped! ✨        │
│                                 │
│  ┌─────┐ ┌─────┐ ┌─────┐      │
│  │     │ │     │ │     │      │
│  │ 🗡️  │ │ 🛡️  │ │ 💍  │      │
│  │Epic │ │Rare │ │Leg  │      │
│  │Lv12 │ │Lv10 │ │Lv15 │      │
│  └─────┘ └─────┘ └─────┘      │
│                                 │
│  ┌───────────────────────────┐  │
│  │     📦 TAKE ALL            │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │      CONTINUE ▶            │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Reveal Animation per item:**
- Scale: 0.3 → 1.0 over 500ms (bounce ease)
- Alpha: 0 → 1 over 500ms
- Stagger: 250ms delay per item (item 0 at 0ms, item 1 at 250ms, etc.)

**Actions:**
- Take All → Adds all loot to `CacheManager` inventory → Disables button, shows "Collected!" → Auto-continue
- Continue → Clears combat data → Returns to source screen (arena or hub)

---

### 2.14 — Dungeon Select Screen

**Purpose:** Choose dungeon, difficulty, and enter dungeon run. Also provides access to minigames.
**Source:** `scenes/dungeon/dungeon_select_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back         DUNGEONS 🏰      │
│─────────────────────────────────│
│  STA: 100/120                   │
│                                 │
│  Difficulty:                    │
│  [Easy 15] [Normal 20] [Hard 25]│
│─────────────────────────────────│
│                                 │
│  ┌─ 💀 Crypt of Shadows ─────┐  │
│  │  Min Level: 1               │  │
│  │  Progress: ██░░░ 2/5        │  │
│  │  Boss: Lich King Verath     │  │
│  │           [Enter 20 STA]    │  │
│  └────────────────────────────┘ │
│  ┌─ 🔥 Volcanic Forge ───────┐  │
│  │  Min Level: 10              │  │
│  │  Progress: ░░░░░░ 0/7      │  │
│  │  Boss: Magma Titan Pyrox    │  │
│  │           [Enter 20 STA]    │  │
│  └────────────────────────────┘ │
│  ┌─ ❄ Frozen Abyss ──────────┐  │
│  │  Min Level: 20              │  │
│  │  Progress: ░░░░░░░░ 0/9    │  │
│  │  Boss: Frost Wyrm Glacius   │  │
│  │           [Enter 20 STA]    │  │
│  └────────────────────────────┘ │
│                                 │
│─── Minigames ───────────────────│
│ [🐚 Shell Game][⛏ Mine][⚡Rush] │
│                                 │
└─────────────────────────────────┘
```

**Dungeon Data:**
| Dungeon | Icon | Min Lv | Floors | Boss | Theme Color |
|---|---|---|---|---|---|
| Crypt of Shadows | 💀 (S) | 1 | 5 | Lich King Verath | Purple (0.5, 0.3, 0.7) |
| Volcanic Forge | 🔥 (F) | 10 | 7 | Magma Titan Pyrox | Orange (1.0, 0.4, 0.15) |
| Frozen Abyss | ❄ (I) | 20 | 9 | Frost Wyrm Glacius | Blue (0.3, 0.7, 1.0) |

**Difficulty Stamina Costs:**
| Difficulty | Cost/Floor |
|---|---|
| Easy | 15 STA |
| Normal | 20 STA |
| Hard | 25 STA |

**Per Dungeon Card:**
- Icon letter (S/F/I) in theme color
- Dungeon name
- Min level requirement (red if under-leveled)
- Progress bar: "boss_index / floors"
- Boss name: "Boss: {name}"
- Enter button: "Enter\n{sta_cost} STA"

**Navigation:**
- Enter dungeon → `DungeonRoomScreen` (via `GameManager.combat_data`)
- Shell Game → `ShellGameScreen`
- Gold Mine → `GoldMineScreen` (placeholder)
- Dungeon Rush → `DungeonRushScreen` (placeholder)
- Back → `HubScreen`

---

### 2.15 — Dungeon Room Screen

**Purpose:** Floor-by-floor dungeon progression with enemy encounters and mini-map.
**Source:** `scenes/dungeon/dungeon_room_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Retreat     Crypt of Shadows  │
│         Floor 3 / 5             │
│─────────────────────────────────│
│                                 │
│  Mini-map:                      │
│  [1]──[2]──[3]──[4]──[B]       │
│   ✓    ✓    ●    ○    ○        │
│  (green)(grn)(ylw)(gray)(gray)  │
│                                 │
│  ┌─ Enemy ────────────────────┐ │
│  │                            │ │
│  │         SK                 │ │
│  │    Shadow Knight           │ │
│  │    Level 12  |  HP: 150    │ │
│  │                            │ │
│  │  Loot: 30-80 Gold          │ │
│  │        Uncommon+ Items     │ │
│  │                            │ │
│  └────────────────────────────┘ │
│                                 │
│         ⚠ BOSS FLOOR!          │
│     (visible only on last)      │
│                                 │
│  ┌───────────────────────────┐  │
│  │       ⚔ FIGHT! ⚔          │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │    🏃 RETREAT (keep loot)  │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Mini-map Dots:**
| State | Color | Notes |
|---|---|---|
| Completed | Green | Floors already beaten |
| Current | Yellow + border | Current floor |
| Upcoming | Dark gray | Future floors |
| Boss (B) | Special | Last floor indicator |

**Enemy Pool per Dungeon:**
| Dungeon | Enemies |
|---|---|
| Crypt of Shadows | Shadow Knight (SK), Bone Archer (BA), Wraith (WR), Death Priest (DP) |
| Volcanic Forge | Lava Golem (LG), Fire Imp (FI), Magma Spider (MS), Flame Guard (FG) |
| Frozen Abyss | Ice Wraith (IW), Frost Bear (FB), Snow Witch (SW), Crystal Golem (CG) |

**Difficulty Multipliers:**
| Difficulty | HP/Damage Multiplier |
|---|---|
| Easy | 1.0x |
| Normal | 1.4x |
| Hard | 2.0x |

**Accumulated Rewards:**
- Gold and XP accumulate across floors
- Loot collected per floor
- On retreat: all accumulated rewards are applied to character
- On defeat: lose current floor, keep previous accumulated rewards

**Navigation:**
- Fight → `CombatScreen` (sets dungeon combat data)
- Retreat → Apply accumulated rewards → `DungeonSelectScreen`

---

### 2.16 — Shop Screen

**Purpose:** Buy items, consumables, and special packs.
**Source:** `scenes/shop/shop_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back           SHOP 🏪        │
│─────────────────────────────────│
│ 💰 12,450        💎 23          │
│─────────────────────────────────│
│[Weapons][Armor][Consumables][Spcl]│
│─────────────────────────────────│
│                                 │
│  ┌───────────────────────────┐  │
│  │ [W] Steel Longsword       │  │
│  │     COMMON  Req. Lv.5     │  │
│  │     200 G         [BUY]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ [W] Flame Blade           │  │
│  │     RARE    Req. Lv.10    │  │
│  │     800 G         [BUY]   │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ [W] Void Reaper           │  │
│  │     EPIC    Req. Lv.15    │  │
│  │     50 D          [BUY]   │  │
│  └��──────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ [W] Thunder Mace          │  │
│  │     UNCOMMON Req. Lv.8    │  │
│  │     450 G         [BUY]   │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Tab Categories:**
| Tab | Item Types |
|---|---|
| Weapons | weapon |
| Armor | helmet, chest, gloves, legs, boots, accessory, amulet, ring |
| Consumables | consumable, potion |
| Special | special, gem_pack, gold_pack |

**Shop Item Card (`shop_item_card.gd`):**
| Element | Notes |
|---|---|
| Icon Frame | Letter icon (W/H/C/G/L/B/A/Am/Ri/P/S) in rarity-tinted background |
| Item Name | Rarity-colored text |
| Rarity Label | Capitalized rarity in rarity color |
| Level Req | "Req. Lv.X" |
| Price | "X D" (gems, cyan text) or "X G" (gold, yellow text) |
| Buy Button | Emits `buy_requested(item_data)` |

**Mock Shop Catalog (13 items):**
| Category | Items |
|---|---|
| Weapons (4) | Steel Longsword 200G, Flame Blade 800G, Void Reaper 50D, Thunder Mace 450G |
| Armor (5) | Iron Helm 150G, Plate Armor 500G, Dragon Scale Boots 900G, Shadow Gloves 35D, Leather Leggings 180G |
| Consumables (3) | Health Potion 50G, Stamina Elixir 100G, XP Boost Scroll 300G |
| Special (2) | 100 Gems Pack 5000G, Legendary Chest 100D |

**Purchase Flow:**
- Tap Buy → Validate gold/gems sufficient → Deduct currency → Title label shows "Purchased {name}!" for 1.5s → Update gold/gems display

**Navigation:** Back → `HubScreen`

---

### 2.17 — Battle Pass Screen

**Purpose:** Seasonal progression with free and premium reward tracks.
**Source:** `scenes/battle_pass/battle_pass_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back      BATTLE PASS         │
│─────────────────────────────────│
│                                 │
│  Season 1: Iron Dawn            │
│  Level: 5                       │
│  XP: ████░░░░░░ 45/120          │
│                                 │
│  ┌─ FREE TRACK (scroll→) ────┐  │
│  │ [Lv1✓][Lv2✓][Lv3○]...[30]│  │
│  └────────────────────────────┘ │
│  ┌─ PREMIUM TRACK (scroll→) ─┐  │
│  │ [Lv1🔒][Lv2🔒][Lv3🔒]..30│  │
│  └────────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 💎 UNLOCK PREMIUM (500)   │  │
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

**Reward Node (per level):**
| Element | Notes |
|---|---|
| Level Number | "Lv.X" |
| Reward Type Icon | gold/xp/item/chest/stamina |
| Reward Name | e.g. "50 Gold", "10 XP" |
| Amount | Numeric value |
| Claimed State | Checkmark if claimed, lock if premium not purchased |
| Claim Button | Appears if level reached and unclaimed |

**30-Level Reward Formula:**
- Free track gold: level × 50
- Free track XP: level × 10
- Premium track: similar but higher amounts

**Navigation:** Back → `HubScreen`

---

### 2.18 — Achievements Screen

**Purpose:** Track and claim achievement rewards across 6 categories.
**Source:** `scenes/achievements/achievements_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back       ACHIEVEMENTS 🎖️    │
│─────────────────────────────────│
│ 8/32 (3 unclaimed!)            │
│                                 │
│[Combat][Progress][Collect]      │
│[Dungeon][Economy][Rank]         │
│─────────────────────────────────│
│                                 │
│  ┌─ First Blood ──────────────┐ │
│  │ Win your first PvP match    │ │
│  │ ████████████████ 1/1        │ │
│  │ 💰 100 Gold      [CLAIM]   │ │
│  └────────────────────────────┘ │
│  ┌─ Pit Fighter ─────────────┐ │
│  │ Win 10 PvP matches          │ │
│  │ ████████░░░░░░░░ 7/10      │ │
│  │ 💰 500 Gold                 │ │
│  └────────────────────────────┘ │
│  ┌─ Arena Veteran ────────────┐ │
│  │ Win 50 PvP matches          │ │
│  │ ██░░░░░░░░░░░░░░ 7/50     │ │
│  │ 💎 2 Gems                   │ │
│  └────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**6 Category Tabs:**
| Tab | Achievement Count | Examples |
|---|---|---|
| Combat | 9 | First Blood, Pit Fighter, Arena Veteran, Gladiator, Arena Legend, On Fire, Unstoppable, Sweet Revenge, Grudge Settler |
| Progression | 5 | Level Up!, Seasoned Warrior, Master, Prestige Initiate, Prestige Master |
| Collection | 4 | First Loot, Rare Collector, Epic Hoarder, Legendary Hunter |
| Dungeon | 4 | Dungeon Novice, Dungeon Explorer, Dungeon Master, Abyss Conqueror |
| Economy | 4 | First Purchase, Gold Hoarder, Big Spender, Upgrade Master |
| Rank | 6 | Bronze Fighter, Silver Rank, Gold Rank, Platinum Rank, Diamond Rank, Grandmaster |

**32 total achievements.** Sort order: Claimable first → In-progress → Claimed

**Count Label:** "X/Y" or "X/Y (Z unclaimed!)" if unclaimed > 0

**Reward Types:** Gold, Gems, Titles, Frames

**Navigation:** Back → `HubScreen`

---

### 2.19 — Daily Quests Screen

**Purpose:** View and track 4 random daily quests with completion bonus.
**Source:** `scenes/quests/daily_quests_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back       DAILY QUESTS 📋    │
│─────────────────────────────────│
│  Resets in: 14h 23m             │
│                                 │
│  ┌─ Complete All 4 Quests ────┐ │
│  │ ██████████░░░░░░ 2/4       │ │
│  │ Reward: 500 Gold + 1 Gem   │ │
│  │              [CLAIM]       │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ ⚔ Arena Fighter ─── ✅ ──┐ │
│  │ Win 3 PvP matches           │ │
│  │ ████████████████ 3/3        │ │
│  │ 300 Gold  100 XP   [Claim] │ │
│  └────────────────────────────┘ │
│  ┌─ 💰 Shopping Spree ── ✅ ─┐ │
│  │ Spend 1000 gold             │ │
│  │ ████████████████ 1000/1000  │ │
│  │ 200 Gold  80 XP    [Done]  │ │
│  └────────────────────────────┘ │
│  ┌─ 🏰 Dungeon Runner ──────┐ │
│  │ Complete 2 dungeons         │ │
│  │ ████████░░░░░░░░ 1/2       │ │
│  │ 400 Gold  150 XP           │ │
│  └────────────────────────────┘ │
│  ┌─ 🔨 Upgrade Equipment ───┐ │
│  │ Upgrade items 1 time        │ │
│  │ ░░░░░░░░░░░░░░░░ 0/1      │ │
│  │ 350 Gold  120 XP           │ │
│  └────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**7 Quest Types (4 random per day):**
| Type | Title | Icon | Target Range | Reward |
|---|---|---|---|---|
| pvp_wins | Arena Fighter | ⚔ | 2-5 | 300 gold, 100 XP |
| dungeons_complete | Dungeon Runner | 🏰 | 1-3 | 400 gold, 150 XP |
| gold_spent | Shopping Spree | 💰 | 500-2000 | 200 gold, 80 XP |
| item_upgrade | Upgrade Equipment | 🔨 | 1-3 | 350 gold, 120 XP |
| consumable_use | Potion Drinker | 🧪 | 2-5 | 200 gold, 80 XP |
| shell_game_play | Gambler | 🎲 | 2-5 | 250 gold, 100 XP |
| gold_mine_collect | Gold Miner | ⛏ | 1-3 | 300 gold, 100 XP |

**Completion Bonus:** Finish all 4 quests → 500 gold + 1 gem

**Reset Timer:** Countdown to midnight UTC, "Resets in: Xh Ym"

**Navigation:** Back → `HubScreen`

---

### 2.20 — Daily Login Popup (Modal)

**Purpose:** Show daily login reward and streak progress. Auto-shown from HubScreen.
**Source:** `scenes/daily_login/daily_login_popup.gd`

```
┌─────────────────────────────────┐
│                                 │
│     🎁 7 Day Login Rewards 🎁   │
│                                 │
│  Day 1   Day 2   Day 3   Day 4 │
│  💰 200  🧪 ×1   💰 500  🧪 ×2 │
│   ✓      ✓      [✨]     ○    │
│  (green) (grn)  (gold)  (gray) │
│                                 │
│  Day 5   Day 6   Day 7         │
│  💰1000  🧪 Lg   💎5+Rare     │
│   ○      ○      ○             │
│                                 │
│  ┌─ 🔥 7-Day Streak ─────────┐ │
│  │  +2 Gems                   │ │
│  │  Progress: 3 / 7           │ │
│  └────────────────────────────┘ │
│                                 │
│  Streak: 3 days                 │
│                                 │
│  ┌───────────────────────────┐  │
│  │      🎁 CLAIM DAY 3       │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │         CLOSE              │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**7-Day Reward Cycle:**
| Day | Type | Reward | Icon |
|---|---|---|---|
| 1 | Gold | 200 | 💰 |
| 2 | Item | 1 Stamina Potion (S) | 🧪 |
| 3 | Gold | 500 | 💰 |
| 4 | Item | 2 Stamina Potions (S) | 🧪 |
| 5 | Gold | 1000 | 💰 |
| 6 | Item | 1 Large Potion | 🧪 |
| 7 | Gems | 5 Gems + Rare Item | 💎 |

**Day Card States:**
| State | Border Color | Notes |
|---|---|---|
| Claimed | Green | Already collected |
| Current (claimable) | Gold | Glowing, active |
| Upcoming | Gray | Not yet available |

**Streak Bonus:** 7 consecutive days = "+2 Gems bonus!"

**Signals:** `reward_claimed(day, reward)`, `popup_closed()`

---

### 2.21 — Leaderboard Screen

**Purpose:** View top player rankings by different criteria.
**Source:** `scenes/leaderboard/leaderboard_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back       LEADERBOARD 📊     │
│─────────────────────────────────│
│ [Rating] [Level] [Gold]         │
│─────────────────────────────────│
│                                 │
│  🥇 1. LegendSlayer     2,450  │
│  🥈 2. DragonKnight     2,380  │
│  🥉 3. ShadowQueen      2,310  │
│     4. IronWill         2,290  │
│     5. BladeMaster      2,240  │
│     ...                         │
│                                 │
│  ┌─ Your Position ────────────┐ │
│  │ #8                          │ │
│  └────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**3 Tab Filters:**
| Tab | Sorts By | Display Value |
|---|---|---|
| Rating | PvP Rating (ELO) | Rating points |
| Level | Player Level | Level number |
| Gold | Total Gold | Gold amount |

**Leaderboard Row:**
- Rank number (1-100)
- Character name
- Class
- Value (formatted based on tab)
- Current player highlighted with special styling

**Navigation:** Back → `HubScreen`

---

### 2.22 — Profile Screen

**Purpose:** Read-only character overview with all stats and PvP record.
**Source:** `scenes/profile/profile_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back         PROFILE          │
│─────────────────────────────────│
│                                 │
│    DarkBlade                    │
│    Warrior • Orc                │
│    Level 15                     │
│    user@email.com               │
│    (or "Guest Account")         │
│                                 │
│  ┌─ Stats ────────────────────┐ │
│  │ STR    38    │  INT    12  │ │
│  │ AGI    22    │  WIS    15  │ │
│  │ VIT    30    │  LUK    14  │ │
│  │ END    18    │  CHA    11  │ │
│  │ HP   280/340 │             │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ PvP ─────────────────────┐ │
│  │ Rating: 1240               │ │
│  │ Record: 42W / 18L          │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ Resources ───────────────┐ │
│  │ Gold: 12,450               │ │
│  │ Arena Tokens: 50           │ │
│  └────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**Navigation:** Back → `HubScreen`

---

### 2.23 — Shell Game (Minigame)

**Purpose:** Gambling minigame — bet gold, pick the cup hiding the ball.
**Source:** `scenes/minigames/shell_game_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back       SHELL GAME 🐚      │
│─────────────────────────────────│
│  Your Gold: 12,450              │
│                                 │
│  Bet: [50] [100] [200] [500]    │
│                                 │
│                                 │
│      🐚       🐚       🐚       │
│      (?)      (?)      (?)     │
│                                 │
│   Bet 100 gold. Pick a cup!    │
│                                 │
│                                 │
│  After reveal:                  │
│      (X)      (O)      (X)    │
│   "WIN! +100 gold!" (green)    │
│   or "Lost 100 gold..." (red)  │
│                                 │
└─────────────────────────────────┘
```

**State Machine:**
| State | Description |
|---|---|
| BETTING | Select bet amount (default 100) |
| SHUFFLING | Cups shuffle with 5 rounds of visual swaps |
| PICKING | Player taps a cup |
| REVEALING | All cups reveal (O = ball, X = empty) |
| RESULT | Win/lose message, auto-reset after 2s |

**Cup Colors:**
| State | Color |
|---|---|
| Default | Brown (0.25, 0.15, 0.05) |
| Hover | Lighter brown (0.35, 0.22, 0.08) |
| Win | Green (0.15, 0.4, 0.15) |
| Lose | Red (0.4, 0.15, 0.15) |
| Ball | Gold (1.0, 0.85, 0.2) |

**Bet Amounts:** 50, 100, 200, 500 gold

**API (Real mode):**
- `POST /api/minigames/shell-game/start` → session_id
- `POST /api/minigames/shell-game/guess` → {ball_position, is_win}

**Navigation:** Back → `DungeonSelectScreen`

---

### 2.24 — Gold Mine (Minigame) — Placeholder

**Purpose:** Passive gold generation with timed mining slots.
**Source:** `scenes/minigames/gold_mine_screen.gd` (skeleton)
**Status:** Not yet implemented — placeholder screen.

---

### 2.25 — Dungeon Rush (Minigame) — Placeholder

**Purpose:** Rapid-fire floor climbing minigame.
**Source:** `scenes/minigames/dungeon_rush_screen.gd` (skeleton)
**Status:** Not yet implemented — placeholder screen.

---

### 2.26 — Settings Screen

**Purpose:** Audio, notifications, language, account management.
**Source:** `scenes/settings/settings_screen.gd`

```
┌─────────────────────────────────┐
│ ◀ Back        SETTINGS ⚙️       │
│─────────────────────────────────│
│                                 │
│  ┌─ Audio ────────────────────┐ │
│  │ Sound:    [ON] / OFF       │ │
│  │ Music:    [ON] / OFF       │ │
│  │ Volume:   ████████░░  80%  │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ Notifications ────────────┐ │
│  │ Push: [ON] / OFF           │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ Language ─────────────────┐ │
│  │ [English           ▼]     │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ Account ──────────────────┐ │
│  │ [Link Account] (coming soon)│ │
│  └────────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐  │
│  │      🚪 LOG OUT            │  │
│  └───────────────────────────┘  │
│                                 │
│  Hexbound v0.1.0               │
│                                 │
└─────────────────────────────────┘
```

**Settings Controls:**
| Control | Type | Behavior |
|---|---|---|
| Sound Toggle | CheckButton | Mutes/unmutes SFX AudioServer bus |
| Music Toggle | CheckButton | Mutes/unmutes Music AudioServer bus |
| Volume Slider | HSlider | Adjusts SFX bus volume (0-100 → dB) |
| Push Toggle | CheckButton | Saves to ConfigFile |
| Language | OptionButton | 9 options: English, Spanish, French, German, Portuguese, Russian, Japanese, Korean, Chinese |
| Link Account | Button | Shows "Coming soon..." placeholder |
| Logout | Button | `AuthManager.logout()` → `LoginScreen` |

**Persistence:** Settings saved to `user://settings.cfg` (ConfigFile)

**Navigation:**
- Back → `HubScreen`
- Logout → `LoginScreen`

---

## 3. User Flows

### 3.1 — Starting the Game (New Player)

```
┌──────────┐   ┌──────────┐   ┌──────────┐
│  Splash  │──▶│  Login   │──▶│ Register │
│  Screen  │   │  Screen  │   │  (Email) │
└──────────┘   └──────────┘   └────┬─────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │     Onboarding Screen       │
                    │  Step 1: Choose Race         │
                    │  Step 2: Choose Gender/Avatar │
                    │  Step 3: Choose Class         │
                    │  Step 4: Name Hero            │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │       Hub Screen             │
                    │  (Daily Login Popup shows)   │
                    │  → Tutorial tooltip overlay  │
                    │  → "Try Training!" prompt    │
                    └──────────────────────────────┘
```

**Steps:**
1. App opens → Splash Screen with auto-login check
2. No token found → Login Screen
3. Player taps "Create Account" → Registration form
4. After auth → Onboarding Screen (4-step character creation)
5. Step 1: Choose Race (5 races with stat bonuses)
6. Step 2: Choose Gender (Male/Female) + Avatar (4 per gender)
7. Step 3: Choose Class (4 classes with stat bonuses)
8. Step 4: Enter Name + Review Summary → Confirm
9. Character saved → Hub Screen with Daily Login popup
10. Tutorial tooltips guide to first training battle

### 3.2 — Returning Player

```
┌──────────┐   ┌──────────────────────────┐
│  Splash  │──▶│       Hub Screen         │
│  (token  │   │  (Auto-login success)    │
│  found)  │   │  Daily Login Popup       │
└──────────┘   └──────────────────────────┘
```

---

### 3.3 — Character Progression Flow

```
┌──────────────┐
│  Earn XP     │ (Training, PvP, Dungeons, Quests)
└──────┬───────┘
       │
┌──────▼───────┐
│  Level Up!   │ (XP needed = 100 + level × 50)
│  +3 Stats    │
│  +15 Max HP  │
└──────┬───────┘
       │
┌──────▼───────────────────────┐
│  Character Screen             │
│  Allocate Stat Points         │
│  [+] STR, [+] AGI, etc.      │
│  [Save Changes]               │
└──────┬───────────────────────┘
       │
┌──────▼───────────────────────┐
│  Set Stance (optional)        │
│  Attack: Head/Chest/Legs      │
│  Defense: Head/Chest/Legs     │
└──────┬───────────────────────┘
       │
┌──────▼───────────────────────┐
│  Equipment Screen             │
│  Equip better gear            │
│  Upgrade items at Shop        │
└──────────────────────────────┘
```

**Progression Math:**
| Level | XP Needed | Cumulative Stat Points |
|---|---|---|
| 1→2 | 150 | 3 |
| 5→6 | 400 | 15 |
| 10→11 | 600 | 30 |
| 15→16 | 850 | 45 |
| 20→21 | 1100 | 60 |

---

### 3.4 — PvP Battle Flow

```
┌──────────┐    ┌──────────────┐    ┌──────────────┐
│   Hub    │───▶│   Arena      │───▶│  Select      │
│  (Arena) │    │   Screen     │    │  Opponent    │
└──────────┘    └──────────────┘    └──────┬───────┘
                                           │
                     ┌─────────────────────▼──┐
                     │  Confirm Fight?        │
                     │  Cost: 10 STA (or FREE)│
                     │  Free PvP: X/3         │
                     └─────────────┬──────────┘
                                   │
                     ┌─────────────▼──────────┐
                     │    Combat Screen       │
                     │  7-14 turns            │
                     │  [1x] [2x] [Skip]      │
                     └─────────────┬──────────┘
                                   │
                ┌──────────────────┼──────────────────┐
                │                  │                   │
       ┌────────▼─────┐  ┌────────▼──────┐           │
       │   VICTORY    │  │   DEFEAT      │           │
       │  +Gold +XP   │  │  -Rating      │           │
       │  +25 Rating  │  │  +some XP     │           │
       │  +Loot?      │  │  -15 Rating   │           │
       └────────┬─────┘  └────────┬──────┘           │
                │                  │                   │
       ┌────────▼─────┐           │                   │
       │  Loot Screen │           │                   │
       │  (if drop)   │           │                   │
       └────────┬─────┘           │                   │
                └──────────┬───────┘                   │
                           │                           │
                     ┌─────▼─────┐                     │
                     │  Continue │─────────────────────┘
                     │  → Arena  │         (Rematch)
                     └───────────┘
```

**PvP Rules:**
| Rule | Value |
|---|---|
| Free PvP per day | 3 matches (no stamina cost) |
| Regular PvP cost | 10 stamina |
| First Win bonus | x2 Gold + x2 XP |
| Win rating change | +25 (K=48 during calibration) |
| Loss rating change | -15 |
| Matchmaking range | ±150 (calibration), ±100 (after) |
| Revenge window | 72 hours after loss |
| Revenge gold bonus | x1.5 |
| Max turns per fight | 15 |

---

### 3.5 — PvE Dungeon Flow

```
┌──────────┐    ┌──────────────┐
│   Hub    │───▶│  Dungeon     │
│(Dungeons)│    │  Select      │
└──────────┘    │  + Difficulty │
                └──────┬───────┘
                       │
          ┌────────────▼──────────────┐
          │    Dungeon Room Screen    │
          │    Floor 1 / 5            │
          │    Enemy: Shadow Knight   │
          │    [Fight] [Retreat]      │
          └──────┬────────────────────┘
                 │
          ┌──────▼──────┐    ┌───────────┐
          │ Combat      │    │ Retreat → │
          │ Screen      │    │ Keep loot │
          └──────┬──────┘    │ → Dungeon │
                 │           │   Select  │
          ┌──────▼──────┐    └───────────┘
          │  Victory?   │
          │  Yes → Next │
          │  Floor      │──── Floor 2, 3, 4...
          │  No → Fail  │
          │  → Dungeon  │
          │    Select   │
          └──────┬──────┘
                 │ (Last floor)
          ┌──────▼──────┐
          │ BOSS FIGHT! │
          │ (Lich King)  │
          └──────┬──────┘
                 │
          ┌──────▼────────┐
          │  Complete!    │
          │  All rewards  │
          │  + Boss loot  │
          └──────┬────────┘
                 │
          ┌──────▼────────┐
          │ Dungeon Select│
          └───────────────┘
```

**Dungeon Details:**
| Dungeon | Floors | Min Lv | Boss | Theme |
|---|---|---|---|---|
| Crypt of Shadows | 5 | 1 | Lich King Verath | Purple |
| Volcanic Forge | 7 | 10 | Magma Titan Pyrox | Orange |
| Frozen Abyss | 9 | 20 | Frost Wyrm Glacius | Blue |

---

### 3.6 — Inventory Management Flow

```
┌──────────────┐
│ Hub (bottom  │
│ nav: Inv)    │
└────┬─────────┘
     │
┌────▼──────────────────┐
│  Inventory Screen     │
│  [Filter] [Sort]      │
│  Grid of item cards   │
│  Tap item ↓           │
└────┬──────────────────┘
     │
┌────▼──────────────────┐
│ Item Detail Modal     │
│                       │
│ Stats + Comparison    │
│ vs equipped item      │
│ ▲ green = better      │
│ ▼ red = worse         │
│                       │
│ [Equip]  → Stats update, close
│ [Unequip]→ Stats update, close
│ [Sell]   → Gold gained, item removed
│ [Close]  → Back to grid
└────┬──────────────────┘
     │
┌────▼──────────────────┐
│  Equipment Screen     │
│  12-slot paper doll   │
│  Tap filled slot →    │
│    ItemDetailModal    │
│  Stat summary panel   │
└───────────────────────┘
```

**Item Upgrade Success Rates (via Shop):**
| Level | Rate |
|---|---|
| +1 to +5 | 100% |
| +6 | 80% |
| +7 | 60% |
| +8 | 40% |
| +9 | 25% |
| +10 | 15% |

---

## 4. Design Tokens (AAA Standard)

> All tokens aligned with Section 0 — AAA Visual Design Language. Use these as the single source of truth for Figma variables, Godot theme resources, and shader parameters.

### 4.1 — Color Palette

**Background & Surface Colors:**
```
Core Background:
  --bg-abyss:         #08080C    (Deepest black — used behind modals, vignette center)
  --bg-primary:       #0D0D12    (Deep black-blue — main screen background)
  --bg-secondary:     #1A1A2E    (Dark navy — panel backgrounds, cards)
  --bg-tertiary:      #16213E    (Muted navy — card interiors, form fields)
  --bg-elevated:      #1E2240    (Elevated surfaces — active cards, selected items)
  --bg-modal:         #000000BF  (Modal overlay — 75% opacity pure black)

Surface Materials (overlay textures applied ON TOP of bg colors):
  --surface-stone:    url(textures/dark_stone_noise.png)     repeat, 3% opacity blend
  --surface-leather:  url(textures/leather_grain.png)        repeat, 5% opacity blend
  --surface-parchment: url(textures/aged_parchment.png)      repeat, 8% opacity blend
  --surface-metal:    url(textures/hammered_metal.png)       repeat, 4% opacity blend
```

**Accent Colors:**
```
Gold System (Primary):
  --accent-gold:        #D4A537    (Primary CTA, gold buttons, active tabs)
  --accent-gold-bright: #FFD700    (Highlighted text, important values, badges)
  --accent-gold-dim:    #8B6914    (Disabled gold, inactive accent)
  --accent-gold-glow:   #D4A53766  (Gold glow for shadows — 40% opacity)

Feedback:
  --accent-red:         #E63946    (Danger, defeat, HP critical, destructive actions)
  --accent-red-glow:    #E6394640  (Red glow/shadow — 25% opacity)
  --accent-green:       #2ECC71    (Success, victory, HP high, positive stat change)
  --accent-green-glow:  #2ECC7140  (Green glow — 25% opacity)
  --accent-blue:        #3498DB    (Info, links, mana-themed elements)
  --accent-cyan:        #00D4FF    (Enchanted/premium accents, crystal glow)
  --accent-purple:      #9B59B6    (XP, magic, epic rarity themes)
```

**Text Colors:**
```
  --text-primary:     #F5F5F5    (Main readable text — 15.3:1 on --bg-primary ✓ WCAG AAA)
  --text-secondary:   #A0A0B0    (Subtitles, labels — 7.8:1 on --bg-primary ✓ WCAG AA)
  --text-tertiary:    #6B6B80    (Hints, placeholders — 4.6:1 ✓ WCAG AA large text)
  --text-disabled:    #555566    (Disabled states, unavailable items)
  --text-gold:        #FFD700    (Important values, currency, highlighted — 8.7:1 ✓)
  --text-on-gold:     #1A1A2E    (Dark text ON gold button backgrounds — 5.2:1 ✓)
  --text-danger:      #FF6B6B    (Error messages, negative stat changes)
  --text-success:     #5DECA5    (Positive changes, buffs, equip improvements)
```

**Border & Frame Colors:**
```
  --border-subtle:    #2A2A3E    (Panel borders, divider lines)
  --border-medium:    #3A3A50    (Metallic highlight — top/left edge of panels)
  --border-strong:    #4A4A60    (Active element borders, focus rings)
  --border-gold:      #D4A537    (Selected items, active tabs, CTA borders)
  --border-ornament:  #B8860B    (Ornamental engravings, decorative frames)
```

**Rarity Colors (from code — used for borders, text, glow):**
```
  --rarity-common:    #999999    rgb(0.6, 0.6, 0.6)    Dim Iron
  --rarity-uncommon:  #4DCC4D    rgb(0.3, 0.8, 0.3)    Forest Green
  --rarity-rare:      #4D80FF    rgb(0.3, 0.5, 1.0)    Azure Blue
  --rarity-epic:      #A64DE6    rgb(0.65, 0.3, 0.9)   Amethyst Purple
  --rarity-legendary: #FFBF1A    rgb(1.0, 0.75, 0.1)   Molten Gold

  Rarity Glow (for card shadows):
  --rarity-common-glow:    #99999920  (barely visible)
  --rarity-uncommon-glow:  #4DCC4D30
  --rarity-rare-glow:      #4D80FF40
  --rarity-epic-glow:      #A64DE650
  --rarity-legendary-glow: #FFBF1A60  (strongest glow + pulse animation)
```

**Stat Colors (from CharacterScreen):**
```
  --stat-str:  #E6594D  rgb(0.9, 0.35, 0.3)  Crimson (Strength)
  --stat-agi:  #4DE666  rgb(0.3, 0.9, 0.4)   Emerald (Agility)
  --stat-vit:  #E68080  rgb(0.9, 0.5, 0.5)   Rose (Vitality)
  --stat-end:  #B3B34D  rgb(0.7, 0.7, 0.3)   Amber (Endurance)
  --stat-int:  #6680FF  rgb(0.4, 0.5, 1.0)   Sapphire (Intelligence)
  --stat-wis:  #9966E6  rgb(0.6, 0.4, 0.9)   Violet (Wisdom)
  --stat-luk:  #E6D94D  rgb(0.9, 0.85, 0.3)  Gold (Luck)
  --stat-cha:  #E699CC  rgb(0.9, 0.6, 0.8)   Blush (Charisma)
```

**Class Colors (from CombatScreen):**
```
  --class-warrior:  #E68C33  (Ember Orange)
  --class-rogue:    #4DD958  (Venom Green)
  --class-mage:     #6680FF  (Arcane Blue)
  --class-tank:     #9999B2  (Iron Gray)
```

**Rank Colors (from ArenaScreen):**
```
  --rank-bronze:      #B38040  rgb(0.7, 0.5, 0.3)    Tarnished Bronze
  --rank-silver:      #BFBFCC  rgb(0.75, 0.75, 0.8)   Polished Silver
  --rank-gold:        #FFD600  rgb(1.0, 0.84, 0.0)    Pure Gold
  --rank-platinum:    #66CCCC  rgb(0.4, 0.8, 0.8)     Platinum Frost
  --rank-diamond:     #99CCFF  rgb(0.6, 0.8, 1.0)     Diamond Blue
  --rank-grandmaster: #FF4D4D  rgb(1.0, 0.3, 0.3)     Blood Crimson
```

**Stance Zone Colors:**
```
  --zone-head:  #E66666  rgb(0.9, 0.4, 0.4)  Crimson (Head)
  --zone-chest: #6699E6  rgb(0.4, 0.6, 0.9)  Steel Blue (Chest)
  --zone-legs:  #66E666  rgb(0.4, 0.9, 0.4)  Forest (Legs)
```

**Progress Bar Gradients:**
```
HP Bar:
  --hp-high-start:  #2ECC71    --hp-high-end:  #27AE60   (Green, >60%)
  --hp-mid-start:   #F1C40F    --hp-mid-end:   #F39C12   (Amber, 30-60%)
  --hp-low-start:   #E74C3C    --hp-low-end:   #C0392B   (Red, <30%, + pulse)

XP Bar:
  --xp-start:       #9B59B6    --xp-end:       #8E44AD   (Purple gradient)

Stamina Bar:
  --stamina-start:  #E67E22    --stamina-end:  #D35400   (Orange gradient)

Quest/Battle Pass Progress:
  --progress-start: #D4A537    --progress-end: #B8860B   (Gold gradient)
```

### 4.2 — Typography (AAA Standard)

> See Section 0 for full Typography Scale table. These tokens map directly to Figma text styles.

```
Font Families:
  --font-display:    "Cinzel Bold"       (Titles, hero names, cinematic text)
  --font-heading:    "Oswald SemiBold"   (Section headers, button labels, card titles)
  --font-heading-md: "Oswald Medium"     (Card titles, medium emphasis)
  --font-body:       "Inter Medium"      (Body text, descriptions, UI labels)
  --font-body-bold:  "Inter SemiBold"    (Stat labels, emphasized body text)
  --font-caption:    "Inter Medium"      (Timestamps, fine print)
  --font-badge:      "Inter Bold"        (Notification badges, "NEW" tags)

Size Scale (mobile, portrait 1170×2532):
  --text-cinematic:  40px / 48px LH  (Victory/Defeat, hero moments)
  --text-screen:     28px / 34px LH  (Screen titles: "ARENA", "INVENTORY")
  --text-section:    22px / 28px LH  (Panel headers: "Core Stats", "Rewards")
  --text-card:       18px / 24px LH  (Item names, character names)
  --text-button:     18px / 22px LH  (All button labels, UPPERCASE mandatory)
  --text-body:       16px / 22px LH  (Descriptions, flavor text)
  --text-label:      14px / 18px LH  (Stat labels, filter tags, small info)
  --text-caption:    12px / 16px LH  (Timestamps, version numbers)
  --text-badge:      11px / 14px LH  (Notification counts, "NEW" badges)

Letter Spacing:
  --ls-cinematic:  +2px     (Display titles)
  --ls-screen:     +1.5px   (Screen titles)
  --ls-section:    +1px     (Section headers)
  --ls-card:       +0.5px   (Card titles)
  --ls-button:     +2px     (Button labels — extra wide for readability)
  --ls-label:      +0.5px   (UI labels)
  --ls-default:    0px      (Body text)

Rules:
  ✗ Never use font weight below Medium (500)
  ✗ Never use size below 11px
  ✗ Body text and button labels must be 16px+
  ✗ Light/Thin weights are FORBIDDEN
  ✓ All button text: UPPERCASE
  ✓ All screen titles: UPPERCASE
```

### 4.3 — Spacing & Layout

```
Spacing Scale:
  --space-2xs:  2px    (Micro gaps, inline icon offsets)
  --space-xs:   4px    (Badge padding, tight groups)
  --space-sm:   8px    (Card internal gaps, filter tag gaps)
  --space-md:   16px   (Standard padding, section gaps)
  --space-lg:   24px   (Section separation, generous card padding)
  --space-xl:   32px   (Screen section breaks)
  --space-2xl:  48px   (Hero areas, dramatic spacing)

Screen Layout:
  --screen-padding:    16px   (Horizontal content inset from screen edges)
  --screen-top-gap:    16px   (Gap below header before content)
  --content-max-width: 1138px (1170 - 16px×2 padding)
  --safe-area-top:     59px   (iOS Dynamic Island)
  --safe-area-bottom:  34px   (iOS Home indicator)

Component Sizing:
  --button-height-lg:    56px   (Primary CTA buttons)
  --button-height-md:    48px   (Secondary buttons, inline actions)
  --button-height-sm:    36px   (Tertiary, filter tags, compact actions)
  --button-padding-h:    24px   (Horizontal padding inside buttons)
  --button-radius:       8px
  --card-padding:        16px   (Inner padding for all card types)
  --card-radius:         12px
  --panel-radius:        8px
  --modal-radius:        16px
  --input-height:        52px   (Text inputs, dropdowns)
  --input-radius:        8px
  --avatar-size-lg:      72px   (Hub screen, profile)
  --avatar-size-md:      56px   (Combat, leaderboard)
  --avatar-size-sm:      40px   (Lists, chat)
  --bottom-nav-height:   64px

Touch Targets:
  --touch-min:           48px   (Minimum interactive element size per AAA)
  --touch-comfortable:   56px   (Preferred primary button height)

Grid:
  --inventory-cols:    4
  --inventory-gap:     8px
  --item-card-size:    ~80px (fills available width in 4-col)
  --equipment-cols:    3
  --equipment-gap:     12px
  --class-grid-cols:   2
  --class-grid-gap:    12px
  --avatar-grid-cols:  2
  --avatar-grid-gap:   12px
  --nav-grid-cols:     2
  --nav-grid-gap:      12px
```

### 4.4 — Shadow & Effect Tokens

```
Shadows:
  --shadow-sm:       0 2px 4px rgba(0,0,0,0.3)       (Subtle elevation — tabs, badges)
  --shadow-md:       0 4px 12px rgba(0,0,0,0.4)       (Cards, panels, buttons)
  --shadow-lg:       0 8px 24px rgba(0,0,0,0.6)       (Modals, elevated panels)
  --shadow-xl:       0 12px 48px rgba(0,0,0,0.8)       (Full-screen overlays)
  --shadow-gold:     0 4px 12px rgba(212,165,55,0.3)   (Primary gold CTA glow)
  --shadow-gold-lg:  0 8px 24px rgba(212,165,55,0.4)   (Legendary item glow)
  --shadow-inset:    inset 0 2px 4px rgba(0,0,0,0.5)   (Input fields, inset panels)

Glows (Outer):
  --glow-gold:       0 0 8px rgba(212,165,55,0.4)     (Selected/active gold elements)
  --glow-rarity:     0 0 12px [rarity-color] at 40%    (Item rarity border glow)
  --glow-enchanted:  0 0 16px rgba(0,212,255,0.3)     (Premium/enchanted elements)
  --glow-pulse:      Animated 0→8px→0px over 2s ease   (Legendary items, active highlights)

Borders:
  --border-width-subtle:    1px    (Panel borders, dividers)
  --border-width-standard:  2px    (Card frames, button outlines)
  --border-width-ornament:  3px    (Modal frames, ornamental borders)
  --border-metallic-top:    1px solid --border-medium   (Top-edge light catch)

Overlays:
  --overlay-dark:     rgba(0,0,0,0.75)    (Modal backdrop)
  --overlay-vignette: radial-gradient(transparent 50%, rgba(0,0,0,0.6) 100%)   (Screen edges)
  --overlay-noise:    3% opacity noise texture blend    (Stone/metal surfaces)
```

### 4.5 — Animation Tokens

```
Easing Functions:
  --ease-out:         cubic-bezier(0.0, 0.0, 0.2, 1.0)    (Standard exits, UI transitions)
  --ease-in:          cubic-bezier(0.4, 0.0, 1.0, 1.0)    (Entrances, build-up)
  --ease-in-out:      cubic-bezier(0.4, 0.0, 0.2, 1.0)    (Smooth loops)
  --ease-bounce:      cubic-bezier(0.34, 1.56, 0.64, 1.0) (Loot reveal, celebration)
  --ease-snap:        cubic-bezier(0.2, 0.0, 0.0, 1.0)    (Quick actions, button press)

Transition Durations:
  --duration-instant:   100ms   (Hover color change, active state feedback)
  --duration-fast:      150ms   (Button press/release, tab switch)
  --duration-normal:    300ms   (Panel open/close, screen transitions)
  --duration-slow:      500ms   (Modal enter, loot reveal)
  --duration-dramatic:  800ms   (Victory/defeat splash, legendary item reveal)

Combat Animations (from CombatAnimationPlayer):
  Attacker slide:     40px forward, 0.15s ease-out
  Defender flash:     White overlay, 0.15s
  Crit screen shake:  4 tweens × 0.04s (total 0.16s)
  Damage popup:       Float 80px up, 0.7s, fade last 200ms
  HP bar tween:       0.3s ease-out
  Between turns:      0.3s delay
  Kill animation:     Scale 1.0→0.8 + fade out, 0.5s

Loot Reveal Sequence:
  Card scale in:      0.3→1.0 over 500ms (bounce ease)
  Card alpha:         0→1 over 500ms
  Stagger delay:      250ms per item
  Legendary burst:    Golden particle explosion + pulse glow, 800ms

Scene Transitions:
  Fade out:           300ms ease-in (current screen darkens)
  Fade in:            300ms ease-out (new screen appears)
  Modal enter:        Scale 0.9→1.0 + fade 0→1, 300ms ease-out
  Modal exit:         Scale 1.0→0.95 + fade 1→0, 200ms ease-in
  Toast slide:        translateY(-100%) → 0, 300ms ease-out

Idle Animations (ambient):
  Gold shimmer:       Linear gradient shift, 3s infinite
  Particle float:     Translate up 20px + fade, 2-4s random delay
  Pulse glow:         Opacity 0.3→0.6→0.3, 2s ease-in-out infinite
  Legendary border:   Hue-rotate 0→30°→0°, 3s ease-in-out infinite
```

---

## 5. Interaction States & Feedback

> Every interactive element must have clearly distinguishable states. Players must always know: what they CAN tap, what they ARE tapping, and what is UNAVAILABLE. No guessing.

### 5.1 — Button States

**Primary Button (Gold CTA):**
| State | Background | Border | Text | Shadow | Additional |
|---|---|---|---|---|---|
| **Default** | Gold gradient #D4A537→#B8860B | 2px ornamental gold | #1A1A2E Oswald SemiBold 18px | 0 4px 12px gold glow 30% | — |
| **Pressed** | Darkened gold #B8860B→#8B6914 | 2px gold (brighter #FFD700) | #1A1A2E | Shadow shrinks to 0 2px 4px | Scale 0.97 transform, 100ms |
| **Disabled** | #333340 flat | 1px #444455 | #555566 | None | Opacity 40%, no pointer events |
| **Loading** | Gold gradient (dimmed 70%) | 2px gold | Hidden | Subtle glow | Centered spinner (gold, 20px) |

**Secondary Button (Outlined):**
| State | Background | Border | Text | Additional |
|---|---|---|---|---|
| **Default** | Transparent | 1px solid #D4A537 | #D4A537 | — |
| **Pressed** | #D4A53715 (gold 8%) | 1px solid #FFD700 | #FFD700 | Scale 0.97, 100ms |
| **Disabled** | Transparent | 1px solid #444455 | #555566 | Opacity 40% |

**Danger Button (Crimson):**
| State | Background | Border | Text | Additional |
|---|---|---|---|---|
| **Default** | #E63946 | None | #FFFFFF | — |
| **Pressed** | #C0313C (darker) | None | #FFFFFF | Scale 0.97, 100ms |
| **Disabled** | #333340 | None | #555566 | Opacity 40% |

**Icon Buttons (Settings ⚙, Back ◀, Close ✕):**
| State | Icon Color | Background | Additional |
|---|---|---|---|
| **Default** | #A0A0B0 | Transparent | — |
| **Pressed** | #F5F5F5 | #FFFFFF10 (white 6%) | Scale 0.9, 100ms |
| **Disabled** | #555566 | Transparent | Opacity 40% |

### 5.2 — Card States

**Selectable Cards (Race, Class, Avatar, Opponent):**
| State | Border | Background | Shadow | Additional |
|---|---|---|---|---|
| **Default** | 1px #2A2A3E | --bg-secondary | --shadow-sm | — |
| **Pressed** | 1px #3A3A50 | --bg-elevated | --shadow-sm | Scale 0.98, 100ms |
| **Selected** | 2px #D4A537 (gold) | --bg-elevated | 0 0 8px gold glow 30% | Gold check icon top-right corner |
| **Disabled** | 1px #2A2A3E | --bg-secondary | None | Opacity 40%, grayscale filter |

**Item Cards (Inventory, Shop, Loot):**
| State | Border | Additional |
|---|---|---|
| **Default** | 1px [rarity-color] at 40% | Rarity-tinted background at 10% |
| **Pressed** | 2px [rarity-color] at 80% | Scale 0.96, 100ms, brighter rarity tint |
| **Equipped** | 2px [rarity-color] + "[E]" prefix | Gold star badge top-left corner |
| **New** | Animated pulse border | "NEW" badge top-right, pulsing glow |
| **Locked** | 1px #333340 | Grayscale, padlock icon overlay, Opacity 50% |

### 5.3 — Tab & Filter States

**Bottom Navigation Tabs:**
| State | Icon Color | Label Color | Additional |
|---|---|---|---|
| **Active** | #D4A537 (gold) | #D4A537 (gold) | Bold label, subtle glow under icon |
| **Inactive** | #6B6B80 (gray) | #6B6B80 (gray) | — |
| **Pressed** | #FFD700 (bright gold) | #FFD700 | 100ms flash, then settle to active/inactive |

**Filter Tabs (Inventory, Achievements, Arena, Shop):**
| State | Background | Text | Border |
|---|---|---|---|
| **Active** | #D4A537 (gold fill) | #1A1A2E (dark) | None |
| **Inactive** | Transparent | #A0A0B0 | 1px bottom #2A2A3E |
| **Pressed** | #D4A53730 (gold 20%) | #D4A537 | — |

### 5.4 — Form Input States

**Text Inputs (Email, Password, Name):**
| State | Border | Background | Label/Placeholder | Additional |
|---|---|---|---|---|
| **Empty** | 1px #2A2A3E | --bg-tertiary | #6B6B80 placeholder text | — |
| **Focused** | 2px #D4A537 (gold) | --bg-tertiary | Placeholder fades, cursor blinks | Subtle gold glow |
| **Filled** | 1px #3A3A50 | --bg-tertiary | #F5F5F5 value text | — |
| **Error** | 2px #E63946 (red) | --bg-tertiary | #F5F5F5 text | Red error message below, subtle red glow |
| **Disabled** | 1px #222230 | #0D0D12 | #555566 text | Opacity 50% |

### 5.5 — Progress Bar States

**HP Bar Animation:**
```
Value decrease: Current fill shrinks with 0.3s ease-out tween
                Behind the new fill, a "damage ghost" bar in lighter color fades over 0.8s
                <30% HP: fill pulses red (opacity 0.7→1.0→0.7, 1s loop)
                0% HP: fill completely empty, bar border flashes red 3× then dims

Value increase: Fill grows with 0.3s ease-out tween
                Flash of green/white at the growth edge for 200ms
```

**XP Bar Level-Up:**
```
Bar fills to 100% with 0.5s tween
Flash of white across entire bar (left→right, 300ms)
Bar resets to 0% immediately
Level number animates: scale 1.0→1.3→1.0 with gold flash, 500ms
"+1" floats upward from level number, fades over 0.7s
```

### 5.6 — Toast & Notification Feedback

**Toast Messages (via ToastManager):**
```
Position: Top-center, below safe area (y = 80px from top)
Enter: Slide down from -100% + fade in, 300ms ease-out
Display: Hold for 3 seconds
Exit: Slide up + fade out, 200ms ease-in
Max visible: 1 at a time (new toast replaces current)

Toast Types:
  Success: --bg-secondary, left border 3px --accent-green, green icon ✓
  Error:   --bg-secondary, left border 3px --accent-red, red icon ✗
  Info:    --bg-secondary, left border 3px --accent-blue, blue icon ℹ
  Warning: --bg-secondary, left border 3px --accent-gold, gold icon ⚠
  Loot:    --bg-secondary, left border 3px [rarity-color], item icon
```

**Haptic Feedback (iOS):**
```
Button press:        Light impact (UIImpactFeedbackGenerator.style.light)
Successful action:   Success notification (UINotificationFeedbackGenerator.success)
Error/failure:       Error notification (UINotificationFeedbackGenerator.error)
Item equip/loot:     Medium impact
Combat hit:          Rigid impact
Combat crit:         Heavy impact
Level up:            Success × 2 (double pulse)
```

### 5.7 — Loading & Empty States

**Loading State:**
```
Full screen: --bg-primary + centered gold spinner (32px)
             Spinner: Rotating ornamental ring, 1s per rotation
             Below spinner: "Loading..." in Inter Medium 14px, --text-secondary
             After 5s: Add "This is taking longer than expected..." below

Panel loading: Content area replaced with 3 shimmer placeholder bars
               Shimmer: Linear gradient sweep left→right, 1.5s infinite
               Bar colors: #1A1A2E → #2A2A3E → #1A1A2E
```

**Empty State:**
```
Centered icon: Large 64px muted icon (varies by context)
Title: Oswald SemiBold 18px, --text-primary
Subtitle: Inter Medium 14px, --text-secondary, 1-2 lines
Optional CTA button below subtitle

Examples:
  Empty inventory: "🎒 No items yet" / "Win battles or visit the shop to collect gear."
  No opponents:    "⚔ No challengers" / "Check back soon or lower your search range."
  No quests:       "📜 All done for today!" / "Come back tomorrow for new quests."
```

---

## 6. Visual Material & Surface Design

> This section provides Figma-ready specifications for the dark fantasy material language. Every surface in the game should feel like a physical object — stone, metal, leather, parchment — not a flat modern app.

### 6.1 — Material Implementation Guide

**Dark Stone (Screen Backgrounds):**
```
Base color: --bg-primary (#0D0D12)
Texture overlay: Subtle noise pattern at 3% opacity (multiply blend)
Vignette: Radial gradient — transparent center → rgba(0,0,0,0.4) at edges
Implementation in Figma:
  1. Fill: #0D0D12
  2. Add noise fill layer: Pattern, 3% opacity, Multiply
  3. Add radial gradient layer: transparent center → #00000066 edges
```

**Worn Metal (Borders & Frames):**
```
Primary border: 1-2px solid --border-subtle (#2A2A3E)
Top-edge highlight: 1px solid --border-medium (#3A3A50) — simulates light catch
Scratched texture: Optional noise overlay at 2% on borders
Gold variant: #D4A537 border + 1px #FFD700 inner highlight on top edge
Implementation:
  1. Inner stroke: --border-subtle
  2. Top 1px override: --border-medium (metallic reflection)
  3. For gold: --border-gold with inner top-line #FFD700
```

**Engraved Frames (Decorative Panels):**
```
Pattern: Thin ornamental line art along panel edges
Color: #B8860B at 60% opacity (dark gold)
Width: 3px ornamental borders for modals, 2px for important cards
Corner treatment: Small diamond or cross motif at corners
Implementation:
  1. Create ornamental border as SVG/vector asset
  2. Apply as 9-slice border image
  3. Tint with --border-ornament color
```

**Parchment (Info Panels & Tooltips):**
```
Base color: #2A2015 (warm dark brown)
Text color: #E8DCC8 (warm cream)
Texture: Aged paper grain at 8% opacity
Border: 1px #3D3020 (worn leather edge)
Usage: Flavor text panels, lore descriptions, tutorial popups
Implementation:
  1. Fill: #2A2015
  2. Text: #E8DCC8
  3. Optional noise layer: warm-tinted, 8% opacity
```

**Leather (Buttons & Interactive Surfaces):**
```
Base: Dark brown gradient #2A1F15 → #1A1510
Texture: Leather grain at 5% opacity
Stitch line: Subtle 1px dashed border inside at 20% opacity
Press state: Darken by 20%, remove stitch highlight
Usage: Primary button backgrounds (under gold gradient), card press states
```

**Enchanted Crystal (Premium & Magic Elements):**
```
Core color: --accent-cyan (#00D4FF) or --accent-purple (#9B59B6)
Inner glow: Radial gradient from bright center to transparent
Facet highlights: 2-3 white dots at 40% opacity (diamond sparkle)
Animated: Slow pulse (opacity 0.6→1.0→0.6, 3s loop)
Usage: Premium currency icons, legendary item accents, skill gems
```

### 6.2 — Ornamental Dividers

```
Standard Divider:
  ─── ◆ ───────────────────── ◆ ───
  Height: 1px line with diamond endpoints
  Color: --border-subtle (#2A2A3E)
  Diamond: 6px rotated square, --accent-gold at 40%

Section Divider (heavier):
  ═══ ◆ ═══════════════════════ ◆ ═══
  Height: 2px line
  Color: --border-gold at 60%
  Diamond: 8px rotated square, --accent-gold at 70%

Ornamental Header Underline:
  After section headers (e.g., "CORE STATS"):
  ════════════════════════
  Width: matches header text width + 16px padding each side
  Color: --accent-gold at 30%
  Height: 2px, with subtle gold glow below (4px blur, 15% opacity)
```

### 6.3 — Particle & VFX Layer Specifications

```
Floating Embers (Hub, Splash, Victory):
  Count: 8-15 particles visible at any time
  Size: 2-4px circular dots
  Color: #D4A537 → #E6594D (gold to ember)
  Movement: Float upward 20-40px, gentle sine-wave drift horizontal
  Lifetime: 2-4 seconds per particle
  Opacity: Fade in 0→0.6 first 20%, hold, fade out to 0 last 30%

Victory Burst (Combat Result — Win):
  Golden particle explosion: 30-50 particles from center
  Spread: Radial, 200px radius over 1s
  Color: #FFD700 → #D4A537 (bright gold → muted)
  Size: 3-6px, shrinking over lifetime
  Secondary: Small white sparkles (8-12) with 200ms delay

Legendary Loot Reveal:
  Background: Purple vignette pulse (0→20%→0% over 1.5s)
  Border: Gold animated glow pulse (intensity 0.3→1.0→0.3)
  Particles: 5-8 golden sparkles floating from item center
  Sound cue marker: "legendary_reveal" at t=0ms

Defeat Atmosphere (Combat Result — Loss):
  Ash fall: Slow-falling gray particles
  Count: 10-15
  Color: #666666 at 30% opacity
  Screen tint: Red vignette at 15% opacity
```

---

## 7. Figma Implementation Notes

### 7.1 — Recommended Figma File Structure

```
📁 Hexbound — AAA UI Kit
│
├── 📄 Cover Page
│   └── Game logo, version, device target, quality tier reference
│
├── 📁 🎨 Design System
│   ├── 📄 Color Tokens
│   │   ├── Background & Surface Colors (6 levels)
│   │   ├── Accent Colors (Gold, Red, Green, Blue, Cyan, Purple)
│   │   ├── Text Colors (Primary, Secondary, Tertiary, Disabled, Gold, Danger, Success)
│   │   ├── Border & Frame Colors (Subtle, Medium, Strong, Gold, Ornament)
│   │   ├── Rarity Colors (5 tiers + glow variants)
│   │   ├── Stat Colors (8 stats)
│   │   ├── Class Colors (4 classes)
│   │   ├── Rank Colors (6 tiers)
│   │   └── Gradient Sets (HP, XP, Stamina, Progress, Gold button)
│   │
│   ├── 📄 Typography Styles
│   │   ├── Cinematic Title (Cinzel Bold 40/48)
│   │   ├── Screen Title (Cinzel Bold 28/34)
│   │   ├── Section Header (Oswald SemiBold 22/28)
│   │   ├── Card Title (Oswald Medium 18/24)
│   │   ├── Button Label (Oswald SemiBold 18/22, UPPERCASE)
│   │   ├── Body Text (Inter Medium 16/22)
│   │   ├── UI Label (Inter SemiBold 14/18)
│   │   ├── Caption (Inter Medium 12/16)
│   │   └── Badge (Inter Bold 11/14)
│   │
│   ├── 📄 Spacing & Grid
│   │   ├── Spacing scale: 2/4/8/16/24/32/48px
│   │   ├── Screen frame: 1170×2532 with 16px horizontal padding
│   │   ├── Safe areas: 59px top (Dynamic Island), 34px bottom (Home indicator)
│   │   └── Grid configurations: 4-col inventory, 3-col equipment, 2-col nav
│   │
│   ├── 📄 Effects & Shadows
│   │   ├── Shadow tokens: sm/md/lg/xl/gold/gold-lg/inset
│   │   ├── Glow tokens: gold/rarity/enchanted/pulse
│   │   ├── Border tokens: subtle/medium/strong/gold/ornament
│   │   └── Overlay tokens: dark/vignette/noise
│   │
│   └── 📄 Material Textures
│       ├── Dark Stone noise (3% overlay)
│       ├── Leather grain (5% overlay)
│       ├── Parchment texture (8% overlay)
│       ├── Hammered metal (4% overlay)
│       └── Ornamental border SVGs
│
├── 📁 🧩 Components
│   │
│   ├── 📁 Atoms
│   │   ├── Button/Primary — Default, Pressed, Disabled, Loading (4 variants)
│   │   ├── Button/Secondary — Default, Pressed, Disabled (3 variants)
│   │   ├── Button/Danger — Default, Pressed, Disabled (3 variants)
│   │   ├── Button/Icon — Default, Pressed, Disabled (3 variants)
│   │   ├── Input/Text — Empty, Focused, Filled, Error, Disabled (5 variants)
│   │   ├── Input/Password — Same 5 states + toggle visibility icon
│   │   ├── Badge/Rarity — Common, Uncommon, Rare, Epic, Legendary (5 variants)
│   │   ├── Badge/Status — Equipped, New, Locked (3 variants)
│   │   ├── Badge/Count — Notification number badge (red circle)
│   │   ├── ProgressBar/HP — High, Mid, Low, Critical-Pulse (4 variants)
│   │   ├── ProgressBar/XP — Default + Level-Up flash state
│   │   ├── ProgressBar/Stamina — Default
│   │   ├── ProgressBar/Quest — Default (gold)
│   │   ├── ProgressDots — 4-step variant (1/2/3/4 active)
│   │   ├── Icon/Stat — 8 color variants (STR/AGI/VIT/END/INT/WIS/LUK/CHA)
│   │   ├── Icon/Class — 4 variants (Warrior/Rogue/Mage/Tank)
│   │   ├── Icon/Zone — 3 color variants (Head/Chest/Legs)
│   │   ├── Icon/Currency — Gold, Gems, Rating
│   │   ├── Toggle/Gender — Male/Female pill group
│   │   ├── Divider/Standard — 1px with diamond endpoints
│   │   ├── Divider/Section — 2px gold with diamond endpoints
│   │   └── Divider/Ornamental — Header underline with glow
│   │
│   ├── 📁 Molecules
│   │   ├── StatRow — Label + Value + [−] + [+] buttons + optional color bar
│   │   ├── ItemCard — Icon letter + rarity frame + name + level + equipped badge
│   │   ├── ShopItemCard — Icon + name + rarity tag + price + BUY button
│   │   ├── OpponentCard — Avatar + name + class + rating + FIGHT button
│   │   ├── QuestCard — Icon + title + progress bar + reward + CLAIM button
│   │   ├── AchievementCard — Title + desc + progress + reward badge
│   │   ├── BPRewardNode — Level number + icon + amount + claimed/locked state
│   │   ├── DungeonCard — Icon + name + floor progress + boss name + ENTER button
│   │   ├── DayCard — Day number + reward icon + claimed/current/upcoming state
│   │   ├── LeaderboardRow — Rank medal + name + class icon + value
│   │   ├── RaceCard — Icon + name + bonuses + description (selectable)
│   │   ├── ClassCard — Icon + name (selectable, 2×2)
│   │   ├── AvatarCard — Photo + name (selectable, 2×2)
│   │   ├── NavTile — Icon + title + subtitle (2×2 hub grid)
│   │   ├── CurrencyRow — Gold + Gems + Rating in horizontal row
│   │   └── Toast — Icon + message + type border (4 type variants)
│   │
│   ├── 📁 Organisms
│   │   ├── ScreenHeader — Back button + Title + optional right action
│   │   ├── BottomNav — 3 tabs: HUB/HERO/LEADER with active/inactive states
│   │   ├── FilterBar — Horizontal scrollable filter tabs
│   │   ├── ItemDetailModal — Full stat sheet + comparison + equip/sell actions
│   │   ├── DailyLoginPopup — 7-day grid + streak bonus + claim button
│   │   ├── CombatFighterPanel — Avatar + name + class + HP bar + status effects
│   │   ├── CombatTurnLog — Scrollable turn-by-turn text log
│   │   ├── EquipmentGrid — 12-slot paper doll with slot labels
│   │   ├── StanceSelector — Attack (3 zones) + Defense (3 zones) + summary
│   │   └── CharacterSummary — Avatar + name + class/race + stats + XP bar
│   │
│   └── 📁 Templates
│       ├── ScreenLayout — ScreenHeader + scrollable content + BottomNav
│       ├── ModalLayout — Overlay + centered panel + close button
│       ├── LoadingState — Spinner + text (full screen variant)
│       └── EmptyState — Icon + title + subtitle + optional CTA
│
├── 📁 📱 Screens (1170×2532 frames)
│   │
│   │  Each screen has multiple STATES/VARIANTS as separate frames:
│   │
│   ├── 01 - Splash Screen
│   │   ├── Loading state (progress bar visible)
│   │   └── Ready state (tap prompt pulsing)
│   ├── 02 - Login Screen
│   │   ├── Default (empty fields)
│   │   ├── Focused (email field active)
│   │   ├── Error (validation message shown)
│   │   └── Loading (spinner overlay)
│   ├── 03a - Onboarding Step 1 (Race Selection)
│   │   ├── No selection
│   │   └── Race selected (e.g., Orc highlighted gold)
│   ├── 03b - Onboarding Step 2 (Gender/Avatar - Male)
│   ├── 03c - Onboarding Step 2 (Gender/Avatar - Female)
│   ├── 03d - Onboarding Step 3 (Class Selection)
│   │   ├── No selection
│   │   └── Class selected (info panel visible)
│   ├── 03e - Onboarding Step 4 (Name & Summary)
│   ├── 04 - Hub Screen
│   │   ├── Default (all banners visible)
│   │   ├── First win claimed (banner hidden)
│   │   └── Low stamina (training tile dimmed)
│   ├── 05 - Character Screen
│   │   ├── Default (stat points = 0, +buttons disabled)
│   │   └── Allocating (stat points > 0, modified stats green)
│   ├── 06 - Stance Selector
│   ├── 07 - Inventory Screen
│   │   ├── All tab active (default sort)
│   │   ├── Weapon filter active
│   │   └── Empty state (no items)
│   ├── 08 - Item Detail Modal (overlay)
│   │   ├── Unequipped item (EQUIP + SELL buttons)
│   │   ├── Equipped item (UNEQUIP button)
│   │   └── Comparison visible (▲ green / ▼ red stat deltas)
│   ├── 09 - Equipment Screen
│   │   ├── Partially equipped
│   │   └── Fully equipped
│   ├── 10 - Arena Screen
│   │   ├── Opponents tab (3 opponent cards)
│   │   ├── Revenge tab
│   │   └── History tab
│   ├── 11 - Combat Screen
│   │   ├── Turn start (both fighters full HP)
│   │   ├── Mid-combat (damage indicators, status effects)
│   │   └── Final blow (one fighter at 0 HP)
│   ├── 12a - Combat Result (Victory)
│   ├── 12b - Combat Result (Defeat)
│   ├── 13 - Loot Screen
│   │   ├── Common item reveal
│   │   └── Legendary item reveal (golden particles)
│   ├── 14 - Dungeon Select
│   │   ├── Default (Normal difficulty)
│   │   └── All dungeons visible, progress shown
│   ├── 15 - Dungeon Room
│   │   ├── Floor 1 entry
│   │   ├── Mid-dungeon progress
│   │   └── Boss floor
│   ├── 16 - Shop Screen
│   │   ├── Weapons tab
│   │   ├── Armor tab
│   │   ├── Consumables tab
│   │   └── Special tab
│   ├── 17 - Battle Pass
│   │   ├── Free track progress
│   │   └── Premium track (locked/unlocked)
│   ├── 18 - Achievements
│   │   ├── Combat category
│   │   └── With unlocked achievement (CLAIM visible)
│   ├── 19 - Daily Quests
│   │   ├── Mixed progress (some complete, some in-progress)
│   │   └── All complete (all CLAIM buttons)
│   ├── 20 - Daily Login Popup (overlay)
│   │   ├── Day 1 (fresh streak)
│   │   ├── Day 4 (mid-week)
│   │   └── Day 7 (bonus chest)
│   ├── 21 - Leaderboard
│   │   ├── Rating tab
│   │   ├── Level tab
│   │   └── Gold tab
│   ├── 22 - Profile Screen
│   ├── 23 - Shell Game
│   │   ├── Betting phase
│   │   ├── Shuffling animation
│   │   ├── Pick phase
│   │   ├── Reveal (win)
│   │   └── Reveal (lose)
│   ├── 24 - Settings
│   ├── 25 - Gold Mine (placeholder — coming soon)
│   └── 26 - Dungeon Rush (placeholder — coming soon)
│
├── 📁 🔄 User Flows (FigJam or Prototype)
│   ├── Flow 1: New Player Onboarding (Splash → Login → Create Hero → Hub)
│   ├── Flow 2: Returning Player Login (Splash → Auto-login → Hub)
│   ├── Flow 3: Character Progression (Earn XP → Level Up → Allocate → Equip)
│   ├── Flow 4: PvP Battle (Hub → Arena → Pick Opponent → Combat → Result → Loot)
│   ├── Flow 5: PvE Dungeon Run (Hub → Dungeon Select → Room → Combat → Boss → Complete)
│   └── Flow 6: Inventory Management (Inventory → Filter → Item Detail → Equip/Sell → Equipment)
│
├── 📁 🗺️ Screen Map
│   └── Full navigation diagram (all 26 screens connected with arrows)
│
└── 📁 📐 Prototyping
    ├── Main Happy Path: Splash → Login → Hub → Arena → Combat → Victory → Loot → Hub
    ├── Onboarding Path: Login → Step 1-4 → Hub
    ├── Dungeon Path: Hub → Select → Room 1...N → Boss → Complete → Hub
    └── Inventory Path: Hub → Inventory → Item Detail → Equip → Equipment → Hub
```

### 7.2 — Component Naming Convention (AAA)

> Figma component names follow: `Category/Name/State/Variant`
> Every interactive component MUST have all applicable states defined.

```
BUTTONS:
  Button/Primary/Default
  Button/Primary/Pressed
  Button/Primary/Disabled
  Button/Primary/Loading
  Button/Secondary/Default
  Button/Secondary/Pressed
  Button/Secondary/Disabled
  Button/Danger/Default
  Button/Danger/Pressed
  Button/Danger/Disabled
  Button/Icon/Default
  Button/Icon/Pressed

CARDS:
  Card/Item/[Rarity]/Default         (5 rarity × Default)
  Card/Item/[Rarity]/Pressed         (5 rarity × Pressed)
  Card/Item/[Rarity]/Equipped        (5 rarity × Equipped)
  Card/Item/[Rarity]/New             (5 rarity × New badge)
  Card/Item/Locked                   (single locked state)
  Card/Opponent/Default
  Card/Opponent/Pressed
  Card/Race/Default
  Card/Race/Pressed
  Card/Race/Selected
  Card/Class/[ClassName]/Default     (4 class × Default)
  Card/Class/[ClassName]/Selected    (4 class × Selected)
  Card/Avatar/[Gender]/Default       (Male+Female × Default)
  Card/Avatar/[Gender]/Selected      (Male+Female × Selected)
  Card/Quest/InProgress
  Card/Quest/Complete
  Card/Quest/Claimed
  Card/Achievement/Locked
  Card/Achievement/Unlocked
  Card/Achievement/Claimed
  Card/Day/Upcoming
  Card/Day/Current
  Card/Day/Claimed

NAVIGATION:
  Nav/BottomTab/Active
  Nav/BottomTab/Inactive
  Nav/GridTile/Default
  Nav/GridTile/Pressed
  Nav/GridTile/Disabled
  Tab/Filter/Active
  Tab/Filter/Inactive
  Tab/Filter/Pressed

PROGRESS:
  Bar/HP/High                        (>60%, green)
  Bar/HP/Mid                         (30-60%, amber)
  Bar/HP/Low                         (≤30%, red + pulse)
  Bar/HP/Empty                       (0%, dim)
  Bar/XP/Default
  Bar/XP/LevelUp                    (flash animation keyframe)
  Bar/Stamina/Default
  Bar/Quest/Default

INPUTS:
  Input/Text/Empty
  Input/Text/Focused
  Input/Text/Filled
  Input/Text/Error
  Input/Text/Disabled
  Input/Password/Empty
  Input/Password/Focused (visible)
  Input/Password/Focused (hidden)

BADGES & ICONS:
  Badge/Rarity/[5 tiers]
  Badge/Equipped
  Badge/New
  Badge/Count/[number]
  Icon/Stat/[8 stats]
  Icon/Class/[4 classes]
  Icon/Zone/[3 zones]
  Icon/Currency/Gold
  Icon/Currency/Gems
  Icon/Currency/Rating

MODALS & OVERLAYS:
  Modal/ItemDetail/Weapon
  Modal/ItemDetail/Armor
  Modal/DailyLogin/Day[1-7]
  Toast/Success
  Toast/Error
  Toast/Info
  Toast/Warning
  Toast/Loot

MISC:
  Divider/Standard
  Divider/Section
  Divider/Ornamental
  Loading/Spinner
  Loading/Shimmer
  Empty/Default
```

### 7.3 — Auto Layout Rules

```
SCREEN LEVEL:
  Frame: 1170×2532
  Auto-layout: Vertical
  Padding: 16px horizontal, 0px vertical (safe areas handled by spacers)
  Gap: 0 (each section manages its own spacing)
  Top spacer: 59px (iOS Dynamic Island safe area)
  Bottom spacer: 34px (iOS Home indicator safe area)

HEADER:
  Auto-layout: Horizontal
  Height: 48px
  Alignment: Center vertically
  Left: Back button (48×48 touch target)
  Center: Title (fill remaining space, centered text)
  Right: Optional action button (48×48)
  Bottom: 1px divider line --border-subtle

CONTENT AREA:
  Auto-layout: Vertical, scrollable
  Padding: 0px (inherits screen padding)
  Gap: 16px between sections
  Fill: Remaining space between header and bottom nav

BOTTOM NAV:
  Auto-layout: Horizontal
  Height: 64px
  Distribution: Space-evenly
  Top border: 1px --border-subtle
  Background: --bg-secondary
  Each tab: 48×48 icon + label below (Inter Medium 11px)

CARDS:
  Auto-layout: Vertical
  Inner padding: 16px
  Gap between elements: 8px
  Corner radius: 12px
  Border: As specified per card type/state

GRIDS:
  Inventory: Auto-layout wrap, 4 columns, 8px gap
  Equipment: Auto-layout wrap, 3 columns, 12px gap
  Class selection: Auto-layout wrap, 2 columns, 12px gap
  Avatar selection: Auto-layout wrap, 2 columns, 12px gap
  Hub nav tiles: Auto-layout wrap, 2 columns, 12px gap
  Filter tabs: Horizontal auto-layout, 4px gap, horizontal scroll

BUTTONS:
  Auto-layout: Horizontal, center-center
  Height: 56px (primary), 48px (secondary), 36px (small)
  Padding: 24px horizontal, 16px vertical (primary)
  Width: Fill container (full-width) or Hug contents (inline)
  Min-width: 120px (inline buttons)
```

### 7.4 — Figma Variables & Styles Setup

```
FIGMA VARIABLES (Collections):

Collection: "Colors"
  Mode: Dark (single mode — dark fantasy only)
  Variables: Map all --bg-*, --accent-*, --text-*, --border-*, --rarity-*, --stat-*, --class-*, --rank-* tokens

Collection: "Spacing"
  Variables: space-2xs(2), space-xs(4), space-sm(8), space-md(16), space-lg(24), space-xl(32), space-2xl(48)

Collection: "Sizing"
  Variables: button-height-lg(56), button-height-md(48), button-height-sm(36), input-height(52),
             avatar-lg(72), avatar-md(56), avatar-sm(40), bottom-nav(64), touch-min(48)

Collection: "Radius"
  Variables: button(8), card(12), panel(8), modal(16), input(8), full(999)

FIGMA TEXT STYLES (9 styles):
  Display/Cinematic:  Cinzel Bold 40/48, LS +2
  Display/Screen:     Cinzel Bold 28/34, LS +1.5
  Heading/Section:    Oswald SemiBold 22/28, LS +1
  Heading/Card:       Oswald Medium 18/24, LS +0.5
  Label/Button:       Oswald SemiBold 18/22, LS +2, UPPERCASE
  Body/Default:       Inter Medium 16/22, LS 0
  Body/Label:         Inter SemiBold 14/18, LS +0.5
  Body/Caption:       Inter Medium 12/16, LS 0
  Body/Badge:         Inter Bold 11/14, LS +0.5

FIGMA EFFECT STYLES (8 styles):
  Shadow/Small:       0 2px 4px rgba(0,0,0,0.3)
  Shadow/Medium:      0 4px 12px rgba(0,0,0,0.4)
  Shadow/Large:       0 8px 24px rgba(0,0,0,0.6)
  Shadow/XLarge:      0 12px 48px rgba(0,0,0,0.8)
  Shadow/Gold:        0 4px 12px rgba(212,165,55,0.3)
  Shadow/Inset:       inset 0 2px 4px rgba(0,0,0,0.5)
  Glow/Gold:          0 0 8px rgba(212,165,55,0.4)
  Glow/Enchanted:     0 0 16px rgba(0,212,255,0.3)
```

### 7.5 — Design QA Checklist

> Use this checklist before marking any screen as "design complete."

```
VISUAL QUALITY:
  □ Background uses dark stone material (not flat #0D0D12 alone)
  □ All panels have metallic top-edge highlight
  □ Cards use rarity-colored borders with appropriate glow
  □ Gold elements use gradient (#D4A537 → #B8860B), not flat color
  □ Ornamental dividers used between major sections
  □ Screen has vignette overlay on edges

TYPOGRAPHY:
  □ No text below 11px
  □ No font weight below Medium (500)
  □ Screen title uses Cinzel Bold 28px UPPERCASE
  □ Button labels use Oswald SemiBold 18px UPPERCASE
  □ Body text uses Inter Medium 16px minimum
  □ Text contrast meets WCAG AAA (7:1 for primary, 4.5:1 for secondary)

INTERACTION:
  □ All buttons have Default + Pressed + Disabled states designed
  □ All cards have Default + Selected states (where applicable)
  □ Input fields have Empty + Focused + Filled + Error + Disabled states
  □ Active tab clearly distinguishable from inactive (gold vs gray)
  □ Touch targets ≥ 48px on all interactive elements

LAYOUT:
  □ Safe areas respected (59px top, 34px bottom)
  □ Content doesn't overlap bottom nav
  □ Scrollable areas have clear scroll indicators
  □ Maximum 4-6 primary actions visible at once
  □ Consistent 16px screen padding

NAVIGATION:
  □ Back button present on all non-hub screens
  □ Bottom nav visible on main screens (Hub, Character, Leaderboard)
  □ No dead ends — every screen has a clear exit
  □ Depth ≤ 3 levels from Hub

POLISH:
  □ Loading state designed for data-fetching screens
  □ Empty state designed for list/grid screens
  □ Error state designed for form screens
  □ Animations documented (enter/exit/interaction timing)
```

---

*End of Document — Version 3.0 AAA Quality Standard*
