# Achievement badges + item / loot icons — prompts (2026-10-14)

Все ассеты — в семействе **pen-and-ink rulebook** из `ART_STYLE_GUIDE.md` (шаблон-библия дословно, фиксированное освещение, плоский ключ). Модель `nano_banana_2_1`, 1:1, 2k, thinking medium.

## Пайплайн

- Ключ: зелёный `#00FF00` по умолчанию; маджента `#FF00FF` там, где в самом предмете есть зелёный (яд, листья, чешуя).
- Ingest: `scripts/ingest_generated_sprite.py <raw> <name> --key <hex> --pt <pt>` — ачивки `--pt 96` → `Assets.xcassets/Achievements/`, предметы и лут `--pt 128` → `Assets.xcassets/Items/`, узлы раша `--pt 86` → корень.
- Golden anchors (Higgsfield job id, прикладывается как image_reference ко всем вызовам класса):
  - медали ачивок: `achievement-pvp-wins-10` = `b0b76198-dfda-44a3-b22b-3866e6f6e065`; гербы рангов: `achievement-rank-grandmaster` = `b20dabec-0d53-4d19-a3dd-d05e17a44070`
  - оружие: `wpn_soulreaver` = `0c72abb7-2329-453d-bb4f-8247e71e0efc`; броня/бижутерия/прочее: `chest_godplate` = `1c5bda93-1f54-4c55-9261-c03d3d8fe087`
- Префикс при якоре: *"Image 1 is the STYLE ANCHOR from the same … set: match its pen-and-ink linework, outline weight, lighting … exactly; …"*

## Шаблон (предмет)

```
Pen and ink illustration of {SUBJECT}, bold black ink outlines on every element, colored with {BASE TONES} and {ACCENT} accents, weathered, scratched and worn surfaces, a single game inventory item icon, big clear shapes that read at small icon size, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat bright green background, centred with margin, the item filling about 80% of the frame, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters, numbers or logos, no particles. The ENTIRE background is one flat, uniform, solid bright green colour (#00FF00) edge to edge, no pattern, no stripes, no frame, no border.
```

## Ачивки (18) — `achievement-<key>`

| asset | Ачивка | Эмблема |
|---|---|---|
| `achievement-pvp-first-blood` | First Blood | a single notched short sword pointing down with one fat drop of blood falling from its tip |
| `achievement-pvp-wins-10` | 10 Victories | two crossed short swords behind a small round buckler |
| `achievement-pvp-wins-50` | 50 Victories | two crossed longswords behind a kite shield with a skull boss |
| `achievement-pvp-wins-100` | Centurion | a crested gladiator helmet with a red horsehair plume above two crossed swords |
| `achievement-pvp-wins-500` | Warmaster | a horned war helm resting on a pile of three skulls, with two crossed battle axes behind it |
| `achievement-pvp-streak-5` | On Fire | an upright sword whose blade is wrapped in solid painted orange flame shapes |
| `achievement-pvp-streak-10` | Unstoppable | a snorting horned bull skull charging forward with solid painted orange flame shapes behind its horns |
| `achievement-revenge-first` | Sweet Revenge | a curved dagger plunged downward through a cracked skull |
| `achievement-revenge-wins-10` | Nemesis | a hooded skull with red-painted eye sockets and two crossed daggers beneath it |
| `achievement-reach-level-10` | Adventurer | a rolled leather map tied with cord crossed with a wooden walking staff and a small lantern hanging from it |
| `achievement-reach-level-25` | Veteran | a dented, scarred knight helmet framed by a laurel wreath of iron leaves |
| `achievement-reach-level-50` | Legend | a jagged gold crown resting on a laurel wreath, with a small skull set in the crown's front |
| `achievement-first-prestige` | Reborn | a phoenix with spread wings rising from a cracked skull, its feathers painted as solid orange and red flame shapes |
| `achievement-prestige-3` | Thrice Forged | a blacksmith's anvil with a red-hot orange sword blade on it and three small hammers fanned above |
| `achievement-rank-silver` | Silver Rank | a single upright sword and one small five-pointed star above it |
| `achievement-rank-gold` | Gold Rank | a single upright sword under a small crown, with two stars on either side |
| `achievement-rank-diamond` | Diamond Rank | a large faceted ice-blue diamond gem set in claws, with two crossed swords behind it |
| `achievement-rank-grandmaster` | Grandmaster | a crowned skull wearing a jewelled crown, flanked by a pair of spread iron wings, with three violet gems set in the rim |

## Предметы (63) и лут подземелий (27)

| asset | Описание (SUBJECT) | Ключ |
|---|---|---|
| `acc_aegis` | Aegis Shield, a round heater-edged shield of polished bronze with a raised boss shaped like a stern face, layered rim with rivets, shown from the front at a slight 3/4 angle | green |
| `acc_aegis_of_dawn` | Aegis of Dawn, a large tower-kite shield of white steel with a rising sun emblem in gold rays across its face and a gilded rim, shown from the front at a slight 3/4 angle | green |
| `acc_mirror_shield` | Mirror Shield, a kite shield whose face is a single mirror-polished silver plate framed by an ornate gilded rim with small sapphires, shown from the front at a slight 3/4 angle | green |
| `acc_tower_shield` | Obsidian Tower Shield, a tall rectangular tower shield made of chipped black volcanic glass slabs bound with iron bands, shown from the front at a slight 3/4 angle | green |
| `amu_doomward` | Doomward Amulet, a heavy iron amulet on a chain, a round pendant with a carved skull inside a ring of protective iron thorns and a red gem in the skull's brow | green |
| `amu_eye_of_the_ascendant` | Eye of the Ascendant, a gold amulet on a fine chain whose pendant is a single open eye carved from amber in a winged gold setting | green |
| `amu_heart_of_eternity` | Heart of Eternity, a gold amulet on a fine chain holding an anatomical crystal heart in a gilded cage of ribs | green |
| `amu_soulchain` | Soulchain Pendant, a pendant of linked black iron rings holding a small pale-blue soul crystal in a skeletal claw | green |
| `belt_titanbind` | Titanbind, a belt cut from giant iron chain links with a massive broken shackle as its buckle, shown coiled | green |
| `belt_warbrand` | Warbrand Belt, a thick studded leather war belt with a large iron buckle shaped like a branding iron sigil and small throwing knives tucked in loops, shown coiled | green |
| `belt_worldserpent` | Worldserpent Belt, a belt made of dark green serpent scales whose gold buckle is a serpent biting its own tail, shown coiled | magenta |
| `belt_wyrmskin` | Wyrmskin Belt, a girdle of overlapping red-brown dragon scales with a bone buckle carved like a wyrm's head, shown coiled | green |
| `boot_ascendant_treads` | Ascendant Treads, a pair of heavy white-steel sabatons with gold-trimmed shin plates and small wing shapes at the heels | green |
| `boot_eternaltread` | Eternal Treads, a pair of ancient plated boots of weathered bronze with gold filigree and tiny hourglass emblems on the cuffs | green |
| `boot_stormstriders` | Stormstrider Boots, a pair of tall leather boots with steel shin guards engraved with lightning bolt shapes and blue-painted bolt accents | green |
| `boot_wraithstep` | Wraithstep Boots, a pair of dark grey leather boots with tattered grey cloth wrappings trailing from the ankles like ghostly rags | green |
| `chest_ascendant_plate` | Ascendant Plate, a heavy white-steel breastplate dented in many places, with gold-trimmed pauldrons and a winged emblem on the chest, shown from the front with no wearer | green |
| `chest_bloodweave` | Bloodweave Armor, a leather-and-sinew jerkin woven from dark red cords and stitched with bone toggles, shown from the front with no wearer | green |
| `chest_dragonhide` | Dragonhide Cuirass, a cuirass made of overlapping green-bronze dragon scales with a horned collar, shown from the front with no wearer | magenta |
| `chest_spiritweave` | Spiritweave Robe, a hooded silk robe in pale grey with faint ghostly faces woven into the fabric and a rope belt, shown from the front with no wearer | green |
| `glove_ascendant_grips` | Ascendant Grips, a pair of white-steel gauntlets with gold-trimmed knuckle plates and small wing shapes on the cuffs | green |
| `glove_demongrasps` | Demongrasps, a pair of black iron gauntlets with clawed fingertips, horned knuckle plates and red-painted runes on the cuffs | green |
| `glove_irongrip` | Irongrip Gauntlets, a pair of heavy riveted iron gauntlets with thick fingers clenched into a fist and a chain wrapped around the wrist | green |
| `glove_plaguegrip` | Plaguegrip Gloves, a pair of stitched leather gloves stained with dripping green venom and small glass vials strapped to the cuffs | magenta |
| `helm_abyssal_crown` | Abyssal Crown, a jagged black iron crown with tall twisted spikes and a deep violet gem in its front | green |
| `helm_ascendant_crown` | Ascendant Crown, a tall white-steel helm-crown with gold laurel trim and a single white gem on the brow | green |
| `helm_dread_visor` | Dread Visor, a close black iron helmet with a grimacing skull-faced visor and small horns | green |
| `helm_moonveil` | Moonveil Hood, a deep midnight-blue cloth hood with a silver crescent moon clasp and a thin veil hanging over the face opening | green |
| `helm_warskull` | Warskull Helm, a helmet made from the huge horned skull of a beast, with leather straps and an iron nose guard | green |
| `legs_ascendant_greaves` | Ascendant Greaves, a pair of white-steel plated leg greaves with gold-trimmed knee cops and winged emblems | green |
| `legs_boneguard` | Boneguard Greaves, a pair of leg armour greaves reinforced with strapped monster bones and rib plates over dark leather | green |
| `legs_nightstalker` | Nightstalker Leggings, a pair of dark leather trousers with padded knee guards and buckled straps, laid flat with no wearer | green |
| `legs_voidwalker` | Voidwalker Greaves, a pair of dark steel leg plates with violet starry void panels set into the thighs and gold trim | green |
| `loot-arcane-scroll` | Arcane Scroll, a rolled parchment scroll tied with a blue ribbon and sealed with a blue wax seal stamped with an arcane sigil | green |
| `loot-bone-armor` | Bone Armor, a cuirass built from a ribcage of bones lashed over dark leather, shown from the front with no wearer | green |
| `loot-bone-shield` | Bone Shield, a round shield made of lashed bones around a skull boss, shown from the front at a slight 3/4 angle | green |
| `loot-cinder-mail` | Cinder Mail, a chainmail shirt of blackened iron rings with ember-orange heated links scattered through it, shown from the front with no wearer | green |
| `loot-crypt-sword` | Crypt Sword, an old tarnished arming sword with a cobwebbed crossguard and a small skull pommel, shown diagonally | magenta |
| `loot-death-thread` | Death Thread, a small spool of black thread with a bone needle stuck in it, a few loose strands curling off | green |
| `loot-ember-rune` | Ember Rune, a palm-sized flat stone tablet carved with a single fire rune filled with ember-orange paint | green |
| `loot-fire-scroll` | Fire Scroll, a rolled parchment scroll with scorched edges tied with a red cord and sealed with red wax | green |
| `loot-ghoul-hide` | Ghoul Hide, a stitched vest of grey-green ghoul hide with crude bone toggles, shown from the front with no wearer | magenta |
| `loot-hound-fang` | Hound Fang, a short curved dagger whose blade is a huge hellhound fang set into a bone handle wrapped in leather, shown diagonally | green |
| `loot-iron-plate` | Iron Plate, a plain heavy iron breastplate with rivets and leather straps, shown from the front with no wearer | green |
| `loot-knights-edge` | Knight's Edge, a straight knightly longsword with a cross-shaped guard and a blue leather grip, shown diagonally | green |
| `loot-lava-scroll` | Lava Burst Scroll, a rolled parchment scroll with a molten-orange wax seal and charred cracked edges | green |
| `loot-lich-scythe` | Lich Scythe, a tall war scythe with a long curved black blade, a bone-segment haft and a skull with violet eye gems at the joint, shown diagonally | green |
| `loot-mage-wand` | Mage Wand, a short carved wooden wand with a brass tip holding a small blue crystal, shown diagonally | green |
| `loot-magma-core` | Magma Core, a fist-sized round rock cracked open with bright molten orange core showing through the cracks | green |
| `loot-necrotic-tome` | Necrotic Tome, a heavy book bound in stitched grey skin with a skull clasp and iron corners, shown closed at a slight 3/4 angle | green |
| `loot-obsidian-blade` | Obsidian Blade, a jagged sword chipped from a single shard of black volcanic glass with a bound leather hilt, shown diagonally | green |
| `loot-plague-elixir` | Plague Elixir, a bulbous corked glass flask filled with bubbling sickly green liquid with a small skull tag tied to its neck | magenta |
| `loot-pyrox-greatsword` | Pyrox Greatsword, a massive two-handed greatsword with a jagged black blade split by a molten orange core and a horned dragon-skull crossguard, shown diagonally | green |
| `loot-shadow-dagger` | Shadow Dagger, a slim curved dagger with a black blade and a violet-wrapped grip, shown diagonally | green |
| `loot-slag-plate` | Slag Plate, a crude breastplate hammered from lumpy grey-orange slag metal with uneven rivets, shown from the front with no wearer | green |
| `loot-titan-hammer` | Titan Hammer, a heavy two-handed war hammer with a square bronze-banded iron head and a long haft, shown diagonally | green |
| `loot-venom-vial` | Venom Vial, a small slender glass vial of bright green venom with a wax-sealed cork and a snake fang hanging from a string | magenta |
| `loot-wail-scroll` | Wail Scroll, a rolled pale parchment scroll tied with a grey ribbon and sealed with ghostly pale-blue wax pressed with a screaming face | green |
| `loot-wardens-blade` | Warden's Blade, a broad heavy sword with a wide guard shaped like a closed gate and a bronze pommel, shown diagonally | green |
| `loot-wraith-blade` | Wraith Blade, a long thin ghostly pale sword whose blade fades into tattered translucent edges, with a black iron hilt, shown diagonally | green |
| `neck_bloodstone` | Bloodstone Pendant, a dark iron pendant on a leather cord holding a large blood-red stone with dark veins | green |
| `neck_dreadstone` | Dreadstone Collar, a stiff collar necklace of black iron plates with a cold grey stone set at the front, frost painted on its edges | green |
| `neck_soulbinder` | Soulbinder Chain, a heavy silver chain necklace with a pendant of three interlocking rings around a pale soul gem | green |
| `neck_starbound_chain` | Starbound Chain, a fine gold chain necklace with small star-shaped links and a dark blue sapphire pendant flecked with tiny painted stars | green |
| `relic_crown_of_ashes` | Crown of Ashes, a charred, cracked crown of blackened gold crumbling into flakes of ash at its points, with ember-orange cracks | green |
| `relic_demon_eye` | Demon Eye, a large demonic eyeball with a slit yellow pupil set in a clawed bronze setting | green |
| `relic_heart_of_the_void` | Heart of the Void, a dark violet crystalline heart split open in the middle with a black starry void inside, bound by thin iron bands | green |
| `relic_warhorn` | Warhorn of the Fallen, a curved war horn carved from a giant beast horn, bound with iron rings and hung with a tattered red pennant | green |
| `ring_eclipse` | Eclipse Band, a thick black iron ring holding a dark round stone with a thin gold crescent edge like a solar eclipse | green |
| `ring_oblivion` | Ring of Oblivion, a twisted dark silver ring holding a black gem that seems to swallow light, with tiny cracks radiating from it | green |
| `ring_shadowfang` | Shadowfang Ring, a dark iron ring with a curved black wolf fang set across its band | green |
| `ring_singularity` | Ring of Singularity, a gold ring whose bezel is a tiny swirling dark-violet spiral held by four claws | green |
| `wpn_ascendant_blade` | Ascendant Blade, a broad white-steel greatsword with gold-trimmed fuller and a winged crossguard, shown diagonally | green |
| `wpn_ascendant_bulwark` | Ascendant Bulwark, a weapon that is half hammer and half shield: a white-steel hammer head with a tall shield plate along the haft, gold trimmed, shown diagonally | green |
| `wpn_ascendant_edge` | Ascendant Edge, a slender white-steel rapier-dagger with a gold winged guard, shown diagonally | green |
| `wpn_ascendant_staff` | Ascendant Staff, a tall white-wood mage staff topped with a gold winged ring holding a white crystal orb, shown diagonally | green |
| `wpn_astral_codex` | Astral Codex, a thick spellbook bound in midnight-blue leather with gold corner guards, a gold star chart on its cover and a clasp shaped like a crescent moon, shown closed at a slight 3/4 angle | green |
| `wpn_bonecleaver` | Bonecleaver, a huge single-edged cleaver axe with a chipped iron blade and a handle wrapped in bone segments, shown diagonally | green |
| `wpn_colossus_maul` | Colossus Maul, a gigantic square iron maul head bound with bronze bands on a thick wooden haft, shown diagonally | green |
| `wpn_crystalcore_staff` | Crystalcore Staff, a gnarled dark wood staff whose head clutches a large faceted blue mana crystal in wooden roots, shown diagonally | green |
| `wpn_dawnbreaker` | Dawnbreaker, a radiant longsword with a pale steel blade, a gold sunburst crossguard and a white gem pommel, shown diagonally | green |
| `wpn_eclipse_fangs` | Eclipse Fangs, a pair of curved black daggers crossed in an X, each with a gold crescent-moon guard | green |
| `wpn_fey_bow` | Feywisp Bow, a curved longbow carved from pale living wood with tiny leaves sprouting along the limbs and a silver bowstring, shown diagonally | magenta |
| `wpn_hellfire_blade` | Hellfire Blade, a broad longsword with a black blade whose edges are cracked with orange molten veins and a horned crossguard, shown diagonally | green |
| `wpn_nightmare_staff` | Nightmare Staff, a twisted black staff topped with a screaming skull wrapped in thorny branches, shown diagonally | green |
| `wpn_serrated_cleaver` | Serrated Cleaver, a heavy iron cleaver with a saw-toothed edge and a wrapped leather grip, shown diagonally | green |
| `wpn_starfall_codex` | Starfall Codex, an open spellbook whose pages show painted falling stars, bound in black leather with silver corner guards, shown at a slight 3/4 angle | green |
| `wpn_worldbreaker` | Worldbreaker, a colossal two-handed warhammer whose stone-and-iron head is cracked with bright orange painted fault lines, shown diagonally | green |
| `wpn_soulreaver` | (якорь) Soulreaver, legendary two-handed greatsword, black-steel blade with screaming faces, bone-horn crossguard, skull pommel, violet soul gem | green |
| `chest_godplate` | (якорь) Godplate Armor, heavy plate cuirass, sunburst on chest, gilded trim, white gem at collar | green |

## Узлы Dungeon Rush

- `rush-node-treasure` — закрытый сундук с замком и монетами; `rush-node-shop` — кошель + весы торговца. Якорь — `wpn_soulreaver`.

## Брак

- `rank_gold` — 1 failed (таймаут), повтор прошёл.
- `boot_wraithstep` — ложный NSFW, переписан («dark grey leather boots with tattered cloth wrappings»).
- Перестраховка до генерации: `legs_nightstalker` («tight leggings» → «dark leather trousers … laid flat»), `wraith blade` (без «translucent»).
- `loot-rusty-blade` не генерировался — маппится на существующий `wpn_rusty_sword`.
