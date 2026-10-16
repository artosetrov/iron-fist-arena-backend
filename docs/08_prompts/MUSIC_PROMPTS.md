# Hexbound — Music Prompts

Prompts behind the background tracks. Companion to
`SOUND_CATALOG.md`, which numbered the tracks (M1–M12) back in March and
described what each one is for; this file is what you paste into a
generator to get them.

**Status at 2026-10-16.** All thirteen tracks exist and are wired. The
seven below were generated in Mureka (V9.5, Custom, Instrumental) from the
prompts in this file, two variants each; variant A is in the bundle and both
sit in `_music_audition/normalized/` for comparison. Swapping a zone to its
B take is a file copy over the same name — no project or code change.

Levels: each take was trimmed to -15 LUFS to match the existing tracks, or
further if that left the true peak above -1.5 dBFS, then re-encoded at
192 kbps. `scripts/check_audio_levels.py` covers them from here.

| # | Zone (`AmbientZone`) | File | Status |
|---|---|---|---|
| M1 | — (Welcome, onboarding) | `main-theme.mp3` | ✅ |
| M2 | `hub`, `hubRain` | `stray-city.mp3` | ✅ |
| M3 | `arenaFight` | `battle-combat.mp3` | ✅ wired 2026-10-15 |
| M4 | — (result screen, win) | `victory-fanfare.mp3` | ✅ wired 2026-10-15 |
| M5 | — (result screen, loss) | `defeat-sting.mp3` | ✅ wired 2026-10-15 |
| M6 | `arena` | `arena-pvp.mp3` | ✅ |
| M7 | `dungeon`, `dungeonDeep` | `music-dungeon.mp3` | ✅ wired 2026-10-16 |
| M8 | `dungeonBoss` | `music-boss.mp3` | ✅ wired 2026-10-16 |
| M9 | `shop` | `music-shop.mp3` | ✅ wired 2026-10-16 |
| M10 | `tavern` | `music-tavern.mp3` | ✅ wired 2026-10-16 |
| M13 | `forge` | `music-forge.mp3` | ✅ wired 2026-10-16 |
| M14 | `goldMine` | `music-gold-mine.mp3` | ✅ wired 2026-10-16 |
| M15 | `hallOfFame` | `music-hall-of-fame.mp3` | ✅ wired 2026-10-16 |

M11 (character creation) and M12 (dungeon rush) from the old catalog are
deliberately not here — onboarding drives its own per-page track, and
Dungeon Rush has no zone of its own yet.

## How to add one once it is generated

1. Drop the file in `Hexbound/Hexbound/Resources/Audio/BGM/` under the name
   in the table.
2. `python3 scripts/check_audio_levels.py` — it will flag the level against
   the BGM median and refuse anything peaking over −1 dBFS.
   `python3 scripts/normalize_audio.py` fixes both.
3. Replace the `nil` for that zone in `AmbientZone.bgmTrack`
   (`Persistence/AmbientManager.swift`) with the filename. That is the whole
   wiring — the screen already enters the zone.
4. Register it in the Xcode project so it ships in the bundle.

---

## House style — prepend to every prompt

> Dark fantasy game soundtrack, orchestral and acoustic, no vocals, no
> drums-only loops, no modern synths, no cinematic risers or trailer hits.
> Live-sounding instruments: strings, low woodwinds, hand percussion, lute,
> hammered dulcimer, solo cello. Restrained and grim rather than heroic —
> closer to a rulebook illustration than a film trailer. Seamless loop,
> quiet enough to sit under speech, no sudden peaks.

The visual half of the same world is in `ART_STYLE_GUIDE.md`: pen-and-ink,
muted earth tones, Darkest Dungeon / D&D Monster Manual. The music should
feel like it belongs to those pictures — small ensemble, close-recorded,
nothing glossy.

---

## M7 — Dungeon

*Zones `dungeon` and `dungeonDeep`. 90–120 s loop.*

> Dark fantasy dungeon exploration loop. Sparse and patient: a low drone on
> cellos and double bass, a single plucked lute figure repeating every eight
> bars, occasional bowed harmonics far away. Tempo around 60 BPM, minor
> mode, long silences between phrases. Tension from emptiness, not from
> volume. No percussion except a rare soft frame drum. Seamless loop, no
> vocals.

## M8 — Boss

*Zone `dungeonBoss`. 60–90 s loop.*

> Dark fantasy boss encounter loop. Low brass and contrabass ostinato, taiko
> and timpani on the downbeats, a dissonant held string cluster over the
> top. Tempo around 90 BPM, driving but heavy rather than fast. Builds once
> across the loop and resets without a cymbal crash. Menacing and physical,
> not triumphant. No vocals, no electronic elements.

## M9 — Shop

*Zone `shop`. 60–90 s loop. Also plays in the black market for now.*

> Medieval merchant's shop loop. Warm and busy: hammered dulcimer and lute
> trading a simple major-key phrase, light tambourine, pizzicato strings
> underneath. Tempo around 100 BPM, friendly but a little sly — this
> merchant is not giving anything away. Small room, close-recorded. Seamless
> loop, no vocals.

## M10 — Tavern

*Zone `tavern`. Shell game, fortune wheel, the chest. 90–120 s loop.*

> Medieval tavern loop. Lute, fiddle and a soft bodhrán playing a relaxed
> drinking tune in a minor key that keeps resolving to major. Tempo around
> 95 BPM, swung slightly, like musicians playing for themselves rather than
> for a crowd. Warm, low-lit, a bit worn. Seamless loop, no vocals.

## M13 — Forge

*Zone `forge`. Hero screen, inventory, upgrades. 90–120 s loop.*

> Blacksmith's forge loop. Rhythmic and deliberate: a low anvil-like pulse
> every two beats, bowed cello holding long notes over it, a quiet brass
> swell at the end of each phrase. Tempo around 75 BPM, minor mode. Sounds
> like work being done well — focused, unhurried, slightly proud. Seamless
> loop, no vocals.

## M14 — Gold Mine

*Zone `goldMine`. 60–90 s loop.*

> Deep mine loop. Hollow and echoing: sparse marimba or struck-metal tones
> dripping into a long reverb, a sustained low drone far beneath, faint
> irregular taps like distant picks. Tempo around 70 BPM, modal rather than
> clearly minor or major. Patient, slightly hypnotic — idle income, not
> danger. Seamless loop, no vocals.

## M15 — Hall of Fame

*Zone `hallOfFame`. Leaderboard. 60–90 s loop.*

> Hall of records loop. Solemn and spacious: a small string ensemble playing
> a slow processional, a church organ pedal note underneath, occasional
> harp. Tempo around 65 BPM, minor with an open fifth ending. Reverent and
> cold, like a room full of names of people who are mostly dead. No
> percussion, no fanfare. Seamless loop, no vocals.

---

## Notes for whoever generates these

- **Ask for the loop explicitly.** Generators love to end on a fade or a
  cymbal; a track that does not loop is unusable here.
- **Keep them quiet at the source.** The BGM median in this project is
  around −13.6 LUFS and everything stays under −1 dBFS true peak. The gate
  will catch it either way, but a track generated hot and then pulled down
  sounds worse than one generated with room.
- **Save the prompt that produced the keeper**, next to this file. Doing
  that for the art is what keeps the style consistent across batches; music
  is no different.
