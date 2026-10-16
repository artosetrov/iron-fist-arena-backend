# NPC voice-over

Every line an NPC speaks (`NPCGuideWidget`, `NPCSpeechBubble`, `TutorialQuestBanner`) is
looked up by its text in `Resources/Audio/NPC/npc_voice_manifest.json` and played by
`NPCVoice` (through `AudioManager.playVoice`, which ducks BGM). Text with no recording is silent.

Lookup key = the line lowercased, ASCII letters and digits only. Changing a line's wording
changes its key, so **re-voice any NPC line you edit** (or it goes silent — nothing breaks).

## Adding / changing lines
1. Edit the copy in Swift as usual.
2. `python3 scripts/npc_voice/build_catalog.py` → `catalog.new.json` (diff it against `catalog.json`;
   add the new source to the script if the line lives in a new file).
3. Generate the new lines with Higgsfield TTS (`text2speech_v2`, variant `elevenlabs`) using the
   speaker's `voice` id from `catalog.json`, the `tts` field as the prompt. Rate limit ≈ 4 parallel jobs.
4. Save the mp3s as `<id>.mp3` in a folder, then `python3 scripts/npc_voice/process_audio.py <folder>`.

## Cast (Higgsfield preset voices)
Each speaker also has a face: `Assets.xcassets/NPC/npc-<speaker>` (waist-up, 256 pt) and `npc-<speaker>-face` (round avatars). `NPCVoice.speaker(for:)` reads the speaker from the recording name, so any recorded line shows the portrait of whoever voices it — a new speaker needs both a voice and a portrait (`docs/08_prompts/NPC_PORTRAITS_PROMPTS.md`).

| speaker | NPC | voice |
|---|---|---|
| tavern | Tavern Keeper Grothmund, tutorial guide | Bram |
| arena | Arena Master | Gideon |
| merchant | Merchant | Sterling |
| sage | Sage | Alistair |
| healer | Healer | Imogen |
| medic | Field Medic | Tamsin |
| smith | Blacksmith | Reid |
| dungeon | Dungeon Guide / Keeper | Orion |
| mine | Mine Foreman | Barrett |
| herald | Herald | Harrison |
| chronicler | Chronicler | Caspian |
| finch | Finch (Shell game) | Callum |
| fortuna | Lady Fortuna | Vesper |
| scavenger | The Scavenger (Black Market keeper) | Knox |
