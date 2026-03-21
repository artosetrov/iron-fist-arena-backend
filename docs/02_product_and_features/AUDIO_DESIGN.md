# Hexbound — Audio Design

*Sound, music, and SFX design reference. Updated: 2026-03-21*

**Status:** Planning / pre-production. No audio assets exist yet.

---

## Audio Vision

Hexbound's audio should reinforce the grimdark dark fantasy atmosphere without dominating the player's attention. Mobile-first means: short loops, low memory footprint, and respect for players who play on mute (50%+ of mobile gamers).

---

## Music

### Style Reference

- **Primary:** Darkest Dungeon OST — somber, oppressive, chamber-music-like
- **Secondary:** Dark Souls OST — quiet ambience with dramatic boss themes
- **Avoid:** Epic orchestral (too heroic), chiptune/retro (wrong tone), electronic/EDM (wrong genre)

### Track List (Planned)

| Context | Mood | Duration | Loop? | Priority |
|---------|------|----------|-------|----------|
| **Hub/City** | Melancholic, muted, safe but fragile | 60-90s | Yes | High |
| **Arena (Pre-battle)** | Tension, anticipation | 30-45s | Yes | High |
| **Combat (Active)** | Aggressive, rhythmic, dark | 45-60s | Yes | High |
| **Victory** | Brief relief, dark triumph | 5-10s | No (sting) | High |
| **Defeat** | Somber, loss | 5-10s | No (sting) | High |
| **Dungeon** | Dread, exploration, underground | 60-90s | Yes | Medium |
| **Boss** | Intense, dramatic, unique per boss type | 60-90s | Yes | Medium |
| **Shop/Inventory** | Quiet, ambient, non-intrusive | 45-60s | Yes | Low |
| **Menu/Settings** | Minimal, dark ambient | 30s | Yes | Low |

### Music Implementation Notes

- All music tracks should crossfade (0.5-1s) on scene transitions
- Combat music starts on battle init, not on screen load
- Boss music overrides dungeon music
- Player can mute music independently of SFX (Settings screen)
- Music volume defaults to 50% (not 100%)

---

## Sound Effects (SFX)

### Combat SFX (Critical Path)

| Event | Sound Description | Priority |
|-------|-------------------|----------|
| **Physical hit** | Metal clang, sword impact, dull thud | High |
| **Magical hit** | Arcane whoosh, energy burst | High |
| **Poison hit** | Acid sizzle, drip sound | High |
| **Critical hit** | Amplified version of hit type + bone crack | High |
| **Dodge/Miss** | Swoosh, air displacement | High |
| **Block** | Shield clang, heavy thud | High |
| **Heal** | Warm shimmer, soft chime | Medium |
| **Buff applied** | Low hum, power-up tone | Medium |
| **Character death** | Heavy fall, armor clatter | High |

### UI SFX

| Event | Sound Description | Priority |
|-------|-------------------|----------|
| **Button tap** | Soft click, satisfying but not loud | High |
| **Navigation** | Subtle whoosh or page turn | Medium |
| **Gold received** | Coin clink (1-3 coins sound) | High |
| **Gem received** | Crystal chime | High |
| **Level up** | Triumphant short fanfare + shimmer | High |
| **Achievement unlocked** | Distinct notification chime | Medium |
| **Item equipped** | Metal latch, buckle sound | Medium |
| **Item dropped/looted** | Bag rustle, item clatter | Medium |
| **Error/invalid action** | Low dull thud or buzz | Medium |
| **Quest complete** | Scroll unfurl + stamp sound | Medium |

### Dungeon SFX

| Event | Sound Description | Priority |
|-------|-------------------|----------|
| **Floor transition** | Stone grinding, door opening | Medium |
| **Boss entrance** | Deep rumble, dramatic reveal | Medium |
| **Loot chest open** | Lock click, lid creak, sparkle | Medium |
| **Ambient** | Dripping water, distant echoes, wind | Low |

---

## Audio Technical Requirements

### File Format

- **Format:** AAC (.m4a) or CAF (.caf) for iOS
- **Music:** 128-192 kbps, stereo
- **SFX:** 44.1 kHz, mono (spatial audio not needed for 2D combat)
- **Total budget:** ~20-30 MB for all audio (mobile constraint)

### Implementation

- Use AVAudioEngine or native SwiftUI audio APIs
- SFX triggered by combat engine events (damage dealt, dodge, crit, etc.)
- Music managed by a singleton AudioManager service
- Preload combat SFX during battle init (not on-demand)
- Respect system silent mode / ringer switch

### Player Controls (Settings Screen)

| Setting | Default | Range |
|---------|---------|-------|
| Master Volume | 80% | 0-100% |
| Music Volume | 50% | 0-100% |
| SFX Volume | 80% | 0-100% |
| Haptic Feedback | On | On/Off |

---

## Haptic Feedback (iOS)

Mobile-specific — use UIImpactFeedbackGenerator for physical feel:

| Event | Haptic Type | Notes |
|-------|------------|-------|
| **Critical hit landed** | Heavy impact | Most dramatic |
| **Damage taken** | Medium impact | Player feedback |
| **Button tap** | Light impact | Subtle confirmation |
| **Level up** | Success notification | Celebratory |
| **Victory** | Success notification | Reward moment |
| **Defeat** | Error notification | Somber feedback |
| **Gold received** | Soft impact | Satisfying |

---

## Asset Sourcing Strategy

### Options (in priority order)

1. **Royalty-free libraries:** Freesound.org, Sonniss GDC bundles, Zapsplat
2. **AI-generated:** ElevenLabs SFX, Suno for music prototyping
3. **Custom composition:** Hire composer for final music tracks (when budget allows)
4. **Placeholder silence:** Ship without audio before shipping with bad audio

### Budget Estimate

| Category | Approach | Estimated Cost |
|----------|----------|---------------|
| Music (8-10 tracks) | Commission from indie composer | $500-1500 |
| Combat SFX (15-20 sounds) | Royalty-free + light editing | $0-100 |
| UI SFX (15-20 sounds) | Royalty-free + light editing | $0-50 |
| Total | | $500-1650 |

---

## Dependencies

- **Combat engine events** → trigger combat SFX (requires event hooks in `combat.ts` response)
- **UI state changes** → trigger UI SFX (requires AudioManager in SwiftUI views)
- **Settings screen** → volume controls (requires new settings keys in `GameConfig`)
- **Art Style Guide** → audio tone must match visual tone (grimdark, not heroic)

---

## Future Expansion

- **Voice lines:** Short combat grunts per origin/gender (no dialogue)
- **Ambient soundscapes:** Per-location background audio (hub, dungeon, arena)
- **Seasonal audio:** Event-specific music themes (holiday, tournament)
- **Dynamic music:** Layer intensity based on HP threshold during combat
