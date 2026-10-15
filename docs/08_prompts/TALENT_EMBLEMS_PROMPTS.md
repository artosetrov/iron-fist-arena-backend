# Talent emblems — prompts (2026-10-14)

59 эмблем для всех узлов дерева талантов, у которых нет руны (foundation + tier-2 ветки; руны, keystone- и ultimate-узлы показывают камни рун `rune-*`).
Семейство pen-and-ink из `ART_STYLE_GUIDE.md`, якоря те же, что у иконок предметов: оружие → `wpn_soulreaver` (`0c72abb7-…`), всё остальное → `chest_godplate` (`1c5bda93-…`).

- Имя ассета: `talent-<nodeKey>` с заменой `.`/`_` на `-` (`rogue.found.agility` → `talent-rogue-found-agility`), папка `Assets.xcassets/Talents/`.
- `TalentNodeView` берёт эмблему, если ассет есть в бандле; иначе — SF Symbol. Залоченный узел — обесцвечен, 55% opacity.
- Ingest `--pt 64` (узел 56pt, эмблема 78% = ~44pt). Ключ `#00FF00`, маджента — где в предмете зелёный (яд, мох).

## Шаблон

```
Pen and ink illustration of {SUBJECT}, a single talent emblem icon, one compact object with a bold readable silhouette, bold black ink outlines on every element, colored with {BASE TONES} and {ACCENT} accents, weathered and worn surfaces, big clear shapes that read at very small icon size, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat bright green background, centred with margin, the object filling about 80% of the frame, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters, numbers or logos, no particles. The ENTIRE background is one flat, uniform, solid bright green colour (#00FF00) edge to edge, no pattern, no stripes, no frame, no border.
```

## Узлы

| asset | SUBJECT | ключ |
|---|---|---|
| `talent-warrior-found-vitality` | a red anatomical heart wrapped in an iron band with rivets | green |
| `talent-warrior-found-iron-skin` | a forearm bracer of overlapping riveted iron scales | green |
| `talent-warrior-found-wards` | a round iron shield boss engraved with a protective ward sigil | green |
| `talent-warrior-found-critical-eye` | a narrowed one-eyed war helm visor with a single red-painted eye slit | green |
| `talent-warrior-found-swift-resolve` | a short sword with a winged crossguard and a leather grip | green |
| `talent-warrior-berserk-rage` | a horned berserker skull mask with bared teeth and red war paint | green |
| `talent-warrior-crus-iron-will` | a clenched iron gauntlet fist holding a small prayer bead chain | green |
| `talent-warrior-crus-fortitude` | a heavy kite shield with a carved oak tree emblem | green |
| `talent-warrior-exec-ruthless` | a jagged serrated axe head dripping a single drop of blood | green |
| `talent-warrior-berserk-momentum` | a war hammer with motion speed-lines painted as solid ink strokes behind its head | green |
| `talent-warrior-crus-retribution` | a sword thrust upward through a cracked round shield | green |
| `talent-warrior-crus-second-wind` | a battered war horn with a small red heart charm tied to it | green |
| `talent-warrior-exec-execute` | an executioner's broad axe embedded in a wooden block | green |
| `talent-warrior-berserk-bloodlust` | a horned drinking goblet carved from bone overflowing with red | green |
| `talent-warrior-crus-sanctified` | a crusader shield with a golden sunburst and a small chalice | green |
| `talent-warrior-crus-aegis` | a tall gilded tower shield with a lion head boss | green |
| `talent-warrior-exec-decapitate` | a long two-handed executioner sword with a notched blade and a skull pommel | green |
| `talent-rogue-found-agility` | a winged leather boot with a feather tucked in its strap | green |
| `talent-rogue-found-precision` | a throwing knife piercing the centre of a small round target | green |
| `talent-rogue-found-shadows` | a black hooded cloak with an empty dark hood | green |
| `talent-rogue-found-venom` | a coiled viper with fangs bared and a drop of venom | magenta |
| `talent-rogue-found-swiftness` | a pair of crossed thin daggers with motion strokes | green |
| `talent-rogue-asn-backstab` | a curved dagger plunged into the back of a dark cloak | green |
| `talent-rogue-duel-parry` | a slender rapier with a swept basket hilt deflecting a blade | green |
| `talent-rogue-sab-toxin` | a small cracked glass vial leaking green poison | magenta |
| `talent-rogue-asn-bleed` | a curved blade with three red blood drops falling from its edge | green |
| `talent-rogue-duel-riposte` | two crossed rapiers forming an X with a small red spark of contact painted at the cross | green |
| `talent-rogue-sab-paralyze` | a spider-silk wrapped dagger with a small black spider on its blade | green |
| `talent-rogue-asn-deep-cut` | a hooked karambit knife with a long slash mark painted behind it | green |
| `talent-rogue-duel-finesse` | a duelist's feathered cap resting on a thin rapier | green |
| `talent-rogue-sab-weaken` | a broken iron chain link split by a dagger | magenta |
| `talent-mage-found-intellect` | an ancient bright blue painted eye set in the cover of a closed tome | green |
| `talent-mage-found-mana-pool` | a round stone bowl filled with deep blue mana liquid | green |
| `talent-mage-found-focus` | a crystal lens on a brass stand focusing a single blue beam painted as a solid ink stroke | green |
| `talent-mage-found-resonance` | a brass tuning fork with concentric ring strokes painted around its prongs | green |
| `talent-mage-found-arcane-armor` | a mage's robe collar clasp shaped like a shield with a blue gem | green |
| `talent-mage-pyro-kindle` | a small iron brazier with a solid painted orange flame | green |
| `talent-mage-arc-focus-flow` | an hourglass whose sand is blue mana | green |
| `talent-mage-cryo-frost` | a sharp jagged ice crystal shard | green |
| `talent-mage-pyro-conflagration` | a cracked scroll bursting into solid painted orange flames at one end | green |
| `talent-mage-arc-arcane-might` | a carved wooden staff head clutching a violet orb | green |
| `talent-mage-cryo-freeze` | a snowflake-shaped ice sigil carved in a frozen stone disc | green |
| `talent-mage-pyro-inferno` | a horned demon skull wreathed in solid painted orange flame shapes | green |
| `talent-mage-arc-chronomancy` | a brass pocket watch with a cracked glass face and a crescent moon on the lid | green |
| `talent-mage-cryo-glacial` | a thick block of blue glacier ice with a sword frozen inside | green |
| `talent-tank-found-stoneform` | a stone fist cracked and studded with pebbles | magenta |
| `talent-tank-found-plate` | a single thick riveted pauldron of heavy plate | green |
| `talent-tank-found-resilience` | an iron anvil with a dented top | green |
| `talent-tank-found-rebuke` | a spiked iron shield boss with thorns | green |
| `talent-tank-found-stability` | a heavy iron sabaton planted on a flat stone slab | green |
| `talent-tank-prot-cleave` | a huge two-headed battle axe | green |
| `talent-tank-ward-shield` | a round wooden shield banded with iron and a bronze boss | green |
| `talent-tank-jug-fortify` | a stone castle tower with iron-banded gate | green |
| `talent-tank-prot-challenge` | an iron gauntlet throwing down a challenge, palm open, with a fallen glove below | green |
| `talent-tank-ward-reflect` | a polished round steel shield with a mirror-bright face | green |
| `talent-tank-jug-immovable` | a giant iron anchor sunk into a rock | green |
| `talent-tank-prot-retaliation` | a mace with spikes and a small red drop on one spike | green |
| `talent-tank-ward-absolution` | a silver chalice with a red droplet and a small halo ring painted above | green |
| `talent-tank-jug-unbreakable` | a thick iron chain with one link reinforced by a bronze band | green |

## Заметки

- 8 эмблем (`rogue.found.*` ×5, `rogue.asn.backstab`, `mage.found.intellect`, `mage.cryo.frost`) сделала параллельная сессия до этой — взяты как есть, тот же стиль.
- `tank.found.rebuke`: «spiked iron shield boss with thorns» → ложный NSFW, переписан как «round iron buckler studded with short sharp iron spikes».
