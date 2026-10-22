# Daily quest card banners — prompts

> **Status**: `canonical` — Active prompt collection. Indexed at `docs/08_prompts/ASSET_PROMPTS_INDEX.md`

The banner at the top of each daily quest card (`DailyQuestsDetailView.questBanner`) is filled by a painted scene, one per `QuestType` (2026-10-18). The scene's subject is on the right. The left half is dark and quiet because the title and task are drawn over it in code, behind a left-to-right `bgSecondary` scrim. The image is pinned to the trailing edge, so on narrow cards only the empty left side is cropped.

- Family: painted scenes (`bg-shop`, `bg-hub`) — pen and ink with watercolour washes. Not the isolated-sprite family.
- Model: `nano_banana_2_1`, **4:1**, 2k, thinking medium.
- References (`image_references`): `bg-shop` = `77da6de2-550f-47cb-909e-ac7bf104ab0a`, `bg-hub` (full) = `dc279b9f-7458-435c-9fa7-1bdef09da0c7`.
- Assets: `Assets.xcassets/QuestBanners/quest-banner-<name>`, JPEG @1x/@2x/@3x at 512/1024/1536 px wide. The card shows them at about 360 × 104 pt.

## Prompt shape

> Images 1 and 2 are STYLE REFERENCES from the same game: match their pen-and-ink linework, watercolour washes, palette and lighting exactly; do not copy their content or composition.
>
> Pen and ink illustration with watercolor wash coloring of {SCENE}, a very wide horizontal banner for a mobile game quest card. Bold black ink outlines on every element, watercolor fills with visible brush texture, crosshatching for shadows. Muted dark earth tones ({TONES}) with one accent: {ACCENT}.
>
> COMPOSITION: the main subject sits in the right third of the frame; the left half is a calm, dark, almost empty stretch of {LEFT}, because the quest title and text are drawn over it in code. Low close eye-level view, big simple shapes that read at small size.
>
> Lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows. Painted flames are fine but no glow halos, no light rays, no bloom. Not a 3D render, not a digital painting, not concept art, no blur, no fog, no text, letters, numbers or logos, no UI, no frame, no border.

## Assets

| QuestType | Asset | Scene | Accent | Job |
|---|---|---|---|---|
| `pvp_wins` | `quest-banner-pvp` | Arena sand: round shield and crossed swords stuck in it, crimson banner on the wall, bones. | crimson | `d1985103-df98-4546-9813-2863dc23d7be` |
| `dungeons_complete` | `quest-banner-dungeon` | Stairs down through a carved arch with a half-raised portcullis, a skull, a torch. | acid-green slime | `79dfb162-105c-401b-8e39-81dc80bdf3d0` |
| `gold_spent` | `quest-banner-shop` | Merchant counter with spilled gold and a coin purse, brass scales, potions, a dagger, the edge of a teal awning. | gold coins | `98c1459d-9297-4fec-b799-0beb17fed312` |
| `item_upgrade` | `quest-banner-upgrade` | Anvil with an orange-hot blade, hammer, tongs, bucket, forge mouth with embers. | hot metal | `a9674d2c-6a55-48b0-8645-8a2780400e8a` |
| `consumable_use` | `quest-banner-alchemy` | Alchemist table with a big red potion flask, bottles, mortar, herbs, candle. Labels blank, book closed. | red potion | `331d62e0-…` → edit `7a2dd7b8-6164-499d-a7b9-3cdcbab01e37` |
| `shell_game_play` | `quest-banner-shell` | Tavern table with three upside-down brass cups, one tipped over a golden ball; coins, tankard, skull candle. | tarnished gold | `f28012f3-…` → edit `4149684c-b611-458b-8c89-4321b76ac6f7` |
| `gold_mine_collect` | `quest-banner-mine` | Mine tunnel with a cart of gold ore on rails, gold veins in the rock, pickaxe, lantern. | gold ore | `8064e911-1f2d-40dc-9e5e-619c72503e82` |

## Rejects

- `quest-banner-alchemy`, first roll: legible "Health Potion" labels and an open book with writing. Fixed with an edit ("make every label blank, close the book; keep everything else identical").
- `quest-banner-shell`, first roll: the cups were upright goblets, so it did not read as a shell game. Fixed with an edit that turned them upside down.

A new quest type needs its own banner. `questBannerAsset(for:)` returns nil for unknown types, which keeps the plain fill.
