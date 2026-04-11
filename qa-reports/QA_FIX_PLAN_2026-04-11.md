# Hexbound — QA Fix Plan 2026-04-11

**Источник**: `QA_REPORT_2026-04-10.md`
**Автор**: Claude (orchestrator)
**Режим**: план-перед-кодом — никаких правок до явного ОК от Artem

---

## Контекст

После `874effd` закрыто 19 багов. Осталось:

- **High живой**: BUG-47 — требует playtest, **не трогаем в этом проходе**
- **Medium живых**: 21 баг
- **Low**: 17 багов, не трогали

Этот план разбивает оставшиеся Medium + Low на **3 фазы** по размеру риска и типу работы. Каждая фаза требует отдельного ОК перед имплементацией.

---

## Phase 1 — Функциональные Medium (4 бага)

Эти баги ломают фичу, а не её внешний вид. Делаем первыми.

### BUG-34 — Referral code не загружается

**Статус**: [LIVE] — но точный корень не подтверждён; бэкенд и клиент по коду выглядят корректно.

**Диагноз (гипотезы по убыванию вероятности)**:
1. **Гость без персонажа**. `ReferralSectionView.loadReferralData()`:
   ```swift
   guard let charId = appState.currentCharacter?.id else { return }
   ```
   При `return` не выставляется ни `loadFailed`, ни `referralCode` → `"Loading..."` навсегда. Но в отчёте видно error state → значит `currentCharacter` был, fetch вернулся с ошибкой.
2. **Stale Prisma client**. Таблица `character` содержит `referralCode` / `referredBy` поля, но если на VM был запущен старый клиент — GET падает с `Unknown field`.
3. **Guest auth timing**. JWT ещё не готов к моменту первого `.task` при cold-start.
4. **500 без видимой причины** — `console.error` в бэкенде, но мы его не видим из клиента (показывается только "Could not load referral code").

**Патч (поэтапный)**:
1. **Наблюдаемость**: на клиенте в `catch` логировать `(error as NSError).localizedDescription` + HTTP status. На бэкенде добавить explicit `console.error('GET /tutorial/referral failed', { userId, characterId, error })`.
2. **Guard отсутствия персонажа**: если `currentCharacter == nil`, показать отдельный "Create a character to get your invite code" state, а не бесконечный спиннер.
3. **Retry с exponential backoff** на первый 500/timeout (1 попытка) перед показом error-state.

**Поверхности**:
- `Hexbound/Hexbound/Views/Settings/ReferralSectionView.swift`
- `backend/src/app/api/tutorial/referral/route.ts`

**Риски**: низкие. Добавляем логи + edge-case UI.

**Оценка**: ~60 строк клиента + 10 строк бэкенда. Нужен runtime playtest после фикса.

---

### BUG-35 — Push Notifications toggle без iOS permission prompt

**Статус**: [LIVE] — **подтверждён в коде**.

**Диагноз**: `SettingsViewModel.swift`:
```swift
var pushNotifications: Bool {
    get { settings.pushNotifications }
    set { settings.pushNotifications = newValue }
}
```
Сеттер только пишет в local storage — никогда не вызывает `PushNotificationService.requestPermissionAndRegister()`. Toggle UI показывает ON (дефолт), но iOS ни разу не запрошен.

**Патч**:
1. В `SettingsViewModel` заменить простой setter на async действие:
   - при ON: читать `UNUserNotificationCenter.current().notificationSettings().authorizationStatus`
     - `.notDetermined` → `requestPermissionAndRegister()`, выставить toggle по факту granted/denied
     - `.denied` → показать toast "Enable push in iOS Settings → Hexbound" + открыть `UIApplication.openSettingsURLString`, оставить toggle OFF
     - `.authorized` → писать в settings
   - при OFF: писать в settings + вызвать `/api/push/unregister` (если есть) или просто остановить доставку локально
2. Дефолт toggle = **OFF** до первого явного согласия. Никогда не показывать ON без подтверждённого `.authorized`.
3. `.task` на Settings screen: синкать toggle с фактическим `authorizationStatus` на каждый онапир.

**Поверхности**:
- `Hexbound/Hexbound/Views/Settings/SettingsViewModel.swift`
- `Hexbound/Hexbound/Services/PushNotificationService.swift` (возможно доработать)
- `Hexbound/Hexbound/Views/Settings/SettingsView.swift` (подписка на `.task`)

**Риски**: низкие. iOS permission API стабилен.

**Оценка**: ~80 строк ViewModel + 20 строк View.

---

### BUG-54 — Inbox BATTLES tab пуст после PvP

**Статус**: [LIVE] — код по всем слоям выглядит корректно, проблема в runtime.

**Диагноз (гипотезы)**:
1. **Silent try/catch в `battle-mail.ts`** глотает ошибку:
   ```typescript
   } catch (error) {
     console.error('Failed to create battle result mail:', error)
   }
   ```
   Почтовые сообщения не создаются, но сам матч закрывается — UI не видит ошибки.
2. **Race condition**: клиент делает `GET /api/mail` до того, как `battle-mail` завершил транзакцию. После обновления Inbox (pull-to-refresh) сообщения есть.
3. **`senderType` mismatch**: в схеме Prisma поле называется иначе, или модель клиента не ест `"arena_result"` (мы видели код — он читает правильно, но схема могла измениться).

**Патч (поэтапный)**:
1. **Восстановить видимость ошибок**: заменить `console.error` на `console.error` + write to analytics + throw, если окружение `development`. В production оставить не-фатальным, но ЯВНО логировать user-facing.
2. **Refresh-after-PvP**: после `/api/pvp/resolve` клиент должен принудительно инвалидировать InboxViewModel кэш (сейчас полагается на следующий tab switch).
3. **Runtime проверка schema**: `node -e "console.log(require('./backend/node_modules/.prisma/client').MailMessage)"` для подтверждения актуальности клиента.
4. **Log-assert в `battle-mail.ts`**: после `prisma.$transaction` логировать `id` созданных писем.

**Поверхности**:
- `backend/src/lib/game/battle-mail.ts`
- `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift` (invalidation)
- `Hexbound/Hexbound/Views/Combat/` (post-resolve hook)

**Риски**: средние. Если корень — race, нужно менять где именно клиент делает refetch после `resolve`.

**Оценка**: ~30 строк бэкенда + ~40 строк клиента. Нужен playtest 2 PvP подряд.

---

### BUG-56 — Castle Hub building labels некликабельны

**Статус**: [LIVE] — **подтверждён в коде**.

**Диагноз**: `CityBuildingView.swift`:
```swift
VStack(spacing: LayoutConstants.spaceXS) {
    if !spriteOnly {
        CityBuildingLabel(text: building.label, ...)
            .offset(y: building.labelYOffset * terrainSize.height + 10)  // ← проблема
    }
    ZStack { buildingImage ... }
}
.position(x: posX, y: posY)
.onTapGesture { handleTap() }
```

Две проблемы сразу:
1. `.offset(y:)` сдвигает лейбл **визуально**, но hit-test зона остаётся на изначальной позиции VStack'а. Игрок тапает туда, где видит лейбл — попадает в пустоту.
2. Лейбл стилизован как dark pill с яркой gold-типографикой ⇒ воспринимается как кнопка. UX affordance обманывает.

**Патч (выбираем один из двух)**:

**Вариант A (минимальный, рекомендую)**:
- Заменить `.offset(y: ...)` на `.padding(.top, building.labelYOffset * terrainSize.height + 10)` или переместить в отдельный `ZStack` с корректным layout. VStack окажется корректно растянут — тап по лейблу пройдёт в `handleTap()`.
- Оставить pill-стиль — он и есть button affordance, теперь честный.

**Вариант B (декоративный)**:
- Сделать лейбл явно некликабельным: плоский текст без pill-фона, меньший контраст, `allowsHitTesting(false)`.
- Сохранить hit-test только на спрайт.
- Не обманывает affordance, но теряем дополнительный touch-target.

**Решение**: я за **Вариант A** — расширяем hit-test, сохраняя премиальный вид. Вариант B — запасной, если A сломает layout спрайтов.

**Поверхности**:
- `Hexbound/Hexbound/Views/Hub/CityBuildingView.swift`

**Риски**: средние. Может сдвинуть вертикальное положение всех зданий на карте → потребуется pass по всем `building.labelYOffset` в данных.

**Оценка**: ~20 строк кода + визуальный regression test на всех 10 зданиях хаба.

---

## Phase 2 — Косметические Medium (кластеры)

21 баг, сгруппированы по файлам для одного PR за кластер.

### Кластер 2A — Character Creation UX

**Баги**: BUG-01, 02, 03, 04, 07

| BUG | Фикс |
|---|---|
| 01 | Выровнять `Assassin`/`Guardian` в UI с enum `rogue`/`tank` — либо ввести display-name словарь, либо переименовать enum (я за словарь). |
| 02 | Guardian selected state: применить ту же `.fight`/gold highlight как у остальных классов. |
| 03 | Appearance: показать итоговый stat-блок под расой, как на CLASS step. |
| 04 | Charisma: либо добавить в `Character.baseStats`, либо убрать из Human-бонусов. Нужно решение от game design. |
| 07 | Female gender: проверить `onTap` handler, показать fallback-toast если нет female-ассета для расы. |

**Поверхности**: `Views/CharacterCreation/*.swift`

**Оценка**: ~150 строк. BUG-04 блокирован решением от game design.

---

### Кластер 2B — Copy / Terminology

**Баги**: BUG-09, 25, 26, 43

| BUG | Фикс |
|---|---|
| 09 | Обрезанный story-текст: добавить `.fixedSize(horizontal: false, vertical: true)` + проверить `maxWidth`. |
| 25 | Daily Quest "Warrior" → переименовать в "PvP Duelist" или матчить action. |
| 26 | Random gold target `1353` → округлять до `1500`/`2000` через `roundToNice(_:)` в генераторе квестов. |
| 43 | Unify `Stamina`/`Energy`/`⚡`: выбрать **Stamina**, заменить везде. Grep для поверхностей. |

**Поверхности**: `Views/Onboarding/StoryView.swift`, `backend/src/lib/game/quests/*.ts`, все экраны с `Energy`

**Оценка**: ~60 строк + grep-sweep на `Energy`.

---

### Кластер 2C — Victory / Level-up Flow

**Баги**: BUG-17, 18

| BUG | Фикс |
|---|---|
| 17 | Victory screen не обновляется после Level Up modal: после dismiss modal'а инвалидировать `VictoryViewModel.hero` и перерисовать. |
| 18 | Двойной показ Victory: проверить условие переоткрытия, вероятно `.onChange(character)` триггерит re-present. |

**Поверхности**: `Views/Combat/VictoryView.swift`, `LevelUpModal.swift`

**Оценка**: ~40 строк.

---

### Кластер 2D — Inventory / Shop / Pre-fight

**Баги**: BUG-11, 14, 31, 40, 41, 48, 49, 50, 61

| BUG | Фикс |
|---|---|
| 11 | Winrate цвета: swap зелёный/красный в `statPillColor(winRate:)`. |
| 14 | Pre-fight modal: показать все 7 stats либо объяснить почему 3. |
| 31, 61 | `ATTACK CHEST / DEFENSE CHEST`: переписать label на `ATTACK: <item name>` / `DEFENSE: <slot>`. Удалить "CHEST" как текст. |
| 40 | Shop quantity selector: добавить явный `Stepper`-look с +/− кнопками. |
| 41 | Large Stamina Potion: добавить `description` в Supabase item + sync. |
| 48 | Small HP Potion: пересчитать heal amount в `consumable-effects.ts` (33% вместо фикс. 50). |
| 49 | "Health is low" banner: перепроверять на каждый HP change, скрывать при `hp/maxHp > 0.3`. |
| 50 | Stamina potion at max: добавить client-side guard + server 400 `"Already at max"`. |

**Поверхности**: широкие — `Views/Inventory/*`, `Views/Shop/*`, `Views/Arena/PreFightModal.swift`, `backend/src/lib/game/consumable-effects.ts`, Supabase `items` table.

**Оценка**: ~200 строк + 1 Supabase update.

---

## Phase 3 — Low sweep (17 багов)

Однотипные косметические — один PR на всё:

BUG-05, 06, 10, 12, 15, 16, 21, 22, 24, 27, 29, 32, 33, 36, 38, 55, 60

**Подход**: читаем отчёт сверху вниз, правим мелочи, коммитим одним `fix(qa): low-sweep 2026-04-11 — 17 cosmetic fixes` с явным списком в body.

**Оценка**: ~300 строк спредом по 15-20 файлам.

---

## Что НЕ делаем в этом проходе

- **BUG-47** — ждёт playtest в Training Camp Stage 2
- **BUG-63** (если он есть) — ждёт playtest
- **Any Critical/High** — уже закрыты

---

## Порядок работы (когда Artem даст ОК)

1. **Phase 1** — 4 бага, каждый со своим коммитом. После каждого — CDO verification scan.
2. **Approval gate** → **Phase 2** — кластер за кластером, 4 коммита.
3. **Approval gate** → **Phase 3** — один коммит.
4. **Финальный retro**: обновить `QA_REPORT_2026-04-10.md` — все `[LIVE]` → `[FIXED <sha>]`.

---

## Риски и допущения

- **Runtime-зависимые баги (34, 54)** требуют playtest после фикса — нельзя закрывать без повторной проверки.
- **BUG-56** может потребовать пересчёта `labelYOffset` для всех зданий — визуальный regression по всему хабу.
- **BUG-04 (Charisma)** блокирован решением от game design — кому и зачем нужна Charisma вне расы Human.
- **Phase 2D** трогает Supabase items (BUG-41) — нужен direct edit + iOS cache invalidation.
