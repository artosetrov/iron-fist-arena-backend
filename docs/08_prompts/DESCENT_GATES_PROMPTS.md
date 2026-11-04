# The Descent — guardian gates and faces (2026-11-04)

A depth opens on its guardian waiting in the gate at the top of the stairs (`DescentGateStage`,
`Views/Minigames/DescentRoomScenes.swift`). Chosen by Art on the canvas "Descent run screen",
row "Вход в глубину и «глубина пройдена»": Ossuary **A**, Warrens **B**, Molten **B**.

| Asset | Depth | Painting |
|---|---|---|
| `rush2-bg-ossuary-gate` | I · The Ossuary | the Bone King fills a pointed crypt gate, skull niches either side |
| `rush2-bg-warrens-gate` | II · The Shadow Warrens | the Lord of Shadows grips a timbered tunnel mouth, his one eye burning |
| `rush2-bg-molten-gate` | III · The Molten Heart | the Warden, axe-halberd in hand, between falls of lava |
| `rush2-face-lordshadows`, `rush2-face-warden` | the next guardian on the depth-cleared DESCEND card | head crops of the boss sprites |

## How they were made

1. **Generation** (Higgsfield `nano_banana_2_1`, 3:4, 2k, two per guardian). Full-scene style bible
   (the backdrop variant: "filling the entire frame edge to edge … the scene fills the whole canvas
   with no empty space … no white border, no margins") with the fixed light sentence. References:
   the guardian's own combat sprite first (`rush2-boss-<key>`, "the same character as the first
   attached image"), the depth's room painting second (stonework, palette). The eyes are painted as
   small ember-orange points only — **no glow**; the glow is code.
2. **Crop and pack**: the paper border some results carry (~30 px) was cut, the width trimmed to the
   scene aspect (1290 : 1747, `DescentGeometry.sceneAspect`, the same as every room painting), and the
   result written as JPEG at 430 / 860 / 1290 px wide.
3. **Measure**:
   - the eyes, on the crop the imageset keeps → `DescentGeometry.gateEyes` (centre 0…1 and glow width
     as a share of the painting's width);
   - the mean luminance (Rec. 709, on @3x) → `DescentGeometry.backdropLuma` (the night grade's exposure).
   Re-measure both if a gate is regenerated.
4. **Faces**: a square head crop of `rush2-boss-<key>@3x`, in a soft disc, written at 64 / 128 / 192 px.
   The server names the next one (`depthClear.nextGuardianFace = rush2-face-<boss>`); a new guardian
   needs its face here.

## Prompts

### The Bone King (Ossuary, variant A of 2)

```
Pen and ink illustration of the Bone King, a colossal crowned skeleton king, looming inside a towering pointed stone crypt gateway, filling the entire frame edge to edge, bold black ink outlines on every element, colored with charcoal and bone-grey stone tones and faded purple and tarnished gold accents, he is the same character as the first attached image — grinning skull with a jagged gold crown, purple robe with a white fur collar, heavy gold chains, a long sword in one bony hand and a skull-topped scepter in the other — two small burning ember-orange pinpoints deep in his eye sockets, bony fingers gripping the sides of the arch, the gateway is carved with skulls and rune bands, niches stacked with skulls and bones on both sides, the stonework and palette of the second attached image, Composition, portrait: the gateway and the guardian fill the upper two thirds, the guardian's head about one third from the top, the guardian is enormous, far taller than a man, half swallowed by the black darkness inside the gateway so only the top of the head, the face, the shoulders and the edges are lit, looking down at the viewer; the lower third of the picture is a wide flight of worn empty stone steps rising toward the gate, quiet and uncluttered, darker at the bottom. lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles, no white border, no margins
```

### The Lord of Shadows (Warrens, variant B of 2)

```
Pen and ink illustration of the Lord of Shadows, a colossal hooded shadow wraith, looming inside a jagged tunnel mouth hacked into black rock and braced with rotten timbers and rusted iron, filling the entire frame edge to edge, bold black ink outlines on every element, colored with charcoal rock and dark violet tones and bone-white accents, he is the same character as the first attached image — tattered dark violet hooded robe, a crown of black thorns on the hood, one single huge eye in the darkness of the hood, a necklace of small skulls, long skeletal clawed hands — the single huge eye has a burning ember-orange iris, his clawed hands grip both sides of the tunnel mouth, inked shadow tendrils spill from under his robe down onto the top steps, claw marks scored into the rock, the rock and timber of the second attached image, Composition, portrait: the gateway and the guardian fill the upper two thirds, the guardian's head about one third from the top, the guardian is enormous, far taller than a man, half swallowed by the black darkness inside the gateway so only the top of the head, the face, the shoulders and the edges are lit, looking down at the viewer; the lower third of the picture is a wide flight of worn empty stone steps rising toward the gate, quiet and uncluttered, darker at the bottom. lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles, no white border, no margins
```

### The Warden of the Depths (Molten, variant B of 2)

```
Pen and ink illustration of the Warden of the Depths, a colossal armored knight, looming inside a massive forge gateway of black basalt blocks and riveted iron plates, filling the entire frame edge to edge, bold black ink outlines on every element, colored with black iron and bronze tones and molten orange accents, he is the same character as the first attached image — crested bronze-black helm, heavy ornate plate armour with orange-hot cracks, a tattered red cape, a huge axe-halberd — two burning ember-orange eye slits in his helm, the axe-halberd planted upright before him, thin seams of orange lava in the basalt walls and between the steps, the basalt and lava of the second attached image, Composition, portrait: the gateway and the guardian fill the upper two thirds, the guardian's head about one third from the top, the guardian is enormous, far taller than a man, half swallowed by the black darkness inside the gateway so only the top of the head, the face, the shoulders and the edges are lit, looking down at the viewer; the lower third of the picture is a wide flight of worn empty stone steps rising toward the gate, quiet and uncluttered, darker at the bottom. lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles, no white border, no margins
```

## Check before shipping a new gate

- Approve in the assembled screen at display size, night-graded, with the eye glows on.
- The guardian's head sits in the top third: the scene is anchored there (`focusY` 0.3) and the
  title block covers the bottom of the painting.
- The eyes land on the painted eyes on the @2x image (mark them and look).
