# Gold Mine screen assets — prompts

Sprites for the reworked Gold Mine screen (2026-10-16): the cart that rides each tunnel's rails, the expedition chest (5 hauls → chest) and the small UI icons that replace SF Symbols on that screen. Tunnel backdrops stay `mine-slot-1…6` / `mine-slot-locked` (`mine-card-prompts.md`).

- Family: pen-and-ink rulebook (`ART_STYLE_GUIDE.md` template + fixed light sentence), magenta key `#FF00FF`.
- Model: `nano_banana_2_1`, 1:1, 2k, thinking medium. Style anchor: `Items/chest_godplate` = `1c5bda93-1f54-4c55-9261-c03d3d8fe087` (`image_references`).
- Variants (`mine-cart-full`, `mine-chest-open`) also take their base job as Image 1 ("the EXACT SAME cart/chest: keep shape, angle, size and position"), so the pair cross-fades cleanly.
- Ingest: `scripts/ingest_generated_sprite.py <raw> <name> --pt <pt> --key FF00FF --out Hexbound/Hexbound/Resources/Assets.xcassets/GoldMine`.
- Prompt shape: *"Image 1 is the STYLE ANCHOR from the same item icon set: match its pen-and-ink linework, outline weight, lighting and colouring exactly; do not copy its subject. Pen and ink illustration of {SUBJECT}, bold black ink outlines on every element, colored with {TONES} and {ACCENT} accents, weathered, scratched and worn surfaces, a single game icon/sprite, big clear shapes that read at small icon size, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, the item filling about 80% of the frame, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. The ENTIRE background is one flat, uniform, solid bright magenta colour (#FF00FF) edge to edge, no pattern, no stripes, no frame, no border."*

| Asset | Subject | pt | Job |
|---|---|---|---|
| ~~`mine-cart-empty`~~ | *removed 2026-10-17 — the three-quarter view never stood on side-on rails; replaced by `mine-cart-side-empty`* | 120 | `84bab48a-220b-447b-aa09-b164d4cc989c` |
| ~~`mine-cart-full`~~ | *removed 2026-10-17 — replaced by `mine-cart-side-full`* | 120 | `5df64c9c-fc0f-4ee3-a525-2a2d772331cb` |
| `mine-chest-closed` | domed treasure chest, iron bands, brass corners, skull lock plate | 160 | `d63a83f4-7707-4936-933e-7f57b4f6bb36` |
| `mine-chest-open` | the same chest, lid swung fully back, packed with gold coins and three cut red/blue gems (Image 1 = closed chest) | 160 | `da85fe0b-0668-4de0-b35e-b94cae3f231b` |
| `mine-chest-ajar` | middle frame of the opening: lid tilted back ~20°, coins visible in the gap, hasp hanging loose, no light (Images 1–2 = closed and open chest) | 160 | `29afca6d-94ec-4b42-a7a9-e6aeaa50cc02` |
| `icon-hourglass` | brass-and-wood hourglass, golden sand | 48 | `593049cd-b0f7-463c-95a0-9ea907dfd76e` |
| `icon-mine-bonus` | tipped leather coin pouch spilling gold coins (bonus run) | 48 | `5495b65d-e218-49cf-9e35-a075caa141e7` |
| `icon-mine-boost` | two crossed pickaxes with gilded heads (double haul) | 48 | `1c6c0517-e756-4963-9d5f-cd510b93d5ba` |
| `icon-mine-lock` | heavy rusted iron padlock (sealed level) | 48 | `4bb308a4-1259-44e3-b46f-033ad46916a6` |

The three chest frames (closed / ajar / open) are one animation: ingest them together with `python3 scripts/align_sprite_frames.py --out …/GoldMine --pt 160 --margin 18 closed.png:mine-chest-closed ajar.png:mine-chest-ajar open.png:mine-chest-open`, which registers them on the chest base and crops all three to one canvas so the cross-fade never jumps. The light from the crack, rays and coin fountain are code (`MineClaimRewardView`).

Subjects for the first six jobs are summarised from the results; the exact wording lives in the Higgsfield job history. All eight passed review on the first roll.

## Art pass 2 (2026-10-17) — carts on the rails, ladder, plates, backdrop

Feedback on the first build: the three-quarter cart sat crooked on side-on rails, the code-drawn rails/ladder and the plain number circles looked generic, the foreman was too small, and the screen had no atmosphere. Same family, model and anchor as above unless noted.

| Asset | Subject | Size | Ratio | Job |
|---|---|---|---|---|
| `mine-cart-side-empty` | the same wooden mine cart in **pure side view** (orthographic, no perspective), two iron wheels whose bottoms sit on one straight horizontal line, tow hooks at both ends | 120 pt, `--margin 0` | 1:1 | `63274628-7db7-4ab6-9803-b30708be62c1` |
| `mine-cart-side-full` | the same side-view cart heaped above the rim with gold ore and coins (Image 1 = empty side cart) | 120 pt, `--margin 0` | 1:1 | `6ed58fb0-3856-4610-ba0d-0b779809d546` |
| `mine-rail-tile` | raw: one long iron rail beam in pure side view over end-on wooden sleeper blocks with iron chairs | tile 24 × 14 pt | 4:1 | `85cad97a-7ee5-4adb-9b89-ae12e424c29e` |
| `mine-ladder-tile` | raw: one straight vertical timber ladder, front view, two side rails with bolts, evenly spaced rope-lashed rungs | tile 30 × 12 pt | 1:4 | `6f4a9ec9-d167-4a45-8141-8d02c3bf2a43` |
| `mine-level-plate` | blank round wooden plaque with an iron rim, four rivets and a hanging ring on top — **no number** | 48 pt, `--margin 0` | 1:1 | `ab2121f3-2c4b-4599-b4b4-979fc5063879` |
| `bg-gold-mine` | full-screen backdrop: timbered mine tunnel in front view, a lantern upper right, rails running into a dark centre, a loaded cart, tools, crates and barrels; centre left dark for UI. Painted-scene family (`bg-shop` = `77da6de2-550f-47cb-909e-ac7bf104ab0a` as style reference), no magenta key | 1536 × 2752 px, JPEG @1x/@2x/@3x | 9:16 | `57f32b96-ed72-442b-901f-ea8778f359a2` |

- Carts: both trimmed with `--margin 0`, so the wheel bottoms are the image's bottom edge and both carts are the same width (360 px @3x) — `MineRails` stands either one on the rail top with a 1 pt overlap.
- Tiles are not ingested as sprites: `python3 scripts/build_mine_tiles.py --rail <raw> --ladder <raw> --out …/GoldMine` rebuilds them seamless at exact point sizes (the raw's sleepers are unevenly spaced, so the rail tile is reassembled from one rail stretch + two copies of one sleeper; the ladder's rungs are spread to a 12 pt pitch).
- The plate's number is SwiftUI text (`MineLevelBadge`), per the no-text-in-PNG rule.
- The foreman header reuses `ShopkeeperHeader(style: .goldMine)` with the existing `npc-mine` portrait — no new NPC art.
