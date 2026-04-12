# Ambient Sound Files — Hexbound

Place `.wav` files here. AmbientManager looks for files by name (without extension).

## Required Ambient Loops (from Fantasy 200 SFX Pack + custom)

All files should be **seamless loops** (can repeat infinitely without clicks).

| File | Source from Pack | Used in Zone |
|------|-----------------|--------------|
| `amb_torch_crackle.wav` | Background/Fire or Campfire loop | Hub, HubRain, Arena, Shop, HallOfFame |
| `amb_city_murmur.wav` | Background/Town Day or Market | Hub |
| `amb_wind_light.wav` | Background/Wind Light or Day | Hub |
| `amb_rain_loop.wav` | Background/Rain or Weather | HubRain |
| `amb_thunder_distant.wav` | Background/Thunder Distant | HubRain |
| `amb_crowd_murmur.wav` | Background/Crowd or Tavern | Arena |
| `amb_crowd_roar.wav` | Background/Crowd Loud or Battle | ArenaFight |
| `amb_cave_drip.wav` | Background/Cave or Drip Water | Dungeon, DungeonDeep, GoldMine |
| `amb_wind_cave.wav` | Background/Wind Cave or Dungeon | Dungeon, DungeonBoss |
| `amb_wind_heavy.wav` | Background/Wind Strong or Storm | DungeonDeep, Cinematic |
| `amb_bone_rattle.wav` | Custom / skeleton rattle | DungeonDeep |
| `amb_ominous_rumble.wav` | Background/Ominous or Boss | DungeonBoss |
| `amb_coins_ambient.wav` | Custom from coins SFX (looped) | Shop |
| `amb_forge_fire.wav` | Background/Forge or Fire Heavy | Forge |
| `amb_anvil_ambient.wav` | Custom from mining/anvil hits | Forge |
| `amb_pickaxe_distant.wav` | Mining/Chop SFX (looped) | GoldMine |
| `amb_tavern_bustle.wav` | Background/Tavern or Inn | Tavern (Shell/Wheel) |
| `amb_fire_distant.wav` | Background/Fire Distant | Cinematic |
| `amb_hall_echo.wav` | Background/Cave or Hall Reverb | HallOfFame |

## Required One-Shot SFX (place in ../SFX/)

| File | Variations | Source from Pack | Used for |
|------|-----------|-----------------|----------|
| `crowd_roar.wav` | `_2` | Crowd cheer | Arena entrance |
| `war_drums.wav` | `_2` | Drum or Battle | Pre-fight |
| `gong_hit.wav` | — | Metal hit / gong | Match start |
| `coins_jingle.wav` | `_2`, `_3` | Coin sounds | Purchase |
| `merchant_greet.wav` | — | Door bell + cloth | Shop open |
| `pouch_drop.wav` | — | Bag/pouch drop | Transaction |
| `armor_clink.wav` | `_2` | Metal armor equip | Metal equip |
| `cloth_rustle.wav` | — | Cloth/fabric | Cloth equip |
| `magic_shimmer.wav` | — | Magic/enchant | Relic equip |
| `anvil_strike.wav` | — | Anvil/hammer hit | Upgrade hit |
| `enchant_glow.wav` | — | Magic spell success | Upgrade success |
| `creature_growl.wav` | `_2`, `_3` | Monster/creature | Boss tension |
| `rock_crumble.wav` | `_2` | Rock/stone break | Floor collapse |
| `chain_rattle.wav` | — | Chain/metal rattle | Gate unlock |
| `footstep_stone.wav` | `_2`, `_3`, `_4` | Footstep/stone | Dungeon move |
| `footstep_wood.wav` | `_2`, `_3` | Footstep/wood | Building entry |
| `epic_horn_fanfare.wav` | — | Horn/fanfare/victory | Level up, rank up |
| `seal_stamp.wav` | — | Seal/stamp heavy | Achievement |
| `scroll_unfurl.wav` | — | Paper/scroll | Quest list open |
| `chain_break.wav` | — | Chain break/snap | BP tier unlock |
| `magic_spark.wav` | — | Magic sparkle/chime | Reward claim |
| `wheel_spin.wav` | — | Ratchet/click loop | Fortune wheel |
| `shell_shuffle.wav` | — | Wood slide/shuffle | Shell game |
| `pickaxe_hit.wav` | `_2`, `_3` | Pickaxe/mining | Gold mine tap |
| `door_creak.wav` | `_2` | Door wood creak | Building entry |
| `torch_ignite.wav` | — | Fire whoosh | Screen transition |

## Naming Convention

- Ambient loops: `amb_<name>.wav` → placed in `Audio/Ambient/`
- One-shot SFX: `<name>.wav` → placed in `Audio/SFX/`
- Variations: `<name>_2.wav`, `<name>_3.wav`, etc.

## Tips for Selecting from Pack

1. **Loopable backgrounds** → Use directly as `amb_*.wav` files
2. **Footsteps** → Pack has dirt/stone/wood/water — use stone and wood
3. **Doors/chests/gates** → Great for `door_creak` and `chain_rattle`
4. **Mining/chopping** → Perfect for `pickaxe_hit` and `anvil_strike`
5. **Sword/bow SFX** → Already have combat sounds, but can replace/add
6. **Spell SFX** → Use for `magic_shimmer`, `enchant_glow`, `magic_spark`
7. **Rivers/waterfalls** → Could add water zone later
