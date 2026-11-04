# Guild Hall interior, amethyst chest, crisp stamina potions — art log (2026-11-04)

Art for the two redesigned screens (PR #19, canvas directions "A · Сундуки недели" and "A · Зал гильдии"). Higgsfield `nano_banana_2_1`, thinking `high`, the `ART_STYLE_GUIDE.md` bible and fixed light sentence on every call.

## Assets

| Asset | Use | Job | Refs | Ingest |
|---|---|---|---|---|
| `bg-guild-hall` | Guild Hall header (`GuildHallHeader`) | `fc522625-cbf2-4ebf-8ec5-288570c5d10f` (2k, 21:9, 3168×1344) | env anchor `03a55121-…` (fork-ossuary-2, style only) + `building-guild-hall` exterior (timber, stone, banner colours) | JPEG 528 / 1056 / 1584 px wide (fits a header up to 224 pt tall at 3x) |
| `tribute-chest-gem-closed` | Day 7 of the Daily Tribute | `584eda65-76dd-4e30-b440-e80331a7173f` (1k, 1:1, key `00FF00`) | chest anchors `591e03c4-…` (gold closed), `2f62914f-…` (wood closed) | `ingest_generated_sprite.py --pt 300 --key 00FF00` (900×846 @3x, like `rush2-chest-*`) |
| `tribute-chest-gem-open` | Day 7, opened | `a39f8851-fda7-475e-8b36-02a6f3c83266` (edit of the closed job) | `584eda65-…` + `60320053-…` (gold open, lid geometry) | same, 900×896 @3x |
| `stamina_potion_small/medium/large` | Items (inventory, shop, daily rewards) | upscales `6560f353-…` (small), `92a7dd2b-…` (medium), `7caec428-…` (large) | the shipped 128 px icons | full canvas kept (framing unchanged), @1x/@2x/@3x = 128/256/384 px |

## Prompts

**Hall interior** (bible, environment variant: the isolation clause swapped for a full-bleed scene):
> Pen and ink illustration of the great hall inside a warriors' guild house, seen from the entrance at standing eye level, wide view: heavy dark-oak beams and rafters, rough grey stone walls and pillars, a worn flagstone floor, a long scarred oak table with benches running down the middle of the hall, a huge stone hearth on the back wall with cold ashes (the fire is out), a mounted horned beast skull above the hearth, tattered faded crimson and guild-green banners hanging from the rafters along both walls, a weapon rack with axes and spears, a notice board covered in pinned parchment scrolls and red wax seals on the left wall, a chronicler's lectern with a huge open ledger and a quill on the right, unlit candle stubs, cobwebs, a few skulls and bones kept as trophies, bold black ink outlines on every element, colored with dark oak brown, grey stone and bone tones with faded crimson and guild-green accents, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, big quiet shapes, the top band is calm dark rafters with little detail, full-bleed interior scene filling the frame edge to edge, no characters, no frame, no border, no paper margin, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. First reference image: match its pen-and-ink line, hatching and palette exactly (style only, not its layout or its doorways). Second reference image: the same guild hall seen from outside; match its timber, stone and banner colours.

**Amethyst chest, closed** — purple subject, so the green key (§5):
> Pen and ink illustration of a reliquary treasure chest, the grandest chest of the set: dark ebony planks bound with blackened iron bands and riveted iron corners, a domed lid inlaid with a lattice of faceted violet amethyst crystals, a heavy silver padlock shaped like a horned skull on the front, small bone ornaments on the corners, iron claw feet, the lid closed, bold black ink outlines on every element, colored with charcoal iron, dark ebony and bone tones with violet amethyst accents, same chest family as the reference chests: the same three-quarter camera angle from slightly above, the same proportions, size in the frame and line weight, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green #00FF00 background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. The ENTIRE background is one flat, uniform, solid green #00FF00, edge to edge, no pattern, no stripes, no frame, no border.

**Amethyst chest, open** — an edit of the closed job ("keep everything else identical"), the same bible tail:
> Edit the first image: open the lid of this same treasure chest so the domed lid stands upright behind the box, and fill the open chest to the top with faceted violet amethyst gemstones and a few gold coins. Keep everything else identical: the dark wooden planks, blackened iron bands, the amethyst lattice on the lid, the padlock hanging unlocked on its hasp, the bone ornaments, the claw feet, the camera angle, the size in the frame and the line weight. The second image only shows how an open lid of this chest family sits. …

## Rejects and lessons
- Open chest, first try `2f0094b2-6896-41de-b8b4-04a503aef0e5`: false NSFW flag. The reworded prompt drops "thrown open", "skull goblet" and "brim".
- Potions: the first upscales sat on a magenta key, and keying ate the small potion's **purple glass** (magenta-adjacent hue). The small and medium potions were re-upscaled on green (`00FF00`) — the §5 rule holds for upscales too: key colour opposite the subject's accents.
- The potions were upscaled, not regenerated: they are the painterly pre-2026-10-14 icons kept by decision; only the resolution changed (1x-only 128 px → @1x/@2x/@3x).

## Acceptance
Still to approve on a 3x device in the assembled screens (§7): the hall behind the title and pinned tabs, the amethyst chest as today's chest on day 7 and in the week strip, the potions at 16 / 28 / 56 pt.
