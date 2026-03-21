# Unified Hero Widget — Deep Product / UX / Data Audit

*Hexbound · March 2026 · Read-only audit — zero code changes*

---

## 1. Executive Summary

Hexbound сейчас показывает информацию о герое в **5+ разных местах** с разной структурой, разным набором данных и разной визуальной иерархией. Это создаёт три ключевые проблемы:

1. **Дублирование компонентов.** `HubCharacterCard`, inline-секция в `ArenaDetailView`, портрет в `HeroDetailView`, stamina bar отдельно на каждом экране — всё это независимые реализации одних и тех же данных.
2. **Inconsistent hierarchy.** На Hub главный акцент — HP + валюты. На Arena — rating + record. На Hero — equipment + stats. Игрок каждый раз переключает ментальную модель, хотя core identity героя один и тот же.
3. **Wasted vertical space.** Stamina bar + character card + currencies + status text суммарно занимают 180-220pt вертикального пространства на Hub и Arena. Это 25-30% видимого экрана до начала actionable content.

**Главный вывод:** нужен один `UnifiedHeroWidget` с единой data model, единой визуальной структурой и контекстной адаптацией через compact/expanded mode + contextual badges.

---

## 2. Backend / DB Truth Audit

### 2.1 Поля, реально существующие в Character (Prisma → API → iOS Model)

| Field | DB (Prisma) | API (/game/init) | iOS Model | Used in current UI | Widget Priority | Notes |
|-------|:-----------:|:-----------------:|:---------:|:------------------:|:---------------:|-------|
| characterName | ✅ | ✅ | ✅ | Hub, Arena, Hero, Combat | **A (always)** | Max ~20 chars |
| level | ✅ | ✅ | ✅ | Hub (badge), Arena, Hero | **A** | 1-100, resets on prestige |
| avatar / portrait | ✅ (string key) | ✅ | ✅ | Hub, Arena, Hero, Combat | **A** | Resolves via GameDataCache → AsyncImage |
| characterClass | ✅ | ✅ | ✅ | Hero header, Arena (opponent) | **A** | warrior/rogue/mage/tank |
| origin | ✅ | ✅ | ✅ | Hero header only | **D** | human/orc/skeleton/demon/dogfolk — flavor, not decision data |
| gender | ✅ | ✅ | ✅ (optional) | Character creation only | **D** | Never shown post-creation |
| currentHp / maxHp | ✅ | ✅ | ✅ | Hub (HP bar), Hero (HP bar), Combat | **A** | Server regen, gradient bar |
| currentStamina / maxStamina | ✅ | ✅ | ✅ | Hub (stamina bar), Arena, Dungeon (all separate) | **A** | Shared StaminaBarView component |
| experience (currentXp) | ✅ (BigInt) | ✅ | ✅ | Hub (XP ring on avatar), Hero | **B** | xpPercentage computed client-side |
| gold | ✅ (BigInt) | ✅ | ✅ | Hub (currency), Hero Status | **A** | Soft currency |
| gems | ✅ (on User, not Character) | ✅ | ✅ (optional) | Hub (currency) | **B** | Premium currency, comes from User record |
| pvpRating | ✅ | ✅ | ✅ | Arena header | **B (Arena only)** | ELO 800-3000+ |
| pvpWins / pvpLosses | ✅ | ✅ | ✅ | Arena header (W/L record) | **B (Arena only)** | Combined as "192W / 15L" |
| pvpWinStreak | ✅ | ✅ | ✅ (optional) | Not shown in widget | **C** | Alert-worthy if streak ≥ 5 |
| pvpLossStreak | ✅ | ✅ | ✅ (optional) | Not shown | **C** | Alert-worthy if ≥ 3 |
| firstWinToday | ✅ | ✅ | ✅ (optional) | Hub (bonus card) | **C** | Shows as separate card, not in widget |
| freePvpToday | ✅ | ✅ | ✅ (optional) | Not shown in widget | **C** | Relevant only in Arena context |
| strength..charisma (8 stats) | ✅ | ✅ | ✅ (all optional) | Hero Status tab only | **D** | Detail screen data, never summary |
| statPoints | ✅ | ✅ | ✅ (optional) | Hero tab badge (blinking gold) | **C** | Alert: "stat points available" |
| armor / magicResist | ✅ (derived) | ✅ | ✅ (optional) | Hero Status tab | **D** | Derived stats, detail screen only |
| attackPower | ❌ (computed client) | ❌ | ✅ (computed) | Hero Status tab | **D** | Client-computed, not in widget |
| combatStance | ✅ | ✅ | ✅ (optional) | Arena (stance selector), Hero | **B (Arena)** | attack/defense zones |
| prestige | ✅ | ✅ | ✅ (optional) | Hero header | **C** | Show only if > 0 |
| inventorySlots | ✅ | ✅ | ✅ (optional) | Inventory only | **D** | Never in summary |
| durability (equipment) | ✅ (per item) | ✅ | ✅ | Item detail only | **C** | Alert if any item at 0 durability |
| rankName | ❌ (computed client) | ❌ | ✅ (computed) | Arena header | **B (Arena)** | Bronze/Silver/Gold/Platinum/Diamond/GM |

### 2.2 Поля, которые НЕ существуют в backend (не выдумывать)

| Often expected | Reality |
|---|---|
| gear score / power level | **Не существует.** Нет агрегированного показателя "силы". Только individual stats + equipment bonuses |
| "Battle Ready" status | **Computed client-side** в HubCharacterCard. Логика: HP ≥ 50% = "Battle Ready", HP 25-50% = "Almost Ready", HP < 25% = "Needs Healing" / "Critical HP!" |
| activity timer / last active | **lastPlayed** есть в DB, но не используется в widget |
| clan / guild | **Не существует** |
| title (cosmetic) | Существует в Cosmetics (CosmeticType.TITLE), но **не отображается в widget** |
| buff/debuff timers | **Не существует** как persistent state. Consumables have quantity, not active timer |
| quest progress summary | Приходит из /game/init как отдельный массив, **не часть Character model** |

---

## 3. Current Widget Problems

### 3.1 Structural Duplication

| Проблема | Где проявляется | Severity |
|---|---|---|
| **Stamina bar копируется на каждом экране.** Hub, Arena, Dungeon — каждый рендерит свой StaminaBarView в header. | HubView, ArenaDetailView, DungeonSelectDetailView, HeroDetailView | 🔴 Critical |
| **Character card существует в 2+ вариантах.** HubCharacterCard (самостоятельный), HubCharacterCardWrapper (обёртка для Arena), inline-портрет в HeroDetailView. | Hub, Arena, Hero | 🔴 Critical |
| **Currencies показываются в разных местах по-разному.** Hub: inline в карточке. Hero Status: отдельная секция "Resources". Arena: нигде. | Hub, Hero | 🟡 High |

### 3.2 Information Hierarchy Issues

| Проблема | Impact |
|---|---|
| **Hub character card объединяет identity + resources + health в один блок ~120pt.** Слишком много для summary, слишком мало для detail. Ни то ни сё. | Cognitive overload |
| **Arena показывает rating/record В ОТДЕЛЬНОМ header**, а character card ниже дублирует avatar + name + HP. Два блока вместо одного. | Wasted space (~80pt) |
| **Hero screen показывает avatar + equipment + tabs + stats ВСЁ ВМЕСТЕ.** Equipment grid с портретом в центре — красиво, но не scalable для widget. | Layout lock-in |
| **XP progress показывается ТОЛЬКО как ring на аватаре.** Мелкий, трудно читать процент. На Hero screen отдельная XP bar — inconsistency. | Missed feedback |
| **"Battle Ready" / "Needs Healing" текст есть ТОЛЬКО на Hub.** Arena и Dungeon не показывают health status, хотя это critical для pre-battle decision. | Missing context |

### 3.3 Missing Critical Alerts

| Что должно быть видно | Сейчас | Проблема |
|---|---|---|
| Low HP warning | Только на Hub (text color change + pulse animation) | Arena и Dungeon не предупреждают |
| Low stamina | Stamina bar жёлтый/красный на каждом экране | Нет явного "Not enough for battle" alert |
| Stat points available | Blinking badge на Hero tab | Не видно с Hub или Arena |
| Broken equipment (0 durability) | Нигде | Игрок может пойти в бой без stats от сломанного предмета |
| Level up imminent (XP > 90%) | Нигде | Missed dopamine opportunity |
| Loss streak | Нигде | Мог бы предупреждать перед Arena |

### 3.4 Wasted Space Analysis

| Экран | Текущее пространство до actionable content | Что можно сжать |
|---|---|---|
| **Hub** | ~220pt (stamina bar + character card + first win bonus) | Stamina + character card → unified widget ~80pt |
| **Arena** | ~280pt (stamina bar + rating header + character card + stance) | Stamina + rating + character → unified widget ~100pt |
| **Dungeon** | ~120pt (stamina bar + section title) | Stamina → inline в unified widget ~60pt |
| **Hero** | ~300pt (stamina bar + equipment grid with portrait) | Portrait section → unified widget + equipment below |

---

## 4. Information Priority Matrix

### A — Always Visible (Core Identity)

Это то, что игрок должен видеть **мгновенно на любом экране** — в пределах 1 секунды.

| Data | Why Always | Source |
|---|---|---|
| **Avatar** (thumbnail) | Visual identity — player recognizes their character | avatar field + GameDataCache |
| **Name** | Core identity | characterName |
| **Level** (badge on avatar) | Progression anchor — defines power context | level |
| **HP bar** (compact gradient) | Pre-battle readiness. Green = go, red = stop | currentHp / maxHp |
| **Stamina** (compact inline) | Can I do the next action? | currentStamina / maxStamina |
| **Gold** (number) | Can I afford things? | gold |

### B — Contextual (Show per-screen)

Показывать **только на экранах, где это влияет на решение**.

| Data | Context | Screen(s) |
|---|---|---|
| **Gems** | Purchase/upgrade decisions | Hub (если есть shop nudge), Shop |
| **PvP Rating** (number) | Competitive context | Arena only |
| **PvP Rank** (tier name + icon) | Identity in PvP | Arena only |
| **W/L Record** | Performance context | Arena only |
| **XP progress** (%) | Leveling context | Hub (ring on avatar), Hero |
| **Combat Stance** | Pre-battle config | Arena only |
| **Class icon/name** | Role context | Arena (opponent comparison), Hero |
| **Free PvP remaining** | Action cost context | Arena only |

### C — Warning / Temporary (Show only on state change)

Показывать **только когда что-то требует внимания**.

| Signal | Trigger | Display |
|---|---|---|
| 🔴 **Critical HP** | currentHp < 25% maxHp | Red pulse on HP bar + "Heal" badge |
| 🟡 **Low HP** | currentHp < 50% maxHp | Amber HP bar (already gradient) |
| ⚡ **Low Stamina** | currentStamina < action cost | "Low Energy" badge |
| ⬆️ **Level Up Ready** | XP ≥ 90% of xpNeeded | Glow/sparkle on level badge |
| 🎯 **Stat Points Available** | statPoints > 0 | Small badge on avatar or name area |
| 🔧 **Broken Equipment** | Any equipped item durability = 0 | "⚠ Broken Gear" badge |
| 🏆 **First Win Bonus** | firstWinToday = false | Small star icon near PvP area |
| 🔥 **Win Streak** | pvpWinStreak ≥ 5 | "🔥5" badge (Arena only) |
| 💀 **Loss Streak** | pvpLossStreak ≥ 3 | Subtle warning (Arena only) |
| ⭐ **Prestige** | prestige > 0 | Small prestige badge on level |

### D — Remove from Widget (Detail Screen Only)

Эти данные **никогда не должны быть в summary widget**:

| Data | Why Remove |
|---|---|
| 8 base stats (STR, AGI, VIT, END, INT, WIS, LUK, CHA) | Detail screen only — no decision made from widget |
| Derived stats (armor, magic resist, attack power, crit, dodge) | Same — detail data |
| Equipment bonuses | Shown in Hero Status tab |
| Origin | Flavor text, zero gameplay impact on decision |
| Gender | Never shown post-creation |
| Inventory slots | Inventory screen concern |
| Full W/L history | Arena History tab |
| Achievement count | Achievement screen |
| Quest progress | Quest screen / separate banner |

---

## 5. Recommended Unified Widget: "Balanced Compact" (Recommended)

### 5.1 Structure

```
┌─────────────────────────────────────────────────┐
│ [Avatar]  Hero Name           ⚡ 87/120  [+]    │
│  Lv.14    ██████████░░ HP     🪙 17,864         │
│  (badges) ████░░░░░░░░ XP     💎 143            │
└─────────────────────────────────────────────────┘
```

**Height: ~72-80pt** (vs current ~180-220pt)

### 5.2 Layout Breakdown

**Left Column (~60pt wide):**
- Avatar thumbnail (48×48pt) с level badge (bottom-left)
- XP ring вокруг аватара (тонкий, 2pt stroke) — показывает xpPercentage
- State badges stack ниже аватара (max 2 одновременно)

**Center Column (flexible):**
- **Row 1:** Character name (bold, 15pt) + inline class icon (12pt, grey)
- **Row 2:** HP bar (compact, 8pt high, gradient green→amber→red) + "currentHp/maxHp" text (10pt, right-aligned)
- **Row 3 (optional, contextual):** XP bar OR contextual info (depends on screen)

**Right Column (~80pt wide):**
- **Row 1:** Stamina: ⚡ current/max + [+] button (buy/refill)
- **Row 2:** Gold: 🪙 formatted number
- **Row 3 (optional):** Gems: 💎 number (show only on Hub, hide on Arena/Dungeon)

### 5.3 Why This Is The Best Option

1. **72pt vs 220pt** — экономит ~150pt вертикального пространства на Hub, ~200pt на Arena.
2. **Всё что нужно за 1 секунду:** identity (avatar+name+level), readiness (HP+stamina), resources (gold).
3. **Единый компонент:** один SwiftUI View, одна data model (Character), один state machine.
4. **Контекстная адаптация:** через параметр `context: .hub | .arena | .dungeon | .hero` меняется третий ряд и видимость gems/pvp data.
5. **Alert system:** badges на аватаре + HP bar цвет дают мгновенный feedback без дополнительного UI.

### 5.4 Contextual Adaptation

| Screen | Row 3 Center | Right Column Extra | Visible Badges |
|---|---|---|---|
| **Hub** | XP bar (thin) | Gems shown | All warnings |
| **Arena** | PvP: "🏆 1633 · Gold" | Gems hidden, free fights shown | First win, streak, low HP |
| **Dungeon** | Hidden (save space) | Gems hidden | Low HP, low stamina, broken gear |
| **Hero** | XP bar (thin) | Gems shown | Stat points, broken gear |

### 5.5 What It Removes From Surrounding Screens

| Screen | What Can Be Removed | Space Saved |
|---|---|---|
| **Hub** | Отдельный StaminaBarView, отдельный HubCharacterCard, отдельный CurrencyDisplay | ~140pt |
| **Arena** | Отдельный StaminaBarView, отдельный rating header panel, отдельный HubCharacterCardWrapper | ~180pt |
| **Dungeon** | Отдельный StaminaBarView | ~40pt |
| **Hero** | Inline портрет в equipment grid (заменить на widget сверху + equipment grid ниже без портрета) | ~60pt |

---

## 6. Alternative Variants

### 6.1 Variant A: "Ultra Compact" (~48pt)

```
┌──────────────────────────────────────────┐
│ [Ava] Degon Lv.14  ██HP██  ⚡87  🪙17.8k│
└──────────────────────────────────────────┘
```

**Плюсы:**
- Минимальный footprint — 1 строка
- Максимум места для контента ниже
- Идеально для Dungeon и Combat

**Минусы:**
- Нет места для contextual info (rating, XP, gems)
- HP bar слишком маленький для чтения percentage
- Нет места для alert badges
- Ощущение "спрятали героя" — теряется RPG fantasy

**Verdict:** Годится как **альтернативный compact mode** внутри recommended widget (например для scroll-away header), но не как default.

### 6.2 Variant C: "Expanded Contextual" (~120pt)

```
┌─────────────────────────────────────────────────┐
│ [Avatar]  Degon                    ⚡ 87/120 [+] │
│  Lv.14    Demon · Warrior           🪙 17,864   │
│  ★★       ██████████░░░ HP 1030/1030  💎 143    │
│           ████░░░░░░░░░ XP 78%                   │
│  🏆 1633 Gold · 192W/15L · 🔥5 streak           │
└─────────────────────────────────────────────────┘
```

**Плюсы:**
- Вся информация в одном месте
- Не нужно менять layout per screen — всегда полная картина
- Отлично для Hero screen

**Минусы:**
- 120pt — всё ещё много для Arena/Dungeon
- PvP данные не нужны на Hub/Dungeon — wasted space
- Origin + class text — noise для repeated viewing
- Перегрузка: 5 строк данных в одном блоке

**Verdict:** Подходит как **expanded state** recommended widget (например при tap/long press), но не как default everywhere.

---

## 7. State Model

### 7.1 Complete State Table

| State | Trigger Condition | Visual Change | Priority |
|---|---|---|---|
| **default** | HP ≥ 50%, stamina ≥ action cost, no warnings | Standard colors, no badges | Baseline |
| **battle_ready** | HP ≥ 75%, stamina ≥ cost | Green accent on HP, "Battle Ready" можно убрать (redundant — зелёный HP = ready) | Low |
| **low_hp** | 25% ≤ HP < 50% | Amber HP bar gradient, no badge needed (color is the signal) | Medium |
| **critical_hp** | HP < 25% | Red HP bar + subtle pulse animation + ❤️‍🩹 badge on avatar | 🔴 Critical |
| **low_stamina** | stamina < min action cost (e.g. < PVP_COST from config) | Stamina number turns amber/red | High |
| **no_stamina** | stamina = 0 | Stamina area shows "Empty" + ⚡ badge flashes | 🔴 Critical |
| **level_up_imminent** | xpPercentage ≥ 0.9 | XP ring on avatar glows / sparkles gold | Medium |
| **level_up_achieved** | Triggered by server after XP gain | Brief celebratory animation (scale up level badge, gold flash) → returns to default | High (but transient) |
| **stat_points_available** | statPoints > 0 | Small "+" badge on level area | Medium |
| **broken_equipment** | Any equipped item durability = 0 | ⚠️ badge on avatar edge | High |
| **first_win_available** | firstWinToday = false (Arena context) | ⭐ small star near PvP info | Low |
| **win_streak** | pvpWinStreak ≥ 5 (Arena context) | 🔥 badge + streak count | Low |
| **loss_streak** | pvpLossStreak ≥ 3 (Arena context) | Subtle border or indicator | Low |
| **prestige** | prestige > 0 | Prestige star/badge on level badge | Low (persistent) |
| **loading** | Data fetching | Skeleton placeholder (existing SkeletonViews pattern) | N/A |
| **no_avatar** | avatar = nil or image load failed | Class icon fallback (existing AvatarImageView logic) | N/A |
| **long_name** | characterName > 15 chars | Truncation with "..." | N/A |
| **high_values** | gold > 999,999 or similar | Compact notation: "17.8K", "1.2M" | N/A |

### 7.2 Badge Priority System

Maximum **2 badges** visible simultaneously. Priority order:
1. 🔴 Critical HP (highest)
2. ⚡ No stamina
3. ⚠️ Broken equipment
4. ⬆️ Stat points available
5. ⭐ First win bonus
6. 🔥 Win streak

If > 2 badges would show, display top 2 + small "•" indicator for more.

---

## 8. Per-Screen Behavior

### 8.1 Hub

**Widget variant:** Balanced Compact (recommended default)

**Visible fields:**
- Avatar + level badge + XP ring
- Name + class icon (subtle)
- HP bar (gradient, compact)
- Stamina inline (⚡ current/max + [+])
- Gold + Gems
- XP bar (thin, row 3 center)

**Visible badges:** All warnings (HP, stamina, stat points, broken gear)

**What to REMOVE from Hub after unification:**
- `StaminaBarView` в header → stamina уже в widget
- `HubCharacterCard` → заменяется unified widget
- `CurrencyDisplay` (если есть отдельный) → в widget
- First Win Bonus card можно оставить как отдельный элемент ПОД widget (это actionable CTA, не identity)

**Space saved:** ~140pt → город/map начинается выше, больше immersion

### 8.2 Arena

**Widget variant:** Balanced Compact + Arena context overlay

**Visible fields:**
- Avatar + level badge + XP ring
- Name + class icon
- HP bar
- Stamina inline
- Gold (gems hidden)
- **Row 3 center:** PvP info: "🏆 1633 · Gold" (rating number + rank name)

**Visible badges:** First win, win/loss streak, critical HP, low stamina

**What to REMOVE from Arena after unification:**
- `StaminaBarView` в header → в widget
- Rating/Record/Rank отдельный header panel → rating в widget, full record → можно показать при tap на rating или оставить в History tab
- `HubCharacterCardWrapper` → unified widget
- Potential: stance selector можно вынести в отдельную секцию ниже или в overlay

**Space saved:** ~180pt → opponent cards видны сразу, без скролла

### 8.3 Dungeon

**Widget variant:** Balanced Compact (minimal context)

**Visible fields:**
- Avatar + level badge
- Name
- HP bar
- Stamina inline (critical для dungeon cost)
- Gold

**Row 3 and gems:** hidden (не нужны при выборе подземелья)

**Visible badges:** Low HP, low stamina, broken gear

**What to REMOVE from Dungeon after unification:**
- `StaminaBarView` в header → в widget

**Space saved:** ~40pt (stamina bar was small anyway, but consistency matters)

### 8.4 Hero Screen

**Widget variant:** Balanced Compact (top of screen, sticky)

**Visible fields:**
- Avatar + level badge + XP ring
- Name + class + origin (more detail allowed here)
- HP bar
- Stamina inline
- Gold + Gems
- XP bar

**Visible badges:** Stat points, broken gear

**What changes on Hero screen:**
- Equipment grid ниже widget БЕЗ портрета в центре (портрет уже в widget)
- Equipment grid becomes a clean 3×4 or 4×3 grid
- Status tab data stays as-is (full stat allocation, derived stats, etc.)

**Space saved:** ~60pt (portrait area in equipment grid becomes usable slot space)

### 8.5 Training Camp / Dungeon Rush

**Widget variant:** Same as Dungeon (minimal)

**Note:** Training Camp (visible in screenshots) shows character card + stamina. Unified widget replaces both.

### 8.6 Combat

**Widget variant:** NOT used. Combat has its own specialized HP/skill bars. Widget не нужен в active combat.

---

## 9. Space Saving Opportunities

### 9.1 Quantified Space Recovery

| Screen | Before (pt) | After (pt) | Saved (pt) | Saved (%) |
|---|---|---|---|---|
| Hub | ~220 | ~80 | **~140** | 64% |
| Arena | ~280 | ~100 | **~180** | 64% |
| Dungeon | ~120 | ~72 | **~48** | 40% |
| Hero | ~300 | ~80 + equipment grid | **~60** | 20% |

### 9.2 What Moves Into Widget (no longer separate)

| Component | Was | Becomes |
|---|---|---|
| `StaminaBarView` | Standalone component, rendered per-screen | Inline ⚡ number in widget right column |
| `HubCharacterCard` | 120pt card with avatar, name, HP, currencies, status text, potion button | Replaced entirely by unified widget |
| `HubCharacterCardWrapper` | Wrapper for reuse in Arena | Deleted — widget is the wrapper |
| Currency display (gold/gems) | Shown differently per screen | Unified right column in widget |
| Status text ("Battle Ready") | Only on Hub | Replaced by HP bar color + contextual badges |

### 9.3 What Stays Separate (NOT absorbed)

| Element | Why Separate |
|---|---|
| First Win Bonus card | Actionable CTA, not identity — should be a separate dismissible card |
| Stance Selector | Complex interactive UI, not summary data |
| Equipment Grid | Too complex for widget, stays on Hero screen |
| Opponent cards | Arena-specific, below widget |
| Quest banners | ActiveQuestBanner is a different concern |

---

## 10. Risks / Constraints

### 10.1 Backend Constraints

| Constraint | Impact on Widget |
|---|---|
| **No "gear score" field.** | Cannot show aggregate power level. Придётся обходиться без "power" number. |
| **No "isBattleReady" from backend.** | Client must compute readiness from HP + stamina thresholds. Logic already exists in HubCharacterCard. |
| **Gems are on User, not Character.** | Widget needs access to both Character AND User model (or GameState that contains both). Already the case via /game/init. |
| **Stamina regen is server-computed.** | Client gets current value on /game/init. For realtime countdown, client uses `lastStaminaUpdate` + regen interval. Already implemented. |
| **HP regen is server-computed.** | Same as stamina — client gets snapshot. Widget should NOT animate HP regen locally (server authoritative). |
| **PvP rank is client-computed from pvpRating.** | PvPRank.fromRating() already exists in iOS. Widget uses this. |
| **Durability per-item, no aggregate "has broken gear".** | Widget needs to check equipped items array for any durability = 0. This is a new client-side computation, but data already available from /game/init equipment array. |
| **XP formula is client-side.** | `xpNeeded = 100 * nextLevel + 20 * nextLevel²`. Already in Character.swift computed property. |

### 10.2 UX Risks

| Risk | Mitigation |
|---|---|
| **Too compact = lost RPG feel.** | Avatar must stay 48pt minimum. Gold accents, dark fantasy border keep theme. |
| **Too many badges = noise.** | Max 2 badge rule. Priority system. |
| **Arena users want to see rating prominently.** | Contextual row 3 shows PvP data in Arena context. |
| **Hub users expect currencies visible.** | Gold always visible. Gems on Hub/Hero. |
| **Removing status text ("Battle Ready") may confuse.** | HP bar color gradient IS the status. Green = ready. Red = not. More universal than text. |
| **Long names truncation.** | Test with max-length names. 15 char cutoff with "..." |

### 10.3 Technical Risks

| Risk | Mitigation |
|---|---|
| **Xcode project file complexity.** | One new file (UnifiedHeroWidget.swift) replacing 2-3 files. Net reduction in project complexity. |
| **Breaking existing navigation.** | Widget tap → Hero screen (same as HubCharacterCard). No nav changes needed. |
| **Animation performance.** | HP gradient + XP ring + badge animations. Keep under 3 concurrent animations. Use `.animation(.easeInOut)` not `.spring`. |

---

## 11. Final Recommendation

**Делать "Balanced Compact" вариант** (Section 5) как единственный `UnifiedHeroWidget`.

**Почему именно этот:**

1. **72-80pt height** — экономит 40-64% вертикального пространства на каждом экране.
2. **1-second glance** — avatar + name + level + HP + stamina + gold видны мгновенно. Это ровно то, что нужно для pre-action decision.
3. **Context param** — единый компонент с `context: .hub | .arena | .dungeon | .hero` адаптирует третий ряд и видимость данных. Один View, один ViewModel, одна data model.
4. **Alert system через badges** — не перегружает layout, но даёт critical signals (low HP, no stamina, stat points, broken gear).
5. **HP bar gradient заменяет текст "Battle Ready"** — более универсальный, более быстрый для parsing, работает на всех экранах.
6. **Устраняет 3 отдельных компонента** (StaminaBarView в header, HubCharacterCard, HubCharacterCardWrapper) и заменяет одним.
7. **Совместим с backend truth** — использует только реально существующие поля, не требует новых API endpoints или DB changes.

**Чего НЕ делать:**
- Не добавлять gear score (нет в backend)
- Не показывать 8 stats в widget (detail screen only)
- Не показывать origin (noise)
- Не делать widget expandable/collapsible на первом этапе (усложнение без подтверждённой потребности)

---

## 12. Optional Next Step

Если после аудита принято решение двигаться дальше:

1. **Wireframe** — создать точный wireframe UnifiedHeroWidget с pixel-perfect размерами, используя существующие DarkFantasyTheme tokens и LayoutConstants.
2. **Data Contract** — определить точный протокол `HeroWidgetData` с полями из Priority A + B + C, computed properties для badges, и context enum.
3. **State Machine** — формализовать state transitions (Section 7) как Swift enum с associated values.
4. **Implementation** — один файл `UnifiedHeroWidget.swift`, одна замена на каждом экране, удаление deprecated components.
5. **Per-screen integration** — последовательно: Hub → Arena → Dungeon → Hero. Каждый шаг — отдельный PR.
6. **Validation** — visual regression test на всех 4 экранах, проверка всех 10+ states из Section 7.

Но всё это — **после** product decision на основе данного аудита.
