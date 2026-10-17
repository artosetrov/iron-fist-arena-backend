# Crest layers — prompts (layered Hexbound logo)

The game logo rebuilt as separate painted layers so the title screen can animate it (`Views/Components/HexboundCrest.swift`). It replaces the single-PNG `hexbound-logo` on the title screen; the old asset stays in the catalog for now. Generated 2026-10-17.

## Pipeline

- Model `nano_banana_2_1`, 2k, thinking medium.
- Two references on every call:
  - Image 1 = style anchor `Items/chest_godplate`, job `1c5bda93-1f54-4c55-9261-c03d3d8fe087`.
  - Image 2 = the old logo, flattened on #0D0D12, media `888a752d-4231-4bac-8005-c1bfaf192bd6`. It is used for motifs only.
- Prefix: *"Image 1 is the STYLE ANCHOR from the same icon set: match its pen-and-ink linework, outline weight, lighting and colouring exactly; do not copy its subject. Image 2 is the current HEXBOUND game logo: use it only for the shapes and motifs of the one part described below, redraw that part in Image 1's pen-and-ink style with no glow, and draw ONLY that part — nothing else from Image 2."*
- Then the `ART_STYLE_GUIDE.md` template verbatim, with the fixed light sentence. The class tail is *"a separate layer of a game logo kit, big clear shapes,"*. The prompt ends with the flat-key sentence.
- Key colour: magenta `#FF00FF`, except the gem, which is purple and so uses green `#00FF00` (guide §5).
- Ingest: `scripts/ingest_generated_sprite.py <raw> <name> --pt <pt> --key <key> --out Hexbound/Hexbound/Resources/Assets.xcassets/Crest`.
- **Brand-lettering exception.** The wordmark is the one layer that carries letters. It is the logo itself, not UI text. Its negative clause reads "no other words, letters or logos" instead of "no text, letters or logos". The spelling was checked at 100%.
- Everything else follows "AI paints, code rules":
  - the forge glow on the letters, the gem's violet light, the warm pool and the storm-light sheen are drawn in `HexboundCrest`;
  - "FORGE YOUR FATE" is typeset (Oswald 16, `buttonLabelCompact`).

## Layers

| Asset | `--pt` | Subject (after "Pen and ink illustration of") | Job (chosen) |
|---|---|---|---|
| `crest-plate` | 300 | a large ornate hexagonal shield frame seen straight from the front, a pointy-top hexagon with vertices at the top and bottom, a thick border of blackened iron with raised bronze filigree, rivets and curling thorny vines, two small bone-white skull ornaments on the upper left and upper right corners of the border, an empty round metal socket at the top point of the border with nothing set in it, and inside the border a recessed flat panel of dark weathered slate stone with a few fine cracks, the panel completely blank — blackened iron, dark bronze and slate grey; tarnished gold filigree | `b75d5e45-6573-442e-8693-762cdf74fe5c` |
| `crest-wordmark` | 340 | the single word HEXBOUND spelled H-E-X-B-O-U-N-D in large heavy fantasy display lettering, all capitals on one straight line, letters slightly flared with sharp wedge serifs, each letter cast in gold-bronze metal with crosshatch shading for volume, a thick black ink outline around every letter, a few fine engraved rune scratches on the letter faces, the X a little larger than the other letters — warm gold and bronze; deep umber shading. 21:9 | `1bffbb89-9f74-4a59-ac9b-76cdefd03f8d` |
| `crest-gem` | 100 | a single faceted hexagonal amethyst gemstone seen from the front, set in a small ornate bronze claw mount with six prongs — deep violet and plum; tarnished gold mount. Green key | `71d7ac23-1cd2-43a8-b9e2-5d0f5ccf0e92` |
| `crest-banner` | 260 | an empty horizontal subtitle plaque, a long riveted bronze-and-iron plate with notched swallowtail ends and a recessed dark centre strip, completely blank with nothing written on it — dark bronze and blackened iron; tarnished gold rim. 4:1 | `f6479ce0-cde3-4885-8754-41fb4b2d5c5d` |
| `crest-chain` | 140 | a single short iron chain hanging straight down, seven thick oval links and a round ring at the top — blackened iron and gunmetal; rust brown. 1:4 | `88eb390c-5a79-4176-812c-20f6c04609ca` |
| `crest-claws` | 200 | two skeletal hands side by side reaching up from below, long bony fingers curled forward over the top of an edge as if pulling themselves up, cracked yellowed fingernails, the edge they grip is not drawn — bone white and aged ivory; dark brown cracks. 16:9 | `d8be1ef5-41f6-409f-b9b1-85bac94e9467` |

Rejected alternates:

- `62cc9d7b-44bc-409e-bfde-896e2adfce98` — the plate with a brown panel. The gold letters read better on slate.
- `76719545-618d-4359-a894-497865131331` — the hands with straight raised fingers. They don't grip.
- `b6683c48-…` — the second wordmark. Generation failed and wasn't needed.

Key residue is 0 px on every layer.

## Assembly (HexboundCrest)

All values are in units of the crest width W (300 pt on the title screen). The box is W × 1.16 W. Each layer is positioned by its centre (x, y) and its width w:

| Layer | x | y | w | Order |
|---|---|---|---|---|
| warm light pool (code) | 0.50 | 0.48 | 1.28 | back |
| chains (behind the plate, pivot at the top ring) | 0.165 / 0.835 | 0.80 | 0.075 | |
| plate | 0.50 | 0.48 | 0.80 | |
| bony hands (wrists fade out: opaque to 55 %, clear at the bottom) | 0.50 | 0.90 | 0.52 | |
| gem + violet light (code, Ø 0.4 W) | 0.50 | 0.186 | 0.16 | |
| wordmark + forge glow (template silhouette, blur 0.03 W) | 0.50 | 0.45 | 1.00 | |
| banner + tagline | 0.50 | 0.665 | 0.80 | front |

Intro cues, in seconds from appear:

| Time | Step |
|---|---|
| 0.10 | plate: fade, rise 10 pt, blur 8 → 0 |
| 0.30 | chains swing in from ±14° (`springBouncy`) |
| 0.40 | hands climb 18 pt |
| 0.55 | gem; its light flares to 1 and rests at 0.35 |
| 0.70 | wordmark is struck left → right (soft-edged wipe); its glow flares to 1 and rests at 0.3 |
| 1.05 | banner |
| 1.25 | tagline |
| 1.30–2.50 | one storm-light sheen across the letters |

Reduce Motion gets one plain fade. `mode: .still` shows everything in place.
