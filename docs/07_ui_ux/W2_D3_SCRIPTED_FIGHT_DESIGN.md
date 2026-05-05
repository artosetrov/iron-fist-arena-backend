# W2.D3 — Scripted Tutorial Fight: Architecture & Design Doc

**Дата:** 2026-04-10
**Статус:** 📚 HISTORICAL DESIGN DOC — scripted tutorial fight proposal snapshot
**Исходный plan item:** `QA_FIX_PLAN_2026-04-10.md` W2.D3 — *«ONB-01 Tutorial fight (biggest win)»*
**Оценка:** 2 дня (biggest task недели)

> **Status boundary:** historical design doc for the scripted tutorial fight before implementation. The live tutorial/runtime truth has since moved into the codebase and `wiki/features/tutorial.md`; keep this file as design rationale, not active spec.

---

## TL;DR

Scripted tutorial fight — это **самый важный элемент онбординга**. Best practice F2P RPG: игрок должен пережить первую гарантированную победу с эпическим reward'ом до того, как увидит любой meta-game UI (hub, shop, daily login, achievements). Это создаёт «я герой» momentum, который определяет D1 retention больше, чем любой другой фактор.

У нас **уже есть все ингредиенты:**
- Combat engine (`runCombat(attacker, defender, seed)`) — **детерминированный с seed** → это ровно то, что нужно для scripted победы
- Tutorial infrastructure (`TutorialManager`, `TutorialTooltipView`, `TutorialOverlayView`, `NPCSpeechBubble`) — 7 файлов уже существуют
- FTUE система (`FTUEObjective` enum) — переиспользуем структуру
- Combat view (`CombatDetailView` + `CombatViewModel`) — переиспользуем с tutorial mode flag
- Backend routes `/api/tutorial/*` — добавляем новый endpoint

**Нам нужно:**
1. Новый backend endpoint `POST /api/tutorial/scripted-fight`
2. Seed-поиск (offline job): найти seed который гарантированно даёт victory для default Orc Grunt Lv1
3. `tutorialCompleted: Boolean` field на `Character` в Prisma
4. iOS: tutorial mode flag в `CombatViewModel` + hint overlay logic
5. Scripted opponent definition (Orc Grunt stats + equipment)
6. Navigation rewire (уже покрыто W2.D2 Step 4)

**Архитектура — важнейшая часть для «масштабируемый продукт»:**
- Extending `runCombat` с seed-based scripting **не** ломает PvP/PvE — tutorial это просто дополнительный caller с параметром `seed`
- Tutorial mode flag в `CombatViewModel` открывает дверь для **будущих tutorials** (pre-dungeon tutorial, guild tutorial, minigame tutorials) без дублирования combat view
- Scripted opponent catalog через JSON config → легко добавлять новые scripted fights в LiveOps без code deploy

---

## 1. Best practices recap (что мы реплицируем)

Источники: Raid Shadow Legends, AFK Arena, Epic Seven, Rise of Kingdoms (публичные GDC talks + Sensor Tower tear-downs).

### Anatomy of F2P RPG first fight

| # | Step | Duration | Notes |
|---|---|---|---|
| 1 | **Cold-open cinematic** | ≤ 20 sec | Contextualize: «You are in the Arena, an enemy awaits». Skippable. (W2.D2 Cold-Open покрывает это) |
| 2 | **Enemy reveal** | ≤ 3 sec | Зумнутый shot противника, имя + уровень + угрожающая поза |
| 3 | **Hero reveal** | ≤ 3 sec | Camera swings to hero, name badge, class tag |
| 4 | **Mandatory tooltip #1** | — | «Choose your attack zone» — blocking overlay, dimmed background, arrow pointing to stance selector |
| 5 | **Mandatory tooltip #2** | — | «Choose your defense» — blocking overlay, arrow to defense zones |
| 6 | **FIGHT button** | — | Large pulsing gold CTA |
| 7 | **Turn 1 — hero hits** | 3–4 sec | Big damage number, satisfying VFX, enemy takes visible damage |
| 8 | **Turn 2 — enemy hits (glancing)** | 3 sec | Enemy attacks, but damage is low, hero survives «dramatically» |
| 9 | **Turn 3 — finishing blow** | 4 sec | Hero performs crit, enemy defeated, slow-mo optional |
| 10 | **Victory overlay** | 3 sec | «VICTORY» text, confetti/particles, crowd roar SFX |
| 11 | **Reward screen** | 5 sec | +150 gold, +50 XP, +1 common item drop («Your First Weapon!»), level up to Lv2 optional |
| 12 | **Transition to lore** | 1 sec | (W2.D2 lore reorder — shows 6 slides now, while player basks in victory) |

**Total tutorial fight time: 45–60 seconds** (from first tooltip to victory overlay).

### Key constraints

1. **Победа гарантирована.** Ни один random элемент не может нарушить исход. Seed-based determinism — не приятная опция, а требование.
2. **Прогрессия обучения — 2 tooltip'а максимум.** Не пытаемся научить полному stance system, только базовому choose-attack + choose-defense.
3. **Hero damage >> enemy damage.** Player должен увидеть что он **сильный**, не «еле выжил».
4. **Никаких крит-промахов у игрока.** Все его атаки попадают. Все его криты — есть. (Seed control это обеспечивает.)
5. **Scripted, не rigged.** Игрок не должен чувствовать что «игра поддавалась». Visible damage numbers должны казаться честными, просто удачными.
6. **Rewards эпические но не dominanting.** +150 gold + 1 common item достаточно чтобы почувствовать прогресс, но не разваливает balance economy.
7. **Skip exists, но hidden.** Первый tap на hidden zone (top-right corner, 20×20pt invisible button) → confirm dialog → skip to hub. Returning игроки знают.

---

## 2. Что у нас уже есть

### Backend

**`combat.ts:447`:**
```typescript
export async function runCombat(
  attacker: CharacterStats,
  defender: CharacterStats,
  seed?: number
): Promise<CombatResult>
```

**Это gold.** `seed` parameter уже есть. `runCombat` использует `createSeededRng(seed)` (line 131) — детерминированный RNG. Если мы найдём seed, который даёт victory для нашей пары (hero, orcGrunt) — эта пара **всегда** даст тот же исход. Идеально для scripted.

**`pvp/fight/route.ts`** — реальный боевой endpoint. Делает много вещей: rate limit, stamina, ELO, rewards, achievements, battle pass, durability. Для tutorial нужна **упрощённая версия** — без stamina, без ELO, с фиксированными rewards.

### iOS

**`CombatDetailView.swift`** — main combat view, читает `appState.combatData`, передаёт в `CombatViewModel`.
**`CombatViewModel.swift`** — animation scheduler, turn playback.
**`Hexbound/Tutorial/*` + `Views/Tutorial/*` + `Views/Components/Tutorial*`** — 7 файлов tutorial UI.
**`TutorialManager.swift`** — state machine (existing).
**`TutorialOverlayView.swift`** — blocking overlay with pointer.
**`NPCSpeechBubble.swift`** — NPC dialogue.

### Prisma

Нет `tutorialCompleted` на `Character`. Есть FTUE state (через `/api/tutorial/step`), но это не про scripted fight completion.

### FTUE

`FTUEObjective` enum с тремя целями:
- `firstBattle` — «Fight your first opponent in the Arena»
- `gearUp` — «Equip your first item from the Shop»
- `exploreDungeon` — «Complete Floor 1 of the Normal Dungeon»

**Design decision:** scripted tutorial fight **заменяет** FTUE `firstBattle` (конкретно этот objective становится автоматически completed после scripted victory). `gearUp` и `exploreDungeon` остаются как последующие FTUE steps — их игрок выполняет уже в hub'е.

---

## 3. Architecture

### 3.1. Overall component diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                       W2.D2 Cold-Open                          │
│  CinematicOpenView (2 slides, ≤15s, skippable)                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    W2.D3 Scripted Fight                        │
│                                                                 │
│  TutorialFightView (thin wrapper над CombatDetailView)         │
│    ├─ CombatDetailView (reused, via tutorialMode flag)         │
│    ├─ TutorialHintOverlay (reuses TutorialOverlayView)         │
│    │    ├─ Tooltip 1: Choose attack zone                       │
│    │    └─ Tooltip 2: Choose defense zone                      │
│    └─ Skip affordance (top-right 20×20 invisible button)       │
│                                                                 │
│  ViewModel: TutorialFightViewModel                             │
│    ├─ loads opponent from /api/tutorial/scripted-fight/preload │
│    ├─ holds hint state (current_tooltip_index)                 │
│    └─ calls /api/tutorial/scripted-fight/resolve on FIGHT tap  │
│                                                                 │
│  Backend:                                                      │
│    POST /api/tutorial/scripted-fight/preload                   │
│      → returns CombatPreparePayload (hero + scripted_opponent) │
│    POST /api/tutorial/scripted-fight/resolve                   │
│      → runs runCombat(hero, opponent, TUTORIAL_SEED)          │
│      → grants rewards (150 gold, 50 XP, 1 common item)         │
│      → sets character.tutorialCompleted = true                 │
│      → returns CombatResult                                    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Victory Overlay (shared)                      │
│  VictoryOverlayView (new, small ~100 LOC)                      │
│    ├─ «VICTORY» text fade-in                                   │
│    ├─ Reward breakdown (gold, XP, item)                        │
│    └─ «CONTINUE» CTA → .loreIntro                              │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│             LoreIntroView (6 slides, repositioned)            │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│               Daily Login (gated on tutorialCompleted)        │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CityMapView (hub reveal)                   │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2. Backend architecture

#### 3.2.1. Prisma migration

`backend/prisma/schema.prisma`, на `Character` model:

```prisma
model Character {
  // ... existing fields ...
  tutorialCompleted Boolean   @default(false)
  tutorialCompletedAt DateTime?
  // ... rest ...
}
```

**Миграция:**
```bash
cd backend
npm run db:migrate:dev -- --name add_tutorial_completed
cp backend/prisma/schema.prisma admin/prisma/schema.prisma
git add backend/prisma/schema.prisma backend/prisma/migrations admin/prisma/schema.prisma
```

#### 3.2.2. Scripted opponent catalog

**New file:** `backend/src/lib/game/tutorial-opponents.ts`

```typescript
/**
 * Scripted opponents for tutorial fights.
 * These are NOT real Characters in the DB — they're synthetic CharacterStats
 * used only by runCombat(). No persistence, no ratings, no consequences.
 *
 * Extensible: add new entries here for future scripted tutorials
 * (pre-dungeon tutorial, guild tutorial, event tutorials).
 */

import type { CharacterStats } from './combat';

export type ScriptedOpponentKey =
  | 'tutorial_orc_grunt'
  | 'tutorial_dungeon_skeleton'  // future: pre-dungeon tutorial
  | 'tutorial_boss_preview';     // future: chapter boss teaser

export interface ScriptedOpponent {
  key: ScriptedOpponentKey;
  displayName: string;
  character: CharacterStats;
  /** Seed that guarantees hero victory against this opponent (found offline via seed-search). */
  guaranteedVictorySeed: number;
  /** Optional: stance preset to force (for determinism if seed alone isn't enough). */
  forcedStance?: {
    attack: 'head' | 'chest' | 'legs';
    defense: 'head' | 'chest' | 'legs';
  };
}

export const TUTORIAL_OPPONENTS: Record<ScriptedOpponentKey, ScriptedOpponent> = {
  tutorial_orc_grunt: {
    key: 'tutorial_orc_grunt',
    displayName: 'Orc Grunt',
    character: {
      id: 'tutorial_orc_grunt',
      name: 'Orc Grunt',
      class: 'warrior',
      level: 1,
      // Stats chosen to lose against ANY class Lv1 default loadout.
      // Hero base str: 10. Orc base str: 6. Hero maxHp: 100. Orc maxHp: 60.
      str: 6, agi: 4, vit: 6, end: 4, int: 2, wis: 2, luk: 2, cha: 2,
      maxHp: 60,
      currentHp: 60,
      armor: 5,
      magicResist: 2,
      equippedSkills: [],  // no skills — pure basic attacks
      passiveBonuses: undefined,
    },
    guaranteedVictorySeed: 0xDEADBEEF,  // placeholder — replaced by offline seed-search
    forcedStance: { attack: 'head', defense: 'chest' },
  },
  // ... future entries ...
};

export function getScriptedOpponent(key: ScriptedOpponentKey): ScriptedOpponent {
  const opponent = TUTORIAL_OPPONENTS[key];
  if (!opponent) {
    throw new Error(`Unknown scripted opponent: ${key}`);
  }
  return opponent;
}
```

**Why catalog, not hardcoded:** scalability. Future scripted tutorials reuse the same pattern — just add an entry. LiveOps team can extend without touching endpoint code.

#### 3.2.3. Seed search (offline script)

**New file:** `backend/scripts/find-tutorial-seed.ts`

```typescript
/**
 * Offline seed-search: find a seed that guarantees hero victory against
 * each scripted opponent for ALL 4 classes × 5 races × 2 genders × default loadouts.
 *
 * Runs runCombat() with seeds 0..1_000_000, collects seeds where hero wins for ALL
 * permutations, picks lowest.
 *
 * Run: cd backend && tsx scripts/find-tutorial-seed.ts
 */

import { runCombat, initCombatConfig, type CharacterStats } from '../src/lib/game/combat';
import { TUTORIAL_OPPONENTS } from '../src/lib/game/tutorial-opponents';

const CLASSES: CharacterStats['class'][] = ['warrior', 'rogue', 'mage', 'tank'];

async function defaultHeroStats(cls: CharacterStats['class']): Promise<CharacterStats> {
  // Matches OnboardingViewModel default stats for Lv1 fresh character per class
  // ... (read from GameConfig defaults)
  return { /* ... */ } as CharacterStats;
}

async function findSeed() {
  await initCombatConfig();
  const opponent = TUTORIAL_OPPONENTS.tutorial_orc_grunt.character;

  for (let seed = 0; seed < 1_000_000; seed++) {
    let allWin = true;
    for (const cls of CLASSES) {
      const hero = await defaultHeroStats(cls);
      const result = await runCombat(hero, opponent, seed);
      if (result.winnerId !== hero.id) {
        allWin = false;
        break;
      }
      // Also check: turns ≤ 5 (tutorial pacing)
      if (result.totalTurns > 5) {
        allWin = false;
        break;
      }
    }
    if (allWin) {
      console.log(`Found seed: ${seed}`);
      return seed;
    }
  }
  throw new Error('No seed found in range [0, 1000000)');
}

findSeed().catch(console.error);
```

**Why offline:** поиск детерминирован, его не нужно делать на каждый request. Результат — одна константа в `TUTORIAL_OPPONENTS`. Если balance меняется → перезапускаем скрипт, обновляем константу, commit'им.

**Альтернатива (простая):** вместо seed-search взять opponent stats **настолько слабые**, что любой seed даёт victory. Например: orc с 1 HP, 0 damage. Минус: выглядит как «rigged», нет tension. **Я предпочитаю seed search.**

**Edge case:** если для какого-то класса seed не находится в первых 1M → opponent нужно ослабить. Скрипт это диагностирует.

#### 3.2.4. Endpoints

**New file:** `backend/src/app/api/tutorial/scripted-fight/preload/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { getAuthUser } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { loadCombatCharacter } from '@/lib/game/combat-loader';
import { getScriptedOpponent } from '@/lib/game/tutorial-opponents';

/**
 * GET /api/tutorial/scripted-fight/preload?character_id=...
 * Returns player's CombatPreparePayload-shaped response with scripted opponent.
 * Does NOT run the fight. Used by iOS to populate CombatDetailView state.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req);
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const characterId = req.nextUrl.searchParams.get('character_id');
  if (!characterId) return NextResponse.json({ error: 'character_id required' }, { status: 400 });

  const character = await prisma.character.findFirst({
    where: { id: characterId, userId: user.id }
  });
  if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 });
  if (character.tutorialCompleted) {
    return NextResponse.json({ error: 'Tutorial already completed' }, { status: 409 });
  }

  const hero = await loadCombatCharacter(characterId);
  const scripted = getScriptedOpponent('tutorial_orc_grunt');

  return NextResponse.json({
    hero,
    opponent: scripted.character,
    scripted: true,
  });
}
```

**New file:** `backend/src/app/api/tutorial/scripted-fight/resolve/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { getAuthUser } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { rateLimit } from '@/lib/rate-limit';
import { runCombat, initCombatConfig } from '@/lib/game/combat';
import { loadCombatCharacter } from '@/lib/game/combat-loader';
import { getScriptedOpponent } from '@/lib/game/tutorial-opponents';
import { applyLevelUp } from '@/lib/game/progression';

/**
 * POST /api/tutorial/scripted-fight/resolve
 * Body: { character_id, stance: { attack, defense } }
 * Runs scripted tutorial fight with deterministic seed, grants rewards,
 * marks tutorialCompleted.
 *
 * Rewards: 150 gold + 50 XP + 1 common item (scripted drop)
 * Does NOT touch: ELO, stamina, daily quests, achievements, battle pass
 * (those are for real PvP only)
 */
const TUTORIAL_REWARDS = {
  gold: 150,
  xp: 50,
  itemKey: 'wpn_iron_sword_tutorial',  // scripted drop, must exist in item catalog
};

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req);
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  if (!(await rateLimit(`tutorial-fight:${user.id}`, 3, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  const body = await req.json();
  const { character_id } = body;
  if (!character_id) return NextResponse.json({ error: 'character_id required' }, { status: 400 });

  await initCombatConfig();

  return await prisma.$transaction(async (tx) => {
    const character = await tx.character.findFirst({
      where: { id: character_id, userId: user.id }
    });
    if (!character) throw new Error('Character not found');
    if (character.tutorialCompleted) {
      throw new Error('Tutorial already completed');
    }

    const hero = await loadCombatCharacter(character_id);
    const scripted = getScriptedOpponent('tutorial_orc_grunt');

    // Apply hero stance preset for determinism (if not client-provided)
    // ... set combatStance from body or forcedStance ...

    const result = await runCombat(hero, scripted.character, scripted.guaranteedVictorySeed);

    // SANITY CHECK: result must be victory. If not — seed/balance drift detected.
    if (result.winnerId !== hero.id) {
      console.error('[tutorial-fight] Hero lost scripted fight — seed drift!');
      // Fallback: award rewards anyway, mark completed, log for alert
      // Better to ship a slightly-off tutorial than block player entirely
    }

    // Grant rewards
    const updated = await tx.character.update({
      where: { id: character_id },
      data: {
        gold: { increment: TUTORIAL_REWARDS.gold },
        xp: { increment: TUTORIAL_REWARDS.xp },
        tutorialCompleted: true,
        tutorialCompletedAt: new Date(),
      }
    });

    // Level up check (fresh Lv1 → Lv2 with 50 XP assuming xpPerLevel[1] ≤ 50)
    await applyLevelUp(tx, character_id);

    // Grant first-weapon item (scripted drop — always this item for consistency)
    // ... tx.inventory.create({ characterId, itemKey: TUTORIAL_REWARDS.itemKey }) ...

    return NextResponse.json({
      combat: result,
      rewards: TUTORIAL_REWARDS,
      levelUp: true,  // or computed
    });
  });
}
```

**Security notes:**
- `tutorialCompleted` check in both endpoints — prevents re-running for extra rewards
- Rate limit at 3/60s — prevents rapid-fire attempts
- Transaction wraps reward grant + tutorialCompleted flag → atomicity
- No stamina cost, no ELO → tutorial fight doesn't affect real game state
- SANITY_CHECK на seed drift — если balance меняется и seed перестаёт давать victory, логируем и **не блокируем игрока**

### 3.3. iOS architecture

#### 3.3.1. CombatViewModel — add tutorial mode

**Current:**
```swift
@MainActor @Observable
final class CombatViewModel {
    var combatData: CombatData
    // ... animation state ...
    init(appState: AppState, combatData: CombatData) { ... }
}
```

**New:**
```swift
@MainActor @Observable
final class CombatViewModel {
    var combatData: CombatData
    var tutorialMode: TutorialCombatMode?  // nil = normal PvP, non-nil = scripted
    // ... animation state ...

    init(appState: AppState, combatData: CombatData, tutorialMode: TutorialCombatMode? = nil) {
        self.combatData = combatData
        self.tutorialMode = tutorialMode
    }
}

struct TutorialCombatMode {
    let hintSchedule: [TutorialHint]
    let onVictory: () -> Void  // called after turn playback completes

    struct TutorialHint {
        let trigger: HintTrigger
        let anchor: HintAnchor  // which UI element to point at
        let text: String
    }

    enum HintTrigger {
        case onAppear             // show immediately
        case beforeStanceSelect   // before user taps stance
        case beforeFightButton    // after stance chosen, before FIGHT tap
    }

    enum HintAnchor {
        case stanceAttackZones
        case stanceDefenseZones
        case fightButton
    }
}
```

**Why extend existing ViewModel vs new one:** scalability. If we create a separate `TutorialCombatViewModel`, we have to duplicate turn playback, animation scheduling, audio — ~400 LOC. The `tutorialMode: TutorialCombatMode?` flag is a clean extension point: it's ignored in PvP (passed `nil`), activated in tutorial (non-nil). Future tutorials (guild tutorial with scripted PvP, dungeon tutorial with scripted PvE) reuse the same flag.

#### 3.3.2. TutorialFightView — thin wrapper

**New file:** `Hexbound/Hexbound/Views/Tutorial/TutorialFightView.swift`

```swift
import SwiftUI

/// Wraps CombatDetailView with tutorial hint overlays.
/// Exists because CombatDetailView is reused for PvP and scripted — we want
/// tutorial-specific UI (skip button, hint overlays, victory callback) without
/// polluting CombatDetailView.
struct TutorialFightView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var viewModel: TutorialFightViewModel?

    var body: some View {
        ZStack {
            // 1. Existing combat view (reused)
            if let vm = viewModel {
                CombatDetailView()  // reads from appState.combatData
                    .environment(vm.combatViewModel)
            } else {
                LoadingOverlay()
            }

            // 2. Hint overlay (on top)
            if let vm = viewModel, let hint = vm.currentHint {
                TutorialHintOverlay(hint: hint) {
                    vm.advanceHint()
                }
            }

            // 3. Hidden skip affordance (top-right 20×20)
            VStack {
                HStack {
                    Spacer()
                    Color.clear
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                        .onTapGesture { vm?.requestSkip() }
                }
                Spacer()
            }
            .padding()
        }
        .task { await bootstrap() }
        .confirmationDialog(
            "Skip Tutorial?",
            isPresented: Binding(
                get: { viewModel?.skipDialogVisible ?? false },
                set: { viewModel?.skipDialogVisible = $0 }
            )
        ) {
            Button("Skip", role: .destructive) { viewModel?.skip() }
            Button("Continue", role: .cancel) {}
        }
    }

    private func bootstrap() async {
        let vm = TutorialFightViewModel(appState: appState)
        viewModel = vm
        await vm.preload()
    }
}
```

**New file:** `Hexbound/Hexbound/Views/Tutorial/TutorialFightViewModel.swift`

```swift
@MainActor @Observable
final class TutorialFightViewModel {
    var combatViewModel: CombatViewModel?
    var currentHintIndex = 0
    var skipDialogVisible = false
    private let appState: AppState

    private let hints: [TutorialCombatMode.TutorialHint] = [
        .init(trigger: .onAppear, anchor: .stanceAttackZones, text: "Choose where to strike."),
        .init(trigger: .beforeFightButton, anchor: .stanceDefenseZones, text: "And where to defend."),
    ]

    var currentHint: TutorialCombatMode.TutorialHint? {
        guard currentHintIndex < hints.count else { return nil }
        return hints[currentHintIndex]
    }

    init(appState: AppState) {
        self.appState = appState
    }

    func preload() async {
        // GET /api/tutorial/scripted-fight/preload
        // Sets appState.combatData with scripted payload
        // Creates combatViewModel with tutorialMode: TutorialCombatMode
    }

    func advanceHint() {
        currentHintIndex += 1
    }

    func requestSkip() {
        skipDialogVisible = true
    }

    func skip() {
        // POST /api/tutorial/scripted-fight/resolve with skip flag (still grants rewards)
        // Transition to .victoryOverlay
    }
}
```

**New file:** `Hexbound/Hexbound/Views/Tutorial/TutorialHintOverlay.swift`

Небольшой компонент (~80 LOC): dimmed background, spotlight на anchor, speech bubble с текстом, tap anywhere → next. Переиспользует существующие `TutorialOverlayView` и `NPCSpeechBubble`.

**Why split into 3 files:** single-responsibility. View (SwiftUI layout), ViewModel (state + API), Overlay (reusable UI primitive). Future tutorial screens (dungeon tutorial, guild tutorial) reuse `TutorialHintOverlay` as-is.

#### 3.3.3. VictoryOverlayView

**New file:** `Hexbound/Hexbound/Views/Tutorial/VictoryOverlayView.swift`

```swift
struct VictoryOverlayView: View {
    let rewards: TutorialRewards  // gold, xp, itemKey
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            // Radial gradient + particles
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgPrimary,
                glowColor: DarkFantasyTheme.gold,
                glowIntensity: 0.6,
                cornerRadius: 0
            )
            .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Text("VICTORY")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 20)

                rewardRow

                Button("CONTINUE") { onContinue() }
                    .buttonStyle(.primary(enabled: true))
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    private var rewardRow: some View {
        HStack(spacing: LayoutConstants.spaceLG) {
            rewardBox(icon: "icon-gold", value: "+\(rewards.gold)", label: "GOLD")
            rewardBox(icon: "icon-xp", value: "+\(rewards.xp)", label: "XP")
            rewardBox(icon: rewards.itemKey, value: "NEW!", label: "WEAPON")
        }
    }
}
```

~100 LOC, использует DS tokens, nothing fancy.

### 3.4. Navigation integration (ties to W2.D2)

`AppState.swift` получает новые states:

```swift
enum Screen {
    // ... existing ...
    case cinematicOpen(heroName: String)       // W2.D2
    case scriptedTutorial                       // W2.D3 — THIS DOC
    case tutorialVictory(rewards: TutorialRewards)  // W2.D3
    case loreIntro(heroName: String)            // existing, repositioned (W2.D2)
    case dailyLoginModal                        // W2.D5 — future
    case game                                    // existing
}
```

`HexboundApp.swift` routes каждый case к соответствующему view.

**Flow:**
```
OnboardingViewModel.finalizeCreation()
  → .cinematicOpen(heroName)
    → CinematicOpenView (W2.D2)
    → .scriptedTutorial
      → TutorialFightView (W2.D3)
      → .tutorialVictory(rewards)
        → VictoryOverlayView
        → .loreIntro(heroName)  ← repositioned from post-creation to post-victory
          → LoreIntroView (existing, via CinematicSlideView refactor in W2.D2)
          → .dailyLoginModal
            → DailyLoginModalView
            → .game
              → CityMapView (hub reveal)
```

### 3.5. Error & edge case handling

| Case | Handling |
|---|---|
| Network error on preload | Retry with exponential backoff × 3, then offer skip-to-hub with «Couldn't load tutorial» alert. Player still gets rewards on next launch via client-side fallback flag. |
| Network error on resolve | Rewards pending, retry on next launch. `tutorialCompleted` remains false until success. |
| Seed drift (hero loses scripted fight) | Backend logs error, grants rewards anyway, proceeds to victory overlay. Player never sees loss. Alert ops team. |
| Player kills app mid-fight | On relaunch, `tutorialCompleted = false` → restart from cold-open. Rewards not granted (transaction not committed). |
| Player tries to access `/api/pvp/fight` with `tutorialCompleted = false` | Backend blocks with 403 «Complete tutorial first». (Optional — may confuse returning players.) **Decision: DON'T block.** Let them skip to real PvP if they want. |
| Already-completed tutorial (returning player) | `.cinematicOpen` → skip → `.game`. Preload endpoint returns 409, client handles as «already done» → skip. |
| Character created on guest, guest deletes → re-creates | Fresh character, `tutorialCompleted = false` → full tutorial again. Correct behavior. |
| Rate limit exceeded on resolve | 429 → retry with backoff. Should never happen in normal flow (1 attempt per character). |

---

## 4. Implementation plan

### Phase 1: Backend foundation (0.5 day)
1. Prisma migration: `add_tutorial_completed`
2. `schema.prisma` → `admin/prisma/schema.prisma` copy
3. `tutorial-opponents.ts` — catalog with placeholder seed
4. `find-tutorial-seed.ts` — offline script
5. **Run seed search** — populate real seed in catalog
6. Commit: `feat(tutorial): scripted opponent catalog + schema migration`

### Phase 2: Backend endpoints (0.5 day)
7. `POST /api/tutorial/scripted-fight/preload` — hero + opponent payload
8. `POST /api/tutorial/scripted-fight/resolve` — runCombat + rewards + flag
9. Unit test: resolve endpoint grants correct rewards, sets flag, idempotent
10. Unit test: seed search produces seed that yields victory for all 4 classes
11. Commit: `feat(tutorial): scripted fight endpoints`

### Phase 3: iOS — ViewModel & networking (0.5 day)
12. `CombatViewModel` — add `tutorialMode: TutorialCombatMode?` parameter
13. `TutorialFightViewModel` — new file, preload + resolve API calls
14. Network client methods for new endpoints
15. Add to pbxproj

### Phase 4: iOS — Views (0.5 day)
16. `TutorialHintOverlay` — reuses existing `TutorialOverlayView` + `NPCSpeechBubble`
17. `TutorialFightView` — thin wrapper
18. `VictoryOverlayView` — reward screen
19. Add all 3 to pbxproj
20. Agent review: `hexbound-studio:guardian`

### Phase 5: Navigation integration (depends on W2.D2)
21. `AppState.swift` — add new cases
22. `HexboundApp.swift` — add routes
23. Wire `OnboardingViewModel.finalizeCreation()` → `.cinematicOpen`
24. Wire victory → `.tutorialVictory` → `.loreIntro` → `.dailyLoginModal` → `.game`

### Phase 6: Manual QA + agent reviews
25. Artem manual QA: full flow replay × 4 classes × 2 races × 2 genders
26. Agent: `hexbound-studio:flow` — UX timing audit
27. Agent: `hexbound-studio:bladework` — combat tutorial pacing
28. Agent: `hexbound-studio:gauntlet` — QA test plan, exploit check
29. Agent: `hexbound-studio:server` — backend security audit
30. Commit + tag: `feat(w2): scripted tutorial fight complete`

---

## 5. Скоп того, что НЕ входит в W2.D3

Чтобы удержать 2 дня — эти вещи **переносим** или делаем позже:

| Feature | Deferred to | Reason |
|---|---|---|
| Enemy reveal zoom camera | W3 polish | Nice-to-have, not blocking |
| Slow-mo finishing blow | W3 polish | VFX work, requires combat-vfx tuning |
| Hero reveal cinematic | W3 polish | Same |
| Crowd roar SFX | W2.D5 polish | Requires new audio asset |
| Animated «VICTORY» text (letter stagger) | W3 polish | Motion polish |
| Multi-language tutorial hint text | W4+ | l10n not in W2 scope |
| Tutorial replay (testing flag) | W4 dev tool | Admin debug feature |
| Gift a returning-player skip path | W4 | Not blocking first-time users |

---

## 6. Дизайн-вопросы к Артёму (BLOCKING)

1. ✅/❌ **Архитектурный подход** — extend `CombatViewModel` с `tutorialMode` flag vs создавать отдельный `TutorialCombatViewModel`? (Я рекомендую **extend** для переиспользования turn playback logic.)

2. ✅/❌ **Scripted opponent как catalog (`tutorial-opponents.ts`)** vs hardcoded в endpoint? (Рекомендую catalog для scalability.)

3. ✅/❌ **Seed search offline script** vs «очень слабый opponent который любой seed даёт victory»? (Рекомендую seed search — честнее ощущение победы.)

4. **Rewards для tutorial fight:**
   - Предлагаю: 150 gold + 50 XP + 1 common weapon (`wpn_iron_sword_tutorial`)
   - Другие варианты: 200 gold + 100 XP + 1 uncommon, или 100 gold + 50 XP + 2 commons
   - Твой call? Или вызвать `hexbound-studio:vault` для economy review?

5. **Forced level-up to Lv2?**
   - 50 XP возможно прокачивает до Lv2 (зависит от `xpPerLevel[1]`)
   - Argumento PRO: «LEVEL UP!» баннер добавляет dopamine
   - Argumento CONTRA: прыжок с Lv1 на Lv2 обесценивает первый «real» фар
   - Я склоняюсь к **да, принудительный level up до 2** — первая тройка dopamine (victory + reward + level up) стоит этого

6. **Rate limit `/api/pvp/fight` если `tutorialCompleted = false`?**
   - Я предлагаю **НЕ блокировать** — pro users могут хотеть skip tutorial и сразу PvP
   - Tutorial просто не показывается если guest/player уже делал (idempotent)
   - Согласен?

7. **Scripted opponent — Orc Grunt** ок или другой? (Tutorial lore говорит про arenas, dungeons, boss ghoul — может быть «Arena Brawler» более thematic?)

8. **Параллельные агент-ревью** — перед тем как я начну писать код Phase 1, хочешь ли вызвать сейчас `hexbound-studio:architect` + `hexbound-studio:heartbeat` в параллель на этот документ для independent design review? +1 день orchestration, но добавляет valid. Я рекомендую **пропустить** — документ self-contained, агенты скорее всего повторят мои же рекомендации.

---

## 7. Expected impact

| Metric | Current | Target (post W2.D3) |
|---|---|---|
| Time from tap «PLAY AS GUEST» to first victory | ∞ (может быть много неудачных боёв) | **≤ 3 minutes guaranteed** |
| First-session emotional peak | Нет (только character creation + lore) | Scripted victory + rewards + level up |
| D1 retention (hypothesis) | baseline | +10–20% (мой estimate, основной вклад недели) |
| Tutorial completion rate | N/A | ≥ 85% (industry standard для force-sequence tutorials; skip option снижает с 100%) |

---

## 8. Files touched

### New files (iOS)
- `Hexbound/Hexbound/Views/Tutorial/TutorialFightView.swift` (~80 LOC)
- `Hexbound/Hexbound/Views/Tutorial/TutorialFightViewModel.swift` (~150 LOC)
- `Hexbound/Hexbound/Views/Tutorial/TutorialHintOverlay.swift` (~80 LOC)
- `Hexbound/Hexbound/Views/Tutorial/VictoryOverlayView.swift` (~100 LOC)

### New files (backend)
- `backend/src/app/api/tutorial/scripted-fight/preload/route.ts` (~60 LOC)
- `backend/src/app/api/tutorial/scripted-fight/resolve/route.ts` (~120 LOC)
- `backend/src/lib/game/tutorial-opponents.ts` (~80 LOC)
- `backend/scripts/find-tutorial-seed.ts` (~100 LOC, dev-only)

### Modified files (iOS)
- `Hexbound/Hexbound/Views/Combat/CombatViewModel.swift` (+~30 LOC for tutorialMode)
- `Hexbound/Hexbound/App/AppState.swift` (+4 enum cases — shared with W2.D2)
- `Hexbound/Hexbound/App/HexboundApp.swift` (+4 routes — shared with W2.D2)
- `Hexbound/Hexbound.xcodeproj/project.pbxproj` (4 new files × 4 sections = 16 entries)

### Modified files (backend)
- `backend/prisma/schema.prisma` (Character: +tutorialCompleted, +tutorialCompletedAt)
- `backend/prisma/migrations/YYYYMMDD_add_tutorial_completed/migration.sql`
- `admin/prisma/schema.prisma` (copy)

### Documentation
- `docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md` ← this doc
- `docs/03_backend_and_api/API_REFERENCE.md` ← add new endpoints
- `docs/04_database/SCHEMA_REFERENCE.md` ← add new fields
- `docs/07_ui_ux/SCREEN_INVENTORY.md` ← add new views

---

## 9. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Seed search fails to find universal seed | 🟡 Medium | Weaken opponent slightly + re-run. Ultimate fallback: different opponent per class (4 seeds). |
| Balance changes invalidate seed | 🟢 Low | CI guard: unit test runs scripted fight on every PR touching `balance.ts`, fails if hero doesn't win. |
| iOS combatViewModel extension leaks tutorialMode logic into PvP | 🟡 Medium | Code review: `tutorialMode?.X` nil-coalescing everywhere, PvP tests pass `nil`, unit tests verify no behavior change for `tutorialMode == nil` |
| Player finds exploit to run tutorial N times for N × rewards | 🟢 Low | DB-level `tutorialCompleted` flag + transaction + 409 on already-completed |
| Hidden skip button discovered by children, unintentional skip | 🟢 Low | Confirmation dialog before skip |
| 2-day estimate slips | 🟡 Medium | Phase 1–2 are self-contained; if Phase 3–4 slips, W2.D2 Step 4 (navigation rewire) can delay by 1 day without breaking W2.D4/D5 independence |

---

## 10. Dependencies

- **Prerequisite for W2.D4 (building gating):** нужен `tutorialCompleted` flag для первого unlock ceremony triggered at correct moment
- **Prerequisite for W2.D5 (daily login timing):** нужен `tutorialCompleted` flag для gate
- **Shares navigation rewire with W2.D2:** `AppState` enum cases + `HexboundApp` routing добавляются один раз для всего W2

---

## Status

⏳ **Waiting for Artem approval on 8 design questions above.** Ни одной строки кода не написано.

Когда одобришь — я пойду в execution order:
1. W2.D2 Steps 1–3 (CinematicSlideView + LoreIntroView refactor + CinematicOpenView)
2. W2.D3 Phase 1–4 (backend foundation + endpoints + iOS views)
3. W2.D2 Step 4 + W2.D3 Phase 5 (navigation integration — they share enum/routing changes)
4. W2.D4 (building gating)
5. W2.D5 (badges + polish)
6. W2 checkpoint (manual QA + agent reviews + tag)

Реальная оценка **W2 total: 4.5–5 дней** с учётом этого design-first подхода.
