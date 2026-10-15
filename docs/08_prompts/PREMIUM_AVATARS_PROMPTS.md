# Premium Avatars — prompts (2026-10-14)

80 премиум-аватаров: по 8 на (раса × пол), по 2 на класс (warrior / rogue / mage / tank).
Класс выражен только в арте — схема `appearance_skins` не менялась. Первый в паре — **epic, 400 гемов**, второй — **legendary, 800 гемов**.

- Модель: `nano_banana_2_1`, 1:1, 2k, thinking medium.
- Референсы (style+race): дефолтный бюст той же расы+пола + дефолт другого пола той же расы.
- Пайплайн: magenta key → `scripts/ingest_generated_sprite.py <raw> <key> --pt 256` → `Assets.xcassets/PremiumAvatars/<key>.imageset` (@1x/@2x/@3x).
- В БД: `image_key = skin_key`, `image_url = NULL` (бандл-first через `CachedAssetImage`). Миграция: `backend/prisma/migrations/20261014_premium_avatars/migration.sql`.

## Шаблон промпта

```
Images 1 and 2 are STYLE AND RACE REFERENCES: match their art style exactly — the same pen-and-ink linework with watercolour wash, the same thick hand-drawn outlines with varying weight, the same grotesque ugly-funny caricature proportions, the same saturated palette and level of detail, and the same race anatomy. Do NOT copy their outfit, pose or composition.

ASSET: A half-body character portrait (head, shoulders and chest, cut off at mid-torso), 3/4 view, of a {male|female} {race word}: {DESCRIPTION}. Expressive face full of personality, a {class}-class hero. [legendary: This is a LEGENDARY premium look: the most ornate, prestigious and detailed outfit, with rich gold or precious accents and a striking silhouette.] Hand-drawn ink and watercolor illustration, pen-and-ink linework with watercolor wash coloring, grotesque caricature, dark fantasy cartoon. Thick hand-drawn outlines. Flames, glow and magic are painted as solid opaque ink-and-watercolour shapes, no soft bloom, no transparent wisps, no smoke haze, no light rays. No cast shadow, no ground plane, no background scene, no pattern, no stripes, no frame, no border. One character only, centred, the bust filling about 85% of the frame, cut off flat at the bottom edge at mid-torso. The ENTIRE background is one flat, uniform, solid bright magenta colour (#FF00FF) edge to edge, with absolutely nothing else in the frame. Not a 3D render, not a photo, no text, letters or logos.
```

## Список

| skin_key | Имя | Класс | Rarity | Цена | Описание |
|---|---|---|---|---|---|
| `human_m_sellsword` | Sellsword | warrior | epic | 400 💎 | a scarred mercenary with a broken nose and a crooked grin, a greatsword strapped across his back, a stained red gambeson with mismatched pauldrons, coin pouches on a bandolier |
| `human_m_crusader` | Crusader | warrior | legendary | 800 💎 | a fanatical crusader with a burning-eyed stare and a shaved head, gilded plate armour with a red tabard bearing a sun sigil, a flaming sword hilt over the shoulder, prayer scrolls nailed to the pauldrons |
| `human_m_cutpurse` | Cutpurse | rogue | epic | 400 💎 | a shifty pickpocket with a thin moustache and darting eyes, a dark hood thrown back, a dozen stolen rings on his fingers, a dagger twirling in one hand, lock-picks tucked behind his ear |
| `human_m_nightblade` | Nightblade | rogue | legendary | 800 💎 | a cold master assassin with a black half-mask and one white scarred eye, a midnight-blue leather coat with silver buckles, twin curved daggers crossed on the chest, a raven perched on his shoulder |
| `human_m_alchemist` | Alchemist | mage | epic | 400 💎 | a frazzled alchemist with singed eyebrows and huge goggles pushed up on his forehead, a leather apron full of bubbling vials, one green potion smoking in his hand, soot on his face |
| `human_m_archmage` | Archmage | mage | legendary | 800 💎 | an ancient archmage with an enormous braided white beard and a tall star-embroidered hat, deep violet robes with gold trim, a floating spellbook beside him and a crackling blue orb in his palm |
| `human_m_shieldbearer` | Shieldbearer | tank | epic | 400 💎 | a stocky veteran shieldbearer with a thick ginger beard, a dented kite shield bigger than his torso, a chainmail coif and a squashed nose, a calm stubborn expression |
| `human_m_bastion_lord` | Bastion Lord | tank | legendary | 800 💎 | a massive lord commander in white-and-gold full plate, a lion-crested great helm tucked under one arm revealing a square-jawed face, a tower shield emblazoned with a golden lion, a fur-lined cape |
| `human_f_shieldmaiden` | Shieldmaiden | warrior | epic | 400 💎 | a fierce shieldmaiden with a blonde braid and freckles, a round wooden shield painted with a wolf, a bronze-scaled hauberk, a bearded axe over her shoulder, a gap-toothed battle grin |
| `human_f_valkyrie` | Valkyrie | warrior | legendary | 800 💎 | a radiant valkyrie with a winged silver helm and long platinum braids, polished silver armour with gold filigree, white feathered wings folded behind her, a spear with a glowing tip |
| `human_f_duelist` | Duelist | rogue | epic | 400 💎 | a smug duelist with a feathered tricorne and a beauty mark, a slashed crimson doublet with puffed sleeves, a rapier raised in salute, one eyebrow cocked arrogantly |
| `human_f_shadow_queen` | Shadow Queen | rogue | legendary | 800 💎 | the queen of thieves with a black lace veil and a sly red-lipped smile, a hooded cloak of night-black velvet, jewelled daggers on her belt, a crown of thin silver thorns |
| `human_f_hedge_witch` | Hedge Witch | mage | epic | 400 💎 | a scruffy hedge witch with frizzy grey-streaked hair full of twigs, a patched green shawl, a frog sitting on her shoulder, a gnarled wand dripping green sparks |
| `human_f_star_oracle` | Star Oracle | mage | legendary | 800 💎 | a mysterious star oracle with closed glowing eyes and silver star tattoos on her face, flowing midnight robes with constellations, a crystal ball floating above her hands, a circlet of moonstone |
| `human_f_iron_matron` | Iron Matron | tank | epic | 400 💎 | a broad formidable iron matron with rosy cheeks and a stern frown, a dented steel breastplate, a huge round shield and a mace, grey hair pinned in a tight bun |
| `human_f_templar_saint` | Templar Saint | tank | legendary | 800 💎 | a serene templar saint in heavy gold-edged white plate with a halo-shaped crest, a tower shield with a holy rose emblem, a short white veil under the helm, an unshakable calm gaze |
| `orc_m_ironjaw` | Ironjaw | warrior | epic | 400 💎 | a green-skinned orc brawler with a riveted iron jaw replacing his lower teeth, a scarred bald head, spiked leather harness, a huge cleaver on his shoulder |
| `orc_m_bloodlord` | Bloodlord | warrior | legendary | 800 💎 | a towering orc warlord with red war paint across his eyes, a crown of tusks and bones, blackened iron armour with skull pauldrons, a massive double-headed axe, a cloak of wolf fur |
| `orc_m_sneak` | Sneak | rogue | epic | 400 💎 | a scrawny sly orc sneak with huge ears and a toothy smirk, a ragged hood, a curved knife between his teeth, bags of stolen loot hanging from his belt |
| `orc_m_venomfang` | Venomfang | rogue | legendary | 800 💎 | a lean orc assassin with green-black camo paint, a snake coiled around his neck, poison-dripping twin daggers, a mask of a snake skull over the brow, yellow slit eyes |
| `orc_m_fire_shaman` | Fire Shaman | mage | epic | 400 💎 | a wild-eyed orc fire shaman with a mane of braided dreadlocks, a necklace of boar teeth, a gnarled wooden staff crowned with a painted orange flame shape, ember-orange war paint |
| `orc_m_storm_seer` | Storm Seer | mage | legendary | 800 💎 | an elder orc storm seer with milky lightning-lit eyes, a tall antlered headdress, a cloak of black feathers, lightning crackling between his outstretched clawed fingers |
| `orc_m_boulder` | Boulder | tank | epic | 400 💎 | an enormous fat orc with a tiny head on huge shoulders, a slab of stone strapped to his chest as armour, a log for a club, a dopey satisfied grin |
| `orc_m_warwall` | Warwall | tank | legendary | 800 💎 | a gigantic orc juggernaut in layered black iron plates covered in spikes, a tower shield made from a gate, a horned helm with glowing red eye-slits, chains wrapped around his arms |
| `orc_f_axe_mother` | Axe Mother | warrior | epic | 400 💎 | a muscular green-skinned orc woman with braided black hair and tusks, a fur-lined leather vest, two hand axes, a battle-scarred grin |
| `orc_f_war_queen` | War Queen | warrior | legendary | 800 💎 | a regal orc war queen with a crown of iron spikes and red war paint, black iron armour with gold rings, a long glaive, braids decorated with trophy rings |
| `orc_f_scout` | Scout | rogue | epic | 400 💎 | a wiry orc scout with a shaved undercut and nose ring, green paint stripes, a short bow on her back, a hooded cloak of leaves |
| `orc_f_widowmaker` | Widowmaker | rogue | legendary | 800 💎 | a deadly orc assassin with a black spider tattoo across her face, a black leather corset, poisoned throwing knives along a bandolier, a cold smirk with one broken tusk |
| `orc_f_bone_caller` | Bone Caller | mage | epic | 400 💎 | an orc bone caller with a skull mask pushed up on her forehead, beaded braids, a bone rattle in her hand, green spirit-smoke curling around her fingers |
| `orc_f_blood_witch` | Blood Witch | mage | legendary | 800 💎 | a terrifying orc blood witch with red-glowing eyes and blood-red runes on her skin, a cloak of crow feathers, a floating ritual dagger, a crown of small skulls |
| `orc_f_ironhide` | Ironhide | tank | epic | 400 💎 | a huge orc woman with a flat-topped iron helmet and thick arms, a battered round iron shield, a chain shirt, a determined underbite |
| `orc_f_stone_mother` | Stone Mother | tank | legendary | 800 💎 | a colossal orc matriarch in armour of carved stone slabs covered in glowing green runes, a monolith shield, a headdress of stone horns, an ancient patient stare |
| `skeleton_m_grave_knight` | Grave Knight | warrior | epic | 400 💎 | an undead skeleton warrior with a cracked skull and glowing blue eye sockets, rusted plate armour with a torn black tabard, a notched longsword resting on his shoulder |
| `skeleton_m_bone_king` | Bone King | warrior | legendary | 800 💎 | a regal skeleton king with a jagged iron crown and violet flame in his eye sockets, ornate black-and-gold armour, a royal fur cape, a giant bone greatsword |
| `skeleton_m_grinner` | Grinner | rogue | epic | 400 💎 | a lanky skeleton thief with a permanent wide grin and one gold tooth, a tattered hood, daggers tucked between his ribs, a stolen pocket watch dangling from his jaw |
| `skeleton_m_phantom_blade` | Phantom Blade | rogue | legendary | 800 💎 | a skeletal assassin wrapped in shadowy ghost-cloth, green ghost-fire eyes, spectral daggers, a cowl of mist, chains with hooks wrapped around his arms |
| `skeleton_m_necromancer` | Necromancer | mage | epic | 400 💎 | a skeleton necromancer in a moth-eaten black robe with a high collar, a staff topped with a smaller skull, green flames in his eye sockets, a tome chained to his belt |
| `skeleton_m_soul_lich` | Soul Lich | mage | legendary | 800 💎 | a powerful skeleton lich with a crown of black crystals, a phylactery glowing violet in his ribcage, ornate purple robes, ghostly souls swirling around his raised hand |
| `skeleton_m_tombguard` | Tombguard | tank | epic | 400 💎 | a stocky skeleton guardian in heavy bronze tomb armour with a round burial shield, a helmet with cheek guards, dull orange eye lights |
| `skeleton_m_dread_bulwark` | Dread Bulwark | tank | legendary | 800 💎 | a massive armoured skeleton in black spiked plate with a tower shield made from a coffin lid, a horned helm, green soul-fire leaking from every gap |
| `skeleton_f_bone_valkyrie` | Bone Valkyrie | warrior | epic | 400 💎 | a skeleton warrior woman with a winged iron helm and long ghostly white hair, rusted scale armour, a spear, blue glowing eye sockets |
| `skeleton_f_death_duchess` | Death Duchess | warrior | legendary | 800 💎 | a regal skeleton duchess in black lace and gilded armour, a tall bone tiara, a long black veil, an elegant rapier, crimson flame in her eye sockets |
| `skeleton_f_ghostthief` | Ghost Thief | rogue | epic | 400 💎 | a sneaky skeleton thief girl with a ragged hood and a tattered scarf, a bag of stolen jewels, spectral blue wisps around her bony hands |
| `skeleton_f_widow_wraith` | Widow Wraith | rogue | legendary | 800 💎 | a skeletal assassin in a black mourning gown, a wide-brimmed veiled hat, a poisoned hatpin, a bouquet of dead roses, violet eye flames |
| `skeleton_f_grave_witch` | Grave Witch | mage | epic | 400 💎 | a skeleton witch with a crooked pointed hat full of cobwebs, a lantern with a trapped soul, a tattered purple shawl, green sparks at her fingertips |
| `skeleton_f_lich_queen` | Lich Queen | mage | legendary | 800 💎 | a terrifying skeleton lich queen with a crown of ice crystals, a long flowing pale-blue robe, frost runes orbiting her, a staff of frozen bone, cold blue eye flames |
| `skeleton_f_crypt_warden` | Crypt Warden | tank | epic | 400 💎 | a sturdy skeleton warden woman in bronze tomb armour with a large round shield, a crested helm, a lantern on her belt |
| `skeleton_f_iron_maiden` | Iron Maiden | tank | legendary | 800 💎 | a skeleton in heavy black plate shaped like a gothic iron maiden, a spiked tower shield, a horned visor, violet soul-fire leaking from the seams |
| `demon_m_pit_brawler` | Pit Brawler | warrior | epic | 400 💎 | a red-skinned horned demon brawler with a broken horn, chains wrapped around his fists, a spiked leather harness, a nasty fanged grin |
| `demon_m_hellknight` | Hellknight | warrior | legendary | 800 💎 | a demon knight in black hellforged armour with glowing orange cracks, huge curling horns through the helm, a flaming greatsword, a cape of embers |
| `demon_m_imp_thief` | Imp Thief | rogue | epic | 400 💎 | a small mischievous orange demon thief with big ears and a forked tail, a stolen golden goblet in one hand, a tiny hooded cloak, a toothy grin |
| `demon_m_shadow_fiend` | Shadow Fiend | rogue | legendary | 800 💎 | a sleek dark-purple demon assassin with glowing white eyes, swept-back horns, a hood of living shadow, twin black daggers with violet edges |
| `demon_m_hexer` | Hexer | mage | epic | 400 💎 | a crimson demon hexer with a goatee and long curved horns, a tattered red robe with occult symbols, a cursed doll in one hand, purple hex-fire in the other |
| `demon_m_inferno_lord` | Inferno Lord | mage | legendary | 800 💎 | a mighty demon sorcerer with a crown of fire between his horns, black and gold robes, molten-gold eyes, a floating sphere of hellfire, smouldering wings |
| `demon_m_brimstone_brute` | Brimstone Brute | tank | epic | 400 💎 | a hulking demon with a rocky brimstone hide, small eyes under heavy horns, a huge iron shield with a demon face, steam rising from his shoulders |
| `demon_m_abyss_warden` | Abyss Warden | tank | legendary | 800 💎 | a colossal demon warden in black obsidian armour with lava between the plates, a gate-sized shield, four horns, chains of hellfire around his arms |
| `demon_f_fury` | Fury | warrior | epic | 400 💎 | a fierce red demon woman with a wild black mane and short horns, a spiked leather armour, a flaming whip, a snarling fanged grin |
| `demon_f_hellblade_queen` | Hellblade Queen | warrior | legendary | 800 💎 | a regal demon queen warrior in black-gold armour, long elegant horns with gold rings, a curved flaming sword, bat wings folded behind her, burning eyes |
| `demon_f_trickster` | Trickster | rogue | epic | 400 💎 | a playful purple demon trickster with a jester's collar and small horns, a deck of burning cards, a forked tail holding a dagger, a mischievous grin |
| `demon_f_night_temptress` | Night Temptress | rogue | legendary | 800 💎 | a dangerous demon assassin with dark violet skin, a hooded cloak of shadows, glowing pink eyes, poisoned stiletto blades, a sly smile |
| `demon_f_cinder_witch` | Cinder Witch | mage | epic | 400 💎 | a demon witch with ash-grey skin and red horns, smouldering hair, a robe of charred cloth, a small cauldron of fire floating beside her |
| `demon_f_hellfire_empress` | Hellfire Empress | mage | legendary | 800 💎 | a majestic demon empress with a crown of molten gold between tall horns, an ornate high-collared black and gold robe with flame-shaped trim, eyes of white fire, a ring of painted fire runes floating above her raised hand |
| `demon_f_brimstone_matron` | Brimstone Matron | tank | epic | 400 💎 | a big burly demon woman with a rocky hide and thick horns, a heavy iron shield, a chain shirt, a stubborn scowl |
| `demon_f_obsidian_aegis` | Obsidian Aegis | tank | legendary | 800 💎 | a towering demon guardian woman in obsidian plate with glowing lava seams, a shield shaped like a demon face, a horned crown-helm, unshakable |
| `dogfolk_m_bulldog` | Bulldog | warrior | epic | 400 💎 | an anthropomorphic bulldog warrior with a wide jowly face, a spiked collar, a dented iron breastplate, a short heavy sword, a stubborn underbite |
| `dogfolk_m_wolf_lord` | Wolf Lord | warrior | legendary | 800 💎 | a regal grey wolf-headed warlord with a scarred muzzle, silver armour with wolf motifs, a fur cloak, a long war-axe, piercing golden eyes |
| `dogfolk_m_jackal` | Jackal | rogue | epic | 400 💎 | a sly jackal-headed thief with huge ears and a sneaky grin, a sand-coloured hood, a curved dagger, gold coins jingling on his belt |
| `dogfolk_m_shadow_hound` | Shadow Hound | rogue | legendary | 800 💎 | a black doberman-headed assassin with glowing red eyes, a black leather coat, twin daggers, a spiked collar with a silver tag, a cold stare |
| `dogfolk_m_beagle_scholar` | Beagle Scholar | mage | epic | 400 💎 | a floppy-eared beagle-headed scholar with round spectacles, a stack of books under one arm, a blue robe, a small magic spark on his paw |
| `dogfolk_m_moon_seer` | Moon Seer | mage | legendary | 800 💎 | a mystical white husky-headed seer with glowing ice-blue eyes, a moon-crest headdress, a silver robe, a crescent moon staff with floating runes |
| `dogfolk_m_mastiff` | Mastiff | tank | epic | 400 💎 | a gigantic mastiff-headed guard with drooping jowls, heavy chainmail, a big wooden tower shield, a drooling calm expression |
| `dogfolk_m_iron_saint` | Iron Saint | tank | legendary | 800 💎 | a massive saint-bernard-headed paladin in steel plate, a barrel on his chest, a huge shield with a paw emblem, a kind but immovable expression |
| `dogfolk_f_boxer` | Boxer | warrior | epic | 400 💎 | a fierce boxer-dog-headed fighter woman with wrapped paws, a leather vest, a scar over one eye, a confident toothy grin |
| `dogfolk_f_silver_alpha` | Silver Alpha | warrior | legendary | 800 💎 | a majestic silver wolf-headed warrior woman in ornate silver armour, a crescent-blade glaive, a white fur mantle, fierce golden eyes |
| `dogfolk_f_fox_thief` | Fox Thief | rogue | epic | 400 💎 | a sly fox-headed thief woman with a bushy tail curled forward, a green hood, a stolen necklace in her paw, a smug grin |
| `dogfolk_f_night_huntress` | Night Huntress | rogue | legendary | 800 💎 | a sleek black wolf-headed huntress with violet eyes, a dark leather hood, a crossbow, a necklace of fangs, a silent predatory stare |
| `dogfolk_f_poodle_enchantress` | Poodle Enchantress | mage | epic | 400 💎 | a fancy poodle-headed enchantress with a pink pompadour, a frilly violet robe, a jewelled wand with pink sparks, a snooty expression |
| `dogfolk_f_spirit_fox` | Spirit Fox | mage | legendary | 800 💎 | a mystical white fox-headed mage with three flame-tipped tails, blue spirit fire floating around her, a red and white shrine robe, golden eyes |
| `dogfolk_f_shepherd_guard` | Shepherd Guard | tank | epic | 400 💎 | a sturdy german-shepherd-headed guard woman in chainmail, a big round shield, a helmet with ear holes, an alert loyal expression |
| `dogfolk_f_bastion_matriarch` | Bastion Matriarch | tank | legendary | 800 💎 | a towering great-dane-headed matriarch knight in heavy bronze plate, a tower shield with a hound crest, a fur cloak, a regal protective gaze |

## Брак / перегенерации

- `orc_m_fire_shaman` — 1-я генерация failed (вероятно фильтр на «smoking pipes»), переписан без трубок.
- `demon_f_hellfire_empress` — failed на «gown of flame», переписан на «black and gold robe with flame-shaped trim».
- `dogfolk_f_shepherd_guard` — 1 failed, повтор с перефразировкой прошёл.
- `dogfolk_m_moon_seer` — руны на 1-й версии читались как латинские буквы (iRKS), перегенерирован с кристаллами вместо рун.
- Остаточный magenta: 0 предупреждений по всем 80.
