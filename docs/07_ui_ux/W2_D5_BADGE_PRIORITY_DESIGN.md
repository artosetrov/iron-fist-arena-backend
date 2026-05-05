# W2.D5 — Badge Priority System

**Дата:** 2026-04-10
**Статус:** 📚 HISTORICAL DESIGN DOC — archived badge-priority proposal
**План:** `QA_FIX_PLAN_2026-04-10.md` W2.D5 — «Badge priority / visual hierarchy»
**Связанные доки:** `W2_D4_BUILDING_GATING_DESIGN.md`

> **Status boundary:** historical badge-priority proposal. Useful for product reasoning, but not a live statement of current hub badge behavior or current UX policy without revalidation.

---

## TL;DR

Сейчас все 6 badges в hub выглядят одинаково (gold pill с числом) и весят визуально одинаково. Это нарушает правило «if everything is urgent, nothing is». Игрок не понимает, **что требует действия прямо сейчас** vs **что просто информация**.

Предложение — `BadgePriority` enum с 3 уровнями:

1. **`.critical`** — красная pulsing pill, требует действия игрока (unclaimed rewards, ready collections, inbox unread)
2. **`.info`** — золотая static pill (нейтральная informational: free fights remaining, bosses metadata)
3. **`.none`** — не показывать вообще

Cap: **максимум 3 critical badges одновременно** в hub (Miller's Law). Если больше — показать только топ-3 по severity.

Скоуп: ~2 часа работы, никаких backend изменений, только Swift refactor.

---

## Текущее состояние (audit)

`CityMapView.swift:215-269` — `badgeFor(_ building)` возвращает `String?`. Все 6 badges одинаковые визуально:

| Building | Badge | Current priority (none) | Proposed priority |
|---|---|---|---|
| `arena` | "FREE 3" (free PvP remaining) | = | **`.info`** |
| `achievements` | "2" (claimable rewards) | = | **`.critical`** |
| `battlepass` | "5" (claimable tiers) | = | **`.critical`** |
| `gold-mine` | "READY" | = | **`.critical`** |
| `guild-hall` | "4" (social total) | = | **composite** (see below) |
| `dungeon` | "12" (bosses remaining) | = | **`.none`** ❗ |

### Проблема с `dungeon` badge

«12» — это НЕ количество доступных действий, это метаданные о total content. Нет необходимости бейджить игрока на каждый enter в hub. Убрать.

### Проблема с `arena` badge

«FREE 3» информирует о free fights — важно, но не требует действия СЕЙЧАС. Downgrade до `.info` (золото), чтобы не конкурировать с reward-claim badges.

### Проблема с `guild-hall` compound badge

Сейчас `socialStatus.totalBadge` суммирует друзей + вызовов + сообщения + revenges. Нужно разложить:

- Unread messages → **critical**
- Incoming challenges → **critical**
- New friend requests → **info**
- Unclaimed revenge opportunities → **info**

Показывать максимум **высший priority** из compound + число.

---

## Best Practices

| Принцип | Источник | Применение |
|---|---|---|
| **Max 3 critical notifications** | Miller's Law, iOS HIG | Cap critical badges to 3 per screen |
| **Red = action required, Gold = info** | Clash Royale, Raid | Two-tier color system |
| **Pulsing only on critical** | AFK Arena, Epic Seven | Subtle opacity pulse (NOT scale — see feedback memory) |
| **«Claimable» > «ready» > «unread» > «new»** | Game UX research | Priority ordering of critical items |
| **Downgrade stale badges** | Fortnite, Genshin | If badge shown > 3 sessions without interaction → downgrade to info |

---

## API Design

### `BadgePriority` enum

Файл: `Hexbound/Hexbound/Views/Hub/BuildingBadge.swift` (новый).

```swift
/// Priority of a hub building badge — determines visual treatment and sort order.
enum BadgePriority: Int, Comparable {
    case none = 0       // Don't show
    case info = 1       // Gold, static pill — informational only
    case critical = 2   // Red, pulsing pill — action required

    static func < (lhs: BadgePriority, rhs: BadgePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Full badge data — replaces current `String?` API.
struct BuildingBadge {
    let text: String
    let priority: BadgePriority
    let severity: Int  // Tiebreaker for cap-3 selection (higher = more urgent)

    static let none = BuildingBadge(text: "", priority: .none, severity: 0)

    var shouldShow: Bool { priority != .none }
}
```

### Usage в `CityMapView`

```swift
private func badgeFor(_ building: CityBuilding) -> BuildingBadge {
    switch building.id {

    case "arena":
        let used = appState.currentCharacter?.freePvpToday ?? 0
        let limit = cache.gameConfig?.freePvpPerDay ?? AppConstants.freePvpPerDay
        let remaining = limit - used
        guard remaining > 0 else { return .none }
        return BuildingBadge(
            text: "FREE \(remaining)",
            priority: .info,
            severity: 10 + remaining
        )

    case "achievements":
        let claimable = cache.achievements.filter(\.canClaim).count
        guard claimable > 0 else { return .none }
        return BuildingBadge(
            text: "\(claimable)",
            priority: .critical,
            severity: 50 + claimable * 5
        )

    case "battlepass":
        guard let bp = cache.battlePassData else { return .none }
        let claimable = (bp.freeRewards + bp.premiumRewards).filter {
            !$0.claimed && $0.level <= bp.currentLevel && ($0.track == "free" || bp.hasPremium)
        }.count
        guard claimable > 0 else { return .none }
        return BuildingBadge(
            text: "\(claimable)",
            priority: .critical,
            severity: 60 + claimable * 5  // Higher than achievements — time-limited
        )

    case "gold-mine":
        let ready = cache.goldMineSlots.filter { ($0["status"] as? String) == "ready" }.count
        guard ready > 0 else { return .none }
        return BuildingBadge(
            text: "READY",
            priority: .critical,
            severity: 40 + ready * 2
        )

    case "guild-hall":
        return buildGuildHallBadge()

    case "dungeon":
        // No badge — total bosses is metadata, not a notification
        return .none

    default:
        return .none
    }
}

private func buildGuildHallBadge() -> BuildingBadge {
    guard let social = cache.socialStatus else { return .none }

    // Priority: unread messages > incoming challenges > friend requests > revenge ops
    let unreadMsg = social.unreadMessages ?? 0
    let challenges = social.incomingChallenges ?? 0
    let friendReq = social.newFriendRequests ?? 0
    let revenges = social.availableRevenges ?? 0

    if unreadMsg > 0 || challenges > 0 {
        let total = unreadMsg + challenges
        return BuildingBadge(
            text: "\(total)",
            priority: .critical,
            severity: 55 + total * 3
        )
    }

    if friendReq > 0 || revenges > 0 {
        let total = friendReq + revenges
        return BuildingBadge(
            text: "\(total)",
            priority: .info,
            severity: 15 + total
        )
    }

    return .none
}
```

### Cap-3 critical selection

После computing badges для всех buildings:

```swift
private func filteredBadges(
    _ buildings: [CityBuilding]
) -> [String: BuildingBadge] {
    let all = buildings.map { ($0.id, badgeFor($0)) }

    // Split by priority
    let critical = all.filter { $0.1.priority == .critical }
        .sorted { $0.1.severity > $1.1.severity }
    let info = all.filter { $0.1.priority == .info }

    // Cap critical at 3
    let cappedCritical = Array(critical.prefix(3))
    let downgraded = critical.dropFirst(3).map { ($0.0, BuildingBadge(
        text: $0.1.text,
        priority: .info,
        severity: $0.1.severity
    )) }

    var result: [String: BuildingBadge] = [:]
    for (id, badge) in cappedCritical { result[id] = badge }
    for (id, badge) in info { result[id] = badge }
    for (id, badge) in downgraded { result[id] = badge }
    return result
}
```

Зовётся один раз per render:

```swift
let badges = filteredBadges(buildings)
// …
badge: locked ? .none : (badges[building.id] ?? .none)
```

---

## Visual Design

### `.critical` treatment (red pulsing)

```swift
struct CriticalBadge: View {
    let text: String
    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.badge)
            .foregroundStyle(.white)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.dangerRed)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: DarkFantasyTheme.dangerRed.opacity(0.6), radius: 6, y: 0)
            .opacity(pulseOpacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseOpacity = 0.75
                }
            }
    }
}
```

**Opacity pulse only — NO scale animation.**

### `.info` treatment (gold static)

Существующий стиль, уже реализован как `WidgetPill` в DS. Переиспользовать:

```swift
struct InfoBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.badge)
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.gold)
            )
            .overlay(
                Capsule()
                    .stroke(DarkFantasyTheme.goldBright, lineWidth: 1)
            )
    }
}
```

### Wrapper component

```swift
struct BuildingBadgeView: View {
    let badge: BuildingBadge

    var body: some View {
        Group {
            switch badge.priority {
            case .critical:
                CriticalBadge(text: badge.text)
            case .info:
                InfoBadge(text: badge.text)
            case .none:
                EmptyView()
            }
        }
    }
}
```

---

## Files Changed

### New files

| File | LOC est | Purpose |
|---|---|---|
| `Hexbound/Hexbound/Views/Hub/BuildingBadge.swift` | ~120 | `BadgePriority`, `BuildingBadge`, `CriticalBadge`, `InfoBadge`, `BuildingBadgeView` |

### Modified files

| File | Changes |
|---|---|
| `Hexbound/Hexbound/Views/Hub/CityMapView.swift` | `badgeFor` returns `BuildingBadge`; new `filteredBadges` + `buildGuildHallBadge`; pass to `CityBuildingView`; remove `dungeon` badge case |
| `Hexbound/Hexbound/Views/Hub/CityBuildingView.swift` | Change `badge: String?` → `badge: BuildingBadge`; render via `BuildingBadgeView` |
| `Hexbound/Hexbound/Views/Hub/CityBuildingLabel.swift` (if exists separately) | Same type change |

### pbxproj

1 new file → 4 entries.

### NO backend changes

Все badge state derived из существующих cache fields. Нет миграций, нет API изменений.

---

## Edge Cases

| Edge case | Handling |
|---|---|
| Все badges <= info priority | Cap не срабатывает, все показываются |
| 5+ critical badges | Top-3 по severity остаются critical, остальные downgrade в info |
| Badge source возвращает negative number | Guarded by `guard count > 0` pattern — no badge |
| GameDataCache не загружена | Все badges `.none` — fail-safe default |
| Locked building + critical state (mega-edge case) | `locked ? .none : badge` — lock wins, no badge shown |
| Reduce Motion включен в iOS Settings | Pulsing animation должна respect `@Environment(\.accessibilityReduceMotion)` — disable pulse, static red background |
| Guild hall compound = 0 total | `.none`, no badge |

### Accessibility

```swift
struct CriticalBadge: View {
    let text: String
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        // … same as above …
        .opacity(pulseOpacity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.75
            }
        }
    }
}
```

Voice Over labels:

```swift
.accessibilityLabel("\(building.label). \(badge.priority == .critical ? "Action required: " : "")\(badge.text)")
```

---

## Implementation Plan

### Phase 1 — BuildingBadge infrastructure (30 min)
1. Create `BuildingBadge.swift` с enum + struct + views
2. Add pbxproj entries
3. Compile check

### Phase 2 — CityMapView refactor (45 min)
1. Change `badgeFor` signature
2. Add `buildGuildHallBadge` helper
3. Add `filteredBadges` cap-3 logic
4. Remove `dungeon` case
5. Downgrade `arena` to info
6. Pass `BuildingBadge` to `CityBuildingView`

### Phase 3 — CityBuildingView refactor (20 min)
1. Change `badge: String?` → `badge: BuildingBadge`
2. Replace inline badge rendering with `BuildingBadgeView`
3. Check `CityBuildingLabel` if separate

### Phase 4 — Visual QA (25 min)
1. Manual test Lv1: arena info badge if free fights > 0, nothing else
2. Manual test Lv2+ после scripted fight: achievements critical (first achievement claimable)
3. Manual test Lv4+ с ready gold mine: gold-mine critical
4. Manual test 5+ critical scenario (edge case)
5. Reduce Motion on → pulse disabled, static red
6. Voice Over → labels read correctly
7. CDO verification scan

**Total: ~2 hours**

---

## Acceptance Criteria

- [ ] `BuildingBadge.swift` создан с enum + struct + 3 views
- [ ] pbxproj содержит новый файл (4 sections)
- [ ] `CityMapView.badgeFor` returns `BuildingBadge`
- [ ] `filteredBadges` реализует cap-3 + severity sort + downgrade
- [ ] `buildGuildHallBadge` разлагает compound social badge
- [ ] `dungeon` больше не имеет badge
- [ ] `arena` badge = `.info` priority
- [ ] `achievements`, `battlepass`, `gold-mine` = `.critical` priority
- [ ] `CriticalBadge` уважает `accessibilityReduceMotion`
- [ ] `accessibilityLabel` включает «Action required» для critical
- [ ] No scale animations (only opacity pulse)
- [ ] No hardcoded colors (все через `DarkFantasyTheme`)
- [ ] CDO verification scan: CLEAN
- [ ] Manual visual test passes для 6 scenarios

---

## Вопросы для Artem

1. **Priority assignment**: Согласен что `arena` = info (не critical)? Некоторые игры делают free fight timer critical red, т.к. «use it or lose it».

2. **Dungeon badge removed**: Убираем badge совсем или оставляем info «12»? Мой вердикт — убрать (не actionable), но могу ошибаться, если retention data показывает что badge помогает re-engagement.

3. **Pulsing**: Opacity pulse 1.0 → 0.75 → 1.0 с периодом 1.2 сек. Согласен с параметрами, или медленнее (2 сек)?

4. **Red color**: Использовать `DarkFantasyTheme.dangerRed` или добавить новый token `badgeCritical` на случай если хотим менее агрессивный оттенок?

5. **Cap-3**: Действительно ли Miller's Law применим к hub badges (это не navigation, игрок быстро сканирует)? Или cap можно снять?

6. **Compound guild badge**: Нужен ли отдельный `socialStatus.unreadMessages` / `incomingChallenges` field на сервере, или уже есть? Нужна проверка в `SocialStatus` model.

7. **Parallel agent review**: Запустить `hexbound-studio:flow` (UX Director) для badge hierarchy + `hexbound-studio:canvas` (UI Art) для visual treatment?

---

## Next Step

**PAUSE — Present all W2 design docs (D1 reality check, D2 lore audit, D3 scripted fight, D4 gating, D5 badges) to Artem for approval.** После approval — execution order:

1. W2.D2 Phase 1–3 (CinematicSlideView extract + LoreIntroView refactor + CinematicOpenView)
2. W2.D3 Phase 1–4 (scripted fight backend + endpoints + iOS views)
3. W2.D2 Phase 4 + W2.D3 Phase 5 (shared navigation integration)
4. W2.D4 (building gating + ceremony)
5. W2.D5 (badge priority)
6. W2 checkpoint: manual QA + agent reviews + tag
