# W2.D2 — REALITY CHECK: Current Cinematic ≠ Original Plan

**Дата:** 2026-04-10
**Статус:** 🛑 Обновление плана — execution paused до подтверждения
**Связанные:** `W2_D2_LORE_AUDIT.md` (обсолет в части архитектуры)

---

## TL;DR

Оригинальный W2.D2 план был написан для `LoreIntroView.swift` (545 LOC, 6 статических slide'ов с текстом). **Этого файла больше не существует.** Текущая реальность:

**`OnboardingCinematicView.swift` — 854 LOC, 3-страничный comic mosaic** с voice narration, BGM per page, typewriter captions, ornamental frames, page curtain transitions. Примерно **~130 секунд** cinematic длительности (хуже чем оценка 60-90 сек).

План «extract `CinematicSlideView` слайд-инфраструктуру» **архитектурно несовместим** с текущим файлом — там нет «slides», там mosaic panels + voice sync engine.

Что остаётся валидным:
- ✅ Концепция: перенести cinematic ПОСЛЕ первой победы (Epic Seven pattern)
- ✅ Идея cold-open mini-intro перед боем для контекста
- ❌ Extract slide infrastructure — не применимо к comic architecture

Рекомендация: **R1 + R2 combo** (reorder + cold-open), **без** R3 (full extraction). Экономим бюджет, минимизируем риск сломать полированную фичу.

---

## Что реально существует (audit)

### `OnboardingCinematicView.swift` — архитектура

Файл: `Hexbound/Hexbound/Views/Auth/OnboardingCinematicView.swift` (854 LOC)

**Структура:**

```swift
private struct ComicPage {
    let title: String              // "WELCOME TO HEXBOUND" / "BLOOD & GLORY" / "YOUR TURN"
    let accentColor: Color         // Gold / Danger / Gold
    let panels: [ComicPanel]       // 3-4 panels per page
    let finalText: String?         // "YOUR TURN." only on page 3
    let bgmTrack: String           // "main-theme.mp3" / "arena-pvp.mp3" / "arena-pvp.mp3"
    let voiceTrack: String?        // 3 voice files, ~15 seconds each
    let panelDurations: [Double]   // Per-panel reveal window, synced to voice
    let finalTextDuration: Double  // YOUR TURN. typewriter duration
}

private struct ComicPanel {
    let area: String          // Grid area name ("city", "arena", "dungeon", etc.)
    let imageAsset: String    // xcassets name (onboarding-city-panorama, etc.)
    let caption: String?      // Typewriter caption text
    let isWide: Bool          // Landscape vs portrait layout
}
```

**3 pages × 3-4 panels = 10 panels total.** Каждый panel — полноэкранный mosaic tile с image asset.

### Текст narration (pages × panels)

**Page 1 — WELCOME TO HEXBOUND (~15 sec, main-theme.mp3 + voice):**
- «HEXBOUND. A city older than regret.»
- «They sell swords, curses, and secondhand potions. No refunds.»
- «"You look like easy money. Welcome."»

**Page 2 — BLOOD & GLORY (~15 sec, arena-pvp.mp3 + voice):**
- «Bakers fight. Priests fight. Even the rats have a ranking.»
- «Win, and they sing songs about you.»
- «Lose, and they sing funnier ones.»
- «Below the city, things get worse. Much worse.»

**Page 3 — YOUR TURN (~12 sec, arena-pvp.mp3 + voice):**
- «Every legend started broke, confused, and slightly terrified.»
- «The difference? They fought anyway.»
- (image-only panel — forge)
- FINAL: «YOUR TURN.»

**Total runtime:** 15 + 15 + 12 + 2.5 (final text) + transitions ≈ **130 seconds** = 2:10 минут cinematic до первого действия.

### Features современного cinematic (что нельзя терять)

1. **Voice narration** — 3 professionally recorded audio files (`onboarding-voice-welcome.mp3`, `onboarding-voice-blood-glory.mp3`, `onboarding-voice-your-turn.mp3`)
2. **BGM switching** — main-theme → arena-pvp для эмоционального сдвига
3. **Typewriter captions synced with voice duration** — `typewriterMsPerChar` вычисляет speed чтобы текст заканчивался одновременно с narration
4. **Comic mosaic layouts** — 3 разных grid recipes, aspectRatio 0.72/0.85/0.72
5. **Ornamental frames** — corner brackets, diamonds, side diamonds с accent color per page
6. **Page curtain transitions** — dramatic dark fade между страницами, не белый flash
7. **Panel reveal flash** — brightness spike + radial glow на каждый reveal
8. **Skip button существует** — line 552-561, всегда доступен (кроме final state)
9. **Swipe gesture** — back/forward между страницами
10. **Tap to reveal / skip typewriter** — user control на каждый panel
11. **YOUR TURN. final beat** — custom typewriter synced to voice narration end
12. **Auto-reveal timer** — если игрок не тапает, panels раскрываются по timer

Это **очень полированная, высококачественная фича**. Refactor риск высокий.

### Текущий flow

```
OnboardingViewModel.finishOnboarding
    → appState.currentScreen = .loreIntro(heroName: character.characterName)
    → HexboundApp switch → OnboardingCinematicView(heroName:)
    → user watches 3 pages (~130s) OR taps SKIP
    → enterGame() → loadGameData() → appState.currentScreen = .game
    → City hub (empty handed, Lv1, no context for what to do)
```

**Проблема:** 130 секунд cinematic **до того** как игрок получил dopamine hit. F2P best practice — dopamine first, narrative second.

---

## Что НЕ работает из оригинального W2.D2 плана

| Оригинальный пункт | Почему не применимо |
|---|---|
| «Extract CinematicSlideView from 545 LOC file» | Файл не 545 LOC а 854. Это не слайды, это comic mosaic + voice sync engine. Extract требует перестроения 5+ подсистем (panel reveal, typewriter, voice sync, BGM, transitions, ornamental frames) |
| «CinematicSlide data struct с title/body/footnote» | Реальная структура — `ComicPage(panels:voiceTrack:bgmTrack:panelDurations:)`. Текст не в header/body формате, он в captions per panel |
| «6 slides с автоадванс» | 3 pages × 3-4 panels = 10 granular interactions, не 6 |
| «~60-90 seconds cutscene» | Реально ~130 seconds. Хуже чем ожидалось |
| «Static text format» | Typewriter + voice sync + flash reveals — динамика, а не текст |

---

## Пересмотренный план — 3 реалистичных опции

### Option R1 — **Reorder only** (RECOMMENDED, минимальный риск)

**Что делаем:**
1. Изменить `OnboardingViewModel.finishOnboarding`:
   ```swift
   // БЫЛО:
   appState.currentScreen = .loreIntro(heroName: character.characterName)
   // СТАНЕТ:
   appState.currentScreen = .scriptedTutorial  // прямо в бой
   ```
2. Добавить новый case в `AppState.Screen`: `.loreIntro(heroName:)` уже есть, добавить `.scriptedTutorial` (из W2.D3)
3. После tutorial victory (`TutorialFightViewModel` completes):
   ```swift
   appState.currentScreen = .loreIntro(heroName: character.characterName)
   ```
4. После cinematic (`OnboardingCinematicView.enterGame()`) → `.game` (как сейчас)

**Результат новый flow:**

```
onboarding wizard (class/appearance/name)
    → scripted tutorial fight (~45 sec, dopamine hit: victory + rewards)
    → level up modal → unlock ceremony (Lv2 → Dungeon)
    → cinematic narrative (~130 sec, now earned context)
    → daily login modal
    → city hub
```

**Плюсы:**
- Zero risk к OnboardingCinematicView (untouched)
- Epic Seven pattern — narrative after first victory
- 30 минут работы
- Все voice/BGM/typewriter фичи сохраняются

**Минусы:**
- Игрок ВСЁ ЕЩЁ сидит 130 секунд через cinematic — просто позже в flow
- Нет контекста перед tutorial fight («кто мой противник и почему мы деремся?»)

### Option R2 — **Reorder + Cold-Open** (RECOMMENDED combo с R1)

**Что делаем дополнительно к R1:**
1. Создать `CombatColdOpenView.swift` — **короткий** (10-15 sec) single-page intro ДО tutorial fight
2. Один screen, 2-3 typewriter captions, БЕЗ voice narration (just ambient SFX)
3. Context: «A grunt challenges you. End him.»

**Skeleton:**

```swift
struct CombatColdOpenView: View {
    @Environment(AppState.self) private var appState
    @State private var phase: Phase = .blackout

    enum Phase { case blackout, opponentReveal, challengeText, continuePrompt }

    var body: some View {
        ZStack {
            // Background — tutorial arena scene
            Image("bg-arena").resizable().scaledToFill().ignoresSafeArea()
                .overlay(Color.black.opacity(0.6))

            VStack(spacing: LayoutConstants.spaceLG) {
                // Opponent silhouette reveals (t=2s)
                if phase >= .opponentReveal {
                    Image("enemy-orc-grunt")
                        .resizable().scaledToFit()
                        .frame(maxHeight: 200)
                        .transition(.opacity)
                }

                // Challenge typewriter (t=4s)
                if phase >= .challengeText {
                    Text("«A grunt challenges you. End him.»")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(LayoutConstants.spaceMD)
                }

                Spacer()

                // Continue (t=8s)
                if phase == .continuePrompt {
                    Button { enterTutorial() } label: {
                        Text("DRAW STEEL").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                    .padding(LayoutConstants.spaceMD)
                }
            }
        }
        .onAppear { startSequence() }
    }
}
```

**Текст опций (выбрать 1):**
1. «A grunt challenges you. End him.»  (mini, 5 слов)
2. «They call him "The First Lesson". Teach him otherwise.»  (7 слов)
3. «Your first fight. His last.» (5 слов)

**Плюсы:**
- Context перед боем (кто, зачем)
- ~10 секунд, не 130
- Отдельный компонент, не трогаем existing cinematic
- Scalable: future tutorials могут переиспользовать `CombatColdOpenView(opponent: character: challengeText:)`

**Минусы:**
- 2-3 часа работы вместо 30 минут
- Лишний beat в flow (cold-open → fight → victory → level up → lore → hub)

### Option R3 — **Full extraction** (NOT RECOMMENDED)

Извлечь всю comic mosaic + voice sync infrastructure в `ComicCinematicPlayer` engine, чтобы future chapter intros / boss cinematics могли переиспользовать.

**Плюсы:**
- True scalability для будущих cinematics

**Минусы:**
- 2+ дня работы
- Высокий риск сломать полированную фичу
- YAGNI — других cinematics в ближайшем roadmap нет
- Engine нужен будет только когда появится вторая cinematic; сейчас преждевременный

**Вердикт: defer до Q3 или когда появится второй use case.**

---

## Моя рекомендация: **R1 + R2**

### Почему combo

- **R1 alone** = reorder без context. Игрок попадает в tutorial fight без понимания «кто, почему, зачем». Dopamine работает (victory), но отсутствует setup для payoff.
- **R2 alone** = cold-open без reorder. Не решает главную проблему 130-sec cinematic перед игрой.
- **R1 + R2 combo** = 10 sec setup → 45 sec action → 130 sec reward → hub. Setup + payoff, narrative earned.

### Estimated time

- R1: 30 минут (navigation reorder)
- R2: 2.5 часа (CombatColdOpenView + pbxproj + navigation hooks)
- **Total: ~3 часа** вместо ~1 дня оригинального W2.D2 плана

### Scope reduction win

Оригинальный W2.D2 план включал extract `CinematicSlideView` (~400 LOC refactor + migration). Новый план: **0 LOC refactor в OnboardingCinematicView**, только 1 новый файл (R2) + 2-line navigation change (R1).

**Сэкономили ~400 LOC refactor риск.** Бюджет перераспределяем на W2.D3 (scripted fight, самая важная фича).

---

## Flow Comparison

### Текущий (проблемный)

```
wizard → 130s cinematic → hub (пустой, confused) → ???
```

### После R1+R2 (рекомендуемый)

```
wizard
  → ~10s cold-open ("A grunt challenges you")
  → ~45s scripted tutorial fight (guaranteed win, hint overlay)
  → victory overlay (rewards: 150g + 50xp + weapon)
  → level up modal (Lv1 → Lv2)
  → unlock ceremony (Dungeon Rush unlocks!)
  → ~130s cinematic (NOW earned: "you won, here's the world you saved from")
  → daily login modal
  → hub (context-rich, dopamine-fed, clear next action)
```

Total time to first interaction: **~55 sec** (down from currently 0 sec to «tap to reveal» но 130 sec to hub).

Total time to hub: **~3 минут 30 сек** (примерно столько же как сейчас), но с **4 dopamine hits** внутри вместо 0.

---

## Impact на другие W2 доки

### W2.D3 (scripted fight) — unchanged

D3 план полностью совместим. W2.D3 Phase 5-6 (iOS TutorialFightView + CombatViewModel extension) остаётся как есть. Navigation integration phase обрабатывает R1 reorder через `.scriptedTutorial` case.

### W2.D4 (building gating) — unchanged

Unlock ceremony работает с новым flow — играется после scripted victory, перед lore cinematic.

### W2.D5 (badge priority) — unchanged

Независимо от cinematic flow.

### Risks

- **Voice file references**: `OnboardingCinematicView` ссылается на 3 voice files. Убедиться что они существуют в bundle (`onboarding-voice-welcome.mp3`, `onboarding-voice-blood-glory.mp3`, `onboarding-voice-your-turn.mp3`). Проверка: `find Hexbound/Hexbound -name "onboarding-voice-*.mp3"`.
- **`AudioManager.shared.stopVoice`**: вызывается в `onDisappear` — при reorder cinematic срабатывает позже, поэтому stopVoice поведение должно оставаться тем же.

---

## Блокирующие вопросы для Artem

1. **R1 + R2 combo OK?** Или только R1 (reorder без cold-open)?
2. **Cold-open text выбор**: (a) «A grunt challenges you. End him.» (b) «They call him "The First Lesson". Teach him otherwise.» (c) «Your first fight. His last.»?
3. **Voice для cold-open**: нужно ли воспроизводить короткий voice clip в cold-open, или хватит typewriter + ambient SFX?
4. **Preserve existing cinematic**: полностью untouched (моя рекомендация) или мелкие правки (например сократить с 3 pages до 2)?

---

## Немедленные действия

1. ✅ **Закрыть** obsolete `W2_D2_LORE_AUDIT.md` секции про extract (пометить как SUPERSEDED)
2. ⏳ **Execute R1** немедленно (30 минут, zero-risk) как только Artem подтвердит choice
3. ⏳ **R2 cold-open** — после R1 + подтверждения текста
4. 🔄 **Parallel**: начать W2.D3 Phase 1-2 (backend foundation) — независимо от D2 решения

Если Artem говорит «делай R1+R2, cold-open текст (a), без voice» — execute весь combo за один проход.
