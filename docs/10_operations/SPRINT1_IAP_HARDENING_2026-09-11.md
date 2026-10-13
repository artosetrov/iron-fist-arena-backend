# Спринт 1 — деньги: что сделано 2026-09-11

Закрывает P0-1 … P0-5 и P0-7 из `docs/10_operations/HEXBOUND_FULL_AUDIT_2026-09-10.md`.
Ничего не закоммичено — изменения лежат в рабочем дереве.

**Ни одна строка Swift не компилировалась:** на машине, где шла работа, нет Xcode.
Первое, что нужно сделать — собрать проект.

---

## Backend

### `src/lib/apple-iap.ts`
- `verifyAppleTransaction` больше **не возвращает `valid: true`** при отсутствующих ключах. В продакшене (`NODE_ENV=production` **или** любой `VERCEL_ENV`) — отказ. Байпас остался только для локальной разработки со StoreKit Configuration.
- Добавлена `APPLE_TO_INTERNAL_PRODUCT_ID` — единственное авторитетное соответствие идентификатора App Store Connect ключу `IAP_PRODUCTS`, плюс `internalProductIdFromApple()`. Голый внутренний ключ тоже принимается (StoreKit Configuration отдаёт его без префикса), строгость от этого не страдает: результат всё равно обязан совпасть с заявленным клиентом продуктом.

### `src/app/api/iap/verify-receipt/route.ts`
- Награда резолвится из `appleResult.transactionInfo.productId`. Несовпадение с клиентским `product_id` → **403**, а не `console.warn`. Неизвестный Apple-идентификатор → 403.
- Отклоняются отозванные/возвращённые чеки (`revocationDate`) и не-`PURCHASED` владение (family sharing).
- `resolvedProductId` пишется в `iapTransaction`, подписку и аналитику — запись отражает реально купленное.
- Проверка `product_id` через `hasOwnProperty` (иначе `"constructor"` проходил).
- **Новый контракт ошибок для клиента:** `code: 'RECEIPT_REJECTED'` — чек не будет выдан никогда, клиент обязан завершить транзакцию; `code: 'VERIFICATION_UNAVAILABLE'` и любой 5xx — временно, транзакцию надо оставить незавершённой.

### `src/lib/apple-jws.ts` — новый файл
Проверка подписи JWS через официальную `@apple/app-store-server-library` (добавлена в зависимости). Строятся **два** верификатора — production и sandbox — и пробуются по очереди: Apple шлёт оба типа уведомлений на один URL.

### `src/app/api/iap/apple-notifications/route.ts`
- Подпись проверяется до чтения payload. Нет конфигурации → 503 (Apple ретраит, ничего не теряется). Плохая подпись → 401.
- Защита от `undefined`: у библиотеки **все** поля опциональные, а `findFirst({ where: { originalTransactionId: undefined } })` в Prisma означает «без фильтра» — то есть вернул бы и изменил чужую подписку. Теперь без `originalTransactionId` и без `notificationType` обработка прекращается.

### `src/app/api/user/delete/route.ts`
Чистка `pvp_matches` перед удалением пользователя (те FK — `ON DELETE RESTRICT`), всё внутри транзакции, список персонажей читается там же. Проверка «уже удалён» по коду `P2025`, а не по тексту сообщения.

### Тесты
`iap-verify-receipt` и `iap-apple-notifications` обновлены под новое поведение, добавлены регрессии: подмена продукта → 403, неизвестный SKU → 403, совпадение → 200; поддельная подпись → 401 и ноль записей; отсутствующая конфигурация → 503.
**Весь набор: 64 файла / 373 теста зелёные.** `check_schema_drift.py` — OK.

---

## iOS

### `Services/StoreKitService.swift`
- `IAPProduct` содержит только живые SKU; `internalId` связывает их с бэкендом. Снятые с продажи `gold_*` и `premium_forever` вынесены в `legacyProductIds` — они **не продаются**, но недоставленный чек по ним всё равно уходит на сервер, который отвечает 410. Иначе реальная покупка молча уничтожалась бы на клиенте.
- `redeem(_:)` возвращает `.granted` / `.alreadyCredited` / `.undeliverable` и бросает исключение только для того, что имеет смысл повторить.
- `executePurchase` выдаёт на сервере **до** `finish()`. Терминальный ответ завершает транзакцию, но при `.undeliverable` продукт не помечается купленным и бросается ошибка — игроку не показывают «покупка успешна».
- `Transaction.updates` и `restorePurchases()` дожимают незавершённые транзакции. `restorePurchases()` возвращает `RestoreResult` со счётчиками, так что «Purchases restored!» больше не печатается поверх провала.

### `Views/Shop/PremiumPurchaseView.swift`
- Продаёт `premium_pass_monthly` вместо отключённого `premium_forever`.
- **Экран больше не называет подписку разовой покупкой.** Добавлен блок раскрытия по гайдлайну 3.1.2: период, цена за период, условия автопродления, ссылки на Terms и Privacy. Цена берётся из StoreKit; пока она не загружена — не называется вообще, вместо выдуманных «$4.99» в чужой витрине.
- Бонус золота исправлен с +20% на +10% (сервер: `PREMIUM_GOLD_MULTIPLIER = 1.10`), в таблицу добавлены 300 гемов за продление.

### `Views/Shop/CurrencyPurchaseView.swift` и `Models/CurrencyPackage.swift`
Вкладка GOLD заменена на BUNDLES: `starter_bundle` и три `adventurer_bundle`. Добавлены `subtitle` (состав на карточке) и `successSummary` (что именно зачислено).

### `Resources/HexboundProducts.storekit`
Снятые SKU удалены, добавлены четыре бандла и группа подписки для `premium_pass_monthly`.

---

## Безопасность

`Hexbound.xcscheme` — из отслеживаемого git файла убраны `DEV_EMAIL` и `DEV_PASSWORD`. `scripts/check_tracked_secrets.py` теперь сканирует `.xcscheme` и ловит литеральные пароли в конфигах (плейсхолдеры вида `$(VAR)` и `CHANGEME` игнорируются). Проверено, что прежнее содержимое схемы срабатывает.

---

## Что нужно сделать вам — без этого правки не работают

1. **Сменить пароль** от `osetrov.artem@gmail.com`, который лежал в git. Из файла он убран, из истории — нет.
2. **Vercel → переменные окружения:** `APPLE_IAP_KEY_ID`, `APPLE_IAP_ISSUER_ID`, ключ `.p8`, `APPLE_APP_APPLE_ID` (числовой id из App Store Connect), `UPSTASH_REDIS_REST_URL` и `UPSTASH_REDIS_REST_TOKEN`. В `DEPLOY.md` их сейчас нет. Без первых трёх verify-receipt теперь честно отказывает вместо тихой раздачи валюты.
3. **Корневые сертификаты Apple:** скачать с https://www.apple.com/certificateauthority/ и положить в `backend/certs/apple/` либо передать как `APPLE_ROOT_CERTS` (base64 DER через запятую). Домен apple.com был закрыт прокси, поэтому скачать не удалось. Пока их нет, вебхук отвечает 503 и Apple ретраит — уведомления не теряются, но продления не применяются.
4. **App Store Connect:** создать пять новых SKU — `com.hexbound.starter_bundle`, `com.hexbound.adventurer_bundle_I/II/III` и подписку `com.hexbound.premium_pass_monthly` в группе подписок.
5. **Собрать в Xcode.** Swift не компилировался. Два независимых ревью прочитали его построчно и подтвердили, что он валиден, но это не сборка.
