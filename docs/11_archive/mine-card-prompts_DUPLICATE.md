# Gold Mine Card Art — AI Image Generation Prompts

## Style Reference (analyzed from Hexbound boss/hero assets)

Key visual traits:
- **Pen and ink drawing** — every element has a bold black ink outline
- **NOT digital painting** — no soft edges, no blending, no atmospheric fog
- **Colored fills inside outlines** — muted earthy tones (brown, gray, bone-white) with 1-2 saturated accent colors
- **High detail props** — cracks, rivets, rust, bones, skulls, dripping, scratches
- **Full canvas scene** — the mine fills the entire image edge-to-edge, no empty space, no white margins
- **Western comic book style** — like D&D Monster Manual or Pathfinder rulebook illustrations

## Aspect Ratio

3:2 landscape

---

## Slot 1 — "Amethyst Cavern" (accent: purple)

```
Pen and ink illustration of an underground mine cavern interior filling the entire frame edge to edge, bold black ink outlines on every element, colored with muted grays and earth tones, jagged purple amethyst crystal clusters growing from the stone walls and ceiling, a battered wooden pickaxe leaning against the cave wall, scattered cracked skulls and bone fragments in rubble on the ground, rusty mine cart tracks on the floor, cobwebs between stalactites, dripping moisture stains on stone, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text, no white border, no margins
```

## Slot 2 — "Emerald Vein" (accent: green)

```
Pen and ink illustration of a damp underground grotto mine interior filling the entire frame edge to edge, bold black ink outlines on every element, colored with muted browns and grays, bright green emerald ore veins cracking through dark wet rock walls, rotting wooden support beams with a rusty hanging lantern, a corroded mining cart overflowing with green ore chunks, sickly green mushroom clusters on the floor, dripping green slime from ceiling, rat bones near the cart, old pickaxes covered in moss, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text, no white border, no margins
```

## Slot 3 — "Molten Forge" (accent: orange)

```
Pen and ink illustration of a volcanic underground mine shaft interior filling the entire frame edge to edge, bold black ink outlines on every element, colored with dark grays and blacks, cracks in obsidian floor revealing orange lava beneath, glowing orange ore deposits in blackened rock walls, a heavy iron pickaxe driven into a cracked boulder, ember particles floating upward, crumbling dwarven rune carvings on pillars glowing orange, charred wooden beams, soot and ash on everything, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text, no white border, no margins
```

## Slot 4 — "Frozen Depths" (accent: cyan/ice blue)

```
Pen and ink illustration of an icy underground mine cavern interior filling the entire frame edge to edge, bold black ink outlines on every element, colored with cold grays and dark blues, sharp cyan ice crystal formations jutting from ceiling and walls, a frozen waterfall cracked and ancient in background, frost-covered rusty mining cart on icy rails, icicle stalactites with bones frozen inside, cracked permafrost floor, old mining tools embedded in ice walls, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text, no white border, no margins
```

## Slot 5 — "Blood Quarry" (accent: crimson red)

```
Pen and ink illustration of a sinister deep underground mine interior filling the entire frame edge to edge, bold black ink outlines on every element, colored with dark grays and muted browns, dark crimson bloodstone crystal formations jutting from cracked walls, rusty iron chains and shackles hanging from ceiling, corroded broken mining equipment scattered around, crumbling stone pillars with dark stains, crude skull warning totems carved into rock, scattered broken pickaxe heads, dried dark liquid in crevices, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text, no white border, no margins
```

## Slot 6 — "King's Treasury" (accent: gold)

```
Pen and ink illustration of a magnificent ancient underground vault-mine interior filling the entire frame edge to edge, bold black ink outlines on every element, colored with dark stone grays and warm golds, thick veins of gold ore in dark stone walls, crumbling golden dwarven pillars with skull engravings, a treasure chest broken open spilling gold coins, jewel-encrusted mining tools on walls, ancient gold-inlaid floor tiles cracked with age, centuries of neglect and dust, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text, no white border, no margins
```

## Locked Slot — "Sealed Mine"

```
Pen and ink illustration of a sealed mine entrance blocked by heavy corroded iron chains filling the entire frame edge to edge, bold black ink outlines on every element, colored with dark grays and muted browns, a large ornate padlock with rune engravings, crumbling dark stone archway, thick cobwebs covering the entrance, dust and debris piled at base, crude skull carvings on archway stones, absolute darkness beyond the chains, cracked mortar and loose stones, the scene fills the whole canvas with no empty space, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text, no white border, no margins
```

---

## Negative prompt (if supported)

```
painting, oil painting, watercolor, digital painting, concept art, realistic, photorealistic, 3D render, soft edges, blurry, atmospheric lighting, volumetric light, fog, mist, glow effects, smooth shading, airbrushed, white background, empty space, margins, border, isolated object, floating object
```

---

## Integration Notes

After generating, save images as:
- `mine-slot-1.png` through `mine-slot-6.png`
- `mine-slot-locked.png`

Add to: `Hexbound/Resources/Assets.xcassets/`

In `GoldMineDetailView.swift` (line ~215), replace:
```swift
Image("icon-gold-mine")
```
with:
```swift
Image("mine-slot-\(index + 1)")
```

For locked card, use `Image("mine-slot-locked")`.
