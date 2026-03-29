# Hexbound Landing Page — Art Generation Prompts

> **Стиль**: Caricature grotesque fantasy cartoon. Thick black outlines, watercolor shading, strong contrast, rich colors. Grimdark dark humor. **Характеры ugly-funny — repulsive yet humorous**: asymmetrical features, exaggerated proportions, visible warts/scars/grime. Основа — загруженные reference images (orc warrior + goblin mage).
>
> **Генератор**: ChatGPT (DALL-E) с uploaded reference images
>
> **Workflow**: Для каждого промта — загрузить 1-2 reference image из Hexbound, вставить промт, скачать результат, удалить фон (если нужен transparent), сжать в WebP.

---

## Базовый шаблон (копировать и менять блок `change appearance details`)

```
use the uploaded image as base reference for character style and proportions,
single [CHARACTER TYPE] character,

change appearance details:
[ДЕТАЛИ ВНЕШНОСТИ],

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,

one character only,
[FORMAT],
[ASPECT RATIO],
plain background
```

---

## 1. HERO CHARACTER (главный арт на первом экране)

**Файл**: `hero-character.png`
**Размер**: 1024×1536 (2:3 portrait) → обрезать/масштабить на сайте
**Фон**: прозрачный (удалить plain background)

```
use the uploaded image as base reference for character style and proportions,
single human male warrior character,

change appearance details:
full body standing pose facing slightly left,
towering muscular dark knight,
heavy black iron plate armor with skull-shaped pauldrons,
tattered crimson cape flowing behind,
massive two-handed greatsword resting on shoulder,
scarred face with glowing amber eyes,
short cropped dark hair with grey streaks,
grim determined expression with slight scowl,
heavy boots with metal shin guards,
belt with hanging skulls and chain links,
battle-worn scratched dented armor,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
visible scars, grime, battle damage on skin,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
muted earth tones with crimson and gold accents,

one character only,
full body,
2:3 portrait orientation,
plain white background
```

---

## 2. CLASS CHARACTERS (для интерактивных табов)

### 2a. Warrior
**Файл**: `class-warrior.png`
**Размер**: 1024×1536 (2:3)

```
use the uploaded image as base reference for character style and proportions,
single human male warrior character,

change appearance details:
full body aggressive battle stance,
bulky muscular brute with thick neck,
heavy iron chainmail with metal plates on shoulders,
large round shield with dented surface and claw marks,
one-handed battle axe raised overhead,
wild messy red hair and thick braided beard,
battle rage expression with teeth bared,
scarred arms and face,
leather belt with potion vials,
heavy fur-lined boots,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
visible scars, warts, grime and dirty details,
drool and sweat from battle rage,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
earth tones with deep red accents,

one character only,
full body,
2:3 portrait orientation,
plain white background
```

### 2b. Rogue
**Файл**: `class-rogue.png`
**Размер**: 1024×1536 (2:3)

```
use the uploaded image as base reference for character style and proportions,
single character,

change appearance details:
full body crouching sneaky pose,
lean wiry female rogue assassin,
dark hooded leather armor with many buckles and straps,
two curved daggers held in reverse grip,
hood pulled low over face showing only sharp chin and smirk,
dark violet eyes visible under hood,
bandolier of throwing knives across chest,
wrapped cloth around forearms and ankles,
tattered dark cloak with torn edges,
pouch of lockpicks on belt,
lean and agile body proportions,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
visible scars, grime and dirty details,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
dark tones with purple and shadow accents,

one character only,
full body,
2:3 portrait orientation,
plain white background
```

### 2c. Mage
**Файл**: `class-mage.png`
**Размер**: 1024×1536 (2:3)

```
use the uploaded image as base reference for character style and proportions,
single character,

change appearance details:
full body casting spell pose with one hand raised,
old gaunt skeletal male sorcerer,
long tattered dark robes with arcane symbols stitched in gold thread,
tall crooked pointed hat with patches and holes,
long wispy white beard reaching waist,
one eye larger than the other with crazed expression,
gnarled wooden staff with skull on top in other hand,
bony fingers with oversized knuckles,
ancient tome chained to belt,
bare feet with long toenails,
hunched posture,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
visible warts, age spots, grime and arcane stains,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
dark robes with purple and teal magic accents,

one character only,
full body,
2:3 portrait orientation,
plain white background
```

### 2d. Tank
**Файл**: `class-tank.png`
**Размер**: 1024×1536 (2:3)

```
use the uploaded image as base reference for character style and proportions,
single character,

change appearance details:
full body defensive stance with shield forward,
enormous stocky dwarf-proportioned tank,
massive full plate armor covering entire body,
tower shield nearly as tall as character,
small war hammer in other hand,
helmet with narrow eye slit showing two beady eyes,
impossibly thick armor plates with rivets everywhere,
scratched dented battered but unbroken armor,
short stubby legs in heavy greaves,
chain skirt under plate armor,
immovable fortress personality,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
beady eyes barely visible through helmet slit, stubby and comically immovable,
visible rust stains, dents, grime on skin and armor,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
iron grey and bronze tones with gold accents,

one character only,
full body,
2:3 portrait orientation,
plain white background
```

---

## 3. ORIGIN PORTRAITS (5 рас — для секции Origins)

### 3a. Human
**Файл**: `origin-human.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded image as base reference for character style and proportions,
single human male character,

change appearance details:
portrait bust from chest up,
weathered middle-aged human soldier,
short brown hair with receding hairline,
thick bushy eyebrows over tired cynical eyes,
strong square jaw with stubble,
scar across bridge of nose,
worn leather collar and chainmail visible at shoulders,
determined but weary expression,
average proportions not heroic,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
visible scars, stubble, tired cynical expression with drooping eyes,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,

one character only,
portrait,
1:1,
plain background
```

### 3b. Orc
**Файл**: `origin-orc.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded image as base reference for character style and proportions,
single orc male character,

change appearance details:
portrait bust from chest up,
massive green-skinned orc berserker,
messy tangled black hair sticking in all directions,
wild wide eyes with manic aggressive grin,
huge lower jaw with two prominent tusks,
flat broad nose with nostrils flaring,
thick neck wider than head,
crude spiked metal pauldron on one shoulder,
tribal war paint red stripes on cheeks,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
bulging asymmetrical eyes, drool, warts on skin, feral manic grin,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,

one character only,
portrait,
1:1,
plain background
```

### 3c. Skeleton
**Файл**: `origin-skeleton.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded image as base reference for character style and proportions,
single undead skeleton character,

change appearance details:
portrait bust from chest up,
animated skeleton warrior with glowing purple eyes in empty sockets,
cracked yellowed skull with missing teeth,
rusted iron helmet slightly too large sitting crooked on skull,
tattered remains of a noble cloak around neck bones,
exposed ribcage visible below collar,
jawbone hanging slightly loose on one side,
faint purple magical glow in eye sockets and between bones,
cobwebs in helmet crevices,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
lopsided grin, cracked jaw, cobwebs in eye sockets, comically decrepit,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
bone-white and iron-grey with purple magic accents,

one character only,
portrait,
1:1,
plain background
```

### 3d. Demon
**Файл**: `origin-demon.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded image as base reference for character style and proportions,
single demon character,

change appearance details:
portrait bust from chest up,
sinister crimson-skinned demon with curved ram horns,
narrow slitted golden eyes with vertical pupils,
sharp angular face with high cheekbones,
thin cruel smile showing pointed teeth,
two large curved horns sweeping back from forehead,
dark cracks in skin glowing faint orange like magma beneath,
small pointed goatee beard,
spiked obsidian collar around neck,
smoke wisps rising from skin,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
thin cruel smirk, one eyebrow raised higher than other, sulfur smoke from nostrils,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
crimson skin with orange fire and obsidian black accents,

one character only,
portrait,
1:1,
plain background
```

### 3e. Dogfolk
**Файл**: `origin-dogfolk.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded image as base reference for character style and proportions,
single beast-kin dogfolk character,

change appearance details:
portrait bust from chest up,
anthropomorphic wolf-headed warrior with fur,
thick grey and brown fur covering face and neck,
pointed tall ears one torn and scarred,
long canine snout with visible fangs,
intelligent amber eyes with fierce loyal expression,
leather straps and buckles around neck and shoulders,
bone necklace with animal teeth,
wild mane of longer fur around neck like a lion,
one ear folded back alertly,

caricature grotesque fantasy cartoon style,
exaggerated proportions and asymmetrical features,
ugly-funny — repulsive yet humorous,
one torn ear folded, lolling tongue, wild asymmetrical eyes, scruffy matted fur,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
grey-brown fur tones with leather and bone accents,

one character only,
portrait,
1:1,
plain background
```

---

## 4. DUNGEON CARDS (4 подземелья — вертикальные карточки)

### 4a. The Catacombs
**Файл**: `dungeon-catacombs.png`
**Размер**: 1024×1365 (3:4)

```
use the uploaded image as base reference for art style only,

single environment scene,
underground catacombs entrance,
stone archway carved with skulls and bones,
crumbling ancient stairs descending into darkness,
scattered bones and broken coffins,
green moss and cobwebs on walls,
single flickering torch casting harsh shadows,
rats on the floor,
cracked stone walls with skeletal hands reaching out,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
grey stone and bone-white with sickly green accents,

single scene,
3:4 portrait orientation,
no text
```

### 4b. Frozen Abyss
**Файл**: `dungeon-frozen.png`
**Размер**: 1024×1365 (3:4)

```
use the uploaded image as base reference for art style only,

single environment scene,
frozen ice cavern entrance,
massive ice stalactites and stalagmites,
frozen warrior skeleton trapped in translucent ice wall,
frost crystals covering everything,
cold blue light emanating from deep within,
cracked ice floor with dark water underneath,
icicles dripping from stone archway,
frozen chains hanging from ceiling,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
ice blue and frost white with dark stone accents,

single scene,
3:4 portrait orientation,
no text
```

### 4c. Volcanic Forge
**Файл**: `dungeon-volcanic.png`
**Размер**: 1024×1365 (3:4)

```
use the uploaded image as base reference for art style only,

single environment scene,
volcanic forge entrance in a cave,
rivers of molten lava flowing between stone platforms,
massive rusted iron anvil with glowing metal,
heat distortion and ember particles,
chains and gears hanging from rocky ceiling,
crude iron gates with skull motifs,
charred bones scattered on ground,
cracked obsidian walls with orange glow,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
dark stone and iron with orange-red lava accents,

single scene,
3:4 portrait orientation,
no text
```

### 4d. Infernal Throne
**Файл**: `dungeon-infernal.png`
**Размер**: 1024×1365 (3:4)

```
use the uploaded image as base reference for art style only,

single environment scene,
demonic throne room entrance,
massive obsidian double doors cracked open,
carved demon faces on door panels,
crimson carpet stained and torn leading into darkness,
floating candles with purple flames,
twisted black iron columns with thorns,
pentagram etched into stone floor,
dark smoke rising from cracks,
ominous red glow from beyond the doors,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
obsidian black and dark purple with crimson accents,

single scene,
3:4 portrait orientation,
no text
```

---

## 5. BOSS CHARACTERS (5 боссов — квадратные)

> Боссов можно пере-генерировать крупнее из текущих 256×256. Загрузить текущий спрайт как reference + стилевой reference.

### 5a. Skeleton Knight
**Файл**: `boss-skeleton-knight.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded images as base reference for character style and proportions,
single undead skeleton knight character,

change appearance details:
full body menacing battle pose,
towering skeleton in heavy corroded plate armor,
glowing purple eyes in skull sockets,
massive rusted greatsword held in both bone hands,
tattered purple cape flowing behind,
cracked skull with deep gash across forehead,
armor covered in dents and old battle damage,
one pauldron shaped like a screaming skull,
chains wrapped around arms,
purple magical energy wisping from joints,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
iron grey and bone with purple magic accents,

one character only,
full body,
1:1,
plain white background
```

### 5b. Lich King
**Файл**: `boss-lich-king.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded images as base reference for character style and proportions,
single undead lich king character,

change appearance details:
full body floating slightly above ground,
emaciated skeletal lich in ornate decayed robes,
tall spiked crown of blackened iron on skull,
one hand raised casting purple necromantic spell,
other hand holding ancient gnarled staff with floating skull,
long tattered robes once regal now rotting,
glowing intense purple eyes with trails of magic,
visible ribcage through torn robes,
gold jewelry tarnished and corroded,
swirling purple energy around lower body,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
decayed gold and rotting cloth with intense purple accents,

one character only,
full body,
1:1,
plain white background
```

### 5c. Bone Colossus
**Файл**: `boss-bone-colossus.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded images as base reference for character style and proportions,
single bone construct monster,

change appearance details:
full body towering forward,
massive golem made entirely of fused bones and skulls,
multiple skulls forming the head cluster,
huge bone fists with protruding rib-cage fingers,
spine-chain whip tail,
held together by purple magical sinew and energy,
glowing purple veins running between bone joints,
tiny skulls embedded in shoulder masses,
cracked and ancient yellowed bones,
impossibly large and heavy looking,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
yellowed bone and grey with purple energy accents,

one character only,
full body,
1:1,
plain white background
```

### 5d. Iron Guardian
**Файл**: `boss-iron-guardian.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded images as base reference for character style and proportions,
single iron golem character,

change appearance details:
full body standing guard pose with arms crossed,
massive mechanical iron construct,
riveted plates of dark iron forming body,
glowing golden furnace visible through chest grate,
heavy square head with two glowing amber eye slits,
oversized iron fists with spiked knuckles,
steam venting from shoulder joints,
rust and corrosion patterns on lower body,
ancient dwarven runes etched on chest plate,
chains draped across shoulders,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
dark iron grey with golden-amber furnace glow accents,

one character only,
full body,
1:1,
plain white background
```

### 5e. Banshee
**Файл**: `boss-banshee.png`
**Размер**: 1024×1024 (1:1)

```
use the uploaded images as base reference for character style and proportions,
single ghost banshee character,

change appearance details:
full body floating with wispy lower body fading out,
translucent female ghost with anguished screaming expression,
long wild flowing white hair whipping upward,
hollow dark eye sockets with pale blue light,
mouth open in eternal scream,
tattered remnants of once-fine dress clinging to form,
bony hands with long sharp fingers reaching forward,
pale blue-white translucent skin,
wisps of ectoplasm trailing from body,
frost forming on surfaces near her,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
pale ghost-white and ice-blue with dark void accents,

one character only,
full body,
1:1,
plain white background
```

---

## 6. FEATURE ICONS (для секции Game Systems)

> Иконки зданий 300×300 уже ОК по размеру, но стиль casual. Можно пере-генерировать в гротескном стиле или оставить как есть (они мелкие на сайте, 72×72px). **Низкий приоритет.**

### Если решим перегенерировать:

**Размер**: 512×512 (1:1) каждый

```
use the uploaded image as base reference for art style only,

single building icon,
[ОПИСАНИЕ — см. ниже],
isolated object,
no characters,

caricature grotesque fantasy cartoon style,
thick black outlines,
watercolor shading,
rich colors,

single object,
1:1,
plain white background
```

Описания:
- **Arena**: `stone colosseum arena with iron gates, skull banners, blood stains on sand`
- **Dungeon**: `dark cave entrance with iron portcullis, skulls on stakes flanking doorway`
- **Shop**: `crooked medieval merchant stall with hanging weapons and potions`
- **Battle Pass**: `ornate scroll with wax seal and golden ribbon, fantasy reward document`
- **Gold Mine**: `cave entrance with mining cart full of gold nuggets, wooden support beams`
- **Tavern**: `crooked medieval tavern building with creaking sign, smoke from chimney`

---

## 7. OG IMAGE (для соцсетей)

**Файл**: `og-image.jpg`
**Размер**: 1200×630 (≈1.9:1)
**Формат**: JPG (не нужен transparent)

```
use the uploaded image as base reference for art style only,

group composition with hexbound game logo in center,
four fantasy characters standing in a row:
left to right: armored warrior with axe, hooded rogue with daggers, robed mage with staff, heavy tank with shield,
dark moody background with subtle stone texture,
gold decorative border frame around edges,
space for text overlay at top,

caricature grotesque fantasy cartoon style,
dark humor,
thick black outlines,
watercolor shading,
strong contrast,
rich colors,
dark background with gold accents,

group portrait,
landscape 1.9:1 ratio,
dark textured background
```

> **Примечание**: Логотип добавляется поверх в Figma/Photoshop, не генерировать текст в DALL-E.

---

## 8. HERO BACKGROUND (фоновое изображение)

**Файл**: `hero-bg.webp`
**Размер**: 1920×1080
**Формат**: WebP (сжать до ~200KB, dark, размытый — это фон)

> **Можно оставить текущий** `bg-hub.jpg` но сжать. Или сгенерировать новый:

```
dark fantasy landscape,
distant ruined castle on a hill against stormy sky,
dead twisted trees in foreground,
cracked barren ground,
ominous purple-tinged storm clouds,
very dark overall with minimal lighting,
muted desaturated colors,
atmospheric and moody,

digital matte painting style,
1920x1080 landscape,
very dark tones suitable for text overlay
```

> **Примечание**: Фон НЕ в гротескном стиле — он должен быть тёмным и размытым, чтобы не конфликтовать с контентом поверх.

---

## Порядок генерации (приоритет)

| # | Ассет | Кол-во | Приоритет | Влияние |
|---|---|---|---|---|
| 1 | Hero character | 1 | 🔴 Высший | Первое что видит посетитель |
| 2 | 4 класса (full body) | 4 | 🔴 Высший | Интерактивная витрина |
| 3 | 5 origin портретов | 5 | 🟡 Высокий | Секция рас |
| 4 | OG image | 1 | 🟡 Высокий | Шеринг в соцсетях |
| 5 | 4 dungeon cards | 4 | 🟡 Высокий | Секция подземелий (128px → 1024px) |
| 6 | 5 боссов (увеличение) | 5 | 🟠 Средний | Preview в dungeons |
| 7 | Hero background | 1 | 🟠 Средний | Можно пока оставить текущий |
| 8 | 6 feature icons | 6 | 🟢 Низкий | Мелкие, текущие ОК |
| **Итого** | | **27 изображений** | | |

---

## Post-Processing Pipeline

1. **Генерация** → DALL-E / ChatGPT с reference image
2. **Удаление фона** → remove.bg или rembg (Python) для персонажей
3. **Resize** → ImageMagick: `convert input.png -resize 1024x1536 output.png`
4. **Конверсия в WebP** → `cwebp -q 85 input.png -o output.webp`
5. **PNG fallback** → `pngquant --quality=70-90 input.png`
6. **Оптимизация** → target <150KB для персонажей, <200KB для фонов

```bash
# Пример batch конверсии
for f in assets/*.png; do
  cwebp -q 85 "$f" -o "${f%.png}.webp"
done
```
