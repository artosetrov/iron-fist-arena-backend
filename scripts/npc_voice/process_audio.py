#!/usr/bin/env python3
"""Turn raw TTS mp3s into the shipped NPC voice-over.

Input : a JSON bundle {line_id: base64 mp3} (how the files were pulled from
        the Higgsfield CDN), or a folder of <line_id>.mp3 files.
Output: Hexbound/Hexbound/Resources/Audio/NPC/<line_id>.m4a + manifest.

Per-speaker treatment: male voices are pitched down and warmed (the art
direction is grimdark; the stock TTS voices read too clean), every line is
loudness-normalized to -16 LUFS so NPCs sit at the same level, mono AAC 64k.
"""
import base64, json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "../../Hexbound/Hexbound/Resources/Audio/NPC")
# semitones; 0 = untouched. Female voices and Finch (a quick trickster) stay lighter.
PITCH = {"tavern": -1.5, "arena": -2, "merchant": -1, "sage": -1, "smith": -2.5, "dungeon": -2,
         "mine": -2, "herald": -1, "chronicler": -1, "finch": -0.5,
         "healer": 0, "medic": 0, "fortuna": 0, "scavenger": -1.5}
WARM = "equalizer=f=140:t=q:w=1.2:g=3,equalizer=f=3200:t=q:w=1.5:g=-2,lowpass=f=10000"

def main(src):
    catalog = {o["id"]: o for o in json.load(open(os.path.join(HERE, "catalog.json")))}
    if src.endswith(".json"):
        blobs = {k: base64.b64decode(v) for k, v in json.load(open(src)).items()}
    else:
        blobs = {f[:-4]: open(os.path.join(src, f), "rb").read() for f in os.listdir(src) if f.endswith(".mp3")}
    os.makedirs(OUT, exist_ok=True)
    missing = sorted(set(catalog) - set(blobs))
    with tempfile.TemporaryDirectory() as tmp:
        for lid, data in sorted(blobs.items()):
            if lid not in catalog:
                print("skip unknown", lid); continue
            raw = os.path.join(tmp, lid + ".mp3"); open(raw, "wb").write(data)
            st = PITCH[catalog[lid]["speaker"]]
            chain = []
            if st:
                chain.append(f"rubberband=pitch={2 ** (st / 12):.5f}:formant=preserved")
                chain.append(WARM)
            chain.append("loudnorm=I=-16:TP=-1.5:LRA=11")
            chain.append("silenceremove=start_periods=1:start_threshold=-50dB")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", raw, "-af", ",".join(chain),
                            "-ac", "1", "-ar", "44100", "-c:a", "aac", "-b:a", "64k",
                            os.path.join(OUT, lid + ".m4a")], check=True)
    manifest = {}
    for o in catalog.values():
        key = "".join(c for c in o["text"].lower() if c.isascii() and c.isalnum())
        if os.path.exists(os.path.join(OUT, o["id"] + ".m4a")):
            manifest[key] = o["id"] + ".m4a"
    json.dump(manifest, open(os.path.join(OUT, "npc_voice_manifest.json"), "w"), indent=0, sort_keys=True)
    print(f"{len(manifest)} lines voiced, {len(missing)} missing: {missing[:5]}")

if __name__ == "__main__":
    main(sys.argv[1])
