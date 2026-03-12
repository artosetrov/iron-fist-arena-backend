# Hexbound — Hub City (промпты для Nano Banana Pro)

Подход: **слоёная карта**. Фон (terrain) генерируется отдельно, каждое здание — отдельный спрайт на прозрачном/чёрном фоне. В коде здания накладываются поверх фона. Это даёт контроль над позиционированием, анимацией и адаптивностью.

Стиль — ink crosshatching, гротескный dark fantasy.

---

## Здания-локации:

| Кнопка | Здание-спрайт |
|--------|---------------|
| ARENA | Гексагональный колизей (самый большой) |
| DUNGEON | Вход в пещеру с решёткой |
| TAVERN | Кривая деревянная таверна |
| SHOP | Лавка торговца с навесом |
| RANKS | Каменная башня с флагами |
| BATTLE PASS | Мистический шатёр |
| ACHIEVEMENTS | Зал трофеев с колоннами |

---

## 1. ФОН — terrain без зданий (широкая панорама 21:9)

```
Create a very wide horizontal panoramic background illustration for a dark fantasy mobile RPG town map. This is ONLY the terrain and environment — NO buildings, NO structures, NO tents, NO towers anywhere in the image. Just the empty landscape that buildings will be placed on top of later.

The scene is a dark rocky valley at night, viewed from a tilted bird's-eye perspective (like Hustle Castle town map angle). Aspect ratio 21:9, very wide panoramic.

THE TERRAIN from left to right:

FAR LEFT: A massive dark stone fortress wall stretches vertically across the left edge with a heavy gatehouse and iron portcullis in the center, flanked by two round guard towers with burning torches. A rickety wooden bridge crosses a dark moat in front of the gate. The wall is crumbling with cracks, moss, and old bloodstains. Iron chains and a hanging cage on the wall. Beyond the bridge — pure darkness.

The rest of the panorama (left to right): Dark rocky terrain with winding dirt and cobblestone paths branching out from the fortress gate, spreading across the landscape. The main road winds horizontally through the scene. Multiple cleared flat areas along the path where buildings could stand (like building plots — flat packed earth clearings of various sizes). The terrain between paths is dark brown-gray rocky earth with dead yellowed grass patches, exposed boulders, cracked tombstones, muddy puddles reflecting torchlight.

ATMOSPHERIC DETAILS scattered everywhere: flickering iron lanterns and torches on wooden posts lining all the paths, dead twisted leafless trees with gnarled branches, rusty iron fences and broken wooden barriers, scattered human skulls and bones on the ground, cobwebs between fence posts, puddles, old wooden road signs pointing in various directions (no text — just weathered blank signs), stacked supply crates along path edges, broken cart wheels, a dry cracked stone well, tattered wanted posters on posts, rats scurrying, ravens perched on dead tree branches and fence posts, a mangy black cat, faint fog hugging the ground in lower areas, a gibbet with a hanging cage near the fortress.

SKY: Dark night sky across the top. A large pale moon on the upper-right, partially behind wispy clouds, casting cold bluish-white moonlight. Sky darkest on far left, slightly brighter moonlit on the right — subtle left-to-right lighting gradient.

CRITICAL: NO buildings, NO structures, NO houses, NO tents, NO towers anywhere. Only terrain, paths, fences, trees, props, sky. The cleared flat areas along the paths are empty — waiting for buildings to be placed on them later as separate layers.

Art style: detailed hand-drawn ink illustration with crosshatching for ALL shading. Visible pen strokes, cross-hatch texturing. Hand-drawn with ink, colored with muted watercolor washes. NOT clean digital art. Rough, textured, hand-crafted.

Color palette: very muted and dark — deep browns, charcoal grays, dead olive greens, bone whites, black shadows. Golden-orange torchlight provides warm contrast. Cold bluish moonlight on the right side. Dark fantasy medieval manuscript aesthetic.

Far-left and far-right edges fade to pure black. 21:9 aspect ratio, maximum resolution.
```

---

## 2. АРЕНА (отдельный спрайт — самое большое здание)

```
Create a single isolated dark fantasy building illustration on a pure solid black background, viewed from a tilted bird's-eye isometric angle. This building will be placed as a separate layer on top of a game map, so it must sit on pure black with NO ground, NO terrain, NO paths around it — just the building itself floating on black. NO text.

THE ARENA: A massive crumbling hexagonal stone colosseum — the largest and most impressive building in the game. Tall dark stone walls with burning golden-orange torches at each of the six corners casting warm light. Tattered dark banners with faded arcane symbols hang between the torch pillars. The open top reveals the sandy arena floor below with a brightly glowing golden hexagonal magical seal in the center, radiating golden-orange light upward. Rows of crumbling stone seating visible inside. Iron chains dangle from the inner walls. Skulls mounted on spikes above the main entrance arch. The stone is cracked, weathered, covered in old dark stains.

Art style: hand-drawn ink illustration with crosshatching for all shading. Muted dark palette — gray stone, dark iron, with bright golden-orange glow from torches and the hexagonal seal. Dark fantasy medieval manuscript style. Thick dark ink outlines on the entire building silhouette for easy compositing.

Pure solid black background. The building must have clean edges. Square 1:1 aspect ratio, high resolution.
```

---

## 3. ДАНЖЕН (отдельный спрайт)

```
Create a single isolated dark fantasy dungeon entrance illustration on a pure solid black background, viewed from a tilted bird's-eye isometric angle. This will be placed as a separate layer on a game map — NO ground, NO terrain, NO paths. Just the structure on black. NO text.

THE DUNGEON: A dark rocky hillside outcrop with a menacing cave entrance carved into it. A heavy rusted iron portcullis gate partially raised, revealing impenetrable darkness within. Thick sickly green-purple poisonous mist seeps out from the cave mouth and creeps along the base. Rough stone steps descend into blackness. Skull-on-spike warning markers flank the entrance. Ancient crumbling stone pillars frame the cave with faded arcane carvings. Chains with padlocks bolted to the rock walls. A few dying torches with sickly green flames. Claw marks scratched deep into the stone. Cobwebs in the upper corners. A discarded broken shield and scattered bones near the entrance.

Art style: hand-drawn ink illustration with crosshatching. Muted dark palette with eerie green-purple glow from cave, faint sickly torch glow. Medieval manuscript style. Thick dark ink outlines for compositing.

Pure solid black background. Clean edges. Square 1:1, high resolution.
```

---

## 4. ТАВЕРНА (отдельный спрайт)

```
Create a single isolated dark fantasy tavern building illustration on a pure solid black background, viewed from a tilted bird's-eye isometric angle. Separate layer for a game map — NO ground, NO terrain. Just the building on black. NO text.

THE TAVERN: A leaning crooked two-story dark wooden building that looks drunk itself — walls not straight, roof sagging to one side. Messy thatched roof full of holes and patches. A fat stone chimney belches thick dark smoke upward. Warm dim orange-golden light seeps from dirty diamond-pane windows. Heavy oak front door with iron studs, slightly ajar, warm light spilling out. Beer barrels and broken bottles stacked outside. A creaky wooden sign hangs from a rusty chain above the door (no text — just a carved beer mug shape). Outdoor wooden tables and benches, one overturned. A flickering lantern by the door. A rat near the barrels. A pair of muddy boots left outside.

Art style: hand-drawn ink illustration with crosshatching. Muted dark earthy palette — brown wood, gray stone — with warm golden-orange window and lantern glow. Medieval manuscript style. Thick dark ink outlines.

Pure solid black background. Clean edges. Square 1:1, high resolution.
```

---

## 5. МАГАЗИН (отдельный спрайт)

```
Create a single isolated dark fantasy merchant shop illustration on a pure solid black background, viewed from a tilted bird's-eye isometric angle. Separate layer for game map — NO ground, NO terrain. Just the structure on black. NO text.

THE SHOP: A dark crooked open-front wooden market stall and workshop. A tattered patched canvas awning covers the front, held up by rough wooden poles. Wooden display racks showing rusty weapons (swords, axes, daggers), glowing potion bottles (green, red, blue liquids), and battered pieces of armor. A weathered wooden counter with a set of brass scales and scattered gold coins. Behind the counter, messy shelves with mysterious boxes, rolled scrolls, and dusty jars. Wooden crates, barrels, and sacks piled on one side. A small blacksmith forge with dying orange embers glowing in the back. A lantern hanging from the awning pole. A wooden cart with a broken wheel parked beside the stall.

Art style: hand-drawn ink illustration with crosshatching. Muted dark earthy palette with warm golden lantern light and faint forge ember glow. Medieval manuscript style. Thick dark ink outlines.

Pure solid black background. Clean edges. Square 1:1, high resolution.
```

---

## 6. БАШНЯ РАНГОВ (отдельный спрайт)

```
Create a single isolated dark fantasy ranking tower illustration on a pure solid black background, viewed from a tilted bird's-eye isometric angle. Separate layer for game map — NO ground, NO terrain. Just the tower on black. NO text.

RANKS TOWER: A tall narrow dark stone watchtower with a pointed slate roof. The tower rises high, significantly taller than it is wide. Multiple tattered victory banners and heraldic flags in dark red and faded gold flutter from wooden poles at the top, catching the wind. A large ornate golden trophy cup sits at the very peak, glinting faintly in moonlight. The tower wall has a large wooden notice board nailed to it with parchment notices pinned (illegible — just texture and pins). Iron torch brackets hold burning torches on either side of a heavy wooden door at the base. A small tournament shield crest above the door. Crumbling stone steps lead up to the entrance. The stone is dark, weathered, with cracks and moss.

Art style: hand-drawn ink illustration with crosshatching. Muted dark palette — gray stone, dark iron — with golden trophy gleam and warm torch glow. Medieval manuscript style. Thick dark ink outlines.

Pure solid black background. Clean edges. Square 1:1, high resolution.
```

---

## 7. ШАТЁР BATTLE PASS (отдельный спрайт)

```
Create a single isolated dark fantasy mysterious tent illustration on a pure solid black background, viewed from a tilted bird's-eye isometric angle. Separate layer for game map — NO ground, NO terrain. Just the tent on black. NO text.

BATTLE PASS TENT: A mysterious ornate exotic tent or pavilion made of rich layered fabrics in deep dark crimson, purple, and black. Faded golden arcane hexagonal symbols and mystical patterns embroidered on the fabric in golden thread. Tassels and decorative fringe hang from the edges and peak. The tent entrance is draped with beaded curtains that shimmer faintly. A glowing crystal ball on a small ornate table visible just inside, emanating purple-golden magical light. Magical golden sparkles and tiny floating hexagonal rune symbols drift around the tent. A small bronze incense brazier outside with curling smoke. Several mysterious sealed treasure chests with ornate golden padlocks sit near the entrance. The whole tent has an air of mystery and hidden riches.

Art style: hand-drawn ink illustration with crosshatching. Muted dark palette with rich purple-golden magical glow and shimmer. Medieval manuscript style. Thick dark ink outlines.

Pure solid black background. Clean edges. Square 1:1, high resolution.
```

---

## 8. ЗАЛ ДОСТИЖЕНИЙ (отдельный спрайт)

```
Create a single isolated dark fantasy trophy hall and library building illustration on a pure solid black background, viewed from a tilted bird's-eye isometric angle. Separate layer for game map — NO ground, NO terrain. Just the building on black. NO text.

ACHIEVEMENTS HALL: A small but grand dark stone building with classical style. Two dark stone pillars flank the entrance. Heavy ornate wooden double doors with iron ring handles and decorative metalwork. Arched windows glow faintly golden from within — old leather-bound books on shelves and golden trophy silhouettes visible inside. Above the entrance, a carved stone pedestal holds a golden star or medal emblem, glowing softly. The facade has carved stone relief panels showing heroic battle scenes. Small stone gargoyle statues perch on the roof corners. The pointed roof has dark slate tiles. Dead ivy and withered vines creep up one wall. A weathered stone bench near the entrance. The building feels ancient, scholarly, and important.

Art style: hand-drawn ink illustration with crosshatching. Muted dark palette with warm scholarly golden glow from windows. Medieval manuscript style. Thick dark ink outlines.

Pure solid black background. Clean edges. Square 1:1, high resolution.
```

---

## 9. КРЕПОСТНЫЕ ВОРОТА (отдельный спрайт, если нужны отдельно от фона)

```
Create a single isolated dark fantasy fortress gate illustration on a pure solid black background, viewed from a tilted bird's-eye isometric angle. Separate layer for game map. NO text.

FORTRESS GATE: A massive dark crumbling stone gatehouse with a heavy iron portcullis gate, flanked by two round guard towers. Burning torches in iron brackets on both towers cast warm golden-orange light. Tattered dark banners with faded crests hang from the towers. A rickety wooden bridge with rope railings extends forward from the gate, crossing over a dark void (moat). The wall is crumbling with deep cracks, patches of moss, old dark stains. Iron chains, a hanging cage with a skeleton inside, skull decorations mounted on spikes above the gate arch. The portcullis is partially raised, revealing darkness beyond. Heavy wooden doors behind the portcullis, iron-studded. Arrow slits in the tower walls.

Art style: hand-drawn ink illustration with crosshatching. Muted dark palette — gray stone, dark iron, rust — with warm golden torch glow. Medieval manuscript style. Thick dark ink outlines.

Pure solid black background. Clean edges. Aspect ratio 4:3 (wider than tall), high resolution.
```

---

## Советы по реализации

### Генерация
- **Фон (промпт #1)**: генерируй в 21:9, это основной слой
- **Здания (промпты #2-9)**: генерируй каждое в 1:1, убирай чёрный фон (в любом редакторе или programmatically)
- **Консистентность**: генерируй все здания в одной сессии подряд, чтобы стиль не плыл
- **Если стиль между зданиями отличается**: загрузи первое удачное здание как референс для остальных

### В коде (Godot / Next.js)
- Фон = одна широкая текстура, скроллится горизонтально (drag/swipe)
- Каждое здание = отдельный спрайт/компонент поверх фона
- Тап-зона = hitbox совпадает с контуром здания
- **Тап-фидбек**: золотая подсветка контура + scale 1.05 + лёгкий bounce
- **Анимации**: дым из трубы таверны (частицы), мерцание факелов, пульсация свечения арены, блеск трофея, искры у кузницы — каждое здание живёт
- **Персонаж Degon**: анимированный спрайт на дороге, idle-анимация
- **Переход**: при тапе на здание — zoom-in анимация к зданию, потом переход на экран
