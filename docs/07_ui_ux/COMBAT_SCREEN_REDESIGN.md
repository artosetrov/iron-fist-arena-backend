# Combat Screen Redesign — UX Prototype

**Date:** 2026-04-13
**Author:** Claude (UX orchestrator)
**Status:** Paper prototype — awaiting Artem's approval before Figma + Swift build
**Scope:** Active fight screen + end-of-fight reveal. Combat log visibility rethought.

---

## 1. Problem

Current combat screen (see reference screenshots):

- **Combat log eats ~40% of screen real estate** during the fight. It's the most visually dominant element — but the weakest emotionally.
- **Portraits and HP bars are small** and don't carry the drama of the fight.
- **Damage numbers are text lines, not flying numbers** — zero wow.
- **VICTORY/DEFEAT** feels flat — same layout as the fight, just with a banner on top.
- **"Attack / Defend" zone panel** is static and unclear — no visual link to the body.
- **SKIP button cuts straight to result** — players who want speed lose the moment.

Result: players tap 2x/Skip to get it over with because the fight isn't rewarding to watch. That kills the core dopamine loop.

---

## 2. How competitors handle this

Quick reference — what other PvP RPGs do during combat:

| Game | Log visible? | Wow delivery |
|---|---|---|
| RAID: Shadow Legends | No (icon opens it) | Full-frame portraits, floating damage numbers, screen shake on hits, cinematic crit slowdowns |
| AFK Arena | No | Animated sprites, big damage numbers in rarity color, ultimate cutscenes |
| Hero Wars | No | Trailing "ghost HP" bar, particle bursts, camera pans |
| Watcher of Realms | Collapsed by default | 3D models, hit flashes, ultimate reveal takeover |
| Summoners War | Tiny top-right, off by default | Sprite hits, crit bursts, heavy SFX |
| Marvel Snap / Hearthstone | No log — the animation IS the log | Card plays animate, numbers pop from the target |
| Auto Chess / TFT | Side panel (damage dealt) | Units clash with particles, health bars drain with lag |

**Conclusion:** no serious PvP game keeps a scrolling text log as the primary mid-fight element. The genre standard is: **animation carries emotion during the fight; log becomes a tappable post-fight detail accordion.**

---

## 3. Proposed direction (recommendation)

### 3.1 Hide the log during the fight. Show it collapsed after.

- During fight: no scrolling text log. Combat log icon (📜) in the top-right corner if a player really wants it live — single tap toggles a side drawer.
- Post-fight: VICTORY/DEFEAT reveal, then a **"Combat Details"** section below the rewards, collapsed. Tap to expand — keeps the log available for theorycrafters without cluttering the moment.

### 3.2 Portraits become the stage.

- Portraits scale up **~1.4×** (from ~120pt to ~160pt on the fight screen).
- On each exchange, the defender's portrait:
  - Red frame flash (100ms)
  - Shake 4–6pt horizontal (120ms ease-out)
  - Damage number flies up from the hit zone label — rarity-colored (white → yellow → red for normal/crit/lethal), 24pt bold, drifts up 40pt with fade over 600ms
- Crit adds a short gold flare + screen-wide 50ms flash at 15% white overlay.
- Missed attack: grey "MISS" label floats up, no flash.

### 3.3 HP bars with ghost damage.

- Current: instant red drain.
- New: front bar drops instantly; **white "ghost" bar trails behind** and drains over 500ms with ease-out. This is the single highest-ROI visual upgrade — cheap to build, huge perceived polish.

### 3.4 Momentum bar between portraits.

- Thin vertical strip (or horizontal slash) between the two avatars showing "who's winning" — damage differential as a glowing bar that tilts toward the stronger side.
- Purely ornamental but builds tension. Optional — kill if it crowds the layout.

### 3.5 Attack/Defend zone: silhouette not text panel.

- Replace the current flat "Attack HEAD / Defend CHEST" panel with a small warrior silhouette showing the targeted body zone **pulsing in gold** (attack) and the defended zone **pulsing in blue** (defend).
- Still shows the pair ATTACK / DEFEND, but the visual is the silhouette, not two boxes.
- This also teaches new players the hit-zone system visually.

### 3.6 End-of-fight reveal.

Three-beat sequence instead of one flat screen:

1. **Beat 1 (0–400ms):** final hit plays at 0.5× speed (bullet-time). Loser's portrait goes desaturated + drops to 40% opacity.
2. **Beat 2 (400–900ms):** VICTORY (or DEFEAT) banner sweeps in from top — gold for victory, red-grey for defeat. Screen edge gets a vignette.
3. **Beat 3 (900ms+):** rewards panel rises from bottom with stagger. Combat Details accordion (collapsed) sits below.

### 3.7 Skip → highlight reel (optional but huge).

- Instead of cutting to result, Skip plays a **3-second highlight reel** of the top 3 hits + the killing blow. No text.
- Keeps speed for grinders AND preserves the emotional moment. This is the RAID/AFK Arena model.

---

## 4. Layout variants (pick one)

Three options for the **active fight screen** layout. ASCII wireframes.

### Variant A — "Stage" (recommended)

```
┌─────────────────────────┐
│  2:46       ···    📶🔋 │
│                         │
│         YOUR ATTACK     │  ← phase label, top-center
│                         │
│   [ HERO ]     [ ENEMY ]│  ← portraits ~160pt, framed
│    DEGON        BLOOD-  │
│   Lv.17 ⚔      STRIKE   │
│                         │
│  ████████▓░ ░▓█████     │  ← HP bars with ghost trail
│  1,101/1,171    0/378   │
│                         │
│      ╱╲      ╱╲         │  ← silhouette w/ pulsing zones
│   ATTACK    DEFEND      │
│    HEAD      CHEST      │
│                         │
│                         │  ← whitespace, dramatic
│                         │
│  [1X]  [2X]  [SKIP]  🚩 │
│                     📜  │  ← log icon top-right (not shown here)
└─────────────────────────┘
```

**Pros:** clean, cinematic, portraits dominate, HP bars readable, no competing text.
**Cons:** lots of empty vertical space in the middle — could feel thin on small devices.

### Variant B — "Dual HUD"

```
┌─────────────────────────┐
│         YOUR ATTACK     │
│                         │
│  [ HERO ]     [ ENEMY ] │
│   ████████░    ░░████   │
│   1,101       0/378     │
│                         │
│  ─── MOMENTUM ►──────   │  ← momentum bar
│                         │
│    [warrior silhouette] │
│    ATTACK HEAD          │
│    DEFEND CHEST         │
│                         │
│                         │
│  Last hit: -37 CRIT     │  ← single-line "last action"
│                         │
│  [1X] [2X] [SKIP] 🚩 📜 │
└─────────────────────────┘
```

**Pros:** fills vertical space, momentum bar gives context, single "last action" line answers "what just happened" without a scrolling log.
**Cons:** momentum bar adds one more concept — more to explain.

### Variant C — "Immersive" (bold)

```
┌─────────────────────────┐
│                         │
│  [  HERO PORTRAIT  ]    │  ← portrait fills top half
│    DEGON  Lv.17         │     as backdrop
│  ████████▓░  1101/1171  │
│                         │
│ ─────────VS──────────── │  ← divider w/ VS glyph
│                         │
│  [  ENEMY PORTRAIT ]    │  ← portrait fills bottom half
│    BLOODSTRIKE Lv.7     │
│  ░▓████  0/378          │
│                         │
│  ATTACK HEAD • DEFEND   │
│  CHEST                  │
│                         │
│  [1X] [2X] [SKIP] 🚩 📜 │
└─────────────────────────┘
```

**Pros:** maximum drama, feels like a boxing fight card.
**Cons:** breaks from current side-by-side metaphor — bigger dev cost, harder for zone silhouette.

**Recommendation: Variant A.** Lowest risk, highest readability, most compatible with the existing VM/state structure. Variant C is a future direction if we do a v2 combat engine.

---

## 5. Motion choreography (Variant A)

Frame-by-frame (assumes 1x speed):

| t (ms) | Event | Animation |
|---|---|---|
| 0 | Turn start | Phase label fades in (150ms) |
| 100 | Attack zone locks | Gold pulse on silhouette head zone (200ms) |
| 300 | Strike | Attacker portrait shifts +4pt toward enemy (80ms), snaps back |
| 380 | Hit lands | Enemy portrait: red frame flash + shake + damage number flies from "HEAD" label |
| 380 | HP drain | Red bar drops instantly, white ghost trails 500ms ease-out |
| 900 | Phase reset | Phase label for next turn fades in |

**2x speed:** halve all durations.
**Skip:** fade current animation to 10%, play 3 highlight frames at 300ms each, final frame holds into reveal.

All timings tokenized — add to `LayoutConstants` as `combatAttackDuration`, `combatShakeDuration`, `combatHPGhostDuration`.

---

## 6. Post-fight reveal — Variant A

```
┌─────────────────────────┐
│                         │
│       ★ VICTORY ★       │  ← cinematic title, gold, ornamental
│                         │
│  [HERO]        [ENEMY]  │  ← enemy desaturated, 40% opacity
│   DEGON       BLOOD...  │
│                         │
│  ─── REWARDS ────       │
│  +240 XP  +185 gold     │
│  +12 ELO  🎖 Achievement│
│                         │
│                         │
│  ▼ Combat Details       │  ← collapsed accordion (tap to expand)
│                         │
│  [  CONTINUE  ]         │  ← gold CTA w/ ornamentals
└─────────────────────────┘
```

Expanding "Combat Details" reveals the scrolling log exactly as it is today — just gated behind a tap.

---

## 7. Open questions (need Artem's call before Figma)

Two I flagged earlier, restating with assumed defaults:

1. **Keep Attack/Defend zone panel visible during fight?**
   Assumed: yes, replaced with silhouette (Section 3.5). If fight is fully auto after zone selection, we can hide it entirely once combat starts and free up more space.

2. **1x / 2x / Skip pacing stays?**
   Assumed: yes, with Skip enhanced to play highlight reel (Section 3.7). If you want to simplify to just "Auto ▶" toggle + speed slider, that's a different direction.

Three more that came up writing this:

3. **Momentum bar — in or out?** Nice-to-have. Costs UI real estate. Vote: in for Variant B, out for Variant A.
4. **Crit / lethal hit treatments — how loud?** Proposal: crit = gold flare + 50ms white flash. Lethal (killing blow) = 0.5× slow-mo + 300ms red vignette. Too much?
5. **Sound design scope** — do we want new SFX (hit thump, crit ring, ghost-bar whoosh) in this pass, or is this pure visual?

---

## 8. What I'll build once you approve a direction

Phase 1 (Figma, ~2 hrs):
- Active fight frame (chosen variant) in `Hexbound-Design` file, fully tokenized
- End-of-fight reveal frame (victory + defeat states)
- Zone silhouette component for DS
- Motion annotations as Figma comments

Phase 2 (Swift, ~4 hrs):
- HP bar ghost-drain upgrade (`HPBarView` extension)
- Floating damage number component (`FloatingDamageNumber.swift` + pool)
- Portrait frame flash + shake modifiers
- Combat log → collapsible accordion in `BattleResultView`
- Skip highlight reel (if green-lit)

Phase 3 (polish):
- Timing tokens added to `LayoutConstants`
- SFX hooks (if green-lit)
- Balance of motion durations via playtesting

---

## 9. TL;DR

Kill the always-on log. Make the portraits the stage. Floating damage numbers + HP ghost trail + portrait shake = 80% of the wow for 20% of the effort. End-of-fight becomes a three-beat reveal (slow-mo hit → banner → rewards). Skip plays a highlight reel instead of cutting.

**Your call on:**
- Variant A / B / C
- Momentum bar in/out
- Skip: instant vs highlight reel
- SFX in this pass yes/no
