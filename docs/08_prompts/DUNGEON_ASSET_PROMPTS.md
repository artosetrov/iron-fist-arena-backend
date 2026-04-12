# Hexbound — Промпты для генерации ассетов подземелий (Dungeons 3–10)

> **Status**: `canonical` — Active prompt collection
> **Scope**: 8 dungeons without art: Volcanic Forge, Fungal Grotto, Scorched Mines, Frozen Abyss, Realm of Light, Shadow Depths, Clockwork Citadel, Infernal Throne
> **Per dungeon**: 1 cover, 1 background, 10 boss portraits, 10 boss full-body = **22 prompts × 8 = 176 prompts**
> **Existing art (skip)**: Training Camp (Dungeon 1) + Desecrated Catacombs (Dungeon 2) — see `BOSS_SPRITES_PROMPTS.md`

---

## Общие правила

### Стиль боссов (портреты + full body)

Все боссы генерируются в едином стиле проекта:

**Портрет (portrait):** Head and upper shoulders, cropped at chest level, slightly angled 3/4 view, 1:1 square
**Полная фигура (full):** Full body visible, dynamic pose, 1:1 square

**Style block (append to every boss prompt):**
```
Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with exaggerated proportions, dark fantasy cartoon style, dark humor. Thick hand-drawn outlines with varying line weight. Rich vibrant colors. Warm cream parchment background.
```

**Negative prompt:**
```
painting, oil painting, digital painting, concept art, realistic, photorealistic, 3D render, soft edges, blurry, atmospheric lighting, volumetric light, fog, mist, glow effects, gradient background, smooth shading, airbrushed, anime, pixel art, text, watermark, logo
```

### Стиль обложки подземелья (cover)

Иконка/обложка подземелья — показывает вход/ворота/портал. 1:1 square, ~512×512 → 1024×1024 retina.

**Style block (append to every cover prompt):**
```
Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, no text, no speech bubbles, no UI elements, no logo.
```

### Стиль фона подземелья (background)

Фон для боевых сцен внутри подземелья. 3:2 aspect ratio, ~1024×680.

**Style block (append to every background prompt):**
```
Hand-drawn ink illustration with crosshatching for ALL shading, visible pen strokes, muted watercolor-style color washes over ink linework, thick black outlines on every element, dark fantasy medieval manuscript aesthetic. NOT clean digital art, NOT smooth gradients. Deliberately rough, textured, hand-crafted. 3:2 aspect ratio, dark moody atmosphere, no text, no UI elements, no characters.
```

---

# ДАНЖ 3: VOLCANIC FORGE 🌋 (Lv. 20–30)

> Backend: ✅ defined in `dungeon.ts`. Boss art: ❌ missing all 10.
> Theme: lava, molten metal, fire, forge, obsidian, magma caverns.
> Palette: deep reds, bright orange, molten gold, charcoal black, obsidian purple.

---

## Cover — `dungeon-cover-volcanic-forge`

A massive ancient dwarven forge entrance carved into the side of a volcanic mountain, rivers of molten lava flowing down channels on either side. Enormous iron doors half-melted and warped by heat, glowing orange-red from within. Obsidian pillars flanking the entrance with carved runes glowing ember-orange. Thick black smoke billowing from vents above. Chains and pulleys hanging from a stone arch. The rock face cracked and bleeding lava like open wounds. Anvil-shaped keystone above the door. Heat shimmer distorting the air.

Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, no text, no speech bubbles, no UI elements, no logo.

---

## Background — `bg-dungeon-volcanic-forge`

Dark fantasy volcanic forge interior, bird's-eye tilted perspective looking down into a vast cavern workshop. Rivers of molten lava flowing through stone channels carved into the floor. Massive iron anvils and broken forging equipment scattered around. Chains hanging from a ceiling lost in black smoke. Glowing orange-red forge pits built into the walls. Obsidian pillars cracked from extreme heat. Scattered blacksmith tools — tongs, hammers, molds — all oversized and ancient. Iron grates over lava channels, some broken through. Charred bones of previous challengers. Soot and ash covering every surface. The air thick with embers drifting upward like fireflies.

Hand-drawn ink illustration with crosshatching for ALL shading, visible pen strokes, muted watercolor-style color washes over ink linework, thick black outlines on every element, dark fantasy medieval manuscript aesthetic. Color palette: deep charcoal, bright molten orange, volcanic red, obsidian black, ember gold. NOT clean digital art, NOT smooth gradients. Deliberately rough, textured, hand-crafted. 3:2 aspect ratio, dark moody atmosphere, no text, no UI elements, no characters.

---

## Boss 1/10 — Lava Crawler (Lv.20)

### `boss-lava-crawler-portrait` — Портрет

A portrait bust of a monstrous insectoid creature that lives in lava, head and thorax, 3/4 view. A beetle-like head with a thick obsidian carapace cracked and glowing orange from within, six tiny molten eyes arranged in a row, mandibles dripping liquid fire, antennae made of cooled lava curling like horns, steam venting from cracks in its shell. Looks like a cockroach that crawled out of hell and survived. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with exaggerated proportions, dark fantasy cartoon style, dark humor. Thick hand-drawn outlines with varying line weight. Charcoal and molten orange tones. Warm cream parchment background.

### `boss-lava-crawler-full` — Полная фигура

A full-body view of a massive insectoid lava crawler in an aggressive scuttling pose, six legs spread wide on hot stone. A giant beetle-centipede hybrid with obsidian shell plates cracked revealing molten interior, segmented body trailing sparks, front claws glowing white-hot, a tail-stinger dripping lava. Disturbing combination of insect and volcano. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Charcoal and bright orange tones. Thick hand-drawn outlines. Aggressive scuttle pose. Warm cream parchment background.

---

## Boss 2/10 — Ember Sprite (Lv.21)

### `boss-ember-sprite-portrait` — Портрет

A portrait bust of a tiny mischievous fire elemental, face and upper body, 3/4 view. A small humanoid made entirely of dancing flames and embers, a wide manic grin made of white-hot fire, two asymmetrical ember eyes — one large and excited, one squinting, a crown of flickering blue-tipped flames for hair, tiny charcoal horns, soot-stained cheeks from its own explosions. Gleefully pyromaniac. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized head, dark fantasy cartoon, dark humor. Orange, yellow, and blue flame tones. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-ember-sprite-full` — Полная фигура

A full-body view of a tiny ember sprite gleefully dancing and juggling fireballs, leaving scorch marks everywhere. A small flame-bodied creature with oversized head, stick-thin limbs made of smoldering wood, embers trailing from every movement, two fireballs orbiting above its hands, standing on a pile of ash it just created. The happiest arsonist in the dungeon. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Bright orange and yellow tones. Thick hand-drawn outlines. Manic dance pose. Warm cream parchment background.

---

## Boss 3/10 — Slag Brute (Lv.22)

### `boss-slag-brute-portrait` — Портрет

A portrait bust of a hulking humanoid made of cooled slag and molten metal, head and shoulders, 3/4 view. A crude face formed from slag waste — jaw made of cooled iron drippings, eye sockets filled with bubbling molten metal, a flat crushed nose, sharp metal shrapnel teeth, rivulets of liquid slag running down the cheeks like tears. Looks like someone melted a golem and it refused to die. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with exaggerated bulk, dark fantasy cartoon, dark humor. Gray slag, orange molten accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-slag-brute-full` — Полная фигура

A full-body view of a massive slag brute lumbering forward with fists raised. A towering humanoid of cooled and molten slag mixed together, one arm hardened iron-gray and the other still glowing orange, chunks falling off its body revealing the molten core, thick stumpy legs leaving melted footprints, a crude iron girder used as a club in one hand. Industrial waste brought to angry life. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Gray and molten orange tones. Thick hand-drawn outlines. Lumbering smash pose. Warm cream parchment background.

---

## Boss 4/10 — Flame Hound (Lv.23)

### `boss-flame-hound-portrait` — Портрет

A portrait bust of a demonic dog made of fire and charcoal, head and upper body, 3/4 view. A hellhound with a massive head — cracked obsidian skull showing fire beneath, three asymmetrical eyes burning different intensities, a mouth full of jagged iron teeth with flame drool dripping, charred ears — one standing, one broken, a thick collar of cooled lava around the neck with a broken chain dangling. Ugly, angry, and on fire. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized head, dark fantasy cartoon, dark humor. Charcoal black and fire orange. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-flame-hound-full` — Полная фигура

A full-body view of a flame hound in a snarling attack crouch, ready to pounce. A large hellhound with a charcoal-black body cracked like cooling lava, fire visible through every crack, a mane of actual flames along the spine, powerful legs with ember claws leaving scorch marks, a whip-like tail of fire, drool of liquid fire pooling beneath the jaw. Terrifying guard dog of the forge. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Black and fiery orange-red. Thick hand-drawn outlines. Attack crouch pose. Warm cream parchment background.

---

## Boss 5/10 — Molten Shaman (Lv.24)

### `boss-molten-shaman-portrait` — Портрет

A portrait bust of an ancient fire priest, head and shoulders, 3/4 view. A wizened humanoid figure with cracked obsidian skin, hollow eye sockets containing floating orbs of white-hot magma, elaborate headdress of twisted metal and volcanic glass shards, ritual scars carved into the face glowing orange, a necklace of volcanic crystals and small skulls, wisps of smoke from the nostrils. Ancient and terrifying wisdom. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Dark obsidian with bright magma accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-molten-shaman-full` — Полная фигура

A full-body view of the Molten Shaman hovering above a pool of lava, arms raised in ritual casting. A gaunt robed figure with obsidian skin, tattered ceremonial robes of fire-resistant hide covered in glowing runes, a gnarled staff made of a petrified lava flow with a magma orb at the tip, bare feet dripping lava, orbiting volcanic shards circling the body. Calling upon the volcano itself. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Dark and bright orange ritual accents. Thick hand-drawn outlines. Ritual casting pose. Warm cream parchment background.

---

## Boss 6/10 — Obsidian Knight (Lv.25)

### `boss-obsidian-knight-portrait` — Портрет

A portrait bust of a knight in obsidian armor, helmet and shoulders, 3/4 view. Full obsidian plate armor — jet black with razor-sharp edges, a visor with narrow slits glowing dull red, deep cracks in the pauldrons revealing embers within, volcanic glass sword hilt visible at shoulder, a tattered cape of charred fabric, the helmet crowned with broken obsidian spikes. Elegant but brutally sharp. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with exaggerated sharp angles, dark fantasy cartoon, dark humor. Jet black and deep red accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-obsidian-knight-full` — Полная фигура

A full-body view of the Obsidian Knight in a wide combat stance, holding a jagged obsidian greatsword. Full obsidian plate armor with edges sharp enough to cut, every joint cracked and glowing red-orange, a tower shield of volcanic glass in the off-hand, a charred cape flowing behind. Moves with terrifying grace for something made of glass and fire. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Black obsidian and ember red. Thick hand-drawn outlines. Dueling stance. Warm cream parchment background.

---

## Boss 7/10 — Furnace Worm (Lv.26)

### `boss-furnace-worm-portrait` — Портрет

A portrait bust of a massive worm emerging from a furnace, head section, 3/4 view. An enormous segmented worm with a head like an open furnace door — a gaping circular maw lined with rings of iron teeth, the interior glowing white-hot, heat-distorted air rippling around it, iron plating bolted onto segments of its body, slag and soot dripping from seams. An industrial nightmare. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized maw, dark fantasy cartoon, dark humor. Iron gray and furnace orange-white. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-furnace-worm-full` — Полная фигура

A full-body view of the Furnace Worm bursting upward from the floor, coiled and striking. A massive segmented worm with iron-plated body sections, the front segments glowing white-hot, a circular maw of spinning iron teeth, smaller furnace vents along its body belching fire, a tail end disappearing into molten rock below. Part worm, part blast furnace, all terror. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Iron and white-hot orange. Thick hand-drawn outlines. Erupting strike pose. Warm cream parchment background.

---

## Boss 8/10 — Cinderlord (Lv.27)

### `boss-cinderlord-portrait` — Портрет

A portrait bust of an aristocratic fire demon, head and shoulders, 3/4 view. A tall elegant humanoid with ashen gray skin cracked like dried mud revealing ember veins, a gaunt aristocratic face with a thin cruel smile, eye sockets containing swirling cinder storms, tall swept-back horns of charcoal, a high collar of smoldering fabric, an elaborate medallion of fused gold and obsidian at the throat. Arrogant and ancient. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with elongated features, dark fantasy cartoon, dark humor. Ash gray with ember orange veins. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-cinderlord-full` — Полная фигура

A full-body view of the Cinderlord standing imperiously, one hand extended casting a fire spell. A tall thin aristocratic fire demon in ornate charred robes, ashen skin cracked with ember veins, long clawed fingers trailing cinder sparks, a cape of living smoke and ash, standing on a circle of scorched earth, embers orbiting slowly. Looks down at you like something beneath his notice. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Ash gray and warm ember tones. Thick hand-drawn outlines. Imperial commanding pose. Warm cream parchment background.

---

## Boss 9/10 — Magma Titan (Lv.28)

### `boss-magma-titan-portrait` — Портрет

A portrait bust of a colossal elemental made of living magma, head and shoulders, 3/4 view. A massive crude head of cooled and flowing magma — the surface constantly shifting between black crust and bright orange molten rock, two deep crater eye sockets glowing white-hot, a jaw that cracks open revealing a furnace interior, cooling rock forming temporary features that melt and reform, steam and gas venting from fissures. A mountain that decided to fight. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with exaggerated mass, dark fantasy cartoon, dark humor. Black crust and bright molten orange. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-magma-titan-full` — Полная фигура

A full-body view of the Magma Titan rising from a lava pool, arms raised to smash. An enormous humanoid elemental of living magma, black cooled crust cracking across the body revealing bright orange molten interior, each step creating lava footprints, boulders and obsidian chunks embedded in its body, one fist raised overhead trailing lava droplets, the other slamming the ground. Unstoppable volcanic force. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Black and brilliant orange. Thick hand-drawn outlines. Erupting smash pose. Warm cream parchment background.

---

## Boss 10/10 — Pyrox the Eternal (Lv.30) ★ ФИНАЛЬНЫЙ БОСС

### `boss-pyrox-the-eternal-portrait` — Портрет

A portrait bust of Pyrox the Eternal — the ancient fire dragon god of the forge, head and upper neck, 3/4 view. A colossal dragon head with obsidian scales each edged in molten gold, four asymmetrical horns — two massive curved ones and two broken stumps, eyes of pure white fire with no pupils, a mouth full of blackened fangs with lava dripping between them, a crown of volcanic crystals fused to the skull, ancient battle scars across the snout where scales have been torn away revealing the fire beneath. Ageless, furious, magnificent. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with exaggerated draconic features, dark fantasy cartoon, dark humor. Obsidian black, molten gold, white-fire eyes. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-pyrox-the-eternal-full` — Полная фигура

A full-body view of Pyrox the Eternal — a massive fire dragon coiled atop its volcanic throne, wings spread wide, breathing a torrent of white-hot flame. An enormous dragon with obsidian scales cracked and bleeding lava, four horns (two broken from ancient battles), massive bat-like wings with membranes of living fire, a long serpentine tail wrapped around a mountain of melted gold and burned bones, claws the size of swords gripping the volcanic rock. The forge itself bows to this creature. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Obsidian, molten gold, white fire. Thick hand-drawn outlines. Regal fury pose. Warm cream parchment background.

---

# ДАНЖ 4: FUNGAL GROTTO 🍄 (Lv. 30–40)

> Backend: ❌ not yet defined. Boss names are PROPOSALS — confirm before backend implementation.
> Theme: underground mushroom caverns, bioluminescent fungi, spores, poison, rot, damp.
> Palette: deep purples, toxic greens, bioluminescent cyan, sickly yellow, damp brown.

---

## Cover — `dungeon-cover-fungal-grotto`

A massive cavern entrance overgrown with enormous grotesque mushrooms of every color — purple caps dripping luminescent slime, green shelf fungi growing like stairs up the walls, bioluminescent blue tendrils hanging like curtains across the entrance. The stone arch is barely visible beneath layers of fungal growth. Pools of toxic green liquid at the base. Spore clouds drifting lazily in the air, glowing faintly. A crude wooden sign half-consumed by mold (no readable text). The darkness beyond the entrance pulses with faint bioluminescent light. Mushrooms with faces — not friendly faces.

Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, no text, no speech bubbles, no UI elements, no logo.

---

## Background — `bg-dungeon-fungal-grotto`

Dark fantasy underground mushroom cavern interior, bird's-eye tilted perspective. A vast damp cave with enormous mushrooms growing from floor to ceiling like pillars, some caps 3 meters wide. Bioluminescent fungi on the walls casting eerie blue-green light. Pools of stagnant toxic water with floating spores. Thick mycelium networks covering the stone floor like white veins. Shelf fungi growing on broken stalagmites. Dripping moisture everywhere. Small glowing mushrooms in clusters like alien lanterns. Spore clouds hanging in the air. Rotting wooden mine supports half-consumed by fungal growth. A carpet of tiny mushrooms covering old bones.

Hand-drawn ink illustration with crosshatching for ALL shading, visible pen strokes, muted watercolor-style color washes over ink linework, thick black outlines on every element, dark fantasy medieval manuscript aesthetic. Color palette: deep purple, toxic green, bioluminescent cyan, sickly yellow, damp brown stone. NOT clean digital art. Deliberately rough, textured. 3:2 aspect ratio, dark moody atmosphere, no text, no UI elements, no characters.

---

## Boss 1/10 — Spore Puffball (Lv.30)

### `boss-spore-puffball-portrait` — Портрет

A portrait bust of a sentient giant puffball mushroom, upper body, 3/4 view. A round bloated mushroom body with a crude face — two uneven dot eyes made of dark spore clusters, a wide gaping mouth that's actually a split in the cap releasing toxic yellow spore clouds with every "breath," warty bumps covering the surface, a few tiny parasitic mushrooms growing on its head like a bad hairdo. Looks harmless but the spore cloud is deadly. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with exaggerated roundness, dark fantasy cartoon, dark humor. Sickly cream-yellow and toxic green spore accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-spore-puffball-full` — Полная фигура

A full-body view of a giant sentient puffball mushroom bouncing toward the viewer, releasing spore clouds. A round bloated mushroom creature with stubby root-legs, tiny arm-tendrils, a split-cap mouth billowing yellow-green toxic spores, leaving a trail of smaller puffballs behind it. Deceptively cute, lethally toxic. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Cream and toxic green. Thick hand-drawn outlines. Bouncing attack pose. Warm cream parchment background.

---

## Boss 2/10 — Mycelium Crawler (Lv.31)

### `boss-mycelium-crawler-portrait` — Портрет

A portrait bust of a spider-like creature made entirely of fungal mycelium, head and forelegs, 3/4 view. A mass of white threadlike mycelium woven into a spider shape, eight eyes made of tiny bioluminescent mushroom caps glowing blue, mandibles of hardened fungal chitin, small mushrooms sprouting randomly from its body, strands of mycelium trailing from its face like a beard. Organic and alien. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. White mycelium, blue bioluminescent accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-mycelium-crawler-full` — Полная фигура

A full-body view of the Mycelium Crawler skittering across the cavern ceiling, legs spread in all directions. A spider-like mass of white mycelium threads with eight legs made of woven fungal strands, bioluminescent blue mushroom eyes, a body covered in tiny parasitic fungi, trailing threads that connect to the walls and floor — it IS the network. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. White and bioluminescent blue. Thick hand-drawn outlines. Ceiling crawl pose. Warm cream parchment background.

---

## Boss 3/10 — Toxic Shroom Knight (Lv.32)

### `boss-toxic-shroom-knight-portrait` — Портрет

A portrait bust of a humanoid warrior with a massive mushroom cap as a helmet, head and shoulders, 3/4 view. A stocky creature wearing the cap of a giant purple-spotted toadstool as a helmet — it's grown INTO the head, eyes barely visible beneath the cap's rim, crude armor made of hardened shelf fungi and bark, a collar of smaller mushrooms, toxic green drool from the mouth, one eye larger than the other peeking out. Looks ridiculous but hits hard. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Purple mushroom cap, brown-green armor. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-toxic-shroom-knight-full` — Полная фигура

A full-body view of the Toxic Shroom Knight in a combat stance, holding a club made of a petrified giant mushroom stalk. A stocky humanoid with a giant purple toadstool cap fused to its head, bark-and-fungus armor, a shield made of a giant shelf fungus, thick legs covered in moss, releasing toxic spores when it moves. The mushroom kingdom's worst soldier. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Purple, brown, toxic green. Thick hand-drawn outlines. Shield-bash stance. Warm cream parchment background.

---

## Boss 4/10 — Rot Toad (Lv.33)

### `boss-rot-toad-portrait` — Портрет

A portrait bust of an enormous toad covered in fungal growths, face and upper body, 3/4 view. A grotesquely swollen toad with warty skin, multiple mushrooms growing directly from its back and head, a massive mouth stretching ear to ear with a toxic purple tongue lolling out, one eye bulging and bloodshot, the other half-closed and crusty, patches of bioluminescent mold on the cheeks. Disgusting and proud of it. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized mouth, dark fantasy cartoon, dark humor. Sickly green-brown with purple fungal accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-rot-toad-full` — Полная фигура

A full-body view of the Rot Toad in a bloated crouch, mouth wide open ready to swallow. An enormous toad with mushrooms growing from its back like a garden, warty mottled skin, a grotesquely long toxic tongue extending forward, sitting in a pool of its own slime, smaller toads and mushrooms around its feet. A portable ecosystem of rot. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Sickly green and purple. Thick hand-drawn outlines. Gulping attack pose. Warm cream parchment background.

---

## Boss 5/10 — Fungal Witch (Lv.34)

### `boss-fungal-witch-portrait` — Портрет

A portrait bust of an ancient hag who has become one with the fungi, head and shoulders, 3/4 view. A wizened crone's face half-consumed by mushroom growth — one side still humanoid (wrinkled, one beady eye, crooked nose), the other side overtaken by a mass of colorful fungi (purple, green, yellow caps sprouting from the cheek and eye socket), a crown of bioluminescent mushrooms replacing hair, spore dust drifting from every crevice. She chose this. She loves it. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Flesh tones merging into fungal purples and greens. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-fungal-witch-full` — Полная фигура

A full-body view of the Fungal Witch floating above a ring of mushrooms, arms spread, commanding spore clouds. A hunched old crone in robes made of living mycelium, half her body consumed by colorful fungal growth, one arm ending in a cluster of mushroom tendrils, the other holding a staff of twisted petrified wood with a glowing mushroom cap at the top, spore clouds swirling around her in patterns. The grotto's mad queen. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Multicolor fungal palette. Thick hand-drawn outlines. Spore-conjuring pose. Warm cream parchment background.

---

## Boss 6/10 — Phosglow Stalker (Lv.35)

### `boss-phosglow-stalker-portrait` — Портрет

A portrait bust of a predatory creature that lures prey with bioluminescence, head and forelimbs, 3/4 view. A lean reptilian-insectoid hybrid with smooth dark skin, a flat angular head, enormous forward-facing eyes reflecting bioluminescent green, a lure-like appendage extending from the forehead tipped with a glowing cyan mushroom, needle-thin teeth in a wide lipless mouth, long clawed fingers. Beautiful and deadly — an anglerfish of the caves. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized eyes, dark fantasy cartoon, dark humor. Dark body with brilliant cyan-green lure glow. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-phosglow-stalker-full` — Полная фигура

A full-body view of the Phosglow Stalker crouching on a stalagmite, ready to leap at prey attracted by its glow. A lean predator with dark smooth skin, long limbs with adhesive pads, a bioluminescent lure dangling from its head casting eerie cyan light, a long prehensile tail tipped with another glowing lure, needle teeth bared in anticipation. The cave's most beautiful nightmare. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Dark with cyan bioluminescent accents. Thick hand-drawn outlines. Predatory crouch pose. Warm cream parchment background.

---

## Boss 7/10 — Cordyceps Puppet (Lv.36)

### `boss-cordyceps-puppet-portrait` — Портрет

A portrait bust of a dead warrior being piloted by parasitic fungi, head and shoulders, 3/4 view. A humanoid corpse — dead eyes staring blankly, mouth frozen in a scream, skin gray and papery — with an enormous cordyceps stalk erupting from the back of the skull, branching into orange-red fruiting bodies, smaller stalks pushing through the eye socket and ear, fungal threads visible beneath the skin of the neck like dark veins. The body is dead. The fungus is very much alive. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Dead gray flesh, vibrant orange-red cordyceps. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-cordyceps-puppet-full` — Полная фигура

A full-body view of the Cordyceps Puppet lurching forward in a broken puppet-like walk, arms dangling at wrong angles. A dead warrior's body in rusted armor, moved by fungal stalks erupting from the spine and skull, limbs jerking in unnatural directions, an enormous orange cordyceps bloom exploding from the head, the original sword still gripped in a death-locked hand. Moves like a marionette with half the strings cut. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Gray corpse, orange-red fungal. Thick hand-drawn outlines. Broken puppet lurch pose. Warm cream parchment background.

---

## Boss 8/10 — Swamp Lurker (Lv.37)

### `boss-swamp-lurker-portrait` — Портрет

A portrait bust of an amphibian predator that hides in toxic pools, head and upper body emerging from water, 3/4 view. A broad flat head like a catfish crossed with an alligator, wide-set eyes covered with a translucent fungal membrane, a mouth stretching the entire width of the head filled with flat crushing teeth, algae and mushrooms growing on its head like camouflage, slimy glistening skin in mottled green-brown. Looks like the swamp floor decided to eat you. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized flat head, dark fantasy cartoon, dark humor. Swamp green-brown with slimy textures. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-swamp-lurker-full` — Полная фигура

A full-body view of the Swamp Lurker bursting from a toxic pool, massive jaws open. An enormous amphibian with a flat wide body, powerful stubby legs with webbed claws, a long whip-like tail, the back covered in mushrooms and algae as natural camouflage, dripping with toxic green water, smaller fish and fungi clinging to its body. A living ambush. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Swamp greens and toxic browns. Thick hand-drawn outlines. Erupting ambush pose. Warm cream parchment background.

---

## Boss 9/10 — Blight Colossus (Lv.38)

### `boss-blight-colossus-portrait` — Портрет

A portrait bust of an enormous fungal giant, head and shoulders towering, 3/4 view. A massive humanoid face made entirely of layered shelf fungi and mushroom caps — the "head" is a cluster of enormous fungi forming a crude face shape, two deep cavities serving as eyes filled with swirling spore clouds, a gaping maw of overlapping mushroom gills, the "shoulders" are rolling hills of fungal growth with small trees and mushrooms growing on top. A walking ecosystem of rot. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with enormous scale, dark fantasy cartoon, dark humor. Multiple fungal colors — purple, brown, sickly yellow. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-blight-colossus-full` — Полная фигура

A full-body view of the Blight Colossus striding through the cavern, head scraping the ceiling. A towering fungal giant made of countless mushrooms and fungal growths layered upon each other, each step releasing massive spore clouds, arms of twisted mycelium thick as tree trunks, smaller creatures living in its body like an apartment building, uprooting stalagmites as it walks. The grotto's immune system. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Full fungal color spectrum. Thick hand-drawn outlines. Towering stride pose. Warm cream parchment background.

---

## Boss 10/10 — Sporoth the Undying (Lv.40) ★ ФИНАЛЬНЫЙ БОСС

### `boss-sporoth-the-undying-portrait` — Портрет

A portrait bust of Sporoth the Undying — the ancient fungal god-brain at the heart of the grotto, head-mass, 3/4 view. Not a creature but a massive intelligent fungal BRAIN — a pulsating mass of interwoven mycelium the size of a room, with multiple "faces" forming and dissolving on its surface (a screaming mouth here, an eye there, a reaching hand), the largest face has two enormous knowing eyes made of bioluminescent caps, surrounded by a halo of the largest most colorful mushrooms in the grotto, psychic spore energy crackling between the faces. Has consumed thousands of minds. Remembers all of them. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with eldritch horror proportions, dark fantasy cartoon, dark humor. Bioluminescent multicolor with pulsing purple core. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-sporoth-the-undying-full` — Полная фигура

A full-body view of Sporoth the Undying — a colossal fungal mass filling a cathedral-sized cavern, with tentacle-like mycelium roots extending in every direction. The central mass is a pulsating brain-like structure with multiple faces emerging and dissolving, surrounded by a forest of enormous bioluminescent mushrooms, mycelium tendrils reaching toward the viewer, smaller cordyceps puppets (previous adventurers) standing guard around the base like zombies. The entire grotto is its body. It has always been watching. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Full bioluminescent spectrum, purple core energy. Thick hand-drawn outlines. Eldritch presence pose. Warm cream parchment background.

---

# ДАНЖ 5: SCORCHED MINES ⛏️ (Lv. 40–50)

> Backend: ❌ not yet defined.
> Theme: abandoned mining complex, coal, dynamite, minecarts, cave-ins, soot, heat.
> Palette: charcoal black, coal dust gray, ember orange, dynamite red, lantern yellow.

---

## Cover — `dungeon-cover-scorched-mines`

A collapsed mine entrance braced with charred wooden beams, a broken minecart track leading into darkness. Dynamite crates stacked haphazardly by the entrance, some with lit fuses (comically). A miner's lantern hanging from a bent nail casting harsh yellow light. Coal dust covering everything. Pick-axes and shovels embedded in the walls. A "DANGER" sign in multiple languages (illegible, burned). Scorch marks from explosions. Rails warped by heat disappearing into the smoldering depths. A single miner's helmet with a cracked lamp sitting on a pile of coal.

Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, no text, no speech bubbles, no UI elements, no logo.

---

## Background — `bg-dungeon-scorched-mines`

Dark fantasy abandoned mine shaft interior, bird's-eye tilted perspective. Narrow mine tunnels with scorched wooden support beams, some collapsed. Minecart rails running through the center, a derailed minecart on its side. Coal seams exposed in the walls glowing faintly orange where they burn underground. Dynamite crates and loose sticks scattered recklessly. Miner's lanterns hanging at intervals, some shattered. Pick-axes embedded in walls. Coal dust and soot covering every surface. Underground gas pockets visible as shimmering heat distortion. Scattered bones of miners who didn't make it out. A bucket-and-chain elevator shaft in the corner.

Hand-drawn ink illustration with crosshatching for ALL shading, visible pen strokes, muted watercolor-style color washes over ink linework, thick black outlines on every element, dark fantasy medieval manuscript aesthetic. Color palette: charcoal black, coal dust gray, lantern yellow-orange, ember orange, dynamite red accents. NOT clean digital art. Deliberately rough, textured. 3:2 aspect ratio, dark moody atmosphere, no text, no UI elements, no characters.

---

## Boss 1/10 — Coal Mite (Lv.40)

### `boss-coal-mite-portrait` — Портрет

A portrait bust of a dog-sized insect made of living coal, head and thorax, 3/4 view. A beetle-like creature with a body of compressed coal, faceted coal-crystal eyes reflecting orange light, mandibles that are essentially two sharp coal shards, antennae of thin coal filaments, cracks in its carapace showing ember glow beneath, coal dust constantly shedding from its body. Crunchy and flammable. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Coal black with ember orange cracks. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-coal-mite-full` — Полная фигура

A full-body view of a Coal Mite scuttling aggressively, mandibles spread. A large beetle of living coal, six segmented legs of compressed carbon, a body that crumbles slightly with each movement leaving a trail of coal dust, ember-glow cracks pulsing, mandibles snapping shut with sparks. Step on it and it explodes. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Coal black and ember. Thick hand-drawn outlines. Aggressive scuttle. Warm cream parchment background.

---

## Boss 2/10 — Pickaxe Wraith (Lv.41)

### `boss-pickaxe-wraith-portrait` — Портрет

A portrait bust of the ghost of a dead miner, head and shoulders, 3/4 view. A translucent spectral miner with a cracked hard hat, hollow ghostly eyes still showing the panic of the cave-in that killed him, a mouth frozen in a perpetual scream, a spectral pickaxe raised over one shoulder, coal dust somehow clinging to the ghost, a broken miner's lantern hanging from the belt still glowing sickly green. Died on the job. Still clocking in. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Ghostly pale blue-white with sickly green lantern. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-pickaxe-wraith-full` — Полная фигура

A full-body view of the Pickaxe Wraith swinging its spectral pickaxe in a wide arc. A ghostly miner in tattered work clothes, translucent body revealing the cave wall behind, a cracked hard hat, the pickaxe leaving a trail of ectoplasmic sparks, feet not touching the ground, broken chains and mine debris orbiting the ghost. Overtime in the afterlife. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Ghostly blue-white and green. Thick hand-drawn outlines. Swing attack pose. Warm cream parchment background.

---

## Boss 3/10 — Ember Rat Swarm (Lv.42)

### `boss-ember-rat-swarm-portrait` — Портрет

A portrait bust showing a mass of fire-touched rats, the largest rat's face dominating the frame, 3/4 view. An enormous rat face with smoldering fur, red-ember eyes, blackened whiskers still smoking, yellowed teeth like hot coals, smaller rats climbing over and around the main one, all their fur singed and smoking, some tails actively on fire. The rats don't mind — they've adapted. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized lead rat, dark fantasy cartoon, dark humor. Charred brown-black with ember red eyes. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-ember-rat-swarm-full` — Полная фигура

A full-body view of a massive swarm of ember rats pouring forward like a burning river. Dozens of singed rats of various sizes, the alpha rat in front twice as large, all with smoldering fur and ember eyes, moving as one mass over mine equipment, some rats carrying lit dynamite sticks in their mouths, others with tails on fire leaving scorch trails. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Charred and ember tones. Thick hand-drawn outlines. Swarming flood pose. Warm cream parchment background.

---

## Boss 4/10 — Mine Shaft Horror (Lv.43)

### `boss-mine-shaft-horror-portrait` — Портрет

A portrait bust of a creature that has grown to fill an entire mine shaft, face emerging from darkness, 3/4 view. An amorphous mass of earth, coal, and mine debris that has formed a crude face — two eye sockets made of embedded miner's helmets with the lamps still glowing, a mouth of broken mine rails and wooden beams, veins of coal seam running through like blood vessels, loose rocks and rubble constantly falling from its form. The mine itself woke up. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Earth brown, coal black, helmet-lamp yellow. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-mine-shaft-horror-full` — Полная фигура

A full-body view of the Mine Shaft Horror pressing out of a collapsed tunnel, reaching with arms made of mine rails and support beams. A massive creature of compressed earth and mine debris, embedded tools and equipment visible throughout its body, mine carts for shoulders, rail-track arms, a chest of coal seam, helmet lamps for eyes. An entire collapsed mine section come to vengeful life. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Earth and industrial debris tones. Thick hand-drawn outlines. Emerging crush pose. Warm cream parchment background.

---

## Boss 5/10 — Soot Golem (Lv.44)

### `boss-soot-golem-portrait` — Портрет

A portrait bust of a golem made of compressed soot and ash, head and shoulders, 3/4 view. A crude humanoid head formed from packed black soot, crumbling at the edges, ember-orange eyes in deep-set sockets, a mouth that opens releasing clouds of black soot, coal chunks embedded in the shoulders like epaulettes, ash constantly sifting down from its form like black snow. Touch it and you can't breathe. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Deep black soot with orange ember accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-soot-golem-full` — Полная фигура

A full-body view of the Soot Golem stomping forward, each step releasing a cloud of black dust. A massive humanoid of compressed soot and ash, leaving a trail of darkness, coal chunk fists, ember veins pulsing through the body, smaller soot devils swirling at its feet. The air around it is unbreathable. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Black soot with ember glow. Thick hand-drawn outlines. Dust-cloud stomp pose. Warm cream parchment background.

---

## Boss 6/10 — Dynamite Goblin (Lv.45)

### `boss-dynamite-goblin-portrait` — Портрет

A portrait bust of a crazed goblin demolitions expert, face and shoulders, 3/4 view. A small manic goblin with soot-blackened skin, one eye normal and one replaced with a monocle made from a dynamite cap, a wide toothy grin missing half the teeth (blown out), singed pointy ears (one shorter than the other — blown off), a bandolier of dynamite sticks across the chest, soot and burn marks everywhere, holding a lit match near its own face. Absolutely unhinged and LOVING it. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with manic expression, dark fantasy cartoon, dark humor. Soot-black and dynamite red. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-dynamite-goblin-full` — Полная фигура

A full-body view of the Dynamite Goblin leaping through the air, both hands full of lit dynamite sticks. A tiny crazed goblin covered in soot, a belt of dynamite, a backpack of dynamite, pockets stuffed with dynamite, one foot already bandaged from a previous explosion, a manic grin, ears singed, throwing dynamite in every direction including its own. The mine's least safe employee. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Soot-black, dynamite red, explosion orange. Thick hand-drawn outlines. Mid-air throw pose. Warm cream parchment background.

---

## Boss 7/10 — Magma Centipede (Lv.46)

### `boss-magma-centipede-portrait` — Портрет

A portrait bust of an enormous centipede that lives in lava veins within the mine, head and forward segments, 3/4 view. A massive centipede head with obsidian mandibles, dozens of tiny orange eyes arranged in rows, segments of its body alternating between cooled rock and molten sections, heat distortion around the head, antennae of solidified lava dripping sparks. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Obsidian and molten orange-red segments. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-magma-centipede-full` — Полная фигура

A full-body view of the Magma Centipede bursting from a mine wall, body coiling. An enormous centipede with dozens of legs, body segments alternating between cooled obsidian and glowing molten rock, drilling through stone with its mandibles, leaving a tunnel of molten rock behind, the full serpentine body curving through the frame. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Obsidian and magma segments. Thick hand-drawn outlines. Wall-burst coil pose. Warm cream parchment background.

---

## Boss 8/10 — Minecart Fiend (Lv.47)

### `boss-minecart-fiend-portrait` — Портрет

A portrait bust of a demon that has fused with an iron minecart, face and upper body, 3/4 view. A demon's upper body emerging from a battered iron minecart — muscular soot-covered arms, a horned head with coal-fire eyes, the mouth full of iron teeth (literally — made from mine rails), the minecart body has grown organic — veins of flesh connecting demon to cart, wheels replaced by clawed feet, the cart interior burning with hellfire. Condemned to ride forever. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with industrial body horror, dark fantasy cartoon, dark humor. Iron gray, hellfire orange, demon-flesh red. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-minecart-fiend-full` — Полная фигура

A full-body view of the Minecart Fiend barreling down the tracks at full speed, arms swinging. A demon fused with an iron minecart, the upper body leaning forward aggressively, arms trailing sparks as claws drag along the tunnel walls, the minecart body running on clawed legs instead of wheels, hellfire engine burning in the cart, mine debris flying in its wake. Maximum-speed murder delivery. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Iron and hellfire. Thick hand-drawn outlines. Full-speed charge pose. Warm cream parchment background.

---

## Boss 9/10 — Slag Overlord (Lv.48)

### `boss-slag-overlord-portrait` — Портрет

A portrait bust of an ancient mine foreman transformed into a slag monster, head and shoulders, 3/4 view. A massive humanoid face made of layered industrial slag waste, still wearing a crushed foreman's hard hat, one eye a glowing furnace port, the other a cold dead slag ball, a mouth of fused metal scraps, a whistle fused to the neck (from when he was alive), slag dripping from the jaw like a metal beard. He ran this mine. Now he IS this mine. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Slag gray, furnace orange, industrial metal. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-slag-overlord-full` — Полная фигура

A full-body view of the Slag Overlord rising from a slag pit, towering over the mine. A massive humanoid of industrial slag and mine waste, wearing a crushed hard hat, one hand is a giant slag-encrusted pickaxe, the other a furnace-hot fist, mine rails wrapped around the body like belts, smaller mine creatures cowering at its feet. The ultimate foreman — clock in or get crushed. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Industrial slag and furnace tones. Thick hand-drawn outlines. Commanding overlord pose. Warm cream parchment background.

---

## Boss 10/10 — Cinder Baron Kael (Lv.50) ★ ФИНАЛЬНЫЙ БОСС

### `boss-cinder-baron-kael-portrait` — Портрет

A portrait bust of Cinder Baron Kael — the cursed mine owner who burned alive and refused to stop profiting, head and shoulders, 3/4 view. An aristocratic skeleton in a charred top hat and the remains of a fine suit, the skull constantly smoldering with ember-orange fire in the eye sockets, a monocle fused to the skull over one eye socket, a gold pocket watch chain melted to the ribcage, burned paper money stuffed in the hat band, a cigar of pure coal clenched between gold teeth. Died rich. Still collecting. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with aristocratic skeleton proportions, dark fantasy cartoon, dark humor. Charred black, ember orange, tarnished gold. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-cinder-baron-kael-full` — Полная фигура

A full-body view of Cinder Baron Kael standing atop a mountain of scorched gold coins, cane raised like a scepter. A burning aristocratic skeleton in a charred tailcoat, top hat, and spats, one hand holding a gold-tipped cane that doubles as a dynamite detonator, the other clutching a burning ledger book, surrounded by ghostly miners still working at his command, gold coins melting and re-solidifying around his feet. The mine's eternal capitalist nightmare. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Charred elegance, burning gold, ember skeleton. Thick hand-drawn outlines. Capitalist overlord pose. Warm cream parchment background.

---

# ДАНЖ 6: FROZEN ABYSS ❄️ (Lv. 50–60)

> Backend: ❌ not yet defined.
> Theme: frozen underground chasm, permafrost, ice caves, crystalline formations, ancient frozen things thawing.
> Palette: ice blue, frost white, deep midnight blue, pale cyan, glacier green, cold purple.

---

## Cover — `dungeon-cover-frozen-abyss`

A gaping chasm in the earth with walls of ancient blue ice, jagged frozen stalactites hanging like teeth over the entrance. A rickety ice-covered rope bridge crossing the opening. Frost crystals growing from every surface in geometric patterns. The depth below is pure black with faint blue glows from deep within. Frozen waterfalls on either side, mid-cascade, trapped in time. Ancient bones and weapons frozen into the ice walls, visible but unreachable. A cold wind blowing snow and ice crystals upward from the abyss.

Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, no text, no speech bubbles, no UI elements, no logo.

---

## Background — `bg-dungeon-frozen-abyss`

Dark fantasy frozen underground cavern interior, bird's-eye tilted perspective. A vast ice cave with walls of translucent blue glacier ice, ancient creatures and warriors visible frozen inside the walls like a museum. The floor is polished black ice with frost patterns. Enormous ice stalagmites and stalactites. A frozen underground river cutting through the center, the ice cracked and groaning. Frost crystal formations growing from the ceiling like chandeliers. Cold blue light emanating from deep ice. Snow drifting from above despite being underground. Chains and old climbing equipment frozen to the walls.

Hand-drawn ink illustration with crosshatching for ALL shading, visible pen strokes, muted watercolor-style color washes over ink linework, thick black outlines on every element, dark fantasy medieval manuscript aesthetic. Color palette: deep midnight blue, ice blue, frost white, pale cyan, cold purple accents. NOT clean digital art. Deliberately rough, textured. 3:2 aspect ratio, dark moody atmosphere, no text, no UI elements, no characters.

---

## Boss 1/10 — Ice Wisp (Lv.50)

### `boss-ice-wisp-portrait` — Портрет

A portrait bust of a tiny floating ice spirit, 3/4 view. A small orb of swirling frost and ice crystals with a vaguely face-like arrangement — two dark spots for eyes that look perpetually surprised, a jagged line of frost for a mouth, tiny ice-crystal arms, surrounded by a halo of snowflakes. Looks adorable. Freezes your blood on contact. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Pale blue-white with cyan crystal accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-ice-wisp-full` — Полная фигура

A full-body view of an Ice Wisp darting through the air, trailing frost crystals. A floating sphere of condensed frost energy with a face, tiny crystal arms outstretched, a comet-tail of snowflakes and ice shards behind it, the air around it visibly freezing, small icicles forming wherever it passes. The cave's most inconveniently cute hazard. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Ice blue-white. Thick hand-drawn outlines. Darting flight pose. Warm cream parchment background.

---

## Boss 2/10 — Frost Grub (Lv.51)

### `boss-frost-grub-portrait` — Портрет

A portrait bust of a massive larva adapted to extreme cold, head section, 3/4 view. An enormous pale blue grub with translucent skin showing dark organs within, a ring of tiny black eyes around the head, a circular mouth with rings of ice-crystal teeth, frost growing on its segmented body like fur, two small frost-tipped antennae, constantly secreting a frozen slime that solidifies on contact. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with bloated proportions, dark fantasy cartoon, dark humor. Pale blue translucent with dark internal organs. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-frost-grub-full` — Полная фигура

A full-body view of the Frost Grub rearing up, mouth open to bite. A massive segmented grub of pale ice-blue, translucent sections revealing frozen internal organs, stubby frost-tipped legs, a trail of frozen slime behind it, the mouth a terrifying lamprey-ring of ice teeth. Surprisingly fast for something so disgusting. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Pale ice blue. Thick hand-drawn outlines. Rearing bite pose. Warm cream parchment background.

---

## Boss 3/10 — Glacial Skeleton (Lv.52)

### `boss-glacial-skeleton-portrait` — Портрет

A portrait bust of an ancient warrior skeleton encased in ice, skull and shoulders, 3/4 view. A human skeleton with bones turned blue-white from centuries in ice, frost crystals growing from eye sockets, a crown of icicles replacing a helmet, ice filling the ribcage like a frozen heart, ancient armor fragments frozen to the bones, jaw locked in a permanent frost-sealed grin. Thawed just enough to move. Not enough to stop being cold. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Ice blue bones, frost white. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-glacial-skeleton-full` — Полная фигура

A full-body view of the Glacial Skeleton lurching forward with an ice-encased sword. A frost-blue skeleton with ice crystals growing from every joint, ancient frozen armor hanging in pieces, wielding a sword that's mostly a blade-shaped icicle, each step cracking the ice on its body, frost aura surrounding it. Has been waiting in this cave for centuries for someone to fight. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Ice blue and frost white. Thick hand-drawn outlines. Frozen lurch pose. Warm cream parchment background.

---

## Boss 4/10 — Snow Hag (Lv.53)

### `boss-snow-hag-portrait` — Портрет

A portrait bust of a terrifying ice witch, head and shoulders, 3/4 view. An ancient crone with blue-gray skin stretched tight over sharp bones, a long hooked nose with an icicle hanging from the tip, milky white eyes with no pupils, wild white hair that's actually frozen in place like a sculpture, blue lips pulled back in a cruel smile showing teeth of ice, frost patterns tattooed across the face, wearing a shawl of frozen spider silk. She's been cold so long she forgot what warmth is. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with elongated features, dark fantasy cartoon, dark humor. Blue-gray skin, ice white. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-snow-hag-full` — Полная фигура

A full-body view of the Snow Hag conjuring a blizzard, hands outstretched, robes whipping in frozen wind. A tall gaunt crone in tattered blue-white robes frozen stiff in places, bare frost-blue feet, long clawed fingers trailing ice magic, a staff of a frozen branch with a captured ice wisp at the top, surrounded by swirling snow and ice shards. The temperature drops 20 degrees when she appears. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Blue-gray and blizzard white. Thick hand-drawn outlines. Blizzard-casting pose. Warm cream parchment background.

---

## Boss 5/10 — Frozen Knight (Lv.54)

### `boss-frozen-knight-portrait` — Портрет

A portrait bust of a paladin who froze to death on a quest and keeps fighting, helmet and shoulders, 3/4 view. Ornate plate armor completely encased in thick ice, the visor frozen open showing a blue-skinned frozen face with frost on the eyelashes, the eyes still burning with faint blue determination, ice growing from the joints making the armor even bulkier, a frozen cape of solid ice extending behind like a shelf. Duty doesn't end at death. Or freezing. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with ice-enlarged armor, dark fantasy cartoon, dark humor. Silver armor under blue ice. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-frozen-knight-full` — Полная фигура

A full-body view of the Frozen Knight in a wide defensive stance, ice-encased sword and shield ready. A massive armored figure made twice as large by the ice growing on the armor, every movement cracking ice that immediately re-forms, a frozen two-handed sword, a tower shield of solid ice with an ancient crest barely visible beneath, icicles hanging from every edge. So frozen it's become its own ice golem. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Silver and ice blue. Thick hand-drawn outlines. Frozen guardian pose. Warm cream parchment background.

---

## Boss 6/10 — Blizzard Wolf (Lv.55)

### `boss-blizzard-wolf-portrait` — Портрет

A portrait bust of an enormous wolf made partly of living blizzard, head and mane, 3/4 view. A massive wolf head with ice-white fur that dissolves into swirling snow at the edges, piercing pale blue eyes with slit pupils, a muzzle covered in frost, fangs of solid ice, a mane of frozen spikes and snow crystals, breath visible as a concentrated cone of frost. The blizzard has teeth. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized head, dark fantasy cartoon, dark humor. White, ice blue, frost. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-blizzard-wolf-full` — Полная фигура

A full-body view of the Blizzard Wolf mid-howl, a blizzard erupting from its body. A massive dire wolf with fur of ice crystals, the hindquarters dissolving into a localized blizzard, ice claws, a trail of frozen ground behind each step, mid-howl with a visible shockwave of cold radiating outward. Part wolf, part weather event. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. White and ice blue. Thick hand-drawn outlines. Blizzard-howl pose. Warm cream parchment background.

---

## Boss 7/10 — Crystal Lurker (Lv.56)

### `boss-crystal-lurker-portrait` — Портрет

A portrait bust of a predatory creature that mimics ice crystal formations, face emerging from crystals, 3/4 view. At first glance a cluster of ice crystals — but look closer and you see two eyes nestled between crystal shafts, a mouth that opens by splitting a crystal in half, skin that's a perfect camouflage of crystal-texture, one clawed hand reaching out from between formations. You walked past a dozen of these without noticing. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with camouflage elements, dark fantasy cartoon, dark humor. Crystal clear and pale cyan. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-crystal-lurker-full` — Полная фигура

A full-body view of the Crystal Lurker fully emerged from its crystal camouflage, lunging forward. A lean predator with crystal-textured skin, angular limbs that fold to look like crystal formations, a long spiked tail of crystal shards, emerging from a wall of ice crystals — impossible to tell where the cave ends and the creature begins. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Crystal clear and ice blue. Thick hand-drawn outlines. Ambush lunge pose. Warm cream parchment background.

---

## Boss 8/10 — Permafrost Giant (Lv.57)

### `boss-permafrost-giant-portrait` — Портрет

A portrait bust of an ancient giant frozen in the earth for millennia, now partially thawed, head and shoulders, 3/4 view. An enormous craggy face of frozen earth and ice — the "skin" is permafrost soil with ice lenses, one eye thawed and glowing cold blue, the other still frozen shut, a mouth of permafrost that cracks open releasing ancient cold air, frozen mammoth tusks protruding from the shoulders like pauldrons, preserved grass and ancient flowers still frozen in its hair. It remembers the last ice age. It wants it back. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Earth-brown permafrost with ice blue. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-permafrost-giant-full` — Полная фигура

A full-body view of the Permafrost Giant tearing free from the cavern wall, ancient ice and soil falling from its body. An enormous humanoid of frozen earth, ice, and ancient organic matter, half still embedded in the wall, one arm free swinging a club of solid permafrost, mammoth bones visible inside its body, ancient frozen animals falling from its form as it moves. Awake for the first time in 10,000 years and very cranky. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Permafrost earth and ancient ice. Thick hand-drawn outlines. Breaking-free pose. Warm cream parchment background.

---

## Boss 9/10 — Avalanche Wyrm (Lv.58)

### `boss-avalanche-wyrm-portrait` — Портрет

A portrait bust of a serpentine ice dragon that lives in the deepest crevasses, head and neck, 3/4 view. A sleek serpentine dragon head with scales of overlapping ice plates, two forward-facing eyes of deep glacier blue, a mouth full of icicle fangs arranged in rows, a crest of razor-sharp ice shards along the skull, frost breath constantly leaking from between the teeth, small ice crystals forming and breaking on the scales. Elegant and lethal. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with elongated serpentine proportions, dark fantasy cartoon, dark humor. Ice-plate white and deep glacier blue. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-avalanche-wyrm-full` — Полная фигура

A full-body view of the Avalanche Wyrm coiled around an ice pillar, head striking forward. A massive wingless serpentine dragon with a body of ice-plate scales, no legs — it moves like a snake through ice, a crest of ice shards running the entire body length, the tail ending in a massive ice-crystal club, frost aura freezing the air around it. Fast, silent, inevitable. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. White and deep blue. Thick hand-drawn outlines. Coiled strike pose. Warm cream parchment background.

---

## Boss 10/10 — Cryoth the Icebound (Lv.60) ★ ФИНАЛЬНЫЙ БОСС

### `boss-cryoth-the-icebound-portrait` — Портрет

A portrait bust of Cryoth the Icebound — an ancient frost titan sealed in the heart of a glacier, head emerging from ice, 3/4 view. A colossal face half-emerging from a glacier wall — one enormous eye of deep sapphire blue with a frost-spiral pupil, the other still sealed behind ice, a crown of massive icicles like a king's diadem, the skin is blue-white ancient ice with veins of frozen magical energy, the mouth frozen in mid-roar, cracks spreading across the glacier as it awakens. Has been imprisoned here since before the kingdom existed. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with titanic scale, dark fantasy cartoon, dark humor. Deep sapphire blue, glacier white, magical frost energy. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-cryoth-the-icebound-full` — Полная фигура

A full-body view of Cryoth the Icebound shattering free from the glacier, the entire cavern cracking around it. A colossal frost titan — humanoid but massive, body of ancient enchanted ice, a crown of icicles, arms ending in claws of crystallized cold, the remains of magical chains (its prison) still dangling from wrists and ankles, glacier fragments orbiting its body, the floor beneath it frozen solid in an expanding circle, pure cold radiating visible waves. The oldest and coldest thing alive. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Deep blue, glacier white, magical sapphire. Thick hand-drawn outlines. Breaking-free titanic pose. Warm cream parchment background.

---

# ДАНЖ 7: REALM OF LIGHT ✨ (Lv. 60–70)

> Backend: ❌ not yet defined.
> Theme: blinding radiance, corrupted temple of light, searing holy energy turned hostile, gold and white gone wrong.
> Palette: blinding white, burnished gold, searing yellow, pale holy blue, tarnished silver.

---

## Cover — `dungeon-cover-realm-of-light`

A grand temple entrance of white marble and burnished gold, blindingly bright — but something is wrong. The light is too intense, too sharp. The golden columns are cracked and leaking searing light like wounds. Marble statues of angels flanking the entrance, their faces melted smooth by their own radiance. A stairway of gold leading up to massive doors thrown open, blinding white light pouring out. The ground around the entrance is scorched white — nothing grows, nothing survives the light. Moths and insects drawn to the glow, burning up mid-flight.

Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, no text, no speech bubbles, no UI elements, no logo.

---

## Background — `bg-dungeon-realm-of-light`

Dark fantasy corrupted temple of light interior, bird's-eye tilted perspective. A vast cathedral-like hall of white marble and gold, every surface radiating hostile light. Tall stained glass windows (shattered, light pouring through the gaps). Gold-leafed columns cracked and weeping searing energy. A central altar of pure light too bright to look at directly. The marble floor scorched with burn patterns from worshippers who got too close. Floating motes of aggressive light energy. Holy symbols on the walls warped and melted. Gold everywhere — too much gold — oppressive, blinding.

Hand-drawn ink illustration with crosshatching for ALL shading, visible pen strokes, muted watercolor-style color washes over ink linework, thick black outlines on every element, dark fantasy medieval manuscript aesthetic. Color palette: blinding white, burnished gold, searing yellow, pale blue holy light, scorched marble. NOT clean digital art. Deliberately rough, textured. 3:2 aspect ratio, no text, no UI elements, no characters.

---

## Boss 1/10 — Radiant Moth (Lv.60)

### `boss-radiant-moth-portrait` — Портрет

A portrait bust of an enormous moth that feeds on holy light, head and wings, 3/4 view. A massive moth with wings of hammered gold leaf, compound eyes that are tiny suns, fuzzy antennae crackling with light energy, a proboscis that siphons radiance, the body covered in fine golden dust, wings creating lens-flare patterns. Beautiful, blinding, and ravenously hungry for your light. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with exaggerated wingspan, dark fantasy cartoon, dark humor. Gold, white, searing yellow. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-radiant-moth-full` — Полная фигура

A full-body view of the Radiant Moth hovering, wings spread wide, releasing bursts of blinding light. An enormous golden moth, wings spanning wide with intricate holy patterns, six legs tipped with tiny golden claws, a trail of golden dust, the air around it shimmering with heat. The temple's prettiest pest. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Gold and blinding white. Thick hand-drawn outlines. Hovering display pose. Warm cream parchment background.

---

## Boss 2/10 — Light Scarab (Lv.61)

### `boss-light-scarab-portrait` — Портрет

A portrait bust of a beetle made of solidified light energy, head and thorax, 3/4 view. A scarab beetle with a carapace of crystallized light — prismatic, refracting rainbows at the edges, mandibles of focused light that cut like lasers, eyes that are two concentrated beams, hieroglyphic patterns etched into the shell glowing gold. An ancient temple guardian in insect form. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Prismatic light with gold hieroglyphs. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-light-scarab-full` — Полная фигура

A full-body view of the Light Scarab charging forward, shell open, inner wings of pure light deployed. A large beetle of crystallized light, six prismatic legs, the carapace split open revealing wings of concentrated radiance, leaving a trail of scorched ground, mandibles glowing white-hot. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Prismatic and gold. Thick hand-drawn outlines. Charging flight pose. Warm cream parchment background.

---

## Boss 3/10 — Blinding Sentinel (Lv.62)

### `boss-blinding-sentinel-portrait` — Портрет

A portrait bust of a temple guardian statue that has come to life with hostile light, head and shoulders, 3/4 view. A marble statue head with blank smooth features — no pupils, just searing light pouring from the eye sockets, the mouth a slit leaking white energy, gold leaf armor cracked and bleeding light, serene expression despite being terrifying. Designed to protect. Now it protects against everyone. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with smooth unsettling features, dark fantasy cartoon, dark humor. White marble, gold, searing light. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-blinding-sentinel-full` — Полная фигура

A full-body view of the Blinding Sentinel standing guard, a massive two-handed golden mace raised. A marble and gold statue come to life — smooth featureless face, light pouring from every crack, golden armor, a halo of concentrated light behind the head, standing on a pedestal it tore from the floor. Judgment has no face. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Marble white and burnished gold. Thick hand-drawn outlines. Guardian judgment pose. Warm cream parchment background.

---

## Boss 4/10 — Solar Monk (Lv.63)

### `boss-solar-monk-portrait` — Портрет

A portrait bust of a monk who meditated on light until it consumed him, head and shoulders, 3/4 view. A bald monk with serene closed eyes — but light leaks from the eyelids, mouth sealed with golden thread, skin translucent showing veins of liquid light, a third eye on the forehead WIDE OPEN and blazing like a searchlight, prayer beads of tiny suns around the neck, the robes bleached pure white and smoking at the edges. Found enlightenment. It's killing him. He doesn't care. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Translucent skin with inner light, white robes. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-solar-monk-full` — Полная фигура

A full-body view of the Solar Monk levitating in lotus position, third eye beaming a cone of searing light. A gaunt translucent monk in white robes, hovering, hands in prayer mudra, light energy radiating from every pore, the floor beneath scorched in a perfect circle, prayer beads orbiting the body, shadows unable to exist near him. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. White and inner golden light. Thick hand-drawn outlines. Levitating meditation pose. Warm cream parchment background.

---

## Boss 5/10 — Gilded Automaton (Lv.64)

### `boss-gilded-automaton-portrait` — Портрет

A portrait bust of a mechanical angel built of gold and holy machinery, head and shoulders, 3/4 view. A clockwork face of polished gold with painted-on serene features (cracked paint revealing gears beneath), crystal eyes refracting light, a halo of spinning golden gears behind the head, neck of exposed golden clockwork, wings of beaten gold with feather-shaped blades, inscriptions in holy script engraved on every surface. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with mechanical angel proportions, dark fantasy cartoon, dark humor. Gold, crystal, holy inscriptions. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-gilded-automaton-full` — Полная фигура

A full-body view of the Gilded Automaton descending from above, golden wings extended, a sword of light in each hand. A mechanical angel of gold and holy clockwork, articulated golden limbs, wings of razor-sharp golden feathers, a halo of spinning gears, feet that don't touch the ground — suspended by golden chains from above. Engineered divinity. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Burnished gold and light. Thick hand-drawn outlines. Descending judgment pose. Warm cream parchment background.

---

## Boss 6/10 — Searing Angel (Lv.65)

### `boss-searing-angel-portrait` — Портрет

A portrait bust of a corrupted angel whose holy fire has gone out of control, head and wings, 3/4 view. A beautiful face twisted in agony — skin cracking like porcelain revealing searing white light beneath, eyes weeping golden fire, a mouth screaming silently with light pouring out, a halo above the head burning too brightly, warped and tilted, wings of white flame not feathers, once-elegant features melting from their own radiance. Was once beautiful. Still is. It hurts. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with anguished beauty, dark fantasy cartoon, dark humor. White, gold, cracking porcelain. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-searing-angel-full` — Полная фигура

A full-body view of the Searing Angel hovering, arms outstretched, light erupting from cracks all over its body. A humanoid figure of cracking porcelain skin, wings of white holy fire, golden tears streaking down the face, robes burning away revealing more light, the floor beneath melting from proximity. Too holy to touch. Too broken to stop. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Cracking white and burning gold. Thick hand-drawn outlines. Radiant agony pose. Warm cream parchment background.

---

## Boss 7/10 — Prism Golem (Lv.66)

### `boss-prism-golem-portrait` — Портрет

A portrait bust of a massive golem made of crystal prisms, head and shoulders, 3/4 view. A crude humanoid head made of transparent crystal prisms fitted together like puzzle pieces, light entering from one side and splitting into rainbow beams from the other, a face visible deep inside the crystal — the trapped soul of the builder, fissures where prisms have cracked leaking concentrated light. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Transparent crystal with rainbow refractions. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-prism-golem-full` — Полная фигура

A full-body view of the Prism Golem standing wide, refracting light in every direction like a walking disco ball of death. A massive humanoid of crystal prisms, every surface splitting light into dangerous rainbow beams, fists of concentrated crystal, leaving rainbow scorch marks on the walls, some prisms cracked and leaking raw light energy. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Crystal and rainbow beams. Thick hand-drawn outlines. Refracting smash pose. Warm cream parchment background.

---

## Boss 8/10 — Halo Wraith (Lv.67)

### `boss-halo-wraith-portrait` — Портрет

A portrait bust of a ghost of a saint, corrupted by its own holy power, head and shoulders, 3/4 view. A spectral figure in golden robes, a face of pure light with hollow dark sockets where eyes should be — the inverse of normal ghosts, a massive golden halo behind the head cracked down the middle, spectral hands clutching a holy book that burns with white fire, chains of golden light binding the ghost to this realm. Too holy to die. Too corrupted to live. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with holy ghost proportions, dark fantasy cartoon, dark humor. Gold spectral, broken halo. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-halo-wraith-full` — Полная фигура

A full-body view of the Halo Wraith gliding above the floor, golden chains trailing, casting judgment. A spectral saint in golden robes, transparent but radiating light, a cracked halo spinning behind the head, one hand raised casting a beam of golden judgment, the other clutching the burning holy book, chains of light connecting to the temple pillars. Hauntingly beautiful. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Spectral gold and holy white. Thick hand-drawn outlines. Floating judgment pose. Warm cream parchment background.

---

## Boss 9/10 — Dawn Colossus (Lv.68)

### `boss-dawn-colossus-portrait` — Портрет

A portrait bust of a colossal statue of a sun god, animated by corrupted radiance, head and shoulders, 3/4 view. An enormous head of white marble and gold — the face is the sun personified, a wide open mouth radiating light like a furnace, eyes like two sunrise beams, a crown of golden rays extending from the head, the marble cracking from the energy within, gold leaf peeling off in sheets. The temple's ultimate defense — a god that no one can turn off. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with colossal divine scale, dark fantasy cartoon, dark humor. White marble, gold, solar radiance. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-dawn-colossus-full` — Полная фигура

A full-body view of the Dawn Colossus stepping forward, one massive foot crushing the temple floor, arms raised to the ceiling. An enormous marble and gold statue of a sun god come to life, radiant crown, a massive golden scepter in one hand, the other hand open and blasting concentrated dawn-light, marble cracking across the body revealing inner radiance, smaller temple statues crumbling as it moves. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Marble and gold divine. Thick hand-drawn outlines. Apocalyptic stride pose. Warm cream parchment background.

---

## Boss 10/10 — Lucirath the Unblinking (Lv.70) ★ ФИНАЛЬНЫЙ БОСС

### `boss-lucirath-the-unblinking-portrait` — Портрет

A portrait bust of Lucirath the Unblinking — a primordial entity of pure light that should never have been worshipped, a single enormous eye, 3/4 view. Not a creature — an EYE. An enormous single eye of pure golden-white radiance occupying the entire frame, the iris a spiral of holy symbols and geometric patterns, the pupil a void of absolute brilliance, surrounded by a corona of golden fire, smaller eyes orbiting the main one like moons, everything it looks at burns. It sees everything. It cannot look away. It does not blink. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with eldritch eye proportions, dark fantasy cartoon, dark humor. Pure gold-white radiance, geometric patterns. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-lucirath-the-unblinking-full` — Полная фигура

A full-body view of Lucirath the Unblinking — a massive eye floating above the altar, tentacles of concentrated light extending in all directions, smaller eyes opening on the walls. A colossal single eye of golden radiance as the central mass, six beam-tentacles of focused light extending outward, each ending in a smaller eye that independently tracks targets, the air around it crystallized from sheer energy, the floor directly below turned to glass. The temple was built to contain it, not worship it. It's been watching the whole time. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Blinding gold-white, geometric eldritch. Thick hand-drawn outlines. Omniscient horror pose. Warm cream parchment background.

---

# ДАНЖ 8: SHADOW DEPTHS 🌑 (Lv. 70–80)

> Backend: ❌ not yet defined.
> Theme: absolute darkness, void, shadow entities, the absence of light, psychological horror.
> Palette: pitch black, void purple, shadow gray, pale ghostly white, dark violet.

---

## Cover — `dungeon-cover-shadow-depths`

A crack in reality leading downward into absolute blackness — not darkness, the total absence of light and color. The edges of the crack are ragged, as if reality was torn. Shadow tendrils reaching upward from the void like hands. The stone around the entrance has lost its color — gray fading to black. Shadow creatures barely visible at the threshold, just pale eyes. A discarded torch at the entrance, extinguished — light cannot survive here. The ground around the entrance is stained black like an oil spill of pure shadow.

Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, no text, no speech bubbles, no UI elements, no logo.

---

## Background — `bg-dungeon-shadow-depths`

Dark fantasy void cavern interior, bird's-eye tilted perspective. Not a natural cave — a space where darkness IS the material. Walls of solid shadow, slightly undulating as if alive. Floating platforms of dark stone suspended in void. Faint purple-violet veins of dark energy running through the "walls." Pale ghostly wisps drifting like deep-sea jellyfish. The floor is black glass reflecting nothing. Chains of shadow holding things that shouldn't exist. The sense that the darkness has depth, layers, and things living between those layers.

Hand-drawn ink illustration with crosshatching for ALL shading, visible pen strokes, muted watercolor-style color washes over ink linework, thick black outlines on every element, dark fantasy medieval manuscript aesthetic. Color palette: pitch black, void purple, dark violet, ghostly pale white wisps, shadow gray. NOT clean digital art. Deliberately rough, textured. 3:2 aspect ratio, dark moody atmosphere, no text, no UI elements, no characters.

---

## Boss 1/10 — Void Maggot (Lv.70)

### `boss-void-maggot-portrait` — Портрет

A portrait bust of a larva made of solidified darkness, head section, 3/4 view. A fat segmented maggot of pure black — not dark-colored, actually absorbing light, with segments visible only where void-purple veins pulse, a circular mouth of tiny void-teeth that erase what they bite, two pale pinprick eyes. Disturbingly simple. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Void black with purple veins and pale eyes. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-void-maggot-full` — Полная фигура

A full-body view of the Void Maggot writhing forward, mouth gaping. A fat segmented worm of pure shadow, leaving a trail of erased ground behind, void-purple veins pulsing along its length, the circular mouth dissolving reality at the edges. It eats light. You're next. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Void black and purple. Thick hand-drawn outlines. Writhing advance pose. Warm cream parchment background.

---

## Boss 2/10 — Shade Crawler (Lv.71)

### `boss-shade-crawler-portrait` — Портрет

A portrait bust of a spider made of living shadow, head and forelegs, 3/4 view. A spider shape defined by absence — where it exists, you see nothing, the outline visible only against the parchment, eight eyes of pale ghostly white, mandibles of concentrated darkness that seem to cut into the background itself. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Shadow silhouette with pale white eyes. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-shade-crawler-full` — Полная фигура

A full-body view of the Shade Crawler descending from above on a thread of darkness. Eight legs of solid shadow, a body that's a hole in reality, leaving web-like strands of darkness, pale eyes multiplied across the body. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Shadow and pale eyes. Thick hand-drawn outlines. Descending pose. Warm cream parchment background.

---

## Boss 3/10 — Dusk Phantom (Lv.72)

### `boss-dusk-phantom-portrait` — Портрет

A portrait bust of a ghost where the boundary between light and dark has broken, half-face, 3/4 view. Half the face is a normal ghostly specter, the other half is dissolving into void — the boundary between the halves shifts and churns, one eye normal ghostly white, the other a void-purple spiral, the mouth splits between a scream and a void. Caught between existing and not. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Ghost white splitting into void purple-black. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-dusk-phantom-full` — Полная фигура

A full-body view of the Dusk Phantom flickering between visibility and void, arms reaching. A humanoid specter constantly shifting — one moment visible as a pale ghost, the next dissolving into shadow patches, trailing afterimages, the outline unstable. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Flickering ghost-white and void. Thick hand-drawn outlines. Unstable reach pose. Warm cream parchment background.

---

## Boss 4/10 — Abyssal Leech (Lv.73)

### `boss-abyssal-leech-portrait` — Портрет

A portrait bust of an enormous leech from the deepest void, mouth section, 3/4 view. A massive circular lamprey mouth of concentric rings of void-teeth, the interior pure black, the body glistening dark violet, covered in sensory bumps that detect light to consume it, dripping black ichor. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized mouth, dark fantasy cartoon, dark humor. Dark violet with void-black mouth. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-abyssal-leech-full` — Полная фигура

A full-body view of the Abyssal Leech lunging from the darkness, entire body visible. An enormous leech of dark violet, segmented body, lamprey mouth wide open, the suction rings creating a vortex of shadow, a tail anchored in the void behind. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Violet and void black. Thick hand-drawn outlines. Lunging maw pose. Warm cream parchment background.

---

## Boss 5/10 — Nightmare Stalker (Lv.74)

### `boss-nightmare-stalker-portrait` — Портрет

A portrait bust of a creature that embodies nightmares given form, face, 3/4 view. A face that keeps changing — an amalgam of terrifying features: too many eyes arranged wrong, a mouth where an ear should be, human and animal features blending, all rendered in shadow with pale ghostly details. Your brain refuses to process what it sees. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with impossible anatomy, dark fantasy cartoon, dark humor. Shadow with wrong-anatomy pale details. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-nightmare-stalker-full` — Полная фигура

A full-body view of the Nightmare Stalker moving on too many limbs in wrong directions. A humanoid shape but wrong — limbs at wrong angles, joints bending backward, fingers where toes should be, a shadow body with nightmare details, moving in a way that makes your brain hurt. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Shadow body, wrong anatomy. Thick hand-drawn outlines. Impossible movement pose. Warm cream parchment background.

---

## Boss 6/10 — Shadow Weaver (Lv.75)

### `boss-shadow-weaver-portrait` — Портрет

A portrait bust of an entity that weaves shadow into physical forms, head and hands, 3/4 view. A gaunt face of pure shadow with elegant features — sharp cheekbones, a thin knowing smile, eyes of swirling violet void, long delicate fingers working strands of solid darkness like a weaver at a loom, shadow-silk threads extending from each fingertip. An artist of darkness. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with elegant gaunt proportions, dark fantasy cartoon, dark humor. Shadow with violet accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-shadow-weaver-full` — Полная фигура

A full-body view of the Shadow Weaver suspended in a web of darkness, hands orchestrating shadow puppets. A tall gaunt figure floating in a cat's cradle of shadow threads, long robes of woven darkness, each hand controlling multiple threads that extend to shadow creatures fighting at a distance. The puppet master of the depths. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Shadow and violet threads. Thick hand-drawn outlines. Puppet-master pose. Warm cream parchment background.

---

## Boss 7/10 — Darkness Elemental (Lv.76)

### `boss-darkness-elemental-portrait` — Портрет

A portrait bust of a raw elemental of pure darkness, mass with face, 3/4 view. Not a creature with shape — a roiling mass of darkness that occasionally forms features: an eye here, a mouth there, a reaching hand, all dissolving back into formless black, the edges boiling like black smoke, the only constants are two points of pale light that might be eyes. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with formless horror, dark fantasy cartoon, dark humor. Pure black mass with pale eye-points. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-darkness-elemental-full` — Полная фигура

A full-body view of the Darkness Elemental — a towering pillar of living darkness reaching from floor to ceiling. A column of absolute black that shifts and pulses, temporary limbs forming and dissolving, multiple faces appearing briefly, consuming everything it touches into itself. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Absolute black with pale flickers. Thick hand-drawn outlines. Towering consume pose. Warm cream parchment background.

---

## Boss 8/10 — Eclipse Knight (Lv.77)

### `boss-eclipse-knight-portrait` — Портрет

A portrait bust of a fallen holy knight whose light was consumed by the void, helmet and shoulders, 3/4 view. Once-golden armor now half-consumed by shadow — one pauldron still burnished gold, the other dissolved into flowing darkness, the helmet visor showing a face split between golden light and void-purple shadow, a cracked halo behind the head half-bright and half-dark. A knight who fought the darkness and the darkness won half. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Half-gold half-shadow split. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-eclipse-knight-full` — Полная фигура

A full-body view of the Eclipse Knight in combat stance, one hand wielding a sword of light, the other a blade of shadow. Armor split perfectly down the center — gold and holy on one side, void and shadow on the other, a cape that's white on one side and dissolves into darkness on the other, standing on a dividing line between light and shadow. Eternally at war with itself. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Split gold/shadow. Thick hand-drawn outlines. Dual-blade stance. Warm cream parchment background.

---

## Boss 9/10 — Void Colossus (Lv.78)

### `boss-void-colossus-portrait` — Портрет

A portrait bust of an enormous entity made of compressed void, head emerging, 3/4 view. A colossal head of solid darkness so dense it warps the space around it — features visible only as deeper darkness within darkness, two galaxy-like spiral eyes, a mouth that opens to reveal an inner void of infinite depth, the edges of the head distorting the parchment itself as if bending light. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with reality-warping scale, dark fantasy cartoon, dark humor. Compressed void with galaxy-spiral eyes. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-void-colossus-full` — Полная фигура

A full-body view of the Void Colossus standing in the abyss, so large the frame barely contains it. A mountainous humanoid of compressed darkness, gravity distorting around it, smaller shadow creatures orbiting like satellites, each step creating ripples in reality, arms that stretch into infinity. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Void darkness with gravity distortion. Thick hand-drawn outlines. Primordial presence pose. Warm cream parchment background.

---

## Boss 10/10 — Nyxrath the Devourer (Lv.80) ★ ФИНАЛЬНЫЙ БОСС

### `boss-nyxrath-the-devourer-portrait` — Портрет

A portrait bust of Nyxrath the Devourer — the entity that ate all the light from these depths, a face of absolute void, 3/4 view. Not a face in the traditional sense — a concentrated point of absolute darkness so intense it PULLS light into it like a black hole, surrounded by a corona of dying light being consumed, the faintest outline of features visible only where light is being destroyed — an enormous mouth consuming a stream of radiance, eyes that are two collapsing stars. The opposite of light. The thing that eats gods. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with cosmic horror proportions, dark fantasy cartoon, dark humor. Absolute void with dying-light corona. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-nyxrath-the-devourer-full` — Полная фигура

A full-body view of Nyxrath the Devourer — a colossal entity occupying the entire cavern, mouth open consuming reality. A being of absolute darkness shaped like a maw — the entire body IS a mouth, layers upon layers of shadow-teeth spiraling inward toward a central point of total void, tentacles of darkness extending in all directions anchoring to walls and ceiling, streams of consumed light flowing toward the center, the outline of previously consumed creatures visible as briefly-luminous silhouettes within. It doesn't guard the depths. The depths are its stomach. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Absolute void, dying-light streams, consumed silhouettes. Thick hand-drawn outlines. World-devouring maw pose. Warm cream parchment background.

---

# ДАНЖ 9: CLOCKWORK CITADEL ⚙️ (Lv. 80–90)

> Backend: ❌ not yet defined.
> Theme: ancient mechanical fortress, gears, steam, clockwork, brass, copper, malfunctioning machinery.
> Palette: brass gold, copper orange, iron gray, steam white, oil black, green patina.

---

## Cover — `dungeon-cover-clockwork-citadel`

A massive fortress gate made entirely of interlocking gears and mechanical parts. Giant brass cogwheels slowly turning, some jammed with bones and old weapons. Steam venting from pressure valves at the top. A portcullis made of rotating saw-blade gears. Copper pipes running along the walls leaking green steam. A clock face above the entrance, the hands spinning erratically. Mechanical arms extending from the walls, some welcoming, some holding weapons. The entire structure vibrating with the hum of machinery. Oil stains and green patina covering ancient brass.

Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, no text, no speech bubbles, no UI elements, no logo.

---

## Background — `bg-dungeon-clockwork-citadel`

Dark fantasy mechanical fortress interior, bird's-eye tilted perspective. A vast hall of brass, copper, and iron machinery. Enormous gears interlocking across walls and ceiling, some spinning, some stuck. Steam pipes running everywhere, some burst and leaking white steam. Conveyor belts carrying mysterious parts. Brass catwalks over a pit of grinding gears. Control panels with levers and gauges, all at wrong readings. Oil puddles reflecting gear movements. Scattered broken automaton parts. The constant sense of movement — everything turns, ticks, clicks.

Hand-drawn ink illustration with crosshatching for ALL shading, visible pen strokes, muted watercolor-style color washes over ink linework, thick black outlines on every element, dark fantasy medieval manuscript aesthetic. Color palette: brass gold, copper orange, iron gray, steam white, oil black, green patina. NOT clean digital art. Deliberately rough, textured. 3:2 aspect ratio, dark moody atmosphere, no text, no UI elements, no characters.

---

## Boss 1/10 — Rust Tick (Lv.80)

### `boss-rust-tick-portrait` — Портрет

A portrait bust of a mechanical tick — a clockwork parasite, head and legs, 3/4 view. A small mechanical arachnid made of rusted gears and copper plating, eight articulated brass legs, a body of an old pocket watch with the face cracked, mandibles that are tiny spinning drill bits, a single oversized lens-eye, covered in green patina and oil stains. Feeds on other machines. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Rusted brass and green patina. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-rust-tick-full` — Полная фигура

A full-body view of several Rust Ticks swarming, the largest one in front. Mechanical clockwork ticks of various sizes, all brass and copper, drill-mandibles spinning, scuttling on gear-legs, trailing oil, the largest one latched onto a broken automaton arm and draining it. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Rusted clockwork. Thick hand-drawn outlines. Swarming feed pose. Warm cream parchment background.

---

## Boss 2/10 — Gear Sprite (Lv.81)

### `boss-gear-sprite-portrait` — Портрет

A portrait bust of a tiny mechanical fairy, head and wings, 3/4 view. A small humanoid with a face made from a clock face — the eyes are tiny spinning gears, the mouth a keyhole, wings of spinning brass gears and copper wire, a body of interlocking small mechanisms, sparks flying from its joints. Mischievous and precise. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with dainty mechanical proportions, dark fantasy cartoon, dark humor. Polished brass and copper. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-gear-sprite-full` — Полная фигура

A full-body view of the Gear Sprite zipping through the air, leaving a trail of loose cogs. A tiny clockwork fairy, gear-wings buzzing like a hummingbird, clutching a tiny wrench as a weapon, trailing sparks and loose screws, surrounded by a cloud of tiny floating gears. The citadel's most annoying mechanic. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Brass and copper sparkle. Thick hand-drawn outlines. Manic flight pose. Warm cream parchment background.

---

## Boss 3/10 — Steam Sentry (Lv.82)

### `boss-steam-sentry-portrait` — Портрет

A portrait bust of a guard automaton powered by steam, head and torso, 3/4 view. A humanoid robot with a boiler-drum torso, a head that's a pressure gauge with two glass-porthole eyes glowing orange from the furnace inside, a whistle-pipe mouth that screams steam as an alarm, riveted iron panels, one arm a mounted crossbow, steam venting from every joint. On permanent guard duty since the builders died. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with industrial proportions, dark fantasy cartoon, dark humor. Iron gray, steam white, furnace orange. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-steam-sentry-full` — Полная фигура

A full-body view of the Steam Sentry in alert stance, steam whistle blowing, crossbow arm aimed. A bulky steam-powered automaton, boiler-body with pressure gauges in the red, stomping iron feet, crossbow arm aimed, the other arm a steam-powered fist, steam erupting from the whistle-head. INTRUDER DETECTED. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Iron and steam. Thick hand-drawn outlines. Alert firing pose. Warm cream parchment background.

---

## Boss 4/10 — Copper Hound (Lv.83)

### `boss-copper-hound-portrait` — Портрет

A portrait bust of a mechanical hunting dog, head and shoulders, 3/4 view. A clockwork greyhound head of polished copper and brass, articulated jaw with gear-teeth, glass eyes with spinning iris-apertures, copper wire whiskers, steam puffing from nostrils, ears that are satellite dishes rotating to track sound, scratches and dents across the muzzle from centuries of use. A very good (mechanical) boy. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Copper and brass. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-copper-hound-full` — Полная фигура

A full-body view of the Copper Hound in a running leap, all four legs extended. A sleek clockwork greyhound of copper and brass, articulated leg joints, a gear-driven spine visible through the ribcage, a tail that's a rotating antenna, steam trailing behind from exhaust ports, leaving paw prints of hot brass. Fast, loyal, 300 years out of warranty. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Copper gleam. Thick hand-drawn outlines. Full-sprint leap pose. Warm cream parchment background.

---

## Boss 5/10 — Piston Knight (Lv.84)

### `boss-piston-knight-portrait` — Портрет

A portrait bust of a medieval knight made of pistons and hydraulics, helmet and shoulders, 3/4 view. A knight's helmet made of riveted iron with a steam stack for a crest, eye slits revealing spinning gears behind, shoulders of massive hydraulic pistons, the gorget made of interlocking brass plates, steam venting from under the visor, oil dripping like sweat. Chivalry, automated. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with overbuilt mechanical proportions, dark fantasy cartoon, dark humor. Iron and brass with steam. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-piston-knight-full` — Полная фигура

A full-body view of the Piston Knight in heavy combat stance, hydraulic arms wielding a massive gear-mace. A mechanical knight with piston-powered limbs, hydraulic legs, a boiler-backpack powering the suit, each swing of the mace accompanied by a blast of steam, the floor dented from the weight. Too heavy to dodge, too armored to stop. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Heavy iron and brass. Thick hand-drawn outlines. Hydraulic overhead swing pose. Warm cream parchment background.

---

## Boss 6/10 — Gear Mage (Lv.85)

### `boss-gear-mage-portrait` — Портрет

A portrait bust of a mechanical wizard that casts "spells" through precision engineering, head and shoulders, 3/4 view. A robed automaton with a face made of a complex orrery — spinning brass planets and gears forming features, eyes of tiny telescopes, a pointed hat of stacked spinning gears, hands visible at the collar — delicate articulated brass fingers holding tiny precision tools, a beard of dangling copper wires and small pendulums. Magic through engineering. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with wizardly mechanical proportions, dark fantasy cartoon, dark humor. Brass and precision copper. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-gear-mage-full` — Полная фигура

A full-body view of the Gear Mage casting a spell — deploying a complex array of spinning gears that form a magical circle in the air. A robed automaton with orrery-head, delicate brass hands manipulating floating gears into geometric patterns, each pattern producing a different effect, a mechanical familiar (a brass owl) on one shoulder, gear-rune circles spinning around the body. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Brass and floating gear-magic. Thick hand-drawn outlines. Spell-engineering pose. Warm cream parchment background.

---

## Boss 7/10 — Boiler Horror (Lv.86)

### `boss-boiler-horror-portrait` — Портрет

A portrait bust of a massive pressure boiler that has become sentient and hostile, front view, 3/4 view. A giant iron boiler with a face formed by the pressure gauges (eyes, all in the red), the furnace door (mouth, open and flaming), riveted panels bulging dangerously, pipes extending like horns, safety valves screaming steam, the entire surface shaking and rattling, about to explode at any moment. Industrial anxiety incarnate. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with bloated industrial body, dark fantasy cartoon, dark humor. Iron, rust, steam, furnace orange. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-boiler-horror-full` — Полная фигура

A full-body view of the Boiler Horror rolling forward on crude pipe-legs, steam erupting from every valve. A massive iron boiler on mechanical legs, furnace-mouth burning hot, pressure gauges for eyes all showing DANGER, pipes flailing like tentacles, trailing steam and fire, rivets popping off like bullets. Over-pressure, under-maintenance, maximum hostility. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Iron and screaming steam. Thick hand-drawn outlines. Rolling charge pose. Warm cream parchment background.

---

## Boss 8/10 — Cog Centipede (Lv.87)

### `boss-cog-centipede-portrait` — Портрет

A portrait bust of an enormous centipede made of interlocking gears, head and forward segments, 3/4 view. A centipede head with mandibles of meshing gears (crush anything between them), eyes of multiple tiny clock faces, each segment of the body a different gear size, legs are small rotating cogs, antennae of copper wire picking up vibrations. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Brass gears and iron. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-cog-centipede-full` — Полная фигура

A full-body view of the Cog Centipede coiling through the machinery, body winding between gears and pipes. An enormous centipede of interlocking gears, the body meshing with the citadel's own machinery as it moves — it IS part of the infrastructure, separating and reattaching, mandibles spinning. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Brass and iron mechanical. Thick hand-drawn outlines. Coiling through machinery pose. Warm cream parchment background.

---

## Boss 9/10 — Iron Titan (Lv.88)

### `boss-iron-titan-portrait` — Портрет

A portrait bust of an enormous ancient war machine, head and shoulders towering, 3/4 view. A colossal mechanical head of riveted iron plates, a face plate with two searchlight eyes, a voice grille mouth crackling with old electricity, massive brass horn-speakers on the sides, the head alone the size of a house, armor plating inches thick, ancient kill markings scratched into the surface. The citadel's last defense. Finally turned on after centuries. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with industrial war-machine scale, dark fantasy cartoon, dark humor. Heavy iron with searchlight eyes. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-iron-titan-full` — Полная фигура

A full-body view of the Iron Titan standing up, the ceiling breaking above it, arms of industrial hydraulics. A colossal mechanical war golem of riveted iron, standing three stories tall, one arm a massive gear-driven fist, the other a cannon of spinning gears, a furnace-heart burning in the chest visible through a porthole, heavy stomping feet, the citadel shaking with each step. The builders' ultimate weapon, online after 1000 years. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Heavy iron and war-machine tones. Thick hand-drawn outlines. Rising war-machine pose. Warm cream parchment background.

---

## Boss 10/10 — Machinator Prime (Lv.90) ★ ФИНАЛЬНЫЙ БОСС

### `boss-machinator-prime-portrait` — Портрет

A portrait bust of Machinator Prime — the sentient core intelligence of the entire citadel, a face made of a thousand gears, 3/4 view. Not a body — a FACE formed from the convergence of every gear, pipe, and mechanism in the citadel. An enormous face visible in the wall of machinery — eyes of two massive clock faces with hands spinning wildly, a mouth of interlocking gears that speaks in clicks and tones, the face stretches across the entire wall, constantly reconfiguring, pipes and wires as hair, the entire citadel IS its body. It has been calculating for centuries. It has a conclusion. You won't like it. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with architectural scale, dark fantasy cartoon, dark humor. Brass, copper, iron — all the metals. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-machinator-prime-full` — Полная фигура

A full-body view of Machinator Prime — the walls, floor, and ceiling ARE the boss, mechanical limbs extending from every surface. The entire room is alive — massive gear-arms reaching from walls, piston-legs stamping from the floor, sensor-eyes opening across the ceiling, the central clock-face commanding everything, conveyor belts redirecting to carry weapons, pipes rotating to aim steam jets, the furnace-heart of the citadel glowing through the floor grating. You didn't enter the boss room. You entered the boss. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. All metals, all machinery, total mechanical horror. Thick hand-drawn outlines. Living-room attack pose. Warm cream parchment background.

---

# ДАНЖ 10: INFERNAL THRONE 👑🔥 (Lv. 90–100)

> Backend: ❌ not yet defined.
> Theme: hell, demons, brimstone, eternal fire, infernal hierarchy, the final dungeon.
> Palette: hellfire red, brimstone yellow, demon black, molten gold, blood crimson, sulfur.

---

## Cover — `dungeon-cover-infernal-throne`

A colossal gate of black iron and bone, the entrance to hell itself. Two enormous demon skulls form the gateposts, hellfire burning in their eye sockets. The doors are covered in screaming faces pressed from the inside. Rivers of lava flow from either side. A staircase of black obsidian descends into red-lit darkness. The air above shimmers with heat. Chains of damned souls hanging from the arch. The doorframe carved with infernal contracts and dark sigils. Above the gate — a crown of black iron and flame. This is the end.

Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, no text, no speech bubbles, no UI elements, no logo.

---

## Background — `bg-dungeon-infernal-throne`

Dark fantasy infernal throne room interior, bird's-eye tilted perspective. A vast hellish cathedral — black iron pillars carved with tortured souls, a floor of cracked obsidian with lava visible through the cracks, an enormous throne of black iron and bones at the far end on a raised platform of skulls. Rivers of lava channel through the room. Hellfire braziers of demonic design burning with unnatural flame. Chains hanging from a ceiling lost in smoke and fire. Tattered battle banners of defeated kingdoms. A carpet of blackened bones leading to the throne. The walls alive with carved tormented faces.

Hand-drawn ink illustration with crosshatching for ALL shading, visible pen strokes, muted watercolor-style color washes over ink linework, thick black outlines on every element, dark fantasy medieval manuscript aesthetic. Color palette: hellfire red, brimstone yellow, obsidian black, blood crimson, molten gold. NOT clean digital art. Deliberately rough, textured. 3:2 aspect ratio, dark moody atmosphere, no text, no UI elements, no characters.

---

## Boss 1/10 — Hellfire Imp (Lv.90)

### `boss-hellfire-imp-portrait` — Портрет

A portrait bust of a hell-born imp, a nastier cousin of the fire imp, face and upper body, 3/4 view. A small demonic creature with crimson skin, an enormous toothy grin stretching impossibly wide, two mismatched horns — one curled, one straight and broken, bulging yellow sulfur eyes with slit pupils, a forked tongue dripping brimstone, pointed ears with gold rings, a tiny but elaborate iron crown tilted on the head. Thinks it's royalty. Everyone in hell hates it. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with oversized head, dark fantasy cartoon, dark humor. Crimson and brimstone yellow. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-hellfire-imp-full` — Полная фигура

A full-body view of the Hellfire Imp standing on a pile of stolen treasures, juggling brimstone fireballs. A tiny crimson demon with an oversized head, a barbed tail longer than its body, bat wings too small to actually fly, cloven hooves, a stolen crown, surrounded by loot it has hoarded. The least threatening and most annoying thing in hell. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Crimson and gold loot. Thick hand-drawn outlines. Gloating treasure pose. Warm cream parchment background.

---

## Boss 2/10 — Ash Crawler (Lv.91)

### `boss-ash-crawler-portrait` — Портрет

A portrait bust of a demon insect that thrives in volcanic ash, head and thorax, 3/4 view. A cockroach-scorpion hybrid with ashen gray carapace, segmented body of compressed ash, pincers of black iron, a stinger dripping with sulfuric acid, multiple red compound eyes, ash constantly falling from its body. The cockroach of hell. Unkillable. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Ash gray with hellfire-red eyes. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-ash-crawler-full` — Полная фигура

A full-body view of the Ash Crawler skittering forward, stinger raised, pincers open. A large demonic insect hybrid, multiple legs, segmented ash-body, scorpion tail with acid stinger, cockroach wings half-deployed, leaving a trail of hot ash. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Ash gray and red. Thick hand-drawn outlines. Attack scuttle pose. Warm cream parchment background.

---

## Boss 3/10 — Brimstone Brute (Lv.92)

### `boss-brimstone-brute-portrait` — Портрет

A portrait bust of a massive demon made of brimstone and muscle, head and shoulders, 3/4 view. A hulking demon with cracked yellow brimstone skin, a flat brutal face with a jutting underbite showing tusks, tiny angry eyes under a heavy brow, a thick neck wider than the head, steam rising from the skin, patches of skin glowing orange from internal fire, a collar of iron chains fused to the neck. Built for one purpose: hitting things. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with exaggerated muscle mass, dark fantasy cartoon, dark humor. Brimstone yellow and hellfire accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-brimstone-brute-full` — Полная фигура

A full-body view of the Brimstone Brute charging with fists raised, the ground cracking beneath each step. An enormous muscle-bound demon of brimstone, arms as thick as torsos, a chest of cracked yellow stone with fire beneath, legs like pillars, dragging broken chains, a tiny brain and a whole lot of anger. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Brimstone and hellfire. Thick hand-drawn outlines. Charging smash pose. Warm cream parchment background.

---

## Boss 4/10 — Demon Hound (Lv.93)

### `boss-demon-hound-portrait` — Портрет

A portrait bust of a three-headed hellhound, all three heads, 3/4 view. Three dog heads on one neck — each with a different expression (rage, hunger, sadistic glee), crimson fur matted with sulfur, six eyes of burning yellow, three sets of iron-black fangs, one head breathing fire, one drooling acid, one growling ultrasonically, a spiked iron collar connecting at the base. The worst guard dog in creation. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with triple-head focus, dark fantasy cartoon, dark humor. Crimson and sulfur yellow. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-demon-hound-full` — Полная фигура

A full-body view of the three-headed Demon Hound in a wide attack stance, all three heads snapping in different directions. A massive three-headed hellhound with crimson fur, muscular body, a serpentine tail ending in a fanged maw, claws that score obsidian, brimstone smoke trailing from all three mouths, the ground scorched beneath its paws. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Crimson and hellfire. Thick hand-drawn outlines. Triple-snap attack pose. Warm cream parchment background.

---

## Boss 5/10 — Infernal Priestess (Lv.94)

### `boss-infernal-priestess-portrait` — Портрет

A portrait bust of a demon high priestess, face and upper body, 3/4 view. An elegant demoness with smooth obsidian-black skin, ram-like horns of polished black bone curving back, eyes of burning gold with vertical pupils, a cruel beautiful smile showing fangs, an elaborate headdress of black iron and rubies, ritual scars glowing hellfire-red on the cheeks, a necklace of demon teeth and holy symbols worn upside-down. Beauty and damnation. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with elegant demonic proportions, dark fantasy cartoon, dark humor. Obsidian black skin, gold eyes, hellfire accents. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-infernal-priestess-full` — Полная фигура

A full-body view of the Infernal Priestess levitating, arms raised, summoning a hellfire ritual. A tall elegant demoness in robes of black flame, obsidian skin, curving horns, a staff topped with a burning inverted holy symbol, a hellfire circle forming beneath her, demonic sigils floating around her body, a tail of living shadow coiled behind. Hell's head of HR. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Black, gold, and hellfire. Thick hand-drawn outlines. Ritual summoning pose. Warm cream parchment background.

---

## Boss 6/10 — Hellforged Golem (Lv.95)

### `boss-hellforged-golem-portrait` — Портрет

A portrait bust of a golem forged in hellfire from damned souls and iron, head and shoulders, 3/4 view. A massive head of black iron forged in hell — screaming faces of the damned pressed into the metal surface, eyes of molten hellfire, a jaw of interlocking iron plates, demonic runes etched and glowing across every surface, chains embedded in the metal. Made from sin. Fueled by suffering. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Black iron with hellfire runes and soul-faces. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-hellforged-golem-full` — Полная фигура

A full-body view of the Hellforged Golem stomping forward, fists of compressed damned souls. A massive iron golem with screaming faces across its surface, hellfire burning through the seams, each fist a compressed mass of tormented souls in iron, chains trailing behind, demonic runes blazing, the ground melting beneath its feet. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Black iron and hellfire souls. Thick hand-drawn outlines. Unstoppable march pose. Warm cream parchment background.

---

## Boss 7/10 — Pit Fiend (Lv.96)

### `boss-pit-fiend-portrait` — Портрет

A portrait bust of a greater demon — the pit fiend commander, head and shoulders, 3/4 view. A terrifying demon face with crimson skin pulled tight over angular bones, four horns — two sweeping back, two curling forward, fiery orange eyes with intelligence and malice, a mouth of black fangs, a forked beard of living flame, battle scars across the face showing darker flesh beneath, elaborate demonic armor on the shoulders with trophies of defeated heroes. A general of hell. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with commanding demon proportions, dark fantasy cartoon, dark humor. Crimson, dark iron, fire. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-pit-fiend-full` — Полная фигура

A full-body view of the Pit Fiend standing tall with massive bat wings spread, a flaming whip in one hand, a barbed trident in the other. An enormous winged demon in black iron armor, crimson skin, powerful build, a tail ending in a spiked mace-ball, cloven hooves on a throne-room floor, lesser demons cowering at his feet. Commands legions. Enjoys it. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Crimson and black iron. Thick hand-drawn outlines. Commander's challenge pose. Warm cream parchment background.

---

## Boss 8/10 — Doom Knight (Lv.97)

### `boss-doom-knight-portrait` — Портрет

A portrait bust of hell's most feared warrior, helmet and shoulders, 3/4 view. A knight in armor that is ALIVE — demonic black plate armor with faces of the damned moving across its surface, the helmet visor revealing only two burning red eyes and absolute darkness, a crown of black iron thorns welded to the helmet, pauldrons of demon skulls, a cape of solidified hellfire. The armor chose its wearer. Or consumed them. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with imposing armored proportions, dark fantasy cartoon, dark humor. Black demonic armor, hellfire red. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-doom-knight-full` — Полная фигура

A full-body view of the Doom Knight in a wide battle stance, wielding a greatsword of black flame. A massive armored figure in living demonic plate, the greatsword burning with black fire, a shield of compressed damned souls, the cape of solidified hellfire flowing behind, every step leaving burning footprints, the air around warping from infernal energy. Hell's champion. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Black armor, black flame, crimson. Thick hand-drawn outlines. Executioner stance. Warm cream parchment background.

---

## Boss 9/10 — Apocalypse Dragon (Lv.98)

### `boss-apocalypse-dragon-portrait` — Портрет

A portrait bust of a dragon born from the end of the world, head and neck, 3/4 view. A colossal dragon head of cracked obsidian scales with hellfire bleeding through every crack, six horns of varying sizes and shapes — some broken from ancient battles, eyes of pure hellfire with cross-shaped pupils, a mouth full of teeth made from the weapons of defeated heroes, a mane of black flame, scars from fighting gods visible across the snout. Older than the throne. Meaner than its master. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with apocalyptic dragon proportions, dark fantasy cartoon, dark humor. Obsidian and hellfire. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-apocalypse-dragon-full` — Полная фигура

A full-body view of the Apocalypse Dragon coiled around the throne room's central pillar, wings spread, breathing a torrent of black hellfire. An enormous dragon of cracked obsidian and hellfire, massive wings of black leathery membrane, a serpentine body coiled around the pillar, a tail that smashes through walls, breathing black flame that erases rather than burns, the floor melting in its presence. The last thing most heroes see. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Obsidian and black hellfire. Thick hand-drawn outlines. Apocalyptic fury pose. Warm cream parchment background.

---

## Boss 10/10 — Malachar the Undying (Lv.100) ★ ФИНАЛЬНЫЙ БОСС ИГРЫ

### `boss-malachar-the-undying-portrait` — Портрет

A portrait bust of Malachar the Undying — the Demon King, Lord of the Infernal Throne, the final boss of Hexbound, head and shoulders, 3/4 view. A regal demonic face of terrible beauty and ancient power — angular features neither fully human nor fully demonic, skin of deep crimson with veins of molten gold, eyes that are two different colors — one burning gold (ambition) and one cold void-purple (death), a crown of black iron and eternal flame fused to the skull, a thin cruel smile that has seen empires rise and fall, elaborate demon-king armor of black iron and gold inlay at the shoulders, a high collar of screaming soul-faces. He is not just a demon king. He is THE demon king. The reason heroes exist. The reason most of them don't come back. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature with supreme demonic regal proportions, dark fantasy cartoon, dark humor. Crimson, black iron, molten gold, void-purple eye. Thick hand-drawn outlines. Warm cream parchment background.

### `boss-malachar-the-undying-full` — Полная фигура

A full-body view of Malachar the Undying standing before his Infernal Throne, arms wide in a gesture of "welcome to your doom." A tall regal demon in black iron and gold armor, crimson skin, a crown of eternal flame, massive black-feathered wings (not bat wings — fallen angel wings, burned black), one hand holding a scepter of black iron topped with a screaming golden skull, the other hand open and inviting — daring you to try, a cape of living shadows flowing behind, the throne of bones and iron behind him, lesser demons and the Apocalypse Dragon visible in the background kneeling, lava rivers framing the scene, the floor a mosaic of defeated heroes' shields. He has been waiting. He has been waiting specifically for YOU. And he is not impressed. Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon, dark humor. Crimson, black, and imperial gold. Thick hand-drawn outlines. "Welcome to hell" throne pose. Warm cream parchment background.

---

# SUMMARY

| Dungeon | Cover | Background | Boss Portraits | Boss Full Body | Total |
|---|---|---|---|---|---|
| Volcanic Forge | 1 | 1 | 10 | 10 | 22 |
| Fungal Grotto | 1 | 1 | 10 | 10 | 22 |
| Scorched Mines | 1 | 1 | 10 | 10 | 22 |
| Frozen Abyss | 1 | 1 | 10 | 10 | 22 |
| Realm of Light | 1 | 1 | 10 | 10 | 22 |
| Shadow Depths | 1 | 1 | 10 | 10 | 22 |
| Clockwork Citadel | 1 | 1 | 10 | 10 | 22 |
| Infernal Throne | 1 | 1 | 10 | 10 | 22 |
| **TOTAL** | **8** | **8** | **80** | **80** | **176** |

### Boss Names (for backend `DUNGEON_BOSSES` implementation)

**Volcanic Forge** (already in backend): Lava Crawler, Ember Sprite, Slag Brute, Flame Hound, Molten Shaman, Obsidian Knight, Furnace Worm, Cinderlord, Magma Titan, Pyrox the Eternal

**Fungal Grotto** (proposed): Spore Puffball, Mycelium Crawler, Toxic Shroom Knight, Rot Toad, Fungal Witch, Phosglow Stalker, Cordyceps Puppet, Swamp Lurker, Blight Colossus, Sporoth the Undying

**Scorched Mines** (proposed): Coal Mite, Pickaxe Wraith, Ember Rat Swarm, Mine Shaft Horror, Soot Golem, Dynamite Goblin, Magma Centipede, Minecart Fiend, Slag Overlord, Cinder Baron Kael

**Frozen Abyss** (proposed): Ice Wisp, Frost Grub, Glacial Skeleton, Snow Hag, Frozen Knight, Blizzard Wolf, Crystal Lurker, Permafrost Giant, Avalanche Wyrm, Cryoth the Icebound

**Realm of Light** (proposed): Radiant Moth, Light Scarab, Blinding Sentinel, Solar Monk, Gilded Automaton, Searing Angel, Prism Golem, Halo Wraith, Dawn Colossus, Lucirath the Unblinking

**Shadow Depths** (proposed): Void Maggot, Shade Crawler, Dusk Phantom, Abyssal Leech, Nightmare Stalker, Shadow Weaver, Darkness Elemental, Eclipse Knight, Void Colossus, Nyxrath the Devourer

**Clockwork Citadel** (proposed): Rust Tick, Gear Sprite, Steam Sentry, Copper Hound, Piston Knight, Gear Mage, Boiler Horror, Cog Centipede, Iron Titan, Machinator Prime

**Infernal Throne** (proposed): Hellfire Imp, Ash Crawler, Brimstone Brute, Demon Hound, Infernal Priestess, Hellforged Golem, Pit Fiend, Doom Knight, Apocalypse Dragon, Malachar the Undying
