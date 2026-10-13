# Hexbound — Art Style Guide for AI Image Generation

Canonical style reference for all AI-generated art. Use this guide for all DALL-E, Midjourney, and other image generation prompts.

---

## Visual DNA

### Drawing Technique

- **Pen and ink illustration** — NOT digital painting, NOT concept art, NOT watercolor
- Every element outlined with **bold black ink** (crisp, sharp outlines)
- Interior areas filled with **colored ink or wash** (visible brushstrokes, textured, NOT flat)
- Shadows created by darkening the fill, NOT blurring or soft lighting
- No glow, fog, mist, atmospheric lighting, or volumetric effects
- Style closest to: **D&D Monster Manual / Pathfinder rulebook / Darkest Dungeon**

### Color Palette

**Base:** Muted earth tones — gray stone, brown, beige/bone, dark iron, charcoal

**Accents:** 1-2 saturated colors per illustration. Common accent colors:
- **Purple/violet:** magic, undead, curses (skeleton knight, lich king, bone colossus, necro priest)
- **Green:** poison, disease, nature (cave spider, plague bearer)
- **Orange:** fire, rust, lava (fire imp, rusty golem)
- **Blue/white:** ice, ghosts, frost (banshee, ice wraith)
- **Red/brown:** blood, flesh, decay (ghoul brute, corpse weaver)
- **Gold/bronze:** metal, wealth, light (iron guardian, temple statue)

### Detail & Texture

- Very high detail — cracks, rivets, scratches, drips, rust, corrosion
- Small props: skulls, bones, chains, cobwebs, swords, scrolls, glyphs
- Textures: rough stone, tattered fabric, corroded metal, decay and rot
- Every surface looks **aged and worn** — nothing clean, nothing new

### Composition

- Subject **isolated on white or transparent background** — like a game sprite
- No background scenery, no environment, no landscape
- Characters usually in 3/4 view, slightly dynamic pose (not stiff, not idle)
- Objects/scenes (mines, locations, structures) in frontal or 3/4 view

### Mood

- **Grimdark / gothic dark fantasy**
- Skulls, bones, decay — recurring motif across almost every illustration
- Dark, dangerous, abandoned — nothing "pretty" or "magical" in a positive sense
- Even "good" elements (gold, crystals) surrounded by ruin and decay

### Proportions

- Slightly stylized, NOT photorealistic
- NOT chibi, NOT anime — western illustration style
- Solid, heavy forms (armor, weapons, creatures)

---

## Generation Rules — AI paints, code rules

> Added 2026-10-13. Source: the `ref2game` skill (studioigor) and its 5-game study; adapted to Hexbound (SwiftUI, xcassets). These rules sit **on top of** the Visual DNA above and apply to every new or regenerated asset.

### 1. What to generate vs what to do in code

| Generate (image model) | Do in code (SwiftUI / Metal / VFX layer) |
|---|---|
| Characters, bosses, NPCs, portraits | Idle/hit/flash states, tint, outline pass, drop/contact shadow |
| Buildings, props, item icons, HUD frames | Glow, pulse, selected/locked states, badges, counters |
| Painted backgrounds split by depth (far / mid / near) | Parallax, haze, vignette, fog, light pools, god rays |
| Shape-only FX plates (slash arc, burst, shield) — neutral, unlit | Colour tint per damage type, particles, screen flash, motion |
| — | **All text** (DODGE / MISS / CRIT / numbers) — typography from the design system, localizable |

**Never bake into an image:** glow or bloom, light rays, cast shadows, motion blur, **text or glyphs**, particles, water/fire motion. Each one duplicates an engine effect, breaks alpha, or freezes something that must move. If the reference shows a lit lamp, generate it **unlit-neutral** and add the glow in code.

> Known violations to retire: `fx-dodge-text`, `fx-miss-text`, `fx-crit-text`, `fx-critical-text` (256×256 PNGs with baked text / crosshair, shown fullscreen in combat). Replace with a code-drawn callout (Cinzel-Bold, `DarkFantasyTheme` tokens, opacity-only animation). Tracked in `docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md` follow-ups.

### 2. The style bible rides on every call, verbatim

The **Prompt Template** below is the style bible. Prepend it **word for word** to every generation; never paraphrase it per asset. One wording for the whole pack is what keeps separate calls consistent. Asset specifics go after it, never inside it.

**Fixed light sentence (same words on every call):**

```
Lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground.
```

Light direction drifting between pieces is the No. 1 "AI slop" tell. Flip sprites only in code and keep the lit side consistent.

### 3. Consistency across separate generations

- **One call = one image.** Asking one prompt for "6 variants" gives near-duplicates, not a kit. Distinct assets need distinct calls, or one deliberate sheet.
- **Golden-set anchor.** Once the first asset of a class is approved, attach it as a second reference on every later call of that class ("same character: keep face, outfit, proportions" / "same style as this approved building"). Current anchors: see *Reference Assets in Project* below.
- **Kit-mates on one sheet** for sets that must match (icon sets, tile variants, 4 shields): a row or grid with **wide empty gutters**, sliced afterwards. Pieces made in one image share light, palette and line. Characters are the exception — anchor each alone at full resolution.
- **Edit-based variants** for states (damaged, lit, closed eyes, rarity recolour): edit the approved image with "change only X; keep everything else identical". Holds identity far better than a fresh prompt. Keep edit chains short — drift accumulates; when it shows, edit from the approved base again.
- **Reject budget: 2 re-rolls.** Past that, change the prompt, the anchor or the approach (sheet, edit from the nearest good asset) — not the dice. Log rejects and the reason.

### 4. Resolution: generate above display size, downscale

Generate every asset at **≥ 3× its largest display size in points** (Pro devices are 3x), then downscale into `@1x / @2x / @3x` slots. Never ship a 1x-only imageset (see `docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md`, finding A1). Downscaling also removes the micro-detail-everywhere look; upscaling never fixes it.

| Asset class | Display (pt, max) | Generate at (px) |
|---|---|---|
| Hub building | ~570 | 2048 |
| Boss / hero full body | ~400 | 1536–2048 |
| Portrait / NPC bust | ~200 | 1024 |
| FX plate | ~240 | 1024 |
| Item / HUD icon | ~64 | 512 |

### 5. Alpha: key colour, not white

Our palette is bone, beige, grey stone — keying on white eats edges and highlights. Generate on a **flat saturated key colour far from the subject's palette** (magenta `#FF00FF` by default; green `#00FF00` for purple/magic subjects), then key it out (`.claude/skills/remove-background` as the fallback for hair, smoke, wisps). Ask for: *centred, with margin, one subject only, flat {key colour} background, no floor, no cast shadow, no frame*. Check edges at 100% for halo/fringe before accepting.

### 6. Slop signals and their fixes

| Signal | Fix |
|---|---|
| Micro-detail everywhere, no hierarchy | Ask for big quiet shapes; generate large and downscale; detail only at the focal point |
| Light direction differs between pieces | Fixed light sentence on every call; reject, don't patch |
| Glossy "3D render" plastic look | Name the medium ("pen and ink… not a 3D render"); **reject** — post can't fix it |
| Oversaturation / neon | Clamp in post; keep high chroma only for the 1–2 accents |
| Line weight varies between assets | Same bible wording; compare outline widths at display size |
| Scale / texel density varies | Fixed canvas and fill ratio per class (§4); normalise in code |
| Halo or fringe around the sprite | Key colour + un-mix edges (§5) |
| Gibberish detail (pseudo-runes, extra fingers, melted props) | Exclude "text, letters, logos" in the prompt (decorative glyphs are part of the style — keep them, but review them at 100%); review at 100%; regenerate |
| Different design between views/states of one character | Golden anchor + edit-based variants (§3) |
| A frozen "postcard" | Not an art problem — motion/feedback (`pulse` agent) |

**Never write** generic quality boosters ("high detail", "8k", "masterpiece"), mood-lighting words ("cinematic", "epic", "dramatic lighting"), "trending", or artist names. They pull toward the model's default look and fight the reference.

### 7. Acceptance checklist (the `canvas` agent's list)

Approve assets only **in the assembled screen at display size** on a 3x device/simulator. "Looks great alone" is not approval.

1. One rendering family — pen-and-ink lineart, nothing painterly/3D/pixel next to it
2. One texel density — art pixels / line weights the same size on screen as neighbours (no mixels)
3. One outline weight and one light direction across sprites, props and code-drawn pieces
4. No baked glow, shadow, text, particles (§1)
5. No generator artifacts: garbled glyphs, logos, halos, cut edges, extra limbs
6. Correct `@2x/@3x` slots filled; no runtime upscale > 1.0×
7. Accent colour is one of the palette accents and reads at icon size
8. Silhouette reads at the smallest display size it is used at

---

## Landing Page Character Style (SEPARATE STYLE)

> ⚠️ **Это отдельный стиль** — только для персонажей лендинга (`LANDING_ART_PROMPTS.md`). В игре НЕ используется.

### Ключевые отличия от основного стиля

| | Основной (in-game) | Лендинговый (landing) |
|---|---|---|
| Техника | Pen and ink, линейная | Watercolor + pen and ink |
| Пропорции | Solid, slightly stylized | **Exaggerated caricature** |
| Персонажи | Серьёзные, угрожающие | **Ugly-funny — repulsive yet humorous** |
| Фон | White / transparent | White |
| Фон (боссы) | Warm cream parchment | — |

### Обязательные элементы лендингового стиля

Каждый персонаж лендинга ДОЛЖЕН содержать:
- **Exaggerated proportions and asymmetrical features** — ничего симметричного и правильного
- **Ugly-funny — repulsive yet humorous** — персонаж смешной за счёт уродства, не страшный
- **Visible warts, scars, grime and dirty details** — грязь, шрамы, бородавки по ситуации
- **Asymmetrical eyes / lopsided expressions** — один глаз больше, кривая ухмылка, перекошенный рот
- Специфика по классу: drool (warrior), age spots/arcane stains (mage), beady eyes (tank), lolling tongue (dogfolk)

### Prompt структура (лендинг)

```
use the uploaded image as base reference for character style and proportions,
single [TYPE] character,

change appearance details:
[ПОЗА И ОПИСАНИЕ ПЕРСОНАЖА],

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
[СПЕЦИФИЧЕСКИЕ ГРОТЕСКНЫЕ ДЕТАЛИ ПО ПЕРСОНАЖУ],
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
[ЦВЕТОВОЙ АКЦЕНТ],

one character only,
full body или portrait,
[ASPECT RATIO],
plain white background
```

---

## Prompt Template for AI Generation

### Structure

```
Pen and ink illustration of [SUBJECT DESCRIPTION], bold black ink outlines on every element, colored with [BASE TONES] and [ACCENT COLOR] accents, [DETAILS AND PROPS], lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles
```

### Example

```
Pen and ink illustration of a skeletal knight in tarnished plate armor, holding a greatsword, bold black ink outlines on every element, colored with gray stone and bronze tones with purple magical runes etched into the armor, skull face with hollow eye sockets, surrounded by spectral wisps and bone fragments, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles
```

### Negative Prompt (if supported)

```
painting, oil painting, watercolor, digital painting, concept art, realistic, photorealistic, 3D render, soft edges, blurry, atmospheric lighting, volumetric light, fog, mist, glow effects, gradient background, smooth shading, airbrushed, anime, pixel art
```

---

## Key Phrases That Work

| Desired Effect | Prompt Phrase |
|---|---|
| Bold outlines | `bold black ink outlines on every element` |
| Not a painting | `pen and ink illustration`, `not a painting` |
| Correct genre | `fantasy RPG rulebook illustration` |
| Isolation | `isolated on white background` |
| Sharpness | `crisp sharp black outlines`, `comic book lineart` |
| Textured fill | `colored with muted earth tones` |
| Grimdark details | `weathered, corroded, cracked, bone fragments, skulls, cobwebs` |

---

## Phrases That DON'T Work (Avoid)

| Bad Phrase | Why |
|---|---|
| `Darkest Dungeon inspired` | AI interprets as a painted scene, loses lineart style |
| `dark fantasy` (alone) | Too vague, results in concept art instead |
| `glowing`, `magical light` | Adds soft glow effects, contradicts lineart |
| `atmospheric` | Introduces fog, mist, volumetric lighting |
| `detailed`, `high quality` | Generic, doesn't help with style |
| `transparent background` | AI often ignores; use a flat **magenta** key background and key it out (see Generation Rules §5). White eats bone/beige edges |

---

## Standard Asset Sizes

> ⚠️ Superseded by Generation Rules §4: generate at ≥ 3× display size and fill all three scale slots. Table kept for aspect ratios.

| Asset Type | Size (1x) | Size (2x Retina) | Aspect Ratio |
|---|---|---|---|
| Boss full body | ~512×512 | 1024×1024 | 1:1 |
| Boss portrait | ~256×256 | 512×512 | 1:1 |
| Mine card illustration | ~512×340 | 1024×680 | 3:2 |
| Icon (sidebar) | ~64×64 | 128×128 | 1:1 |
| Loading screen | ~1024×768 | 2048×1536 | 4:3 |
| Hero character | ~512×512 | 1024×1024 | 1:1 |

---

## Reference Assets in Project

### Bosses (Full Body — Most Characteristic Style)

- `Assets.xcassets/Bosses/boss-skeleton-knight-full` — Typical style: armor, purple accent, skulls
- `Assets.xcassets/Bosses/boss-rusty-golem-full` — Metal, rust, orange accent
- `Assets.xcassets/Bosses/boss-cave-spider-full` — Creature, green poison, sharp outlines
- `Assets.xcassets/Bosses/boss-iron-guardian-full` — Heavy metal, gold/bronze accent
- `Assets.xcassets/Bosses/boss-banshee-full` — Cold tones, white/blue accent

### Portraits (Bust — Lineart Technique Visible)

- `Assets.xcassets/Bosses/boss-necro-priest-portrait` — Purple + gold, religious theme
- `Assets.xcassets/Bosses/boss-skeleton-knight-portrait` — Skull and helmet with clear ink outlines
- `Assets.xcassets/Bosses/boss-plague-bearer-portrait` — Skin texture, green poison, flies

### Warning

- `Assets.xcassets/icon-gold-mine` — ⚠️ DIFFERENT style (casual/cartoon) — do NOT use as style reference

---

## Additional Guidelines

### When to Use This Guide

Use this guide when:
- Creating new boss illustrations
- Generating character art
- Making UI backgrounds
- Producing any game-related visual asset
- Briefing illustrators or AI image generation services

### When Generating Prompts

1. Start with the template structure above
2. Plug in your specific subject description
3. Choose 1-2 accent colors from the palette
4. Add relevant details (props, textures, mood)
5. Always end with the standard closing phrase
6. Always include the negative prompt

### Common Mistakes to Avoid

- Don't say "concept art" (you want lineart, not concept art)
- Don't ask for "soft lighting" (contradicts pen and ink)
- Don't skip "bold black ink outlines" (critical for style)
- Don't ask for "3D render" or "realistic" (wrong medium)
- Don't forget "isolated on white background" (important for sprite use)
- Don't skip the negative prompt (helps AI avoid wrong styles)
