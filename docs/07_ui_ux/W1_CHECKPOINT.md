# W1 Foundation — Checkpoint Report

**Дата:** 2026-04-10
**Статус:** ✅ Все automated gates пройдены, ждёт manual QA от Артёма
**Tag target:** `v2026.04.17-w1-foundation`

> **Status boundary:** historical checkpoint snapshot for the W1 foundation slice. Useful as evidence of what was believed complete on `2026-04-10`, but not a live readiness verdict for the current repo state.

---

## Объём W1 (5 дней)

| День | Commit | Описание |
|---|---|---|
| **W1.D1** | `e03766f` | CRIT-01 — `freePvpPerDay` unified iOS↔backend via `GameConfig` |
| **W1.D2** | `1b59bc7` | CRIT-02 daily login drift + CRIT-03 hub HP/XP hierarchy |
| **W1.D3** | `61ad39b` | Daily Login → `GameConfig` SSoT, 7-day table из `balance.ts` |
| **W1.D4** | `57b4f80` | `BALANCE_CONSTANTS_AUTO.md` auto-gen + drift check |
| **W1.D5** | `5e65db5` | `check_ios_backend_drift.sh` iOS hardcode guard |

Связанные отчёты: `W1_D3_GAMECONFIG_SSOT_REVIEW.md`, `W1_D4_BALANCE_DOCS_AUTOGEN.md`, `W1_D5_DRIFT_GUARD.md`.

---

## Automated gates

### 1. Preflight (`gatekeeper`) ✅

```
=== HEXBOUND PREFLIGHT ===
## Changed Files
  - docs/07_ui_ux/W1_D4_BALANCE_DOCS_AUTOGEN.md
  - docs/07_ui_ux/W1_D5_DRIFT_GUARD.md
===============================
✅ VERDICT: READY TO COMMIT
===============================
```

### 2. CDO Full Scan ✅

Все 10 проверок пройдены:

| # | Check | Result |
|---|---|---|
| 1 | Invented font tokens (`largeTitleFont`, etc.) | ✅ CLEAN |
| 2 | `font(size:)` functions | ✅ CLEAN |
| 3 | Invented spacing tokens (`spacingXL`, etc.) | ✅ CLEAN |
| 4 | `Color(hex:)` в Views | ✅ CLEAN (1 false positive — MARK comment) |
| 5 | Hardcoded system fonts | ✅ CLEAN |
| 6 | Raw `Color.red/orange/...` | ✅ CLEAN |
| 7 | SF Symbol currency icons | ✅ CLEAN |
| 8 | Hardcoded `cornerRadius: N` | ✅ CLEAN (1 doc-comment, 1 явный `// keep` декоративный 1px) |
| 9 | Junk files в xcodeproj | ✅ CLEAN |
| 10 | Merge conflict markers | ✅ CLEAN |

### 3. iOS/Backend Drift Guard ✅

```
## AppConstants.swift declarations
  ✅ line 84: static let maxStamina = 120 — deprecated, skipped
  ✅ line 86: static let freePvpPerDay = 3 — deprecated, skipped
  ✅ line 88: static let pvpStaminaCost = 10 — deprecated, skipped
## iOS sources outside AppConstants.swift
  ✅ no loose declarations
✅ CLEAN: no iOS/backend constant drift
```

### 4. Balance Docs Drift Check ✅

```
$ cd backend && npm run docs:balance:check
# silent, exit 0
```

`BALANCE_CONSTANTS_AUTO.md` синхронизирован с `balance.ts`.

### 5. Prisma Schema Sync ✅

`backend/prisma/schema.prisma` === `admin/prisma/schema.prisma` (diff = 0 lines).

---

## Agent Reviews

### `hexbound-studio:guardian` (iOS) — APPROVED WITH NOTES

**Passing:**
- Cache-first pattern корректно в `CityMapView:221` и `ArenaViewModel:56`
- `DailyLoginData.swift` — нет hardcoded 7-day table, всё из `balance.ts` через `GameConfig`
- `DailyLoginDetailView.swift` — `@Environment(GameDataCache.self)` injected, все 4 call sites `DailyReward.rewards(from: cache)` на строках 180/188/195/305
- `DailyLoginPopupViewModel` принимает `cache: GameDataCache` в init
- `DailyLoginRewardDef.swift` — 4 записи в pbxproj (PBXBuildFile, PBXFileReference, PBXGroup, Sources)
- `@MainActor @Observable` корректно, `@Environment` DI правильный
- Zero `Color(hex:)`, zero `font(size:)`, zero изобретённых токенов
- `RoundedRectangle(cornerRadius:)` — везде `LayoutConstants.*` токены

**False positive (dismissed):**
- Агент пожаловался на расположение `// DEPRECATED` маркеров в `AppConstants.swift`, утверждая что они не на N-1 строке. **Проверено руками**: декларации на строках 84/86/88, маркеры на 83/85/87 — это ровно N-1. Positive test скрипта `check_ios_backend_drift.sh` проходит чисто. Flag отклонён.

### `hexbound-studio:oracle` (backend) — APPROVED

**Passing:**
- Type safety: нет `any` leaks, нет unsafe casts
- Async: `getDailyLoginRewardsConfig()` корректно `await` в `/api/game/init:274` внутри `Promise.all`
- Prisma schema sync: backend ↔ admin идентичны
- `DAILY_LOGIN_REWARDS` в `balance.ts:94-102` — единственный канонический 7-day cycle, экспонирован через `/api/game/init:298` как `config.dailyLoginRewards`. Нет вторичных hardcoded таблиц.
- `freePvpPerDay`: `staminaConfig.FREE_PVP_PER_DAY:287` извлечён корректно, нет redundant DB queries (всё через `Promise.all`)
- `generate-balance-docs.ts`: детерминистичный вывод, `--check` режим валидирует drift, error handling через `try/catch` + `process.exit(1)`
- Server authority сохранён: client получает только config values, combat/rewards остаются server-side

**Known pre-existing debt (NOT W1, escalated to W4):**
- `backend/src/app/api/auth/guest-login.ts:52,143` — `deviceId` не в `UserWhereUniqueInput` / `UserCreateInput`. Pre-existing, не введено в W1
- 80 "missing await" patterns в кодовой базе — все pre-W1, в helper-функциях

---

## Manual QA Checklist (for Artem)

Requires simulator or device. Не могу выполнить сам — нужна твоя визуальная валидация.

### ✅ Onboarding smoke test
- [ ] Новый guest account: класс/раса/gender выбор → ОК
- [ ] Tutorial triggers: welcome gold +500 отображается
- [ ] Первый вход в Hub — без crash, все виджеты рендерятся

### ✅ CRIT-01: Free PvP per day (W1.D1)
- [ ] Hub → видно бадж "FREE 3" у арены (или текущее значение `cache.gameConfig.freePvpPerDay`)
- [ ] Arena detail: `pvpCount < 3` → бой без стамины, `>= 3` → стоит `pvpStaminaCost`
- [ ] После 3 боёв бадж меняется на "0 FREE"

### ✅ CRIT-02: Daily Login drift (W1.D2 + W1.D3)
- [ ] Hub → Daily Login popup показывается (если сегодня новый день)
- [ ] Day 1 reward = **150 gold** (должно совпадать с `balance.ts:DAILY_LOGIN_REWARDS[0]`)
- [ ] Day 7 highlighted с Day 7 badge (legendary chest)
- [ ] Progress dots: 3+3+1 grouping, current day подсвечен
- [ ] Claim → gold +150, popup dismissed, streak incremented

### ✅ CRIT-03: Hub HP/XP hierarchy (W1.D2)
- [ ] HP bar (характер) выше XP bar (progression) в визуальной иерархии
- [ ] XP bar показывает `current/next` и level число

### ✅ Architecture sanity
- [ ] Kill app → relaunch → все config значения те же (cache persistence W4, сейчас in-memory)
- [ ] Network throttle: `/api/game/init` timeout → fallback `AppConstants` значения работают

### ⚠️ Known issues (не блокируют W1)
- Preflight emoji-counter line 110 bash warning — pre-existing, не W1
- `pvpStaminaCost` direct reads в `ArenaViewModel:82,86` и `ArenaDetailView:280` — W4 Polish debt
- `maxStamina` — dead unused константа, W4 удалит
- `guest-login.ts` tsc errors — W4 Polish

---

## Verdict

**Automated gates:** ✅ ALL PASS
**Agent reviews:** ✅ APPROVED (guardian with 1 false positive dismissed, oracle clean)
**Manual QA:** ⏳ PENDING (Artem)

После manual QA → tag `v2026.04.17-w1-foundation` → переход в **W2 (Onboarding hook — 5 дней)**.

---

## Следующие шаги

1. **Артём делает manual QA** по чеклисту выше
2. Если всё ок → `.git-trigger` с сообщением `chore(w1): checkpoint — tag v2026.04.17-w1-foundation` + отдельная команда watcher'у: `git tag v2026.04.17-w1-foundation && git push --tags`
3. Если найдены регрессии → фикс → перезапуск checkpoint
4. После тега → начало **W2** (Onboarding compression, D1 retention +15-25% target)

---

## Appendix: W1 metrics

| Метрика | Значение |
|---|---|
| Commits | 5 (D1-D5) |
| Files touched | ~15 iOS + ~8 backend + ~3 docs |
| Net LOC | ~1200 added, ~300 removed |
| Critical bugs fixed | 3 (CRIT-01, CRIT-02, CRIT-03) |
| New CI guards | 2 (balance docs drift, iOS hardcode guard) |
| New auto-docs | 1 (`BALANCE_CONSTANTS_AUTO.md`, 459 LOC) |
| Known debt created | 0 |
| Known debt escalated to W4 | 3 items |
