# Hexbound → TestFlight: Пошаговая инструкция

> Версия: 1.0.0 (build 1) | Bundle ID: `com.hexbound.app` | iOS 17+

---

## ШАГ 1: Создать приложение в App Store Connect

1. Зайди на [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Apps → "+" → New App**
3. Заполни:
   - **Platforms:** iOS
   - **Name:** Hexbound
   - **Primary Language:** English (US) *(или Russian)*
   - **Bundle ID:** `com.hexbound.app` — если его нет в выпадающем списке, сначала зарегистрируй App ID (см. Шаг 1.5)
   - **SKU:** `hexbound-ios-001`
   - **User Access:** Full Access
4. Нажми **Create**

### Шаг 1.5: Регистрация App ID (если Bundle ID отсутствует)

1. Зайди на [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Нажми **"+"** → **App IDs** → **Continue**
3. Тип: **App**
4. **Description:** Hexbound
5. **Bundle ID:** Explicit → `com.hexbound.app`
6. **Capabilities:** отметь:
   - ✅ Push Notifications
   - ✅ Sign in with Apple
7. Нажми **Continue → Register**

---

## ШАГ 2: Настроить Code Signing в Xcode

1. Открой `Hexbound.xcodeproj` в Xcode
2. Выбери target **Hexbound** → вкладка **Signing & Capabilities**
3. Включи **✅ Automatically manage signing**
4. Выбери свой **Team** (Apple Developer аккаунт)
5. Xcode должен показать ✅ зелёную галочку и Provisioning Profile
6. Убедись что capabilities включают:
   - **Push Notifications**
   - **Sign In with Apple** (уже в entitlements)

> ⚠️ Если Xcode показывает ошибку — попробуй: Xcode → Settings → Accounts → нажми Manage Certificates → создай Apple Distribution Certificate

---

## ШАГ 3: Проверить настройки сборки

В Xcode → target Hexbound → **General**:
- **Display Name:** Hexbound
- **Bundle Identifier:** com.hexbound.app
- **Version:** 1.0.0
- **Build:** 1
- **iOS Deployment Target:** 17.0
- **Device:** iPhone

В **Build Settings** проверь:
- **MARKETING_VERSION** = 1.0.0
- **CURRENT_PROJECT_VERSION** = 1

---

## ШАГ 4: Загрузить через Fastlane (РЕКОМЕНДУЕТСЯ)

Fastlane уже настроен в проекте. Нужно сделать 3 вещи:

### Первоначальная настройка (один раз):
```bash
cd Hexbound/

# 1. Установить Fastlane
bundle install
# или: gem install fastlane

# 2. Отредактировать fastlane/Appfile — вписать свой Apple ID и Team ID
open fastlane/Appfile
```

### Загрузка на TestFlight (одна команда):
```bash
cd Hexbound/
./scripts/deploy_testflight.sh
# или напрямую: bundle exec fastlane beta
```

Fastlane автоматически: инкрементирует build number → соберёт архив → загрузит на TestFlight.

### Другие полезные команды:
```bash
fastlane build          # Только собрать (проверка)
fastlane bump_patch     # 1.0.0 → 1.0.1
fastlane bump_minor     # 1.0.x → 1.1.0
fastlane bump_major     # 1.x.x → 2.0.0
```

---

## ШАГ 4 (альтернатива): Archive вручную через Xcode

1. Подключи реальный iPhone **ИЛИ** выбери в верхнем меню:
   **Product → Destination → Any iOS Device (arm64)**
2. **Product → Archive** (⌘ + Shift + B не подойдёт — нужен именно Archive)
3. Дождись завершения (2-5 минут)
4. Автоматически откроется **Organizer** (Window → Organizer если не открылся)

> ⚠️ Если Archive недоступен (серый) — убедись что выбран реальный девайс или "Any iOS Device", а не симулятор

---

## ШАГ 5: Upload to App Store Connect

1. В **Organizer** выбери архив Hexbound
2. Нажми **Distribute App**
3. Выбери **App Store Connect** → **Upload**
4. Оставь все опции по умолчанию:
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number
5. Нажми **Upload**
6. Дождись загрузки (1-5 минут в зависимости от интернета)

---

## ШАГ 6: Настроить TestFlight

1. Зайди на [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → твоё приложение
2. Вкладка **TestFlight**
3. Подожди пока Apple обработает билд (10-30 минут, статус "Processing")
4. Когда статус станет "Ready to Submit" или появится ⚠️ жёлтый:
   - Заполни **Test Details** → What to Test, Email, etc.
   - Если просят **Export Compliance** → выбери "No" (если не используешь свою криптографию)

### Внутреннее тестирование (до 100 человек, без Review):
1. **Internal Testing → "+"** → создай группу (напр. "Team")
2. Добавь тестировщиков по Apple ID email
3. Они получат приглашение в почту и смогут установить через TestFlight app

### Внешнее тестирование (до 10,000 человек, нужен Review):
1. **External Testing → "+" → New Group**
2. Добавь тестировщиков
3. Нажми **Submit for Review** — Apple проверит за 24-48 часов

---

## Частые проблемы и решения

| Проблема | Решение |
|----------|---------|
| "No accounts with App Store Connect access" | Xcode → Settings → Accounts → добавь Apple ID |
| "No signing certificate" | Xcode → Settings → Accounts → Manage Certificates → "+" → Apple Distribution |
| Archive грейд-аут | Выбери "Any iOS Device" вместо симулятора |
| "Missing Compliance" в TestFlight | В App Store Connect → билд → кликни "Manage" → ответь на вопросы про криптографию |
| Билд не появляется в TestFlight | Подожди 10-30 минут, проверь email на ошибки от Apple |
| "Invalid Bundle" email от Apple | Проверь Bundle ID, версию, иконку |

---

## Что было исправлено перед загрузкой

- ✅ Удалено 21 дубликат файлов (`* 2.swift`) — мусор который мог вызвать конфликты
- ✅ Синхронизирована версия в Info.plist (была "1.0", стала "1.0.0" как в project.yml)
- ✅ Проверены Privacy API — приложение запрашивает только Push Notifications (не требует NSUsageDescription)
- ✅ App Icon настроен ✓
- ✅ Launch Screen настроен (SwiftUI SplashView) ✓
- ✅ Entitlements включают Sign in with Apple ✓

---

*Удачного релиза! 🎮⚔️*
