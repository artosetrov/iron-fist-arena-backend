# Reward card frames and reward art (2026-10-22)

Art for the reward cards (`Views/Components/RewardCard*.swift`, design in
`docs/07_ui_ux/REWARD_CARDS.md`): 40 stretchable frames (8 families × 5 tiers) and six
reward illustrations. Nano Banana 2.1 via Higgsfield, 2K.

## Pipeline

1. **Gold base per family** — `2:3`, key `#00FF00` inside and outside the frame, the
   approved hero frame `card-frame-4` (job `de850af7-806e-4bc2-82a8-3e08aff5a953`) as the
   style reference: "match the style … but NOT its layout".
2. **Other tiers as edits of the gold base** — the gold job id as the image reference,
   "change ONLY the materials". Same shape in every tier, so the content layout is the
   same per family (measured anyway, per frame).
3. **Cut and ship** — `python3 scripts/reward_card_frames.py <dir with family-tier.png>`:
   keys the green, finds the plain stretch of the side rails, cuts a top cap, a rail strip
   (cross-faded so copies meet seamlessly) and a bottom cap, writes
   `Assets.xcassets/RewardFrames/reward-frame-<family>-<tier>-{top,mid,bottom}` at
   @1x/@2x/@3x (360 pt wide) and regenerates `RewardCardFrameMetrics.swift` from
   `scripts/reward_card_frames.metrics.json`. Re-run it for any frame you regenerate.
4. **Reward art** — the art style guide template verbatim, `1:1`, the item anchor
   `chest_godplate` (`1c5bda93-1f54-4c55-9261-c03d3d8fe087`) as reference; ingest with
   `scripts/ingest_generated_sprite.py <raw> reward-art-<name> --pt 280 --out …/RewardArt`.

### What makes a frame stretchable (put it in every prompt)

- The crest stands **on** the top edge and rises **above** the card; nothing reaches into
  the window. Same for the bottom ornament, hanging below.
- Corner pieces stay compact — nothing runs along the sides or curls into the window.
- The long side rails are **plain, straight and identical along their whole length**: no
  ornaments, gems, runes, straps or rivet clusters in the middle of the sides.

The script refuses a frame whose plain rail span is shorter than one strip plus its
cross-fade; weathered planks with ragged edges get a looser tolerance (`TOLERANCE` in the
script).

## Gold base prompt

```
Match the drawing style, line weight, gold material and colouring of the reference card
frame, but NOT its layout. A single ornate card frame for a dark fantasy mobile game
REWARD card, seen straight on, perfectly symmetrical left to right, flat, no perspective,
tall portrait proportions, no round socket. The border is one band about 6 percent of the
card width with a fine beaded inner edge. A decorative CREST stands ON the middle of the
top edge and rises ABOVE the card: {CREST}. The crest must NOT hang down into the window:
nothing reaches below the top border. Compact corner pieces sit at the four corners:
{CORNERS}; they stay short and do not run along the sides or into the window. A small
ornament sits ON the middle of the bottom edge and hangs below the card: {BOTTOM}; it must
not reach into the window. The two long vertical side rails, between the top corner
pieces and the bottom corner pieces, are plain, straight and identical along their whole
length: the same simple antique gold bar with a fine beaded edge, repeated, with no
ornaments, no gems, no runes and no clusters of rivets anywhere along the middle of the
sides, so the frame can be stretched taller. Materials: {MATERIALS}. Hand-drawn
pen-and-ink linework with crosshatching, bold black outlines, muted watercolour wash, dark
fantasy RPG rulebook style. Lit by one key light from the upper left, warm bone-coloured
key, cool slate-grey shadows, no cast shadow on the ground. The ENTIRE inside of the frame
is one flat, uniform, solid #00FF00, and everything outside the frame is the same flat
#00FF00, edge to edge, no pattern, no gradient. No text, letters or logos, no glow, no
particles, not a 3D render, not a photo.
```

| Family | Crest | Corners | Bottom |
|---|---|---|---|
| arena | two crossed longswords behind a small round iron-bound shield, ruby boss | shield-shaped plates, filigree, small ruby | crossed short blades, tiny ruby |
| dungeon | horned skull of a dungeon lord, crown of iron spikes, ruby on the brow | short bony claws over filigree | small skull over crossed bones |
| fortune | carved bone dice (no pips) before a small spoked wheel, ruby hub | gold coins set in filigree | three stacked gold coins |
| mine | crossed miner's pickaxes behind a small unlit lantern, ruby | square timber beam ends with iron brackets | small iron mine-cart wheel |
| merchant | balance scale over a tied leather purse, ruby clasp | knotted red silk ribbons over filigree | red wax seal on a short ribbon |
| tribute | rolled scroll crossed with a quill, red wax seal with a ruby | curled parchment ends over filigree | small brass hourglass |
| glory | laurel wreath around a star medallion, two swallow-tailed banners, ruby | laurel sprigs over filigree | laurel sprig, tiny ruby |
| ascension | spread feathered wings around a sun medallion with short rays, ruby | curled feather tips over filigree | single small feather, tiny ruby |

The arena and dungeon gold bases were the second round; the first round let the crest hang
a quarter of the card down into the window, which is why the "must NOT hang down" lines exist.

## Tier edit prompt

```
Edit this card frame. Change ONLY the materials, to the {TIER NAME} tier: {CHANGE}. Keep
EXACTLY the same shape, silhouette, layout, proportions, crest, corner pieces, bottom
ornament and line work, and keep the two long side rails plain, straight and uniform
along their whole length with nothing crossing them. Keep the ENTIRE inside and outside
of the frame one flat, uniform, solid #00FF00. Hand-drawn pen-and-ink linework with
crosshatching, bold black outlines, muted watercolour wash. Lit by one key light from the
upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the
ground. No text, letters or logos, no glow, no particles, not a 3D render.
```

| Tier | Change |
|---|---|
| iron ("lowest") | every gold bar becomes weathered dark oak planks with rusty iron fittings at the corners only, nothing crossing the side rails; the gold filigree becomes simple forged black iron scrollwork; every red ruby becomes a plain round iron rivet; any ivory bone becomes dirty yellowed bone |
| bronze | every gold part becomes dented, darkened bronze with engraved lines; the gold filigree becomes simpler bronze scrollwork; every red ruby becomes a warm orange amber stone |
| silver | every gold part becomes worn, polished silver with fine engraved lines; the gold filigree becomes silver filigree; every red ruby becomes a deep blue sapphire |
| mythic ("highest, mythic") | every gold part becomes polished black obsidian trimmed with thin bright gold edges; the gold filigree becomes black and gold filigree; every red ruby becomes a violet amethyst |

## Job ids (shipped)

| Family | iron | bronze | silver | gold | mythic |
|---|---|---|---|---|---|
| arena | `3e1fc955-6c87-4451-8016-9d589efcd533`* | `ecb7f625-5cd8-42e7-a840-ac60a41665a7` | `91d4c490-f7d5-454d-8e78-0fc49ec5ed25` | `c571aefa-6c34-4657-93dc-6639f5c866dd` | `2808f1da-9a22-4dd0-8f48-fb09a1965687` |
| dungeon | `ea770a61-dcd6-43ab-a81c-666f274390f6`* | `915081bf-d5e2-41ff-a382-28559971c3b8` | `bbab6d7a-d174-421f-853c-babbc9dae9e1` | `a03d2e96-7039-4efd-97eb-eba9548db8b9` | `a87a9247-ea12-43f5-9405-bcd1570957de` |
| fortune | `b7eb2d75-5e43-4d2c-90fc-38d5eeefbb20` | `07e8f8c2-f2b9-4081-b02f-f3494c89eed7` | `a52b81a9-8e33-40bb-a7a5-885658164329` | `9fb55ef1-ccdb-4106-8127-0c4dc0712ab1` | `bd073e4d-4ffe-4644-aabd-3d6db622ccf3` |
| mine | `4188e981-2105-4cee-960b-5ecb888dc721` | `4872c87b-8416-4a4c-b03e-8ed6afeb1740` | `598ff056-8255-4783-bc80-b4bd58629e72` | `8a2a91af-5aec-46c6-b4cb-f345da2b5812` | `73595947-1fa0-4399-9b29-50d916e11213` |
| merchant | `067a32ee-ea2d-45e9-a6c3-b1f825c2bfd3`* | `ce78f1b3-eb42-4e14-a817-5600c6f0648d` | `e29d98b2-c010-4ff5-a343-b5367d05d933` | `493e85f9-3b7c-4dda-9b43-399db1786622` | `ff0e21e6-1d1f-4b03-8fb0-0f2668fcee1a` |
| tribute | `aec7c7aa-f3f3-439c-8ba5-cf08c7982feb` | `bf011b64-22a4-485c-84d4-81594c0ca50a` | `48cb01ba-fa96-4e9f-9cea-26d0b0a652fe` | `d0e46bdf-89d6-4556-8d3b-b28038a6504b` | `720d5c8e-48c0-4f1c-b27b-588859c93f2c` |
| glory | `36d0399c-7c8d-4be6-ad30-79915646ed05`* | `bf3889c1-0897-4e09-b10d-e06cc846ef4f` | `e730cd05-edcc-4740-b850-34d5ced672c0` | `fb3c40cf-56fe-4acb-ac22-61f076d9b918` | `1bd57ca3-8d40-4c1b-95f7-0dd7fa476927` |
| ascension | `ea333fa0-aee2-4965-95b4-b7b68860f6a8` | `1b1ab85c-7c9a-4dc2-b15d-749c9131a331` | `bf266ae5-2c92-47de-aea0-5530074641d6` | `ede8915a-b572-48b5-a386-323398f44c12` | `cbf064db-fac4-4f4f-9031-d2d0891a0e38` |

\* A second edit of the first iron result: "remove the iron straps / scrollwork that cross
the side rails or curl into the window; each side rail becomes one plain, straight
weathered oak plank".

## Reward illustrations (`Assets.xcassets/RewardArt`, `--pt 280`)

| Asset | Subject | Key | Job |
|---|---|---|---|
| `reward-art-gold-purse` | small brown leather money purse closed with a drawstring, a few coins in front | magenta | `dbaaa919-bd17-443c-acac-7b61ac6044b9` |
| `reward-art-gold-heap` | heap of coins around an overstuffed sack, a jewelled goblet on top | magenta | `565d7a3f-dd29-435e-bb15-5b3f2eb6e3a7` |
| `reward-art-gems-few` | three cut violet gems on folded dark velvet | green | `bf60e560-3fd9-45d4-84bd-7702f4b50571` |
| `reward-art-gems-heap` | open iron-bound casket overflowing with violet gems | green | `cb4fd27b-05db-41df-bab8-3a76e04f7180` |
| `reward-art-xp` | the `reward-xp` laurel medallion redrawn large (`reward-xp@3x` as a second reference) | magenta | `b486b3f4-eb7c-469e-afe8-2661e8659b65` |
| `reward-art-potions` | red, blue and amber potions on a small wooden rack | magenta | `101ed1eb-457e-4ae5-b1cf-1282f743dc7b` |

Coins are "stamped with a small skull under a crown", like `icon-gold`.

## Defect ledger

- Crests hanging into the window (round 1, arena and dungeon) → crest wording above.
- Iron edits putting straps across the rails (arena, dungeon) and scrollwork into the window
  (merchant, glory) → second edit, see the asterisk.
- `fortune-mythic` drifted to rounded inner corners; accepted (its window is a little smaller).
- "Coin pouch tied with a cord" was flagged NSFW (false positive) → "money purse closed with
  a drawstring".
- Four illustrations came back on a muted pink (`#B3447C`-ish) instead of `#FF00FF`; the chroma
  key does not recognise it. `scripts/key_sampled_background.py <raw> <out>` keys by the
  sampled border colour and writes the subject over pure magenta for the normal ingest.
