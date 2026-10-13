# Hexbound — Полный аудит проекта 2026-10-13

> Snapshot: `~/Documents/Cursor AI/PVP RPG`, ветка `main`, последний коммит `20cdcea` (2026-05-04).
> Метод: 10 зон по `.claude/skills/project-audit`, 5 параллельных проверок по коду (343 Swift / 190 API-роутов / 44 admin-страницы), сверка с аудитом 2026-04-17 и `HEXBOUND_FULL_AUDIT_2026-09-10.md`.
> Все находки верифицированы по исходникам с `file:line`. Бинарные ассеты (xcassets, аудио) в снапшот не входили.

---

## OVERALL HEALTH: 🔴 — код зрелый, но не собран, не закоммичен и не задеплоен

| Зона | Статус | Одной строкой |
|---|---|---|
| 1. iOS код | 🟡 | Каталожные проверки чистые, pbxproj 343=343. Остатки: 2 force-unwrap, гонка обновления квеста в Shop, 4 `print` в release |
| 2. Backend | 🟡 | Экономика залочена и идемпотентна. 2 новых TOCTOU, 1 неавторизованный dev-роут, мутирующий БД |
| 3. Схема/данные | 🟢 | backend↔admin байт-в-байт, 48 миграций, drift-скрипт OK. 3 миграции не применены на прод |
| 4. API-контракты | 🔴 | **Падение декода на iOS после каждого боя с ботом/боссом**; **10 вызовов без `/api` → 404** |
| 5. Дизайн-система | 🟡 | Нет `Color(hex:)`-утечек. Шрифты <16px в HUD, 37 raw `Color.white/black`, правило «мин. 16px» противоречит токенам |
| 6. Админка | 🟡 | Все прошлые пробелы закрыты (read-only). **Tables CRUD = эскалация привилегий для модератора** |
| 7. Документация | 🟡 | Всё датировано апрелем, код — сентябрём. 40 роутов не задокументированы, wiki заморожена 05-06 |
| 8. Игровые системы | 🟡 | Ядро готово. Нет: refill стамины с iOS, abandon подземелья, prestige UI, BP rollover, dungeons 1–29 в БД |
| 9. Релиз | 🔴 | **205 незакоммиченных файлов за 5 месяцев, iOS не компилировался с мая**, CI ни разу не запускался |
| 10. Аналитика/LiveOps | 🔴 | События идут в `NoopBackend`, iOS `track()` 0 вызовов, **push «отправлен» без отправки** |

**CRITICAL: 7 · HIGH: 14 · MEDIUM: ~25 · LOW: ~30**

---

## 🔴 CRITICAL (чинить первыми)

### C1. Бои с ботами и боссами подземелий ломаются на клиенте
`backend/src/app/api/pvp/match/complete/route.ts:214` → для bot/dungeon_boss `origin: null`, сериализуется в `:658`.
`Hexbound/Hexbound/Models/CombatData.swift:37` → `CombatFighter.origin: CharacterOrigin` **non-optional**, без кастомного `init(from:)`.
`InteractiveBattleViewModel.swift:476,1066` декодит прямо в `CombatData` → `:1074` `phase = .error`.
**Эффект:** сервер начисляет награду/ELO, игрок видит «Failed to complete match» на каждом бою с ботом — включая **первые 3 онбординговых боя** (`ArenaViewModel.swift:218` гонит `npc_*` через этот флоу). Тестов на `match/complete` нет.
**Фикс:** `origin: CharacterOrigin?` + fallback в UI, либо на бэке отдавать реальный `botOrigin` (`lib/game/npc-bots.ts:101`). Добавить vitest на bot-ответ.

### C2. Туториал и рефералы бьют в несуществующие URL
`TutorialService.swift:66,122`, `TutorialManager.swift:458,479,498,515,533,554`, `ReferralSectionView.swift:271,295` — endpoint `"/tutorial..."`, остальные 103 вызова — `"/api/..."`. `APIClient.swift:132` просто `appendingPathComponent`. В `backend/src/app/` роутов вне `api/` нет, `next.config.ts` без rewrites.
**Эффект:** tutorial state/step/skip/quest, scripted-fight preload/resolve, referral — 404 в проде.
**Фикс:** добавить `/api` в 10 местах (или нормализовать в `APIClient.request`).

### C3. Пять месяцев работы не закоммичены и не скомпилированы
126 modified + 77 untracked + 2 deleted с 2026-05-04. Sprint 1–3 (сентябрь: IAP hardening, TestFlight prep, ladder SSOT, LoadOutcome) лежат в working tree. Sprint-доки сами пишут: *«No Xcode on this machine — nothing has been compiled»*. `Package.resolved` не содержит `sentry-cocoa` → SPM не резолвился. CI (`ci.yml` с 6 jobs, включая `ios-build`) сам не закоммичен.
**В дерево попал мусор, который нельзя коммитить:** `prototypes/20260801-Bank statement.pdf`, `prototypes/Daina VIP styling .pdf`, `prototypes/brok_rpt_BO1530021_*.html`, `prototypes/lot-dashboard.html` (личные финансовые файлы), `docs/features/arena/ARENA_OVERVIEW 2.md` (macOS-дубликат), `_audit_tmp/` (мой временный архив — удалить).

### C4. Admin: модератор может сделать себя админом
`admin/src/actions/crud.ts:139-225` — `createRecord/updateRecord/deleteRecord` через `$executeRawUnsafe` на любой таблице (исключена только `_prisma_migrations`), проверка — лишь `getAdminUser()` (любая роль). `UPDATE users SET role='admin'` / `gems=…` доступны модератору. 18 из 20 server-action файлов (`feature-flags.ts`, `shop-offers.ts`, `events.ts`, `mail.ts`, `push.ts`, `players.ts`…) тоже не проверяют роль на мутациях.

### C5. Push-кампании — фикция
`admin/src/actions/push.ts:113-160` считает токены и ставит `status='sent'`, но `backend/src/lib/push/send.ts` (`sendPushToUsers/sendPushBroadcast`) имеет **0 вызовов**. `sendAPNS` — HTTP/1.1 fetch со статичным bearer, JWT не реализован (комментарий в коде это признаёт). `scheduledAt` хранится, cron нет. `ADMIN_CAPABILITIES.md` утверждает «APNS-backed sender» — неправда.

### C6. Аналитика — в никуда
`backend/src/lib/analytics.ts` эмитит 7 воронок (signup, first_pvp, iap_purchase, bp_claim, daily_login, level_up, shop_upgrade), но `setAnalyticsBackend()` нигде не вызывается → `NoopBackend`. Нет `AnalyticsEvent`-модели, нет `/api/analytics`, нет PostHog/Mixpanel в `package.json`. iOS: `AnalyticsService.shared.track(` — **0 вызовов**, `HEXBOUND_SENTRY_DSN` пустой. D1/D7/D30 в дашборде = `null` (`admin/src/actions/dashboard.ts:207`).

### C7. Неавторизованный роут массово пишет в `characters`
`backend/src/app/api/dev/fix-avatars/route.ts:10-39` — без `getAuthUser`, без try/catch, `prisma.character.update` в цикле. `middleware.ts:72` `/api/dev/*` не гейтит (другие dev-роуты проверяют роль сами, этот — нет).

---

## 🟠 HIGH

**Backend / экономика**
- H1. TOCTOU `inventory/use/route.ts:52-142`: cap стамина-зелий читается без лока, пишется `staminaPotionsToday: n+1` абсолютно → параллельные запросы обходят `DAILY_CAP`. Соседний `consumables/use:70-110` делает правильно (FOR UPDATE).
- H2. TOCTOU `social/challenges/route.ts:333-397` (POST): дневной лимит, duplicate-pending и стамина проверяются до `$transaction`, стамина пишется абсолютно → N вызовов за одну стамину, обход 10/день. Accept-путь (`:565`) залочен, send — нет.
- H3. `monthly_gem_card` продаётся на iOS, сервер выдаёт 50 гемов + `daysRemaining:30` (`verify-receipt:312-330`), **ежедневные 10 гемов не начисляет никто** (0 декрементов). Продажа невыполняемого обещания.
- H4. Premium Pass: `DID_RENEW` в `apple-notifications` только продлевает `expiresAt`; 300 гемов за продление, обещанные в `PremiumPurchaseView`, даются лишь при первом verify (`verify-receipt:195`).
- H5. Скины: `AppearanceEditorViewModel.swift:116` показывает `priceGold/priceGems`, а `characters/[id]/appearance/route.ts` берёт 100g только за смену origin и не проверяет владение/цену → все премиум-скины бесплатны.
- H6. XP-кривая: `balance.ts:108` описывает `xpForLevel` как кумулятивную, `progression.ts:178-182` вычитает по уровню → ~986k XP до 50 вместо ~55k (×18). Level 50 / prestige / `reach_level_50` недостижимы.
- H7. 9 «фантомных» balance-ключей в админке (`repair.*`, `matchmaking.*`, `cha.gold_bonus_cap`, `stamina_refill_dr.daily_cap`, `training_xp_dr.*`) бэкендом не читаются (0 hits). Ремонт захардкожен в `shop/repair/route.ts:61`, matchmaking — в `pvp/opponents/route.ts:8-11`. Оператор крутит ручки — ничего не меняется.
- H8. `verify-receipt` не проверяет `appAccountToken` (0 hits) — чужой `transactionId` можно погасить на своём аккаунте.

**iOS / геймплей-дыры**
- H9. `/api/stamina/refill` и `/api/combat/buy-extra` с iOS **не вызываются** (0 hits) → кончилась стамина = сессия окончена, купить нельзя. У `buy-extra` нет серверного дневного капа.
- H10. `/api/dungeons/abandon` с iOS не вызывается → активный ран блокирует все подземелья без выхода (soft-lock за одну сессию).
- H11. Подземелья: 8 в БД на levelReq 30…65 при `PRESTIGE.MAX_LEVEL=50` → 3 недостижимы навсегда; уровни 1–29 покрыты тремя захардкоженными (`lib/game/dungeon.ts:76-133`), которых нет ни в одном сиде, а `DungeonSelectViewModel.swift:108` заменяет локальный список серверным → на чистой БД низкоуровневых подземелий ноль. `DungeonMapBuildingConfig.swift` ждёт `shadow_depths`, в БД `shadow_realm`.
- H12. Prestige: `/api/prestige` есть, на iOS только бейдж `P\(n)` (`IntegratedCharacterCard.swift:224`); кнопки/промпта нет, `atMaxLevel` 0 hits. Эндгейм — стена. У prestige нет капа и он не сбрасывает статы.
- H13. Battle Pass: сезон засеян на 90 дней (`seed-battle-pass.ts:30`), rollover нет → день 91 = 404 «No active season». Weekly challenges (роуты есть) с iOS не вызываются, `SeasonSummaryModalView` 0 call sites.
- H14. Shop: `ShopViewModel.swift:572` `invalidateCache("quests")` **до** POST → `ActiveQuestBanner` (×6 инстансов) тут же перезапрашивает **старый** прогресс, затем `ShopService.refreshDailyQuestsAfterGoldSpend()` — новый; кто последний, тот и показан. `buyGems()` (`ShopService.swift:176-196`) вообще не обновляет квест. Это и есть `0/1 674` на скриншоте после покупки.

**Релиз**
- H15. Три сентябрьские миграции (`20260912_stamina_potion_daily_cap`, `20260912_gold_mine_active_slot_unique`, `20260915_rank_achievement_targets`) не применены на прод; код уже ссылается на `stamina_potions_today`. Деплой бэкенда без них = 500.
- H16. Vercel env не задан/не задокументирован: `APPLE_IAP_KEY_ID/ISSUER_ID/PRIVATE_KEY`, `APPLE_APP_APPLE_ID`, `APPLE_ROOT_CERTS(_DIR)` (папки `backend/certs/` нет → webhook 503), `UPSTASH_REDIS_*`, `BOT_TICKET_SECRET`, `HEXBOUND_SENTRY_DSN`. `verify-receipt` в проде теперь **честно падает** без Apple-ключей. Ни один не упомянут в `DEPLOY.md`, 4 отсутствуют в `.env.example`.
- H17. App Store Connect: 11 SKU из `HexboundProducts.storekit` надо создать; Push на App ID не включён → automatic signing упадёт.
- H18. Пароль, ранее лежавший в `Hexbound.xcscheme`, остался в git-истории — ротация не подтверждена.

---

## 🟡 MEDIUM (выборочно, полные списки в отчётах зон)

- iOS: 3 экрана с optional-VM без `.transaction { $0.animation = nil }` (`BuyStatPointsView:11`, `StashDetailView:17`, `InteractiveBattleView:1004`); 33 файла с орнаментальными стеками без `.compositingGroup()`; `APIClient.swift:78` печатает 500 символов тела ответа в release; force-unwrap `OnboardingViewModel.swift:356`, `InteractiveBattleViewModel.swift:1191`; `DungeonRushStartView.swift:239` течёт 30 Hz Timer; `InventoryViewModel.upgrade():299` и `ArenaViewModel.fight()` без double-tap guard; `CloseButtonStyle` 32×32 < 44pt; Dynamic Type отсутствует (`@ScaledMetric` 0 hits).
- Дизайн-система: правило «мин. 16px» в `Hexbound/CLAUDE.md` противоречит токенам `caption=12/badge=11/uiLabel=14` (209 использований) — решить, что истина. Фиолетовый premium-акцент как `Color(red:)` в `ActiveSlotTile:211-213,274`, `TalentsTabView:257-258` → вынести в токен. `TabSwitcher` без `tabSwitcherPaddingV` в 6 из 9 мест. 12 SF Symbols вместо ассетов. `ToastType.success` существует (`AppState.swift:585`), а CLAUDE.md:225 и ERR-SW-021 утверждают обратное.
- Backend: `game/init:371-378` отдаёт сырой `error.message`; роли `'dev'` vs `'developer'` расходятся; `PvpMatch.loserId`, `DungeonBoss.dungeonId`, `Character.referredBy` без индексов; мёртвые модели `LegendaryShard`, `TrainingSession`; мёртвые роуты `skills/*`, `pvp/find-match`, `combat/simulate` (410), `shell-game/play`, `shop/buy-potion`, `shop/buy-gold` (задуманный gem-sink не вызывается); `combat-loader.ts:32` всё ещё джойнит `characterSkills` на каждый бой.
- Экономика: дневные лимиты считаются **на персонажа** × 5 персонажей (`characters/route.ts:354`); `protection_scroll` и `legendary_shard` продаются в бандлах, но ни один роут их не тратит; AGI overpowered, poison armor-pierce, mine income 4× PvP — открыты с апрельского balance-audit.
- LiveOps: `EventBannerView` 0 call sites, `/api/events/active` не вызывается; `dropRateMult`/`staminaDiscount` из `lib/game/events.ts` никем не читаются; feature-флаги кэшируются на iOS и **ни одна вью их не читает** → kill-switch не работает. Нет audit-trail в БД (`audit-log.ts` = console.log), гранты золота/гемов без потолка, нет страницы `AdminLog`.
- Два боевых стека в одном бинаре: `INTERACTIVE_COMBAT_V1` guard в 4 роутах, `AppRoute.combat` пушится из 6 мест (dungeon_rush, guild challenge replay). Ровно состояние `combat-unification-remaining.md`.
- Туториал не учит zone/predict-механику: `InteractiveBattleView` без tutorial-хуков, первый бой — one-tap auto-resolve.
- Нет UGC-модерации: report-эндпоинта нет (`find api -iname '*report*'` пусто), профанити-фильтра нет, UI жалобы нет — Guideline 1.2 reject.
- Localization мёртвая: 175 ключей в `Localizable.strings`, `L10n.*` 0 вызовов, ~860 `Text("…")` литералов.

---

## 📄 Документация — что протухло

Весь код датирован 2026-09-15, все доки — апрелем/маем:
`RELEASE_IOS.md` (формат тегов, Xcode 16, PrivacyInfo, push, Sentry) · `DEPLOY.md` (3 CI-job вместо 6, нет env-переменных) · `DATABASE_MIGRATIONS.md` (3 из 48 миграций, дублирует `04_database/MIGRATIONS.md`) · `SCHEMA_REFERENCE.md` (839 vs 708 полей, несуществующий enum `UserRole`) · `API_REFERENCE.md` (40 роутов не описаны, 13 методов не совпадают, 4 фантомных) · `BALANCE_CONSTANTS.md` (`STAMINA_POTION_DR`, `BP_WEEKLY`, `CHA_GOLD_BONUS_CAP` не попадают в генератор) · `DOCUMENTATION_INDEX.md` (74 дока не перечислены) · `wiki/_generated/*` (api-routes 185 vs 190, ios-screens 242 vs 246) · wiki inventory/log заморожены 2026-05-06, 8 новых файлов не внесены · `.skills/skills/` (май) новее `.claude/skills/` (апрель) — Claude Code грузит старые.

---

## 🧹 Гигиена репо

Удалить: `Hexbound/test.txt`, `_audit_tmp/`, `.claude/agent-bus/*.md` (stale), 4 личных файла в `prototypes/`, `ARENA_OVERVIEW 2.md`. Переместить: `Hexbound/HERO_PROMPTS.md` → `docs/08_prompts/`; `docs/FULL_PRODUCT_AUDIT_2026-03-21.md`, `MIGRATION_PLAN.md`, `ORCHESTRATOR.md`, `10_operations/HEXBOUND_PRE_RELEASE_AUDIT.md`, `SIMULATOR_PLAYTEST_BUGS_2026-04-09.md` → `docs/11_archive/`. `Hexbound/project.yml` не является источником (в нём нет sentry, есть DotLottie, которого нет в pbxproj) — удалить или пометить. Добавить в `.gitignore`: `_audit_tmp/`, `prototypes/*.pdf`.

---

## ✅ Что в порядке (не трогать)

pbxproj 343=343 во всех 4 секциях · 184/190 роутов в try/catch · 79 роутов в `$transaction`, 57 с `FOR UPDATE` · все shop/claim/minigame/stash/BP залочены и атомарны · gold-mine double-session закрыт partial unique index · 33/33 admin-роутов через `getAuthAdmin` · PII в логах 0 · секретов в трекинге 0 · schema drift OK · 3 миграции консистентны со схемой · ladder parity OK (7 тиров в 4 местах) · PrivacyInfo.xcprivacy, encryption flag, SIWA, versioning — готовы · StoreKit-флоу purchase→verify→finish корректен · 18 ачивок = wiki · 7 типов квестов · деструктивные admin-действия с подтверждением.

---

## ПЛАН ДОДЕЛКИ (порядок важен)

### Спринт 0 — «Сохранить работу» (1 день)
1. Удалить мусор (см. Гигиена), `.gitignore`.
2. Закоммитить сентябрь логичными чанками: миграции+schema+admin-schema → backend IAP → backend ladder/pvp → iOS → CI → docs/wiki/retro.
3. `xcodebuild … clean build` локально (или push и смотреть `ios-build`). **Первая компиляция с мая** — ждать ошибок.
4. Ротировать пароль из истории xcscheme.

### Спринт 1 — «Игра не ломается» (2–3 дня)
5. C1 `CombatFighter.origin` optional + тест на bot `match/complete`.
6. C2 `/api` префикс в 10 вызовах.
7. C7 закрыть `dev/fix-avatars`; C4 `requireStrictAdmin` + allowlist таблиц в `crud.ts`, `canModifyConfig` на все мутирующие actions.
8. H1/H2 TOCTOU → FOR UPDATE + `increment`.
9. H14 Shop: убрать `invalidateCache("quests")` в `ShopViewModel:572`, добавить refresh в `buyGems`.
10. H9 кнопка refill стамины (+ cap на `buy-extra`), H10 кнопка abandon подземелья.
11. H11 засеять dungeons 1–29, починить `shadow_depths`, скрыть 3 подземелья выше 50.
12. H6 определиться с XP-кривой (×18).

### Спринт 2 — «TestFlight» (2–3 дня)
13. H15 применить 3 миграции на прод (Supabase MCP) → H16 env на Vercel → push backend → subtree push admin.
14. H17 SKU в ASC, Push на App ID, App Privacy = PrivacyInfo.
15. H3 убрать `monthly_gem_card` из продажи (или реализовать 10/день); H4 300 гемов на `DID_RENEW`; H5 проверка владения скинами.
16. H8 `appAccountToken`.
17. `fastlane build` → `fastlane beta`.

### Спринт 3 — «Видим, что происходит» (3–4 дня)
18. C6: `AnalyticsEvent`-модель или PostHog через `setAnalyticsBackend`; iOS `track()` на signup / onboarding_step / tutorial_complete / IAP / screen; Sentry DSN; `@sentry/nextjs` на бэке.
19. C5: APNs HTTP/2+JWT (`apns2`/`@parse/node-apn`), подключить `sendCampaign` к реальной отправке, cron на `scheduledAt`.
20. H7 фантомные ключи → читать через `live-config.ts` или убрать из UI. Audit-trail в `AdminLog` + страница.
21. H12 Prestige UI + cap, H13 BP rollover (cron/auto-create).

### Спринт 4 — «App Store» (неделя+)
22. UGC: report endpoint + модерационная очередь + профанити-фильтр.
23. Age rating / simulated gambling, odds disclosure (contraband, loot, mine, wheel).
24. Support URL в приложении, «Sign in with Apple» label, `fastlane/metadata` + скриншоты, demo-аккаунт.
25. Решение по двум боевым стекам: портировать dungeon_rush + challenge replay и удалить `CombatDetailView/CombatViewModel/INTERACTIVE_COMBAT_V1` — или явно принять два стека для 1.0.
26. Дневные лимиты на аккаунт, feature-flag reads на iOS, EventBanner wiring.

### Параллельно, по мере сил
Docs-sync PR (список выше), регенерация `wiki/_generated` (`scripts/wiki/generate-all.sh`), слияние `.skills/` → `.claude/skills/`, DS-чистка (шрифты, `Color.white/black`, `compositingGroup`, TabSwitcher, premium-токен), Dynamic Type + 44pt, балансовые долги (AGI, poison, mine income).

---

## Дельта vs аудит 2026-04-17

Исправлено: цветовая утечка в `ActiveSkillsHUD`, `AppRouter:270`, `post_combat_hp` задокументирован, все admin-роуты на `getAuthAdmin`, страницы minigame-sessions / matchmaking / referrals / offers / flags / iap-products добавлены, 7 воронок эмитятся на бэке (но в Noop).
Не исправлено: шрифты в `ActiveSkillsHUD:166/234/307`, `ButtonStyles:612`, 2 force-unwrap, `game/init` gold/gems в двух местах (теперь помечено как intentional), analytics без sink, 13 моделей без документации (стало хуже — 40 роутов).
Новое: C1, C2, C4, C5, C7, H1, H2, H14 и весь блок «не собрано/не закоммичено».
