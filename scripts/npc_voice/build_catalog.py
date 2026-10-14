import re, json, hashlib, sys
import os
SRC = os.path.join(os.path.dirname(__file__), "../../Hexbound/Hexbound")
lines = []  # (speaker, text, source)
def add(speaker, text, src): lines.append((speaker, text, src))

# 1. NPCHint catalog
s = open(f"{SRC}/Services/NPCHintManager.swift").read()
for m in re.finditer(r'NPCHint\(\s*id: "([^"]+)",\s*npcName: "([^"]+)",.*?message: "((?:[^"\\]|\\.)*)"', s, re.S):
    add(m.group(2), m.group(3).replace('\\"','"'), f"hint:{m.group(1)}")

# 2. Tutorial FTUE objectives (Tavern Keeper Grothmund) + tooltips
t = open(f"{SRC}/Tutorial/TutorialManager.swift").read()
obj = t[t.index("var npcDialog"):t.index("CTA button label")]
for x in re.findall(r'return "([^"]+)"', obj): add("Tavern Keeper", x, "ftue")
tip = t[t.index("var message: String"):t.index("var arrowEdge")]
tipspk = {"hubCharacterCard":"Tavern Keeper","hubCityMap":"Tavern Keeper","hubDailyLogin":"Tavern Keeper","hubStamina":"Tavern Keeper",
          "arenaOpponent":"Arena Master","arenaStance":"Arena Master","shopGems":"Merchant","dungeonEntry":"Dungeon Guide"}
for case, x in re.findall(r'case \.(\w+):\s*return "([^"]+)"', tip): add(tipspk[case], x, f"tooltip:{case}")

# 3. Fortuna / Finch
f = open(f"{SRC}/Views/Minigames/FortuneWheelViewModel.swift").read()
blk = f[f.index("private let speechLines"):]
blk = blk[:blk.index("]", blk.index("loseSpeechLines"))]
for x in re.findall(r'"([^"]+)"', blk): add("Lady Fortuna", x, "fortuna")
add("Lady Fortuna", "The wheel needs rest... come back tomorrow.", "fortuna:limit")
g = open(f"{SRC}/Views/Minigames/ShellGameViewModel.swift").read()
blk = g[g.index("defaultLines = ["):]
blk = blk[:blk.index("]", blk.index("loseLines"))]
for x in re.findall(r'"([^"]+)"', blk): add("Finch", x, "finch")

# 4. Hub onboarding + tutorial quest messages (Tavern Keeper)
h = open(f"{SRC}/Views/Hub/HubView.swift").read()
for x in re.findall(r'\(title: "[^"]+", message: "([^"]+)"\)', h): add("Tavern Keeper", x, "hub_onboarding")
q = h[h.index("func questNpcMessage"):]; q = q[:q.index("return messages")]
for k, x in re.findall(r'"(\w+)": "([^"]+)"', q): add("Tavern Keeper", x, f"quest:{k}")

# 5. Merchant tips (concat segments)
mt = open(f"{SRC}/Views/Shop/MerchantTipProvider.swift").read()
for seg in re.findall(r'MerchantTip\(segments: \[(.*?)\]\)', mt, re.S):
    txt = "".join(re.findall(r'\.(?:plain|gold|gem)\("([^"]*)"\)', seg))
    add("Merchant", txt, "merchant_tip")

# 6. Arena master plain line
add("Arena Master", "Pick an opponent and fight to climb the ranks.", "arena_widget")

SPEAKER = {"Tavern Keeper":"tavern","Guide":"tavern","Arena Master":"arena","Merchant":"merchant","Sage":"sage","Healer":"healer",
  "Field Medic":"medic","Blacksmith":"smith","Dungeon Guide":"dungeon","Dungeon Keeper":"dungeon","Mine Foreman":"mine",
  "Herald":"herald","Chronicler":"chronicler","Trickster":"finch","Finch":"finch","Lady Fortuna":"fortuna"}
def key(text): return "".join(ch for ch in text.lower() if ch.isascii() and ch.isalnum())
out, seen = [], {}
for sp, text, src in lines:
    k = key(text)
    if k in seen:  # same text, maybe different source — voice once
        continue
    slug = SPEAKER[sp]
    fid = f"npc_{slug}_{hashlib.sha1(k.encode()).hexdigest()[:8]}"
    seen[k] = fid
    out.append({"id": fid, "speaker": slug, "text": text, "key": k, "source": src})
def tts(t):
    t = t.replace("PSA:", "Listen up:").replace("HP", "health").replace("2–3", "two or three").replace("10%", "ten percent")
    t = t.replace("RNG gods", "R-N-G gods").replace("XP", "X P").replace("GET MORE", "Get More")
    t = re.sub(r"\b([A-Z]{2,})\b", lambda m: m.group(1).capitalize() if m.group(1) not in ("X","P") else m.group(1), t)
    return t
for o in out: o["tts"] = tts(o["text"])
json.dump(out, open(os.path.join(os.path.dirname(__file__), "catalog.new.json"),"w"), indent=1, ensure_ascii=False)
from collections import Counter
print(len(lines), "lines,", len(out), "unique"); print(Counter(o["speaker"] for o in out))
