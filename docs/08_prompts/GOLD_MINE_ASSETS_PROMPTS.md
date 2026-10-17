# Gold Mine screen assets — prompts

Sprites for the reworked Gold Mine screen (2026-10-16): the cart that rides each tunnel's rails, the expedition chest (5 hauls → chest) and the small UI icons that replace SF Symbols on that screen. Tunnel backdrops stay `mine-slot-1…6` / `mine-slot-locked` (`mine-card-prompts.md`).

- Family: pen-and-ink rulebook (`ART_STYLE_GUIDE.md` template + fixed light sentence), magenta key `#FF00FF`.
- Model: `nano_banana_2_1`, 1:1, 2k, thinking medium. Style anchor: `Items/chest_godplate` = `1c5bda93-1f54-4c55-9261-c03d3d8fe087` (`image_references`).
- Variants (`mine-cart-full`, `mine-chest-open`) also take their base job as Image 1 ("the EXACT SAME cart/chest: keep shape, angle, size and position"), so the pair cross-fades cleanly.
- Ingest: `scripts/ingest_generated_sprite.py <raw> <name> --pt <pt> --key FF00FF --out Hexbound/Hexbound/Resources/Assets.xcassets/GoldMine`.
- Prompt shape: *"Image 1 is the STYLE ANCHOR from the same item icon set: match its pen-and-ink linework, outline weight, lighting and colouring exactly; do not copy its subject. Pen and ink illustration of {SUBJECT}, bold black ink outlines on every element, colored with {TONES} and {ACCENT} accents, weathered, scratched and worn surfaces, a single game icon/sprite, big clear shapes that read at small icon size, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, the item filling about 80% of the frame, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. The ENTIRE background is one flat, uniform, solid bright magenta colour (#FF00FF) edge to edge, no pattern, no stripes, no frame, no border."*

| Asset | Subject | pt | Job |
|---|---|---|---|
| `mine-cart-empty` | empty wooden mine cart, three-quarter view, iron-banded planks, brass corner brackets, four iron wheels, tow hook | 120 | `84bab48a-220b-447b-aa09-b164d4cc989c` |
| `mine-cart-full` | the same cart heaped above the rim with gold ore nuggets and coins, a few dark rocks between them (Image 1 = empty cart) | 120 | `5df64c9c-fc0f-4ee3-a525-2a2d772331cb` |
| `mine-chest-closed` | domed treasure chest, iron bands, brass corners, skull lock plate | 160 | `d63a83f4-7707-4936-933e-7f57b4f6bb36` |
| `mine-chest-open` | the same chest, lid swung fully back, packed with gold coins and three cut red/blue gems (Image 1 = closed chest) | 160 | `da85fe0b-0668-4de0-b35e-b94cae3f231b` |
| `mine-chest-ajar` | middle frame of the opening: lid tilted back ~20°, coins visible in the gap, hasp hanging loose, no light (Images 1–2 = closed and open chest) | 160 | `29afca6d-94ec-4b42-a7a9-e6aeaa50cc02` |
| `icon-hourglass` | brass-and-wood hourglass, golden sand | 48 | `593049cd-b0f7-463c-95a0-9ea907dfd76e` |
| `icon-mine-bonus` | tipped leather coin pouch spilling gold coins (bonus run) | 48 | `5495b65d-e218-49cf-9e35-a075caa141e7` |
| `icon-mine-boost` | two crossed pickaxes with gilded heads (double haul) | 48 | `1c6c0517-e756-4963-9d5f-cd510b93d5ba` |
| `icon-mine-lock` | heavy rusted iron padlock (sealed level) | 48 | `4bb308a4-1259-44e3-b46f-033ad46916a6` |

The three chest frames (closed / ajar / open) are one animation: ingest them together with `python3 scripts/align_sprite_frames.py --out …/GoldMine --pt 160 --margin 18 closed.png:mine-chest-closed ajar.png:mine-chest-ajar open.png:mine-chest-open`, which registers them on the chest base and crops all three to one canvas so the cross-fade never jumps. The light from the crack, rays and coin fountain are code (`MineClaimRewardView`).

Subjects for the first six jobs are summarised from the results; the exact wording lives in the Higgsfield job history. All eight passed review on the first roll.
