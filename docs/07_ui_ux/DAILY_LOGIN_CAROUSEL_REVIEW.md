# Daily Login — Redesign Carousel наград

**Дата:** 2026-04-11
**Автор запроса:** Artem
**Файл под правку:** `Hexbound/Hexbound/Views/DailyLogin/DailyLoginDetailView.swift`
**Связанные компоненты:** `ItemCardView`, `ItemDetailSheet`, `DailyReward`, `DailyLoginRewardDef`

> **Status boundary:** historical redesign review from `2026-04-11` for a specific daily-login UI iteration. Useful as rationale and component-thinking, but not a live guarantee that the current screen still matches this exact scope or recommendation set. Re-check `wiki/features/daily-login.md` and current Swift files before treating it as implementation truth.

---

## 1. Текущая проблема

Нижний блок `dayStrip` → `dayNode` рисует 7 крохотных "icon-well" квадратов (~48pt по высоте) с иконкой внутри и подписью `D1…D7`. Проблемы:

1. **Нечитаемо.** Награды выглядят как иконки-заглушки, не как предметы. Игрок не воспринимает их ценность.
2. **Нет тактильности.** Ячейки не кликабельны — нельзя посмотреть детали предмета (сколько именно, что это, редкость), только Today-карточка сверху раскрывается.
3. **Дубль визуалов.** Hero 168×168 использует `ItemCardView(.preview)`, а strip рисуется вручную (RoundedRectangle + Image). Два разных визуала для одной сущности — нарушение правила "reusability first".
4. **Нет ощущения прогрессии по неделе.** Мелкие точки не создают "timeline" вайб, который обещает Calendar / BP.

---

## 2. Что хочет Artem

- Ряд наград должен быть **размером как ячейка инвентаря** (≈ ширина колонки LazyVGrid на ~2–3 колонки, aspectRatio 1:1).
- **Горизонтальная карусель** со скроллом влево-вправо (все 7 дней).
- Каждая карточка **кликабельна** → открывается **ItemDetailSheet-style модалка** с деталями награды.

Отвеченные вопросы:
- **Scope:** только 7 дней текущей недели.
- **Non-items:** Gold, Gems, Potions тоже должны показывать детальный sheet (не toast).
- **Flow:** сначала отчёт + прототип, потом код.

---

## 3. Архитектурное препятствие: `ItemDetailSheet` жёстко завязан на `Item`

`ItemDetailSheet.swift` принимает `let item: Item` + кучу колбэков (`onEquip`, `onUpgrade`, `onSell`, `onRepair`, `onUse`), а внутри считает `levelMet`, `classMet`, `comparedItem`, `durability`, `upgradeChances`. Ни одного из этих концептов нет у `DailyReward` (который = `{type: "gold"|"gems"|"consumable", amount, displayName, displayIcon}`).

**Вывод:** скармливать `ItemDetailSheet` синтезированные "фейк-Items" для Gold / Gems — грязный хак, который размоет ответственность шита и приведёт к багам (кнопки EQUIP / SELL для "золота").

---

## 4. Решение — новый переиспользуемый `RewardDetailSheet`

Создаём **один новый компонент**, который визуально наследует язык `ItemDetailSheet` (та же modal-карточка, тот же hero `ItemCardView(.preview)`, та же типографика), но принимает абстракцию `RewardDisplayable`. Таким образом его можно переиспользовать для:

- **Daily Login** (текущая задача)
- **Battle Pass** reward nodes — там сейчас тоже кастомный `BPRewardNodeView` sheet, его можно унифицировать
- **Achievements** — rewards на achievement-карточках
- **Mail attachments**, **Quest rewards**, **Event rewards**

Это ровно тот паттерн, который ты настоял (`feedback_reusability_first_rule`): не дублировать UI, а выжимать один компонент в несколько мест.

### 4.1 Протокол `RewardDisplayable`

```swift
protocol RewardDisplayable {
    var id: String { get }
    var rarity: ItemRarity { get }          // для рамки/свечения (Gold = .common, Gems = .rare, Legendary day 7 = .legendary)
    var assetKey: String? { get }           // xcassets image
    var title: String { get }               // "300 Gold", "1 Stamina Potion"
    var subtitle: String? { get }           // "Daily Login Day 3" или nil
    var description: String { get }         // короткий flavor-текст
    var amount: Int? { get }                // для badge "×300"
    var underlyingItem: Item? { get }       // если это реальный item — получаем доступ к stat-блоку
}
```

`DailyReward` адаптируется под `RewardDisplayable` в extension-е (2–3 строчки). `BPRewardNode` тоже легко — уже сейчас использует `ItemCardView`.

### 4.2 `RewardDetailSheet` — структура

```
ModalCard (modalCard style из DailyLogin)
├─ Header: close button + "DAILY LOGIN · DAY 3"
├─ Hero ItemCardView(.preview) 168×168 — рамка по rarity, свечение
├─ Title: "300 GOLD" (cinematicTitle, gold gradient)
├─ Subtitle: "Day 3 reward"
├─ ─── gold divider ───
├─ Description block: "A pouch of gold coins to spend on gear, upgrades, and consumables in the shop."
├─ (Optional) Stat block — только для реальных Item-наград (оружие/броня)
├─ ─── gold divider ───
└─ Primary CTA: "CLAIM REWARD" (если это текущий день и не заклеймен) OR "CLOSE"
```

Для реальных предметов (редкая легенда в day-7) шит опционально добавляет блок `StatComparisonView` — т.е. можно посмотреть, что этот лёгендный меч даст относительно текущей экипировки. Но это **Phase 2**, для текущего MVP достаточно title + description.

---

## 5. Layout — новая карусель

### 5.1 Рекомендация: убрать 168×168 hero, карусель становится центральным элементом

Текущий layout дублирует информацию: hero-карточка и strip оба показывают "сегодняшнюю" награду. Если карусель сделать крупной (инвентарь-size), hero становится избыточен — подсветим "Today" прямо в карусели свечением + рамкой, auto-scroll доскроллит её в центр.

**Плюсы:**
- Экран компактнее на ~200pt (нет двойного hero).
- Один визуальный элемент вместо двух — проще понять.
- Больше фокуса на timeline: игрок сразу видит "что сегодня, что вчера, что завтра".
- Клик по Today = открытие того же `RewardDetailSheet` = **одна точка входа в детали** (claim тоже через sheet).

**Минусы:**
- Нет "wow hero" эффекта, который сейчас делает 168×168 карточка с angular glow.
- Меньше "торжественности" момента клейма.

**Митигация:** fокусную карточку "Today" делаем крупнее остальных (124×124 vs 88×88), добавляем тот же angular rotating glow, что был на hero. Получаем "inline-hero" внутри карусели.

### 5.2 Альтернатива: оставить hero + добавить крупную карусель снизу

Если "wow hero" критичен — оставляем, но тогда экран становится длиннее, и hero дублирует карусель. Я не рекомендую, но это опция.

### 5.3 Финальный layout (Вариант A — рекомендуется)

```
┌─────────────────────────────────────┐
│  DAILY LOGIN                    (×) │
│                                     │
│        Day 2 Streak                 │  ← streak title (cinematicTitle)
│  Keep your streak for bonus rewards │  ← subtitle
│                                     │
│  Weekly Progress            3 / 7   │  ← progress bar (existing)
│  ████████████░░░░░░░░░░░░░░         │
│                                     │
│  TODAY'S REWARD                     │  ← секция label
│                                     │
│  ┌──────────────────────────────┐  │
│  │  ← [D1]  [D2] ┏━━━━━━━┓ [D4] → │   ← horizontal scroll
│  │              ┃  D3   ┃         │   D3 = highlighted (124×124, angular glow)
│  │              ┃ GOLD  ┃         │   D1, D2 = claimed (check, dimmed)
│  │              ┃ 300   ┃         │   D4..D7 = locked (muted)
│  │              ┗━━━━━━━┛         │   All tappable → RewardDetailSheet
│  └──────────────────────────────┘  │
│                                     │
│  ┌─ CLAIM REWARD ─────────────────┐│  ← primary CTA
│  └───────────────────────────────┘│
│                                     │
│  Tomorrow: ⚡ 2 S. Potions          │  ← footer hint
│                                     │
└─────────────────────────────────────┘
```

---

## 6. Размеры (inventory parity)

Инвентарь на iPhone Pro (393pt ширина) использует LazyVGrid с ~3-4 колонками → ширина карточки ~88–108pt. Беру **96×96** как базовый размер для карусели (карточки day 1,2,4–7), **124×124** для Today-карточки.

Spacing между карточками: `LayoutConstants.spaceSM` (8pt). Горизонтальный padding карусели: `LayoutConstants.screenPadding` (16pt) + contentMargins для edge-fade.

На экране помещается одновременно: 3 карточки 96pt + 1 центральная 124pt + gaps. Остальные — доступны скроллом.

---

## 7. Состояния карточки в карусели

| State | Visual |
|---|---|
| **Claimed** (day < displayDay) | ItemCardView rarity-color border, opacity 0.45, большая `checkmark.seal.fill` в центре (success color) |
| **Today / Current** (day == displayDay, canClaim) | ItemCardView 124×124, angular rotating glow (как текущий hero), сильная тень по rarity |
| **Locked / Future** (day > displayDay) | ItemCardView opacity 0.65, grayscale 0.3, маленькая иконка `icon-padlock` в bottom-right |
| **Premium day 7** | ItemCardView(.legendary) даже в locked-состоянии — показываем редкость заранее, чтобы мотивировать |

Подпись `D1`…`D7` под карточкой остаётся — тем же стилем, что сейчас, но с увеличенным tracking и размером, т.к. карточки крупнее.

---

## 8. Взаимодействие

1. **Открытие экрана:** карусель auto-scroll'ит к Today-карточке (`ScrollViewReader.scrollTo(day, anchor: .center)` с лёгким spring).
2. **Tap на карточку:** `HapticManager.tap()` + открытие `RewardDetailSheet` с соответствующим `RewardDisplayable`.
3. **Tap на Today в sheet'е:** CTA `CLAIM REWARD` → обычный claim flow через `vm.claimReward()`, после успеха sheet сам закрывается, карусель играет `claimedDayBounce` animation, карточка флипается в claimed-state.
4. **Tap на claimed-карточку:** открывает sheet с `CLAIMED ✓` (CTA = "CLOSE").
5. **Tap на locked-карточку:** открывает sheet с `LOCKED` overlay + CTA "COME BACK ON DAY X".

Все переходы — opacity only (правило `feedback_no_scale_animations`). Никаких scale grow/shrink.

---

## 9. Реюзабилити win

После имплементации одним компонентом `RewardDetailSheet` + `RewardDisplayable` покрываем 4 места:

1. ✅ Daily Login (задача)
2. ⏭ Battle Pass reward nodes — заменяем кастомный sheet
3. ⏭ Achievement rewards — заменяем кастомный sheet
4. ⏭ Mail attachments

Это оставлю в `docs/07_ui_ux/REWARD_DETAIL_UNIFICATION.md` после апрува — сделаю в фоне при миграции остальных экранов.

---

## 10. План работ (после апрува)

| # | Шаг | Файл |
|---|---|---|
| 1 | Создать `RewardDisplayable` protocol | `Hexbound/Models/RewardDisplayable.swift` (new) |
| 2 | Extension `DailyReward: RewardDisplayable` | `Hexbound/Models/DailyLoginData.swift` (extend) |
| 3 | Создать `RewardDetailSheet.swift` | `Hexbound/Views/Rewards/RewardDetailSheet.swift` (new) |
| 4 | Переписать `dayStrip` → `dayCarousel` в `DailyLoginDetailView` | `Hexbound/Views/DailyLogin/DailyLoginDetailView.swift` |
| 5 | Удалить `heroBlock` (merged into carousel) | `Hexbound/Views/DailyLogin/DailyLoginDetailView.swift` |
| 6 | Добавить файлы в `Hexbound.xcodeproj/project.pbxproj` (4 секции, random UUIDs) | `project.pbxproj` |
| 7 | CDO Verification scan (token check) | — |
| 8 | Figma DS mirror для `RewardDetailSheet` и `Reward Card` component | Figma DS file |

Оценка: ~2 часа кода + ~30 минут Figma mirror + pbxproj.

---

## 11. Risks

- **Auto-scroll race на первом кадре:** `ScrollViewReader` иногда не докручивается до `.center` если data грузится после `.onAppear`. Решение — `scrollTo(vm.displayDay, anchor: .center)` вызывать в `.onChange(of: vm.loginData)`, а не в `.onAppear`.
- **Locked-карточки "спойлерят" будущие награды** — это by design (мотивация), но если захочешь, могу добавить mystery-режим с "?" вместо иконки.
- **Day-7 legendary шит может перекосить layout** — если `displayName` длинный ("Legendary Chest"), проверяем `minimumScaleFactor(0.7)` на title.

---

## 12. Open questions (жду решения)

1. **Убираем hero 168×168 совсем или оставляем?** (я рекомендую убрать — Variant A выше)
2. **Mystery mode для locked?** (иконка "?" вместо превью награды)
3. **Auto-scroll к Today на открытии?** (я за — без него пользователь на day 7 увидит пустое начало)
4. **RewardDetailSheet — сразу миграция BP / Achievements, или только Daily Login в этой PR?** (я за только Daily Login, остальное отдельными PR)

Жду ответов и апрува — после этого перехожу к коду.
