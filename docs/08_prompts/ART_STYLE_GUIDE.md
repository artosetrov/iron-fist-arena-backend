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

## Prompt Template for AI Generation

### Structure

```
Pen and ink illustration of [SUBJECT DESCRIPTION], bold black ink outlines on every element, colored with [BASE TONES] and [ACCENT COLOR] accents, [DETAILS AND PROPS], isolated on white background, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text
```

### Example

```
Pen and ink illustration of a skeletal knight in tarnished plate armor, holding a greatsword, bold black ink outlines on every element, colored with gray stone and bronze tones with purple magical runes glowing on the armor, skull face with hollow eye sockets, surrounded by spectral wisps and bone fragments, isolated on white background, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text
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
| `transparent background` | AI often ignores; use `white background`, remove later |

---

## Standard Asset Sizes

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
