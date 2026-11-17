# 3D dice throw — design and implementation

> Status: **implemented on iOS, not built in Xcode yet** (2026-11-15). Rules of the duel are unchanged: `DICE_RUNES_DESIGN.md`.
> Prototype (web, same physics): artifact "Hexbound — 3D-бросок костей (прототип)".

## 0. What changed for the player

- The dice lanes are a 3D table (RealityKit). At round start you **hold your dice, shake them and flick them up the table**; the enemy throws from the far end a beat later. Dice bounce off the rims and each other, settle, then slide into the same four slots as before (your strike vs their guard, their strike vs your guard) with the same chips (`HIT ~72 · SWEEP`, `BLOCKED`, `1ST`).
- AUTO throws for you; after 7 idle seconds the table throws by itself (PvP pacing).
- Focus actions are physical: **reroll** = the die jumps and tumbles again (it starts on tap, before the server answers); **set face** = the die lifts and turns over.
- Strikes: the attack die lunges at the guard die; block = a clang and a small wobble, hit = a hard knock.
- Runes: when a rune fires, the face on top flashes.
- Portraits grow into whatever height the table doesn't need (130 → up to 176 pt).
- The table under the dice is the **defender's** (§7).
- Reduce Motion: the 2D lanes, unchanged.

## 1. The server still decides every face

The client never picks a face. A throw is a **baked clip** (§3): recorded poses of all four dice. While a die spins in the air, the visual cube turns *inside its physics box* by one of the 24 rotations that map a cube onto itself, so that the server's face is the one on top when the recorded body settles:

```
q_visual(t) = q_body(t) · slerp(C₀, C, s(t))
```

- `C₀ = q_body(0)⁻¹ · q_now` — the die looks exactly as it did when thrown (in the hand, in the tray).
- `C` — the cube symmetry that maps the server face onto the face the clip lands on; of the four that work, the one whose art reads most upright for the player (`DiceCube.correction`).
- `s(t)` goes 0 → 1 between launch and just before the first impact (0.1–0.45 s). `C` is a cube symmetry, so from the first bounce on the visual box and the physics box coincide again — nothing sinks into the felt.

Checked offline over the whole library, mirrored clips included: 912 / 912 corrections land the requested face (`scripts/dice-throws` + an independent decoder).

Reroll latency: the hop starts on tap with an unknown face; when `/pvp/dice/act` answers, the correction is fixed for the rest of the airtime. If the answer is later than ~0.1 s before the first bounce, the clip waits in the air until it arrives.

## 2. Server face ↔ cube face

Server faces are `0,1 head · 2,3 chest · 4,5 legs`. On the cube (`DiceCube.geoFace`): `+X head, −X chest, +Y chest, −Y legs, +Z legs, −Z head` — a zone never sits opposite itself. Face art = the existing tile (`dice-face-attack` / `dice-face-guard`) + zone emblem + rune stone, flattened per face (`DiceFaceArt`).

## 3. Baked throws

RealityKit can't run a simulation ahead of time, so it ran once, offline, with the same physics as the web prototype:

```
cd scripts/dice-throws && npm install && npm run generate
```

- Output: `Hexbound/Hexbound/Resources/Assets.xcassets/dice-throws.dataset/dice-throws.bin` (≈ 660 KB), read via `NSDataAsset("dice-throws")`.
- Set 0: 108 round throws of all four dice — flick angle 0–35° × speed 5–12.5 × 3 variants. Negative angles = the clip mirrored (x → −x, your attack/guard swap tracks). Every throw settles within 2.5 s, every die flat, inside the felt, not stacked.
- Set 1: 24 reroll hops (one die, starting at rest, drifts ≤ 0.6).
- The client picks the clip nearest to the flick (`DiceThrowLibrary.pickThrow`) and blends the hand position into it over 0.2 s.
- Format (little endian) is documented at the top of `generate.mjs`. Change the table size, die size, tray or hand positions there **and** in `DiceTableScene` together.

## 4. Files

| | |
|---|---|
| `Views/Combat/Dice/Table3D/DiceCube.swift` | face layout, 24 rotations, correction, upright pose |
| `.../DiceThrowLibrary.swift` | dataset parser, clip pick, mirror |
| `.../DiceFaceArt.swift` | face textures from the existing tile / emblem / rune assets |
| `.../DiceTableMat.swift` | table keys, tints, client fallback of the server rule |
| `.../DiceTableScene.swift` | ARView (non-AR), felt, dice, lights, camera fit, playback, hold/flick, hop, set face, lunge, rune flash |
| `.../DiceTable3DView.swift` | SwiftUI host, touch layer, labels / chips / status tags / throw cue, VoiceOver actions |
| `DiceBattleViewModel.swift` | drives the table: `throwOnTable`, hop on reroll, enemy act, lunge, pulse, `tableMat` |
| `DiceBattleView.swift` | 3D vs 2D, layout (table ≈ width × 1.3, portraits take the rest), `DiceEndCard` |
| `Persistence/SFXCatalog.swift` + `Audio/SFX/dice_hit*.wav`, `dice_shake*.wav` | synthesised dice sounds (pass `check_audio_levels.py`) |
| backend `lib/game/dice-tables.ts` | `dice_table` in `/pvp/match/start` |

iOS 17 target → `ARView(cameraMode: .nonAR)`; move to `RealityView` when the target is 18+. SceneKit was soft-deprecated at WWDC25, so it isn't used.

## 5. Not verified yet (no Xcode in the session that wrote it)

- **Build in Xcode.** Syntax checked with a Swift parser; RealityKit/SwiftUI calls checked by hand against the iOS 17 SDK. Expect a couple of fixes on first build.
- **Lighting and materials on device**: key / fill / rim / candle intensities, die metalness, felt tints.
- **Camera framing**: converges over the first frames; a cover hides it until done.
- **Feel**: throw speed mapping (`touchEnded`), idle auto-throw (7 s), lunge timing vs VFX.
- **Performance on an older iPhone**; ARView memory released when the battle screen closes.
- Synthesised SFX — replace with recorded takes if they sound thin.

## 6. QA checklist

1. PvP and bot fight: throw by flick, by AUTO, and by waiting 7 s; the faces on top match the chips and the server log.
2. Reroll (2 Focus) and set face (4 Focus): die hops / turns; network error → the die lands back on its old face.
3. Enemy act events (reroll / set) animate on their dice.
4. Boss phase 2: the second attack die drops in beside the first and lunges.
5. Rune fire flashes the face; status tags (OPEN, FROZEN, STUNNED) sit over the right dice.
6. Reduce Motion on → the 2D lanes.
7. Leave the battle mid-throw → no hang, no leak.
8. iPhone SE, standard, Pro Max: portraits and table sizes.

## 7. Tables (play mats)

The duel is fought on the **defender's** table. The server sends `dice_table` in `/pvp/match/start`; the client falls back to the same rule (`DiceTableMat.resolve`).

Pick order (`backend/src/lib/game/dice-tables.ts`): equipped cosmetic (not built) → dungeon boss / rush miniboss `dragon`, rush room `dungeon` → defender class `warrior` / `rogue` / `mage` / `tank` → `tavern`. `arena`, `frost`, `royal` are kept for cosmetics, seasons and the top league.

Art: `Assets.xcassets/DiceMats/dice-mat-<key>.imageset` (1x 384, 2x 768, 3x 1152 px wide, ≈ 5 MB total). Higgsfield `nano_banana_2_1`, 2K, 2:3, template:

```
Pen and ink illustration of a game table surface: <THEME>, bold black ink outlines on every element, colored with <PALETTE>, sparse ink hatching. Seen from directly above, perfectly flat orthographic top-down view of the whole surface, no perspective, the surface fills the entire frame edge to edge, a decorative border runs along all four edges, a large calm centre area with low detail where game pieces will be placed, nothing lying on the surface, symmetrical layout, mid-dark values, flat even lighting with no cast shadows. Comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles, no dice, no cards, no coins, no hands, no people.
```

Themes and palettes per key: project doc `DICE_3D_THROW_2026-11-15.md` §7. The slot marks and vignette are drawn by code over the mat; pale mats (`tank`, `arena`, `frost`) are dimmed by `DiceTableMat.tint`.
