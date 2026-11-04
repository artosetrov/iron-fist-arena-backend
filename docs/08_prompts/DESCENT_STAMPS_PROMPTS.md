# The Descent — kill stamps (2026-11-03)

Two stamps slam across the scene when a foe dies (`DescentBanner`, `Views/Minigames/DescentStage.swift`):

| Asset | When | What |
|---|---|---|
| `rush2-stamp-slain` | any kill (spoils) | SLAIN brushed in bone paint across a dried-blood smear |
| `rush2-stamp-guardian-slain` | the guardian (relic screen) | GUARDIAN SLAIN carved and gilded in a black iron plaque framed by skulls |
| `rush2-stamp-depth-cleared` | a depth's guardian is dead (depth-cleared screen, `DescentDepthClearStage`) | DEPTH CLEARED brushed in bone paint across a torn crimson banner |

They are the one approved exception to "no text in art" (ART_STYLE_GUIDE §1): the word is part of
the painting. English only — a localisation needs its own set. DEPTH CLEARED joined on 2026-11-04 (Art).

## How they were made

1. **Word-less plates** (Higgsfield, `nano_banana_2_1`, 16:9, style bible verbatim, the approved
   `Items/chest_godplate` as the golden anchor): the blood smear on a flat green key
   (job `cbb0cd30-7f69-4391-9ed3-5d076b82ef7d`), the iron plaque on a flat magenta key
   (job `48c11a3a-daf1-443e-8e6d-ae1c8e0cd632`), the torn crimson banner for DEPTH CLEARED
   (job `85fe1621-70cc-4d48-9c6c-f2e516ccc6a7`).
2. **Lettering as an edit of the plate** (`gpt_image_2_5`, 2k, quality high, the plate as the only
   reference — "change only one thing"). Four were made, one per model per plate; the GPT Image ones
   were picked for the brush texture (SLAIN) and the clearer two-size hierarchy (GUARDIAN SLAIN).
   Jobs: SLAIN `37fbdf3e-2bc4-4712-9f8c-65de3582bfef`, GUARDIAN SLAIN `b80ee532-55ed-4b16-9c80-5cde8ac93ae1`.
3. **Key and pack**: the generator's keys are muted (≈ `#79977A` green, `#A2436B` magenta), so they were keyed
   by distance to the sampled border colour with a soft ramp, edge colours unmixed against the key,
   green spill clamped (G ≤ max(R, B) — nothing in these plates is green), trimmed, written at
   320 / 640 / 960 px wide (@1x/@2x/@3x, shown at 300 pt) and palette-compressed with libimagequant.

## Prompts

The style bible with the subject slots filled; the only change to its wording is
"no text, letters or logos" → "no **other** text, letters or logos".

### SLAIN (edit of the blood smear)

```
Pen and ink illustration of a dried-blood brush smear with the word SLAIN hand-lettered across it, bold black ink outlines on every element, colored with dark oxblood and rust-brown tones and bone-white accents, ragged dry-brush edges and drips running down, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no other text, letters or logos, no particles. Edit the attached image and change only one thing: add the word SLAIN. Keep the smear, its strokes, drips, colours, line work and the flat background exactly as they are. The word: five capital letters, spelled exactly S-L-A-I-N, hand-painted with a stiff brush in bone-white paint with a thin black ink outline, heavy rough strokes with dry-brush edges, like a battle mark daubed on stone. The letters are large: they fill the hollow band between the upper and lower blood strokes and overlap both, centred left to right. No other letters, no shadow, no glow.
```

### GUARDIAN SLAIN (edit of the iron plaque)

```
Pen and ink illustration of a black iron plaque framed by skulls and crossed bones with the words GUARDIAN SLAIN carved into its dark stone face, bold black ink outlines on every element, colored with charcoal iron and grey stone tones and tarnished gold accents, rivets at the corners and cracks in the stone, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no other text, letters or logos, no particles. Edit the attached image and change only one thing: carve an inscription into the dark stone panel. Keep the frame, skulls, bones, rivets, cracks, colours, line work and the flat magenta background exactly as they are. The inscription: two centred lines of carved Roman capital letters with sharp serifs, filled with tarnished gold and outlined in black ink, like a tomb inscription. First line GUARDIAN, small. Second line SLAIN, about twice as tall. Spelled exactly G-U-A-R-D-I-A-N and S-L-A-I-N. No other letters, no shadow, no glow.
```

### DEPTH CLEARED (edit of the torn crimson banner, 2026-11-04)

Made with the same edit recipe as SLAIN, the banner as the only reference; two letterings were made —
bone paint and gilded — and Art picked **bone** on the canvas "Descent run screen" (it reads better over
the night-graded arena and does not repeat the gold of GUARDIAN SLAIN, which lands a moment earlier).
The edit's exact wording and job id were not kept with the asset. To remake it, use:

```
Pen and ink illustration of a torn crimson cloth banner nailed up with iron rings, with the words DEPTH CLEARED hand-lettered across it, bold black ink outlines on every element, colored with deep crimson and rust-brown tones and bone-white accents, ragged torn ends and a few stitched patches, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no other text, letters or logos, no particles. Edit the attached image and change only one thing: add the words DEPTH CLEARED. Keep the banner, its folds, tears, rings, colours, line work and the flat background exactly as they are. The words: one line of capital letters, spelled exactly D-E-P-T-H C-L-E-A-R-E-D, hand-painted with a stiff brush in bone-white paint with a thin black ink outline, heavy rough strokes with dry-brush edges. Large, centred on the banner's flat middle panel. No other letters, no shadow, no glow.
```

Packed as above: keyed, trimmed to 960 × 274, written at 320 / 640 / 960 px (@1x/@2x/@3x, shown at
up to 340 pt) as palette PNGs.

## Check before shipping a new stamp

- Spelling at 100 % — generators drop or double letters.
- Edges on a dark and a light background: no key fringe, no halo.
- In the scene at display size (300 pt), over the darkest and the palest room (`rush2-bg-ossuary-hall`).
