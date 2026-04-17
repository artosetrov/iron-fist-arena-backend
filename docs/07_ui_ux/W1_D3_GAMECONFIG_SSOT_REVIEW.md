# W1.D3 — GameConfig SSoT (ревью перед кодом)

**Автор:** Claude (orchestrator)
**Дата:** 2026-04-10
**Скоуп:** W1.D3 Hexbound QA Fix Plan
**Статус:** Ожидает одобрения Артёма

> **Status boundary:** historical review-before-code snapshot tied to the W1.D3 planning moment. Keep it as rationale and evidence, not as the current approval queue or live GameConfig rollout plan.

---

## TL;DR

Хорошая новость: **80% инфраструктуры уже построено**. Бэкенд отдаёт `config` в `/api/game/init`, iOS парсит его в `GameConfig` struct, кладёт в `GameDataCache`. Мы просто **не дочитываем** поля и **не подключаем** экраны к кэшу.

Фикс поэтому хирургический, не архитектурный. Я вижу 3 раунда работы:

| Раунд | Что | Размер |
|---|---|---|
| **R1** (сейчас, W1.D3) | Daily Login — витрина эффекта, убивает CRIT-02 навсегда | ~4 ч |
| **R2** (W3) | ProgressionCurve, UpgradeChances, StaminaConfig на экранах | ~3 ч |
| **R3** (W4 Polish) | Disk-persist + offline-first + version gate | ~3 ч |

W1.D3 = **R1 only**. R2/R3 помечаем follow-up.

---

## Что я нашёл в коде (recon)

### Backend — уже готово ✅

`backend/src/app/api/game/init/route.ts` строки 280–302 возвращают:
```ts
const config = {
  staminaMax, staminaRegenMinutes, hpRegenPercent, hpRegenMinutes,
  pvpStaminaCost, freePvpPerDay, upgradeChances,
  maxLevel, statPointsPerLevel,
  pvpWinGold, pvpLossGold, pvpWinXp, pvpLossXp,
  critMultiplier, maxCritChance, maxDodgeChance,
  dailyLoginRewards: dailyLoginRewardsConfig,   // ← УЖЕ ЗДЕСЬ
  eloCalibrationGames,
  pvpRanks,
  battlePass,
}
```

Все эти поля читаются через `live-config.ts` → `game_config` таблица → `balance.ts` fallback. То есть admin panel **уже может** менять эти значения в рантайме без релиза. Подтверждено прод-запросом: `SELECT key FROM game_config WHERE key = 'daily_login_rewards'` → пусто → fallback работает.

### iOS — инфраструктура есть, но половина выброшена ⚠️

**`Hexbound/Services/GameInitService.swift` строка 79:**
```swift
if let config = response["config"] as? [String: Any] {
    cache.gameConfig = GameConfig(from: config)  // ← ОК, парсим
}
```

**`Hexbound/Services/GameDataCache.swift` строки 541–572:**
```swift
struct GameConfig {
    let staminaMax: Int
    // ... 14 полей ...
    let maxDodgeChance: Int
    // ❌ dailyLoginRewards пропущено
    // ❌ eloCalibrationGames пропущено
    // ❌ pvpRanks пропущено
    // ❌ battlePass пропущено
}
```

**`Hexbound/Models/DailyLoginData.swift` строки 26–35:**
```swift
static let rewards: [DailyReward] = [ /* захардкожено */ ]
```

Экран дейли-логина читает `DailyLoginData.rewards` напрямую — **никогда** не смотрит в `cache.gameConfig`. Именно поэтому CRIT-02 вообще возник: клиент и сервер живут в параллельных вселенных, синхронизировать их нужно руками каждый раз.

---

## Предложенный фикс (R1 — W1.D3)

### Шаг 1. Типизированная модель iOS

Создать `Hexbound/Models/DailyLoginRewardDef.swift`:
```swift
struct DailyLoginRewardDef: Codable, Equatable {
    let type: String        // "gold" | "gems" | "consumable"
    let amount: Int
    let itemId: String?     // present only for consumables

    // MARK: - Display (view-layer derivation, not model state)
    var assetIcon: String {
        switch type {
        case "gold":       return "icon-gold"
        case "gems":       return "icon-gems"
        case "consumable": return "icon-stamina"  // TODO: lookup by itemId
        default:           return "icon-gold"
        }
    }

    var label: String {
        switch type {
        case "gold":       return "\(amount) Gold"
        case "gems":       return "\(amount) Gems"
        case "consumable":
            switch itemId {
            case "stamina_potion_small": return amount == 1 ? "1 S. Potion"  : "\(amount) S. Potions"
            case "stamina_potion_large": return amount == 1 ? "1 L. Potion"  : "\(amount) L. Potions"
            case "health_potion_small":  return amount == 1 ? "1 HP Potion"  : "\(amount) HP Potions"
            default:                      return "\(amount)×"
            }
        default: return "\(amount)"
        }
    }

    var description: String { label }   // can expand later
}
```

**Rationale:** label/icon деривации живут на view-слое, не в state. Когда бэк пришлёт новый `itemId`, клиент покажет fallback `\(amount)×` — некрасиво, но не падает.

### Шаг 2. Расширить `GameConfig`

`Hexbound/Services/GameDataCache.swift`:
```swift
struct GameConfig {
    // ... existing 14 fields ...
    let dailyLoginRewards: [DailyLoginRewardDef]   // ← NEW

    init(from dict: [String: Any]) {
        // ... existing parsing ...
        self.dailyLoginRewards = Self.parseDailyRewards(dict["dailyLoginRewards"])
    }

    private static func parseDailyRewards(_ raw: Any?) -> [DailyLoginRewardDef] {
        guard let array = raw as? [[String: Any]] else { return Self.fallbackDailyRewards }
        let decoder = JSONDecoder()
        guard let data = try? JSONSerialization.data(withJSONObject: array),
              let parsed = try? decoder.decode([DailyLoginRewardDef].self, from: data),
              parsed.count == 7 else {
            #if DEBUG
            print("[GameConfig] dailyLoginRewards parse failed, using fallback")
            #endif
            Analytics.log("gameconfig_fallback", properties: ["key": "dailyLoginRewards"])
            return Self.fallbackDailyRewards
        }
        return parsed
    }

    /// Bundled fallback — ровно то, что сейчас в `DAILY_LOGIN_REWARDS` на бэке.
    /// Обновляется вместе с `balance.ts`. Используется только если сеть сдохла
    /// до первого успешного init (cold start + offline).
    static let fallbackDailyRewards: [DailyLoginRewardDef] = [
        .init(type: "gold",       amount: 150, itemId: nil),
        .init(type: "consumable", amount: 1,   itemId: "stamina_potion_small"),
        .init(type: "gold",       amount: 300, itemId: nil),
        .init(type: "consumable", amount: 2,   itemId: "stamina_potion_small"),
        .init(type: "gold",       amount: 500, itemId: nil),
        .init(type: "consumable", amount: 1,   itemId: "stamina_potion_large"),
        .init(type: "gems",       amount: 25,  itemId: nil),
    ]
}
```

### Шаг 3. Переключить `DailyLoginData.rewards` на кэш

Опция A (предпочтительная): **убить статический массив** и сделать helper на viewmodel-уровне.

`Hexbound/Models/DailyLoginData.swift`:
```swift
struct DailyReward {
    let day: Int
    let assetIcon: String
    let label: String
    let description: String
}

extension DailyReward {
    /// Build display rewards from live server config.
    /// Falls back to bundled constants if cache is empty (cold start).
    static func rewards(from cache: GameDataCache) -> [DailyReward] {
        let source = cache.gameConfig?.dailyLoginRewards
            ?? GameConfig.fallbackDailyRewards
        return source.enumerated().map { index, def in
            DailyReward(
                day: index + 1,
                assetIcon: def.assetIcon,
                label: def.label,
                description: def.description
            )
        }
    }
}
```

Все callers (`DailyLoginView`, `DailyLoginViewModel`, etc.) переписываем на `DailyReward.rewards(from: cache)`. Это grep по `DailyLoginData.rewards` или `DailyReward.rewards` — нужно пройтись по ВСЕМ вызовам (правило "check all callers" из memory).

### Шаг 4. Логирование fallback в проде

Добавить простой счётчик: каждый раз, когда `parseDailyRewards` падает на fallback, пишем в telemetry/Analytics. Если в TestFlight вдруг видим всплеск fallback — значит бэк ломает схему, и это красный флаг до релиза.

(Если Analytics ещё не подключён — кладу `print` + TODO на R3.)

### Шаг 5. Verification

- `grep -rn "DailyLoginData.rewards\|DailyReward.rewards" Hexbound/` — ни одного caller не осталось на старом API.
- CDO full scan (как после CRIT-02/03).
- `npx tsc --noEmit` в backend (ничего не должно измениться, проверка на всякий).
- Руками: запустить app, открыть экран Daily Login, убедиться что карточки те же (150/pot/300/pot/500/pot/25 gems).
- Руками: выключить сеть, холодный старт → fallback путь → карточки те же.

---

## Что я НЕ делаю в R1 (осознанно)

1. **Disk persistence `gameConfig`** (R3). Сейчас после kill app + offline restart → `cache.gameConfig == nil` → fallback. Это норм для CRIT-02 — fallback уже правильный. Диск добавим в W4 Polish когда будем делать offline mode.
2. **Version gate на config** (R3). Схема `DailyLoginRewardDef` не имеет `configVersion`. Если бэк добавит поле — клиент его проигнорирует, не упадёт. Когда будут breaking changes — введём `gameConfig.version` и force-update gate.
3. **Остальные поля config** (R2). `eloCalibrationGames`, `pvpRanks`, `battlePass` — не трогаем пока их не используют экраны. Добавим по необходимости.
4. **`ProgressionCurve` (XP formula)** (R2). Сейчас на клиенте захардкожен `100(L+1) + 20(L+1)^2`. Для W1.D3 не критично — бэк валидирует все левел-апы сам, client-side формула только для UI progress-бара.
5. **Admin UI для редактирования `daily_login_rewards`** (отдельный тикет, не в roadmap). Ключ уже читается из `game_config`, но в admin panel нужно поле для редактирования JSON. Не блокер W1.

---

## Риски и edge cases

| Риск | Митигация |
|---|---|
| Бэк меняет `itemId` на новый (`stamina_potion_xl`) | `label` показывает fallback `"\(amount)×"`, не падает |
| Бэк меняет число ревардов (8 вместо 7) | `guard parsed.count == 7` → fallback + warning |
| `type` становится enum на сервере | Парсим как `String`, устойчиво |
| В `game_config.daily_login_rewards` положили мусор | `JSONDecoder` бросит → fallback |
| Оффлайн холодный старт | `cache.gameConfig == nil` → fallback (все 7 дней те же что на сервере) |
| Race: экран открылся ДО `game/init` ответа | `cache.gameConfig == nil` → fallback (один тик), потом `@Observable` перерисует с live данными |

---

## Список файлов, которые изменю

| Файл | Изменение |
|---|---|
| `Hexbound/Hexbound/Models/DailyLoginRewardDef.swift` | **NEW** — типизированная модель + label/icon деривация |
| `Hexbound/Hexbound/Models/DailyLoginData.swift` | Убрать статический массив, добавить `DailyReward.rewards(from:)` |
| `Hexbound/Hexbound/Services/GameDataCache.swift` | Расширить `GameConfig` на `dailyLoginRewards` + fallback |
| `Hexbound/Hexbound/Views/.../DailyLoginView.swift` | Переключить callers на новый API |
| `Hexbound/Hexbound/Views/.../DailyLoginViewModel.swift` | (если есть) переключить callers |
| `Hexbound/Hexbound.xcodeproj/project.pbxproj` | Добавить `DailyLoginRewardDef.swift` (4 секции, рандомные ID через openssl) |

**Не трогаю:** backend, Figma, xcassets.

---

## Оценка времени

| Шаг | Оценка |
|---|---|
| Шаг 1 — создать `DailyLoginRewardDef.swift` + добавить в pbxproj | 20 мин |
| Шаг 2 — расширить `GameConfig` | 20 мин |
| Шаг 3 — переписать `DailyLoginData` + найти всех callers | 40 мин |
| Шаг 4 — fallback логгинг | 10 мин |
| Шаг 5 — верификация (CDO, tsc, ручной smoke) | 30 мин |
| **Итого** | **~2 ч** |

План писал 8 ч — реальность сильно ниже, потому что 80% уже готово.

---

## Открытые вопросы для Артёма

1. **Формат label'ов.** Сейчас я предлагаю хардкодить мапу `itemId → label` ("stamina_potion_small" → "S. Potion") на клиенте. Альтернатива: бэк кладёт `displayName` и `displayIcon` прямо в reward, клиент тупой. Второй вариант архитектурно правильнее, но это +15 мин работы на бэке и я его в R1 **не** планировал. **Да/нет?**

2. **Item icon для консумейблов.** Сейчас все консумейбл-реварды получат `icon-stamina` (единственный в цепочке). Если когда-то будет HP potion в daily — надо маппинг. Делать сразу маппинг по всем консумейблам из enum — **да/нет?**

3. **R2 куда?** `ProgressionCurve` + `UpgradeChances` + `StaminaConfig` вынести в W3 (Balance) или в W1.D5 (CI guards)? Логичнее в W3, но если хочется раньше — можно.

4. **Fallback как single source.** Сейчас fallback будет в `GameConfig.fallbackDailyRewards`, а статический `DailyLoginData.rewards` умрёт. Хорошо — единый источник правды. Подтверди, что это ок.

---

## Готов кодить по зелёному свету

Если всё ок — отвечай "да" / "ок" / "погнали" и я начинаю с Шага 1. Если по какому-то пункту возражения — говори, я правлю план.
