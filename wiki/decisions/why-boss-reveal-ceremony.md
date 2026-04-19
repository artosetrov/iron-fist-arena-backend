---
title: Why Boss Reveal Ceremony
category: decisions
tags: [pve, dungeons, dungeon-rush, ux, ceremony, bosses]
sources: [Hexbound/Hexbound/Views/Components/BossRevealOverlayView.swift, Hexbound/Hexbound/Views/Components/BossRevealData.swift]
updated: 2026-04-19
---

# Why Boss Reveal Ceremony

A short, dramatic root-level overlay introducing a boss the first time the player sees it. Implemented once (`BossRevealOverlayView`) and fired from two surfaces with different cadence — structured Dungeons and Dungeon Rush.

## Problem

Before this, boss encounters had no "moment." The dungeon unlock flow was:

1. Player defeats boss N → quiet return to `DungeonRoomDetailView`
2. Boss N+1 silently flips from `.locked` → `.current`
3. Player taps the new boss card → pushed to `BossDetailSheet` (info screen) → taps `FIGHT BOSS`

There was no beat to mark the new foe as *notable*. Every boss felt like a menu row.

Similarly, Dungeon Rush showed its floor-12 miniboss as just another room card. The run's climax had no weight.

## Decision

One generic ceremony component, two integration points:

| Surface | Trigger | Cadence | CTA behaviour |
|---|---|---|---|
| **Dungeons** | First time a `.current` real-boss card is opened (real-boss = `BossInfo.isRealBoss == true`, excludes Training Camp practice enemies) | **Once per boss** — gated by `UserDefaults["bossRevealSeen_<name>_<id>"]` | Dismisses overlay. Player lands on `BossDetailSheet` and taps `FIGHT BOSS` when ready. |
| **Dungeon Rush** | `currentRoom.type == "miniboss"` when the player reaches that room | **Every run** (miniboss IS the run's climax; runs are rare, rooms randomise) | Dismisses overlay **and** calls `vm.fight()` directly — no extra browse step. |

Both fire via `AppState.presentBossReveal(_:)`. The overlay is mounted once at the HexboundApp root (`zIndex: 170`, between DailyLogin and HeroForge) so it survives NavigationStack pushes and `currentScreen` transitions.

## Why

- **One-goal-per-screen (Dungeons).** Reveal ≠ commit. Showing the boss and asking for a fight commitment in the same moment flattens the beat. Returning to `BossDetailSheet` preserves the info/lore/loot browse step.
- **Tempo (Rush).** Rush runs are short (~5–10 min) and the miniboss is the payoff. A full ~2.2s ceremony per room would front-load latency onto the climax — the compact ~1.2s variant (`BossRevealData.Kind.rushMiniboss`) trims rise/reveal/letter-drop phases in half.
- **Root-level overlay** — per `CLAUDE.md` "Root-Level Overlays" rule. Dungeon Rush in particular pushes `AppRoute.combat` from the same view that triggered the reveal; mounting in-view would tear the overlay down mid-choreography.
- **Once-per-boss cadence** mirrors Genshin Impact / Honkai Star Rail first-encounter splashes. Rerunning the ceremony on every fight entry would become friction.
- **Per-run cadence** mirrors Hades / Slay the Spire — the miniboss reveal IS a run signal, not a character milestone.

## Why NOT

Alternatives considered and rejected:

| Rejected | Reason |
|---|---|
| Replace `BossDetailSheet` with the reveal screen | Conflates browsing with committing. Players need to see loot tables + HP before fighting. |
| Fire on boss unlock (post-victory), not first detail open | Unlock happens mid-result flow with modals already queued. Would stack on top of level-up / victory / claim ceremonies. Lazy-firing on `BossDetailSheet.onAppear` keeps it predictable. |
| Skip for Rush entirely (only Dungeons) | Rush's endgame needs a climax beat. Without it, the `miniboss` room type was visually indistinguishable from `elite`. |
| Fire on every dungeon boss entry | Becomes friction once the player knows the boss. Industry precedent is strongly once-per-boss. |

## DS mapping

All primitives come from the existing Ornamental system. Zero new tokens:

- **Ribbon** — `FiligreeLine` + tracked label in `DarkFantasyTheme.body.weight(.bold)`, accent-coloured
- **Stat chips** — `RadialGlowBackground` + `.innerBorder` + `.cornerDiamonds` + `.compositingGroup()`
- **CTA** — `.buttonStyle(.fight(accent:))` (same style as `BossDetailSheet` sticky fight button)
- **Close** — `.buttonStyle(.closeButton)` (DS chrome exception — SF `xmark` is allowed)
- **Accent** — `DarkFantasyTheme.arenaRankGold` (Dungeons) / `DarkFantasyTheme.purple` (Rush, matching existing miniboss badge colour in `DungeonRushRoomView`)
- **Typography** — `LayoutConstants.textCinematic` (40pt serif black) for the name, `DarkFantasyTheme.body.italic()` for the subtitle
- **Phases** — `MotionConstants.ceremonyPhase*` conventions; no hardcoded durations
- **Mirroring** — `.scaleEffect(x: -1, y: 1)` on the boss image (DS rule — enemies face left)
- **No scale on reveal** — name uses opacity + y-offset (DS animation rule)
- **SFX** — reuses `.dungeonBossAppear` (3 variations, auto-haptic `heavy`) + `.battleStart` on CTA — no new SFX registration needed

## Subtitle source

Dungeons prefer an authored hook over a derived one:

1. `BossInfo.tagline` — backend column `dungeon_bosses.tagline` (nullable, added 2026-04-19 migration). Keep ≤110 chars, one sentence.
2. First sentence of `BossInfo.extendedLore`, trimmed to ≤110 chars (`BossRevealData.shortenLore`) — fallback when tagline is null.

Rush — hardcoded template `"FINAL ROOM · N / M"` (run progress, not boss lore).

No backfill for existing bosses; the fallback path produces acceptable copy while admin authoring catches up. New seeds should populate `tagline` for real bosses (`isRealBoss == true`).

## Cadence & guards

- Dungeons: `UserDefaults["bossRevealSeen_<boss.name>_<boss.id>"]` + in-view `@State hasTriggeredReveal` guard (prevents duplicate fires from re-render).
- Rush: `@State revealedMinibossIdx: Int?` on `DungeonRushDetailView`. Reset on each run — Rush runs are short and the miniboss room index varies per seed.
- Both fires deferred by `MotionConstants.navigationDelay` (0.15s) so the source transition settles first.

## Skip behaviour

Single tap anywhere outside CTA/close short-circuits to the `.ready` phase (chips + CTA visible, no further choreography). Close/× button → `onSkip` → `dismissBossReveal()` on the AppState.

## See Also

- [[dungeons]]
- [[design-principles]] (root overlays, one-goal-per-screen)
- [[design-system]] (Ornamental primitives)
