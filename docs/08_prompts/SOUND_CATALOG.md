# Hexbound — Полный каталог звуков

*Создано: 2026-03-30. На основе анализа 38+ экранов и всех игровых систем.*

**Общее количество звуков: ~95 SFX + ~12 музыкальных треков**

---

## Приоритеты

| Приоритет | Значение | Когда нужно |
|-----------|----------|-------------|
| P0 | Критично | MVP / первый релиз — без них игра ощущается сломанной |
| P1 | Важно | Soft launch — добавляет polish и вовлечённость |
| P2 | Желательно | Post-launch — финальный слой полировки |

---

## 1. UI / Интерфейс (18 SFX)

### P0 — Критичные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 1 | `ui_tap` | Все кнопки | Мягкий тап, приятный feedback | `ui_tap.mp3` |
| 2 | `ui_tap_heavy` | CTA-кнопки (Fight, Buy, Equip) | Более весомый, "золотой" тап | `ui_tap_heavy.mp3` |
| 3 | `ui_back` | Навигация назад | Лёгкий swoosh назад | `ui_back.mp3` |
| 4 | `ui_tab_switch` | TabSwitcher (Hub/Arena/Hero) | Короткий переключатель | `ui_tab_switch.mp3` |
| 5 | `ui_modal_open` | Все модалки/sheets | Мягкое появление снизу | `ui_modal_open.mp3` |
| 6 | `ui_modal_close` | Закрытие модалок | Мягкое затухание | `ui_modal_close.mp3` |
| 7 | `ui_error` | Ошибки, отказы | Негативный звук, но не раздражающий | `ui_error.mp3` |

### P1 — Важные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 8 | `ui_toggle` | Настройки, переключатели | Click переключателя | `ui_toggle.mp3` |
| 9 | `ui_scroll_tick` | Списки, карусели | Едва слышный тик при скролле | `ui_scroll_tick.mp3` |
| 10 | `ui_notification` | Toast-уведомления | Ping, внимание | `ui_notification.mp3` |
| 11 | `ui_equip` | ItemDetailSheet → Equip | Металлический клик экипировки | `ui_equip.mp3` |
| 12 | `ui_unequip` | Снятие предмета | Обратный клик | `ui_unequip.mp3` |

### P2 — Желательные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 13 | `ui_hover` | Карточки предметов (long press) | Лёгкий feedback | `ui_hover.mp3` |
| 14 | `ui_search` | Поиск в инвентаре | Мягкий тик начала ввода | `ui_search.mp3` |
| 15 | `ui_swipe` | Arena carousel swipe | Whoosh при свайпе | `ui_swipe.mp3` |
| 16 | `ui_stamp` | Toast types: gold, gems, xp | Отдельный приятный stamp | `ui_stamp.mp3` |
| 17 | `ui_lock` | Заблокированный контент | "Locked" короткий звук | `ui_lock.mp3` |
| 18 | `ui_unlock` | Разблокировка | Открытие замка | `ui_unlock.mp3` |

---

## 2. Бой / Combat (22 SFX)

### P0 — Критичные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 19 | `combat_hit_physical` | Физический удар (Warrior, Tank) | Тяжёлый металлический удар | `combat_hit_physical.mp3` |
| 20 | `combat_hit_magical` | Магический удар (Mage) | Энергетический импакт | `combat_hit_magical.mp3` |
| 21 | `combat_hit_rogue` | Удар Rogue (Backstab) | Быстрый, острый порез | `combat_hit_rogue.mp3` |
| 22 | `combat_crit` | Критический удар (все классы) | Усиленный импакт + искры | `combat_crit.mp3` |
| 23 | `combat_miss` | Промах | Свист мимо | `combat_miss.mp3` |
| 24 | `combat_dodge` | Уворот | Быстрый swoosh | `combat_dodge.mp3` |
| 25 | `combat_block` | Блок (Tank) | Щит принимает удар | `combat_block.mp3` |
| 26 | `combat_death` | Смерть персонажа | Падение тела | `combat_death.mp3` |
| 27 | `combat_start` | CombatDetailView → intro | Гонг/рог начала боя | `combat_start.mp3` |

### P1 — Важные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 28 | `combat_heal` | HealEffect VFX | Мягкий целительный звон | `combat_heal.mp3` |
| 29 | `combat_poison` | StatusVFXEffects — poison | Ядовитое шипение | `combat_poison.mp3` |
| 30 | `combat_stun` | StatusVFXEffects — stun | Колокольный звон + замедление | `combat_stun.mp3` |
| 31 | `combat_buff` | Баффы (Fortify, Evasion) | Магическое усиление | `combat_buff.mp3` |
| 32 | `combat_debuff` | Дебаффы (Slow, Silence) | Ослабляющий эффект | `combat_debuff.mp3` |
| 33 | `combat_true_damage` | True damage hit | Особый "пробивающий" звук | `combat_true_damage.mp3` |
| 34 | `combat_stance_switch` | Смена стойки в бою | Металлический сдвиг | `combat_stance_switch.mp3` |
| 35 | `combat_skill_activate` | Активация скилла | Энергетический заряд | `combat_skill_activate.mp3` |
| 36 | `combat_turn_tick` | Переход хода | Тихий tick смены хода | `combat_turn_tick.mp3` |

### P2 — Желательные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 37 | `combat_aoe` | AOE-скиллы (Inferno, Power Attack) | Широкий взрыв | `combat_aoe.mp3` |
| 38 | `combat_summon` | Boss summons (Dungeon) | Тёмный призыв | `combat_summon.mp3` |
| 39 | `combat_low_hp` | HP < 20% | Пульс / heartbeat | `combat_low_hp.mp3` |
| 40 | `combat_cooldown_ready` | Скилл снова доступен | Тихий "ping" готовности | `combat_cooldown_ready.mp3` |

---

## 3. Победа / Поражение / Награды (12 SFX)

### P0 — Критичные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 41 | `result_victory` | CombatResultDetailView → win | Фанфары победы, 2-3 сек | `result_victory.mp3` |
| 42 | `result_defeat` | CombatResultDetailView → loss | Мрачный аккорд поражения | `result_defeat.mp3` |
| 43 | `reward_gold` | Получение золота | Звон монет | `reward_gold.mp3` |
| 44 | `reward_xp` | Получение опыта | Энергетический подъём | `reward_xp.mp3` |
| 45 | `reward_item_drop` | Лут / дроп предмета | Предмет падает + блеск | `reward_item_drop.mp3` |

### P1 — Важные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 46 | `reward_gems` | Получение гемов | Кристальный звон | `reward_gems.mp3` |
| 47 | `reward_level_up` | LevelUpModalView | Грандиозный level-up фанфар | `reward_level_up.mp3` |
| 48 | `reward_achievement` | Ачивка получена | Особый торжественный звук | `reward_achievement.mp3` |
| 49 | `reward_quest_complete` | DailyQuestsDetailView → complete | Квест завершён | `reward_quest_complete.mp3` |
| 50 | `reward_item_rare` | Epic/Legendary дроп | Расширенный блеск (драматичнее) | `reward_item_rare.mp3` |
| 51 | `reward_chest_open` | Gold Mine chest | Открытие сундука | `reward_chest_open.mp3` |
| 52 | `result_revenge` | Revenge победа | Победа + "месть сладка" акцент | `result_revenge.mp3` |

---

## 4. Прогрессия / Progression (10 SFX)

### P0 — Критичные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 53 | `progression_upgrade` | Item upgrade (+1 → +10) | Ковальный удар + улучшение | `progression_upgrade.mp3` |
| 54 | `progression_upgrade_fail` | Upgrade fail (+9/+10) | Треск неудачи | `progression_upgrade_fail.mp3` |

### P1 — Важные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 55 | `progression_prestige` | Prestige level up | Эпический звук перерождения | `progression_prestige.mp3` |
| 56 | `progression_skill_unlock` | Новый скилл / апгрейд скилла | Магическое обретение | `progression_skill_unlock.mp3` |
| 57 | `progression_passive_node` | Passive tree → node unlock | Тихий "click" + свечение | `progression_passive_node.mp3` |
| 58 | `progression_daily_login` | DailyLoginPopupView → claim | Stamp дня | `progression_daily_login.mp3` |
| 59 | `progression_streak` | Login streak milestone | Расширенный streak-звук | `progression_streak.mp3` |
| 60 | `progression_battle_pass` | BattlePassDetailView → claim | Разблокировка ноды battle pass | `progression_battle_pass.mp3` |

### P2 — Желательные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 61 | `progression_stat_point` | Stat allocation (HeroDetail) | Тихий tick вложения очка | `progression_stat_point.mp3` |
| 62 | `progression_respec` | Respec (passives/stats) | Reset-эффект | `progression_respec.mp3` |

---

## 5. Данжи / Dungeons (8 SFX)

### P0 — Критичные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 63 | `dungeon_enter` | DungeonRoomDetailView → enter | Тяжёлая дверь / спуск | `dungeon_enter.mp3` |
| 64 | `dungeon_floor_complete` | Этаж пройден | Короткий триумф | `dungeon_floor_complete.mp3` |
| 65 | `dungeon_boss_appear` | Boss floor (5, 10) | Зловещее появление | `dungeon_boss_appear.mp3` |

### P1 — Важные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 66 | `dungeon_victory` | DungeonVictoryView | Победа в данже (расширенная) | `dungeon_victory.mp3` |
| 67 | `dungeon_door` | Переход между этажами | Скрип двери | `dungeon_door.mp3` |
| 68 | `dungeon_loot_reveal` | LootPreviewSheet | Предметы появляются один за другим | `dungeon_loot_reveal.mp3` |

### P2 — Желательные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 69 | `dungeon_ambient_drip` | Фоновый loop в данже | Капли воды, эхо | `dungeon_ambient_drip.mp3` |
| 70 | `dungeon_rush_wave` | DungeonRush → новая волна | Волна надвигается | `dungeon_rush_wave.mp3` |

---

## 6. Мини-игры (8 SFX)

### P1 — Важные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 71 | `shell_shuffle` | ShellGameDetailView → shuffle | Стаканы перемещаются | `shell_shuffle.mp3` |
| 72 | `shell_reveal_win` | Угадал правильно | Позитивный reveal | `shell_reveal_win.mp3` |
| 73 | `shell_reveal_lose` | Не угадал | Негативный reveal | `shell_reveal_lose.mp3` |
| 74 | `shell_bet_place` | Ставка сделана | Монеты на стол | `shell_bet_place.mp3` |
| 75 | `goldmine_start` | GoldMineDetailView → start session | Кирка + камень | `goldmine_start.mp3` |
| 76 | `goldmine_collect` | Сбор добычи | Мешок монет | `goldmine_collect.mp3` |
| 77 | `goldmine_chest` | Chest drop (10% chance) | Сундук найден! | `goldmine_chest.mp3` |
| 78 | `tavern_ambient` | TavernDetailView (loop) | Бубнёж таверны | `tavern_ambient.mp3` |

---

## 7. Магазин / Экономика (7 SFX)

### P0 — Критичные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 79 | `shop_purchase` | ShopDetailView → buy | Ка-чинг! Покупка | `shop_purchase.mp3` |
| 80 | `shop_sell` | Продажа предмета | Монеты уходят | `shop_sell.mp3` |

### P1 — Важные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 81 | `shop_iap_success` | CurrencyPurchaseView → success | Premium покупка завершена | `shop_iap_success.mp3` |
| 82 | `shop_deal_appear` | Daily Deal / Flash Sale popup | Оффер появился | `shop_deal_appear.mp3` |
| 83 | `shop_repair` | Ремонт экипировки | Ковальный ремонт | `shop_repair.mp3` |
| 84 | `consumable_use` | Potion / Scroll использован | Питьё зелья / чтение свитка | `consumable_use.mp3` |
| 85 | `stamina_refill` | Stamina refill (gems) | Энергия восстановлена | `stamina_refill.mp3` |

---

## 8. Социальные / Arena (5 SFX)

### P1 — Важные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 86 | `arena_match_found` | Matchmaking result | Противник найден | `arena_match_found.mp3` |
| 87 | `arena_rank_up` | ELO milestone (новый ранг) | Ранговое повышение | `arena_rank_up.mp3` |
| 88 | `arena_rank_down` | ELO drop (потеря ранга) | Понижение | `arena_rank_down.mp3` |
| 89 | `inbox_new` | InboxDetailView — новое письмо | Конверт прибыл | `inbox_new.mp3` |
| 90 | `leaderboard_self` | LeaderboardDetailView — своя позиция | Акцент "ты здесь" | `leaderboard_self.mp3` |

---

## 9. Эмбиент / Фон (5 SFX loops)

### P1 — Важные

| # | Звук | Где используется | Описание | Файл |
|---|-------|------------------|----------|------|
| 91 | `ambient_hub` | HubView / CityMapView (loop) | Тихий город, ветер, далёкие звуки | `ambient_hub.mp3` |
| 92 | `ambient_arena` | ArenaDetailView (loop) | Толпа, рёв арены издалека | `ambient_arena.mp3` |
| 93 | `ambient_dungeon` | DungeonRoomDetailView (loop) | Пещера, капли, эхо | `ambient_dungeon.mp3` |
| 94 | `ambient_combat` | CombatDetailView → active (loop) | Напряжение, тихие удары сердца | `ambient_combat.mp3` |
| 95 | `ambient_shop` | ShopDetailView (loop) | Рынок, звон, бормотание | `ambient_shop.mp3` |

---

## 10. Музыка (12 треков)

### P0 — Критичные

| # | Трек | Где используется | Настроение | Длительность | Файл |
|---|-------|------------------|-----------|-------------|------|
| M1 | Main Theme | WelcomeView, загрузка | Эпическое, тёмное фэнтези | 60-90 сек loop | `music_main_theme.mp3` |
| M2 | Hub Theme | HubView / CityMap | Спокойное, мрачноватое, "дом" | 90-120 сек loop | `music_hub.mp3` |
| M3 | Battle Theme | CombatDetailView → active | Напряжённое, быстрое, боевое | 60-90 сек loop | `music_battle.mp3` |
| M4 | Victory Fanfare | CombatResultView → win | Героическое, триумф | 5-8 сек sting | `music_victory.mp3` |
| M5 | Defeat Theme | CombatResultView → loss | Мрачное, потеря | 5-8 сек sting | `music_defeat.mp3` |

### P1 — Важные

| # | Трек | Где используется | Настроение | Длительность | Файл |
|---|-------|------------------|-----------|-------------|------|
| M6 | Arena Theme | ArenaDetailView | Предбоевое напряжение | 60-90 сек loop | `music_arena.mp3` |
| M7 | Dungeon Theme | DungeonRoomDetailView | Тёмное, исследование | 90-120 сек loop | `music_dungeon.mp3` |
| M8 | Boss Theme | Boss floor (5, 10) | Интенсивное, эпическое | 60-90 сек loop | `music_boss.mp3` |
| M9 | Shop Theme | ShopDetailView | Торговое, оживлённое | 60-90 сек loop | `music_shop.mp3` |

### P2 — Желательные

| # | Трек | Где используется | Настроение | Длительность | Файл |
|---|-------|------------------|-----------|-------------|------|
| M10 | Tavern Theme | TavernDetailView | Тёплое, уютное, средневековое | 90-120 сек loop | `music_tavern.mp3` |
| M11 | Character Creation | OnboardingDetailView | Мистическое, предвкушение | 60-90 сек loop | `music_creation.mp3` |
| M12 | Dungeon Rush | DungeonRushDetailView | Ускоряющееся, интенсивное | 60-90 сек loop | `music_dungeon_rush.mp3` |

---

## Бесплатные ресурсы (где искать)

### SFX — Звуковые эффекты

| Ресурс | Лицензия | Что искать | Ссылка |
|--------|----------|------------|--------|
| **Pixabay SFX** | Royalty-free, no attribution | UI, combat, RPG sounds | https://pixabay.com/sound-effects/ |
| **Freesound.org** | CC0 / CC-BY | Всё — огромная база | https://freesound.org/ |
| **Zapsplat** | Free (attribution) / Premium | Fantasy, magic, combat | https://www.zapsplat.com/sound-effect-category/fantasy/ |
| **itch.io SFX packs** | Varies (many free/CC0) | Fantasy RPG пакеты | https://itch.io/game-assets/free/genre-rpg/tag-sound-effects |
| **Free Fantasy 200 SFX Pack** | Free | 200 фэнтези SFX в одном паке | https://tommusic.itch.io/free-fantasy-200-sfx-pack |
| **Fantasy RPG Essential Sounds** | Free | 67 RPG SFX (combat, UI, spells) | https://endersund.itch.io/fantasy-rpg-essential-sounds |
| **OpenGameArt.org** | CC0 / CC-BY | Game-specific sounds | https://opengameart.org/ |
| **Uppbeat SFX** | Free tier (attribution) | UI sounds, digital | https://uppbeat.io/sfx/category/digital-and-ui/ui |
| **Dev_Tones** | Free | UI sounds specifically for apps | https://rcptones.com/dev_tones/ |
| **JDSherbert UI SFX Pack** | Free | Buttons, toggles, alerts | https://jdsherbert.itch.io/ultimate-ui-sfx-pack |

### Музыка — Background Music

| Ресурс | Лицензия | Что искать | Ссылка |
|--------|----------|------------|--------|
| **Pixabay Music** | Royalty-free, no attribution | RPG, fantasy, epic | https://pixabay.com/music/search/rpg/ |
| **Soundimage.org** | Free (credit appreciated) | Fantasy loops, battle, ambient | https://soundimage.org/fantasy-7/ |
| **OpenGameArt Music** | CC0 / CC-BY | RPG loops | https://opengameart.org/content/rpgmusic |
| **itch.io Music Packs** | Varies | Fantasy RPG soundtrack packs | https://itch.io/game-assets/free/genre-rpg/tag-music |
| **Fesliyan Studios** | Royalty-free | Fantasy background music | https://www.fesliyanstudios.com/royalty-free-music/downloads-c/fantasy-music/27 |
| **Tabletop Audio** | Free (non-commercial, check) | Dark fantasy ambience | https://tabletopaudio.com/ |
| **Aaron Krogh Music** | Free RPG loops | Looped battle/town/dungeon | https://soundcloud.com/aaron-anderson-11/sets/rpg-maker-music-loops |

---

## Рекомендация по приоритетности загрузки

### Фаза 1 — MVP (28 файлов)
Все **P0** звуки + **5 музыкальных треков (M1-M5)**:
- 7 UI sounds
- 9 Combat sounds
- 5 Reward sounds
- 2 Progression sounds
- 3 Dungeon sounds
- 2 Shop sounds

### Фаза 2 — Soft Launch (+35 файлов)
Все **P1** звуки + **4 музыкальных трека (M6-M9)**:
- 5 UI sounds
- 8 Combat sounds
- 7 Reward sounds
- 6 Progression sounds
- 3 Dungeon sounds
- 8 Mini-game sounds
- 3 Shop sounds
- 5 Social/Arena sounds
- 5 Ambient loops

### Фаза 3 — Polish (+15 файлов)
Все **P2** звуки + **3 музыкальных трека (M10-M12)**:
- 6 UI sounds
- 4 Combat sounds
- 2 Progression sounds
- 2 Dungeon sounds

---

## Технические требования

| Параметр | Значение |
|----------|----------|
| Формат | MP3 (128-192 kbps) или CAF для iOS |
| Sample rate | 44100 Hz |
| Channels | Mono (SFX), Stereo (Music) |
| Длительность SFX | 0.1 — 3 сек |
| Длительность Music | 60 — 120 сек (seamless loop) |
| Loudness | -16 LUFS (SFX нормализованы) |
| Fade | Music: 0.5s fade-in/out при переходах |
| Naming | snake_case, категория в префиксе |

---

## Заметки по стилю

Hexbound — это **тёмное фэнтези** с мобильным фокусом. Звуки должны быть:

- **Грувовые, но не перегруженные** — мобильные спикеры ограничены
- **Короткие и чёткие** — никаких длинных хвостов на SFX
- **Тёмные, но не депрессивные** — gothic + medieval, без хоррора
- **Тактильные** — каждое действие должно ощущаться физически
- **Различимые** — каждый звук узнаётся с первого раза

Референсы по настроению: Darkest Dungeon, Slay the Spire, Diablo Immortal, AFK Arena.
