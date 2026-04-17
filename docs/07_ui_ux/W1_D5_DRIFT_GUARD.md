# W1.D5 — iOS/Backend Constant Drift Guard (completion report)

**Автор:** Claude (orchestrator)
**Дата:** 2026-04-10
**Скоуп:** W1.D5 Hexbound QA Fix Plan
**Статус:** ✅ Завершено

> **Status boundary:** historical completion report for the first iOS/backend drift-guard rollout. Useful as provenance, but not a substitute for checking the current guard scripts and active CI/preflight wiring.

---

## TL;DR

Новый CI-гард `scripts/check_ios_backend_drift.sh` ловит любые попытки захардкодить game-константы в iOS-коде, которые обязаны приходить с бэкенда через `GameConfig` → `/api/game/init`. Существующие fallback'ы явно помечены `// DEPRECATED`. Подключено к preflight как секция 9 — блокирует коммит при нарушении.

Вместе с W1.D4 (balance docs autogen) это закрывает **inbound-канал drift'а**: Swift код больше не может "отрастить" параллельный источник истины балансу.

---

## Что сделано

### 1. Guard script: `scripts/check_ios_backend_drift.sh` (134 LOC, новый, executable)

**Forbidden pattern list:**

```
freePvpPerDay | maxStamina | pvpStaminaCost | xpPerLevel
```

Это имена констант, которые уже существуют в `balance.ts` → `GameConfig`. Расширяется по мере роста `GameConfig` surface (W3 retuning добавит ещё).

**Две проверки:**

**Check 1 — AppConstants.swift:**

Для каждой строки `static let <forbidden> = ...` скрипт смотрит на **предыдущую строку**. Если там нет `// DEPRECATED` — violation. Это позволяет оставить существующие fallback'ы как "официально deprecated", а любой новый `static let freePvpPerDay = 5` немедленно падает.

```bash
while IFS= read -r match; do
  lineno="${match%%:*}"
  prev_line=$(sed -n "$((lineno - 1))p" "$APPCONSTANTS")
  if echo "$prev_line" | grep -q '// DEPRECATED'; then
    echo "  ✅ line $lineno ... deprecated, skipped"
  else
    echo "  ❌ line $lineno ..."
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done < <(grep -nE "static let ($FORBIDDEN) *=" "$APPCONSTANTS")
```

**Check 2 — всё остальное в `Hexbound/Hexbound/`:**

```bash
grep -rnE "(static )?let ($FORBIDDEN) *= *[0-9]" "$IOS_ROOT" --include="*.swift" \
  | grep -v "$APPCONSTANTS"
```

**Здесь allowlist'а нет вообще** — любое объявление вне `AppConstants.swift` сразу падает. Логика: если константа уже есть в `GameConfig`, прятать её "ещё один раз" в ViewModel или View — это гарантированный bug.

**Exit codes:**

- 0 — clean
- 1 — drift detected (с actionable сообщением: какая константа, где, и куда её переместить)

### 2. `AppConstants.swift` — явные DEPRECATED markers

До:

```swift
// MARK: - Game
static let maxStamina = 120
/// Fallback only — real value comes from /api/game/init via cache.gameConfig.freePvpPerDay.
/// Do NOT read directly in UI code. ...
static let freePvpPerDay = 3
static let pvpStaminaCost = 10
```

После:

```swift
// MARK: - Game (DEPRECATED fallbacks)
//
// ⚠️ These constants are DEPRECATED fallbacks only. The real values come from
// /api/game/init → cache.gameConfig.* and must be read cache-first with these
// as last-resort fallbacks (see CityMapView, ArenaViewModel for pattern).
//
// Do NOT add new hardcoded game constants here. The check_ios_backend_drift.sh
// preflight guard will block any new static let additions matching the forbidden
// name pattern. New game constants belong in backend/src/lib/game/balance.ts and
// must be exposed via GameConfig → /api/game/init.
//
// W4 Polish will remove these entirely once the SSoT migration is disk-persisted
// and version-gated.

// DEPRECATED: use cache.gameConfig.maxStamina — unused fallback, pending W4 removal
static let maxStamina = 120
// DEPRECATED: use cache.gameConfig.freePvpPerDay — migrated 2026-04-09 (W1.D3), kept as fallback
static let freePvpPerDay = 3
// DEPRECATED: use cache.gameConfig.pvpStaminaCost — pending full migration in W4
static let pvpStaminaCost = 10
```

Каждая строка имеет `// DEPRECATED` на строке выше → guard их пропускает. Но любая новая попытка добавить `static let xpPerLevel = 100` без маркера — немедленный fail.

**Usage review (grep во всём iOS коде):**

| Константа | Usage |
|---|---|
| `maxStamina` | **Не используется** нигде. Чисто dead fallback. W4 удалит. |
| `freePvpPerDay` | `CityMapView:221`, `ArenaViewModel:56` — оба cache-first pattern: `cache.gameConfig?.freePvpPerDay ?? AppConstants.freePvpPerDay`. ✅ |
| `pvpStaminaCost` | `ArenaViewModel:82,86`, `ArenaDetailView:280` — **прямые чтения без cache-first** ⚠️ pending W4 full migration. |

`pvpStaminaCost` — известный tech debt: ViewModel ещё не мигрирован на `cache.gameConfig?.pvpStaminaCost`. Guard здесь не поможет (это не `static let <forbidden>`), это отдельный W4 task.

### 3. Preflight integration — секция 9

```bash
# --- 9. iOS/backend constant drift (if AppConstants.swift or any iOS .swift changed) ---
IOS_SWIFT_CHANGED=$(echo "$CHANGED" | grep -E '^Hexbound/Hexbound/.*\.swift$' || true)
if [ -n "$IOS_SWIFT_CHANGED" ]; then
  echo "## iOS ↔ Backend Constant Drift"
  if [ -x "scripts/check_ios_backend_drift.sh" ]; then
    if bash scripts/check_ios_backend_drift.sh > /tmp/hexbound_drift_check.log 2>&1; then
      echo "  ✅ No iOS/backend game-constant drift"
    else
      echo "  ❌ Drift detected — see details:"
      cat /tmp/hexbound_drift_check.log | sed 's/^/     /'
      BLOCKERS="$BLOCKERS\n  - iOS hardcoded game constants ..."
      VERDICT="BLOCKED"
    fi
  fi
fi
```

Триггерится на **любой** `.swift` файл в `Hexbound/Hexbound/`. Не только на `AppConstants.swift` — Check 2 ведь сканирует весь iOS root, и нам нужно поймать попытки подсунуть forbidden константу в любой ViewModel или View.

---

## Verification

### Test 1 — Positive (clean state)

```bash
$ bash scripts/check_ios_backend_drift.sh
=== iOS ↔ Backend Drift Check ===

## AppConstants.swift declarations
  ✅ line 84: static let maxStamina = 120 — deprecated, skipped
  ✅ line 86: static let freePvpPerDay = 3 — deprecated, skipped
  ✅ line 88: static let pvpStaminaCost = 10 — deprecated, skipped

## iOS sources outside AppConstants.swift
  ✅ no loose declarations

=================================
✅ CLEAN: no iOS/backend constant drift
=================================
EXIT=0
```

### Test 2 — Negative (injection without DEPRECATED marker)

```bash
$ cat >> Hexbound/Hexbound/App/AppConstants.swift <<'EOF'

// TEST: inject forbidden constant without DEPRECATED marker
enum BadConstants {
    static let xpPerLevel = 100
}
EOF

$ bash scripts/check_ios_backend_drift.sh
...
  ❌ line 93: static let xpPerLevel = 100
     → missing `// DEPRECATED` marker on line 92

=================================
⛔ DRIFT DETECTED: 1 violation(s)

Forbidden game constants must live in:
  backend/src/lib/game/balance.ts

And be exposed to iOS via:
  GameConfig → /api/game/init → cache.gameConfig.*

Violations:
  - Hexbound/Hexbound/App/AppConstants.swift:93 (static let xpPerLevel = 100)
=================================
EXIT=1
```

Revert → rerun → EXIT 0. ✅

### Test 3 — Preflight end-to-end

С `AppConstants.swift` в staged diff → preflight выводит:

```
## iOS ↔ Backend Constant Drift
  ✅ No iOS/backend game-constant drift

===============================
✅ VERDICT: READY TO COMMIT
```

### CDO scan

Чисто. Нет изобретённых font/spacing токенов, нет merge markers, нет `Color(hex:)` в Views.

---

## Файлы (изменение)

| Файл | Тип | Размер |
|---|---|---|
| `scripts/check_ios_backend_drift.sh` | new, executable | 134 LOC |
| `Hexbound/Hexbound/App/AppConstants.swift` | edited | +15 / -5 LOC (DEPRECATED markers + guidance) |
| `.claude/skills/gatekeeper/scripts/preflight_check.sh` | edited | +18 LOC (section 9) |

---

## Что это разблокирует

1. **Inbound-drift защита**: никто (включая будущего Claude) не сможет случайно ввести параллельный источник правды балансу в iOS-коде.
2. **Safe W4 full migration**: когда в W4 мы полностью удалим `pvpStaminaCost` fallback и мигрируем `ArenaViewModel` на `cache.gameConfig?.pvpStaminaCost`, guard сразу подтвердит что нет регрессий.
3. **Расширяемость**: для новой константы в `GameConfig` достаточно добавить имя в `FORBIDDEN` переменную скрипта — guard сразу начнёт её защищать.

---

## Пара (inbound ↔ outbound)

| Направление | Защищает что | Инструмент |
|---|---|---|
| **Outbound** (balance.ts → docs) | Документация не отстаёт от кода | W1.D4 `generate-balance-docs.ts` + drift check |
| **Inbound** (iOS → balance.ts) | iOS не отращивает параллельный SSoT | W1.D5 `check_ios_backend_drift.sh` |

Вместе они формируют двусторонний periметр вокруг `balance.ts` как единственного источника правды для game constants.

---

## Known debt / follow-up

- **W4 task**: мигрировать `ArenaViewModel` и `ArenaDetailView` чтобы читали `pvpStaminaCost` через cache-first pattern, затем удалить fallback из `AppConstants.swift`.
- **W4 task**: удалить `maxStamina` полностью (unused).
- **Preflight line 110 warning**: preflight'овская эмодзи-проверка имеет pre-existing bash bug (`[: 0\n0: integer expression expected`). Не введено мной, не в скоупе W1.D5. Отдельный fix.
- **GitHub Actions** (nice-to-have): добавить drift check в PR workflow если CI появится.

---

## Связанное

- W1.D3 review: `W1_D3_GAMECONFIG_SSOT_REVIEW.md`
- W1.D4 completion: `W1_D4_BALANCE_DOCS_AUTOGEN.md`
- Plan: `QA_FIX_PLAN_2026-04-10.md` (строка 613)
