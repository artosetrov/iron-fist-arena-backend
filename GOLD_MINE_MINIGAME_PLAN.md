# Gold Mine Mini-game — Implementation Plan

**Status:** Phase 1 spec — LOCKED (Variant D)
**Date:** 2026-04-11
**Dependencies:** `GOLD_MINE_MINIGAME_BALANCE_AUDIT.md`, `gold_mine_minigame_prototype.html`
**Target Phase:** 1 (MVP — ship first)

---

## 0. What we're building

A skill-based 15-second mini-game layered on top of `Collect All` in the Gold Mine. Real coin and gem assets fall from the top of the screen, the player taps to collect them, and the server caps and applies the reward authoritatively in `POST /api/gold-mine/minigame-bonus`. The visual language follows the dark-fantasy DS — hero card at the bottom, cap meter at the top, themed shaft backgrounds.

**Variant D — Pick-a-Shaft + Expedition Progress:**

- Each Collect All drills one extraction ($20\%$) into the player's **active shaft**.
- When a shaft hits $100\%$ ($N = 5$ extractions) it is cleared, the picker reopens, and the player commits to a new shaft.
- The active shaft governs mini-game visuals (background, ambient), not the passive economy.
- All three Gold Mine slots keep mining passively regardless of which shaft is active (decision **Z1**).
- After clearing, the player can re-pick any shaft, including the one just cleared (decision **D1** — revisit in Phase 2 if telemetry shows one shaft dominating).
- Phase 1 completion reward: **nothing** (reward is emotional closure + picker unlock).

**NOT in Phase 1:** no sparks, no class bonuses, no leaderboards, no per-shaft drop tables, no completion titles, no left-hand UI affordances. Only the cycle: Collect All → mini-game → server reward → toast → back to screen, with shaft progress incrementing in the background.

---

## 1. Architecture Overview

```
┌────────────────────────────────────────────────┐
│  GoldMineDetailView                            │
│                                                │
│  ┌──────────────────────────────────┐          │
│  │ ActiveShaftBanner (NEW)          │          │
│  │   Ice Vein — 60% — 3 / 5 extr.   │          │
│  └──────────────────────────────────┘          │
│                                                │
│  [Slot 1] [Slot 2] [Slot 3]  (existing)        │
│                                                │
│  [Collect All] ──tap──┐                        │
│                       ▼                        │
│  GoldMineViewModel.collectAll()                │
│  ├── POST /gold-mine/collect-all               │
│  ├── If activeShaft == nil:                    │
│  │     Server returns needs_picker: true       │
│  │     → ShaftPickerSheet                      │
│  │     → POST again with picked_shaft_key      │
│  ├── Server returns:                           │
│  │   { gold, gems, active_shaft,               │
│  │     minigame_session }                      │
│  └── Present GoldMineMiniGameView              │
└────────────────────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────┐
│  GoldMineMiniGameView (NEW)                    │
│   - Shaft background (stone / ice / …)         │
│   - HUD: gold counter + gem counter + timer    │
│   - CapMeterView                               │
│   - Falling drops                              │
│   - MinigameHeroCard at bottom                 │
│   - On timeout / skip:                         │
│     POST /gold-mine/minigame-bonus             │
│     { session_id, caught, spawned,             │
│       gold_claimed_in_session,                 │
│       gems_claimed_in_session, duration_ms }   │
│   - Server returns authoritative reward        │
│   - Result overlay → dismiss → refresh char    │
└────────────────────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────┐
│  If active_shaft.completed_this_call == true:  │
│    ShaftClearedOverlay                         │
│    → picker unlocks on next Collect All        │
└────────────────────────────────────────────────┘
```

**Critical rule:** the client never adds gold/gems on its own. It reports how much it caught, and the server recomputes the reward against the session cap. Violating this rule is a CDO veto.

---

## 2. Backend Changes

### 2.1 Prisma Schema

Two changes: new `MinigameSession` table, and new shaft-state fields on `Character`.

```prisma
model Character {
  // ... existing fields ...

  // Mini-game shaft expedition state (Phase 1: gold mine)
  activeShaftKey  String?  @map("active_shaft_key")
  shaftProgress   Int      @default(0) @map("shaft_progress")
  shaftTotal      Int      @default(5) @map("shaft_total")

  minigameSessions MinigameSession[]
}

model MinigameSession {
  id                 String    @id @default(uuid())
  characterId        String    @map("character_id")
  kind               String    // "gold_mine" in Phase 1
  shaftKey           String    @map("shaft_key")        // "stone" | "ice" | ...
  passiveGoldAmount  Int       @map("passive_gold_amount")
  capGold            Int       @map("cap_gold")
  status             String    @default("pending")       // pending | claimed | expired
  claimedGold        Int?      @map("claimed_gold")
  claimedGems        Int?      @map("claimed_gems")
  caughtCount        Int?      @map("caught_count")
  spawnedCount       Int?      @map("spawned_count")
  createdAt          DateTime  @default(now()) @map("created_at")
  expiresAt          DateTime  @map("expires_at")         // now + 60s
  claimedAt          DateTime? @map("claimed_at")

  character Character @relation(fields: [characterId], references: [id], onDelete: Cascade)

  @@index([characterId, status])
  @@index([expiresAt])
  @@map("minigame_sessions")
}
```

Migration: `cd backend && npm run db:migrate:dev -- --name add_minigame_sessions_and_shaft_state`
Then mandatory: `cp backend/prisma/schema.prisma admin/prisma/schema.prisma` and commit both together.

### 2.2 Shaft Catalog (constant)

```ts
// backend/src/lib/game/shaft-catalog.ts
export type ShaftKey = 'stone' | 'ice';

export const SHAFT_CATALOG: Record<ShaftKey, {
  key: ShaftKey;
  name: string;
  unlockSlotLevel: number;  // requires Gold Mine slot unlocked at this level
  order: number;
}> = {
  stone: { key: 'stone', name: 'Stone Quarry', unlockSlotLevel: 1, order: 0 },
  ice:   { key: 'ice',   name: 'Ice Vein',     unlockSlotLevel: 2, order: 1 },
};

export const SHAFT_TOTAL_EXTRACTIONS = 5;  // Phase 1 locked
```

Phase 1 ships with `stone` + `ice`. Phase 2 adds `lava` and `crystal` with the same pattern.

### 2.3 Endpoints

#### `POST /api/gold-mine/collect-all` (MODIFIED)

Request:
```ts
{
  character_id: string,
  picked_shaft_key?: ShaftKey,  // only required if no active shaft
}
```

Server logic:
```ts
const char = await prisma.character.findUnique({ where: { id: character_id }});
if (!char) return 404;

// 1. Minigame gate: level >= 3
const minigameUnlocked = char.level >= 3;

// 2. Resolve active shaft
let activeShaftKey = char.activeShaftKey;
let shaftProgress = char.shaftProgress;
let shaftTotal = char.shaftTotal;
let needsPicker = false;

if (minigameUnlocked && activeShaftKey === null) {
  if (!picked_shaft_key) {
    // Client must call back with picked_shaft_key
    needsPicker = true;
    const unlockedShafts = getUnlockedShafts(char);  // based on slot level
    return {
      gold_claimed: 0,
      needs_shaft_pick: true,
      unlocked_shafts: unlockedShafts,  // [{ key, name, order }, ...]
    };
  }
  if (!isShaftUnlocked(char, picked_shaft_key)) return 400;
  activeShaftKey = picked_shaft_key;
  shaftProgress = 0;
  shaftTotal = SHAFT_TOTAL_EXTRACTIONS;
  await prisma.character.update({
    where: { id: character_id },
    data: { activeShaftKey, shaftProgress, shaftTotal },
  });
}

// 3. Existing collect logic — aggregates passive from all ready slots
const result = await collectAllSlots(character_id);

// 4. Create MinigameSession (if unlocked)
let minigameSession = null;
if (minigameUnlocked && result.slotsCollected > 0 && activeShaftKey) {
  const session = await prisma.minigameSession.create({
    data: {
      characterId: character_id,
      kind: 'gold_mine',
      shaftKey: activeShaftKey,
      passiveGoldAmount: result.goldGained,
      capGold: Math.floor(result.goldGained * 0.15),
      expiresAt: new Date(Date.now() + 60_000),
    },
  });
  minigameSession = {
    id: session.id,
    shaft_key: activeShaftKey,
    passive_gold_amount: session.passiveGoldAmount,
    cap_gold: session.capGold,
    expires_at: session.expiresAt.toISOString(),
  };
}

// 5. Response (flat shape per feedback_flat_response_shape)
return {
  gold: updatedChar.gold,
  gems: updatedChar.gems,
  gold_claimed: result.goldGained,
  slots_collected: result.slotsCollected,
  minigame_session: minigameSession,
  active_shaft: activeShaftKey ? {
    key: activeShaftKey,
    progress: shaftProgress,
    total: shaftTotal,
  } : null,
};
```

**Note:** shaft progress is incremented in the `minigame-bonus` claim (not in `collect-all`). This keeps the progress tied to the player actually engaging with the mini-game rather than just collecting passively. If the player skips the mini-game, progress does NOT advance — a clean anti-skip-spam design choice.

#### `POST /api/gold-mine/minigame-bonus` (NEW)

Request:
```ts
{
  character_id: string,
  session_id: string,
  caught: number,                   // 0..40
  spawned: number,                  // 15..40
  gold_claimed_in_session: number,  // 0..(spawned × 3)
  gems_claimed_in_session: number,  // 0..3
  duration_ms: number,              // 13000..17000
  skipped: boolean,                 // true if player skipped
}
```

Server logic (pseudo):
```ts
const session = await prisma.minigameSession.findUnique({ where: { id: session_id }});
if (!session || session.characterId !== character_id) return 404;
if (session.status !== 'pending') return 409;
if (session.expiresAt < new Date()) {
  await prisma.minigameSession.update({
    where: { id: session_id },
    data: { status: 'expired' },
  });
  return 410;
}

// Sanity bounds
if (spawned < 15 || spawned > 40) return 400;
if (caught < 0 || caught > spawned) return 400;
if (gold_claimed_in_session < 0 || gold_claimed_in_session > spawned * 3) return 400;
if (gems_claimed_in_session < 0 || gems_claimed_in_session > 3) return 400;
if (duration_ms < 13000 || duration_ms > 17000) return 400;

// Rate limit: 1 claim per 30s per character
const recent = await prisma.minigameSession.findFirst({
  where: {
    characterId: character_id,
    status: 'claimed',
    claimedAt: { gte: new Date(Date.now() - 30_000) },
  },
});
if (recent) return 429;

// Compute authoritative reward
const bonusGold = Math.min(gold_claimed_in_session, session.capGold);
const bonusGems = Math.min(gems_claimed_in_session, 1);  // hard cap: 1 gem/session

// Shaft progress advances only on real plays (not skips)
const character = await prisma.character.findUnique({ where: { id: character_id }});
let newProgress = character.shaftProgress;
let shaftCompletedThisCall = false;
let newActiveShaftKey = character.activeShaftKey;

if (!skipped && caught > 0) {
  newProgress = character.shaftProgress + 1;
  if (newProgress >= character.shaftTotal) {
    shaftCompletedThisCall = true;
    newActiveShaftKey = null;  // picker reopens
    newProgress = 0;
  }
}

// Transactional apply
const [updatedCharacter] = await prisma.$transaction([
  prisma.character.update({
    where: { id: character_id },
    data: {
      gold: { increment: bonusGold },
      gems: { increment: bonusGems },
      shaftProgress: newProgress,
      activeShaftKey: newActiveShaftKey,
    },
  }),
  prisma.minigameSession.update({
    where: { id: session_id },
    data: {
      status: 'claimed',
      claimedGold: bonusGold,
      claimedGems: bonusGems,
      caughtCount: caught,
      spawnedCount: spawned,
      claimedAt: new Date(),
    },
  }),
]);

// Analytics
await logEvent('minigame_gold_mine_claimed', {
  character_id,
  shaft_key: session.shaftKey,
  bonus_gold: bonusGold,
  bonus_gems: bonusGems,
  caught,
  spawned,
  accuracy: spawned > 0 ? caught / spawned : 0,
  hit_cap: gold_claimed_in_session >= session.capGold,
  skipped,
  shaft_cleared: shaftCompletedThisCall,
});

return {
  bonus_gold: bonusGold,
  bonus_gems: bonusGems,
  gold: updatedCharacter.gold,
  gems: updatedCharacter.gems,
  active_shaft: newActiveShaftKey ? {
    key: newActiveShaftKey,
    progress: newProgress,
    total: character.shaftTotal,
  } : null,
  shaft_completed: shaftCompletedThisCall,
};
```

**Files to change:**
- `backend/src/routes/gold-mine.ts` — add handler, modify `collect-all`
- `backend/src/lib/game/gold-mine.ts` — add `createMinigameSession()`, `claimMinigameBonus()`, `getUnlockedShafts()`
- `backend/src/lib/game/shaft-catalog.ts` — **NEW**
- `backend/src/lib/analytics/events.ts` — register `minigame_gold_mine_claimed`

### 2.4 Admin Panel

- Add `minigame_sessions` table to Supabase view
- Dashboard: daily avg accuracy, % hitting cap, gems awarded/day, shaft distribution, skip rate

---

## 3. iOS / SwiftUI Changes

### 3.1 New Files

All new files MUST get 4-section entries in `Hexbound/Hexbound.xcodeproj/project.pbxproj` (project rule). Generate IDs via `openssl rand -hex 12`.

| # | File | Location |
|---|---|---|
| 1 | `MinigameSession.swift` | `Models/` |
| 2 | `ShaftCatalog.swift` | `Models/` |
| 3 | `GoldMineMiniGameView.swift` | `Views/Minigames/` |
| 4 | `FallingDrop.swift` | `Views/Minigames/Components/` |
| 5 | `MinigameHeroCard.swift` | `Views/Minigames/Components/` |
| 6 | `CapMeterView.swift` | `Views/Minigames/Components/` |
| 7 | `ShaftPickerSheet.swift` | `Views/Minigames/Components/` |
| 8 | `ActiveShaftBanner.swift` | `Views/Minigames/Components/` |
| 9 | `ShaftClearedOverlay.swift` | `Views/Minigames/Components/` |

#### `Models/MinigameSession.swift`

```swift
struct MinigameSession: Identifiable, Codable {
  let id: String
  let shaftKey: String
  let passiveGold: Int
  let capGold: Int
  let expiresAt: Date
}

struct ActiveShaft: Codable, Equatable {
  let key: String
  let progress: Int
  let total: Int
  var fraction: Double { total > 0 ? Double(progress) / Double(total) : 0 }
  var isComplete: Bool { progress >= total }
}

struct MinigameResult {
  let bonusGold: Int
  let bonusGems: Int
  let shaftCompleted: Bool
  let newActiveShaft: ActiveShaft?
}
```

#### `Models/ShaftCatalog.swift`

Mirrors backend constant — source of truth is server, this is for UI display only:

```swift
enum ShaftKey: String, CaseIterable, Codable {
  case stone
  case ice
  // case lava   // Phase 2
  // case crystal  // Phase 2

  var displayName: String {
    switch self {
    case .stone: return "Stone Quarry"
    case .ice:   return "Ice Vein"
    }
  }

  var backgroundAssetName: String {
    switch self {
    case .stone: return "minigame-bg-stone"
    case .ice:   return "minigame-bg-ice"
    }
  }

  var thumbAssetName: String {
    switch self {
    case .stone: return "shaft-thumb-stone"
    case .ice:   return "shaft-thumb-ice"
    }
  }

  var unlockSlotLevel: Int {
    switch self {
    case .stone: return 1
    case .ice:   return 2
    }
  }
}
```

#### `Views/Minigames/GoldMineMiniGameView.swift`

Main mini-game screen. Presented via `fullScreenCover` from `GoldMineDetailView` after a successful `collectAll()`.

- Root: `ZStack` with shaft background image at the back, HUD + playfield + hero card stacked above.
- HUD: two `WidgetPill` / `GlassStatPill` instances for gold & gems, `CapMeterView` below, 15s countdown.
- Playfield: `TimelineView(.animation)` drives drop positions. Drop taps resolve via `.onTapGesture` on each `DropView`.
- Anti-scale rule: fall via `.offset(y:)` only, tap feedback via opacity pulse (0.6 → 1.0), never `.scaleEffect`.
- Hero card: `MinigameHeroCard` pinned to bottom with `spaceMD` padding.
- Intro overlay (1.5s): shaft name splash with ornamental title + "Dig!" button.
- Result overlay: reuses `CelebrationBannerView` pattern — bonus gold + gems + cap hit state.
- Skip button top-right: confirms via `SessionExpiredModalView`-style sheet.
- On timeout / skip / success: call `vm.claimMinigameBonus(...)`, await result, show overlay, then `onComplete(result)`.

#### `Views/Minigames/Components/FallingDrop.swift`

```swift
struct FallingDrop: Identifiable, Equatable {
  let id = UUID()
  let kind: Kind
  let startX: CGFloat
  let spawnTime: Date
  let fallDuration: TimeInterval

  enum Kind: String, CaseIterable {
    case coin  // +1 gold, 76% weight
    case bag   // +3 gold, 20% weight
    case gem   // +1 gem, 4% weight

    var goldValue: Int { self == .bag ? 3 : (self == .coin ? 1 : 0) }
    var gemValue: Int { self == .gem ? 1 : 0 }
    var size: CGFloat { self == .bag ? 60 : (self == .gem ? 50 : 42) }
    var assetName: String {
      switch self {
      case .coin: return "icon-gold"
      case .bag:  return "icon-gold"  // scaled larger; Phase 2 swaps to dedicated bag asset
      case .gem:  return "icon-gems"
      }
    }
  }

  static func weightedRandom() -> Kind {
    let roll = Int.random(in: 0..<100)
    if roll < 76 { return .coin }
    if roll < 96 { return .bag }
    return .gem
  }
}
```

Drop-table weights live on the client for visuals, but the server enforces the cap — the reward is always `min(goldClaimed, session.capGold)`.

#### `Views/Minigames/Components/MinigameHeroCard.swift`

Simplified hero card — portrait + name + class tag + level badge + session bonus line. No equipment grid. Visual vocabulary of `IntegratedCharacterCard` (gold border, corner brackets, portrait vignette) but compressed to ~88pt tall.

```swift
struct MinigameHeroCard: View {
  let character: Character
  let activeShaft: ActiveShaft?

  var body: some View {
    HStack(spacing: LayoutConstants.spaceMS) {
      heroPortrait  // 76x76, gold border, CornerBracketOverlay
      VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
        Text(character.name).font(DarkFantasyTheme.cardTitle)
          .foregroundStyle(DarkFantasyTheme.textPrimary)
        HStack(spacing: LayoutConstants.spaceXS) {
          ClassTagView(characterClass: character.characterClass)
          if let shaft = activeShaft, let key = ShaftKey(rawValue: shaft.key) {
            Text(key.displayName)
              .font(DarkFantasyTheme.caption)
              .foregroundStyle(DarkFantasyTheme.textSecondary)
          }
        }
        Text("Session bonus up to +15%")
          .font(DarkFantasyTheme.caption)
          .foregroundStyle(DarkFantasyTheme.goldLight)
      }
      Spacer()
      CardLevelBadge(level: character.level)
    }
    .padding(LayoutConstants.spaceSM)
    .background(
      RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
        .fill(DarkFantasyTheme.bgCardGradient)
        .overlay(
          RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
            .stroke(DarkFantasyTheme.bgCardBorder, lineWidth: 1)
        )
    )
    .overlay(
      CornerBracketOverlay(
        color: DarkFantasyTheme.gold.opacity(0.55),
        length: 14,
        thickness: 1.5
      )
    )
  }
}
```

Phase 1 keeps this as a separate component under `Views/Minigames/Components/`. If a second caller appears, extract to `Views/Components/CompactHeroCard.swift` (rule: extract on the second need, not the first).

#### `Views/Minigames/Components/CapMeterView.swift`

```swift
struct CapMeterView: View {
  let currentGold: Int
  let capGold: Int

  private var fillRatio: Double {
    capGold > 0 ? min(1, Double(currentGold) / Double(capGold)) : 0
  }
  private var hitCap: Bool { currentGold >= capGold }

  var body: some View {
    HStack(spacing: LayoutConstants.spaceSM) {
      Text("Bonus cap")
        .font(DarkFantasyTheme.caption)
        .foregroundStyle(DarkFantasyTheme.textSecondary)
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule().fill(DarkFantasyTheme.bgDeep.opacity(0.4))
          Capsule()
            .fill(hitCap
              ? DarkFantasyTheme.goldHighlightGradient
              : DarkFantasyTheme.goldGradient)
            .frame(width: geo.size.width * fillRatio)
        }
      }
      .frame(height: 4)
      Text("\(currentGold) / \(capGold)")
        .font(DarkFantasyTheme.caption)
        .foregroundStyle(DarkFantasyTheme.goldLight)
        .monospacedDigit()
    }
    .padding(.horizontal, LayoutConstants.spaceMD)
    .padding(.vertical, LayoutConstants.spaceXS)
    .background(Capsule().fill(DarkFantasyTheme.bgCard.opacity(0.9)))
    .overlay(Capsule().stroke(DarkFantasyTheme.bgCardBorder, lineWidth: 1))
  }
}
```

#### `Views/Minigames/Components/ShaftPickerSheet.swift`

Bottom sheet that lists unlocked shafts as 1–3 cards. Single-tap selection. Skipped entirely if only one shaft is unlocked (auto-selects and proceeds).

```swift
struct ShaftPickerSheet: View {
  let unlockedShafts: [ShaftKey]
  let onPick: (ShaftKey) -> Void

  var body: some View {
    VStack(spacing: LayoutConstants.spaceLG) {
      OrnamentalTitle(text: "Choose your shaft", style: .sectionHeader)
      ForEach(unlockedShafts, id: \.self) { key in
        ShaftPickerCard(shaft: key, onTap: { onPick(key) })
      }
    }
    .padding(LayoutConstants.spaceLG)
    .background(DarkFantasyTheme.bgDeep)
  }
}

private struct ShaftPickerCard: View {
  let shaft: ShaftKey
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: LayoutConstants.spaceMD) {
        Image(shaft.thumbAssetName)
          .resizable()
          .interpolation(.high)
          .aspectRatio(contentMode: .fill)
          .frame(width: 72, height: 72)
          .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
          Text(shaft.displayName).font(DarkFantasyTheme.cardTitle)
            .foregroundStyle(DarkFantasyTheme.textPrimary)
          Text("5 extractions to clear")
            .font(DarkFantasyTheme.caption)
            .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        Spacer()
      }
      .padding(LayoutConstants.spaceMD)
    }
    .buttonStyle(.navigation)  // existing Navigation Button style
  }
}
```

#### `Views/Minigames/Components/ActiveShaftBanner.swift`

Top banner in `GoldMineDetailView` showing the player's active shaft.

```swift
struct ActiveShaftBanner: View {
  let shaft: ActiveShaft

  private var shaftKey: ShaftKey? { ShaftKey(rawValue: shaft.key) }

  var body: some View {
    HStack(spacing: LayoutConstants.spaceMD) {
      Image(shaftKey?.thumbAssetName ?? "")
        .resizable()
        .interpolation(.high)
        .aspectRatio(contentMode: .fill)
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
        .overlay(
          RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
            .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1)
        )
      VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
        Text("ACTIVE EXPEDITION")
          .font(DarkFantasyTheme.caption)
          .tracking(1.5)
          .foregroundStyle(DarkFantasyTheme.textSecondary)
        Text(shaftKey?.displayName ?? shaft.key)
          .font(DarkFantasyTheme.cardTitle)
          .foregroundStyle(DarkFantasyTheme.textPrimary)
        ProgressBarView(
          fraction: shaft.fraction,
          height: 6,
          fillStyle: DarkFantasyTheme.goldGradient
        )
        Text("\(shaft.progress) / \(shaft.total) extractions")
          .font(DarkFantasyTheme.caption)
          .foregroundStyle(DarkFantasyTheme.goldLight)
      }
      Spacer()
    }
    .padding(LayoutConstants.spaceMD)
    .background(
      RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
        .fill(DarkFantasyTheme.bgCardGradient)
    )
    .overlay(
      RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
        .stroke(DarkFantasyTheme.bgCardBorder, lineWidth: 1)
    )
    .overlay(
      CornerBracketOverlay(
        color: DarkFantasyTheme.gold.opacity(0.4),
        length: 12,
        thickness: 1
      )
    )
  }
}
```

Note: `ProgressBarView` is assumed to exist as part of the Progress Bars DS component set. If not, this view falls back to a `GeometryReader` + `Capsule` pair like `CapMeterView`.

#### `Views/Minigames/Components/ShaftClearedOverlay.swift`

Displayed once when `shaft_completed == true` in the minigame-bonus response. Opacity-only fade, no scale.

```swift
struct ShaftClearedOverlay: View {
  let clearedShaftKey: String
  let onDismiss: () -> Void

  var body: some View {
    ZStack {
      DarkFantasyTheme.bgDeep.opacity(0.85).ignoresSafeArea()
      VStack(spacing: LayoutConstants.spaceLG) {
        OrnamentalTitle(text: "Shaft Cleared", style: .screenTitle)
        Text(ShaftKey(rawValue: clearedShaftKey)?.displayName ?? clearedShaftKey)
          .font(DarkFantasyTheme.section)
          .foregroundStyle(DarkFantasyTheme.goldLight)
        Text("Pick a new shaft on your next Collect All")
          .font(DarkFantasyTheme.body)
          .foregroundStyle(DarkFantasyTheme.textSecondary)
          .multilineTextAlignment(.center)
        Button(action: onDismiss) {
          Text("Continue").font(DarkFantasyTheme.buttonLabel)
        }
        .buttonStyle(.primary)
      }
      .padding(LayoutConstants.spaceXL)
    }
  }
}
```

### 3.2 Modified Files

#### `Views/GoldMine/GoldMineViewModel.swift`

Add:
- `@Published var activeShaft: ActiveShaft?`
- `@Published var showShaftPicker: Bool = false`
- `@Published var unlockedShaftKeys: [String] = []`
- `collectAll(pickedShaftKey:)` — sends optional key, handles `needs_shaft_pick` response
- `claimMinigameBonus(...)` — POSTs and updates `activeShaft`, returns `MinigameResult`

**CRITICAL:** preserve the existing `init(appState:cache:)` at the top of the file (feedback_observable_init_preservation).

#### `Views/GoldMine/GoldMineDetailView.swift`

- Render `ActiveShaftBanner(shaft: vm.activeShaft)` above the slot cards if `vm.activeShaft != nil`.
- On `Collect All` tap, call `vm.collectAll(pickedShaftKey: nil)`; if response has `needsShaftPick`, present `ShaftPickerSheet` via `.sheet`.
- On picker selection, call `vm.collectAll(pickedShaftKey: picked)` then present `GoldMineMiniGameView` via `.fullScreenCover`.
- On mini-game completion, if `result.shaftCompleted`, present `ShaftClearedOverlay` before refreshing the screen.

#### `Services/APIEndpoints.swift`

```swift
static let goldMineMinigameBonus = "/api/gold-mine/minigame-bonus"
```

### 3.3 Assets

Already in the repo:
- `icon-gold.png` (`figma-assets/04_Icons/`)
- `icon-gems.png` (`figma-assets/04_Icons/`)

**New Phase 1 assets required:**
- `minigame-bg-stone.png` — 1125×2436, dark stone quarry background (Asset Team deliverable)
- `minigame-bg-ice.png` — 1125×2436, icy vein background
- `shaft-thumb-stone.png` — 256×256, square thumb for picker + banner
- `shaft-thumb-ice.png` — 256×256, square thumb for picker + banner

Run `bash scripts/export-assets-for-figma.sh` after adding to sync with Figma placeholders. Drop into `Assets.xcassets/Minigame/` with kebab-case names.

### 3.4 pbxproj Updates

Nine new `.swift` files, each needs 4 entries:
1. `PBXBuildFile` — `{ID1} /* File.swift in Sources */ = {...};`
2. `PBXFileReference` — `{ID2} /* File.swift */ = {...};`
3. `PBXGroup` — add `{ID2}` to the correct group children array
4. `PBXSourcesBuildPhase` — add `{ID1}` to files array

Generate random hex IDs via `openssl rand -hex 12` (never sequential — `feedback_pbxproj_unique_ids`).

Groups:
- `Models/` — MinigameSession.swift, ShaftCatalog.swift
- `Views/Minigames/` — GoldMineMiniGameView.swift
- `Views/Minigames/Components/` — the 7 component files

---

## 4. Figma DS Updates

### 4.1 New Page: `Minigames / Gold Mine`

In `Hexbound-DS` (fileKey `uDjXIz7CdJxcEOI5jCBcjY`). Create ONE page containing all components below.

| Component | Variants | Notes |
|---|---|---|
| **Mini-game HUD Counter** | Gold / Gem | Reuses Counter pattern. Currency icon via `currency/gold` or `currency/gem`. Text style `Body/UI Label`. |
| **Cap Meter** | 0% / 50% / 100% | 3 states. Fill bound to `color/fill/gold`, track to `color/bg/deep`. |
| **Falling Drop** | Coin / Bag / Gem | 3 variants. Each uses `Asset / Icons / icon-gold` or `icon-gems` as fill. |
| **Mini-game Hero Card** | Default | Composition: `ClassTagView` instance + `CardLevelBadge` instance + text styles. Uses `CornerBracketOverlay`. |
| **Shaft Picker Card** | Stone / Ice | 2 variants matching shipped shafts. Each fills its thumb asset. |
| **Active Shaft Banner** | Stone / Ice / Cleared | 3 states. Uses `ProgressBar` instance. |
| **Shaft Cleared Overlay** | Default | Full-frame modal state. Uses `OrnamentalTitle` + `Button` instance. |
| **Start Overlay** | Default | Shaft-name splash, 1.5s. Uses `OrnamentalTitle` + text. |
| **Result Overlay** | Partial / Max Cap / Empty | 3 variants. Follows `CelebrationBannerView` DS pattern. |

All components follow `docs/07_ui_ux/FIGMA_SCREEN_RULES.md`:
- **0** hardcoded colors — every fill via `boundVariables.fills`
- **0** unstyled text — every text node has `textStyleId`
- **0** raw buttons — all buttons are instances from Buttons page
- **0** raw rectangles pretending to be dividers
- Post-creation audit script MUST pass before moving on

### 4.2 Screen Frames (Hexbound-Design)

Add to `10. Gold Mine` page in `Hexbound-Design` (fileKey `PalemJ36B97ZdC0cd8jzv4`):
1. `Gold Mine / Active Shaft (Stone)`
2. `Gold Mine / Active Shaft (Ice)`
3. `Gold Mine / Shaft Picker`
4. `Gold Mine / Mini-game Running (Stone)`
5. `Gold Mine / Mini-game Running (Ice)`
6. `Gold Mine / Mini-game Result (Partial)`
7. `Gold Mine / Mini-game Result (Max Cap)`
8. `Gold Mine / Shaft Cleared`

Every frame built ONLY from DS instances — no frame-pretending-to-be-a-button, no raw text.

---

## 5. Phases & Timeline

### Phase 1 — MVP (target: 5-6 days)

| Day | Work |
|---|---|
| 1 | Prisma schema + migration + admin copy + shaft-catalog + `collect-all` mod + `minigame-bonus` endpoint + server unit tests |
| 2 | iOS models + `GoldMineMiniGameView` skeleton + `FallingDrop` + `CapMeterView` + data flow |
| 3 | iOS: `MinigameHeroCard` + `ShaftPickerSheet` + `ActiveShaftBanner` + `ShaftClearedOverlay` + animations |
| 4 | iOS: `GoldMineDetailView` integration + `GoldMineViewModel` update + pbxproj entries |
| 5 | Figma DS page + components + screen frames + audits + CDO sweep |
| 6 | Agent sign-offs + preflight + deploy |

### Phase 2 — Tuning (post-launch, gated by Ledger)

- Analytics dashboard (daily accuracy distribution, gem velocity, shaft pick distribution, skip rate)
- Downtune gem weight 4% → 2% if velocity dashboard flags
- Add `lava` and `crystal` shafts with art + components
- Introduce per-shaft drop-table modifiers (gold-tilt / gem-tilt / rare-tilt)
- Possible D1 → D2 migration if single-shaft dominance > 70%
- Cosmetic completion titles ("Stone Delver", "Ice Breaker")

### Phase 3 — Expansion (post-tuning)

- Sparks as third currency
- Class bonuses ($+3\%$ accuracy for Rogue, etc.)
- Weekly high-score leaderboard per shaft
- Rare-item chance on clear (requires Vault + Ledger re-audit)

---

## 6. Closed Decisions

All Phase 1 decisions are locked. Changes require a design re-review.

| # | Question | Decision | Why |
|---|---|---|---|
| 1 | Sparks in Phase 1 or 2? | **Phase 2** | One economy at a time |
| 2 | Auto-skip after how many skips? | **5 consecutive** | Industry-standard burnout threshold |
| 3 | Cap indicator — honest or hidden? | **Honest, visible** | Trust > FOMO |
| 4 | Trigger — per slot or per Collect All? | **Per Collect All (1x)** | Avoids 3-game loot burnout |
| 5 | Min level to unlock? | **character.level $\geq$ 3** | Never in tutorial |
| 6 | Expired session behavior? | **Server 410, toast "Session expired"** | Standard REST |
| 7 | Drop tap hitbox? | **52pt minimum square** | Accessibility |
| 8 | Variant A / B / C / D? | **D — Pick-a-Shaft + Expedition Progress** | Adds commitment loop without breaking economy |
| 9 | Extractions to clear a shaft ($N$)? | **5** | ~20 hrs for hardcore, ~40 hrs for casual |
| 10 | Free re-pick or forced rotation after clear? | **D1 — free re-pick** | Respect agency; revisit in Phase 2 |
| 11 | Passive slots during locked shaft? | **Z1 — keep mining** | Zero economy change |
| 12 | Phase 1 completion reward? | **Nothing** | Reward is closure + picker unlock |
| 13 | Shaft progress advances on skip? | **No — only on real plays with caught $>$ 0** | Anti-spam skip-to-clear-faster |
| 14 | Shafts shipped in Phase 1? | **Stone (default) + Ice (unlocks with slot 2)** | MVP minimum |

---

## 7. Agent Sign-off Checklist

Before merge:

1. **hexbound-studio:vault** — approve drop table + cap + expedition meta-loop
2. **hexbound-studio:ledger** — approve gem velocity, shaft clear rate, skip rate
3. **hexbound-studio:heartbeat** — approve core-loop insertion
4. **hexbound-studio:psyche** — approve skip-as-design + commitment loop
5. **hexbound-studio:ascent** — approve expedition progression pacing ($N=5$)
6. **hexbound-studio:fortress** — approve Prisma migration
7. **hexbound-studio:signal** — approve rate limiting + bounds
8. **hexbound-studio:canvas** — approve shaft background art + banner layout
9. **hexbound-studio:ember** — approve shaft names + thematic cohesion
10. **hexbound-studio:screen** — review SwiftUI implementation
11. **hexbound-studio:oracle** — review backend TypeScript
12. **hexbound-studio:guardian** — review design-system compliance
13. **hexbound-studio:gatekeeper** — preflight check before commit
14. **hexbound-studio:herald** — deploy after sign-offs

**CDO Verification (mandatory):** run the grep sweep from CLAUDE.md on invented tokens, hardcoded colors, DS violations, before every commit.

---

## 8. Rollback Plan

Feature-flagged via `MINIGAME_ENABLED` env var.

1. `MINIGAME_ENABLED=false` in backend → `/collect-all` does not create `MinigameSession` and returns `minigame_session: null`, `needs_shaft_pick: false`.
2. iOS fallback: if `minigame_session == nil`, the old collect flow is used (no sheet presented). Banner is hidden.
3. Character shaft state (`activeShaftKey`, `shaftProgress`) is left intact — turning the flag back on resumes cleanly.
4. DB cleanup: cron every hour marks `MinigameSession` with `expiresAt < now - 7d` as `status='expired'`, or deletes if older than 30 days.
5. No schema rollback needed — the new columns / table do not break existing entities.

Zero-downtime rollback window: $< 5$ minutes.

---

## 9. Summary

- **2 backend endpoints** (1 modified, 1 new).
- **1 new table + 3 new Character columns.**
- **9 new SwiftUI files** + **2 modified views** + **1 modified view model** + **1 modified endpoints file**.
- **9 new Figma DS components** on a new `Minigames / Gold Mine` page + **8 new screen frames**.
- **Fully server-authoritative rewards** — zero client calculation.
- **Economy risk:** minimal on gold (+14.8% ceiling), observable on gems (monitor + downtune plan).
- **UX risk:** managed via skip-as-design, auto-skip after 5 consecutive, $N=5$ commitment loop.
- **Total Phase 1 effort:** ~5-6 days.

**Gate:** Artem approved `let's implement` on 2026-04-11 with Variant D defaults (5, D1, Z1, no reward). Starting build from Prisma schema changes.
