# Dungeon Trail Maps — Prompts

Painted backgrounds for `DungeonTrailView` (the map between the overland Adventures map and the boss room).
One per dungeon, in `Assets.xcassets/DungeonTrails/bg-trail-<slug>.imageset` (single JPEG in the 1x slot, 4480 × 1901).
Boss feet positions live in `Views/Dungeon/DungeonTrailConfig.swift` (normalized 0…1).

## Generation

- Model: Higgsfield `nano_banana_2_1`, 21:9, `resolution: 4k` (6336 × 2688), `thinking_level: high`.
- References (`image_references`, in this order):
  1. hub city map (style), 2. overland dungeon map `bg-dungeon-map` (style),
  3. composition guide: two staggered rows of white ovals on grey — five low (y≈0.73), four high (y≈0.50), a big oval far right (the lair); top quarter black.
- The model keeps the two-row layout reliably; the ovals are only a hint. After generating, mark the ten clearing centres by hand on a 5 % grid and write them to `DungeonTrailConfig` (feet, slightly below the clearing centre).
- Training Camp and Catacombs were the pilots (variant A of each kept).

## Template

```
Images 1 and 2 are STYLE references only: match their art style, rendering, ink line, crosshatching, watercolour palette, the tilted bird's-eye 3/4 view and the scale of details exactly; do not copy their content. Image 3 is a COMPOSITION guide only: the light band is the trail and the ten white ovals mark where ten empty clearings must be. The clearings form two staggered rows: five in a lower row and four in an upper row placed in the gaps between them, the trail zigzagging up and down between the rows from left to right, and the tenth, largest clearing at the far right is the final lair. Keep the upper row in the middle of the image height, well below the top third. Do not draw the ovals, the band or the flat grey; paint real terrain there.

ASSET: a very wide horizontal panoramic game map background, 21:9, of {name}: {description}. A single trail starts at {entrance} on the far left edge and zigzags left to right through ten empty clearings, following the guide. Each clearing is a flat, open, clearly readable patch of {ground}, about the size of a small house, with nothing standing on it (a boss will be placed on it later as a separate layer); clearings may be ringed by low stones, posts, bones or debris that stay at their edges. The tenth clearing on the far right is larger, raised and dramatic: {lair}. Between and around the clearings: {props}.

The top quarter of the image is {top}: dark and quiet, no important detail (the interface sits there). The bottom edge falls away into {bottom}. The far-left and far-right edges fade to black.

Style bible: hand-drawn pen and ink illustration with crosshatching for all shading, bold black ink outlines on every element, coloured with muted watercolour washes; muted dark palette of {palette} with one accent: {accent}; aged and worn surfaces, cracks, moss, cobwebs. Painted flames, lava or crystals are fine as painted colour, but no glow halos, no light rays, no bloom. Same tilted bird's-eye view as the style references.

No people, no creatures, no monsters, no animals, no bodies anywhere in the image. Nothing standing on the clearings. Not a 3D render, not a photo, no blur, no text, letters, numbers or logos.
```

## Per-dungeon fields

### training_camp

- **name**: the Training Camp, an old training ground of the first Arena fighters on the outskirts of the Stray City, at night
- **description**: a trampled dirt-and-cobblestone yard inside a crooked wooden palisade, lit by torches on posts
- **entrance**: a broken wooden gate in the palisade
- **ground**: packed earth, sand or worn flagstones
- **lair**: a round sparring ring of stacked logs and sand with torch posts around its rim and tattered blank banners on poles
- **props**: weapon racks with wooden swords, straw bales and empty dummy posts, archery butts, barrels and crates, a stone well, patched canvas tents, a cellar trapdoor, chains and hanging lanterns, puddles and dead grass
- **top**: a night sky with a pale moon behind clouds and the dark silhouette of distant city walls
- **bottom**: a dark ditch with low fog
- **palette**: dark brown, charcoal grey, bone white and dark iron
- **accent**: warm orange torchlight

### desecrated_catacombs

- **name**: the Desecrated Catacombs, vast underground crypt halls beneath an abandoned cathedral
- **description**: a cavernous burial vault of grey stone hemmed by rough rock walls
- **entrance**: a broken stone stair descending from a ruined crypt door
- **ground**: cracked flagstones strewn with old bones
- **lair**: a raised dais of black stone with an empty cracked sarcophagus throne, bone pillars and braziers of violet fire
- **props**: skulls stacked in wall niches, stone sarcophagi and tomb slabs, collapsed columns, iron candelabras, rusted gates, chains, cobweb-draped arches, channels of black water, burial urns
- **top**: the dark vaulted cave ceiling with hanging roots and chains
- **bottom**: a black chasm with drifting mist
- **palette**: grey stone, bone white, charcoal and dark iron
- **accent**: sickly violet candle flame

### volcanic_forge

- **name**: the Volcanic Forge, an abandoned dwarven forge-hall carved into the heart of a volcano
- **description**: black basalt terraces and iron walkways over rivers of molten lava
- **entrance**: a cracked stone forge gate with broken bronze doors
- **ground**: cooled black basalt or riveted iron plates
- **lair**: a basalt plateau above a roaring lava caldera, ringed by colossal broken anvils and chained crucibles
- **props**: lava channels and falls, giant anvils, hammers and tongs, chains hanging from the cave, crucibles and cooling ingots, bellows, slag heaps, iron bridges, smoking vents
- **top**: a dark cavern ceiling lit from below by lava, with hanging chains
- **bottom**: a sea of dark lava crust and smoke
- **palette**: black basalt, charcoal, rust brown and dark iron
- **accent**: molten orange lava

### fungal_grotto

- **name**: the Fungal Grotto, a sunken cavern swallowed by giant fungi
- **description**: mossy rock shelves and pools under towering mushroom caps
- **entrance**: a root-choked cave mouth
- **ground**: soft moss over flat rock or packed peat
- **lair**: a hollow under the roots of a colossal rotten tree wrapped in fungus, a raised mound ringed by huge toadstools
- **props**: giant mushrooms with spotted caps, shelf fungi on the walls, tangled roots and vines, spore puffballs, still green pools, rotten logs, bones overgrown with moss, hanging moss curtains
- **top**: a dark cave ceiling hidden behind enormous mushroom caps and hanging roots
- **bottom**: a murky green bog with mist
- **palette**: dark olive, earthy brown, charcoal and bone white
- **accent**: sickly luminous green spores

### scorched_mines

- **name**: the Scorched Mines, deep goblin-dug gold mines where the shafts broke into magma
- **description**: timber-braced tunnels, rail tracks and scaffolding on several rock levels
- **entrance**: a timber mine portal with a hanging lantern and a rusted mine cart on rails
- **ground**: flat rock floor or wooden plank decking
- **lair**: a vast cavern floor before a throne carved into a wall of cooling magma, ringed by toppled ore carts and gold heaps
- **props**: mine rails and carts, timber props and scaffolds, rope bridges, pickaxes in the rock, ore veins of gold, lanterns on poles, lava seeping through cracks, broken winches and buckets, rubble
- **top**: a dark rock ceiling with timber beams and hanging chains and ropes
- **bottom**: a drop into a glowing magma crack
- **palette**: soot black, charcoal, rust brown and weathered timber
- **accent**: ember red-orange and gold ore

### frozen_abyss

- **name**: the Frozen Abyss, an ice cavern at the bottom of a glacier
- **description**: frozen ledges, snow drifts and a frozen underground river
- **entrance**: a cracked ice tunnel with frozen chains
- **ground**: flat packed snow or frosted stone
- **lair**: a raised plateau of blue ice before a frozen waterfall, ringed by giant ice crystals and a cracked frozen throne
- **props**: icicles and frozen waterfalls, jagged ice crystals, snow-buried ruins, frozen bones and weapons trapped in ice, a frozen river with cracks, wind-carved rocks, frost-covered banners
- **top**: a dark ice ceiling with huge hanging icicles
- **bottom**: a dark icy chasm with freezing mist
- **palette**: slate grey, ice white, cold blue and charcoal
- **accent**: pale cyan ice

### realm_of_light

- **name**: the Realm of Light, a ruined sun-temple of a fallen radiant order, high above the clouds
- **description**: white marble terraces, broken colonnades and golden mosaics, cracked and abandoned
- **entrance**: a ruined marble archway with a broken golden sun disc
- **ground**: cracked white marble paving
- **lair**: a raised circular sanctum with a huge cracked crystal prism on a golden altar, ringed by tall broken pillars
- **props**: broken columns and statues of faceless saints, golden braziers, crystal shards, stairs, sun mosaics on the floor, toppled bells, banners of faded gold, ivy on marble
- **top**: a dim golden-grey sky with beams blocked by heavy clouds
- **bottom**: a sea of clouds
- **palette**: bone white marble, pale stone, muted gold and grey
- **accent**: pale gold

### shadow_realm

- **name**: the Shadow Realm, a shattered dimension of darkness where the land floats in the void
- **description**: fragments of black rock and ruined stonework drifting over an endless void, joined by crumbling bridges
- **entrance**: a torn rift portal framed by broken stones
- **ground**: flat black rock or cracked obsidian paving
- **lair**: the largest floating island crowned by a ring of tall obsidian shards around a swirling dark rift
- **props**: floating rock fragments, chains anchoring the islands, crumbling bridges, dead black trees, shattered pillars, violet crystal growths, tendrils of smoke-like shadow
- **top**: an endless dark void with faint violet stars
- **bottom**: the bottomless void
- **palette**: black, charcoal, cold grey and dark violet
- **accent**: dim violet

### clockwork_citadel

- **name**: the Clockwork Citadel, a vast brass-and-iron fortress-machine of a vanished mechanist guild
- **description**: riveted brass walkways, iron platforms and stone bastions turning on giant gears
- **entrance**: a riveted iron portcullis gate with gear wheels
- **ground**: flat riveted iron plates or brass floor grating
- **lair**: a raised round platform at the core of the machine, ringed by colossal gears, pistons and a cracked clock face without numerals
- **props**: giant interlocking gears, steam pipes and valves, pistons, chains and pulleys, brass railings, conveyor belts, broken automaton parts, crates of cogs, vents of steam
- **top**: a dark ceiling of girders, chains and hanging gears
- **bottom**: a dark machine pit full of turning gears and steam
- **palette**: tarnished brass, dark iron, charcoal and smoky grey
- **accent**: warm brass gold

### infernal_throne

- **name**: the Infernal Throne, the burning hell-citadel of an archfiend
- **description**: cracked black rock, brimstone and blood-red flagstones over chasms of fire
- **entrance**: a gate of black iron spikes between horned stone pillars
- **ground**: flat cracked black stone or red flagstones
- **lair**: a towering dais of black stone with a huge horned throne of bones and iron, ringed by chained pillars and fire pits
- **props**: fire pits and lava chasms, iron cages, spiked chains, horned skulls, demonic statues without faces, brimstone vents, obsidian spikes, crumbling bridges over fire
- **top**: a dark smoky sky glowing red from below
- **bottom**: a chasm of fire
- **palette**: black stone, charcoal, dried-blood red and dark iron
- **accent**: hellfire crimson-orange
