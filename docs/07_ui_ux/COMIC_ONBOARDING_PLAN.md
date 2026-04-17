# Comic Onboarding — Plan & Art Specs

> **Status boundary:** historical concept + art-spec plan for a comic-style onboarding exploration. Treat this as a proposal snapshot, not as the canonical onboarding/tutorial implementation or current asset manifest. Revalidate against the live `wiki/features/tutorial.md`, `wiki/features/characters.md`, and current onboarding assets before using it operationally.

## Concept: "The Ballad of Nobody"

Короткая лор-история в стиле комикса. Новичок приходит в Hexbound — и город показывает, что его тут ждёт. Тёмный юмор, атмосферный арт, кинематографичная подача.

**3 страницы, 9 панелей, комбо-анимация (авто с задержкой 0.6с + тап для ускорения).**

---

## Стиль (единый для всех панелей)

**Ключевые слова стиля:** Карикатурный гротескный фэнтези-мультяшный стиль. Тёмный юмор. Толстые чёрные контуры. Акварельная заливка. Сильный контраст. Богатые цвета. Тёмный фон с золотыми акцентами.

**Style prefix для КАЖДОГО промпта:**
> Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with subtle stone texture and gold accents, dark fantasy comic panel, exaggerated proportions, expressive faces, no text, no speech bubbles, no UI elements, no logo

**Цветовая палитра:** Совпадает с `DarkFantasyTheme` — `#0D0D1A` (bgAbyss), `#1A1A2E` (bgPrimary), `#D4A537` (gold), `#E63946` (danger/crimson), `#A0A0B0` (textSecondary)

**Референс:** Стиль близкий к Darkest Dungeon / карикатурным средневековым иллюстрациям, но с юмором и гротеском. Персонажи — утрированные, с большими головами, выразительными лицами, комичными позами.

---

## Page 1: "WELCOME TO HEXBOUND" — 3 панели

### Нарратив
Камера приближается к городу. Сначала видим его с высоты — потом улицы — потом первый NPC тебя встречает.

### Panel 1.1 — Город с высоты (WIDE)

| Параметр | Значение |
|---|---|
| **Layout** | Full-width, top |
| **Display size** | 350×197pt (кропнуть сверху/снизу) |
| **Generate ratio** | **16:9** |
| **Кроп в приложении** | Центральный кроп по высоте |

**Prompt:**
> Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with stone texture and gold accents. Bird's eye view of a massive crumbling fantasy city at dusk. A ridiculously oversized arena dome in the center glowing orange. Tiny crooked buildings leaning on each other. Dungeon entrance on the outskirts with eerie green glow and a "KEEP OUT (seriously)" sign. Forge chimneys belching comically thick smoke. A blood-red moon with a slightly annoyed face. Exaggerated gothic architecture, everything slightly wonky and alive. Wide establishing shot. No text.

**Caption:** *"HEXBOUND. A city older than regret."*

### Panel 1.2 — Улица города (LEFT HALF)

| Параметр | Значение |
|---|---|
| **Layout** | Left/Right half |
| **Display size** | 170×213pt |
| **Generate ratio** | **4:5** |
| **Кроп** | Без кропа, точное совпадение |

**Prompt:**
> Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with gold accents. A cramped medieval fantasy market street at night. A suspicious goblin merchant with an enormous grin selling glowing green potions from a rickety cart, one eye bigger than the other. A muscular warrior with a comically bandaged arm and black eye inspecting a bent sword. Wanted posters with ridiculous cartoon faces on stone walls. A tiny rat in full plate armor strutting past confidently. Exaggerated proportions, expressive faces, comedic energy. Street-level perspective. No text.

**Caption:** *"They sell swords, curses, and secondhand potions. No refunds."*

### Panel 1.3 — NPC встречает тебя (RIGHT HALF)

| Параметр | Значение |
|---|---|
| **Layout** | Right half |
| **Display size** | 170×210pt |
| **Generate size** | 510×630px (3x retina) |
| **Aspect ratio** | ~4:5 |

**Prompt:**
> Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with gold accents. Close-up portrait of a skeletal NPC merchant behind a wooden counter, grinning with oversized teeth at the viewer. Wearing a tattered purple hood and gaudy gold jewelry. One bony hand doing a welcoming gesture, the other hiding a knife behind his back. Shelves behind him with cracked skulls, bubbling potions, and a jar labeled "mystery meat". Warm torchlight from below casting dramatic upward shadows. Direct eye contact, breaking fourth wall, mischievous expression. No text.

**Caption (speech bubble style):** *"You look like easy money. Welcome."*

---

## Page 2: "BLOOD & GLORY" — 4 панели

### Нарратив
Арена — главное место в городе. Все дерутся. А под городом — подземелья, где всё ещё хуже.

### Panel 2.1 — Арена: бой (WIDE)

| Параметр | Значение |
|---|---|
| **Layout** | Full-width, top |
| **Display size** | 350×150pt (экстра-широкий, кинематографичный) |
| **Generate ratio** | **21:9** |
| **Кроп** | Без кропа — ультравайд формат |

**Prompt:**
> Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with crimson and gold accents. Inside a massive gladiatorial arena. Two ridiculously muscular cartoon warriors clashing oversized swords mid-air, comically large sparks flying everywhere. A roaring crowd of bizarre fantasy creatures in tiered stone seats — goblins with popcorn, a skeleton taking notes, an orc doing the wave. Blood-red banners hanging from crumbling pillars. Dynamic exaggerated action pose. Low angle looking up at the fighters. Chaotic energy. No text.

**Caption:** *"Bakers fight. Priests fight. Even the rats have a ranking."*

### Panel 2.2 — Победитель (LEFT HALF)

| Параметр | Значение |
|---|---|
| **Layout** | Left/Right half |
| **Display size** | 170×170pt |
| **Generate ratio** | **1:1** |
| **Кроп** | Без кропа |

**Prompt:**
> Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark background with gold accents. A bruised cartoon warrior standing triumphantly on a comical pile of unconscious opponents in an arena. Missing teeth, black eye, armor cracked and dented, but grinning ear to ear with wild pride. Raising a bent sword overhead with one arm, the other arm in a sling. Gold coins raining down from above. Exaggerated heroic pose, comedic bravado. Spotlight from above. No text.

**Caption:** *"Win, and they sing songs about you."*

### Panel 2.3 — Проигравший (RIGHT HALF)

| Параметр | Значение |
|---|---|
| **Layout** | Right half |
| **Display size** | 170×180pt |
| **Generate size** | 510×540px (3x retina) |
| **Aspect ratio** | ~1:1 |

**Prompt:**
> Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark background with muted blue-grey tones. The same bruised cartoon warrior from before, now face-down flat on the arena floor with stars circling his head. A massive new champion casually standing with one foot on his back, yawning. The crowd is pointing and laughing hysterically. A tiny goblin medic approaching with an absurdly small stretcher and a "good luck" expression. Humiliating and hilarious. Visual comedy. No text.

**Caption:** *"Lose, and they sing funnier ones."*

### Panel 2.4 — Подземелья (WIDE)

| Параметр | Значение |
|---|---|
| **Layout** | Full-width, bottom |
| **Display size** | 350×197pt |
| **Generate ratio** | **16:9** |
| **Кроп** | Центральный кроп по высоте |

**Prompt:**
> Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with eerie green and purple accents. A massive dungeon entrance carved into a cliff face shaped like a screaming demon mouth with crooked stone teeth. Scattered bones, broken weapons, and a dropped sandwich on the ground. Multiple pairs of glowing eyes of different sizes visible in the darkness inside — some angry, some curious, one pair wearing tiny glasses. A single flickering torch barely illuminating the entrance. Creepy green mist oozing out. Menacing but with subtle comedic details. Wide shot. No text.

**Caption:** *"Below the city, things get worse. Much worse."*

---

## Page 3: "YOUR TURN" — 2 панели

### Нарратив
Экипируйся. Выходи на арену. Твоя очередь. Финальный кинематографичный момент.

### Panel 3.1 — Экипировка (TALL)

| Параметр | Значение |
|---|---|
| **Layout** | Full-width, tall |
| **Display size** | 350×263pt |
| **Generate ratio** | **4:3** |
| **Кроп** | Без кропа, точное совпадение |

**Prompt:**
> Caricature grotesque fantasy cartoon style, dark humor, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with warm gold and orange accents. A scrawny cartoon hero nervously gearing up in a cluttered forge room. Trying to strap on oversized battle armor that's clearly too big, reaching for a glowing sword on a messy weapon rack. Forge fire blazing behind casting dramatic orange rim lighting. Shelves overflowing with mismatched shields, dented helmets, and suspicious potions. An old blacksmith in the corner shaking his head. The hero's expression is a mix of determination and terror — wide eyes, clenched jaw, shaky hands. The underdog moment. Mid-shot. No text.

**Caption:** *"Every legend started broke, confused, and slightly terrified."*

### Panel 3.2 — Выход на арену (WIDE, HERO SHOT)

| Параметр | Значение |
|---|---|
| **Layout** | Full-width, bottom, hero |
| **Display size** | 350×197pt |
| **Generate ratio** | **16:9** |
| **Кроп** | Центральный кроп по высоте |

**Prompt:**
> Caricature grotesque fantasy cartoon style, thick black outlines, watercolor shading, strong contrast, rich colors, dark moody background with blazing gold and crimson accents. A lone cartoon hero walking through massive arena gates from behind, backlit by a wall of fire and torchlight. Now wearing the armor properly, standing tall, cape flowing dramatically. Silhouette framed by the golden light. The roaring crowd is a chaotic mass of shapes and raised fists beyond the gates. Dramatic low angle looking up at the hero's back. Dust particles and embers in the light beams. Despite the caricature style, this panel is genuinely epic and cinematic — the humor gives way to a real goosebumps moment. The underdog is ready. No text.

**Caption:** *"The difference? They fought anyway."*

**Final text (появляется после паузы):** *"YOUR TURN."*

---

## Сводная таблица панелей

| # | Panel | Layout | Generate Ratio | Display (pt) | Кроп |
|---|---|---|---|---|---|
| 1.1 | Город с высоты | Wide | **16:9** | 350×197 | Центр |
| 1.2 | Улица города | Left half | **4:5** | 170×213 | Нет |
| 1.3 | NPC встречает | Right half | **4:5** | 170×213 | Нет |
| 2.1 | Арена: бой | Ultra-wide | **21:9** | 350×150 | Нет |
| 2.2 | Победитель | Left half | **1:1** | 170×170 | Нет |
| 2.3 | Проигравший | Right half | **1:1** | 170×170 | Нет |
| 2.4 | Подземелья | Wide | **16:9** | 350×197 | Центр |
| 3.1 | Экипировка | Tall | **4:3** | 350×263 | Нет |
| 3.2 | Выход на арену | Wide hero | **16:9** | 350×197 | Центр |

**Всего: 9 панелей, 4 уникальных ratio: 16:9, 4:5, 21:9, 1:1, 4:3.**

---

## Анимация (на каждой странице)

**Комбо-режим:** Панели появляются автоматически с задержкой ~0.6с между ними. Тап ускоряет — показывает следующую панель мгновенно.

| Эффект | Описание |
|---|---|
| **Появление панели** | Fade in (opacity 0→1) + slide up (20pt) за 0.4с |
| **Caption** | Fade in с задержкой 0.2с после панели, typewriter-стиль для речевых пузырей |
| **Переход между страницами** | Swipe left/right + кнопка Continue |
| **Финальный текст "YOUR TURN"** | Cinematic delay 1с, затем fade in с gold glow pulse |

---

## Звук

| Момент | SFX |
|---|---|
| Появление панели | Лёгкий whoosh / page turn |
| Page 2.1 (арена) | Crowd roar (тихо, фоном) |
| Page 2.4 (подземелья) | Distant monster growl |
| Page 3.2 (финал) | Epic horn / drum hit |
| "YOUR TURN" | Anvil strike + crowd cheer |

---

## Технический план (Swift)

1. Заменить `LoreIntroView.swift` — новый `ComicOnboardingView.swift`
2. Модель `ComicPage` с массивом `ComicPanel` (image, caption, layout, speechBubble?)
3. State: `currentPage`, `revealedPanelCount`, `isAutoRevealing`
4. Комбо-логика: Timer на 0.6с + onTapGesture для ускорения
5. Сохранить: Skip, swipe-навигацию, progress bar, ENTER HEXBOUND на последней странице
6. Рамки панелей — `RoundedRectangle` с `DarkFantasyTheme.borderMedium` stroke
