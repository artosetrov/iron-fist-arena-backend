# Interactive Combat v3 — Implementation Plan

> **Scope:** wire the approved prototype (`combat-proto-B2-v3.html`) into native SwiftUI.
> **Prototype:** `/PVP RPG/combat-proto-B2-v3.html`
> **Target screen:** `InteractiveBattleView`
> **Owner:** client-only changes (no backend / schema work — consumes existing `InteractiveStrikeResponse`)
> **Status:** Implemented in workspace; keep as implementation record. Re-verify against native Swift files before using as an active plan.

---

## 1. What the user sees (recap)

1. **Predict phase** — two fighter cards up top, each with stance-bonus chips (ATK/DEF). Below: 3-zone picker with bonus text on every tile, 3-slot talent rail (padlock asset on empty), streak row, bottom CTA row (Skip + STRIKE + timer arc).
2. **Player taps STRIKE** → picker + talents + streak row fade out; Skip dims, STRIKE morphs into a passive "YOUR CHOICE · ATK CHEST / DEF HEAD" badge. CTA row stays pinned.
3. **Round Result Log slides in** in the space the picker just vacated. Summoner's-style event log:
   - One line per event (player strike / talent fire / opponent strike / status applied / block / dodge)
   - Ally rows flow left→right, enemy rows flow right→left
   - 32×32 asset icon on the outside, styled text on the inside
   - Gold "COUNTER" divider between the player's events and the opponent's
   - Footer: pulsing gold dot + "Next round in 1.8s" (2.4s if talent fired)
4. **Auto-dismiss** after 1.8s — or tap-anywhere-on-card to skip. Log slides out, picker slides back, STRIKE re-enables, round counter +1.

No new server calls. Everything derived from the existing `InteractiveStrikeResponse` payload.

---

## 2. Design system contract

**All new components must pull from `DarkFantasyTheme` + `LayoutConstants` — zero raw literals.**

### 2.1 Tokens consumed

| Role | Token | Value |
|---|---|---|
| Log card background | `DarkFantasyTheme.bgElevated` (or `.bgPanel`) | existing |
| Log card border | `DarkFantasyTheme.gold` | #D4A537 |
| Log card shadow | `Shadow/Modal` effect style | existing |
| Row text | `DarkFantasyTheme.body` (16 Inter) | — |
| Row name emphasis | `DarkFantasyTheme.buttonLabelCompact` (16 Oswald, bold) + side-color | — |
| Damage numbers | Oswald bold 16–17, `.danger` | — |
| Crit numbers | Oswald bold 18, `.gold`, glow | — |
| Shield/heal numbers | Oswald bold 16, `.info` / `.success` | — |
| Muted note (`(-26 armor)`, `matched guard`) | Inter italic 14, `.textSecondary` | — |
| Icon tile background | `.bgSecondary` | — |
| Icon tile border — ally | `.success.opacity(0.45)` | — |
| Icon tile border — enemy | `.danger.opacity(0.45)` | — |
| Icon tile border — talent | `.gold` + glow shadow | — |
| Icon tile border — shield | `.info` | — |
| Icon tile border — effect | warning-ish → use `.gold` (no `warning` token exists) | — |
| Divider line | `.goldDim` gradient transparent → `.goldDim` → transparent | — |
| Divider tag | `.badge` font, `.goldDim`, uppercase | — |
| Footer text | `.caption`, `.textTertiary`, 2px tracking, uppercase | — |

**Spacing:** every `padding`, `VStack spacing`, `HStack spacing` uses `LayoutConstants.space2XS / XS / SM / MS / MD / LG`.
**Radius:** log card = `LayoutConstants.radiusLG` (16). Icon tile = `radiusSM` (8).
**No `Color(hex:)`, no `font(.system(...))`, no raw `16`/`12`.**

### 2.2 Button tokens (STRIKE morph)

- Default STRIKE → unchanged (`PrimaryButtonStyle` — gold gradient + `SurfaceLightingOverlay` + brackets + diamonds + inner border).
- Locked "YOUR CHOICE" state → new button style `LockedStanceButtonStyle`:
  - Fill: `.bgElevated` (dark) with 1px inner stroke in `.gold`
  - Keeps brackets + diamonds ornamental layers at low opacity (0.5) so the "box" silhouette survives
  - No SurfaceLightingOverlay (gold gradient gone)
  - Two-line content: top "YOUR CHOICE" in `.badge` gold; bottom "ATK CHEST · DEF HEAD" with `.danger` / `.info` split
  - `isEnabled = false` → `accessibilityHint("Strike locked — awaiting resolution")`
- Skip button dims to `opacity 0.4` and `isEnabled = false` — no style change, just state.

### 2.3 Assets to use

| Event | Asset (from `Assets.xcassets`) |
|---|---|
| Strike — zone = head | `icon-helmet` |
| Strike — zone = chest | `icon-chest` |
| Strike — zone = legs | `icon-legs` |
| Crit | `fx-crit-text` (or `fx-critical-text`) |
| Dodge | `fx-dodge-text` |
| Miss | `fx-miss-text` |
| Block / shield | `fx-block-hexshield` (generic) |
| Talent — burst_damage | `fx-magical-burst` or `fx-fire-flame` |
| Talent — heal_self | `fx-heal-divine` |
| Talent — shield_self | `fx-block-hexshield` |
| Talent — stun_enemy | `fx-true-lightning` |
| Talent — execute | `fx-physical-explosion` |
| Status — bleed | `fx-physical-slash` (placeholder) |
| Status — poison | `fx-poison-skull` |
| Fatigue / stamina | `icon-stamina` |

All rendered via `CachedAssetImage` (scale-aware), `.interpolation(.high)`, sized to tile 40×40 (inner asset 28×28 with 6pt padding).

---

## 3. File inventory — what exists, what's new

### 3.1 Existing (touch)

| File | Change |
|---|---|
| `Hexbound/Views/Combat/InteractiveBattleView.swift` | Phase-based swap of picker↔log, STRIKE morph wiring, pass exchange payload to log card |
| `Hexbound/Views/Combat/InteractiveBattleViewModel.swift` | Add `currentExchange: RoundExchange?`, populate on reveal, clear on next predict, auto-dismiss timer |
| `Hexbound/Views/Combat/InteractiveCombatComponents.swift` | Already has `StanceBonusChip` (v2). Add zone-picker tile bonus text. Keep log-row components here OR split into own file (recommend split — see 3.2) |
| `Hexbound/Views/Combat/ActiveSkillsHUD.swift` | Replace "plus" SF Symbol for empty slots with `icon-padlock` asset; always render 3 slots |
| `Hexbound/Models/InteractiveStanceBonuses.swift` | Already created — wire into pbxproj |
| `Hexbound/Theme/ButtonStyles.swift` | Add `LockedStanceButtonStyle` variant |

### 3.2 New files (6)

| Path | Role |
|---|---|
| `Hexbound/Models/RoundExchange.swift` | Value type modelling one round's event list, built from `InteractiveStrikeResponse` |
| `Hexbound/Models/CombatLogEvent.swift` | Enum of event kinds (strike, talent, block, dodge, status, etc.) + icon/text builders |
| `Hexbound/Views/Combat/InteractiveRoundLogCard.swift` | Container — gold-bordered card, header + scrollable `LazyVStack` of rows + footer countdown |
| `Hexbound/Views/Combat/CombatLogRow.swift` | Leaf — one row (ally/enemy direction, text, icon tile) |
| `Hexbound/Views/Combat/LogDivider.swift` | "COUNTER" gold gradient divider used between player's events and opponent's |
| `Hexbound/Views/Combat/YourChoiceButton.swift` | Morphed STRIKE state — shown only while `vm.phase` is `.resolving`/`.reveal` |

All 6 new files need pbxproj entries in 4 sections (`PBXBuildFile`, `PBXFileReference`, `PBXGroup`, `PBXSourcesBuildPhase`) with random 24-char hex IDs generated via `openssl rand -hex 12`.

---

## 4. Model layer

### 4.1 `CombatLogEvent`

```swift
enum CombatLogEvent: Identifiable, Sendable {
    case strike(side: Side, zone: InteractiveBodyZone, damage: Int, reducedByArmor: Int, skillName: String?)
    case crit(side: Side, zone: InteractiveBodyZone, damage: Int, skillName: String?)
    case blocked(side: Side, zone: InteractiveBodyZone, absorbed: Int)
    case dodged(side: Side, zone: InteractiveBodyZone)
    case missed(side: Side, zone: InteractiveBodyZone)
    case talentFired(side: Side, actionType: TalentActionType, name: String, magnitude: Double)
    case statusApplied(side: Side, status: StatusEffect, turns: Int)
    case hpTick(side: Side, newHp: Int, maxHp: Int)  // optional, only if meaningful gap

    enum Side: Sendable { case ally, enemy }

    var id: String { /* stable per-event index from array position */ }

    /// Asset name from Assets.xcassets, resolved per event kind + zone/action.
    var assetName: String { /* switch ... */ }

    /// AttributedString with styled name / numbers / muted bits.
    var renderedText: AttributedString { /* build from tokens */ }

    /// Drives icon-tile border color.
    var kind: IconKind { /* dmg | shield | talent | effect | heal */ }
}
```

### 4.2 `RoundExchange`

```swift
struct RoundExchange: Sendable, Identifiable {
    let id: UUID
    let roundNumber: Int
    let allyEvents: [CombatLogEvent]
    let enemyEvents: [CombatLogEvent]
    let talentFired: Bool           // any side — extends auto-dismiss to 2.4s
    let finishingBlow: Bool         // if roundNumber ends the match → skip auto-dismiss, let completion flow take over

    var autoDismissDelay: Duration {
        finishingBlow ? .seconds(3.2) : (talentFired ? .seconds(2.4) : .seconds(1.8))
    }

    /// Factory — turns a server payload into a log.
    static func build(from response: InteractiveStrikeResponse,
                      playerName: String,
                      opponentName: String,
                      playerAttackZone: InteractiveBodyZone,
                      playerDefendZone: InteractiveBodyZone) -> RoundExchange
}
```

**Mapping rules (client-side, display only — NO damage calc):**

| Server field | Event emitted |
|---|---|
| `playerStrike.damage > 0 && !isCrit` | `.strike(.ally, ...)` — skillName from `skillUsed` |
| `playerStrike.isCrit == true` | `.crit(.ally, ...)` |
| `playerStrike.isDodge == true` | `.dodged(.ally, ...)` |
| `playerStrike.isMiss == true` | `.missed(.ally, ...)` |
| `playerStrike.damage == 0 && !isDodge && !isMiss` | `.blocked(.ally, ...)` with absorbed = baseExpected estimate from turn metadata |
| `playerActiveFired != nil && playerActiveLabel != nil` | `.talentFired(.ally, ...)` — inserted between player strike and opponent strike |
| `opponentStrike.*` | symmetric, `.enemy` side |
| `opponentActiveFired != nil` | `.talentFired(.enemy, ...)` — inserted before opponent strike line |

**Status effect detection (post-Phase 3B):** `playerActiveLabel == "burst_damage"` with `magnitude` → synthesize a follow-up `.statusApplied(.enemy, .bleed, turns: N)` row **only if backend confirms** via a separate `appliedStatus` field we'll add later (Phase D — for now, display only direct damage).

### 4.3 `TalentActionType`

Already exists implicitly — see `TalentSlotAction` enum in existing code. Map its cases to asset names and display names inside `CombatLogEvent.assetName` / `.renderedText`.

---

## 5. View layer

### 5.1 `CombatLogRow`

```swift
struct CombatLogRow: View {
    let event: CombatLogEvent
    var staggerDelay: Duration = .zero

    @State private var appeared = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if event.side == .enemy {
                Spacer()
                textBlock
                iconTile
            } else {
                iconTile
                textBlock
                Spacer()
            }
        }
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : (event.side == .enemy ? 8 : -8))
        .task {
            try? await Task.sleep(for: staggerDelay)
            withAnimation(.easeOut(duration: 0.35)) { appeared = true }
        }
    }

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(iconBorderColor, lineWidth: 1)
                )
            CachedAssetImage(name: event.assetName)
                .frame(width: 28, height: 28)
        }
        .frame(width: 40, height: 40)
        .shadow(color: event.kind == .talent ? DarkFantasyTheme.gold.opacity(0.35) : .clear,
                radius: 6)
    }

    private var textBlock: some View {
        Text(event.renderedText)
            .font(DarkFantasyTheme.body)
            .lineLimit(2)
            .multilineTextAlignment(event.side == .enemy ? .trailing : .leading)
    }

    private var iconBorderColor: Color {
        switch event.kind {
        case .damage: return DarkFantasyTheme.danger
        case .shield: return DarkFantasyTheme.info
        case .talent: return DarkFantasyTheme.gold
        case .effect: return DarkFantasyTheme.gold  // (warning token doesn't exist)
        case .heal:   return DarkFantasyTheme.success
        case .neutral:
            return event.side == .ally
                ? DarkFantasyTheme.success.opacity(0.45)
                : DarkFantasyTheme.danger.opacity(0.45)
        }
    }
}
```

### 5.2 `LogDivider`

```swift
struct LogDivider: View {
    let label: String  // "COUNTER"
    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            line
            Text(label)
                .font(DarkFantasyTheme.badge)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.goldDim)
            line
        }
        .padding(.vertical, LayoutConstants.space2XS)
    }
    private var line: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.clear, DarkFantasyTheme.goldDim, .clear],
                startPoint: .leading, endPoint: .trailing))
            .frame(height: 1)
    }
}
```

### 5.3 `InteractiveRoundLogCard`

```swift
struct InteractiveRoundLogCard: View {
    let exchange: RoundExchange
    let onDismiss: () -> Void  // called on tap OR auto-timer fires

    @State private var remainingSeconds: Double
    @State private var timerTask: Task<Void, Never>?

    init(exchange: RoundExchange, onDismiss: @escaping () -> Void) {
        self.exchange = exchange
        self.onDismiss = onDismiss
        _remainingSeconds = State(initialValue: Double(exchange.autoDismissDelay.components.seconds))
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            header
            logList
            footer
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .fill(DarkFantasyTheme.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .stroke(DarkFantasyTheme.gold, lineWidth: 1)
                )
                .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 24)
        )
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .task(id: exchange.id) { startCountdown() }
        .onDisappear { timerTask?.cancel() }
    }

    private var header: some View { /* "Round N · Exchange" */ }
    private var logList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                ForEach(Array(exchange.allyEvents.enumerated()), id: \.offset) { i, ev in
                    CombatLogRow(event: ev, staggerDelay: .milliseconds(i * 120))
                }
                if !exchange.enemyEvents.isEmpty {
                    LogDivider(label: "Counter")
                }
                ForEach(Array(exchange.enemyEvents.enumerated()), id: \.offset) { i, ev in
                    CombatLogRow(event: ev, staggerDelay: .milliseconds((exchange.allyEvents.count + i) * 120 + 240))
                }
            }
        }
        .frame(maxHeight: 300)
    }
    private var footer: some View { /* pulsing dot + "Next round in X.Xs" */ }

    private func startCountdown() { /* Task with 0.1s tick, calls onDismiss when 0 */ }
    private func dismiss() { timerTask?.cancel(); onDismiss() }
}
```

### 5.4 `YourChoiceButton`

```swift
struct YourChoiceButton: View {
    let attackZone: InteractiveBodyZone
    let defendZone: InteractiveBodyZone

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text("YOUR CHOICE")
                .font(DarkFantasyTheme.badge)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            HStack(spacing: LayoutConstants.spaceSM) {
                Text("ATK \(attackZone.rawValue.uppercased())")
                    .foregroundStyle(DarkFantasyTheme.danger)
                Text("·").foregroundStyle(DarkFantasyTheme.textTertiary)
                Text("DEF \(defendZone.rawValue.uppercased())")
                    .foregroundStyle(DarkFantasyTheme.info)
            }
            .font(DarkFantasyTheme.buttonLabelCompact)
            .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: LayoutConstants.buttonHeightLG)  // 56
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                .fill(DarkFantasyTheme.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .stroke(DarkFantasyTheme.gold, lineWidth: 2)
                )
        )
        // Keep ornamental brackets at reduced opacity so the CTA footprint
        // reads the same as the live STRIKE button.
        .overlay(CornerBrackets().opacity(0.5))
        .overlay(CornerDiamonds().opacity(0.5))
    }
}
```

### 5.5 `InteractiveBattleView` — phase-based swap

```swift
// Inside the existing VStack, right where InteractivePredictView lives today:

ZStack(alignment: .top) {
    if vm.phase.isPredicting {
        InteractivePredictView(vm: vm)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal:   .opacity.combined(with: .move(edge: .top))
            ))
    } else if let exchange = vm.currentExchange {
        InteractiveRoundLogCard(exchange: exchange) { vm.dismissExchange() }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal:   .opacity.combined(with: .move(edge: .top))
            ))
    }
}
.animation(.easeInOut(duration: 0.3), value: vm.phase)
.animation(.easeInOut(duration: 0.3), value: vm.currentExchange?.id)

// CTA row — unchanged structure, morph the STRIKE content:

HStack(spacing: LayoutConstants.spaceSM) {
    SkipButton(...)
        .disabled(!vm.phase.isPredicting)
        .opacity(vm.phase.isPredicting ? 1 : 0.4)

    ZStack {
        if vm.phase.isPredicting {
            TimerRingStrikeButton(...)  // existing
        } else {
            YourChoiceButton(
                attackZone: vm.selectedAttackZone,
                defendZone: vm.selectedDefendZone
            )
        }
    }
}
```

### 5.6 Zone-picker tile bonus text (v2 debt)

In `InteractivePredictView` zone-picker rows (`zoneTile` function): add a second text line per tile showing `InteractiveStanceBonuses.attackBonusText(for: zone)` or `.defendBonusText(for: zone)`. Icon moves from SF Symbol `brain.head.profile` / `heart.fill` / `figure.walk` → asset `InteractiveStanceBonuses.assetName(for: zone)` (already in the enum).

---

## 6. ViewModel layer — `InteractiveBattleViewModel`

Additions (all `@Published` free — we're on `@Observable`):

```swift
// Current round's log. Nil during .predict, populated at .reveal, cleared when
// user taps-to-skip or auto-timer fires.
var currentExchange: RoundExchange?

// Called by InteractiveRoundLogCard on tap/auto-dismiss.
func dismissExchange() {
    currentExchange = nil
    advanceToNextRound()  // existing transition to .predict
}

// Inside the existing strike-response handler, right after HP animation kicks off:
self.currentExchange = RoundExchange.build(
    from: response,
    playerName: self.playerProfile.name,
    opponentName: self.opponentProfile.name,
    playerAttackZone: self.selectedAttackZone,
    playerDefendZone: self.selectedDefendZone
)
```

The phase machine itself does **not** change — `currentExchange` is an independent field set alongside `.reveal`. The view keys off `phase.isPredicting` to pick picker-vs-log, and `currentExchange != nil` to supply the data.

---

## 7. Animation contract

**Rules (per `feedback_no_scale_animations`):**

- NO `.scaleEffect` grow/shrink. Only opacity + translate.
- Row stagger: `easeOut 0.35s` with 120ms delay per row, + 240ms delay before the "COUNTER" divider.
- Picker ↔ log transition: `easeInOut 0.3s`, combined `.opacity + .move(edge:)` (picker exits up, log enters from below).
- STRIKE → YOUR CHOICE: no transform tween — just swap via `ZStack { if ... }`, both lay out to same frame so no layout jump.
- Icon tile shadow (talent): pre-rendered, no animation.
- Footer pulsing dot: opacity 0.3 ↔ 1.0, 1s cycle, `.easeInOut`.

---

## 8. Edge cases & guardrails

| Case | Handling |
|---|---|
| Match ends this round (`matchFinished == true`) | Still show the log (3.2s delay) so the player sees the killing blow, then let `completing` phase navigate to result screen. |
| Opponent strike is `nil` (shouldn't happen server-side but possible in degraded mode) | Omit enemy section entirely — log shows only player side + divider skipped. |
| Network error mid-strike (existing `.error` phase) | Log card never renders; picker stays visible; error banner owns the screen (no change). |
| Player taps STRIKE twice fast | Existing `phase.isBusy` gate already prevents it — YOUR CHOICE button has `.disabled = true` as defensive redundancy. |
| User force-quits during reveal | `timerTask` cancels in `onDisappear` at screen level (not log-card level — per `feedback_task_cancel_lifetime`). |
| Talent fires but damage is 0 (stun) | Render talent row with `(stunned)` muted tag, no number. |
| Both sides fire talents same round | Two talent rows, one in each section. |
| Round result log overflows the swap area | `ScrollView` inside log card (max-height 300). Unlikely in practice — typical round = 2–4 rows. |

---

## 9. Implementation phases

### Phase A — Models (no UI yet)
1. Create `Hexbound/Models/CombatLogEvent.swift`.
2. Create `Hexbound/Models/RoundExchange.swift` with `build(from:)` factory.
3. Add pbxproj entries (4 sections each, random 24-char IDs).
4. Compile-check: `grep` for `scripts/check_schema_drift.py` not applicable here; just build.
5. **Gate:** project builds, unit-level mental trace of `build(from:)` against a sample payload.

### Phase B — Leaf views
1. Create `Hexbound/Views/Combat/CombatLogRow.swift`.
2. Create `Hexbound/Views/Combat/LogDivider.swift`.
3. Create `Hexbound/Views/Combat/YourChoiceButton.swift`.
4. Add pbxproj entries.
5. Each file ends with a `#Preview` showing one ally row, one enemy row, one crit, one dodge, one talent.
6. **Gate:** previews render cleanly in Xcode preview canvas; every token resolves (no `textPrimary` vs `.textPrimary` slips).

### Phase C — Container
1. Create `Hexbound/Views/Combat/InteractiveRoundLogCard.swift`.
2. `#Preview` with a mock `RoundExchange` covering: 1 crit ally strike, 1 talent fire, 1 enemy block, 1 enemy status-applied.
3. **Gate:** tap gesture dismisses; timer countdown ticks; auto-dismiss fires at 1.8s; respects talent extension.

### Phase D — Wire into `InteractiveBattleView`
1. Add `currentExchange` to VM + populate in strike-response handler + `dismissExchange()`.
2. Swap `InteractivePredictView` → `ZStack { if ... } else if ... }` block.
3. Swap STRIKE button inline → `ZStack { TimerRingStrikeButton | YourChoiceButton }`.
4. Dim Skip when not `.isPredicting`.
5. **Gate:** full round cycle in simulator against a dev account. Verify: picker → STRIKE → YOUR CHOICE morph → log appears with stagger → tap dismisses → picker returns → round number increments.

### Phase E — Zone-picker bonus text + always-3-talent-slots
1. `InteractivePredictView` zone tiles: swap SF Symbol for asset (`InteractiveStanceBonuses.assetName(for:)`); add `Text(attackBonusText(for:zone))` beneath the zone label with `DarkFantasyTheme.caption`.
2. `ActiveSkillsHUD`: replace `Image(systemName: "plus")` for empty slot with `CachedAssetImage(name: "icon-padlock")`. Ensure the slot frame renders at index 2 even when `playerActives.count < 3`.
3. **Gate:** visual diff against `combat-proto-B2-v3.html` on 390×844 iPhone 15 Pro simulator.

### Phase F — Stance chip stack (v2 debt cleanup)
1. Verify `StanceBonusChipStack` (already added in prior session) renders correctly on both fighter cards.
2. Ensure `opponentAttackChipMode` / `opponentDefendChipMode` flip from `.predicted` → `.confirmed` on reveal and back to `.predicted` on next predict.
3. **Gate:** observe full round — chip on enemy card transitions smoothly (no layout shift) from amber/dashed → solid/green.

### Phase G — pbxproj + CDO verification
1. Confirm all 6 new files + `InteractiveStanceBonuses.swift` have pbxproj entries in all 4 sections.
2. Run all CDO scan commands from `CLAUDE.md` §CDO Verification:
   ```bash
   # Invented font tokens / spacing tokens / hardcoded colors / hardcoded radii /
   # merge markers / schema drift / SF symbols where assets expected
   ```
3. Run `bash scripts/preflight_check.sh` if available.
4. **Gate:** `CDO: CLEAN`.

### Phase H — Commit
1. Stage all 7 files + pbxproj + `InteractiveBattleView.swift` + VM + `ActiveSkillsHUD.swift` + `InteractivePredictView` tile changes + `ButtonStyles.swift` (LockedStanceButtonStyle).
2. Commit via `.git-trigger` (NEVER direct commit from sandbox — `feedback_deploy_via_tmp_clone`).
3. Commit message: `feat(combat): interactive round log + YOUR CHOICE morph (v3)`

---

## 10. Estimated scope

| Phase | Files touched | LOC est. | Complexity |
|---|---|---|---|
| A — Models | +2 new, pbxproj | ~180 | Low (pure data) |
| B — Leaf views | +3 new, pbxproj | ~260 | Medium (token discipline) |
| C — Container | +1 new, pbxproj | ~140 | Medium (timer lifecycle) |
| D — Integration | 2 existing | ~90 diff | High (phase machine) |
| E — Picker + slots | 2 existing | ~60 diff | Low |
| F — Chip stack verify | 1 existing | ~30 diff | Low |
| G — CDO + pbxproj | — | — | Low |
| **Total** | **6 new + 5 touched + pbxproj** | **~760** | **Medium** |

One focused session, ~2–3h of coding + ~1h of in-simulator polish.

---

## 11. Out of scope (deferred)

- **Status-applied rows from backend** (bleed/poison turn counts) — requires backend to emit `appliedStatus` field in strike response. Currently inferred heuristically; full accuracy = separate backend PR.
- **HP-tick rows** (`HP 864 → 644`) — considered and dropped; redundant with the damage row + portrait HP bar animation. Can revisit after play-testing.
- **Sound design for log-row stagger** — defer to SFX pass.
- **Localization of log text** — hardcoded English in Phase D. Add `L10n` strings in a follow-up once the schema stabilizes.
- **Variable-speed auto-dismiss based on player preference** — settings toggle for "fast log / normal log / manual-only" — future enhancement.

---

## 12. Risks

| Risk | Mitigation |
|---|---|
| AttributedString token styling too fragile in SwiftUI | Fall back to `HStack` of `Text` spans inside the row if `AttributedString` color-per-run gets flaky on iOS 17 |
| Icon tile 40×40 too large vs. prototype visual weight | Easy polish — revert to 32×32 with 4pt padding if it crowds the row |
| Log card max-height 300 clips on small devices | Use `maxHeight: UIScreen.main.bounds.height * 0.35` clamped to 300 ceiling |
| Phase machine double-fires `dismissExchange` (auto-timer + tap) | Guard: `guard currentExchange != nil else { return }` inside the VM method |
| Ornamental brackets at 50% opacity look dirty on YOUR CHOICE | Prototype in preview first; drop to 30% or hide entirely if so |

---

## 13. Approval checklist before writing code

- [ ] User reviewed + approved `combat-proto-B2-v3.html` (done — latest message)
- [ ] User approves this plan (pending)
- [ ] Confirmed no backend changes in scope
- [ ] Confirmed token list (§2.1) is accurate against `DarkFantasyTheme` (spot-checked: `.bgElevated` exists; `.goldDim` exists)
- [ ] pbxproj ID generation procedure ready (`openssl rand -hex 12` per `feedback_pbxproj_unique_ids`)

---

**Next step:** Artem approves → I start Phase A (models) → ship through to Phase H in one session.
